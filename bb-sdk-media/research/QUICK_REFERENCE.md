# Egress Manager Fix - Quick Reference

## 🚦 Current State

| Component | Status | Notes |
|-----------|--------|-------|
| **Core Build** | ✅ **Working** | `signalling` + `sfu` building and deploying successfully |
| **Egress Manager** | ⏸️ **Disabled** | Commented out in `Cargo.toml` workspace members |
| **Research** | ✅ **Complete** | Problem analyzed, solution identified |
| **Fork** | ⏳ **Not Fixed** | Exists but fix not yet implemented |
| **GitHub Repo** | ✅ **Exists** | `burstbrainconcepts/moq-gst-fixed` (empty/fix pending) |

## 🔍 The Problem (One Sentence)

`moq-gst` uses both `moq-native` and `moq-karp` which have incompatible `web-transport` versions, causing a type size mismatch (1600 vs 960 bits).

## 💡 The Solution (One Sentence)

Extract `quinn::Connection` from `moq-native` and create `moq-karp` session directly, bypassing the type conflict.

## 📁 Where Everything Is

```
bb-sdk-media/
├── Cargo.toml                    # egress-manager commented out, patch commented out
├── research/
│   ├── STATUS.md                # ⭐ Full status and plan
│   ├── README.md                # Research folder overview
│   ├── QUICK_REFERENCE.md        # This file
│   ├── ANALYSIS.md              # Technical deep dive
│   ├── SOLUTION_OPTIONS.md      # All solutions evaluated
│   ├── SUMMARY.md               # Quick summary
│   ├── moq-gst-fixed/           # Our fork (fix pending)
│   └── moq-gst-repo/            # Original source
└── buildspec-egress.yml          # CI/CD for egress (ready when fixed)
```

## 🎯 What Needs to Happen

### Step 1: Fix the Fork ⏳
- Location: `research/moq-gst-fixed/`
- Files: `src/sink/imp.rs`, `src/source/imp.rs`
- Action: Implement connection extraction/bridging fix

### Step 2: Test & Push ⏳
- Test: `cargo build` in fork directory
- Push: Commit and push to GitHub
- Tag: Create release version

### Step 3: Re-enable ⏳
- Uncomment patch in `Cargo.toml`
- Uncomment `egress-manager` in workspace members
- Test: `cargo build --release --all-features`

## 📝 Key Files to Modify (When Ready)

1. **`research/moq-gst-fixed/src/sink/imp.rs`** - Fix session bridging
2. **`research/moq-gst-fixed/src/source/imp.rs`** - Fix session bridging
3. **`Cargo.toml`** (line 5) - Uncomment `"crates/egress-manager"`
4. **`Cargo.toml`** (line 20-21) - Uncomment `[patch.crates-io]` section

## ⚡ Quick Commands

```bash
# Check current status
cat research/STATUS.md

# View the problem
cat research/ANALYSIS.md

# See solution options
cat research/SOLUTION_OPTIONS.md

# Test fork (when fix is implemented)
cd research/moq-gst-fixed
cargo build

# Test main project with egress (after re-enabling)
cd ../..
cargo build --release --all-features
```

## 🔗 Important Links

- **GitHub Fork:** `https://github.com/burstbrainconcepts/moq-gst-fixed.git`
- **Main Project:** `bb-sdk-media/`
- **CI/CD:** `buildspec-core.yml` (working), `buildspec-egress.yml` (ready)

## ⚠️ Important Notes

1. **Core build must stay fast** - Even after fixing, exclude `egress-manager` from core builds
2. **Feature flag** - `egress-manager` should remain optional via feature flag
3. **Test thoroughly** - Fix in fork first, then re-enable in main project
4. **Maintain fork** - Will need updates as upstream `moq-gst` evolves

---

**For full details, see `STATUS.md`**

