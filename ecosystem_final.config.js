module.exports = {
    apps: [
        {
            name: 'bb.meet.server.api',
            script: 'dist/main.js',
            instances: 1,
            exec_mode: 'cluster',
            autorestart: true,
            watch: false,
            max_memory_restart: '3G',
            env: {
                NODE_ENV: 'production',
                NODE_TLS_REJECT_UNAUTHORIZED: '0',
                // Application port
                APP_PORT: '5985',
                PORT: '5985',
                // Database
                DATABASE_TYPE: 'postgres',
                DATABASE_URL: 'postgres://bbadmin:Princesali1@bb-sdk-postgres.cwn4uam28ybs.us-east-1.rds.amazonaws.com:5432/bbsdk?ssl=true',
                DATABASE_SSL_ENABLED: 'true',
                DATABASE_REJECT_UNAUTHORIZED: 'false',
                // Redis
                REDIS_HOST: 'bb-sdk-api-redis.danby6.0001.use1.cache.amazonaws.com',
                REDIS_PORT: '6379',
                // Auth
                AUTH_JWT_SECRET: 'bbmeet-jwt-secret-key-change-me-securely',
                AUTH_JWT_TOKEN_EXPIRES_IN: '7d',
                AUTH_REFRESH_SECRET: 'bbmeet-refresh-secret-key-change-me-securely',
                AUTH_REFRESH_TOKEN_EXPIRES_IN: '30d',
                API_KEY: 'bbmeet-general-api-key',
                // Typesense dummy
                TYPESENSE_API_KEY: 'dummy-key',
                TYPESENSE_HOST: 'localhost',
                TYPESENSE_PORT: '8108',
                // App config
                API_PREFIX: 'api',
                // gRPC Microservices
                AUTH_GRPC_URL: '0.0.0.0:51054',
                WHITE_BOARD_GRPC_URL: '0.0.0.0:51055',
                MEETING_GRPC_URL: '0.0.0.0:51056',
                RECORD_GRPC_URL: '0.0.0.0:51057',
                WEBSOCKET_GRPC_ADDRESS: '0.0.0.0:51058'
            },
            error_file: '/home/ec2-user/bb-sdk-api/logs/error.log',
            out_file: '/home/ec2-user/bb-sdk-api/logs/out.log',
        },
    ],
};
