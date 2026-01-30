# Build script for moq-gst-fixed on Windows
# Sets required environment variables for aws-lc-sys compilation
# 
# Issue: aws-lc-sys requires C11 but defaults to C99 on Windows MSVC
# Solution: Override CFLAGS to use C11 standard

Write-Host "Setting up build environment for moq-gst-fixed..." -ForegroundColor Cyan

# Set CMAKE path if not already set
if (-not $env:CMAKE) {
    $cmakePath = "C:\Program Files\CMake\bin\cmake.exe"
    if (Test-Path $cmakePath) {
        $env:CMAKE = $cmakePath
        Write-Host "Set CMAKE to: $cmakePath" -ForegroundColor Green
    } else {
        Write-Host "Warning: CMake not found at expected path" -ForegroundColor Yellow
    }
}

# Override CFLAGS to use C11 instead of C99
# aws-lc-sys build script sets -std:c99, but we need -std:c11 for C atomics
# Setting AWS_LC_SYS_CFLAGS will override the internal CFLAGS
$env:AWS_LC_SYS_CFLAGS = "-std:c11"

# Also set general CFLAGS as fallback
# Note: The build script may append to this, so we need to ensure C11 is used
if ($env:CFLAGS) {
    # Remove any existing -std:c99 and add -std:c11
    $env:CFLAGS = $env:CFLAGS -replace "-std:c99", "-std:c11"
    if (-not $env:CFLAGS.Contains("-std:c11")) {
        $env:CFLAGS = "$env:CFLAGS -std:c11"
    }
} else {
    $env:CFLAGS = "-std:c11"
}

Write-Host "Environment variables set:" -ForegroundColor Green
Write-Host "  AWS_LC_SYS_CFLAGS = $env:AWS_LC_SYS_CFLAGS" -ForegroundColor Yellow
Write-Host "  CFLAGS = $env:CFLAGS" -ForegroundColor Yellow
if ($env:CMAKE) {
    Write-Host "  CMAKE = $env:CMAKE" -ForegroundColor Yellow
}

Write-Host "`nBuilding moq-gst-fixed..." -ForegroundColor Cyan
Write-Host "Note: This may take several minutes, especially on first build..." -ForegroundColor Gray

# Change to the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $scriptDir

try {
    cargo build
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nBuild successful!" -ForegroundColor Green
    } else {
        Write-Host "`nBuild failed with exit code $LASTEXITCODE" -ForegroundColor Red
        Write-Host "`nTroubleshooting tips:" -ForegroundColor Yellow
        Write-Host "  1. Ensure Visual Studio Build Tools are installed" -ForegroundColor Gray
        Write-Host "  2. Ensure CMake is in PATH or set CMAKE environment variable" -ForegroundColor Gray
        Write-Host "  3. Try running from a Visual Studio Developer Command Prompt" -ForegroundColor Gray
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}

