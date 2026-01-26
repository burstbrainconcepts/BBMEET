# MoQ-GST Fixed Fork

This is a fixed version of `moq-gst` that resolves the type incompatibility between `moq-native` and `moq-karp`.

## Problem

The original `moq-gst` fails to compile because:
- `moq-native` uses one version of `web-transport`
- `moq-karp` uses a different version of `web-transport`
- `moq_transfork::Session::connect()` cannot bridge between incompatible session types

## Solution

The fix requires one of the following approaches:

### Option 1: Use Compatible Dependency Versions (RECOMMENDED)
Update `Cargo.toml` to use versions of `moq-native` and `moq-karp` that use the same `web-transport` version.

### Option 2: Use moq-karp's Own QUIC Client
If `moq-karp` has its own QUIC client API, use it directly instead of `moq-native`'s client.

### Option 3: Create Connection Adapter
Extract the underlying `quinn::Connection` from `moq-native`'s session and create a new `moq-karp` session.

## Current Status

- ✅ Fork created with improved error messages
- ⏳ Need to implement proper fix (requires API investigation)
- ⏳ Need to test compilation

## Next Steps

1. Investigate `moq-karp` API for QUIC client capabilities
2. Check for compatible dependency versions
3. Implement proper connection extraction/adapter
4. Test compilation
5. Integrate into main project

## Usage

Once fixed, this fork can be used in the main project by updating `Cargo.toml`:

```toml
moq-gst = { git = "https://github.com/burstbrainconcepts/moq-gst-fixed.git", branch = "main" }
```
