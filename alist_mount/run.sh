#!/bin/bash

# Read configuration from HAOS add-on options
WEBDAV_URL=$(jq -r '.webdav_url' /data/options.json)
USERNAME=$(jq -r '.username' /data/options.json)
PASSWORD=$(jq -r '.password' /data/options.json)
MOUNT_POINT=$(jq -r '.mount_point' /data/options.json)

# Validate configuration
if [ -z "$WEBDAV_URL" ] || [ "$WEBDAV_URL" = "null" ]; then
  echo "Error: webdav_url is not set or invalid in /data/options.json"
  exit 1
fi
# Basic URL validation (checks for http:// or https://)
if ! echo "$WEBDAV_URL" | grep -qE '^https?://'; then
  echo "Error: webdav_url ($WEBDAV_URL) is not a valid URL. It must start with http:// or https://"
  exit 1
fi
if [ -z "$USERNAME" ] || [ "$USERNAME" = "null" ]; then
  echo "Error: username is not set or invalid in /data/options.json"
  exit 1
fi
if [ -z "$PASSWORD" ] || [ "$PASSWORD" = "null" ]; then
  echo "Error: password is not set or invalid in /data/options.json"
  exit 1
fi
if [ -z "$MOUNT_POINT" ] || [ "$MOUNT_POINT" = "null" ]; then
  echo "Error: mount_point is not set or invalid in /data/options.json. Defaulting to /data/mount"
  MOUNT_POINT="/data/mount"
fi

# Ensure mount point exists
mkdir -p "$MOUNT_POINT"
if [ $? -ne 0 ]; then
  echo "Error: Failed to create mount point directory $MOUNT_POINT"
  exit 1
fi

# Create davfs2 configuration directory
mkdir -p /etc/davfs2
if [ $? -ne 0 ]; then
  echo "Error: Failed to create /etc/davfs2 directory"
  exit 1
fi

# Create secrets file with quoted credentials to handle special characters
echo "\"$WEBDAV_URL\" \"$USERNAME\" \"$PASSWORD\"" > /etc/davfs2/secrets
chmod 600 /etc/davfs2/secrets
if [ $? -ne 0 ]; then
  echo "Error: Failed to create or set permissions for /etc/davfs2/secrets"
  exit 1
fi

# Configure davfs2 to avoid locking issues
echo "use_locks 0" >> /etc/davfs2/davfs2.conf

# Mount the WebDAV share
mount -t davfs -o rw,uid=0,gid=0 "$WEBDAV_URL" "$MOUNT_POINT"
if [ $? -ne 0 ]; then
  echo "Error: Failed to mount $WEBDAV_URL to $MOUNT_POINT"
  exit 1
fi

echo "Successfully mounted $WEBDAV_URL to $MOUNT_POINT"

# Keep the container running
tail -f /dev/null