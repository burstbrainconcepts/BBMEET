$ServerIP = "3.211.71.16"
$User = "ec2-user"
$Key = "bb-sdk-keypair.pem"

Write-Host "Adding CORS headers to Nginx..." -ForegroundColor Cyan

$remoteScript = @"
    set -e
    echo "Updating Nginx configuration to add CORS headers..."

    sudo tee /etc/nginx/conf.d/api.bbmeet.site.conf > /dev/null <<'EOF'
server {
    server_name api.bbmeet.site;

    location / {
        # Handle preflight requests
        if (`$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '`$http_origin' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, PATCH, DELETE, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, api-key, Accept' always;
            add_header 'Access-Control-Allow-Credentials' 'true' always;
            add_header 'Access-Control-Max-Age' 86400 always;
            add_header 'Content-Length' 0;
            return 204;
        }

        # Add CORS headers to all responses
        add_header 'Access-Control-Allow-Origin' '`$http_origin' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, PATCH, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, api-key, Accept' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;

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

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/api.bbmeet.site/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/api.bbmeet.site/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    if (`$host = api.bbmeet.site) {
        return 301 https://`$host`$request_uri;
    } # managed by Certbot

    server_name api.bbmeet.site;
    listen 80;
    return 404; # managed by Certbot
}
EOF

    echo "Testing Nginx configuration..."
    sudo nginx -t

    echo "Reloading Nginx..."
    sudo systemctl reload nginx

    echo "Nginx CORS configuration updated successfully!"
"@

Set-Content -Path "update_nginx_cors.sh" -Value $remoteScript -Encoding ASCII
(Get-Content "update_nginx_cors.sh" -Raw) -replace "`r`n", "`n" | Set-Content "update_nginx_cors.sh" -NoNewline

scp -i $Key -o StrictHostKeyChecking=no update_nginx_cors.sh "${User}@${ServerIP}:/home/${User}/"
ssh -i $Key -o StrictHostKeyChecking=no "${User}@${ServerIP}" "bash update_nginx_cors.sh"

Remove-Item "update_nginx_cors.sh" -ErrorAction SilentlyContinue
