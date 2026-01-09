# CloudFront HTTPS Setup Script
# Usage: .\enable_https.ps1 "my-bucket-name"
param (
    [string]$BucketName
)

# 1. Check/Find AWS CLI
$AwsExe = "aws"
if (-not (Get-Command "aws" -ErrorAction SilentlyContinue)) {
    $StandardPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    if (Test-Path $StandardPath) {
        $AwsExe = $StandardPath
    } else {
        Write-Host "Error: AWS CLI not found." -ForegroundColor Red
        exit 1
    }
}

# 2. Get Bucket Name
if ([string]::IsNullOrEmpty($BucketName)) {
    $BucketName = Read-Host "Enter your S3 Bucket Name (same as before)"
}

$Region = "us-east-1"
$OriginDomain = "$BucketName.s3-website-$Region.amazonaws.com"

Write-Host "`nSetting up CloudFront for: $OriginDomain" -ForegroundColor Cyan
Write-Host "This creates a new distribution (takes ~1-2 min to request, 15 min to deploy)..." -ForegroundColor Yellow

# 3. Create Distribution Config properly
$DistConfig = @{
    CallerReference = (Get-Date).Ticks.ToString()
    Aliases = @{ Quantity = 0 }
    DefaultRootObject = ""
    Origins = @{
        Quantity = 1
        Items = @(
            @{
                Id = "S3-$BucketName"
                DomainName = $OriginDomain
                OriginPath = ""
                CustomHeaders = @{ Quantity = 0 }
                CustomOriginConfig = @{
                    HTTPPort = 80
                    HTTPSPort = 443
                    OriginProtocolPolicy = "http-only"
                    OriginSslProtocols = @{
                        Quantity = 3
                        Items = @("TLSv1", "TLSv1.1", "TLSv1.2")
                    }
                    OriginReadTimeout = 30
                    OriginKeepaliveTimeout = 5
                }
            }
        )
    }
    DefaultCacheBehavior = @{
        TargetOriginId = "S3-$BucketName"
        ViewerProtocolPolicy = "redirect-to-https"
        MinTTL = 0
        AllowedMethods = @{
            Quantity = 2
            Items = @("HEAD", "GET")
            CachedMethods = @{
                Quantity = 2
                Items = @("HEAD", "GET")
            }
        }
        SmoothStreaming = $false
        DefaultTTL = 86400
        MaxTTL = 31536000
        Compress = $true
        LambdaFunctionAssociations = @{ Quantity = 0 }
        FunctionAssociations = @{ Quantity = 0 }
        FieldLevelEncryptionId = ""
        ForwardedValues = @{
            QueryString = $false
            Cookies = @{ Forward = "none" }
            Headers = @{ Quantity = 0 }
            QueryStringCacheKeys = @{ Quantity = 0 }
        }
        TrustedSigners = @{ Enabled = $false; Quantity = 0 }
    }
    CacheBehaviors = @{ Quantity = 0 }
    CustomErrorResponses = @{ Quantity = 0 }
    Comment = "Created by BB Meet Auto-Deploy"
    Logging = @{
        Enabled = $false
        IncludeCookies = $false
        Bucket = ""
        Prefix = ""
    }
    PriceClass = "PriceClass_All"
    Enabled = $true
}

$JsonConfig = $DistConfig | ConvertTo-Json -Depth 10
$JsonFile = "cf_config.json"
$JsonConfig | Out-File $JsonFile -Encoding ASCII

# 4. Run Command
Write-Host "Sending request to AWS..." -ForegroundColor Cyan
try {
    # Using Invoke-Expression to capture output easily with the complex args
    $ResultJson = & $AwsExe cloudfront create-distribution --distribution-config file://$JsonFile
    $Result = $ResultJson | ConvertFrom-Json
    
    $DomainName = $Result.Distribution.DomainName
    $Id = $Result.Distribution.Id

    Write-Host "`nSUCCESS!" -ForegroundColor Green
    Write-Host "Key generated: $Id"
    Write-Host "Your SECURE URL will be: https://$DomainName" -ForegroundColor Green
    Write-Host "`nIMPORTANT: It takes about 15 MINUTES for this link to start working." -ForegroundColor Yellow
    Write-Host "AWS has to replicate it to servers all over the world."
}
catch {
    Write-Host "Failed to create distribution." -ForegroundColor Red
    Write-Host $_
}

Remove-Item $JsonFile -ErrorAction SilentlyContinue
