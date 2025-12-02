#!/bin/bash
set -euo pipefail

# CONFIG
CONTAINER="forgejo"
BACKUP_DIR="/opt/apps/forgejo-server/backups"
DATE=$(date +%F)
BACKUP_FILE="$BACKUP_DIR/$DATE.tar.gz"

# Load restic environment variables
. /opt/apps/forgejo-server/restic.env

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

echo "[*] Starting Forgejo backup: $BACKUP_FILE"

# 1. Run Forgejo's built-in backup inside the container
docker exec --user git "$CONTAINER" forgejo dump --type tar.gz --file "/data/backup-$DATE.tar.gz"

# 2. Move the tarball from container /data to host backup directory
# (Because /data is bind-mounted to /opt/apps/forgejo-server/forgejo)
mv "/opt/apps/forgejo-server/forgejo/backup-$DATE.tar.gz" "$BACKUP_FILE"

echo "[*] Forgejo backup completed."

# 3. Upload to Restic (back up the entire directory so deduplication works)
echo "[*] Running restic backup..."
restic backup "$BACKUP_DIR"

# 4. Apply retention
echo "[*] Applying retention..."
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune

echo "[~\~S] ackup + rotation completed successfully."

