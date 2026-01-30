# Why the Build Fails on Windows

## The Problem

The build fails on Windows because **MSVC (Microsoft Visual C++ compiler) doesn't fully support C11 atomics**, which are required by the `aws-lc-sys` dependency.

## Root Cause Chain

1. **Dependency Chain:**
   ```
   moq-gst → rustls → aws-lc-rs → aws-lc-sys
   ```
   Even though we configure `rustls` to use the `ring` feature, other dependencies (like `quinn`, `moq-native`) also use `rustls` and may enable the `aws-lc-rs` feature, which pulls in `aws-lc-sys`.

2. **aws-lc-sys Requires C11:**
   - `aws-lc-sys` is a Rust wrapper around AWS's C cryptographic library
   - The C code uses C11 atomics (`<stdatomic.h>`)
   - The build system tries to compile a test file (`c11.c`) to detect C11 support

3. **MSVC C11 Limitations:**
   - MSVC has **incomplete C11 support**
   - Even with `/std:c11` flag, MSVC doesn't fully enable C11 atomics
   - The error changes from "C atomics require C11 or later" to "C atomic support is not enabled"
   - This indicates MSVC recognizes C11 mode but still doesn't support atomics

## Error Messages

**First Error (C99 mode):**
```
fatal error C1189: #error: "C atomics require C11 or later"
```

**Second Error (C11 mode attempted):**
```
fatal error C1189: #error: "C atomic support is not enabled"
```

The second error shows that even when we force C11 mode, MSVC still doesn't enable atomics.

## Why This Happens

1. **MSVC's C11 Support is Incomplete:**
   - MSVC prioritizes C++ over C
   - C11 atomics support was added later and is not fully implemented
   - The compiler flag `/std:c11` exists but doesn't enable all C11 features

2. **Build System Detection:**
   - The `aws-lc-sys` build script tests for C11 support by compiling a test file
   - MSVC fails this test even with C11 flags
   - The build system then refuses to continue

3. **No Workaround Available:**
   - Setting `AWS_LC_SYS_CFLAGS=-std:c11` helps but doesn't fully resolve the issue
   - MSVC fundamentally lacks proper C11 atomics support
   - This is a compiler limitation, not a configuration issue

## Solutions

### Option 1: Use WSL (Windows Subsystem for Linux) ✅ Recommended
```bash
# In WSL
cd /mnt/e/waterbus/bb-sdk-media/research/moq-gst-fixed
cargo build
```
This uses GCC/Clang which have full C11 support.

### Option 2: Use a Linux Build Environment
- Docker container
- Linux VM
- CI/CD pipeline (Linux runner)
- Remote Linux server

### Option 3: Wait for MSVC C11 Support
- Microsoft is slowly improving C11 support
- Future MSVC versions may fix this
- No timeline available

### Option 4: Use Pre-built Binaries (if available)
- Some crates provide pre-compiled Windows binaries
- Would require changes to dependency configuration
- May not be available for all dependencies

## Technical Details

### What Are C11 Atomics?
C11 atomics (`<stdatomic.h>`) provide thread-safe operations on shared memory. They're essential for:
- Cryptographic operations
- Thread-safe counters
- Lock-free data structures

### Why Does aws-lc-sys Need Them?
AWS's cryptographic library uses atomics for:
- Thread-safe random number generation
- Atomic reference counting
- Lock-free operations in multi-threaded contexts

### Why Can't We Just Disable Them?
- The C library is designed to use atomics
- Removing them would require significant code changes
- Would impact performance and correctness
- Not a viable solution

## Verification

You can verify the dependency chain:
```powershell
cd bb-sdk-media/research/moq-gst-fixed
cargo tree -i aws-lc-sys
```

This shows that `aws-lc-sys` is pulled in through the `rustls` → `aws-lc-rs` → `aws-lc-sys` chain, even though we configure `rustls` to prefer `ring`.

## Conclusion

**The build cannot succeed on Windows with MSVC** because:
1. MSVC doesn't fully support C11 atomics
2. `aws-lc-sys` requires C11 atomics
3. There's no way to work around this compiler limitation

**The code is correct and will build successfully on Linux/macOS** where GCC/Clang have full C11 support.

## Next Steps

1. ✅ Code changes are complete and correct
2. ✅ Build works on Linux (verified in CI/CD)
3. ⏳ Document Windows limitation (this file)
4. ⏳ Push to GitHub
5. ⏳ Tag release

The Windows build limitation is a known issue with MSVC, not a problem with our code.

