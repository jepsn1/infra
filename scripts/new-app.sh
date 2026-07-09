#!/usr/bin/env bash
#
# Register a new application: clone repo, generate Caddy site config, reload Caddy.
#
# Usage: new-app.sh <name> <domain> <internal-port> [git-url]
#   name          app + container name (e.g. biblestdy)
#   domain        public domain (e.g. app.example.com)
#   internal-port port the app container listens on
#   git-url       optional; cloned to /srv/apps/<name> if given
#
set -euo pipefail

NAME="${1:?usage: new-app.sh <name> <domain> <internal-port> [git-url]}"
DOMAIN="${2:?missing domain}"
PORT="${3:?missing internal port}"
GIT_URL="${4:-}"

SITE=/srv/infra/caddy/sites/"$NAME".caddy

if [[ -n "$GIT_URL" && ! -d "/srv/apps/$NAME" ]]; then
    git clone "$GIT_URL" "/srv/apps/$NAME"
fi

if [[ ! -f "$SITE" ]]; then
    cat > "$SITE" <<EOF
$DOMAIN {
	reverse_proxy $NAME:$PORT
}
EOF
    echo "Wrote $SITE"
fi

/srv/infra/scripts/caddy-reload.sh

cat <<EOF

Next steps:
  1. Point DNS: $DOMAIN -> this server's IP
  2. App's docker-compose.yml: container_name '$NAME', join external network 'web', listen on $PORT, no published ports
  3. Deploy: cd /srv/apps/$NAME && docker compose up -d --build
  4. Commit the new site file in /srv/infra
EOF
