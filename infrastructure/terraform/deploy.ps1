# BB_SDK AWS Infrastructure Setup Script

Write-Host "================================" -ForegroundColor Cyan
Write-Host "BB_SDK AWS Infrastructure Setup" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Step 1: Get user's public IP
Write-Host "Step 1: Getting your public IP..." -ForegroundColor Yellow
try {
    $publicIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content
    Write-Host "Your public IP: $publicIP" -ForegroundColor Green
} catch {
    Write-Host "Could not auto-detect IP. Please enter manually." -ForegroundColor Red
    $publicIP = Read-Host "Enter your public IP"
}

# Step 2: Get database password
Write-Host "`nStep 2: Database password setup" -ForegroundColor Yellow
$dbPassword = Read-Host "Enter a strong database password (min 8 chars)" -AsSecureString
$dbPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbPassword))

if ($dbPasswordPlain.Length -lt 8) {
    Write-Host "Password too short! Must be at least 8 characters." -ForegroundColor Red
    exit 1
}

# Step 3: Create terraform.tfvars
Write-Host "`nStep 3: Creating terraform.tfvars..." -ForegroundColor Yellow
$tfvarsContent = @"
# BB_SDK AWS Configuration
aws_region = "us-east-1"
project_name = "bb-sdk"

# Database password
db_password = "$dbPasswordPlain"

# Your IP for SSH access
your_ip = "$publicIP/32"
"@

Set-Content -Path "terraform.tfvars" -Value $tfvarsContent
Write-Host "✓ terraform.tfvars created" -ForegroundColor Green

# Step 4: Initialize Terraform
Write-Host "`nStep 4: Initializing Terraform..." -ForegroundColor Yellow
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform init failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Terraform initialized" -ForegroundColor Green

# Step 5: Plan
Write-Host "`nStep 5: Creating deployment plan..." -ForegroundColor Yellow
Write-Host "This will show what infrastructure will be created.`n" -ForegroundColor Cyan
terraform plan

if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform plan failed!" -ForegroundColor Red
    exit 1
}

# Step 6: Confirm deployment
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT SUMMARY" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Region: us-east-1" -ForegroundColor White
Write-Host "Estimated Cost: ~`$100/month" -ForegroundColor White
Write-Host "Duration: 15-20 minutes" -ForegroundColor White
Write-Host "`nResources to create:" -ForegroundColor White
Write-Host "  - VPC with subnets" -ForegroundColor Gray
Write-Host "  - RDS PostgreSQL" -ForegroundColor Gray
Write-Host "  - ElastiCache Redis (2 clusters)" -ForegroundColor Gray
Write-Host "  - S3 bucket" -ForegroundColor Gray
Write-Host "  - Security groups & IAM roles" -ForegroundColor Gray
Write-Host "================================`n" -ForegroundColor Cyan

$confirm = Read-Host "Proceed with deployment? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

# Step 7: Apply
Write-Host "`nStep 7: Deploying infrastructure..." -ForegroundColor Yellow
Write-Host "This will take 15-20 minutes. Please wait...`n" -ForegroundColor Cyan
terraform apply -auto-approve

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nDeployment failed! Check errors above." -ForegroundColor Red
    exit 1
}

# Step 8: Save outputs
Write-Host "`nStep 8: Saving outputs..." -ForegroundColor Yellow
terraform output > ../infrastructure-outputs.txt
Write-Host "✓ Outputs saved to infrastructure-outputs.txt" -ForegroundColor Green

# Success
Write-Host "`n================================" -ForegroundColor Green
Write-Host "✓ INFRASTRUCTURE DEPLOYED!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Review outputs in infrastructure-outputs.txt" -ForegroundColor White
Write-Host "2. Deploy bb-sdk-api to EC2" -ForegroundColor White
Write-Host "3. Deploy bb-sdk-media to EC2" -ForegroundColor White
Write-Host "`nSee PROJECT_ROADMAP.md for detailed next steps." -ForegroundColor Cyan
