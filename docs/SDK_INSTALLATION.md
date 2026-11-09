# SDK Installation

## Option 1: PlatformIO (Recommended)

PlatformIO handles dependencies and board configuration automatically.

### Step 1: Install PlatformIO

```bash
pip install platformio
```

Or install the [PlatformIO IDE extension](https://platformio.org/install/ide) for VS Code.

### Step 2: Create a Project

```bash
mkdir my-nexloza-device
cd my-nexloza-device
pio init --board esp32dev  # or esp8266dev
```

### Step 3: Add Dependencies

Edit `platformio.ini`:

```ini
[env:esp32]
platform = espressif32
board = esp32dev
framework = arduino
lib_deps =
    bblanchon/ArduinoJson@^7.0.0
    knolleary/PubSubClient@^2.8.0
lib_extra_dirs = /path/to/nexloza-platform/firmware/nexloza-sdk
```

### Step 4: Build and Upload

```bash
pio run --target upload
pio device monitor
```

## Option 2: Arduino IDE

### Step 1: Install Arduino IDE

Download from [arduino.cc](https://www.arduino.cc/en/software).

### Step 2: Add Board Support

1. Open **File → Preferences**
2. Add to "Additional Boards Manager URLs":
   - ESP32: `https://espressif.github.io/arduino-esp32/package_esp32_index.json`
   - ESP8266: `http://arduino.esp8266.com/stable/package_esp8266com_index.json`
3. Open **Tools → Board → Boards Manager**
4. Search and install:
   - `esp32` by Espressif Systems
   - `esp8266` by ESP8266 Community

### Step 3: Install Libraries

Open **Sketch → Include Library → Manage Libraries** and install:
- ArduinoJson (by Benoit Blanchon) — version 7.0+
- PubSubClient (by Nick O'Leary) — version 2.8+

### Step 4: Install NexlozaSDK

Copy the SDK source files into your Arduino libraries folder:

**Windows:**
```
C:\Users\{username}\Documents\Arduino\libraries\NexlozaSDK\src\
```

**macOS:**
```
~/Documents/Arduino/libraries/NexlozaSDK/src/
```

**Linux:**
```
~/Arduino/libraries/NexlozaSDK/src/
```

Copy these files into the `src/` folder:
- `NexlozaClient.h` / `NexlozaClient.cpp`
- `NexlozaWiFi.h` / `NexlozaWiFi.cpp`
- `NexlozaProvisioning.h` / `NexlozaProvisioning.cpp`
- `NexlozaSensor.h`
- `NexlozaActuator.h`
- `NexlozaLogger.h` / `NexlozaLogger.cpp`

### Step 5: Verify

1. Open Arduino IDE
2. Select your board under **Tools → Board**
3. Create a new sketch with `#include <NexlozaClient.h>`
4. Click **Verify** — should compile without errors

## SDK Files

| File | Purpose |
|------|---------|
| `NexlozaClient.h/.cpp` | Main SDK — MQTT, auth, telemetry, commands |
| `NexlozaWiFi.h/.cpp` | WiFi connection management |
| `NexlozaProvisioning.h/.cpp` | Captive portal for device setup |
| `NexlozaSensor.h` | Sensor framework (base + analog + digital) |
| `NexlozaActuator.h` | Actuator framework (base + digital + PWM) |
| `NexlozaLogger.h/.cpp` | Configurable logging |
