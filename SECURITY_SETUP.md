# Security Setup Guide

## 1. Environment Configuration

### Setup .env File
1. Copy `.env.template` to `.env`:
   ```bash
   cp .env.template .env
   ```
2. Update `.env` with your production values.

> **Note**: The `.env` file should never be committed to version control. It is already added to `.gitignore`.

## 2. AWS Credentials

You need to provide the following credentials from your AWS Console:

### Cognito User Pool
- **COGNITO_POOL_ID**: Found in Cognito > User Pools > [Your Pool] > User Pool ID
- **COGNITO_APP_CLIENT_ID**: Found in App clients tab
- **COGNITO_REGION**: The region your pool is created in (e.g., us-east-1)

### Pinpoint Analytics
- **PINPOINT_APP_ID**: Found in AWS Pinpoint > [Your Project] > Settings > Project ID
- **PINPOINT_REGION**: The region for your Pinpoint project

## 3. Build & Release

### ProGuard/R8
Obfuscation is enabled for release builds. If you encounter issues with third-party libraries, check `android/app/proguard-rules.pro`.

### SSL Pinning
To enable certificate pinning, update `android/app/src/main/res/xml/network_security_config.xml` with your certificate hashes.

## 4. Testing Security

Run the following command to check for basic security issues:
```bash
flutter analyze
```

Verify that no sensitive keys are hardcoded in the source code.
