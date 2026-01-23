use anyhow::Result;
use tracing::{info, error};

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    info!("Starting BB Meet Signalling Server...");
    
    // TODO: Initialize WebSocket server
    // TODO: Handle WebRTC signalling
    // TODO: Connect to database/Redis
    
    info!("Signalling server started on port 5998");
    
    // Keep the server running
    tokio::signal::ctrl_c().await?;
    
    info!("Shutting down signalling server...");
    Ok(())
}

