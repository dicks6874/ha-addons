FROM alpine:3.18

# Install rclone, jq, and dependencies
RUN apk add --no-cache bash jq \
 && apk add --no-cache --virtual .build-deps curl \
 && curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip \
 && unzip rclone-current-linux-amd64.zip \
 && mv rclone-*/rclone /usr/bin/ \
 && rm -rf rclone-current-linux-amd64.zip rclone-* \
 && apk del .build-deps

# Create mount point directory
RUN mkdir -p /data/mount

# Copy run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Set entrypoint
ENTRYPOINT ["/run.sh"]ac