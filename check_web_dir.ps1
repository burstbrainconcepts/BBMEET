$ServerIP = "3.211.71.16"
$User = "ec2-user"
$Key = "bb-sdk-keypair.pem"

Write-Host "Checking /var/www/bbmeet.site on $ServerIP..." -ForegroundColor Cyan

$commands = "ls -la /var/www/bbmeet.site"

ssh -i $Key -o StrictHostKeyChecking=no "${User}@${ServerIP}" $commands
