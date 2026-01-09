# AWS S3 Deployment Script
param (
    [string]$BucketName
)

# 1. Check for AWS CLI
if (-not (Get-Command "aws" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: AWS CLI is not installed." -ForegroundColor Red
    Write-Host "Please install it from: https://aws.amazon.com/cli/"
    exit 1
}

# 2. Get Bucket Name
if ([string]::IsNullOrEmpty($BucketName)) {
    $BucketName = Read-Host "Please enter your S3 Bucket Name (e.g., meet.yourdomain.com)"
}

# 3. Build Web App
Write-Host "`n🔨 Building Web App (Release mode)..." -ForegroundColor Cyan
flutter clean
flutter build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

# 4. Create Bucket (if not exists)
Write-Host "`n🪣 Checking/Creating Bucket: $BucketName..." -ForegroundColor Cyan
aws s3 mb "s3://$BucketName" 2>$null

# 5. Configure Static Hosting
Write-Host "⚙️ Configuring Static Website Hosting..." -ForegroundColor Cyan
aws s3 website "s3://$BucketName" --index-document index.html --error-document index.html

# 6. Apply Public Read Policy
# Note: You might need to disable "Block Public Access" in console manually if this fails
Write-Host "🔓 Applying Public Policy..." -ForegroundColor Cyan
$policy = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$BucketName/*"
        }
    ]
}
"@
$policy | Out-File "s3_policy.json" -Encoding ASCII
aws s3api put-bucket-policy --bucket "$BucketName" --policy file://s3_policy.json
Remove-Item "s3_policy.json"

# 7. Upload Files
Write-Host "`n🚀 Uploading files to S3..." -ForegroundColor Cyan
aws s3 sync build/web "s3://$BucketName"

Write-Host "`n✅ Deployment Complete!" -ForegroundColor Green
Write-Host "🌍 Your site should be available at: http://$BucketName.s3-website-us-east-1.amazonaws.com"
Write-Host "Next Step: Configure CloudFront in the AWS Console for HTTPS."
