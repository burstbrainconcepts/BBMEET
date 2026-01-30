# MoQ-GST Solution Options

## Key Finding: `moq-transfork` is the Bridge

From the code analysis:
- `moq-transfork` is a module within `moq-karp` 
- It's used to bridge `moq-native`'s session to `moq-karp`'s session
- The problem: `moq-native` and `moq-karp` use incompatible `web-transport` versions

## Solution Options

### Option 1: Replace `moq-native` QUIC Client with `moq-karp`'s (BEST)

**If `moq-karp` has its own QUIC client:**

1. Remove `moq-native` dependency entirely
2. Use `moq-karp`'s QUIC client (if available)
3. Directly create `moq-karp` sessions without bridging

**Pros:**
- Eliminates dependency conflict completely
- Simplifies codebase
- One less dependency to maintain

**Cons:**
- Requires `moq-karp` to have QUIC client API
- May need to adapt connection code

**Status:** ⏳ Need to verify if `moq-karp` has QUIC client

---

### Option 2: Extract Underlying `quinn::Connection` (MEDIUM)

**Extract the raw QUIC connection and create new session:**

1. Extract `quinn::Connection` from `moq-native`'s session
2. Create a new `moq-karp` compatible session from it
3. Bypass `moq-transfork` bridge

**Pros:**
- Keeps both dependencies but avoids type conflict
- Works if both use `quinn` under the hood

**Cons:**
- Requires understanding both implementations
- May need unsafe code or API access
- More complex

**Status:** ⏳ Need to check if both use `quinn` and if we can extract it

---

### Option 3: Update Dependencies to Compatible Versions (HARDEST)

**Find compatible versions of `moq-native` and `moq-karp`:**

1. Test different version combinations
2. Find versions that use same `web-transport` version
3. Update `Cargo.toml` accordingly

**Pros:**
- Minimal code changes
- Uses official versions

**Cons:**
- May not exist (versions may have diverged)
- Could break other functionality
- Time-consuming to test

**Status:** ⏳ Need to check version compatibility matrix

---

### Option 4: Fork and Simplify (RECOMMENDED IF OTHERS FAIL)

**Create a simplified fork that removes `moq-native`:**

1. Fork `moq-gst`
2. Replace `moq-native` QUIC client with direct `quinn` usage
3. Or use `moq-karp`'s QUIC client if available
4. Remove `moq-transfork` bridge entirely

**Pros:**
- Full control
- Can optimize for our use case
- Eliminates conflict permanently

**Cons:**
- Need to maintain fork
- More initial work

**Status:** ✅ Can implement if other options don't work

---

## Recommended Approach

1. **First**: Check if `moq-karp` has QUIC client (Option 1)
2. **Second**: Try extracting `quinn::Connection` (Option 2)
3. **Third**: Create simplified fork (Option 4)

## Next Steps

1. ✅ Research organized in `research/` folder
2. ⏳ Check `moq-karp` crate docs/API for QUIC client
3. ⏳ Check if both use `quinn` under the hood
4. ⏳ Decide on solution approach
5. ⏳ Create implementation plan

