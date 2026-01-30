# Egress Manager Fix - Current Status & Plan

## 📋 Executive Summary

**Current State:** `egress-manager` is **disabled** in the main project due to `moq-gst` dependency conflicts. Research and analysis are complete. A fix strategy has been identified but **not yet implemented**.

**Goal:** Fix the `moq-gst` dependency conflict in a separate fork, test it, then re-enable `egress-manager` in the main project.

---

## 🔍 Problem Statement

### The Issue

`egress-manager` depends on `moq-gst`, which has a fundamental dependency conflict:

```
moq-gst
├── moq-native (0.6.7)
│   └── Uses web-transport version A
│
└── moq-karp (0.14.1)
    └── Uses web-transport version B (incompatible with A)
```

**The Conflict:**
- `moq-native` creates a QUIC session using one `web-transport` version
- `moq-karp` expects a session using a different `web-transport` version
- The bridge (`moq_transfork::Session::connect()`) fails due to type size mismatch (1600 bits vs 960 bits)

**Error:**
```
error[E0512]: cannot transmute between types of different sizes
moq_native::web_transport::Session (1600 bits) 
vs 
moq_karp::moq_transfork::web_transport::Session (960 bits)
```

### Why It Matters

`egress-manager` provides:
- HLS streaming capabilities
- MoQ (Media over QUIC) streaming
- Recording/playback features

These are **optional features** - the core WebRTC stack (`signalling` + `sfu`) works fine without them.

---

## 📁 Research Organization

All research files are in `bb-sdk-media/research/`:

```
research/
├── ANALYSIS.md              # Detailed technical analysis
├── SOLUTION_OPTIONS.md      # All possible solutions evaluated
├── SUMMARY.md               # Quick reference summary
├── STATUS.md                # This file - current status
├── moq-gst-repo/            # Original upstream moq-gst source
├── moq-gst-fixed/           # Our fork (work in progress)
└── moq-gst-source/          # Full moq-rs repository (reference)
```

---

## 🔬 Research Findings

### Key Discovery

1. **`moq-native`** is used ONLY for QUIC connection setup:
   - Creates QUIC client
   - Establishes connection
   - Returns `moq_native::web_transport::Session`

2. **`moq-karp`** is used for the actual MoQ protocol:
   - `BroadcastProducer`, `BroadcastConsumer`
   - Handles all MoQ-specific functionality

3. **The Bridge** (`moq_transfork::Session::connect()`) tries to convert between them but fails due to incompatible types.

### Solution Strategy

**Recommended Approach:** Extract the underlying `quinn::Connection` from `moq-native` and create a `moq-karp` compatible session directly.

**Why:** Both likely use `quinn` under the hood, so we can bypass the type conflict by working at the connection level.

---

## 🎯 Implementation Plan

### Phase 1: Fix the Fork ✅ (Research Complete)

**Location:** `bb-sdk-media/research/moq-gst-fixed/`

**Status:** 
- ✅ Fork structure created
- ✅ Problem analyzed
- ⏳ **Fix not yet implemented**

**What Needs to Happen:**

1. **Investigate `moq-karp` API:**
   - Check if `moq-karp` has its own QUIC client
   - If yes: Replace `moq-native` entirely (best solution)
   - If no: Extract `quinn::Connection` from `moq-native`

2. **Implement the Fix:**
   - Modify `src/sink/imp.rs` and `src/source/imp.rs`
   - Replace `moq_transfork::Session::connect()` with direct connection handling
   - Ensure type compatibility

3. **Test Compilation:**
   - `cargo build` in the fork directory
   - Verify no dependency conflicts
   - Ensure all tests pass

### Phase 2: Push to GitHub ⏳

**Repository:** `https://github.com/burstbrainconcepts/moq-gst-fixed.git`

**Status:** Repository exists but fix not yet pushed.

**What Needs to Happen:**

1. Implement the fix locally (Phase 1)
2. Test it works
3. Commit and push to GitHub
4. Tag a release version (e.g., `v0.1.8-fixed`)

### Phase 3: Re-enable in Main Project ⏳

