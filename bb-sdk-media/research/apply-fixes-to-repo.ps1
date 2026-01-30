# Script to apply fixes from moq-gst-fixed to moq-gst-repo
# This script automates the process described in APPLY_FIXES.md

param(
    [switch]$DryRun = $false,
    [switch]$SkipBackup = $false
)

$ErrorActionPreference = "Stop"

# Paths
$researchDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$fixedDir = Join-Path $researchDir "moq-gst-fixed"
$repoDir = Join-Path $researchDir "moq-gst-repo"
$backupDir = Join-Path $researchDir "moq-gst-repo-backup"

Write-Host "=== Applying Fixes to moq-gst-repo ===" -ForegroundColor Cyan
Write-Host ""

# Check if directories exist
if (-not (Test-Path $fixedDir)) {
    Write-Host "Error: moq-gst-fixed directory not found at: $fixedDir" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $repoDir)) {
    Write-Host "Error: moq-gst-repo directory not found at: $repoDir" -ForegroundColor Red
    exit 1
}

# Step 1: Backup
if (-not $SkipBackup) {
    Write-Host "Step 1: Creating backup..." -ForegroundColor Yellow
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would backup $repoDir to $backupDir" -ForegroundColor Gray
    } else {
        if (Test-Path $backupDir) {
            Write-Host "  Removing existing backup..." -ForegroundColor Gray
            Remove-Item -Path $backupDir -Recurse -Force
        }
        Copy-Item -Path $repoDir -Destination $backupDir -Recurse
        Write-Host "  Backup created: $backupDir" -ForegroundColor Green
    }
    Write-Host ""
}

# Step 2: Update Cargo.toml
Write-Host "Step 2: Updating Cargo.toml..." -ForegroundColor Yellow
$cargoToml = Join-Path $repoDir "Cargo.toml"
$fixedCargoToml = Join-Path $fixedDir "Cargo.toml"

if ($DryRun) {
    Write-Host "  [DRY RUN] Would update $cargoToml" -ForegroundColor Gray
} else {
    # Read fixed version
    $fixedContent = Get-Content $fixedCargoToml -Raw
    
    # Read original version
    $originalContent = Get-Content $cargoToml -Raw
    
    # Replace version
    $originalContent = $originalContent -replace 'version = "0\.1\.7"', 'version = "0.1.8"'
    
    # Add dependencies if not present
    if ($originalContent -notmatch "web-transport-quinn") {
        # Find the line after moq-karp
        $originalContent = $originalContent -replace '(moq-karp = "0\.14")', "`$1`n# Use web-transport-quinn 0.5.0 to match moq-karp's web-transport 0.8.0 dependency`n# This is the version that moq-karp expects (via web-transport 0.8.0)`nweb-transport-quinn = "0.5"`n# Direct dependencies for QUIC connection creation`nquinn = "0.11"`nrustls = { version = "0.23", default-features = false, features = ["ring"] }`nrustls-pemfile = "2.0"`nrustls-native-certs = "0.8""
    }
    
    # Add workspace table if not present
    if ($originalContent -notmatch '\[workspace\]') {
        $originalContent = $originalContent -replace '(categories = \[.*?\])', "`$1`n`n# Standalone package, not part of parent workspace`n[workspace]"
    }
    
    # Update description
    $originalContent = $originalContent -replace 'description = "Media over QUIC - Gstreamer plugin"', 'description = "Media over QUIC - Gstreamer plugin (Fixed for moq-native/moq-karp compatibility)"'
    
    Set-Content -Path $cargoToml -Value $originalContent -NoNewline
    Write-Host "  Cargo.toml updated" -ForegroundColor Green
}
Write-Host ""

# Step 3: Update build.rs
Write-Host "Step 3: Updating build.rs..." -ForegroundColor Yellow
$buildRs = Join-Path $repoDir "build.rs"
$fixedBuildRs = Join-Path $fixedDir "build.rs"

if ($DryRun) {
    Write-Host "  [DRY RUN] Would update $buildRs" -ForegroundColor Gray
} else {
    Copy-Item -Path $fixedBuildRs -Destination $buildRs -Force
    Write-Host "  build.rs updated" -ForegroundColor Green
}
Write-Host ""

# Step 4: Create build.ps1
Write-Host "Step 4: Creating build.ps1..." -ForegroundColor Yellow
$buildPs1 = Join-Path $repoDir "build.ps1"
$fixedBuildPs1 = Join-Path $fixedDir "build.ps1"

if ($DryRun) {
    Write-Host "  [DRY RUN] Would create $buildPs1" -ForegroundColor Gray
} else {
    # Read and modify the build script
    $buildScript = Get-Content $fixedBuildPs1 -Raw
    # Replace references to moq-gst-fixed with moq-gst
    $buildScript = $buildScript -replace "moq-gst-fixed", "moq-gst"
    Set-Content -Path $buildPs1 -Value $buildScript -NoNewline
    Write-Host "  build.ps1 created" -ForegroundColor Green
}
Write-Host ""

# Step 5: Copy documentation
Write-Host "Step 5: Copying documentation..." -ForegroundColor Yellow
$docsToCopy = @(
    "WINDOWS_BUILD_ISSUE.md"
)

foreach ($doc in $docsToCopy) {
    $srcDoc = Join-Path $fixedDir $doc
    $dstDoc = Join-Path $repoDir $doc
    
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would copy $doc" -ForegroundColor Gray
    } else {
        if (Test-Path $srcDoc) {
            Copy-Item -Path $srcDoc -Destination $dstDoc -Force
            Write-Host "  Copied $doc" -ForegroundColor Green
        } else {
            Write-Host "  Warning: $doc not found in fixed directory" -ForegroundColor Yellow
        }
    }
}
Write-Host ""

# Summary
Write-Host "=== Summary ===" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "DRY RUN: No changes were made" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Gray
} else {
    Write-Host "Fixes applied successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Review the changes in moq-gst-repo" -ForegroundColor Gray
    Write-Host "  2. Push to GitHub: See PUSH_TO_GITHUB.md for quick guide" -ForegroundColor Gray
    Write-Host "  3. GitHub Actions will build automatically on Linux!" -ForegroundColor Green
    Write-Host "  4. Or test locally: cd moq-gst-repo && cargo build" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Backup location: $backupDir" -ForegroundColor Gray
}

