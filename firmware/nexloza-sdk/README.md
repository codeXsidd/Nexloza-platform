# Nexloza Device SDK

Official device SDK for connecting ESP32 and ESP8266 boards to the Nexloza IoT platform.

## Features

- MQTT telemetry publishing with QoS 1
- Cloud-to-device command handling with acknowledgement
- Device state reporting (retained messages)
- Heartbeat with health metrics (uptime, free heap, RSSI)
- Exponential backoff reconnection
- Last Will and Testament for offline detection
- WiFi connection helper with auto-reconnect
- Captive portal provisioning (enter WiFi + server credentials from a phone)
- OTA firmware update support

## Quick Start

```cpp
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

NexlozaClient nexloza;

void handleCommand(const char* type, JsonObject& payload) {
  Serial.printf("Command: %s\n", type);
}

void setup() {
  Serial.begin(115200);
  NexlozaWiFi::begin("MyNetwork", "MyPassword");

  NexlozaConfig config;
  config.serverHost       = "mqtt.nexloza.com";
  config.mqttPort         = 1883;
  config.deviceId         = "esp32-001";
  config.apiKey           = "YOUR_API_KEY";
  config.apiSecret        = "YOUR_API_SECRET";
  config.projectId        = "YOUR_PROJECT_ID";
  config.useTLS           = false;
  config.heartbeatIntervalMs  = 30000;
  config.reconnectIntervalMs  = 5000;
  config.maxReconnectAttempts = 10;

  nexloza.begin(config);
  nexloza.onCommand(handleCommand);
  nexloza.connect();
}

void loop() {
  nexloza.loop();
  nexloza.publishTelemetry("temperature", 24.5);
  delay(10000);
}
```

## Provisioning Mode

Use the captive portal to configure WiFi and server credentials at runtime:

```cpp
#include <NexlozaProvisioning.h>

NexlozaProvisioning provisioning;

void setup() {
  Serial.begin(115200);

  if (!provisioning.isProvisioned()) {
    provisioning.beginAP("Nexloza-Setup");
    while (!provisioning.isComplete()) {
      provisioning.handleClient();
    }
    ESP.restart();
  }

  ProvisioningData creds = provisioning.loadCredentials();
  // Use creds.wifiSSID, creds.serverHost, etc.
}
```

## MQTT Topic Structure

| Topic | Direction | Purpose |
|-------|-----------|---------|
| `nexloza/{project_id}/{device_id}/telemetry` | Device → Cloud | Sensor readings |
| `nexloza/{project_id}/{device_id}/command` | Cloud → Device | Control commands |
| `nexloza/{project_id}/{device_id}/command/result` | Device → Cloud | Command acknowledgement |
| `nexloza/{project_id}/{device_id}/state` | Device → Cloud | Actuator state (retained) |
| `nexloza/{project_id}/{device_id}/heartbeat` | Device → Cloud | Health status (retained) |
| `nexloza/{project_id}/{device_id}/ota` | Cloud → Device | OTA update notifications |

## Telemetry Payload

```json
{
  "device_id": "esp32-001",
  "sensor_key": "temperature",
  "value": 24.5,
  "timestamp": 123456
}
```

## Command Payload

```json
{
  "command_id": "cmd-uuid",
  "command_type": "set_state",
  "payload": {
    "actuator_key": "relay_1",
    "state": true
  }
}
```

## Dependencies

- [ArduinoJson](https://github.com/bblanchon/ArduinoJson) v7+
- [PubSubClient](https://github.com/knolleary/pubsubclient) v2.8+

## License

MIT
