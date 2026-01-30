#!/bin/bash
set -e

# Function to get public IP from ECS metadata or fallback to checkip
get_public_ip() {
    # Try ECS Metadata v4 first
    if [ -n "$ECS_CONTAINER_METADATA_URI_V4" ]; then
        IP=$(curl -s "$ECS_CONTAINER_METADATA_URI_V4" | jq -r '.Networks[0].IPv4Addresses[0]')
        if [ -n "$IP" ] && [ "$IP" != "null" ]; then
            echo "$IP"
            return
        fi
    fi

    # Fallback to external service
    curl -s --max-time 5 https://checkip.amazonaws.com
}

echo "Starting SFU Entrypoint..."

# Detect Public IP if not already set
if [ -z "$PUBLIC_IP" ]; then
    echo "Detecting Public IP..."
    DETECTED_IP=$(get_public_ip)
    
    if [ -n "$DETECTED_IP" ]; then
        export PUBLIC_IP="$DETECTED_IP"
        echo "Public IP detected: $PUBLIC_IP"
    else
        echo "WARNING: Could not detect Public IP. Defaulting to 0.0.0.0 or checking if running locally."
        # Don't fail, might be local testing
    fi
else
    echo "Public IP already set to: $PUBLIC_IP"
fi

# Execute the main command
exec "$@"
