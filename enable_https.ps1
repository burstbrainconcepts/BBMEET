$remoteScript = @"
    set -e
    echo "Starting SSL Setup on Amazon Linux 2023..."

    # 1. Install Nginx and Augeas
    echo "Installing Nginx and Augeas..."
    sudo dnf install -y nginx augeas-libs

    # 2. Start Nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx

    # 3. Install Certbot via pip (Recommended for AL2023)
    echo "Installing Certbot..."
    sudo dnf remove -y certbot || true
    sudo python3 -m venv /opt/certbot/
    sudo /opt/certbot/bin/pip install --upgrade pip
    sudo /opt/certbot/bin/pip install certbot certbot-nginx
    sudo ln -fs /opt/certbot/bin/certbot /usr/bin/certbot

    # 4. Create Nginx Configuration for api.bbmeet.site
    echo "Configuring Nginx..."
    sudo tee /etc/nginx/conf.d/api.bbmeet.site.conf > /dev/null <<'EOF'
server {
    server_name api.bbmeet.site;

    location / {
        proxy_pass http://127.0.0.1:5985;
        proxy_http_version 1.1;
        proxy_set_header Upgrade `$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
        proxy_cache_bypass `$http_upgrade;
    }
}
EOF

    # 5. Reload Nginx to apply config
    sudo systemctl reload nginx

    # 6. Request SSL Certificate
    echo "Requesting SSL Certificate..."
    # Using --nginx plugin, non-interactive, agreeing to TOS
    # Replace email with a generic admin email or prompt user? Using admin@bbmeet.site for now.
    sudo certbot --nginx -d api.bbmeet.site -m admin@bbmeet.site --agree-tos -n --redirect

    echo "SSL Setup Complete!"
"@

# Save locally to upload
Set-Content -Path "setup_ssl.sh" -Value $remoteScript -Encoding ASCII
(Get-Content "setup_ssl.sh" -Raw) -replace "`r`n", "`n" | Set-Content "setup_ssl.sh" -NoNewline

# Upload and Execute
Write-Host "Uploading SSL setup script..." -ForegroundColor Cyan
scp -i bb-sdk-keypair.pem -o StrictHostKeyChecking=no setup_ssl.sh ec2-user@3.211.71.16:/home/ec2-user/

Write-Host "Executing SSL setup on remote server..." -ForegroundColor Cyan
ssh -i bb-sdk-keypair.pem -o StrictHostKeyChecking=no ec2-user@3.211.71.16 "bash setup_ssl.sh"

if ($LASTEXITCODE -eq 0) {
    Write-Host "HTTPS Enabled Successfully!" -ForegroundColor Green
    Write-Host "Verify at: https://api.bbmeet.site" -ForegroundColor Green
} else {
    Write-Host "SSL Setup Failed." -ForegroundColor Red
}
