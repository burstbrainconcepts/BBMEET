# Deploy Media Server Components to ECS (Fargate)

$CLUSTER_NAME = "bbmeet-cluster"
$REGION = "us-east-1"
$SFU_TASK_FAMILY = "bbmeet-sfu-task"
$SIG_TASK_FAMILY = "bbmeet-signalling-task"

# 1. Register Task Definitions
Write-Host "Registering SFU Task Definition..."
aws ecs register-task-definition --cli-input-json file://infrastructure/task-definition-sfu.json --region $REGION

Write-Host "Registering Signalling Task Definition..."
aws ecs register-task-definition --cli-input-json file://infrastructure/task-definition-signalling.json --region $REGION

# 2. Get Security Group and Subnets (Assuming these exist from previous setup)
# We'll fetch the ID of the 'bb-sdk-media-sg' or similar
$MEDIA_SG_ID = aws ec2 describe-security-groups --filters Name=group-name,Values=bb-sdk-media-sg --query "SecurityGroups[0].GroupId" --output text --region $REGION
if ($MEDIA_SG_ID -eq "None") {
    Write-Host "Error: Security Group bb-sdk-media-sg not found. Please create it or check the name."
    exit 1
}

# Get Public Subnets (assuming we want to deploy in public for SFU)
$SUBNET_ID = aws ec2 describe-subnets --filters "Name=tag:Name,Values=*public*" --query "Subnets[0].SubnetId" --output text --region $REGION

if ($SUBNET_ID -eq "None") {
    Write-Host "Error: No public subnet found."
    exit 1
}

Write-Host "Using Security Group: $MEDIA_SG_ID"
Write-Host "Using Subnet: $SUBNET_ID"

# 3. Create or Update Services

# --- SFU Service ---
Write-Host "Checking bbmeet-sfu-service..."
$SFU_SERVICE = aws ecs describe-services --cluster $CLUSTER_NAME --services bbmeet-sfu-service --query "services[0].status" --output text --region $REGION

if ($SFU_SERVICE -eq "ACTIVE") {
    Write-Host "Updating SFU Service..."
    aws ecs update-service --cluster $CLUSTER_NAME --service bbmeet-sfu-service --task-definition $SFU_TASK_FAMILY --region $REGION
} else {
    Write-Host "Creating SFU Service..."
    aws ecs create-service `
        --cluster $CLUSTER_NAME `
        --service-name bbmeet-sfu-service `
        --task-definition $SFU_TASK_FAMILY `
        --launch-type FARGATE `
        --desired-count 1 `
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$MEDIA_SG_ID],assignPublicIp=ENABLED}" `
        --region $REGION
}

# --- Signalling Service ---
Write-Host "Checking bbmeet-signalling-service..."
$SIG_SERVICE = aws ecs describe-services --cluster $CLUSTER_NAME --services bbmeet-signalling-service --query "services[0].status" --output text --region $REGION

if ($SIG_SERVICE -eq "ACTIVE") {
    Write-Host "Updating Signalling Service..."
    aws ecs update-service --cluster $CLUSTER_NAME --service bbmeet-signalling-service --task-definition $SIG_TASK_FAMILY --region $REGION
} else {
    Write-Host "Creating Signalling Service..."
    aws ecs create-service `
        --cluster $CLUSTER_NAME `
        --service-name bbmeet-signalling-service `
        --task-definition $SIG_TASK_FAMILY `
        --launch-type FARGATE `
        --desired-count 1 `
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$MEDIA_SG_ID],assignPublicIp=ENABLED}" `
        --region $REGION
}

Write-Host "Deployment commands sent. Check ECS Console for status."
