$ServerIP = "3.211.71.16"
$User = "ec2-user"
$Key = "bb-sdk-keypair.pem"

Write-Host "Fixing SSL for bbmeet.site on $ServerIP..." -ForegroundColor Cyan

# We escape $uri as `$uri so PowerShell doesn't interpolate it, but sends $uri to the shell
$remoteScript = @"
    set -e
    echo "Configuring Nginx for bbmeet.site..."

    # Ensure web root exists
    sudo mkdir -p /var/www/bbmeet.site
    sudo chown -R nginx:nginx /var/www/bbmeet.site

    # Create Nginx Config
    # using simple cat with redirect instead of tee/heredoc inside heredoc to avoid complexity
    echo 'server {
        server_name bbmeet.site www.bbmeet.site;
        root /var/www/bbmeet.site;
        index index.html;

        location / {
            try_files `$uri `$uri/ /index.html;
        }
    }' | sudo tee /etc/nginx/conf.d/bbmeet.site.conf > /dev/null

    # Reload Nginx
    echo "Reloading Nginx..."
    sudo systemctl reload nginx

    # Certbot
    echo "Running Certbot..."
    # We use --expand to add to existing certificates or create new if unrelated. 
    # Actually, usually better to keep separate certs if possible, but --expand manages lineages well.
    # Since api.bbmeet.site works, we definitely don't want to break it.
    # We will just request a NEW cert for these domains. Nginx plugin handles the config update.
    sudo certbot --nginx -d bbmeet.site -d www.bbmeet.site --agree-tos -m admin@bbmeet.site -n --redirect

    echo "Fix Complete!"
"@

# Save locally, fix line endings, upload, and run
Set-Content -Path "fix_ssl_remote.sh" -Value $remoteScript -Encoding ASCII
(Get-Content "fix_ssl_remote.sh" -Raw) -replace "`r`n", "`n" | Set-Content "fix_ssl_remote.sh" -NoNewline

scp -i $Key -o StrictHostKeyChecking=no fix_ssl_remote.sh "${User}@${ServerIP}:/home/${User}/"
ssh -i $Key -o StrictHostKeyChecking=no "${User}@${ServerIP}" "bash fix_ssl_remote.sh"

Remove-Item "fix_ssl_remote.sh" -ErrorAction SilentlyContinue
