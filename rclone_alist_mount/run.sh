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

# Test WebDAV connection
echo "Testing WebDAV connection..."
/usr/bin/rclone lsd webdav: --max-depth 1
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to connect to WebDAV server"
    exit 1
fi

# Check FUSE setup
echo "Checking FUSE setup..."
ls -l /dev/fuse || echo "ERROR: /dev/fuse not found"
which fusermount3 || echo "ERROR: fusermount3 not found"
modprobe fuse || echo "WARNING: modprobe fuse failed"

# Start rclone mount in foreground for debugging
echo "Mounting WebDAV remote to ${MOUNT_POINT}"
/usr/bin/rclone mount webdav: "${MOUNT_POINT}" \
    --vfs-cache-mode writes \
    --dir-cache-time 5m \
    --vfs-read-ahead 128M \
    --allow-other \
    --log-level DEBUG