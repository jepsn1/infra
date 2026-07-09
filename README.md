# infra

Reproducible dev + hosting platform for a single VPS. Shared services (Caddy, Postgres, Redis) in Docker, native development, per-app repos under `/srv/apps`.

**Operating manual: [AGENTS.md](AGENTS.md)** — read it first.

## Bootstrap a fresh VPS

```bash
git clone https://github.com/jepsn1/infra ~/infra
cd ~/infra
sudo ./setup.sh    # idempotent; moves repo to /srv/infra
```

Installs Docker, Node 22, UFW, fail2ban, unattended-upgrades; creates `/srv` layout; creates `web` Docker network; hardens SSH; starts shared services; installs daily backup cron.

## Layout

```
setup.sh       idempotent bootstrap
compose/       shared services (caddy, postgres, redis) + .env (secrets, not committed)
caddy/         Caddyfile + sites/*.caddy (one per app)
scripts/       status, logs, caddy-reload, new-app
backups/       backup.sh (cron, daily) + restore.sh
docs/          deployment.md, recovery.md, adr/
```

## Common tasks

```bash
scripts/status.sh                     # overview
scripts/logs.sh [container]           # logs
scripts/new-app.sh <name> <domain> <port> [git-url]   # add app
backups/backup.sh                     # backup now
backups/restore.sh list               # list backups
```

## Docs

- [Deployment](docs/deployment.md) — adding + deploying apps
- [Recovery](docs/recovery.md) — disaster recovery from backup
- [ADRs](docs/adr/) — architecture decisions
