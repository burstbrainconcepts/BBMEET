use anyhow::Context as _;
use gst::glib;
use gst::prelude::*;
use gst::subclass::prelude::*;
use gst_base::subclass::prelude::*;

use moq_karp::moq_transfork;
use once_cell::sync::Lazy;
use std::sync::Arc;
use std::sync::Mutex;
use url::Url;
use quinn::{ClientConfig, Endpoint, TransportConfig};
use rustls::pki_types::ServerName;
use rustls::ClientConfig as RustlsClientConfig;
use std::time::Duration;

pub static RUNTIME: Lazy<tokio::runtime::Runtime> = Lazy::new(|| {
	tokio::runtime::Builder::new_multi_thread()
		.enable_all()
		.worker_threads(1)
		.build()
		.unwrap()
});

#[derive(Default, Clone)]
struct Settings {
	pub url: Option<String>,
	pub tls_disable_verify: bool,
}

#[derive(Default)]
struct State {
	pub media: Option<moq_karp::cmaf::Import>,
}

#[derive(Default)]
pub struct MoqSink {
	settings: Mutex<Settings>,
	state: Arc<Mutex<State>>,
}

#[glib::object_subclass]
impl ObjectSubclass for MoqSink {
	const NAME: &'static str = "MoqSink";
	type Type = super::MoqSink;
	type ParentType = gst_base::BaseSink;

	fn new() -> Self {
		Self::default()
	}
}

impl ObjectImpl for MoqSink {
	fn properties() -> &'static [glib::ParamSpec] {
		static PROPERTIES: Lazy<Vec<glib::ParamSpec>> = Lazy::new(|| {
			vec![
				glib::ParamSpecString::builder("url")
					.nick("Source URL")
					.blurb("Connect to the given URL")
					.build(),
				glib::ParamSpecBoolean::builder("tls-disable-verify")
					.nick("TLS disable verify")
					.blurb("Disable TLS verification")
					.default_value(false)
					.build(),
			]
		});
		PROPERTIES.as_ref()
	}

	fn set_property(&self, _id: usize, value: &glib::Value, pspec: &glib::ParamSpec) {
		let mut settings = self.settings.lock().unwrap();

		match pspec.name() {
			"url" => settings.url = Some(value.get().unwrap()),
			"tls-disable-verify" => settings.tls_disable_verify = value.get().unwrap(),
			_ => unimplemented!(),
		}
	}

	fn property(&self, _id: usize, pspec: &glib::ParamSpec) -> glib::Value {
		let settings = self.settings.lock().unwrap();

		match pspec.name() {
			"url" => settings.url.to_value(),
			"tls-disable-verify" => settings.tls_disable_verify.to_value(),
			_ => unimplemented!(),
		}
	}
}

impl GstObjectImpl for MoqSink {}

impl ElementImpl for MoqSink {
	fn metadata() -> Option<&'static gst::subclass::ElementMetadata> {
		static ELEMENT_METADATA: Lazy<gst::subclass::ElementMetadata> = Lazy::new(|| {
			gst::subclass::ElementMetadata::new(
				"MoQ Sink",
				"Sink/Network/MoQ",
				"Transmits media over the network via MoQ",
				"Luke Curley <kixelated@gmail.com>",
			)
		});

		Some(&*ELEMENT_METADATA)
	}

	fn pad_templates() -> &'static [gst::PadTemplate] {
		static PAD_TEMPLATES: Lazy<Vec<gst::PadTemplate>> = Lazy::new(|| {
			let caps = gst::Caps::builder("video/quicktime")
				.field("variant", "iso-fragmented")
				.build();

			let pad_template =
				gst::PadTemplate::new("sink", gst::PadDirection::Sink, gst::PadPresence::Always, &caps).unwrap();

			vec![pad_template]
		});
		PAD_TEMPLATES.as_ref()
	}
}

impl BaseSinkImpl for MoqSink {
	fn start(&self) -> Result<(), gst::ErrorMessage> {
		let _guard = RUNTIME.enter();
		self.setup()
			.map_err(|e| gst::error_msg!(gst::ResourceError::Failed, ["Failed to connect: {}", e]))
	}

	fn stop(&self) -> Result<(), gst::ErrorMessage> {
		Ok(())
	}

	fn render(&self, buffer: &gst::Buffer) -> Result<gst::FlowSuccess, gst::FlowError> {
		let _guard = RUNTIME.enter();
		let data = buffer.map_readable().map_err(|_| gst::FlowError::Error)?;

		let mut state = self.state.lock().unwrap();
		let mut media = state.media.take().expect("not initialized");

		// TODO avoid full media parsing? gst should be able to provide the necessary info
		media.parse(data.as_slice()).expect("failed to parse");
		state.media = Some(media);

		Ok(gst::FlowSuccess::Ok)
	}
}

