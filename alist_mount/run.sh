#!/bin/bash

# Read configuration from HAOS add-on options
WEBDAV_URL=$(jq -r '.webdav_url' /data/options.json)
USERNAME=$(jq -r '.username' /data/options.json)
PASSWORD=$(jq -r '.password' /data/options.json)
MOUNT_POINT=$(jq -r '.mount_point' /data/options.json)

# Ensure mount point exists
mkdir -p "$MOUNT_POINT"

# Create davfs2 configuration directory
mkdir -p /etc/davfs2

# Create secrets file with credentials
echo "$WEBDAV_URL $USERNAME $PASSWORD" > /etc/davfs2/secrets
chmod 600 /etc/davfs2/secrets

# Configure davfs2 to avoid locking issues (common with some WebDAV servers)
echo "use_locks 0" >> /etc/davfs2/davfs2.conf

# Mount the WebDAV share
mount -t davfs -o rw,uid=0,gid=0 "$WEBDAV_URL" "$MOUNT_POINT"

# Keep the container running
tail -f /dev/null