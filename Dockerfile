FROM eclipse-temurin:25-jre

LABEL maintainer="Eric Briscoe"
LABEL org.opencontainers.image.source="https://github.com/ericbriscoe/hytale-docker-server"
LABEL org.opencontainers.image.description="Hytale Dedicated Server with auto-download"

ENV HYTALE_MEMORY=4G \
    HYTALE_PORT=5520 \
    HYTALE_VIEW_DISTANCE=12 \
    HYTALE_AUTH_MODE=authenticated \
    HYTALE_BACKUP_ENABLED=false \
    HYTALE_BACKUP_FREQUENCY=30 \
    TZ=UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME /app/data

EXPOSE 5520/udp

ENTRYPOINT ["/entrypoint.sh"]
