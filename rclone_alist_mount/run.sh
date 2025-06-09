#!/bin/bash
set -e

# Read configuration from Home Assistant options
WEBDAV_URL=$(jq --raw-output '.webdav_url' /data/options.json)
WEBDAV_USER=$(jq --raw-output '.webdav_user' /data/options.json)
WEBDAV_PASS=$(jq --raw-output '.webdav_pass' /data/options.json)
MOUNT_POINT=$(jq --raw-output '.mount_point' /data/options.json)
VENDOR=$(jq --raw-output '.vendor // "other"' /data/options.json)

# Create mount point if it doesn't exist
mkdir -p "${MOUNT_POINT}"

# Create Rclone config directory
mkdir -p /root/.config/rclone

# Create rclone.conf
cat > /root/.config/rclone/rclone.conf <<EOF
[webdav]
type = webdav
url = ${WEBDAV_URL}
vendor = ${VENDOR}
user = ${WEBDAV_USER}
pass = $(rclone obscure "${WEBDAV_PASS}")
EOF

# Start rclone mount
echo "Mounting WebDAV remote to ${MOUNT_POINT}"
/usr/bin/rclone mount webdav: "${MOUNT_POINT}" \
    --vfs-cache-mode writes \
    --dir-cache-time 5m \
    --vfs-read-ahead 128M \
    --allow-other \
    --daemon

# Keep the script running to prevent container from exiting
tail -f /dev/null