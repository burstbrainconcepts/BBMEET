# PowerShell Script to Deploy Flutter Web App to EC2

$ServerIP = "3.211.71.16"
$User = "ec2-user"
$Key = "bb-sdk-keypair.pem"
$LocalBuildPath = "build\web"
$RemotePath = "/home/$User/web-deploy"
$WebRoot = "/var/www/bbmeet.site"

# 1. Check if build exists
if (-not (Test-Path "$LocalBuildPath\index.html")) {
    Write-Host "Error: build/web/index.html not found!" -ForegroundColor Red
    Write-Host "Please run: flutter build web --release" -ForegroundColor Yellow
    exit 1
}

# 2. Archive the build
Write-Host "Archiving web build..." -ForegroundColor Cyan
Compress-Archive -Path "$LocalBuildPath\*" -DestinationPath "web-deploy.zip" -Force

# 3. Upload
Write-Host "Uploading to EC2..." -ForegroundColor Cyan
scp -i $Key -o StrictHostKeyChecking=no web-deploy.zip "${User}@${ServerIP}:/home/${User}/"

# 4. Remote Script for Nginx & SSL
$remoteScript = @"
    set -e
    echo "Starting Web Deployment..."

    # Prepare Web Root
    sudo mkdir -p $WebRoot
    sudo rm -rf $WebRoot/*
    
    # Extract
    sudo rm -rf web-deploy
    mkdir -p web-deploy
    sudo unzip -o web-deploy.zip -d web-deploy
    sudo cp -r web-deploy/* $WebRoot/
    sudo rm -rf web-deploy web-deploy.zip
    sudo chown -R nginx:nginx $WebRoot
    sudo chmod -R 755 $WebRoot

    # Configure Nginx for SPA (Single Page App)
    echo "Configuring Nginx..."
    sudo tee /etc/nginx/conf.d/bbmeet.site.conf > /dev/null <<'EOF'
server {
    server_name bbmeet.site www.bbmeet.site;
    root /var/www/bbmeet.site;
    index index.html;

    location / {
        try_files `$uri `$uri/ /index.html;
    }
}
EOF

    # Reload Nginx
    sudo systemctl reload nginx

    # SSL Cert (Certbot)
    echo "Requesting SSL..."
    # Check if cert already exists to avoid rate limits/errors?
    # --expand allows adding subdomains or updating
    sudo certbot --nginx -d bbmeet.site -d www.bbmeet.site --agree-tos -m admin@bbmeet.site -n --redirect --expand

    echo "Web Deployment Complete!"
"@

# Save and upload remote script
Set-Content -Path "setup_web.sh" -Value $remoteScript -Encoding ASCII
(Get-Content "setup_web.sh" -Raw) -replace "`r`n", "`n" | Set-Content "setup_web.sh" -NoNewline
scp -i $Key -o StrictHostKeyChecking=no setup_web.sh "${User}@${ServerIP}:/home/${User}/"

# 5. Execute Remote
Write-Host "Executing remote setup..." -ForegroundColor Cyan
ssh -i $Key -o StrictHostKeyChecking=no "${User}@${ServerIP}" "bash setup_web.sh"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nSUCCESS! Web App Deployed." -ForegroundColor Green
    Write-Host "Visit: https://bbmeet.site" -ForegroundColor Green
} else {
    Write-Host "Deployment Failed." -ForegroundColor Red
}

# Cleanup
Remove-Item "web-deploy.zip" -ErrorAction SilentlyContinue
Remove-Item "setup_web.sh" -ErrorAction SilentlyContinue
