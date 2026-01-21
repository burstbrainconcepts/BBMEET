# Create Swap File Script
# 1. Create a 2GB file for swap
sudo dd if=/dev/zero of=/swapfile bs=128M count=16

# 2. Set permissions
sudo chmod 600 /swapfile

# 3. Setup swap area
sudo mkswap /swapfile

# 4. Enable swap
sudo swapon /swapfile

# 5. Verify
free -m

# 6. Retry Build
cd /home/ec2-user/bb-sdk-api
rm -rf dist
yarn build

# 7. Start PM2
pm2 start ecosystem.config.js
pm2 save
