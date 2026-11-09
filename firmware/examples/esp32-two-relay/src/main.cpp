// Nexloza ESP32 Two-Channel Relay Example
// =========================================
//
// Relay 1 on GPIO 26, Relay 2 on GPIO 27.
//
// WARNING: Use low-voltage DC loads (LEDs, small motors) for testing.
// AC mains wiring (110V/220V) must be installed by a qualified
// electrician with appropriate fusing, RCDs/GFCIs, and enclosures.
// Never work with exposed mains voltage.
//
// MQTT Commands accepted (on the "command" topic):
//   { "command_type": "set_state", "payload": { "actuator_key": "relay_1", "state": true } }
//   { "command_type": "set_state", "payload": { "actuator_key": "relay_2", "state": false } }
//   { "command_type": "toggle",    "payload": { "actuator_key": "relay_1" } }
//   { "command_type": "get_state" }

#include <Arduino.h>
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

#define RELAY_1_PIN 26
#define RELAY_2_PIN 27
#define FIRMWARE_VERSION "1.0.0"

NexlozaClient nexloza;

bool relay1On = false;
bool relay2On = false;

void reportState() {
  JsonDocument state;
  state["relay_1"] = relay1On;
  state["relay_2"] = relay2On;
  nexloza.reportState("relays", state);
}

void setRelay(uint8_t pin, bool& stateVar, const char* label, bool on) {
  stateVar = on;
  digitalWrite(pin, stateVar ? HIGH : LOW);
  Serial.printf("[%s] %s\n", label, stateVar ? "ON" : "OFF");
  reportState();
}

void handleCommand(const char* commandType, JsonObject& payload) {
  const char* key = payload["actuator_key"] | "";

  if (strcmp(commandType, "set_state") == 0) {
    bool on = payload["state"] | false;
    if (strcmp(key, "relay_1") == 0) {
      setRelay(RELAY_1_PIN, relay1On, "Relay1", on);
    } else if (strcmp(key, "relay_2") == 0) {
      setRelay(RELAY_2_PIN, relay2On, "Relay2", on);
    }
    if (payload["command_id"]) {
      nexloza.acknowledgeCommand(payload["command_id"], true);
    }
  } else if (strcmp(commandType, "toggle") == 0) {
    if (strcmp(key, "relay_1") == 0) {
      setRelay(RELAY_1_PIN, relay1On, "Relay1", !relay1On);
    } else if (strcmp(key, "relay_2") == 0) {
      setRelay(RELAY_2_PIN, relay2On, "Relay2", !relay2On);
    }
  } else if (strcmp(commandType, "get_state") == 0) {
    reportState();
  }
}

void handleConnection(bool connected) {
  if (connected) reportState();
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== Nexloza ESP32 Two-Channel Relay ===");

  pinMode(RELAY_1_PIN, OUTPUT);
  pinMode(RELAY_2_PIN, OUTPUT);
  digitalWrite(RELAY_1_PIN, LOW);
  digitalWrite(RELAY_2_PIN, LOW);

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
  config.organizationId       = NEXLOZA_ORG_ID;
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
