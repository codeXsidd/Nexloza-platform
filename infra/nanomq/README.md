# NanoMQ — NEXLOZA MQTT Broker

NanoMQ is NEXLOZA's primary open-source MQTT broker.

- **License:** MIT
- **MQTT:** 5.0 + 3.1.1 compatibility
- **Image:** `emqx/nanomq:0.22.6-slim`
- **Source:** https://github.com/nanomq/nanomq

## Quick Start

```bash
cd infra/nanomq
docker compose up -d
```

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 1883 | MQTT TCP | Device and app connections |
| 8083 | MQTT WS | WebSocket connections |
| 8081 | HTTP | Health check and management API |

## Configuration

| File | Purpose |
|------|---------|
| `config/nanomq.conf` | Main broker configuration |
| `config/pw.conf` | Username/password authentication |
| `config/acl.conf` | Topic access control rules |

## Authentication

Anonymous connections are **disabled**. All clients must authenticate.

### Default credentials (development only)

| Username | Purpose |
|----------|---------|
| `nexloza_admin` | Administrative access (all topics) |
| `nexloza_app` | Flutter app client (subscribe all, publish commands) |

Override passwords via environment variables:
- `NANOMQ_ADMIN_PASSWORD`
- `NANOMQ_APP_PASSWORD`

### Device authentication

Devices authenticate via the `device-auth` Edge Function, which returns MQTT credentials. Per-device topic ACL is enforced at the broker level.

## Topic Structure

All NEXLOZA MQTT topics follow this canonical format:

```
nexloza/v1/{organization_id}/{project_id}/{device_id}/{channel}
```

### Channels

| Channel | Direction | QoS | Retained | Description |
|---------|-----------|-----|----------|-------------|
| `telemetry` | Device → Cloud | 0 | No | Sensor readings |
| `command` | Cloud → Device | 1 | No | Device commands |
| `command-ack` | Device → Cloud | 1 | No | Command acknowledgements |
| `state` | Device → Cloud | 1 | Yes | Actuator state reports |
| `status` | Device → Cloud | 1 | Yes | Online/offline status |
| `config` | Cloud → Device | 1 | Yes | Device configuration |

## ACL Rules

- **Admin:** Full access to all topics
- **App client:** Subscribe to all `nexloza/v1/#`, publish to `nexloza/v1/+/+/+/command`
- **Devices:** Restricted to their own topic subtree (enforced by device-auth credentials)
- **Default:** Deny all

## TLS (Production)

For production deployments, uncomment the TLS listener in `nanomq.conf` and provide:
- `server.key` — Server private key
- `server.crt` — Server certificate
- `ca.crt` — CA certificate

## Health Check

```bash
curl http://localhost:8081/api/v4
```

## Monitoring

View logs:
```bash
docker compose logs -f nanomq
```
