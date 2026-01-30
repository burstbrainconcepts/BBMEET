# MoQ-GST Fix Notes

## Problem
`moq-native` and `moq-karp` use incompatible `web-transport` versions, causing type mismatch when trying to bridge sessions via `moq_transfork::Session::connect()`.

**Root Cause:**
- `moq-native` uses `web-transport-quinn` 0.4.x internally
- `moq-karp` (via `web-transport` 0.8.0) expects `web-transport-quinn` 0.5.x
- The type size mismatch (1600 bits vs 960 bits) prevents `moq_transfork` from bridging them

## Solution Implemented

**Approach:** Bypass `moq-native`'s session creation entirely and use `quinn` directly to create a connection, then create a `web-transport-quinn` 0.5.0 session that's compatible with `moq-karp`.

### Changes Made

1. **Updated `Cargo.toml`:**
   - Changed `web-transport-quinn` from `0.4` to `0.5` (matches moq-karp's expectation)
   - Added direct dependencies: `quinn = "0.11"`, `rustls = "0.23"`, `rustls-pemfile = "2.0"`, `rustls-native-certs = "0.8"`

2. **Modified `src/sink/imp.rs`:**
   - Removed dependency on `moq-native::quic` module
   - Added direct `quinn` connection creation
   - Created `create_quinn_client_config()` helper function
   - Creates `web-transport-quinn` 0.5.0 session directly from `quinn::Connection`
   - Uses `moq_transfork::Session::connect()` with the compatible session

3. **Modified `src/source/imp.rs`:**
   - Same changes as sink - direct `quinn` connection creation
   - Creates compatible `web-transport-quinn` 0.5.0 session
   - Bridges to `moq-karp` via `moq_transfork`

### Implementation Details

**Connection Flow:**
1. Create `quinn::Endpoint` with TLS configuration
2. Establish `quinn::Connection` to the server
3. Create `web_transport_quinn::Session` using version 0.5.0 (compatible with moq-karp)
4. Bridge to `moq-karp` using `moq_transfork::Session::connect()`

**TLS Configuration:**
- Supports system certificates (default)
- Supports disabling certificate verification (for development)
- Uses `web-transport-quinn::ALPN` for protocol negotiation

## Build Requirements

**System Dependencies:**
- `cmake` - Required for building `aws-lc-sys` (used by `rustls`)
- GStreamer development libraries (for the plugin)
- Visual Studio Build Tools (Windows) - Required for MSVC compiler

**Rust Dependencies:**
- All Rust dependencies are specified in `Cargo.toml`

**Building on Windows:**
- Use the provided `build.ps1` script: `.\build.ps1`
- The script sets required environment variables to fix C11 standard issues with `aws-lc-sys`
- Alternatively, set these environment variables before running `cargo build`:
  - `AWS_LC_SYS_CFLAGS=-std:c11`
  - `CMAKE=C:\Program Files\CMake\bin\cmake.exe` (if not in PATH)

**Building on Linux/macOS:**
- Run `cargo build` directly (no special configuration needed)

## Testing Status

- ✅ Code changes implemented
- ✅ No linter errors
- ⏳ Full compilation test pending (Windows build requires C11 standard fix)

## Next Steps

1. ✅ Implement fix in fork
2. ⏳ Test compilation (requires cmake installation)
3. ⏳ Push to GitHub repository
4. ⏳ Re-enable in main project

## Build Issues and Solutions

### Windows C11 Standard Issue

**Problem:** `aws-lc-sys` (dependency of `rustls`) requires C11 standard with atomics support, but MSVC has limited C11 support. Even with `-std:c11`, MSVC may not fully support C11 atomics, causing compilation errors:
```
fatal error C1189: #error: "C atomic support is not enabled"
```

**Status:** This is a known limitation of MSVC's C11 implementation. The build script attempts to set C11 flags, but MSVC's C11 atomics support is incomplete.

**Workarounds:**
1. **Use WSL (Windows Subsystem for Linux)** - Recommended for Windows builds
   ```bash
   # In WSL
   cd /mnt/e/waterbus/bb-sdk-media/research/moq-gst-fixed
   cargo build
   ```

2. **Use a Linux build environment** - Docker, VM, or CI/CD pipeline

3. **Use pre-built binaries** - If available, use pre-compiled `aws-lc-sys` binaries

4. **Alternative TLS backend** - Consider using a different TLS implementation that doesn't require `aws-lc-sys` (may require code changes)

**Note:** The `build.ps1` script sets `AWS_LC_SYS_CFLAGS=-std:c11` which helps, but may not fully resolve the issue due to MSVC limitations. The build may succeed on Linux/macOS without these workarounds.

## Notes

- The fix bypasses `moq-native`'s QUIC client entirely, using `quinn` directly
- This ensures we use the `web-transport-quinn` version that `moq-karp` expects
- The `moq_transfork` bridge should now work correctly since both sides use compatible versions



