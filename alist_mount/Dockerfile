FROM alpine:3.18

# Install davfs2, fuse, jq, and dependencies
RUN apk add --no-cache davfs2 fuse bash jq

# Create mount point directory
RUN mkdir -p /data/mount

# Copy run script
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Set entrypoint
ENTRYPOINT ["/run.sh"]