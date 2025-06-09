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

# Configure rclone
cat << EOF > /root/.config/rclone/rclone.conf
[webdav]
type = webdav
url = $WEBDAV_URL
vendor = other
user = $USERNAME
pass = $(echo -n "$PASSWORD" | rclone obscure -)
EOF

# Debug: Test WebDAV connection
echo "Debug: Testing WebDAV connection to $WEBDAV_URL"
rclone lsd webdav:/ --user "$USERNAME" --pass "$PASSWORD"
if [ $? -ne 0 ]; then
  echo "Error: Failed to list directory at $WEBDAV_URL. Check URL, credentials, or directory path."
  exit 1
fi

# Mount WebDAV share as read-only
rclone mount webdav:/ "$MOUNT_POINT" --read-only --vfs-cache-mode off --allow-other --daemon --log-level INFO
if [ $? -ne 0 ]; then
  echo "Error: Failed to mount $WEBDAV_URL to $MOUNT_POINT with rclone"
  exit 1
fi

echo "Successfully mounted $WEBDAV_URL to $MOUNT_POINT"

# Keep the container running
tail -f /dev/null