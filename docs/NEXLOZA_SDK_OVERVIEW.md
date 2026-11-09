# Nexloza SDK Overview

## What is NexlozaSDK?

NexlozaSDK is an Arduino-compatible C++ library that connects ESP32 and ESP8266 microcontrollers to the Nexloza IoT platform. It handles WiFi, MQTT communication, device authentication, telemetry publishing, command handling, and device provisioning.

## Architecture

```
┌─────────────────────────────────────────────────┐
│                  Your Firmware                   │
│   (sensors, actuators, application logic)        │
├─────────────────────────────────────────────────┤
│              NexlozaClient (SDK)                 │
│  ┌────────────┐ ┌───────────┐ ┌──────────────┐  │
│  │  Sensor    │ │ Actuator  │ │   Logger     │  │
│  │  Framework │ │ Framework │ │              │  │
│  └────────────┘ └───────────┘ └──────────────┘  │
│  ┌────────────┐ ┌───────────┐ ┌──────────────┐  │
│  │  WiFi      │ │   MQTT    │ │ Provisioning │  │
│  │  Manager   │ │ Transport │ │   Portal     │  │
│  └────────────┘ └───────────┘ └──────────────┘  │
├─────────────────────────────────────────────────┤
│        Arduino Framework (ESP32/ESP8266)         │
└─────────────────────────────────────────────────┘
           │                    │
      WiFi/TLS            NanoMQ Broker
           │                    │
      ┌────┴────────────────────┴────┐
      │     Nexloza Cloud Platform    │
      │  (Supabase + Edge Functions)  │
      └───────────────────────────────┘
```

## Features

| Feature | Description |
|---------|-------------|
| MQTT Communication | Publish telemetry, receive commands, report state |
| Device Authentication | API key/secret exchange via Edge Function |
| Sensor Framework | Extensible base class with auto-publish |
| Actuator Framework | Extensible base class with command handling |
| Heartbeat | Periodic status (uptime, heap, RSSI) |
| Last Will & Testament | Automatic offline detection |
| Reconnection | Exponential backoff for WiFi and MQTT |
| Provisioning | Captive portal for zero-code setup |
| Error Callbacks | Structured error codes |
| Configurable Logging | NONE, ERROR, WARN, INFO, DEBUG |
| OTA Updates | Update notification channel |

## Supported Boards

| Board | SDK Support | Notes |
|-------|-------------|-------|
| ESP32 (all variants) | Full | Primary target |
| ESP8266 / NodeMCU | Full | No BLE, single ADC |
| Arduino Uno | Gateway only | Needs ESP as bridge |
| Raspberry Pi | Python client | Separate implementation |

## Dependencies

- ArduinoJson v7.0+
- PubSubClient v2.8+
- Arduino framework

## Quick Start

```cpp
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

NexlozaClient nexloza;

void setup() {
  Serial.begin(115200);
  NexlozaWiFi::begin("MyWiFi", "MyPassword");

  NexlozaConfig config;
  config.serverHost      = "your-server.com";
  config.mqttPort        = 1883;
  config.deviceId        = "device-001";
  config.apiKey          = "your-key";
  config.apiSecret       = "your-secret";
  config.organizationId  = "your-org";
  config.projectId       = "your-project";
  config.useTLS          = false;

  nexloza.begin(config);
  nexloza.connect();
}

void loop() {
  nexloza.loop();
  nexloza.publishTelemetry("temperature", 23.5);
  delay(10000);
}
```

## Next Steps

- [SDK Installation](SDK_INSTALLATION.md)
- [ESP32 Setup](ESP32_SETUP.md)
- [ESP8266 Setup](ESP8266_SETUP.md)
- [Firmware Examples](FIRMWARE_EXAMPLES.md)
