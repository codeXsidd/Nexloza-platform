# Nexloza Firmware & Device SDK

Connect ESP32, ESP8266, and other Arduino-compatible boards to the Nexloza IoT platform.

## Supported Hardware

| Board | Status | Notes |
|-------|--------|-------|
| ESP32 (all variants) | Supported | Primary target, all features |
| ESP8266 / NodeMCU | Supported | All features except BLE |
| Arduino + Ethernet/WiFi shield | Compatible | Via MQTT gateway (see arduino-uno example) |
| Raspberry Pi | Compatible | Python MQTT client (see raspberry-pi example) |

## SDK Features

- **MQTT Communication** — publish telemetry, receive commands, report state
- **Device Authentication** — API key/secret exchange for MQTT credentials
- **Sensor Framework** — extensible `NexlozaSensor` base class with auto-publish
- **Actuator Framework** — extensible `NexlozaActuator` base class with command handling
- **Heartbeat & Health** — periodic status reports (uptime, free heap, RSSI)
- **Last Will & Testament** — automatic offline detection
- **Reconnection** — exponential backoff for WiFi and MQTT
- **Provisioning** — captive portal AP for zero-code WiFi/server configuration
- **Error Callbacks** — structured error codes for diagnostics
- **Configurable Logging** — levels: NONE, ERROR, WARN, INFO, DEBUG
- **OTA Updates** — firmware update notification channel
- **ArduinoJson v7** — efficient JSON serialization

## Getting Started

### Prerequisites

- [PlatformIO](https://platformio.org/) (recommended) or Arduino IDE
- ESP32 or ESP8266 board
- A Nexloza platform instance with a registered device

### Using PlatformIO

1. Copy an example project (e.g., `examples/esp32-led/`)
2. Edit `platformio.ini` build flags with your WiFi and Nexloza credentials
3. Build and upload:

```bash
cd firmware/examples/esp32-led
pio run --target upload
pio device monitor
```

### Using Arduino IDE

1. Install libraries: `ArduinoJson`, `PubSubClient`
2. Copy the `nexloza-sdk/src/` files into your Arduino libraries folder
3. Open the example `.cpp` as a `.ino` sketch
4. Set your credentials in the code
5. Upload

## Examples

### ESP32

| Example | Sensors/Actuators |
|---------|-------------------|
| [esp32-led](examples/esp32-led/) | Built-in LED (GPIO2) |
| [esp32-relay-light](examples/esp32-relay-light/) | Relay light switch |
| [esp32-relay-fan](examples/esp32-relay-fan/) | Relay + PWM fan control |
| [esp32-two-relay](examples/esp32-two-relay/) | Two independent relays |
| [esp32-dht22](examples/esp32-dht22/) | DHT22 temperature & humidity |
| [esp32-soil-moisture](examples/esp32-soil-moisture/) | Capacitive soil moisture |
| [esp32-pir-motion](examples/esp32-pir-motion/) | HC-SR501 PIR motion detector |
| [esp32-ultrasonic](examples/esp32-ultrasonic/) | HC-SR04 distance measurement |
| [esp32-water-level](examples/esp32-water-level/) | Analog water level sensor |
| [esp32-multi-sensor](examples/esp32-multi-sensor/) | DHT22 + BMP280 + LDR |
| [esp32-smart-home](examples/esp32-smart-home/) | DHT22 + Relay + PIR + LED combined |
| [esp32-universal](examples/esp32-universal/) | ADC + Relay + LED PWM + OTA |
| [esp32-reconnect-demo](examples/esp32-reconnect-demo/) | Reconnection handling |
| [esp32-provisioning](examples/esp32-provisioning/) | Captive portal setup |

### ESP8266

| Example | Sensors/Actuators |
|---------|-------------------|
| [esp8266-led](examples/esp8266-led/) | Built-in LED (GPIO2, active-LOW) |
| [esp8266-relay](examples/esp8266-relay/) | Relay switch (NodeMCU D1) |
| [esp8266-dht22](examples/esp8266-dht22/) | DHT22 temperature & humidity |
| [esp8266-soil-moisture](examples/esp8266-soil-moisture/) | Soil moisture (A0) |
| [esp8266-multi-sensor](examples/esp8266-multi-sensor/) | DHT22 + LDR |
| [esp8266-reconnect](examples/esp8266-reconnect/) | Reconnection handling |

### Other Platforms

| Example | Platform |
|---------|----------|
| [arduino-uno](examples/arduino-uno/) | Arduino Uno (gateway approach) |
| [raspberry-pi](examples/raspberry-pi/) | Raspberry Pi (Python client) |

## MQTT Topic Structure

All topics follow the v1 canonical format:

```
nexloza/v1/{organization_id}/{project_id}/{device_id}/{channel}
```

| Channel | Direction | QoS | Retained | Purpose |
|---------|-----------|-----|----------|---------|
| `telemetry` | Device → Cloud | 0 | No | Sensor readings |
| `command` | Cloud → Device | 1 | No | Control commands |
| `command-ack` | Device → Cloud | 1 | No | Command acknowledgement |
| `state` | Device → Cloud | 1 | Yes | Actuator/device state |
| `status` | Device → Cloud | 1 | Yes | Online/offline, heartbeat |
| `config` | Cloud → Device | 1 | Yes | Configuration updates |

## Creating a Custom Device

```cpp
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

NexlozaClient nexloza;

void handleCommand(const char* type, JsonObject& payload) {
  if (strcmp(type, "set_state") == 0) {
    const char* key = payload["actuator_key"];
    bool state = payload["state"];
    // Apply to your hardware
  }
}

void setup() {
  Serial.begin(115200);
  NexlozaWiFi::begin("SSID", "Password");

  NexlozaConfig config;
  config.serverHost  = "your-server.com";
  config.mqttPort    = 1883;
  config.deviceId    = "your-device-id";
  config.apiKey      = "your-api-key";
  config.apiSecret   = "your-api-secret";
  config.organizationId = "your-org-id";
  config.projectId   = "your-project-id";
  config.useTLS      = false;
  config.heartbeatIntervalMs  = 30000;
  config.reconnectIntervalMs  = 5000;
  config.maxReconnectAttempts = 10;

  nexloza.begin(config);
  nexloza.onCommand(handleCommand);
  nexloza.connect();
}

void loop() {
  if (!NexlozaWiFi::isConnected()) NexlozaWiFi::reconnect();
  nexloza.loop();

  nexloza.publishTelemetry("my_sensor", analogRead(A0) * 0.1);
  delay(10000);
}
```

## Safety Notice

All relay and actuator examples are designed for **low-voltage testing only** (3.3V–12V DC loads such as LEDs or small DC motors).

**Household AC mains wiring (110V/220V) must be installed by a qualified electrician** using appropriate protection devices (fuses, RCDs/GFCIs), proper enclosures, and in compliance with local electrical codes. Never work with exposed mains voltage.

## License

Apache-2.0 — see the root [LICENSE](../LICENSE) file.