impl MoqSink {
	fn setup(&self) -> anyhow::Result<()> {
		let settings = self.settings.lock().unwrap();
		let url = settings.url.clone().context("missing url")?;
		let url = Url::parse(&url).context("invalid URL")?;
		let tls_disable_verify = settings.tls_disable_verify;

		RUNTIME.block_on(async move {
			// FIXED: Create QUIC connection directly using quinn, then create web-transport-quinn 0.5.0 session
			// This bypasses moq-native's session creation and uses the version that moq-karp expects
			
			// Create quinn endpoint
			let client_config = create_quinn_client_config(tls_disable_verify)?;
			let endpoint = Endpoint::client("[::]:0".parse().unwrap())?;
			endpoint.set_default_client_config(client_config);
			
			// Resolve DNS
			let host = url.host_str().context("missing hostname")?.to_string();
			let port = url.port().unwrap_or(443);
			let server_name = ServerName::try_from(host.as_str())
				.map_err(|_| anyhow::anyhow!("invalid server name"))?;
			
			// Connect
			let connection = endpoint
				.connect((host.clone(), port), server_name)?
				.await
				.context("failed to establish QUIC connection")?;
			
			// Create web-transport-quinn 0.5.0 session (compatible with moq-karp)
			let session = web_transport_quinn::Session::connect(connection, url.clone())
				.await
				.context("failed to create web-transport session")?;
			
			// Bridge to moq-karp compatible session using moq-transfork
			// Now that we're using the correct web-transport-quinn version, this should work
			let karp_session = moq_transfork::Session::connect(session)
				.await
				.context("failed to bridge session to moq-karp - this should work with web-transport-quinn 0.5.0")?;

			let path = url.path().strip_prefix('/').unwrap().to_string();
			let broadcast = moq_karp::BroadcastProducer::new(karp_session, path)
				.context("failed to create broadcast producer")?;
			let media = moq_karp::cmaf::Import::new(broadcast);

			let mut state = self.state.lock().unwrap();
			state.media = Some(media);
			
			Ok::<(), anyhow::Error>(())
		})?;

		Ok(())
	}
}

/// Create a quinn ClientConfig with TLS settings
fn create_quinn_client_config(disable_verify: bool) -> anyhow::Result<ClientConfig> {
	// Load TLS config similar to moq-native
	let tls_config = if disable_verify {
		// Create a config that accepts any certificate (for development)
		// Use empty root store and a verifier that accepts everything
		let root_store = rustls::RootCertStore::empty();
		let mut client_config = RustlsClientConfig::builder()
			.with_root_certificates(root_store)
			.with_no_client_auth();
		
		// Disable certificate verification by using a custom verifier
		client_config
			.dangerous()
			.set_certificate_verifier(Arc::new(NoCertificateVerification));
		
		client_config
	} else {
		// Use system certificates
		let mut root_store = rustls::RootCertStore::empty();
		root_store.extend(rustls_native_certs::load_native_certs()?);
		
		RustlsClientConfig::builder()
			.with_root_certificates(root_store)
			.with_no_client_auth()
	};
	
	// Set ALPN for web-transport
	let mut tls_config = quinn::crypto::rustls::QuicClientConfig::try_from(tls_config)?;
	tls_config.alpn_protocols = vec![web_transport_quinn::ALPN.as_bytes().to_vec()];
	
	// Create quinn client config
	let mut client_config = ClientConfig::new(Arc::new(tls_config));
	
	// Configure transport
	let mut transport = TransportConfig::default();
	transport.max_idle_timeout(Some(Duration::from_secs(10).try_into().unwrap()));
	client_config.transport_config(Arc::new(transport));
	
	Ok(client_config)
}

/// Certificate verifier that accepts all certificates (for development only)
struct NoCertificateVerification;

impl rustls::client::danger::ServerCertVerifier for NoCertificateVerification {
	fn verify_server_cert(
		&self,
		_end_entity: &rustls::pki_types::CertificateDer<'_>,
		_intermediates: &[rustls::pki_types::CertificateDer<'_>],
		_server_name: &rustls::pki_types::ServerName<'_>,
		_ocsp_response: &[u8],
		_now: rustls::pki_types::UnixTime,
	) -> Result<rustls::client::danger::ServerCertVerified, rustls::Error> {
		Ok(rustls::client::danger::ServerCertVerified::assertion())
	}
}
