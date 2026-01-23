# BB SDK Media Server

WebRTC SFU (Selective Forwarding Unit) and Signalling server for BB Meet.

## Building

```bash
cargo build --release
```

This will produce two binaries:
- `target/release/signalling` - WebRTC signalling server
- `target/release/sfu` - WebRTC SFU server

## Running

```bash
# Start signalling server
./target/release/signalling

# Start SFU server
./target/release/sfu
```

## Environment Variables

Create a `.env` file with:

```env
APP_PORT=5998
DATABASE_URL=postgresql://user:pass@host:5432/dbname
REDIS_URIS=redis://host:6379
PUBLIC_IP=your-public-ip
```

## TODO

This is a skeleton structure. You need to implement:
- WebSocket server for signalling
- WebRTC peer connection handling
- Media routing and simulcast
- Database integration
- Redis integration
- etcd clustering

