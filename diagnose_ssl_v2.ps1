$ServerIP = "3.211.71.16"
$User = "ec2-user"
$Key = "bb-sdk-keypair.pem"

Write-Host "Running SSL Diagnostics on $ServerIP..." -ForegroundColor Cyan

$remoteScript = @"
echo '--- Nginx Config Test ---'
sudo nginx -t
echo '--- Certbot Version ---'
certbot --version
echo '--- Certbot Certificates ---'
sudo certbot certificates
echo '--- Nginx Conf Directory ---'
ls -l /etc/nginx/conf.d/
echo '--- bbmeet.site Conf Content ---'
cat /etc/nginx/conf.d/bbmeet.site.conf || echo "File not found"
"@

# Save locally, fix line endings, upload, and run
Set-Content -Path "diagnose.sh" -Value $remoteScript -Encoding ASCII
(Get-Content "diagnose.sh" -Raw) -replace "`r`n", "`n" | Set-Content "diagnose.sh" -NoNewline

scp -i $Key -o StrictHostKeyChecking=no diagnose.sh "${User}@${ServerIP}:/home/${User}/"
ssh -i $Key -o StrictHostKeyChecking=no "${User}@${ServerIP}" "bash diagnose.sh"

Remove-Item "diagnose.sh" -ErrorAction SilentlyContinue
