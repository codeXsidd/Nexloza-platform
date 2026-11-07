# Nexloza + Arduino Uno — Gateway Approach

The Arduino Uno (ATmega328P) has **no built-in WiFi, Bluetooth, or Ethernet**.
To connect an Uno to the Nexloza IoT platform you need an external
communication module or a gateway device.

## Connectivity Options

| Option | Module | Complexity | Recommendation |
|--------|--------|------------|----------------|
| WiFi via ESP8266 | ESP-01 / ESP-12 over UART | Medium | Good for simple bridging |
| Ethernet Shield | W5100 or W5500 shield | Low | Reliable, wired only |
| ESP32 Gateway | ESP32 runs Nexloza SDK | Low | **Recommended** — full SDK support |

### Recommended: Use ESP32 or ESP8266 as the Main Controller

The Nexloza firmware SDK targets **ESP32 and ESP8266 directly**. These boards
have built-in WiFi, plenty of RAM, and run the full SDK (MQTT, authentication,
heartbeat, OTA). In most cases the simplest path is:

- Replace the Uno with an **ESP32 DevKit** or **NodeMCU (ESP8266)**.
- Or keep the Uno for real-time I/O and use an ESP32/ESP8266 as a
  **serial gateway** that relays data to Nexloza over MQTT.

### Option A: Uno + ESP8266 Serial Bridge

The Uno sends sensor readings over its hardware or software serial port to an
ESP-01 (or NodeMCU). The ESP8266 runs a small sketch that forwards the data
to Nexloza via MQTT.

```
┌──────────────┐         UART          ┌──────────────────┐
│  Arduino Uno │  TX (pin 1) -------->  │  ESP-01 / ESP-12 │
│              │  RX (pin 0) <--------  │  (runs Nexloza   │
│  (sensors,   │  GND ──────── GND      │   SDK firmware)  │
│   actuators) │                        │                  │
│              │                        │  WiFi ──> MQTT   │
└──────────────┘                        └──────────────────┘
```

**Wiring (Uno -> ESP-01):**

| Uno Pin | ESP-01 Pin | Notes |
|---------|------------|-------|
| TX (1) | RX | 5 V -> 3.3 V level shifter required |
| RX (0) | TX | ESP-01 TX is already 3.3 V |
| GND | GND | Common ground |
| — | VCC | 3.3 V supply (NOT 5 V!) |
| — | CH_PD (EN) | Tie HIGH to 3.3 V |

> **Important:** The ESP-01 is a 3.3 V device. Use a voltage divider or
> level shifter on the Uno TX -> ESP-01 RX line, or power the Uno at 3.3 V.

**How it works:**

1. The Uno reads sensors and formats a simple serial message
   (e.g., `TEMP:23.5\n`).
2. The ESP-01 sketch parses incoming serial data and calls
   `nexloza.publishTelemetry(...)`.
3. Commands from Nexloza arrive via MQTT on the ESP-01, which forwards
   them over serial to the Uno.

### Option B: Ethernet Shield

Use a W5100 or W5500 Ethernet shield with any Arduino MQTT library
(e.g., `PubSubClient`). You will need to handle authentication and topic
formatting manually — the Nexloza SDK's WiFi and HTTP helpers are
ESP-specific, but the MQTT topic structure is documented in the
[firmware README](../../README.md#mqtt-topic-structure).

### Option C: ESP32 as Full Gateway

Run the Nexloza SDK on an ESP32. The ESP32 reads the Uno over I2C or UART
and publishes telemetry on its behalf. This gives you OTA updates,
heartbeat, and all other SDK features with no custom protocol work.

## Why Not a Direct Uno Port?

- The ATmega328P has only **2 KB RAM** — too small for TLS, JSON parsing,
  and the MQTT + HTTP authentication the SDK requires.
- No built-in networking hardware.
- Arduino libraries for WiFi shields (e.g., WiFi101, WiFiNINA) have
  different APIs than ESP32/ESP8266, so the SDK would need a separate port.

For new projects, an ESP32 DevKit costs roughly the same as an Uno + WiFi
module and is far simpler to set up.

## Further Reading

- [Firmware README](../../README.md) — SDK features, MQTT topics, getting started
- [ESP8266 LED example](../esp8266-led/) — minimal ESP8266 example
- [ESP32 LED example](../esp32-led/) — minimal ESP32 example
- [ESP8266 Relay example](../esp8266-relay/) — relay control on NodeMCU
