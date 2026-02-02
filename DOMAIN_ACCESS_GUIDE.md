# 🌐 BBMeet Domain Access Guide

## Domain Configuration Summary

Based on your Namecheap DNS settings:

### ✅ What Will Work:

#### 1. **`bbmeet.site` (Root Domain)**
- **DNS Setting**: URL Redirect to `https://www.bbmeet.site`
- **Will Work**: ✅ YES
- **What Happens**: Automatically redirects to `https://www.bbmeet.site`
- **Points To**: CloudFront distribution (`d2iuj6f9un560r.cloudfront.net`)
- **Use Case**: Main website/frontend

#### 2. **`www.bbmeet.site`**
- **DNS Setting**: CNAME to `d2iuj6f9un560r.cloudfront.net`
- **Will Work**: ✅ YES
- **Points To**: CloudFront distribution
- **Use Case**: Main website/frontend

#### 3. **`media.bbmeet.site`** ⭐ **MEDIA SERVICES**
- **DNS Setting**: CNAME to `bb-sdk-alb-1284299808.us-east-1.elb.amazonaws.com`
- **Will Work**: ⚠️ **PARTIALLY** (services running, health check stabilizing)
- **Points To**: Media ALB (Signalling & SFU services)
- **Endpoints**:
  - Health Check: `http://media.bbmeet.site/health-check`
  - API: `http://media.bbmeet.site/busapi/v3`
  - WebSocket: `ws://media.bbmeet.site`
  - API Docs: `http://media.bbmeet.site/docs`
- **Status**: Services are running, but health checks are still stabilizing after recent fix

#### 4. **`api.bbmeet.site`**
- **DNS Setting**: CNAME to `bbmeet-alb-397128290.us-east-1.elb.amazonaws.com`
- **Will Work**: ✅ YES (if API service is deployed)
- **Points To**: API ALB
- **Use Case**: REST API endpoints

---

## 🎯 **Current Status**

### Services Running:
- ✅ **SFU Service**: ACTIVE (1/1 tasks)
- ✅ **Signalling Service**: ACTIVE (1/1 tasks)
- ⚠️ **Health Checks**: Still stabilizing (new deployment in progress)

### What You Can Access Now:

1. **`bbmeet.site`** → ✅ Will redirect to `https://www.bbmeet.site` (CloudFront)
2. **`www.bbmeet.site`** → ✅ Will work (CloudFront)
3. **`media.bbmeet.site`** → ⚠️ **Services are running, but:**
   - Health check endpoint may not respond yet (new deployment in progress)
   - API endpoints may work but health checks still stabilizing
   - Wait 5-10 minutes for full deployment to complete

---

## ⏳ **Timeline**

### Right Now:
- ✅ Services are running
- ✅ DNS is correctly configured
- ⚠️ Health checks stabilizing (ResponseCodeMismatch - likely old version still running)

### In 5-10 Minutes:
- ✅ New deployment with health check fix will complete
- ✅ Health checks will show healthy
- ✅ All endpoints will be fully accessible

---

## 🧪 **Testing**

### Test Health Check:
```bash
curl http://media.bbmeet.site/health-check
```
**Expected**: `[v3] Waterbus Service written in Rust` (HTTP 200)

### Test API:
```bash
curl http://media.bbmeet.site/busapi/v3/health-check
```
**Expected**: Same response (if old path still works)

### Test WebSocket:
```javascript
const socket = io('http://media.bbmeet.site');
```

---

## 📝 **Summary**

**Question: "Will `bbmeet.site` work now?"**

**Answer:**
- ✅ **`bbmeet.site`** → YES, redirects to `www.bbmeet.site` (CloudFront)
- ✅ **`www.bbmeet.site`** → YES, works (CloudFront)
- ⚠️ **`media.bbmeet.site`** → **PARTIALLY** - Services are running, but health checks are still stabilizing. Wait 5-10 minutes for full deployment.

**For Media Services**: Use `media.bbmeet.site` (not the root domain)

---

## 🔍 **Troubleshooting**

If `media.bbmeet.site` doesn't work:

1. **Check DNS Propagation**: 
   ```bash
   nslookup media.bbmeet.site
   ```
   Should resolve to: `bb-sdk-alb-1284299808.us-east-1.elb.amazonaws.com`

2. **Check Service Status**:
   ```bash
   aws ecs describe-services --cluster bbmeet-cluster --services bbmeet-signalling-service
   ```

3. **Check Health Checks**:
   ```bash
   aws elbv2 describe-target-health --target-group-arn <signalling-tg-arn>
   ```

4. **Check Logs**:
   ```bash
   aws logs tail /ecs/bbmeet-signalling --follow
   ```



