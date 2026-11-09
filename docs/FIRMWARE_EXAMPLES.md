# Firmware Examples Index

## ESP32 Examples

| Example | Type | Hardware | Description |
|---------|------|----------|-------------|
| [esp32-led](../firmware/examples/esp32-led/) | Actuator | Built-in LED | Toggle LED via MQTT commands |
| [esp32-relay-light](../firmware/examples/esp32-relay-light/) | Actuator | Relay (GPIO 27) | Light switch with state reporting |
| [esp32-relay-fan](../firmware/examples/esp32-relay-fan/) | Actuator | Relay + PWM (GPIO 26, 25) | Fan ON/OFF + speed control |
| [esp32-two-relay](../firmware/examples/esp32-two-relay/) | Actuator | 2x Relay (GPIO 26, 27) | Independent two-channel relay control |
| [esp32-dht22](../firmware/examples/esp32-dht22/) | Sensor | DHT22 (GPIO 4) | Temperature and humidity |
| [esp32-soil-moisture](../firmware/examples/esp32-soil-moisture/) | Sensor | Capacitive (GPIO 34) | Soil moisture percentage |
| [esp32-pir-motion](../firmware/examples/esp32-pir-motion/) | Sensor | HC-SR501 (GPIO 14) | Interrupt-based motion detection |
| [esp32-ultrasonic](../firmware/examples/esp32-ultrasonic/) | Sensor | HC-SR04 (GPIO 12, 14) | Distance measurement in cm |
| [esp32-water-level](../firmware/examples/esp32-water-level/) | Sensor | Analog (GPIO 34) | Water level percentage |
| [esp32-multi-sensor](../firmware/examples/esp32-multi-sensor/) | Sensor | DHT22 + BMP280 + LDR | Multiple sensors with batch telemetry |
| [esp32-smart-home](../firmware/examples/esp32-smart-home/) | Mixed | DHT22 + Relay + PIR + LED | Full smart-home demo device |
| [esp32-universal](../firmware/examples/esp32-universal/) | Mixed | ADC + Relay + LED PWM | All SDK capabilities demo |
| [esp32-reconnect-demo](../firmware/examples/esp32-reconnect-demo/) | Demo | Built-in LED | Reconnection handling and error callbacks |
| [esp32-provisioning](../firmware/examples/esp32-provisioning/) | Demo | Button (BOOT) | Captive portal zero-code setup |

## ESP8266 Examples

| Example | Type | Hardware | Description |
|---------|------|----------|-------------|
| [esp8266-led](../firmware/examples/esp8266-led/) | Actuator | Built-in LED (GPIO 2) | Active-LOW LED control |
| [esp8266-relay](../firmware/examples/esp8266-relay/) | Actuator | Relay (D1/GPIO 5) | Relay switch on NodeMCU |
| [esp8266-dht22](../firmware/examples/esp8266-dht22/) | Sensor | DHT22 (D2/GPIO 4) | Temperature and humidity |
| [esp8266-soil-moisture](../firmware/examples/esp8266-soil-moisture/) | Sensor | Analog (A0) | Soil moisture percentage |
| [esp8266-multi-sensor](../firmware/examples/esp8266-multi-sensor/) | Sensor | DHT22 + LDR | Multiple sensors with batch telemetry |
| [esp8266-reconnect](../firmware/examples/esp8266-reconnect/) | Demo | Built-in LED | Reconnection handling |

## Other Platforms

| Example | Platform | Description |
|---------|----------|-------------|
| [arduino-uno](../firmware/examples/arduino-uno/) | Arduino Uno | Gateway approach (README documentation) |
| [raspberry-pi](../firmware/examples/raspberry-pi/) | Raspberry Pi | Python MQTT client with GPIO support |

## Getting Started with an Example

1. Choose an example that matches your hardware
2. Copy the example folder to your workspace
3. Edit `platformio.ini` with your WiFi and Nexloza credentials
4. Build and upload: `pio run --target upload`
5. Monitor: `pio device monitor`
6. Check the Nexloza dashboard for your device

## Wiring

See [WIRING.md](../firmware/WIRING.md) for pin connections and circuit diagrams for all examples.
