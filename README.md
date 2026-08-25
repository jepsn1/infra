# infra

Reproducible dev + hosting platform for a single VPS. Shared services (Caddy, Postgres, Redis) in Docker, native development, per-app repos under `/srv/apps`.

**Operating manual: [AGENTS.md](AGENTS.md)** — read it first. This README is the front door; AGENTS.md is canonical for conventions, security model, and every rule an agent or human is expected to follow before touching the server.

The invariant everything else follows from: **persistent state lives in `/srv/data` and nowhere else.** The rest of the machine is recreatable with `git clone` + `setup.sh`.

## Bootstrap a fresh VPS

```bash
git clone https://github.com/jepsn1/infra ~/infra
cd ~/infra
sudo ./setup.sh    # idempotent; moves repo to /srv/infra
```

Installs Docker, Node 22, UFW, fail2ban, unattended-upgrades, Tailscale; creates the `/srv` layout and the `web` Docker network; hardens SSH; generates `compose/.env`; starts shared services; installs the daily backup cron. Safe to re-run.

Manual steps it does *not* do: joining the tailnet (`tailscale up`), and DNS A-records.

## What's running

Shared services — `compose/docker-compose.yml`, project `infra`:

| Service | Container | Bind |
| --- | --- | --- |
| Caddy | `infra-caddy` | 80/443 public, automatic HTTPS |
| Postgres 17 (pgvector) | `infra-postgres` | `127.0.0.1:5432`, `infra-postgres:5432` in-network |
| Redis 8 | `infra-redis` | `127.0.0.1:6379`, `infra-redis:6379` in-network |

Apps — one repo each, cloned to `/srv/apps/<name>`:

| App | Exposure | Entry point |
| --- | --- | --- |
| [biblestdy](https://github.com/jepsn1/biblestdy) | public, biblestdy.com | SPA served statically by Caddy + `biblestdy-api` container |
| [pkos](https://github.com/jepsn1/pkos) | private, tailnet only | api `:3002`, webui `:8081` bound to the Tailscale IP |

Two exposure patterns, and the choice is the app's defining infra decision:

- **Public** — no published ports; join the `web` network and add a `caddy/sites/<app>.caddy` file. Caddy proxies by container name.
- **Private** — no Caddy site; publish ports bound to the Tailscale IP (`${TAILSCALE_IP}:port:port` from the app's `.env`). Reachable from any tailnet device, invisible from the WAN.

Never bind `0.0.0.0` — Docker published ports bypass UFW.

## Layout

```
setup.sh          idempotent bootstrap
AGENTS.md         operating manual (canonical)
.env.example      documents compose/.env
compose/          shared services + .env (secrets, generated, not committed)
caddy/            Caddyfile + sites/*.caddy (one per public app, committed)
scripts/          status, logs, caddy-reload, new-app, setup-backup-drive
backups/          backup.sh (daily cron) + restore.sh
docs/             deployment.md, recovery.md, adr/
```

## Common tasks

```bash
scripts/status.sh                     # containers, disk, memory, latest backups
scripts/logs.sh [container]           # logs (default: shared services)
scripts/new-app.sh <name> <domain> <port> [git-url]   # register a public app
scripts/caddy-reload.sh               # after editing caddy/
backups/backup.sh                     # backup now
backups/restore.sh list               # list backups
```

Deploying an app is `cd /srv/apps/<app> && git pull && docker compose up -d --build`. Some apps wrap that in a `make deploy` — check the app's own README.

## Backups

Daily 03:00 → `/srv/data/backups`: `pg_dumpall` of the cluster plus a tarball of `/srv/data/uploads`, 14-day rotation, log at `/srv/logs/backup.log`. Each run rsyncs to a second physical drive at `/mnt/backup/srv-backups`.

**No off-site copy yet** — the mirror survives a drive failure, not a fire or theft. Open TODO.

## Docs

| | |
| --- | --- |
| [AGENTS.md](AGENTS.md) | Operating manual — read before any infra change |
| [docs/deployment.md](docs/deployment.md) | Adding and deploying apps |
| [docs/recovery.md](docs/recovery.md) | Disaster recovery from backup |
| [docs/adr/](docs/adr/) | Architecture decisions |
| [caddy/sites/README.md](caddy/sites/README.md) | Site-file format |

## Secrets

None are in this repo. Shared-services secrets are generated into `compose/.env` (chmod 600) by `setup.sh`; app secrets live in `/srv/apps/<app>/.env`. Both are gitignored; `.env.example` documents what's required. This repo is public — keep it that way by never committing a real `.env`.
