#!/usr/bin/env bash
# System + services overview.
set -euo pipefail
echo "=== Containers ==="
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
echo; echo "=== Disk ==="
df -h / /srv 2>/dev/null | sort -u
echo; echo "=== Memory ==="
free -h
echo; echo "=== Backups (latest 5) ==="
ls -lht /srv/data/backups 2>/dev/null | head -6
