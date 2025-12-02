#!/bin/bash
# /usr/local/bin/forgejo-full-restore.sh
# Full restore of Forgejo from Restic backup (Docker)
#
# Usage:
#   ./forgejo-full-restore.sh          # restore latest snapshot
#   ./forgejo-full-restore.sh abc123   # restore specific snapshot ID

set -euo pipefail

# ----------- Configuration -----------
CONTAINER="forgejo"
DATA_PATH="/opt/apps/forgejo-server/forgejo"  # host path mounted to container /data
BACKUP_DIR="/tmp/forgejo-restore"             # temp folder on host
DATA_BAK="${DATA_PATH}.bak"

# Snapshot to restore
SNAPSHOT="${1:-latest}"

# Load Restic environment
. /opt/apps/forgejo-server/restic.env
# --------------------------------------

echo "Stopping container $CONTAINER..."
docker stop "$CONTAINER"

# Backup existing data
if [ -d "$DATA_PATH" ] && [ "$(ls -A "$DATA_PATH")" ]; then
    echo "Backing up existing /data to $DATA_BAK"
    rm -rf "$DATA_BAK"
    mv "$DATA_PATH" "$DATA_BAK"
    mkdir -p "$DATA_PATH"
    chown 1000:1000 "$DATA_PATH"
fi

mkdir -p "$BACKUP_DIR"

echo "Restoring snapshot $SNAPSHOT from Restic repository $RESTIC_REPOSITORY..."
restic restore "$SNAPSHOT" --target "$BACKUP_DIR"

# Find backup archive
ARCHIVE=$(find "$BACKUP_DIR" -name "*.tar.gz" | head -n1)
if [ -z "$ARCHIVE" ]; then
    echo "Error: no .tar.gz archive found in restored snapshot!" >&2
    exit 1
fi

echo "Unpacking backup into $DATA_PATH..."
tar -xzf "$ARCHIVE" -C "$DATA_PATH"

# Move contents into proper paths
echo "Moving data into final directories..."
mkdir "$DATA_PATH/git"
mv "$DATA_PATH/data" "$DATA_PATH/gitea"
mv "$DATA_PATH/repos" "$DATA_PATH/git/repositories"
# remove forgejo-db.sql, it's irritating, the actual db is in $DATA_PATH/data/gitea.db
rm "$DATA_PATH/forgejo-db.sql"
# remove root app.ini, which is a duplicate of $DATA_PATH/data/conf/app.ini
rm "$DATA_PATH/app.ini"

# Fix ownership
chown -R 1000:1000 "$DATA_PATH"

# Clean up temporary unpack folder
rm -rf "$BACKUP_DIR"

# Start container
echo "Starting container $CONTAINER..."
docker start "$CONTAINER"

# Regenerate Git hooks inside running container
echo "Regenerating Git hooks..."
docker exec --user git "$CONTAINER" /usr/local/bin/gitea admin regenerate hooks

echo "Full restore complete!"

