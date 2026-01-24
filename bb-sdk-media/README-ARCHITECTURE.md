# 🏗️ BBMEET Media Server - Professional Architecture

## Overview

BBMEET follows a **professional workspace structure** with separated core and experimental features, enabling reliable CI/CD and maintainable deployments.

## 🎯 Architecture Separation

### Core Components (Stable, Fast)
- **`signalling`** - WebSocket server for real-time signaling
- **`sfu`** - Selective Forwarding Unit for WebRTC media routing  
- **`webrtc-manager`** - WebRTC peer connection handling
- **`waterbus-proto`** - Protocol definitions
- **`dispatcher`** - Request routing

### Egress Components (Experimental, Optional)
- **`egress-manager`** - HLS/MoQ streaming features (behind feature flag)

## 🔧 Dependency Management

### Fork Override
```toml
[patch.crates-io]
moq-gst = { git = "https://github.com/burstbrainconcepts/moq-gst-fixed.git", branch = "main" }
```

**Why:** The upstream `moq-gst` has dependency conflicts between `moq-native` and `moq-karp` using incompatible `web-transport` versions. Our fork resolves these conflicts.

### Feature Flags
```toml
[features]
default = []  # Core WebRTC only
egress = ["egress-manager"]  # Enable HLS/MoQ streaming
```

## 🚀 CI/CD Strategy

### Two-Build Approach

#### 1. **Core Build** (`buildspec-core.yml`)
- **Fast:** ~3-5 minutes
- **Stable:** No external GStreamer dependencies
- **Components:** signalling + sfu + webrtc-manager
- **Use case:** Production deployments, critical fixes

```bash
cargo build --release --workspace --exclude egress-manager
```

#### 2. **Egress Build** (`buildspec-egress.yml`)  
- **Slower:** ~8-12 minutes
- **Experimental:** Includes GStreamer + moq-gst dependencies
- **Components:** All core + egress-manager
- **Use case:** Feature testing, full-stack validation

```bash
cargo build --release --all-features
```

## 🎮 AWS CodeBuild Integration

### Pipeline Setup
1. **Core Pipeline:** Triggers on `bb-sdk-media/**` changes → Fast, reliable
2. **Egress Pipeline:** Manual trigger or feature branch → Full validation

### Environment Variables
```yaml
MEDIA_HOST: 3.215.239.166
MEDIA_USER: ec2-user  
SSM_PARAM: /bbmeet/ec2-ssh-key
BUILD_TYPE: core|egress
```

## 🐳 Docker Support

### Core Services
```bash
just build-signalling  # → docker.io/lambiengcode/waterbus-signalling
just build-sfu         # → docker.io/lambiengcode/waterbus-sfu
```

### Local Development
```bash
just signalling        # Run signalling server
just sfu               # Run SFU server
just clippy            # Lint all code
just nextest           # Run tests
```

## 🔍 Maintenance

### Dependency Auditing
```bash
cargo audit             # Check for vulnerabilities
cargo tree              # Verify dependency unification
```

### Monitoring
- **Logs:** `~/signalling.log`, `~/sfu.log`, `~/egress.log`
- **Health:** Process monitoring via `ps aux | grep -E "(signalling|sfu)"`

## 📊 Benefits

✅ **Core WebRTC always stable** - No external dependency issues  
✅ **Feature isolation** - Egress problems don't break core functionality  
✅ **Fast CI/CD** - Core builds complete in minutes  
✅ **Professional structure** - Enterprise Rust workspace patterns  
✅ **Fork management** - Controlled dependency overrides  
✅ **Scalable deployment** - Separate Docker containers per service  

## 🔄 Release Process

1. **Core changes** → Trigger core build → Fast deployment
2. **Feature work** → Trigger egress build → Full validation  
3. **Tagged releases** → Both builds → Production deployment

This architecture ensures **reliability** for core video conferencing while enabling **innovation** in streaming features.
