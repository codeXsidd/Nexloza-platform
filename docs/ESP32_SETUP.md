# ESP32 Setup Guide

## What You Need

1. An ESP32 development board (DevKitC, NodeMCU-32S, Wemos D1 R32, etc.)
2. A USB cable (micro-USB or USB-C depending on your board)
3. A computer with PlatformIO or Arduino IDE installed
4. A Nexloza platform account with a registered device

## Step 1: Install USB Drivers

Most ESP32 boards use a CP2102 or CH340 USB-to-serial chip.

- **CP2102**: Download from [Silicon Labs](https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers)
- **CH340**: Download from [WCH](http://www.wch-ic.com/downloads/CH341SER_ZIP.html)

After installing, connect your ESP32 via USB. It should appear as a COM port (Windows) or `/dev/ttyUSB0` (Linux).

## Step 2: Set Up the Project

### Using PlatformIO

```bash
# Clone or copy an example
cp -r firmware/examples/esp32-led my-device
cd my-device
```

Edit `platformio.ini` build flags with your credentials:

```ini
build_flags =
    -DWIFI_SSID=\"YourWiFiName\"
    -DWIFI_PASS=\"YourWiFiPassword\"
    -DNEXLOZA_SERVER=\"your-server.supabase.co\"
    -DNEXLOZA_DEVICE_ID=\"your-device-uuid\"
    -DNEXLOZA_API_KEY=\"your-api-key\"
    -DNEXLOZA_API_SECRET=\"your-api-secret\"
    -DNEXLOZA_ORG_ID=\"your-org-uuid\"
    -DNEXLOZA_PROJECT_ID=\"your-project-uuid\"
```

### Using Arduino IDE

1. Select **Tools → Board → ESP32 Dev Module**
2. Select the correct COM port under **Tools → Port**
3. Set **Upload Speed** to 921600

## Step 3: Build and Upload

### PlatformIO

```bash
pio run --target upload
```

### Arduino IDE

Click the **Upload** button (→ arrow).

## Step 4: Monitor Serial Output

### PlatformIO

```bash
pio device monitor
```

### Arduino IDE

Open **Tools → Serial Monitor** and set baud rate to **115200**.

Expected output:

```
=== Nexloza ESP32 LED Controller ===
[INFO][Nexloza WiFi] Connecting to YourWiFi...
[INFO][Nexloza WiFi] Connected, IP: 192.168.1.42
[INFO][Nexloza] Authenticating device...
[INFO][Nexloza] Authentication successful
[INFO][Nexloza] MQTT connected
```

## Step 5: Verify in Nexloza Dashboard

1. Open your Nexloza project dashboard
2. Navigate to Devices
3. Your device should show as **Online**
4. Telemetry data should start appearing

## ESP32 GPIO Reference

| Pin | Features | Notes |
|-----|----------|-------|
| GPIO 2 | Built-in LED | Blue LED on most DevKit boards |
| GPIO 4 | ADC, Touch | Good for DHT22 data |
| GPIO 12-14 | ADC, Touch | General purpose |
| GPIO 25-27 | DAC, ADC | Good for relays/actuators |
| GPIO 32-39 | ADC only | 32-33: R/W, 34-39: input-only |
| GPIO 21 | I2C SDA | Default I2C data |
| GPIO 22 | I2C SCL | Default I2C clock |

## Common Issues

| Problem | Solution |
|---------|----------|
| Upload fails | Hold BOOT button during upload |
| No serial output | Check baud rate is 115200 |
| WiFi won't connect | Verify SSID and password, check 2.4GHz |
| Auth fails | Verify API key/secret match your device |
| Random restarts | Add 100µF capacitor near power pins |
