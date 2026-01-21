# Api Server Setup Script
# Run these commands one block at a time

# 1. Gain root access and update
sudo su
dnf update -y
dnf install -y git

# 2. Setup Swap (Crucial for build)
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# 3. Install Node/Yarn/PM2
npm install -g yarn pm2 @nestjs/cli

# 4. Prepare Directory
cd /home/ec2-user
rm -rf bb-sdk-api
tar -xzf bb-sdk-api.tar.gz
cd bb-sdk-api

# 5. Build
yarn install
yarn build

# 6. Create Configuration
cat > .env << EOL
PORT=5985
GRPC_PORT=50054
DATABASE_URL=postgres://bbadmin:Princesali1@bb-sdk-postgres.cwn4uam28ybs.us-east-1.rds.amazonaws.com:5432/bbsdk
REDIS_HOST=bb-sdk-api-redis.danby6.0001.use1.cache.amazonaws.com
REDIS_PORT=6379
JWT_SECRET=waterbus-secret-key-change-me
EOL

# 7. Start
pm2 start ecosystem.config.js
pm2 save
pm2 startup
