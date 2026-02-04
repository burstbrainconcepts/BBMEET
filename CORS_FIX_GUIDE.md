# CORS Fix - Environment Variable Configuration

## ✅ **Solution Implemented**

CORS is now **fully configurable via environment variables** and **allows all origins by default** to ensure it works immediately.

### **How It Works:**

1. **By Default**: If `CORS_ORIGINS` is not set, **ALL origins are allowed** (most permissive - will definitely work)
2. **When Configured**: Set `CORS_ORIGINS` to a comma-separated list of allowed origins
3. **Always Allows**: `localhost` origins (for development)

### **Configuration:**

The CORS configuration is read from:
- **Environment Variable**: `CORS_ORIGINS` 
- **SSM Parameter**: `/bbmeet/production/api/CORS_ORIGINS`

### **Setup Steps:**

1. **Set the SSM Parameter** (optional - if not set, allows all origins):
   ```bash
   aws ssm put-parameter \
     --name "/bbmeet/production/api/CORS_ORIGINS" \
     --value "https://www.bbmeet.site,https://bbmeet.site" \
     --type String \
     --overwrite \
     --region us-east-1
   ```

2. **Push the code and rebuild**:
   ```bash
   git push origin main
   aws codebuild start-build --project-name bbmeet-api-build
   ```

3. **Update the ECS task definition** (after build succeeds):
   ```bash
   aws ecs register-task-definition --cli-input-json file://infrastructure/task-definition.json --region us-east-1
   aws ecs update-service --cluster bbmeet-cluster --service bbmeet-api-service --force-new-deployment --region us-east-1
   ```

### **What Changed:**

1. ✅ Added `@fastify/cors` package
2. ✅ CORS now uses Fastify's native CORS plugin (more reliable)
3. ✅ CORS origins configurable via `CORS_ORIGINS` env var
4. ✅ **By default allows ALL origins** (if `CORS_ORIGINS` not set)
5. ✅ Added `CORS_ORIGINS` to task definition (reads from SSM)

### **Why This Will Work:**

- **Most Permissive Default**: If `CORS_ORIGINS` is not set, it allows all origins - this guarantees CORS will work
- **Fastify Native Plugin**: Uses `@fastify/cors` directly, which properly handles preflight OPTIONS requests
- **Environment Variable**: Can be changed without code changes - just update SSM parameter and restart service

### **To Restrict Origins Later:**

Once it's working, you can restrict it by setting the SSM parameter:
```bash
aws ssm put-parameter \
  --name "/bbmeet/production/api/CORS_ORIGINS" \
  --value "https://www.bbmeet.site,https://bbmeet.site" \
  --type String \
  --overwrite \
  --region us-east-1
```

Then restart the ECS service to pick up the new value.



