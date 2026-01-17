# Hytale Docker Server

Docker image for running a Hytale dedicated server with automatic file downloads and updates.

## Quick Start

```bash
docker run -d \
  --name hytale-server \
  -p 5520:5520/udp \
  -v ./data:/app/data \
  -e HYTALE_MEMORY=4G \
  ghcr.io/ericbriscoe/hytale-docker-server:latest
```

## First Run Authentication

The server requires two authentication steps on first run:

1. **Downloader auth** - Watch logs for the authentication URL:
   ```bash
   docker logs -f hytale-server
   ```

2. **Server auth** - After files download, authenticate the server by typing `/auth login device` in the console

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HYTALE_MEMORY` | `4G` | JVM heap size (-Xms/-Xmx) |
| `HYTALE_PORT` | `5520` | Server port (UDP) |
| `HYTALE_VIEW_DISTANCE` | `12` | View distance in chunks |
| `HYTALE_AUTH_MODE` | `authenticated` | Auth mode |
| `HYTALE_BACKUP_ENABLED` | `false` | Enable automatic backups |
| `HYTALE_BACKUP_FREQUENCY` | `30` | Backup interval in minutes |
| `HYTALE_AUTO_UPDATE` | `true` | Auto-update server files on restart |
| `TZ` | `UTC` | Timezone |

## Volumes

| Path | Description |
|------|-------------|
| `/app/data` | Server files, world data, configs |

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 5520 | **UDP** | Game server (QUIC protocol) |

**Important:** Hytale uses QUIC over UDP, not TCP. Ensure your firewall and port forwarding are configured for UDP.

## Docker Compose

```yaml
services:
  hytale-server:
    image: ghcr.io/ericbriscoe/hytale-docker-server:latest
    container_name: hytale-server
    restart: unless-stopped
    stop_grace_period: 2m
    ports:
      - "5520:5520/udp"
    environment:
      - HYTALE_MEMORY=8G
      - HYTALE_VIEW_DISTANCE=12
      - TZ=America/Chicago
    volumes:
      - ./data:/app/data
```

## File Structure

After first run, the data volume contains:

```
data/
├── server/
│   ├── HytaleServer.jar
│   ├── HytaleServer.aot
│   ├── Assets.zip
│   ├── config.json
│   ├── permissions.json
│   ├── universe/
│   ├── mods/
│   └── logs/
└── .hytale-downloader/
```

## Building

```bash
docker build -t hytale-server .
```
