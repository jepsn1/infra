# Disaster recovery

Full VPS loss → working system. Requires: GitHub access, latest backup files (NOTE: backups are local-only in `/srv/data/backups` — copy them off-site or they die with the VPS).

## Procedure

1. **Provision** new Ubuntu LTS VPS, create non-root user with your SSH key, log in as that user.
2. **Bootstrap:**
   ```bash
   git clone https://github.com/jepsn1/infra ~/infra
   cd ~/infra && sudo ./setup.sh
   ```
   Log out/in (docker group). Shared services are now running with a fresh empty Postgres.
3. **Restore data.** Copy backup files to `/srv/data/backups`, then:
   ```bash
   /srv/infra/backups/restore.sh list
   /srv/infra/backups/restore.sh postgres postgres-<stamp>.sql.gz
   /srv/infra/backups/restore.sh uploads uploads-<stamp>.tar.gz
   ```
   Note: `pg_dumpall` includes roles + all databases; restoring into the fresh cluster is sufficient. The `postgres` superuser password is the new generated one from `compose/.env`, not the old one — update app `.env` files accordingly.
4. **Clone + deploy apps** (list in `AGENTS.md` → Current applications):
   ```bash
   git clone git@github.com:jepsn1/<app>.git /srv/apps/<app>
   cd /srv/apps/<app> && cp .env.example .env   # fill in secrets
   docker compose up -d --build
   ```
5. **DNS:** point each app's domain at the new IP. Caddy re-issues certificates automatically.
6. **Verify:** `scripts/status.sh`, hit each domain, check `backups/backup.sh` runs clean.

## Restoring a single mistake (not full loss)

Same `restore.sh` commands on the live server. Postgres restore replays the dump over the existing cluster — for a targeted fix, extract the relevant statements from the dump instead of replaying everything.
