use anyhow::Context as _;
use gst::glib;
use gst::prelude::*;
use gst::subclass::prelude::*;

use moq_karp::moq_transfork;
use once_cell::sync::Lazy;
use std::sync::Arc;
use std::sync::LazyLock;
use std::sync::Mutex;
use quinn::{ClientConfig, Endpoint, TransportConfig};
use rustls::pki_types::ServerName;
use rustls::ClientConfig as RustlsClientConfig;
use std::time::Duration;

static CAT: Lazy<gst::DebugCategory> =
	Lazy::new(|| gst::DebugCategory::new("moqsrc", gst::DebugColorFlags::empty(), Some("MoQ Source Element")));

pub static RUNTIME: Lazy<tokio::runtime::Runtime> = Lazy::new(|| {
	tokio::runtime::Builder::new_multi_thread()
		.enable_all()
		.worker_threads(1)
		.build()
		.unwrap()
});

#[derive(Default, Clone)]
struct Settings {
	pub url: String,
	pub tls_disable_verify: bool,
}

#[derive(Default)]
pub struct MoqSrc {
	settings: Mutex<Settings>,
}

#[glib::object_subclass]
impl ObjectSubclass for MoqSrc {
	const NAME: &'static str = "MoqSrc";
	type Type = super::MoqSrc;
	type ParentType = gst::Bin;

	fn new() -> Self {
		Self::default()
	}
}

impl GstObjectImpl for MoqSrc {}
impl BinImpl for MoqSrc {}

impl ObjectImpl for MoqSrc {
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
			"url" => settings.url = value.get().unwrap(),
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

impl ElementImpl for MoqSrc {
	fn metadata() -> Option<&'static gst::subclass::ElementMetadata> {
		static ELEMENT_METADATA: Lazy<gst::subclass::ElementMetadata> = Lazy::new(|| {
			gst::subclass::ElementMetadata::new(
				"MoQ Src",
				"Source/Network/MoQ",
				"Receives media over the network via MoQ",
				"Luke Curley <kixelated@gmail.com>",
			)
		});

		Some(&*ELEMENT_METADATA)
	}

	fn pad_templates() -> &'static [gst::PadTemplate] {
		static PAD_TEMPLATES: LazyLock<Vec<gst::PadTemplate>> = LazyLock::new(|| {
			let video = gst::PadTemplate::new(
				"video_%u",
				gst::PadDirection::Src,
				gst::PadPresence::Sometimes,
				&gst::Caps::new_any(),
			)
			.unwrap();

			let audio = gst::PadTemplate::new(
				"audio_%u",
				gst::PadDirection::Src,
				gst::PadPresence::Sometimes,
				&gst::Caps::new_any(),
			)
			.unwrap();

			vec![video, audio]
		});

		PAD_TEMPLATES.as_ref()
	}

	fn change_state(&self, transition: gst::StateChange) -> Result<gst::StateChangeSuccess, gst::StateChangeError> {
		match transition {
			gst::StateChange::ReadyToPaused => {
				if let Err(e) = RUNTIME.block_on(self.setup()) {
					gst::error!(CAT, obj = self.obj(), "Failed to setup: {:?}", e);
					return Err(gst::StateChangeError);
				}
			}

			gst::StateChange::PausedToReady => {
				// Cleanup publisher
				self.cleanup();
			}

			_ => (),
		}

		// Chain up
		self.parent_change_state(transition)
	}
}

impl MoqSrc {
	async fn setup(&self) -> anyhow::Result<()> {
		let (url, path, tls_disable_verify) = {
			let settings = self.settings.lock().unwrap();
			let url = url::Url::parse(&settings.url)?;
			let path = url.path().strip_prefix("/").unwrap().to_string();
			(url, path, settings.tls_disable_verify)
		};

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
		let session = moq_transfork::Session::connect(session)
			.await
			.context("Failed to bridge session to moq-karp - this should work with web-transport-quinn 0.5.0")?;
		let mut broadcast = moq_karp::BroadcastConsumer::new(session, path);

		// TODO handle catalog updates
		let catalog = broadcast.next_catalog().await?.context("no catalog found")?.clone();

		gst::info!(CAT, "catalog: {:?}", catalog);

		for video in catalog.video {
			let mut track = broadcast.track(&video.track)?;

			let caps = match video.codec {
				moq_karp::VideoCodec::H264(_) => {
					let builder = gst::Caps::builder("video/x-h264")
						//.field("width", video.resolution.width)
						//.field("height", video.resolution.height)
						.field("alignment", "au");

					if let Some(description) = video.description {
						builder
							.field("stream-format", "avc")
							.field("codec_data", gst::Buffer::from_slice(description.clone()))
							.build()
					} else {
						builder.field("stream-format", "annexb").build()
					}
				}
				_ => unimplemented!(),
			};

			gst::info!(CAT, "caps: {:?}", caps);

			let templ = self.obj().element_class().pad_template("video_%u").unwrap();

			let srcpad = gst::Pad::builder_from_template(&templ).name(&video.track.name).build();
			srcpad.set_active(true).unwrap();

			let stream_start = gst::event::StreamStart::builder(&video.track.name)
				.group_id(gst::GroupId::next())
				.build();
			srcpad.push_event(stream_start);

			let caps_evt = gst::event::Caps::new(&caps);
			srcpad.push_event(caps_evt);

			let segment = gst::event::Segment::new(&gst::FormattedSegment::<gst::ClockTime>::new());
			srcpad.push_event(segment);

			self.obj().add_pad(&srcpad).expect("Failed to add pad");

			let mut reference = None;

			// Push to the srcpad in a background task.
			tokio::spawn(async move {
				// TODO don't panic on error
				while let Some(frame) = track.read().await.expect("failed to read frame") {
					let mut buffer = gst::Buffer::from_slice(frame.payload);
					let buffer_mut = buffer.get_mut().unwrap();

					// Make the timestamps relative to the first frame
					let timestamp = if let Some(reference) = reference {
						frame.timestamp - reference
					} else {
						reference = Some(frame.timestamp);
						frame.timestamp
					};

					let pts = gst::ClockTime::from_nseconds(timestamp.as_nanos() as _);
					buffer_mut.set_pts(Some(pts));

					let mut flags = buffer_mut.flags();
					match frame.keyframe {
						true => flags.remove(gst::BufferFlags::DELTA_UNIT),
						false => flags.insert(gst::BufferFlags::DELTA_UNIT),
					};

					buffer_mut.set_flags(flags);

					gst::info!(CAT, "pushing sample: {:?}", buffer);

					if let Err(err) = srcpad.push(buffer) {
						gst::warning!(CAT, "Failed to push sample: {:?}", err);
					}
				}
			});
		}

		// for audio in catalog.audio {}

		// We downloaded the catalog and created all the pads.
		self.obj().no_more_pads();

		Ok(())
	}

	fn cleanup(&self) {
		// TODO kill spawned tasks
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
