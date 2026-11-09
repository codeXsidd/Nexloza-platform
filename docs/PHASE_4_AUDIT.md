# Phase 4 Audit — Universal Device SDK & Firmware

**Date:** 2026-11-09
**Baseline commit:** 41d162c (Phase 3 complete)
**Flutter test baseline:** 224/224 passing

## Existing SDK Inventory

### Core SDK Files (`firmware/nexloza-sdk/`)

| File | Status | Notes |
|------|--------|-------|
| `src/NexlozaClient.h` | Exists | Config struct, 15 public methods, callback types |
| `src/NexlozaClient.cpp` | Exists | Full implementation: auth, MQTT, heartbeat, reconnect, OTA |
| `src/NexlozaWiFi.h` | Exists | Static WiFi helper (begin, reconnect, status) |
| `src/NexlozaWiFi.cpp` | Exists | Complete implementation |
| `src/NexlozaProvisioning.h` | Exists | Captive portal AP, credential storage (ESP32 NVS / ESP8266 EEPROM) |
| `src/NexlozaProvisioning.cpp` | Exists | Complete: AP setup, web form, save/load/clear credentials |
| `library.json` | Exists | PlatformIO metadata, Apache-2.0 |
| `library.properties` | Exists | Arduino IDE metadata |

### Existing API Surface

| Method | Implemented | Notes |
|--------|-------------|-------|
| `begin(config)` | Yes | Sets up topics, MQTT client, TLS |
| `connect()` | Yes | HTTP auth + MQTT connect with LWT |
| `disconnect()` | Yes | Publishes offline status, disconnects |
| `isConnected()` | Yes | |
| `loop()` | Yes | MQTT loop + auto-heartbeat + reconnect |
| `publishTelemetry(key, float)` | Yes | Single sensor value |
| `publishTelemetry(key, string)` | Yes | String value variant |
| `publishTelemetry(JsonDocument)` | Yes | Batch telemetry |
| `reportState(actuatorKey, state)` | Yes | Retained on state topic |
| `reportDeviceInfo(fw, heap, rssi)` | Yes | Published to status topic |
| `registerSensor(key, type, unit)` | Yes | Published to state topic |
| `registerActuator(key, type)` | Yes | Published to state topic |
| `sendCommand(target, type, payload)` | Yes | Cross-device command |
| `setDeviceMetadata(key, value)` | Yes | Stored in JsonDocument |
| `onCommand(callback)` | Yes | |
| `onConnectionChange(callback)` | Yes | |
| `acknowledgeCommand(id, success, msg)` | Yes | Published to command-ack topic |
| `heartbeat()` | Yes | Status + uptime + heap + RSSI |
| `reconnect()` | Yes | Resets counter and calls connect() |
| `enableOTA(bool)` | Yes | Subscribes to OTA topic |
| `checkForUpdate()` | Yes | Publishes OTA check request |

### Existing Examples

| Example | Board | Type |
|---------|-------|------|
| esp32-led | ESP32 | Actuator (built-in LED) |
| esp32-relay-light | ESP32 | Actuator (relay) |
| esp32-relay-fan | ESP32 | Actuator (relay + PWM) |
| esp32-dht22 | ESP32 | Sensor (temperature + humidity) |
| esp32-soil-moisture | ESP32 | Sensor (capacitive ADC) |
| esp32-pir-motion | ESP32 | Sensor (interrupt-based) |
| esp32-multi-sensor | ESP32 | Sensor (DHT22 + BMP280 + LDR) |
| esp32-universal | ESP32 | Mixed (ADC + relay + LED PWM) |
| esp8266-led | ESP8266 | Actuator (built-in LED, active-LOW) |
| esp8266-relay | ESP8266 | Actuator (relay on D1) |
| arduino-uno | Arduino | README only (gateway approach) |
| raspberry-pi | RPi | Python client |

### Issues Found

1. **Raspberry Pi client uses old topic format** — `nexloza/{project}/{device}/{channel}` instead of v1 canonical
2. **Firmware README shows old topic format** — missing v1 prefix, wrong channel names
3. **NexlozaConfig missing organizationId in some examples** — examples compile but config field must be set
4. **No sensor/actuator abstraction framework** — sensors are handled ad-hoc in each example
5. **No error callback mechanism** — errors only go to Serial
6. **No command expiry checking** — SDK auto-acknowledges all commands regardless of expiry
7. **No message ID generation** — telemetry lacks unique IDs per spec
8. **No configurable log levels** — everything prints to Serial unconditionally
9. **TLS uses setInsecure()** — placeholder, no CA cert support yet
10. **No two-channel relay example** — spec requires it
11. **No water-level sensor example** — spec requires it
12. **No ultrasonic distance example** — spec requires it  
13. **No reconnection demo example** — spec requires it
14. **No provisioning demo example** — spec requires it
15. **No smart-home combined demo** — spec requires it
16. **Missing ESP8266 examples** — temperature, humidity, soil moisture, multi-sensor, reconnection
17. **PlatformIO not installed** — cannot verify firmware compilation on this machine
18. **library.properties says MIT but library.json says Apache-2.0** — license mismatch

## Compilation Status

PlatformIO is not available on this development machine. Firmware compilation cannot be verified locally. All examples will be written to compile against PlatformIO toolchains, but actual compilation is classified as **hardware-not-verified**.
