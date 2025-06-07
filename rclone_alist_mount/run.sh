#!/bin/sh

# Read configuration from add-on options
ALIST_URL=$(jq -r '.alist_url' /data/options.json)
ALIST_USERNAME=$(jq -r '.alist_username' /data/options.json)
ALIST_PASSWORD=$(jq -r '.alist_password' /data/options.json)
MOUNT_POINT=$(jq -r '.mount_point' /data/options.json)
RCLONE_CONFIG=$(jq -r '.rclone_config' /data/options.json)

# Create rclone config directory
mkdir -p /root/.config/rclone

# Create mount point if it doesn't exist
mkdir -p "${MOUNT_POINT}"

# Create rclone configuration file
if [ -n "${RCLONE_CONFIG}" ]; then
    echo "${RCLONE_CONFIG}" > /root/.config/rclone/rclone.conf
else
    cat << EOF > /root/.config/rclone/rclone.conf
[alist]
type = webdav
url = ${ALIST_URL}
vendor = other
user = ${ALIST_USERNAME}
pass = ${ALIST_PASSWORD}
EOF
fi

# Mount the Alist server
rclone mount alist: "${MOUNT_POINT}" \
    --allow-other \
    --vfs-cache-mode writes \
    --daemon

# Keep the container running
tail -f /dev/null