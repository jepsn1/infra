#!/usr/bin/env bash
#
# Restore Postgres and/or uploads from /srv/data/backups.
#
# Usage:
#   ./restore.sh list                                  # show available backups
#   ./restore.sh postgres postgres-<stamp>.sql.gz      # restore full cluster dump
#   ./restore.sh uploads  uploads-<stamp>.tar.gz       # restore uploads
#
set -euo pipefail

BACKUP_DIR=/srv/data/backups
COMPOSE="docker compose -f /srv/infra/compose/docker-compose.yml"

case "${1:-}" in
    list)
        ls -lh "$BACKUP_DIR"
        ;;
    postgres)
        FILE="$BACKUP_DIR/${2:?usage: restore.sh postgres <file>}"
        echo "Restoring $FILE into the running postgres container..."
        gunzip -c "$FILE" | $COMPOSE exec -T postgres psql -U postgres
        echo "Done."
        ;;
    uploads)
        FILE="$BACKUP_DIR/${2:?usage: restore.sh uploads <file>}"
        echo "Restoring $FILE to /srv/data/uploads..."
        tar -xzf "$FILE" -C /srv/data
        echo "Done."
        ;;
    *)
        grep '^#' "$0" | head -8
        exit 1
        ;;
esac
