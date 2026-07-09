#!/usr/bin/env bash
# Tail logs for a container. Usage: logs.sh [container-name] (default: all shared services)
set -euo pipefail
COMPOSE="docker compose -f /srv/infra/compose/docker-compose.yml"
if [[ $# -eq 0 ]]; then
    exec $COMPOSE logs -f --tail 100
fi
exec docker logs -f --tail 100 "$1"
