# Nexloza Firmware & Device SDK

Connect ESP32, ESP8266, and other Arduino-compatible boards to the Nexloza IoT platform.

## Supported Hardware

| Board | Status | Notes |
|-------|--------|-------|
| ESP32 (all variants) | Supported | Primary target, all features |
| ESP8266 / NodeMCU | Supported | All features except BLE |
| Arduino + Ethernet/WiFi shield | Compatible | Via MQTT client |
| Raspberry Pi | Compatible | Use any MQTT client library (Python, Node.js, etc.) |

## SDK Features

- **MQTT Communication** — publish telemetry, receive commands, report state
- **Device Authentication** — API key/secret exchange for MQTT credentials
- **Heartbeat & Health** — periodic status reports (uptime, free heap, RSSI)
- **Last Will & Testament** — automatic offline detection
- **Reconnection** — exponential backoff for WiFi and MQTT
- **Provisioning** — captive portal AP for zero-code WiFi/server configuration
- **OTA Updates** — firmware update notification channel
- **ArduinoJson v7** — efficient JSON serialization

## Getting Started

### Prerequisites

- [PlatformIO](https://platformio.org/) (recommended) or Arduino IDE
- ESP32 or ESP8266 board
- A Nexloza platform instance with a registered device

### Using PlatformIO

1. Copy an example project (e.g., `examples/esp32-relay-light/`)
2. Edit `platformio.ini` build flags with your WiFi and Nexloza credentials
3. Build and upload:

```bash
cd firmware/examples/esp32-relay-light
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

| Example | Hardware | Sensors/Actuators |
|---------|----------|-------------------|
| [esp32-relay-fan](examples/esp32-relay-fan/) | ESP32 | Relay + PWM fan control |
| [esp32-relay-light](examples/esp32-relay-light/) | ESP32 | Relay light switch |
| [esp32-dht22](examples/esp32-dht22/) | ESP32 | DHT22 temperature & humidity |
| [esp32-soil-moisture](examples/esp32-soil-moisture/) | ESP32 | Capacitive soil moisture |
| [esp32-pir-motion](examples/esp32-pir-motion/) | ESP32 | HC-SR501 PIR motion detector |
| [esp32-multi-sensor](examples/esp32-multi-sensor/) | ESP32 | DHT22 + BMP280 + LDR |
| [esp8266-relay](examples/esp8266-relay/) | ESP8266 | Relay switch (NodeMCU) |

## MQTT Topic Structure

All topics follow: `nexloza/{project_id}/{device_id}/{channel}`

| Channel | Direction | QoS | Retained | Purpose |
|---------|-----------|-----|----------|---------|
| `telemetry` | Device → Cloud | 0 | No | Sensor readings |
| `command` | Cloud → Device | 1 | No | Control commands |
| `command/result` | Device → Cloud | 1 | No | Command acknowledgement |
| `state` | Device → Cloud | 1 | Yes | Actuator state |
| `heartbeat` | Device → Cloud | 1 | Yes | Device health |
| `ota` | Cloud → Device | 1 | No | OTA update notifications |

## Creating a Custom Device

```cpp
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

NexlozaClient nexloza;

void handleCommand(const char* type, JsonObject& payload) {
  // Handle incoming commands from the platform
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

  // Publish your sensor data
  nexloza.publishTelemetry("my_sensor", analogRead(A0) * 0.1);
  delay(10000);
}
```

## Safety Notice

All relay and actuator examples are designed for **low-voltage testing only** (3.3V–12V DC loads such as LEDs or small DC motors).

**Household AC mains wiring (110V/220V) must be installed by a qualified electrician** using appropriate protection devices (fuses, RCDs/GFCIs), proper enclosures, and in compliance with local electrical codes. Never work with exposed mains voltage.

## License

MIT — see the root [LICENSE](../LICENSE) file.
