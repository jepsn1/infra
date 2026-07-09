#!/usr/bin/env bash
# Validate and reload Caddy config after editing caddy/ files.
set -euo pipefail
COMPOSE="docker compose -f /srv/infra/compose/docker-compose.yml"
$COMPOSE exec caddy caddy validate --config /etc/caddy/Caddyfile
$COMPOSE exec caddy caddy reload --config /etc/caddy/Caddyfile
echo "Caddy reloaded."
