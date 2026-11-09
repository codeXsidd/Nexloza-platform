# NanoMQ Setup Guide

## Overview

NanoMQ is the **primary MQTT broker** for the Nexloza platform. It is MIT-licensed, lightweight, and runs as a Docker container.

## Quick Start

```bash
docker compose up nanomq -d
```

The broker exposes:

| Port | Protocol | Purpose |
|------|----------|---------|
| 1883 | MQTT TCP | Device and app connections |
| 8083 | MQTT WebSocket | Browser-based clients |
| 8081 | HTTP | Management API |

## Configuration Files

All config lives in `infra/nanomq/config/`:

| File | Purpose |
|------|---------|
| `nanomq.conf` | Broker settings (listeners, limits, auth, logging) |
| `pw.conf` | Username/password credentials |
| `acl.conf` | Topic-level access control rules |

## Authentication

NanoMQ runs with `allow_anonymous = false`. Two default accounts exist for development:

| Username | Role | Access |
|----------|------|--------|
| `nexloza_admin` | Administrator | Publish and subscribe to all topics |
| `nexloza_app` | Application | Subscribe to all topics, publish to command channels |

Passwords are read from environment variables at container start:
- `NANOMQ_ADMIN_PASSWORD`
- `NANOMQ_APP_PASSWORD`

**Production:** Replace default passwords, enable TLS, and rotate credentials regularly.

## ACL Rules

The ACL enforces topic-level permissions:

1. `nexloza_admin` — full access to `nexloza/v1/#`
2. `nexloza_app` — subscribe to `nexloza/v1/#`, publish to `nexloza/v1/+/+/+/command`
3. Default — deny all

## TLS (Production)

To enable TLS in production, add to `nanomq.conf`:

```hocon
listeners.ssl {
  bind = "0.0.0.0:8883"
  keyfile = "/etc/nanomq/certs/server.key"
  certfile = "/etc/nanomq/certs/server.crt"
  cacertfile = "/etc/nanomq/certs/ca.crt"
}
```

Mount certificates via Docker volumes and expose port 8883.

## EMQX (Optional Alternative)

EMQX is available as an optional Docker profile for teams that need its dashboard or plugin ecosystem:

```bash
docker compose --profile emqx up emqx -d
```

EMQX runs on different ports (11883, 18083) to avoid conflicts with NanoMQ.

## Health Check

```bash
curl -sf http://localhost:8081/api/v4
```

Returns broker status JSON when NanoMQ is healthy.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Connection refused on 1883 | Check `docker compose ps nanomq` — container may not be running |
| Auth failure | Verify credentials in `.env` match `pw.conf` overrides |
| Topic denied | Check `acl.conf` rules match the topic pattern |
| WebSocket 404 | Ensure port 8083 is mapped and `listeners.ws` is configured |
