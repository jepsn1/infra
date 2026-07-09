# ADR 0001: Record architecture decisions

## Status
Accepted (2026-07-09)

## Context
Platform must be maintainable by future Claude Code sessions without chat history. Decisions need durable rationale.

## Decision
Keep ADRs in `infra/docs/adr/`, numbered, one decision each: Context / Decision / Alternatives / Consequences. Agents update or supersede ADRs when architecture evolves.

## Consequences
Small writing overhead per significant change; in exchange, future sessions can see *why*, not just *what*.
