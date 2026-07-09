#!/usr/bin/env bash
#
# Idempotent bootstrap for the VPS. Safe to re-run.
# Usage: sudo ./setup.sh
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run as root: sudo ./setup.sh" >&2
    exit 1
fi

DEV_USER="${SUDO_USER:-marcus}"
DEV_HOME="$(getent passwd "$DEV_USER" | cut -d: -f6)"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="/srv/infra"
NODE_MAJOR=22

log() { echo -e "\n==> $*"; }

# --- Packages -----------------------------------------------------------
log "Installing packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -yq \
    git curl ca-certificates gnupg rsync \
    docker.io docker-compose-v2 \
    ufw fail2ban unattended-upgrades

# --- Node.js (NodeSource, pinned major) ---------------------------------
if ! command -v node >/dev/null || [[ "$(node -v | cut -c2-3)" != "$NODE_MAJOR" ]]; then
    log "Installing Node.js $NODE_MAJOR"
    install -d /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor --yes -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list
    apt-get update -q
    apt-get install -yq nodejs
fi
corepack enable   # provides pnpm

# --- Directory layout ----------------------------------------------------
log "Creating /srv layout"
install -d -o "$DEV_USER" -g "$DEV_USER" \
    /srv /srv/apps /srv/logs \
    /srv/data /srv/data/uploads /srv/data/backups \
    /srv/data/caddy /srv/data/caddy/data /srv/data/caddy/config
# Owned by container users; don't chown to $DEV_USER
install -d /srv/data/postgres /srv/data/redis

# Move this checkout to its canonical location if needed
if [[ "$REPO_DIR" != "$INFRA_DIR" && ! -e "$INFRA_DIR/.git" ]]; then
    log "Moving repo to $INFRA_DIR"
    rm -rf "$INFRA_DIR"
    mv "$REPO_DIR" "$INFRA_DIR"
    chown -R "$DEV_USER:$DEV_USER" "$INFRA_DIR"
fi

# --- Docker ---------------------------------------------------------------
log "Configuring Docker"
systemctl enable --now docker
usermod -aG docker "$DEV_USER"
docker network inspect web >/dev/null 2>&1 || docker network create web

# --- Firewall -------------------------------------------------------------
log "Configuring UFW"
ufw allow OpenSSH >/dev/null
ufw allow 80/tcp >/dev/null
ufw allow 443/tcp >/dev/null
ufw --force enable

# --- Fail2ban ---------------------------------------------------------------
log "Configuring fail2ban"
cat > /etc/fail2ban/jail.local <<'EOF'
[sshd]
enabled = true
EOF
systemctl enable --now fail2ban
systemctl restart fail2ban

# --- SSH hardening ----------------------------------------------------------
# Only disable password auth if the dev user actually has a key installed.
if [[ -s "$DEV_HOME/.ssh/authorized_keys" ]]; then
    log "Disabling SSH password authentication"
    cat > /etc/ssh/sshd_config.d/90-hardening.conf <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
EOF
    systemctl reload ssh
else
    log "WARNING: no authorized_keys for $DEV_USER — leaving password auth enabled"
fi

# --- Automatic security updates ----------------------------------------------
log "Enabling unattended-upgrades"
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
systemctl enable --now unattended-upgrades

# --- Secrets ---------------------------------------------------------------
ENV_FILE="$INFRA_DIR/compose/.env"
if [[ ! -f "$ENV_FILE" ]]; then
    log "Generating $ENV_FILE"
    cat > "$ENV_FILE" <<EOF
POSTGRES_PASSWORD=$(openssl rand -hex 24)
CADDY_EMAIL=marcus@jepsn.com
EOF
    chown "$DEV_USER:$DEV_USER" "$ENV_FILE"
    chmod 600 "$ENV_FILE"
fi

# --- Backup cron --------------------------------------------------------------
log "Installing backup cron"
cat > /etc/cron.d/infra-backup <<EOF
0 3 * * * $DEV_USER $INFRA_DIR/backups/backup.sh >> /srv/logs/backup.log 2>&1
EOF
chmod 644 /etc/cron.d/infra-backup

# --- Shared services ------------------------------------------------------------
log "Starting shared services"
docker compose -f "$INFRA_DIR/compose/docker-compose.yml" up -d

log "Done. Log out/in for docker group to apply to $DEV_USER."
