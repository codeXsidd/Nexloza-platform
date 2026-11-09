# Phase 4 Implementation Plan

## Approach

Extend the existing SDK at `firmware/nexloza-sdk/` — do not create a duplicate library. Add new modules alongside existing files using the same include patterns.

## Step 1: SDK Core Enhancements

### 1a. Add NexlozaSensor abstraction (`NexlozaSensor.h/.cpp`)
- Base class with: id, name, type, unit, min/max, precision, interval, metadata
- `read()` virtual method returns float
- `isAvailable()` virtual method
- Auto-publish telemetry at configurable interval
- Register with NexlozaClient for lifecycle management

### 1b. Add NexlozaActuator abstraction (`NexlozaActuator.h/.cpp`)
- Base class with: id, name, type, safe default, current state
- `execute(JsonObject& command)` virtual method
- `getState()` returns current state as JsonDocument
- Auto-acknowledge commands after execution
- Command expiry validation

### 1c. Add NexlozaLogger (`NexlozaLogger.h`)
- Log levels: NONE, ERROR, WARN, INFO, DEBUG
- Configurable at runtime
- Never prints credentials

### 1d. Enhance NexlozaClient
- Add `addSensor(NexlozaSensor*)` and `addActuator(NexlozaActuator*)`
- Add `onError(ErrorCallback)` callback
- Add command expiry checking (skip expired commands)
- Add message ID to telemetry payloads
- Add `setLogLevel()` method
- Fix auto-acknowledge to only fire after user callback returns

### 1e. Fix NexlozaProvisioning
- Add `organizationId` field to ProvisioningData and web form
- Update save/load for both ESP32 NVS and ESP8266 EEPROM

## Step 2: Fix Existing Issues

- Fix Raspberry Pi client topic format to v1 canonical
- Fix firmware README topic documentation
- Fix library.properties license (Apache-2.0 to match library.json)
- Ensure all examples set `organizationId` in config

## Step 3: New ESP32 Examples

| Example | Hardware |
|---------|----------|
| esp32-two-relay | Two relays on GPIO 26, 27 |
| esp32-ultrasonic | HC-SR04 on GPIO 12 (trig), 14 (echo) |
| esp32-water-level | Analog water level on GPIO 34 |
| esp32-reconnect-demo | Deliberate disconnect/reconnect demonstration |
| esp32-provisioning | Uses captive portal for zero-code setup |
| esp32-smart-home | Combined: DHT22 + relay + PIR + LED |

## Step 4: New ESP8266 Examples

| Example | Hardware |
|---------|----------|
| esp8266-dht22 | DHT22 on GPIO 4 (D2) |
| esp8266-soil-moisture | Analog on A0 |
| esp8266-multi-sensor | DHT22 + LDR |
| esp8266-reconnect | Reconnection demo |

## Step 5: Documentation (11 docs)

1. `docs/NEXLOZA_SDK_OVERVIEW.md`
2. `docs/SDK_INSTALLATION.md`
3. `docs/ESP32_SETUP.md`
4. `docs/ESP8266_SETUP.md`
5. `docs/ARDUINO_IDE_SETUP.md`
6. `docs/DEVICE_PROVISIONING.md`
7. `docs/SENSOR_DEVELOPMENT.md`
8. `docs/ACTUATOR_DEVELOPMENT.md`
9. `docs/FIRMWARE_EXAMPLES.md`
10. `docs/FIRMWARE_TROUBLESHOOTING.md`
11. `docs/HARDWARE_COMPATIBILITY.md`

## Step 6: Verification

1. `flutter analyze` — 0 issues
2. `flutter test` — 224+ tests passing
3. Firmware source review — no secrets, correct topics, proper error handling
4. Git diff review
5. Phase 4 completion report

## Compilation Note

PlatformIO is not installed. All firmware is written to compile against standard PlatformIO/Arduino toolchains but actual compilation is classified as **not verified on this machine**. The Phase 4 completion report will state this explicitly.
