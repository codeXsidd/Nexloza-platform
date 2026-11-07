# MQTT Configuration

Client and topic configuration for Nexloza MQTT communication.

## Purpose

This directory contains configuration templates and documentation for MQTT clients, topic mappings, QoS settings, and message schemas used across the platform.

## Topic Convention

All topics follow: `nexloza/{org_id}/{project_id}/{device_id}/{channel}`

Channels: `telemetry/{sensor_key}`, `commands`, `state`, `heartbeat`, `ota`

## Related Documentation

- [MQTT Protocol Specification](../../docs/api/mqtt-protocol.md)
- [Security Architecture](../../docs/architecture/security.md)

Planned for future milestone.
