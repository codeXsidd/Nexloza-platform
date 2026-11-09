# Phase 3 Completion Report — NanoMQ Infrastructure & MQTT Alignment

**Date:** 2026-11-09
**Commit baseline:** 637623e (Phase 2 complete, 223 tests passing)

## Objectives

1. Add NanoMQ as the primary MQTT broker (MIT-licensed, open-source)
2. Unify all MQTT topics to a single canonical format across Flutter, firmware, Edge Functions, code generator, and tests
3. Keep EMQX available as an optional alternative
4. Deploy updated Edge Functions
5. Document the MQTT protocol and NanoMQ setup

## Changes Made

### NanoMQ Infrastructure (NEW)

| File | Description |
|------|-------------|
| `infra/nanomq/config/nanomq.conf` | Broker config: TCP 1883, WS 8083, HTTP API 8081, auth required |
| `infra/nanomq/config/pw.conf` | Dev credentials with env var overrides |
| `infra/nanomq/config/acl.conf` | Topic ACL: admin full access, app subscribe-all + publish commands |
| `infra/nanomq/docker-compose.yml` | Standalone NanoMQ compose for isolated testing |
| `infra/nanomq/README.md` | Setup and operations documentation |

### Canonical Topic Format

**Before:** Three incompatible formats across components.
**After:** Single canonical format everywhere:

```
nexloza/v1/{organization_id}/{project_id}/{device_id}/{channel}
```

Channels: `telemetry`, `command`, `command-ack`, `state`, `status`, `config`

### Flutter App

| File | Change |
|------|--------|
| `app/lib/core/constants/mqtt_constants.dart` | Complete rewrite: 3-param topic builders, wildcard methods, v1 prefix |
| `app/lib/core/services/mqtt_service.dart` | Removed old `buildTopic` method |
| `app/lib/features/devices/presentation/providers/device_mqtt_provider.dart` | Updated to 3-param topic calls with organizationId, projectId, deviceId |
| `app/lib/features/devices/data/command_repository.dart` | Uses MQTT topic from Edge Function response instead of building locally |
| `app/lib/features/device_studio/domain/code_generator.dart` | Updated generated code to v1 topic format |

### Firmware SDK

| File | Change |
|------|--------|
| `firmware/nexloza-sdk/src/NexlozaClient.h` | Added `organizationId` to config, new public methods |
| `firmware/nexloza-sdk/src/NexlozaClient.cpp` | v1 topic setup, registerSensor, registerActuator, sendCommand, setDeviceMetadata |
| `firmware/nexloza-sdk/library.json` | License corrected to Apache-2.0 |

### Edge Functions (Deployed)

| Function | Change |
|----------|--------|
| `device-auth` | Joins through `projects` table for `organization_id`, returns v1 topics |
| `device-command` | Joins through `projects` table for `organization_id`, publishes to v1 topic |

### Docker

| File | Change |
|------|--------|
| `docker-compose.yml` | NanoMQ added as primary broker; EMQX moved to Docker profile `emqx` with non-conflicting ports |

### Tests

| File | Change |
|------|--------|
| `app/test/widget_test.dart` | Updated MqttConstants tests for v1 3-param format, added wildcard tests |

### Documentation

| File | Status |
|------|--------|
| `docs/MQTT_PROTOCOL.md` | NEW — canonical topic spec, channels, QoS, payloads, LWT |
| `docs/NANOMQ_SETUP.md` | NEW — setup, auth, ACL, TLS, troubleshooting |
| `.env.example` | Updated — NanoMQ variables added, EMQX section labeled optional |

## Verification

| Check | Result |
|-------|--------|
| `flutter analyze` | 0 issues |
| `flutter test --concurrency=1` | **224/224 passed** (+1 from wildcard topic test) |
| Edge Function deploy (device-auth) | Deployed to gwxaansxqdxkofrplfqx |
| Edge Function deploy (device-command) | Deployed to gwxaansxqdxkofrplfqx |

## Security

- NanoMQ runs with `allow_anonymous = false`
- ACL denies all by default
- Dev passwords use env var overrides — no hardcoded production credentials
- EMQX no longer has a hardcoded default password (requires `MQTT_ADMIN_PASSWORD` env var)
- No credentials exposed in Flutter app or firmware examples

## What's Next (Phase 4+)

- Virtual device simulator
- Real MQTT broker integration tests
- TLS certificate provisioning for production
- Device provisioning flow (firmware OTA)
