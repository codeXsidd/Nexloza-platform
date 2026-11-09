// Nexloza ESP32 Provisioning Example
// ====================================
//
// Demonstrates zero-code device setup via a captive portal.
//
// First boot (not provisioned):
//   1. ESP32 starts a WiFi Access Point named "Nexloza-Setup".
//   2. Connect to it with a phone or laptop.
//   3. A captive portal opens automatically.
//   4. Enter WiFi credentials, server host, device ID, API keys,
//      organization ID, and project ID.
//   5. Tap Save — credentials are stored in ESP32 NVS (non-volatile).
//   6. ESP32 restarts and connects using the saved credentials.
//
// Subsequent boots:
//   ESP32 reads saved credentials from NVS and connects immediately.
//
// To reset credentials, send a "factory_reset" command via MQTT or
// hold GPIO 0 (BOOT button) LOW for 5 seconds during startup.
//
// No build_flags for credentials are needed — they come from the portal.

#include <Arduino.h>
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>
#include <NexlozaProvisioning.h>

#define LED_PIN      2
#define RESET_PIN    0  // BOOT button on most ESP32 DevKits
#define RESET_HOLD_MS 5000

NexlozaClient nexloza;
NexlozaProvisioning provisioning;
bool deviceReady = false;

void handleCommand(const char* commandType, JsonObject& payload) {
  if (strcmp(commandType, "factory_reset") == 0) {
    Serial.println("[CMD] Factory reset requested");
    provisioning.clearCredentials();
    delay(500);
    ESP.restart();
  } else if (strcmp(commandType, "get_state") == 0) {
    JsonDocument state;
    state["provisioned"] = true;
    state["uptime_s"] = millis() / 1000;
    state["free_heap"] = ESP.getFreeHeap();
    nexloza.reportState("device", state);
  }
}

void handleConnection(bool connected) {
  digitalWrite(LED_PIN, connected ? HIGH : LOW);
  Serial.printf("[CONN] %s\n", connected ? "Connected" : "Disconnected");
}

bool checkResetButton() {
  if (digitalRead(RESET_PIN) == LOW) {
    Serial.println("[RESET] BOOT button held — hold for 5s to factory reset...");
    unsigned long start = millis();
    while (digitalRead(RESET_PIN) == LOW) {
      if (millis() - start >= RESET_HOLD_MS) {
        Serial.println("[RESET] Factory reset triggered!");
        provisioning.clearCredentials();
        delay(500);
        ESP.restart();
        return true;
      }
      delay(100);
    }
    Serial.println("[RESET] Released early — reset cancelled");
  }
  return false;
}

void startProvisioning() {
  Serial.println("\n========================================");
  Serial.println("  Device not provisioned.");
  Serial.println("  Starting WiFi setup portal...");
  Serial.println("  Connect to WiFi: \"Nexloza-Setup\"");
  Serial.println("  Then open http://192.168.4.1");
  Serial.println("========================================\n");

  provisioning.beginAP("Nexloza-Setup");

  while (!provisioning.isComplete()) {
    provisioning.handleClient();

    // Blink LED while in AP mode
    static unsigned long lastBlink = 0;
    static bool ledState = false;
    if (millis() - lastBlink >= 300) {
      ledState = !ledState;
      digitalWrite(LED_PIN, ledState ? HIGH : LOW);
      lastBlink = millis();
    }

    delay(10);
  }

  Serial.println("[PROV] Credentials saved — restarting...");
  delay(1000);
  ESP.restart();
}

void connectWithSavedCredentials() {
  ProvisioningData creds = provisioning.loadCredentials();

  Serial.printf("[PROV] Loaded: SSID=%s Server=%s Device=%s\n",
                creds.wifiSSID, creds.serverHost, creds.deviceId);

  if (!NexlozaWiFi::begin(creds.wifiSSID, creds.wifiPassword)) {
    Serial.println("WiFi failed — entering provisioning mode...");
    startProvisioning();
    return;
  }

  NexlozaConfig config;
  config.serverHost           = creds.serverHost;
  config.mqttPort             = creds.mqttPort;
  config.deviceId             = creds.deviceId;
  config.apiKey               = creds.apiKey;
  config.apiSecret            = creds.apiSecret;
  config.organizationId       = creds.organizationId;
  config.projectId            = creds.projectId;
  config.useTLS               = false;
  config.heartbeatIntervalMs  = 30000;
  config.reconnectIntervalMs  = 5000;
  config.maxReconnectAttempts = 10;

  nexloza.begin(config);
  nexloza.onCommand(handleCommand);
  nexloza.onConnectionChange(handleConnection);
  nexloza.connect();
  nexloza.reportDeviceInfo(FIRMWARE_VERSION, ESP.getFreeHeap(), WiFi.RSSI());

  deviceReady = true;
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== Nexloza ESP32 Provisioning Demo ===");

  pinMode(LED_PIN, OUTPUT);
  pinMode(RESET_PIN, INPUT_PULLUP);
  digitalWrite(LED_PIN, LOW);

  checkResetButton();

  if (provisioning.isProvisioned()) {
    Serial.println("[PROV] Device is provisioned — connecting...");
    connectWithSavedCredentials();
  } else {
    startProvisioning();
  }
}

void loop() {
  if (!deviceReady) return;

  if (!NexlozaWiFi::isConnected()) NexlozaWiFi::reconnect();
  nexloza.loop();

  delay(10);
}
