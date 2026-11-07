# MQTT Broker

Configuration files for the Nexloza MQTT broker (EMQX or Mosquitto).

## Purpose

This directory holds broker configuration, TLS certificates, ACL rules, and authentication plugins used to secure device-to-cloud communication.

## Planned Contents

- EMQX configuration (`emqx.conf`)
- Mosquitto configuration (`mosquitto.conf`) as a lightweight alternative
- TLS certificate setup
- JWT authentication plugin configuration
- Topic ACL rules

Planned for future milestone. See [docs/api/mqtt-protocol.md](../../docs/api/mqtt-protocol.md) for the MQTT topic structure and payload formats.
