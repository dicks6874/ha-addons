#!/bin/bash

# Read configuration from HAOS add-on options
WEBDAV_URL=$(jq -r '.webdav_url' /data/options.json)
USERNAME=$(jq -r '.username' /data/options.json)
PASSWORD=$(jq -r '.password' /data/options.json)
SERVE_PORT=$(jq -r '.serve_port // "8080"' /data/options.json)

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
if [ -z "$SERVE_PORT" ] || [ "$SERVE_PORT" = "null" ]; then
  echo "Error: serve_port is not set or invalid in /data/options.json. Defaulting to 8080"
  SERVE_PORT="8080"
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

# Debug: Show rclone config (masking password)
echo "Debug: rclone config"
cat /root/.config/rclone/rclone.conf | grep -v pass

# Debug: Test WebDAV connection
echo "Debug: Testing WebDAV connection to $WEBDAV_URL"
rclone lsd webdav:/
if [ $? -ne 0 ]; then
  echo "Error: Failed to list directory at $WEBDAV_URL. Check URL, credentials, or directory path."
  exit 1
fi

# Debug: List .strm files in OneDriveShare
echo "Debug: Listing .strm files in webdav:/OneDriveShare"
rclone ls webdav:/OneDriveShare --include "*.strm"
if [ $? -ne 0 ]; then
  echo "Warning: No .strm files found or error listing files in OneDriveShare."
fi

# Serve WebDAV share over HTTP
echo "Serving $WEBDAV_URL on port $SERVE_PORT"
rclone serve webdav webdav:/OneDriveShare --addr :$SERVE_PORT --read-only --user "$USERNAME" --pass "$PASSWORD" &
SERVE_PID=$!
sleep 5
if ! ps -p $SERVE_PID > /dev/null; then
  echo "Error: Failed to serve $WEBDAV_URL on port $SERVE_PORT with rclone"
  exit 1
fi

echo "Successfully serving $WEBDAV_URL on port $SERVE_PORT"

# Keep the container running
tail -f /dev/null