# Use the official Home Assistant base image
ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

# Install dependencies
RUN apk add --no-cache \
    ca-certificates \
    wget \
    jq \
    && wget -q https://downloads.rclone.org/rclone-current-linux-amd64.zip \
    && unzip rclone-current-linux-amd64.zip \
    && mv rclone-*-linux-amd64/rclone /usr/bin/ \
    && rm -rf rclone-*-linux-amd64 rclone-current-linux-amd64.zip \
    && chmod +x /usr/bin/rclone

# Copy run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Copy example config
COPY rclone.conf.example /rclone.conf.example

# Define entrypoint
ENTRYPOINT ["/run.sh"]