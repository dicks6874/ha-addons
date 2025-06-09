# Alist Mount Add-on
Mounts an Alist WebDAV share to a local directory in Home Assistant OS for use with add-ons like Jellyfin.

## Prerequisites
- Alist server with WebDAV enabled (e.g., `http://<alist-server-ip>:5244/dav`).

## Configuration
- `remote`: Name of the alist remote (e.g., `alist`).
- `path`: WebDAV path (e.g., `/` or `/<specific-folder>`).
- `mount_point`: Container path to mount (default: `/mnt/webdav`).
