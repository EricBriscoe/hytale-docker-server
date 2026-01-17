#!/bin/bash
set -e

DATA_DIR="/app/data"
SERVER_DIR="$DATA_DIR/server"
DOWNLOADER_DIR="$DATA_DIR/downloader"

mkdir -p "$SERVER_DIR" "$DOWNLOADER_DIR"

export HOME="$DATA_DIR"
export XDG_DATA_HOME="$DATA_DIR"

cd "$SERVER_DIR"

echo "=========================================="
echo "Hytale Docker Server"
echo "Memory: $HYTALE_MEMORY"
echo "Port: $HYTALE_PORT/UDP"
echo "View Distance: $HYTALE_VIEW_DISTANCE"
echo "=========================================="

install_downloader() {
    if [ -f "$DOWNLOADER_DIR/hytale-downloader" ]; then
        echo "hytale-downloader already installed."
        return 0
    fi

    echo "Installing hytale-downloader..."

    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH_SUFFIX="amd64" ;;
        aarch64) ARCH_SUFFIX="arm64" ;;
        *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
    esac

    DOWNLOAD_URL="https://github.com/decomp-project/hytale-downloader/releases/latest/download/hytale-downloader-linux-${ARCH_SUFFIX}"

    echo "Downloading from: $DOWNLOAD_URL"
    curl -L -o "$DOWNLOADER_DIR/hytale-downloader" "$DOWNLOAD_URL" || {
        echo "Failed to download hytale-downloader. Trying alternative..."
        curl -L -o /tmp/hytale-downloader.zip "https://cdn.hytale.com/tools/hytale-downloader.zip" && \
        unzip -o /tmp/hytale-downloader.zip -d "$DOWNLOADER_DIR" && \
        rm /tmp/hytale-downloader.zip
    }

    chmod +x "$DOWNLOADER_DIR/hytale-downloader"
    echo "hytale-downloader installed successfully."
}

if [ ! -f "$SERVER_DIR/HytaleServer.jar" ] || [ "${HYTALE_AUTO_UPDATE:-true}" = "true" ]; then
    install_downloader

    echo ""
    echo "Running hytale-downloader to fetch/update server files..."
    echo "If this is first run, you'll need to authenticate via the URL below."
    echo ""

    "$DOWNLOADER_DIR/hytale-downloader" -download-path "$SERVER_DIR/game.zip" || {
        echo "Downloader failed. Checking for manually placed files..."
        if [ ! -f "$SERVER_DIR/HytaleServer.jar" ]; then
            echo "ERROR: No HytaleServer.jar found. Please complete authentication or place files manually."
            exit 1
        fi
    }

    if [ -f "$SERVER_DIR/game.zip" ]; then
        echo "Extracting server files..."
        unzip -o "$SERVER_DIR/game.zip" -d "$SERVER_DIR/extracted"

        if [ -d "$SERVER_DIR/extracted/Server" ]; then
            cp -f "$SERVER_DIR/extracted/Server/"* "$SERVER_DIR/" 2>/dev/null || true
        fi
        if [ -f "$SERVER_DIR/extracted/Assets.zip" ]; then
            cp -f "$SERVER_DIR/extracted/Assets.zip" "$SERVER_DIR/"
        fi

        rm -rf "$SERVER_DIR/extracted" "$SERVER_DIR/game.zip"
        echo "Server files extracted successfully."
    fi
fi

if [ ! -f "$SERVER_DIR/HytaleServer.jar" ]; then
    echo "ERROR: HytaleServer.jar not found after download attempt."
    exit 1
fi

if [ ! -f "$SERVER_DIR/Assets.zip" ]; then
    echo "ERROR: Assets.zip not found. Server cannot start without assets."
    exit 1
fi

JVM_OPTS="-Xms${HYTALE_MEMORY} -Xmx${HYTALE_MEMORY}"

if [ -f "$SERVER_DIR/HytaleServer.aot" ]; then
    echo "AOT cache found, enabling for faster startup..."
    JVM_OPTS="$JVM_OPTS -XX:AOTCache=HytaleServer.aot"
fi

SERVER_OPTS="--assets $SERVER_DIR/Assets.zip --bind 0.0.0.0:$HYTALE_PORT --auth-mode $HYTALE_AUTH_MODE"

if [ "$HYTALE_BACKUP_ENABLED" = "true" ]; then
    SERVER_OPTS="$SERVER_OPTS --backup --backup-frequency $HYTALE_BACKUP_FREQUENCY"
fi

if [ -n "$HYTALE_EXTRA_OPTS" ]; then
    SERVER_OPTS="$SERVER_OPTS $HYTALE_EXTRA_OPTS"
fi

shutdown_handler() {
    echo "Received shutdown signal, stopping server gracefully..."
    if [ -n "$SERVER_PID" ]; then
        kill -TERM "$SERVER_PID" 2>/dev/null
        wait "$SERVER_PID" 2>/dev/null
    fi
    exit 0
}

trap shutdown_handler SIGTERM SIGINT

echo ""
echo "Starting Hytale Server..."
echo "Command: java $JVM_OPTS -jar HytaleServer.jar $SERVER_OPTS"
echo ""
echo "NOTE: On first run, you'll need to authenticate the server."
echo "Watch the logs for: /auth login device"
echo "=========================================="

exec java $JVM_OPTS -jar HytaleServer.jar $SERVER_OPTS
