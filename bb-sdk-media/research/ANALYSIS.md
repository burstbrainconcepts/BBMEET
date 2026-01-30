# MoQ-GST Dependency Analysis

## Current Situation

### Problem
`moq-gst` depends on both `moq-native` and `moq-karp`, but they use incompatible `web-transport` versions, causing type conflicts at the bridge point.

### Current Usage Pattern

**In `sink/imp.rs` and `source/imp.rs`:**

1. **moq-native** (lines 9, 154-165):
   - Used for QUIC connection: `quic::Args`, `quic::Endpoint`, `tls::Args`
   - Creates a QUIC client: `quic::Endpoint::new(config)?.client`
   - Connects to get a session: `client.connect(url).await`
   - Returns: `moq_native::web_transport::Session`

2. **moq-karp** (lines 7, 166-173):
   - Used for MoQ protocol: `moq_karp::BroadcastProducer`, `moq_karp::BroadcastConsumer`
   - **THE PROBLEM**: `moq_transfork::Session::connect(session)` expects a compatible session type
   - But `moq-native`'s session type is incompatible with `moq-karp`'s expected type

### The Bridge Point (The Problem)

```rust
// From moq-native (incompatible web-transport version)
let session = client.connect(url).await?;  // moq_native::web_transport::Session

// Trying to bridge to moq-karp (expects different web-transport version)
let session = moq_transfork::Session::connect(session).await?;  // ❌ TYPE MISMATCH
```

## Research Questions

1. **Does `moq-karp` have its own QUIC client?**
   - Need to check if we can replace `moq-native`'s QUIC client entirely
   - This would eliminate the dependency conflict

2. **What does `moq-transfork` actually do?**
   - Is it just a type adapter?
   - Can we bypass it or replace it?

3. **Can we extract the underlying `quinn::Connection`?**
   - Both might use `quinn` under the hood
   - We could extract it and create a new session

## Next Steps

1. ✅ Research files organized in `bb-sdk-media/research/`
2. ⏳ Check `moq-karp` API for QUIC client capabilities
3. ⏳ Check `moq-transfork` documentation/source
4. ⏳ Determine best solution approach
5. ⏳ Create implementation plan

## Files Organization

- `research/moq-gst-repo/` - Original moq-gst source
- `research/moq-gst-source/` - Full moq-rs repository (for reference)
- `research/ANALYSIS.md` - This file



