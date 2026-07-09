# ADR 0002: Shared services (Caddy, Postgres, Redis) run in Docker

## Status
Accepted (2026-07-09)

## Context
PRD lists Caddy/Postgres/Redis as installs; they could run natively (apt) or as containers. Production apps are containerized either way.

## Decision
Run all three as containers in one compose project (`infra`, `compose/docker-compose.yml`), data bind-mounted under `/srv/data`. Caddy joins the shared `web` network and proxies to app containers by name; Postgres/Redis additionally bind `127.0.0.1` for native dev access.

## Alternatives
- Native apt installs: OS-version-coupled, upgrades via distro, config scattered in /etc; less reproducible.
- Caddy native + services in Docker: split model, two config mechanisms.

## Consequences
- One mechanism (compose) for everything production; versions pinned in Git; reproducible.
- Caddy→app routing needs no published app ports.
- Caveat: Docker published ports bypass UFW — mitigated by publishing only 80/443 (Caddy) and binding DB/cache to localhost.
