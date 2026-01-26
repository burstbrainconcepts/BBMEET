# MoQ-GST Fix Notes

## Problem
`moq-native` and `moq-karp` use incompatible `web-transport` versions, causing type mismatch when trying to bridge sessions via `moq_transfork::Session::connect()`.

## Solution Approach
Since both `moq-native` and `moq-karp` use `quinn` under the hood, we need to:
1. Extract the underlying `quinn::Connection` from `moq-native`'s session
2. Create a new `moq-karp` compatible session from that connection

## Implementation Strategy
The fix requires understanding the internal structure of `web_transport_quinn::Session` to extract the connection. Since we can't directly access private fields, we'll need to:

1. **Option A**: Use `moq-karp`'s own QUIC client if it has one (bypass `moq-native` entirely)
2. **Option B**: Create an unsafe adapter that extracts the connection using type casting
3. **Option C**: Update dependencies to compatible versions (may not exist)

## Current Status
- Fork created: `bb-sdk-media/research/moq-gst-fixed/`
- Need to implement proper connection extraction
- Need to test compilation

## Next Steps
1. Investigate `moq-karp` API for QUIC client
2. Implement connection extraction
3. Test compilation
4. Integrate into main project

