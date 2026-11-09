# Device Provisioning

## Overview

NexlozaProvisioning provides a captive portal that lets users configure their device's WiFi and Nexloza credentials through a web browser — no code changes needed after initial firmware upload.

## How It Works

1. Device boots and checks for saved credentials
2. If no credentials found, device starts a WiFi Access Point ("Nexloza-Setup")
3. User connects to the AP from their phone or computer
4. A setup page opens automatically (captive portal)
5. User enters WiFi credentials and Nexloza device details
6. Device saves credentials to persistent storage
7. Device restarts and connects to WiFi and Nexloza

## ProvisioningData Struct

```cpp
struct ProvisioningData {
  char wifiSSID[64];
  char wifiPassword[64];
  char serverHost[128];
  uint16_t mqttPort;
  char deviceId[64];
  char apiKey[64];
  char apiSecret[128];
  char organizationId[64];
  char projectId[64];
  bool valid;
};
```

## API

```cpp
NexlozaProvisioning provisioning;

provisioning.beginAP("Nexloza-Setup");  // Start AP with captive portal
provisioning.handleClient();             // Call in loop during setup mode
provisioning.isProvisioned();            // Check if credentials exist
provisioning.isComplete();               // Check if user submitted the form
provisioning.loadCredentials();          // Load saved ProvisioningData
provisioning.saveCredentials(data);      // Save manually
provisioning.clearCredentials();         // Factory reset
```

## Storage

### ESP32 — NVS (Non-Volatile Storage)

ESP32 uses the Preferences library which writes to NVS flash. Data persists across reboots and firmware updates.

Keys stored: `wifi_ssid`, `wifi_pass`, `server_host`, `mqtt_port`, `device_id`, `api_key`, `api_secret`, `org_id`, `project_id`, `provisioned`.

### ESP8266 — EEPROM

ESP8266 uses emulated EEPROM (512 bytes). A magic number (`0x4E58` = "NX") marks valid data.

**Limitations:**
- EEPROM has ~100,000 write cycles
- Data may be lost during OTA updates depending on flash layout
- Less secure than NVS (no encryption)

## Example Usage

```cpp
#include <NexlozaProvisioning.h>
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

NexlozaProvisioning provisioning;
NexlozaClient nexloza;

void setup() {
  Serial.begin(115200);

  if (!provisioning.isProvisioned()) {
    Serial.println("Not provisioned — starting setup portal");
    provisioning.beginAP("Nexloza-Setup");
    while (!provisioning.isComplete()) {
      provisioning.handleClient();
      delay(10);
    }
    ESP.restart();
  }

  ProvisioningData creds = provisioning.loadCredentials();
  NexlozaWiFi::begin(creds.wifiSSID, creds.wifiPassword);

  NexlozaConfig config;
  config.serverHost      = creds.serverHost;
  config.mqttPort        = creds.mqttPort;
  config.deviceId        = creds.deviceId;
  config.apiKey          = creds.apiKey;
  config.apiSecret       = creds.apiSecret;
  config.organizationId  = creds.organizationId;
  config.projectId       = creds.projectId;
  config.useTLS          = false;

  nexloza.begin(config);
  nexloza.connect();
}
```

## Factory Reset

To clear saved credentials and re-enter provisioning mode:

```cpp
provisioning.clearCredentials();
ESP.restart();
```

A common pattern is to trigger this with a button hold on boot (e.g., hold BOOT button for 5 seconds).

## Security Considerations

- Credentials are stored in plaintext on ESP8266 EEPROM
- ESP32 NVS supports encryption (not enabled by default)
- The captive portal runs over HTTP (not HTTPS) — use only on local AP
- Never expose the AP to untrusted networks in production
- Consider disabling the AP once provisioned
