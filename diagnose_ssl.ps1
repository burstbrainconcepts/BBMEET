$ServerIP = "3.211.71.16"
$User = "ec2-user"
$Key = "bb-sdk-keypair.pem"

Write-Host "Running SSL Diagnostics on $ServerIP..." -ForegroundColor Cyan

$commands = @"
    echo '--- Nginx Config Test ---'
    sudo nginx -t
    echo '--- Certbot Certificates ---'
    sudo certbot certificates
    echo '--- Nginx Conf Directory ---'
    ls -l /etc/nginx/conf.d/
    echo '--- bbmeet.site Conf Content ---'
    cat /etc/nginx/conf.d/bbmeet.site.conf || echo "File not found"
"@

ssh -i $Key -o StrictHostKeyChecking=no "${User}@${ServerIP}" $commands
