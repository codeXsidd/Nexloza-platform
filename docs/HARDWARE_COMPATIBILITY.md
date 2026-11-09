# Hardware Compatibility

## Supported Microcontrollers

### ESP32

| Board | Chip | Flash | RAM | WiFi | BLE | ADC Pins | Status |
|-------|------|-------|-----|------|-----|----------|--------|
| ESP32 DevKit v1 | ESP32-WROOM-32 | 4 MB | 520 KB | 802.11 b/g/n | 4.2 | 18 | Fully tested |
| ESP32-S2 | ESP32-S2 | 4 MB | 320 KB | 802.11 b/g/n | No | 20 | Compatible |
| ESP32-S3 | ESP32-S3 | 8 MB | 512 KB | 802.11 b/g/n | 5.0 | 20 | Compatible |
| ESP32-C3 | ESP32-C3 | 4 MB | 400 KB | 802.11 b/g/n | 5.0 | 6 | Compatible |
| NodeMCU-32S | ESP32-WROOM-32 | 4 MB | 520 KB | 802.11 b/g/n | 4.2 | 18 | Fully tested |

**Recommended for beginners:** ESP32 DevKit v1 — widely available, well-documented, all examples tested on this board.

### ESP8266

| Board | Chip | Flash | RAM | WiFi | ADC | Status |
|-------|------|-------|-----|------|-----|--------|
| NodeMCU v3 (Lolin) | ESP8266EX | 4 MB | 80 KB | 802.11 b/g/n | 1 (A0) | Fully tested |
| Wemos D1 Mini | ESP8266EX | 4 MB | 80 KB | 802.11 b/g/n | 1 (A0) | Compatible |
| ESP-01 | ESP8266EX | 1 MB | 80 KB | 802.11 b/g/n | No | Limited (2 GPIO) |

**Note:** ESP8266 has only **one** analog input (A0, 0–1V range) and limited GPIO. For multi-sensor projects, use ESP32.

### Raspberry Pi

| Board | RAM | WiFi | GPIO | Status |
|-------|-----|------|------|--------|
| Raspberry Pi 4B | 2–8 GB | 802.11ac | 40-pin | Compatible |
| Raspberry Pi 3B+ | 1 GB | 802.11n | 40-pin | Compatible |
| Raspberry Pi Zero 2 W | 512 MB | 802.11n | 40-pin | Compatible |
| Raspberry Pi Pico W | 264 KB | 802.11n | 26 GPIO | Not supported (no Python runtime) |

Raspberry Pi uses the Python client (`nexloza_device.py`), not the C++ SDK.

### Arduino (Gateway Mode)

| Board | RAM | WiFi | Notes |
|-------|-----|------|-------|
| Arduino Uno R3 | 2 KB | No | Requires WiFi shield or ESP gateway |
| Arduino Mega 2560 | 8 KB | No | Requires WiFi shield or ESP gateway |

Arduino boards without WiFi cannot connect directly. Use an ESP32/ESP8266 as a gateway that forwards Serial data to MQTT.

## Supported Sensors

| Sensor | Type | Interface | ESP32 | ESP8266 | Example |
|--------|------|-----------|-------|---------|---------|
| DHT22 / AM2302 | Temperature + Humidity | Digital (1-wire) | Yes | Yes | esp32-dht22, esp8266-dht22 |
| DHT11 | Temperature + Humidity | Digital (1-wire) | Yes | Yes | Use DHT22 example, change type |
| BMP280 | Temperature + Pressure | I2C | Yes | Yes | esp32-multi-sensor |
| HC-SR501 | PIR Motion | Digital | Yes | Yes | esp32-pir-motion |
| HC-SR04 | Ultrasonic Distance | Trigger + Echo | Yes | Yes* | esp32-ultrasonic |
| Capacitive Soil Moisture | Soil Moisture | Analog | Yes | Yes (A0 only) | esp32-soil-moisture |
| Resistive Soil Moisture | Soil Moisture | Analog | Yes | Yes (A0 only) | Use soil-moisture example |
| LDR (Photoresistor) | Light Level | Analog | Yes | Yes (A0 only) | esp32-multi-sensor |
| Water Level Sensor | Water Level | Analog | Yes | Yes (A0 only) | esp32-water-level |

