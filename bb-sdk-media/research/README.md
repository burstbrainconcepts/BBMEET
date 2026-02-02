# MoQ-GST Research & Fix Documentation

This folder contains all research, analysis, and work related to fixing the `moq-gst` dependency conflict that prevents `egress-manager` from being enabled.

## 📚 Documentation Files

### Quick Start
- **`STATUS.md`** ⭐ - **Start here!** Current status, plan, and next steps
- **`SUMMARY.md`** - Quick reference summary of findings
- **`ANALYSIS.md`** - Detailed technical analysis of the problem
- **`SOLUTION_OPTIONS.md`** - All solution approaches evaluated

### Source Code
- **`moq-gst-repo/`** - Original upstream `moq-gst` source code
- **`moq-gst-fixed/`** - Our fork (work in progress, fix not yet implemented)
- **`moq-gst-source/`** - Full `moq-rs` repository (for reference)

## 🎯 Current Status

**TL;DR:** Research is complete, fix strategy identified, but **fix not yet implemented**.

- ✅ Problem analyzed and documented
- ✅ Solution approach identified
- ✅ Fork structure created
- ⏳ **Fix implementation pending**

**See `STATUS.md` for full details and plan.**

## 🔍 The Problem

`moq-gst` depends on both `moq-native` and `moq-karp`, which use incompatible `web-transport` versions. This causes a type size mismatch (1600 bits vs 960 bits) when trying to bridge sessions.

**Error:**
```
error[E0512]: cannot transmute between types of different sizes
```

## 💡 The Solution

Extract the underlying `quinn::Connection` from `moq-native` and create a `moq-karp` compatible session directly, bypassing the type conflict.

## 📋 Next Steps

1. Read `STATUS.md` for the full plan
2. Implement the fix in `moq-gst-fixed/`
3. Test the fix
4. Push to GitHub
5. Re-enable `egress-manager` in main project

## 🔗 Related Files

- `../Cargo.toml` - Main project configuration (egress-manager currently disabled)
- `../README-ARCHITECTURE.md` - Main project architecture documentation
- `../buildspec-egress.yml` - CI/CD buildspec for egress features

---

**Last Updated:** 2026-01-26  
**Status:** Research Complete, Implementation Pending






