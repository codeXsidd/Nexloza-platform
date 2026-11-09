# ESP8266 Setup Guide

## What You Need

1. An ESP8266 board (NodeMCU v3, Wemos D1 Mini, or ESP-12F module)
2. A micro-USB cable
3. PlatformIO or Arduino IDE
4. A Nexloza platform account with a registered device

## ESP8266 vs ESP32

| Feature | ESP8266 | ESP32 |
|---------|---------|-------|
| WiFi | 2.4 GHz | 2.4 GHz |
| Bluetooth | No | Yes |
| ADC pins | 1 (A0, 10-bit) | 18 (12-bit) |
| RAM | ~50 KB usable | ~320 KB usable |
| GPIO | ~11 usable | ~25 usable |
| PWM | Software (all pins) | Hardware (LED_PWM) |
| Built-in LED | GPIO 2 (active-LOW) | GPIO 2 (active-HIGH) |
| Price | Lower | Moderate |

## Step 1: Install USB Drivers

NodeMCU v3 typically uses CH340. Wemos D1 Mini uses CH340 or CP2102.

## Step 2: Set Up the Project

Edit `platformio.ini`:

```ini
[env:esp8266]
platform = espressif8266
board = esp8266dev
framework = arduino
monitor_speed = 115200
lib_deps =
    bblanchon/ArduinoJson@^7.0.0
    knolleary/PubSubClient@^2.8.0
lib_extra_dirs = ../../nexloza-sdk
build_flags =
    -DWIFI_SSID=\"YourWiFi\"
    -DWIFI_PASS=\"YourPassword\"
    -DNEXLOZA_SERVER=\"your-server.supabase.co\"
    -DNEXLOZA_DEVICE_ID=\"your-device-uuid\"
    -DNEXLOZA_API_KEY=\"your-key\"
    -DNEXLOZA_API_SECRET=\"your-secret\"
    -DNEXLOZA_ORG_ID=\"your-org-uuid\"
    -DNEXLOZA_PROJECT_ID=\"your-project-uuid\"
```

## Step 3: Build, Upload, Monitor

```bash
pio run --target upload
pio device monitor
```

## NodeMCU Pin Mapping

| NodeMCU Label | GPIO | Notes |
|---------------|------|-------|
| D0 | GPIO 16 | No interrupt, no PWM |
| D1 | GPIO 5 | I2C SCL, good for relays |
| D2 | GPIO 4 | I2C SDA, good for DHT22 |
| D3 | GPIO 0 | FLASH button, pull-up |
| D4 | GPIO 2 | Built-in LED (active-LOW) |
| D5 | GPIO 14 | SPI CLK |
| D6 | GPIO 12 | SPI MISO |
| D7 | GPIO 13 | SPI MOSI |
| D8 | GPIO 15 | SPI CS, pull-down |
| A0 | ADC | 0–1V (3.3V with NodeMCU divider) |

## Important Differences from ESP32

1. **Active-LOW LED**: `digitalWrite(2, LOW)` turns the LED ON
2. **Single ADC**: Only A0, 10-bit resolution (0–1023)
3. **Less RAM**: Avoid large JSON documents (keep under 256 bytes)
4. **No hardware PWM**: Uses software PWM (all GPIO pins)
5. **Boot pins**: GPIO 0, 2, 15 affect boot mode — avoid using for inputs at startup

## Common Issues

| Problem | Solution |
|---------|----------|
| Upload fails | Ensure D3/D4 are not connected to sensors during upload |
| LED behaves backwards | ESP8266 LED is active-LOW |
| Analog reads wrong | A0 range is 0–1V (NodeMCU has built-in divider for 3.3V) |
| Out of memory | Reduce JSON buffer sizes, use shorter strings |
| WiFi disconnects | ESP8266 WiFi is less stable than ESP32 — ensure good signal |
