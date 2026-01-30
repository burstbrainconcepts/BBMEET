# Fix Notes for moq-gst Dependency Conflict

## Issue
`moq-gst` has a dependency conflict where `moq-native` and `moq-karp` use different versions of `web-transport` internally, causing type incompatibility when trying to pass a `moq-native::web_transport::Session` to `moq_karp::moq_transfork::Session::connect()`.

## Solution
The fix requires:
1. Updating `moq-native` and `moq-karp` to versions that use compatible `web-transport` versions
2. OR modifying the code to extract the underlying `quinn::Connection` and create a new session using the compatible type
3. OR using `moq-karp`'s quic client directly if it has one

## Current Status
- Code has been modified to attempt type conversion
- Dependencies have been updated to try to force compatible versions
- This needs testing and may require further fixes

## Next Steps
1. Test compilation
2. Fix any compilation errors
3. Test functionality
4. Push to fork and update main project to use it

