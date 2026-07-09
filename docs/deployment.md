# Deployment

## Adding a new application

1. Create GitHub repo `jepsn1/<name>` with the repository contract (`Dockerfile`, `docker-compose.yml`, `.env.example`, `README.md`, `AGENTS.md`, `Makefile` where applicable).
2. App `docker-compose.yml` requirements:
   - `container_name: <name>` (matches repo/dir name)
   - joins external network `web`, publishes **no** host ports
   - `restart: unless-stopped`
   - connects to shared services at `infra-postgres:5432` / `infra-redis:6379`
3. Register on the VPS:
   ```bash
   /srv/infra/scripts/new-app.sh <name> <domain> <internal-port> git@github.com:jepsn1/<name>.git
   ```
   This clones to `/srv/apps/<name>`, writes `caddy/sites/<name>.caddy`, reloads Caddy.
4. Point DNS A-record for `<domain>` at this server.
5. Create the app's database (one DB per app, named after it):
   ```bash
   docker exec -it infra-postgres createdb -U postgres <name>
   ```
6. `cp .env.example .env` in the app dir, fill in secrets.
7. Deploy (below). Commit the new site file in `/srv/infra` and add the app to the table in `AGENTS.md`.

## Deploying / updating an app

```bash
cd /srv/apps/<name>
git pull
docker compose up -d --build
```

## Rollback

```bash
cd /srv/apps/<name>
git checkout <last-good-commit>
docker compose up -d --build
```

## Shared services

```bash
docker compose -f /srv/infra/compose/docker-compose.yml up -d      # apply compose changes
/srv/infra/scripts/caddy-reload.sh                                 # apply caddy changes
```
