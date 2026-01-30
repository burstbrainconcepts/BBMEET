@echo off
:: Batch script to create all SSM parameters for BBMEET

echo Creating API SSM Parameters...

:: String parameters
aws ssm put-parameter --name "/bbmeet/production/api/DATABASE_SSL_ENABLED" --value "true" --type String --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/DATABASE_REJECT_UNAUTHORIZED" --value "false" --type String --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/DATABASE_SYNCHRONIZE" --value "true" --type String --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/GRPC_PORT" --value "50054" --type String --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/AUTH_GRPC_URL" --value "0.0.0.0:50051" --type String --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/WHITE_BOARD_GRPC_URL" --value "0.0.0.0:50052" --type String --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/MEETING_GRPC_URL" --value "0.0.0.0:50053" --type String --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/RABBITMQ_HOST" --value "localhost" --type String --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/RABBITMQ_PORT" --value "5672" --type String --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/RABBITMQ_USER" --value "guest" --type String --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/REDIS_HOST" --value "bb-sdk-api-redis.danby6.0001.use1.cache.amazonaws.com" --type String --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/REDIS_PORT" --value "6379" --type String --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/AUTH_JWT_TOKEN_EXPIRES_IN" --value "7d" --type String --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/AUTH_REFRESH_TOKEN_EXPIRES_IN" --value "30d" --type String --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/TYPESENSE_HOST" --value "localhost" --type String --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/TYPESENSE_PORT" --value "8108" --type String --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/WEBSOCKET_GRPC_ADDRESS" --value "10.0.1.248:50052" --type String --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/RECORD_GRPC_URL" --value "10.0.1.248:50051" --type String --overwrite

:: SecureString parameters (secrets)
aws ssm put-parameter --name "/bbmeet/production/api/RABBITMQ_PASSWORD" --value "guest" --type SecureString --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/AUTH_JWT_SECRET" --value "bbmeet-jwt-secret-key-change-me-securely" --type SecureString --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/AUTH_REFRESH_SECRET" --value "bbmeet-refresh-secret-key-change-me-securely" --type SecureString --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/API_KEY" --value "bbmeet-general-api-key" --type SecureString --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/TYPESENSE_API_KEY" --value "dummy-key" --type SecureString --overwrite
aws ssm put-parameter --name "/bbmeet/production/api/JWT_SECRET" --value "bbmeet-jwt-secret-key-change-me-securely" --type SecureString --overwrite

echo Done creating API parameters!
echo.
echo Verifying parameters...
aws ssm get-parameters-by-path --path "/bbmeet/production/api/" --query "Parameters[*].Name" --output table