*HC-SR04 with ESP8266 requires a voltage divider on the Echo pin (5V → 3.3V).

## Supported Actuators

| Actuator | Type | Interface | ESP32 | ESP8266 | Example |
|----------|------|-----------|-------|---------|---------|
| 5V Relay Module (1-ch) | Switching | Digital | Yes | Yes | esp32-relay-light |
| 5V Relay Module (2-ch) | Switching | Digital | Yes | Yes | esp32-two-relay |
| LED (built-in) | Indicator | Digital | Yes | Yes | esp32-led, esp8266-led |
| External LED | Indicator | Digital/PWM | Yes | Yes | Any LED example |
| 5V DC Fan | Motor | PWM | Yes | Limited | esp32-relay-fan |
| Servo Motor (SG90) | Positioning | PWM | Yes | Yes | Custom actuator |
| Buzzer | Audio | Digital/PWM | Yes | Yes | Custom actuator |

## GPIO Quick Reference

### ESP32 Safe Pins

| Use | Recommended Pins | Avoid |
|-----|-----------------|-------|
| Digital Output | 2, 4, 5, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27, 32, 33 | 0, 1, 3, 6–11 |
| Digital Input | 4, 5, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27, 32, 33, 34, 35, 36, 39 | 0, 1, 3, 6–11 |
| Analog Input (ADC1) | 32, 33, 34, 35, 36, 39 | ADC2 (0, 2, 4, 12–15, 25–27) conflicts with WiFi |
| PWM | Any output-capable pin | — |
| I2C | SDA=21, SCL=22 (default) | — |

**Critical:** GPIO 6–11 are connected to the internal flash — never use them. GPIO 34–39 are input-only.

### ESP8266 (NodeMCU) Pin Mapping

| NodeMCU Label | GPIO | Safe for | Notes |
|---------------|------|----------|-------|
| D0 | 16 | Output | No PWM, no interrupt |
| D1 | 5 | I/O, I2C SCL | Recommended for relays |
| D2 | 4 | I/O, I2C SDA | Recommended for sensors |
| D3 | 0 | Input (with pull-up) | BOOT pin — avoid for output |
| D4 | 2 | Output | Built-in LED (active LOW) |
| D5 | 14 | I/O, SPI CLK | General purpose |
| D6 | 12 | I/O, SPI MISO | General purpose |
| D7 | 13 | I/O, SPI MOSI | General purpose |
| D8 | 15 | Output (with pull-down) | Must be LOW at boot |
| A0 | ADC | Analog input | 0–1V range only |

## Power Requirements

| Component | Voltage | Current (typical) | Current (peak) |
|-----------|---------|-------------------|----------------|
| ESP32 DevKit | 5V USB / 3.3V | 80 mA | 500 mA (WiFi TX) |
| ESP8266 NodeMCU | 5V USB / 3.3V | 70 mA | 400 mA (WiFi TX) |
| DHT22 | 3.3–5V | 1.5 mA | 2.5 mA |
| HC-SR501 PIR | 5V | 65 µA | — |
| HC-SR04 | 5V | 15 mA | — |
| 5V Relay Module | 5V | 70 mA per channel | — |
| SG90 Servo | 5V | 100 mA | 700 mA (stall) |

**Important:** Do NOT power relay modules or servos from the ESP's 3.3V regulator. Use a separate 5V supply and share GND.

## Library Dependencies

| Library | Version | Used For | PlatformIO ID |
|---------|---------|----------|---------------|
| PubSubClient | 2.8+ | MQTT | knolleary/PubSubClient |
| ArduinoJson | 7.x | JSON serialization | bblanchon/ArduinoJson |
| DHT sensor library | 1.4+ | DHT11/DHT22 | adafruit/DHT sensor library |
| Adafruit Unified Sensor | 1.1+ | Sensor abstraction | adafruit/Adafruit Unified Sensor |
| Adafruit BMP280 | 2.6+ | BMP280 | adafruit/Adafruit BMP280 Library |

All dependencies are open-source and available through the PlatformIO and Arduino Library Manager.
