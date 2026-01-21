$ServerIP = "3.211.71.16"
$User = "ec2-user"
$Key = "bb-sdk-keypair.pem"

Write-Host "Manually completing web deployment..." -ForegroundColor Cyan

$remoteScript = @"
    set -e
    cd /home/ec2-user
    
    # Check if web-deploy exists
    if [ -d "web-deploy" ]; then
        echo "Copying files to /var/www/bbmeet.site..."
        sudo rm -rf /var/www/bbmeet.site/*
        sudo cp -r web-deploy/* /var/www/bbmeet.site/
        sudo chown -R nginx:nginx /var/www/bbmeet.site
        sudo chmod -R 755 /var/www/bbmeet.site
        echo "Files copied successfully!"
        ls -la /var/www/bbmeet.site | head -10
    else
        echo "No web-deploy directory found, checking for zip..."
        if [ -f "web-deploy.zip" ]; then
            echo "Extracting and copying..."
            mkdir -p web-deploy
            unzip -o web-deploy.zip -d web-deploy
            sudo rm -rf /var/www/bbmeet.site/*
            sudo cp -r web-deploy/* /var/www/bbmeet.site/
            sudo chown -R nginx:nginx /var/www/bbmeet.site
            sudo chmod -R 755 /var/www/bbmeet.site
            echo "Done!"
        else
            echo "Neither web-deploy nor web-deploy.zip found!"
            exit 1
        fi
    fi
"@

Set-Content -Path "complete_deploy.sh" -Value $remoteScript -Encoding ASCII
(Get-Content "complete_deploy.sh" -Raw) -replace "`r`n", "`n" | Set-Content "complete_deploy.sh" -NoNewline

scp -i $Key -o StrictHostKeyChecking=no complete_deploy.sh "${User}@${ServerIP}:/home/${User}/"
ssh -i $Key -o StrictHostKeyChecking=no "${User}@${ServerIP}" "bash complete_deploy.sh"

Remove-Item "complete_deploy.sh" -ErrorAction SilentlyContinue
