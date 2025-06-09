FROM alpine:3.18

# Install davfs2 and dependencies
RUN apk add --no-cache davfs2 bash

# Create mount point directory
RUN mkdir -p /data/mount

# Copy run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Set entrypoint
ENTRYPOINT ["/run.sh"]