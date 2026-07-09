# ADR 0003: Native development, Docker production

## Status
Accepted (2026-07-09)

## Context
Solo dev works directly on the VPS (VS Code Remote SSH + Claude Code). Dev-in-containers adds friction (file watching, node_modules, tool access for agents).

## Decision
Development runs natively (Node 22 via NodeSource, pnpm via corepack) on ports 3000–3999, localhost only. Production runs in Docker on the `web` network behind Caddy. Native dev reaches shared Postgres/Redis via `127.0.0.1:5432/6379`.

## Alternatives
- Dev containers / compose watch: reproducible but slower loops, worse agent ergonomics.
- Everything native incl. prod: no isolation, port conflicts, drift.

## Consequences
Fast dev loop; prod isolation. Dev and prod environments can drift — Dockerfile is the source of truth for prod runtime; test with `docker compose up --build` before relying on native-only behavior.