**Location:** `bb-sdk-media/Cargo.toml`

**Current State:**
```toml
# egress-manager is commented out:
# "crates/egress-manager",  # DISABLED: moq-gst type incompatibility issue

# Patch is commented out:
# [patch.crates-io]
# moq-gst = { git = "https://github.com/burstbrainconcepts/moq-gst-fixed.git", branch = "main" }
```

**What Needs to Happen:**

1. **Uncomment the patch:**
   ```toml
   [patch.crates-io]
   moq-gst = { git = "https://github.com/burstbrainconcepts/moq-gst-fixed.git", branch = "main" }
   ```

2. **Re-enable egress-manager:**
   ```toml
   members = [
       "signalling",
       "sfu",
       "crates/webrtc-manager",
       "crates/waterbus-proto",
       "crates/dispatcher",
       "crates/egress-manager",  # Re-enabled after moq-gst fix
   ]
   ```

3. **Test Core Build Still Works:**
   ```bash
   cargo build --release --workspace --exclude egress-manager
   ```

4. **Test Egress Build:**
   ```bash
   cargo build --release --all-features
   ```

5. **Update CI/CD:**
   - Core build should still exclude `egress-manager` (for speed)
   - Egress build (`buildspec-egress.yml`) should include it
   - Both should use the patched `moq-gst`

---

## 🚦 Current Status Checklist

### Research Phase ✅
- [x] Problem identified and documented
- [x] Dependencies analyzed
- [x] Solution options evaluated
- [x] Research files organized
- [x] Fork structure created

### Implementation Phase ⏳
- [ ] Investigate `moq-karp` QUIC client API
- [ ] Implement fix in `research/moq-gst-fixed/`
- [ ] Test fork compiles successfully
- [ ] Push fix to GitHub
- [ ] Tag release version

### Integration Phase ⏳
- [ ] Uncomment patch in main `Cargo.toml`
- [ ] Re-enable `egress-manager` in workspace
- [ ] Test core build (should still work)
- [ ] Test egress build (should now work)
- [ ] Update CI/CD if needed
- [ ] Document re-enablement

---

## 📝 Files to Modify (When Ready)

### 1. Fork Fix (`research/moq-gst-fixed/`)
- `src/sink/imp.rs` - Fix session bridging
- `src/source/imp.rs` - Fix session bridging
- `Cargo.toml` - Ensure dependencies are correct
- `FIX_NOTES.md` - Document the fix approach

### 2. Main Project (`bb-sdk-media/`)
- `Cargo.toml` - Uncomment patch and re-enable egress-manager
- `README-ARCHITECTURE.md` - Update status
- `buildspec-egress.yml` - Verify it works with fixed fork

---

## 🔗 Related Documentation

- **`ANALYSIS.md`** - Detailed technical analysis of the problem
- **`SOLUTION_OPTIONS.md`** - All solution approaches evaluated
- **`SUMMARY.md`** - Quick reference summary
- **`../README-ARCHITECTURE.md`** - Main project architecture docs

---

## ⚠️ Important Notes

1. **Core Build Must Stay Fast:** Even after fixing, the core build should continue excluding `egress-manager` for speed (~3-5 min vs ~10-15 min).

2. **Feature Flag Strategy:** `egress-manager` should remain behind a feature flag so it's optional:
   ```toml
   [features]
   default = []  # Core only
   egress = ["egress-manager"]  # Optional HLS/MoQ
   ```

3. **Testing Strategy:** Test the fix thoroughly in the fork before re-enabling in main project to avoid breaking the working core build.

4. **Maintenance:** The fork will need to be maintained as upstream `moq-gst` updates. Consider contributing the fix upstream if possible.

---

## 📅 Timeline Estimate

- **Phase 1 (Fix Fork):** 2-4 hours (depending on solution complexity)
- **Phase 2 (Push to GitHub):** 30 minutes
- **Phase 3 (Re-enable):** 1-2 hours (testing + verification)

**Total:** ~4-7 hours of focused work

---

**Last Updated:** 2026-01-26  
**Status:** Research Complete, Implementation Pending

