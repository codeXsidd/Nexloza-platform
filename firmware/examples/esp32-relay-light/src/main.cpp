// Nexloza ESP32 Light Control Example
// Relay on GPIO 27
// WARNING: Use low-voltage loads for testing. AC mains wiring must be
// installed by a qualified electrician with appropriate protection.

#include <Arduino.h>
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

#define RELAY_PIN 27
#define FIRMWARE_VERSION "1.0.0"

NexlozaClient nexloza;
bool lightOn = false;

void reportLightState() {
  JsonDocument state;
  state["on"] = lightOn;
  nexloza.reportState("light", state);
}

void setLight(bool on) {
  lightOn = on;
  digitalWrite(RELAY_PIN, lightOn ? HIGH : LOW);
  Serial.printf("[Light] %s\n", lightOn ? "ON" : "OFF");
  reportLightState();
}

void handleCommand(const char* commandType, JsonObject& payload) {
  if (strcmp(commandType, "set_state") == 0) {
    const char* key = payload["actuator_key"] | "";
    if (strcmp(key, "light") == 0) {
      bool on = payload["state"] | false;
      setLight(on);
      if (payload["command_id"]) {
        nexloza.acknowledgeCommand(payload["command_id"], true);
      }
    }
  } else if (strcmp(commandType, "toggle") == 0) {
    setLight(!lightOn);
  } else if (strcmp(commandType, "get_state") == 0) {
    reportLightState();
  }
}

void handleConnection(bool connected) {
  if (connected) reportLightState();
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== Nexloza ESP32 Light Controller ===");

  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);

  if (!NexlozaWiFi::begin(WIFI_SSID, WIFI_PASS)) {
    Serial.println("WiFi failed, restarting in 10s...");
    delay(10000);
    ESP.restart();
  }

  NexlozaConfig config;
  config.serverHost           = NEXLOZA_SERVER;
  config.mqttPort             = 1883;
  config.deviceId             = NEXLOZA_DEVICE_ID;
  config.apiKey               = NEXLOZA_API_KEY;
  config.apiSecret            = NEXLOZA_API_SECRET;
  config.organizationId     = NEXLOZA_ORG_ID;
  config.projectId            = NEXLOZA_PROJECT_ID;
  config.useTLS               = false;
  config.heartbeatIntervalMs  = 30000;
  config.reconnectIntervalMs  = 5000;
  config.maxReconnectAttempts = 10;

  nexloza.begin(config);
  nexloza.onCommand(handleCommand);
  nexloza.onConnectionChange(handleConnection);
  nexloza.connect();

  nexloza.reportDeviceInfo(FIRMWARE_VERSION, ESP.getFreeHeap(), WiFi.RSSI());
}

void loop() {
  if (!NexlozaWiFi::isConnected()) NexlozaWiFi::reconnect();
  nexloza.loop();
  delay(10);
}
