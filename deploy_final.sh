#!/bin/bash
set -e

# 1. Setup Swap (Just to be safe)
if [ ! -f /swapfile ]; then
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
fi
# Enable swap if not already enabled
grep -q '/swapfile' /proc/swaps || sudo swapon /swapfile

# 2. Install Tools
sudo npm install -g yarn pm2 @nestjs/cli

# 3. Setup Directory
rm -rf bb-sdk-api
mkdir -p bb-sdk-api
tar -xzf bb-sdk-api.tar.gz -C bb-sdk-api
cd bb-sdk-api

# 4. Install & Build
yarn install
yarn build

# 5. Config
cat > .env << EOL
PORT=5985
GRPC_PORT=50054
DATABASE_URL=postgres://bbadmin:Princesali1@bb-sdk-postgres.cwn4uam28ybs.us-east-1.rds.amazonaws.com:5432/bbsdk
REDIS_HOST=bb-sdk-api-redis.danby6.0001.use1.cache.amazonaws.com
REDIS_PORT=6379
JWT_SECRET=waterbus-secret-key-change-me
EOL

# 6. Start
pm2 start ecosystem.config.js
pm2 save
pm2 startup systemd -u ec2-user --hp /home/ec2-user | grep 'sudo' | bash
pm2 save
