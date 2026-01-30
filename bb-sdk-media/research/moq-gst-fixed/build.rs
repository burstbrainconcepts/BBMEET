fn main() {
	// Set C11 standard for aws-lc-sys on Windows MSVC
	// This is required because aws-lc-sys needs C11 features (atomics)
	// but defaults to C99 on Windows, which causes compilation errors
	if cfg!(target_os = "windows") {
		std::env::set_var("AWS_LC_SYS_C_STD", "c11");
		// Also set CFLAGS to use C11 standard for MSVC
		if let Ok(mut cflags) = std::env::var("CFLAGS") {
			// Replace -std:c99 with -std:c11 if present
			if cflags.contains("-std:c99") {
				cflags = cflags.replace("-std:c99", "-std:c11");
			} else if !cflags.contains("-std:c11") {
				cflags.push_str(" -std:c11");
			}
			std::env::set_var("CFLAGS", cflags);
		} else {
			std::env::set_var("CFLAGS", "-std:c11");
		}
	}
	
	gst_plugin_version_helper::info()
}
