# Nexloza MQTT Broker (EMQX)

## Overview
EMQX handles all device-to-cloud and cloud-to-device messaging.

## Topic Structure
```
nexloza/{project_id}/{device_id}/telemetry/{sensor_key}
nexloza/{project_id}/{device_id}/commands
nexloza/{project_id}/{device_id}/state
nexloza/{project_id}/{device_id}/heartbeat
nexloza/{project_id}/{device_id}/ota
```

## Setup
1. Start via docker-compose: `docker-compose up emqx`
2. Dashboard: http://localhost:18083 (admin/public)
3. TCP: localhost:1883, TLS: localhost:8883, WebSocket: localhost:8083

## Authentication
Devices authenticate using their device ID as username. Credentials are verified through the device-auth edge function before MQTT connection.

## ACL
See `acl.conf` — devices can only access their own topic namespace.
