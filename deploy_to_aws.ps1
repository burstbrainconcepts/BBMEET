# AWS S3 Deployment Script
# Usage: .\deploy_to_aws.ps1 "my-bucket-name"
param (
    [string]$BucketName
)

# 1. Check/Find AWS CLI
$AwsExe = "aws"
if (-not (Get-Command "aws" -ErrorAction SilentlyContinue)) {
    $StandardPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    if (Test-Path $StandardPath) {
        Write-Host "Warn: 'aws' command not in PATH, using: $StandardPath" -ForegroundColor Yellow
        $AwsExe = $StandardPath
    } else {
        Write-Host "Error: AWS CLI is not installed." -ForegroundColor Red
        Write-Host "Please install it from: https://aws.amazon.com/cli/"
        exit 1
    }
}

# 1b. Check/Find Flutter
$FlutterExe = "flutter.bat"
if (-not (Get-Command "flutter" -ErrorAction SilentlyContinue)) {
    $FlutterPath = "E:\meeting\flutter\bin\flutter.bat"
    if (Test-Path $FlutterPath) {
        Write-Host "Warn: 'flutter' command not in PATH, using: $FlutterPath" -ForegroundColor Yellow
        $FlutterExe = $FlutterPath
    } else {
        Write-Host "Error: Flutter is not installed or not found." -ForegroundColor Red
        exit 1
    }
}

# 2. Get Bucket Name
if ([string]::IsNullOrEmpty($BucketName)) {
    $BucketName = Read-Host "Enter S3 Bucket Name (e.g. unique-name-123)"
}

# 3. Build Web App
Write-Host "`nBuilding Web App..." -ForegroundColor Cyan
& $FlutterExe clean
& $FlutterExe build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

# 4. Create Bucket
Write-Host "`nCreating Bucket: $BucketName..." -ForegroundColor Cyan
& $AwsExe s3 mb "s3://$BucketName" 2>$null

# 5. Configure Static Hosting
Write-Host "Configuring Website Hosting..." -ForegroundColor Cyan
& $AwsExe s3 website "s3://$BucketName" --index-document index.html --error-document index.html

# 5b. Disable "Block Public Access" (Critical)
Write-Host "🔓 Unblocking Public Access..." -ForegroundColor Cyan
& $AwsExe s3api put-public-access-block --bucket "$BucketName" --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# 6. Apply Public Read Policy
Write-Host "Applying Public Policy..." -ForegroundColor Cyan

$PolicyObj = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Sid = "PublicReadGetObject"
            Effect = "Allow"
            Principal = "*"
            Action = "s3:GetObject"
            Resource = "arn:aws:s3:::$BucketName/*"
        }
    )
}
$PolicyJson = $PolicyObj | ConvertTo-Json -Depth 5

$PolicyFile = "s3_policy_temp.json"
$PolicyJson | Out-File $PolicyFile -Encoding ASCII

& $AwsExe s3api put-bucket-policy --bucket "$BucketName" --policy file://$PolicyFile
Remove-Item $PolicyFile -ErrorAction SilentlyContinue

# 7. Upload Files
Write-Host "`nUploading files..." -ForegroundColor Cyan
& $AwsExe s3 sync build/web "s3://$BucketName"

Write-Host "`nDeployment Complete!" -ForegroundColor Green
Write-Host "URL: http://$BucketName.s3-website-us-east-1.amazonaws.com"
