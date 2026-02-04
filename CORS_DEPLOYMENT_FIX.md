# CORS Fix Deployment Guide

## Problem
CORS preflight requests (OPTIONS) are being blocked, preventing the frontend from making API calls.

## Root Causes Fixed
1. **ApiKeyGuard blocking OPTIONS requests** - Fixed by allowing OPTIONS to bypass API key check
2. **CORS plugin registration** - Ensured Fastify CORS plugin is registered early with proper configuration
3. **Fallback CORS** - Added NestJS CORS as fallback

## Files Changed
- `bb-sdk-api/src/utils/strategies/api-key.strategy.ts` - Allow OPTIONS requests
- `bb-sdk-api/src/main.ts` - Enhanced CORS configuration with fallback

## Deployment Steps

### Option 1: Wait for CodePipeline (Automatic)
The CodeBuild has succeeded. If CodePipeline is configured, it should automatically deploy. Wait 5-10 minutes.

### Option 2: Manual ECS Service Update
If CodePipeline doesn't trigger automatically, manually update the service:

```bash
# Get the latest task definition
aws ecs describe-task-definition --task-definition bbmeet-api-task --region us-east-1 --query "taskDefinition.revision" --output text

# Force new deployment
aws ecs update-service \
  --cluster bbmeet-cluster \
  --service bbmeet-api-service \
  --force-new-deployment \
  --region us-east-1
```

### Option 3: Push Code and Trigger Build
```bash
# Push the latest changes
git push origin main

# Trigger new build
aws codebuild start-build --project-name bbmeet-api-build --region us-east-1
```

## Verification
After deployment, test CORS:
```bash
curl -X OPTIONS https://api.bbmeet.site/v1/auth \
  -H "Origin: https://www.bbmeet.site" \
  -H "Access-Control-Request-Method: POST" \
  -v
```

You should see `Access-Control-Allow-Origin: https://www.bbmeet.site` in the response headers.

## Expected Behavior After Fix
- OPTIONS requests return 200 with proper CORS headers
- POST/GET requests work normally with API key
- Frontend can successfully make API calls

