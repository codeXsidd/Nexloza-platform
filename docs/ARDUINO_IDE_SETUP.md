# Arduino IDE Setup

## Step 1: Install Arduino IDE

Download from [arduino.cc/en/software](https://www.arduino.cc/en/software). Version 2.x is recommended.

## Step 2: Add Board Support

1. Open **File → Preferences**
2. In "Additional Boards Manager URLs", add (comma-separated):
   ```
   https://espressif.github.io/arduino-esp32/package_esp32_index.json,http://arduino.esp8266.com/stable/package_esp8266com_index.json
   ```
3. Click OK

### Install ESP32 Board Package

1. Open **Tools → Board → Boards Manager**
2. Search for `esp32`
3. Install **esp32** by Espressif Systems (latest version)

### Install ESP8266 Board Package

1. Search for `esp8266`
2. Install **esp8266** by ESP8266 Community (latest version)

## Step 3: Install Libraries

Open **Sketch → Include Library → Manage Libraries**:

1. Search `ArduinoJson` → install version **7.x** by Benoit Blanchon
2. Search `PubSubClient` → install version **2.8** by Nick O'Leary
3. For DHT22 examples: search `DHT sensor library` → install by Adafruit

## Step 4: Install NexlozaSDK

### Manual Installation

1. Download or clone the Nexloza repository
2. Navigate to `firmware/nexloza-sdk/src/`
3. Copy all `.h` and `.cpp` files
4. Create a folder in your Arduino libraries directory:
   - **Windows**: `C:\Users\{you}\Documents\Arduino\libraries\NexlozaSDK\src\`
   - **macOS**: `~/Documents/Arduino/libraries/NexlozaSDK/src/`
   - **Linux**: `~/Arduino/libraries/NexlozaSDK/src/`
5. Paste the files into the `src/` folder
6. Restart Arduino IDE

## Step 5: Select Board

### For ESP32
**Tools → Board → ESP32 Arduino → ESP32 Dev Module**

### For ESP8266
**Tools → Board → ESP8266 Boards → NodeMCU 1.0 (ESP-12E Module)**

## Step 6: Select Port

1. Connect your board via USB
2. **Tools → Port** → select the COM port that appeared

## Step 7: Open an Example

1. Copy an example's `main.cpp` content
2. Paste into a new sketch
3. Replace credential placeholders with your values
4. Define credentials as constants at the top of the file:

```cpp
#define WIFI_SSID     "YourWiFi"
#define WIFI_PASS     "YourPassword"
#define NEXLOZA_SERVER    "your-server.supabase.co"
#define NEXLOZA_DEVICE_ID "your-device-uuid"
#define NEXLOZA_API_KEY   "your-api-key"
#define NEXLOZA_API_SECRET "your-api-secret"
#define NEXLOZA_ORG_ID    "your-org-uuid"
#define NEXLOZA_PROJECT_ID "your-project-uuid"
```

## Step 8: Upload

Click the **Upload** button (→ arrow). Open **Tools → Serial Monitor** at 115200 baud.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Board not in list | Verify board URLs in Preferences, restart IDE |
| "No such file" for includes | Verify library files are in the correct folder |
| Compilation errors | Ensure ArduinoJson v7 (not v6), PubSubClient v2.8+ |
| Upload timeout | Hold BOOT button on ESP32 during upload |
| Wrong baud rate | Set Serial Monitor to 115200 |
