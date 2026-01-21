    set -e
    
    # Clean old directory
    rm -rf bb-sdk-api
    mkdir -p bb-sdk-api
    mkdir -p bb-sdk-api/logs
    
    # Extract
    tar -xzf bb-sdk-api.tar.gz -C bb-sdk-api
    rm bb-sdk-api.tar.gz
    cd bb-sdk-api
    
    # Install dependencies and build
    # Install Nest CLI locally if global fails or isn't desired, but global is usually fine.
    # Using sudo for global install
    sudo npm install -g pm2 @nestjs/cli
    
    npm install --legacy-peer-deps
    npm install -D @swc/cli @swc/core --legacy-peer-deps
    npm run build
    
    # Create .env file
    echo 'APP_PORT=5985' > .env
    echo 'GRPC_PORT=50054' >> .env
    
    # gRPC Microservice URLs (CRITICAL - prevents port 5000 conflict)
    echo 'AUTH_GRPC_URL=0.0.0.0:50051' >> .env
    echo 'WHITE_BOARD_GRPC_URL=0.0.0.0:50052' >> .env
    echo 'MEETING_GRPC_URL=0.0.0.0:50053' >> .env
    
    # Database
    echo 'DATABASE_TYPE=postgres' >> .env
    echo 'DATABASE_URL=postgres://bbadmin:Princesali1@bb-sdk-postgres.cwn4uam28ybs.us-east-1.rds.amazonaws.com:5432/bbsdk?ssl=true' >> .env
    echo 'DATABASE_SSL_ENABLED=true' >> .env
    echo 'DATABASE_REJECT_UNAUTHORIZED=false' >> .env
    echo 'NODE_TLS_REJECT_UNAUTHORIZED=0' >> .env
    echo 'DATABASE_SYNCHRONIZE=true' >> .env
    
    # RabbitMQ (Docker)
    echo 'RABBITMQ_HOST=localhost' >> .env
    echo 'RABBITMQ_PORT=5672' >> .env
    echo 'RABBITMQ_USER=guest' >> .env
    echo 'RABBITMQ_PASSWORD=guest' >> .env
    
    # Redis
    echo 'REDIS_HOST=bb-sdk-api-redis.danby6.0001.use1.cache.amazonaws.com' >> .env
    echo 'REDIS_PORT=6379' >> .env
    
    # Auth Configuration
    echo 'AUTH_JWT_SECRET=bbmeet-jwt-secret-key-change-me-securely' >> .env
    echo 'AUTH_JWT_TOKEN_EXPIRES_IN=7d' >> .env
    echo 'AUTH_REFRESH_SECRET=bbmeet-refresh-secret-key-change-me-securely' >> .env
    echo 'AUTH_REFRESH_TOKEN_EXPIRES_IN=30d' >> .env
    echo 'API_KEY=bbmeet-general-api-key' >> .env
    
    # Typesense (Dummy values)
    echo 'TYPESENSE_API_KEY=dummy-key' >> .env
    echo 'TYPESENSE_HOST=localhost' >> .env
    echo 'TYPESENSE_PORT=8108' >> .env
    
    # Legacy / Other
    echo 'JWT_SECRET=bbmeet-jwt-secret-key-change-me-securely' >> .env
    
    # Ensure RabbitMQ is running (Docker)
    if [ ! "$(docker ps -q -f name=rabbitmq)" ]; then
        if [ "$(docker ps -aq -f name=rabbitmq)" ]; then
            echo "Starting existing rabbitmq container..."
            docker start rabbitmq
        else
            echo "Creating and starting new rabbitmq container..."
            docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 --restart always rabbitmq:3-management
        fi
    fi

    # Start with PM2 (using the ecosystem.config.js we just copied into the archive)
    pm2 delete bb.meet.server.api || true
    pm2 start ecosystem.config.js
    pm2 save
    
    # Setup startup hook
    pm2 startup systemd -u ec2-user --hp /home/ec2-user | grep 'sudo' | bash
    pm2 save
