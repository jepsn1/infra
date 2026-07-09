#!/usr/bin/env bash
#
# Back up Postgres (all databases) + /srv/data/uploads to /srv/data/backups.
# Timestamped, rotates automatically. Run daily by /etc/cron.d/infra-backup.
#
set -euo pipefail

BACKUP_DIR=/srv/data/backups
KEEP_DAYS=14
STAMP=$(date +%Y%m%d-%H%M%S)
COMPOSE="docker compose -f /srv/infra/compose/docker-compose.yml"

mkdir -p "$BACKUP_DIR"

echo "[$STAMP] backup start"

# Postgres: full cluster dump
$COMPOSE exec -T postgres pg_dumpall -U postgres | gzip > "$BACKUP_DIR/postgres-$STAMP.sql.gz"

# Uploads
if [[ -d /srv/data/uploads ]] && [[ -n "$(ls -A /srv/data/uploads 2>/dev/null)" ]]; then
    tar -czf "$BACKUP_DIR/uploads-$STAMP.tar.gz" -C /srv/data uploads
fi

# Rotate
find "$BACKUP_DIR" -maxdepth 1 -name '*.gz' -mtime +"$KEEP_DAYS" -delete

# Mirror to second physical drive (set up via scripts/setup-backup-drive.sh)
if mountpoint -q /mnt/backup; then
    rsync -a --delete "$BACKUP_DIR"/ /mnt/backup/srv-backups/
else
    echo "WARN: /mnt/backup not mounted, skipping mirror"
fi

echo "[$STAMP] backup done: $(ls -lh "$BACKUP_DIR" | tail -n +2 | wc -l) files, $(du -sh "$BACKUP_DIR" | cut -f1) total"
