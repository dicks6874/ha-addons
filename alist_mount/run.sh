#!/bin/bash

# Read configuration from HAOS add-on options
WEBDAV_URL=$(jq -r '.webdav_url' /data/options.json)
USERNAME=$(jq -r '.username' /data/options.json)
PASSWORD=$(jq -r '.password' /data/options.json)
ALIST_API_URL=$(jq -r '.alist_api_url // "http://192.168.0.142:5244/api"' /data/options.json)
ALIST_TOKEN=$(jq -r '.alist_token' /data/options.json)
SERVE_PORT=$(jq -r '.serve_port // "8080"' /data/options.json)
STRM_DIR="/data/strm"

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
if [ -z "$ALIST_API_URL" ] || [ "$ALIST_API_URL" = "null" ]; then
  echo "Error: alist_api_url is not set or invalid in /data/options.json"
  exit 1
fi
if [ -z "$ALIST_TOKEN" ] || [ "$ALIST_TOKEN" = "null" ]; then
  echo "Error: alist_token is not set or invalid in /data/options.json"
  exit 1
fi
if [ -z "$SERVE_PORT" ] || [ "$SERVE_PORT" = "null" ]; then
  echo "Error: serve_port is not set or invalid in /data/options.json. Defaulting to 8080"
  SERVE_PORT="8080"
fi

# Create STRM directory
mkdir -p "$STRM_DIR"
if [ $? -ne 0 ]; then
  echo "Error: Failed to create STRM directory $STRM_DIR"
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

# Generate .strm files for .mp4 files
echo "Debug: Listing .mp4 files in webdav:/OneDriveShare"
rclone lsjson webdav:/OneDriveShare --include "*.mp4" | jq -r '.[] | .Path' | while read -r file; do
  STRM_FILE="$STRM_DIR/${file%.mp4}.strm"
  mkdir -p "$(dirname "$STRM_FILE")"
  # Get streaming URL from AList API
  echo "Debug: Fetching streaming URL for $file"
  API_PATH="/OneDriveShare/$file"
  STREAM_URL=$(curl -s -H "Authorization: Bearer $ALIST_TOKEN" "$ALIST_API_URL/fs/get?path=$API_PATH" | jq -r '.data.raw_url // empty')
  if [ -z "$STREAM_URL" ]; then
    echo "Warning: Failed to get streaming URL for $file"
    continue
  fi
  echo "$STREAM_URL" > "$STRM_FILE"
  echo "Generated $STRM_FILE"
done

# Debug: List generated .strm files
echo "Debug: Listing .strm files in $STRM_DIR"
ls -l "$STRM_DIR"

# Serve STRM directory over HTTP
echo "Serving $STRM_DIR on port $SERVE_PORT"
rclone serve http "$STRM_DIR" --addr :$SERVE_PORT --read-only &
SERVE_PID=$!
sleep 5
if ! ps -p $SERVE_PID > /dev/null; then
  echo "Error: Failed to serve $STRM_DIR on port $SERVE_PORT with rclone"
  exit 1
fi

echo "Successfully serving $STRM_DIR on port $SERVE_PORT"

# Keep the container running
tail -f /dev/null