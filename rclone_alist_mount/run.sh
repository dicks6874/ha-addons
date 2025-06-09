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

# Create Rclone config directory and set permissions
echo "Creating Rclone config directory..."
mkdir -p /root/.config/rclone
chmod 755 /root/.config/rclone
echo "Directory contents:"
ls -la /root/.config/rclone

# Create rclone.conf
echo "Writing rclone.conf..."
cat > /root/.config/rclone/rclone.conf <<EOF
[webdav]
type = webdav
url = ${WEBDAV_URL}
vendor = ${VENDOR}
user = ${WEBDAV_USER}
pass = $(rclone obscure "${WEBDAV_PASS}")
EOF

# Verify rclone.conf was created
if [ -f /root/.config/rclone/rclone.conf ]; then
    echo "rclone.conf created successfully:"
    cat /root/.config/rclone/rclone.conf
else
    echo "ERROR: Failed to create rclone.conf"
    exit 1
fi

# Start rclone mount
echo "Mounting WebDAV remote to ${MOUNT_POINT}"
/usr/bin/rclone mount webdav: "${MOUNT_POINT}" \
    --vfs-cache-mode writes \
    --dir-cache-time 5m \
    --vfs-read-ahead 128M \
    --allow-other \
    --daemon

# Wait briefly to ensure the mount starts
sleep 5

# Check if the mount is active
if mount | grep "${MOUNT_POINT}"; then
    echo "Mount successful"
else
    echo "ERROR: Mount failed"
    exit 1
fi

# Keep the script running to prevent container from exiting
tail -f /dev/null