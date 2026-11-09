// Nexloza ESP8266 Built-in LED Control Example
// =============================================
//
// Controls the built-in LED on GPIO2 (D4 on NodeMCU / Wemos D1 Mini).
// Most ESP8266 boards wire the onboard LED to GPIO2 with active-LOW logic:
//   - digitalWrite(LED_PIN, LOW)  -> LED ON
//   - digitalWrite(LED_PIN, HIGH) -> LED OFF
//
// No external wiring required — just power the board via USB.
//
// MQTT Commands accepted (on the "command" topic):
//   { "type": "set_state", "actuator_key": "led", "state": true }   -> LED ON
//   { "type": "set_state", "actuator_key": "led", "state": false }  -> LED OFF
//   { "type": "toggle" }                                             -> flip
//   { "type": "get_state" }                                          -> report current state
//
// Telemetry published every 10 seconds:
//   { "led_on": true/false }

#include <Arduino.h>
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

// GPIO2 = D4 on NodeMCU.  Active-LOW on most ESP8266 boards.
#define LED_PIN       2
#define LED_ACTIVE_LOW true
#define FIRMWARE_VERSION "1.0.0"

// Telemetry interval (milliseconds)
#define TELEMETRY_INTERVAL_MS 10000

NexlozaClient nexloza;
bool ledOn = false;
unsigned long lastTelemetry = 0;

// ---------- helpers ----------

void writeLed(bool on) {
  // Active-LOW: LOW turns the LED on, HIGH turns it off.
  if (LED_ACTIVE_LOW) {
    digitalWrite(LED_PIN, on ? LOW : HIGH);
  } else {
    digitalWrite(LED_PIN, on ? HIGH : LOW);
  }
}

void reportLedState() {
  JsonDocument state;
  state["on"] = ledOn;
  nexloza.reportState("led", state);
}

void setLed(bool on) {
  ledOn = on;
  writeLed(ledOn);
  Serial.printf("[LED] %s\n", ledOn ? "ON" : "OFF");
  reportLedState();
}

void publishTelemetry() {
  JsonDocument doc;
  doc["led_on"] = ledOn;
  nexloza.publishTelemetry(doc);
}

// ---------- callbacks ----------

void handleCommand(const char* commandType, JsonObject& payload) {
  if (strcmp(commandType, "set_state") == 0) {
    const char* key = payload["actuator_key"] | "";
    if (strcmp(key, "led") == 0) {
      bool on = payload["state"] | false;
      setLed(on);
      if (payload["command_id"]) {
        nexloza.acknowledgeCommand(payload["command_id"], true);
      }
    }
  } else if (strcmp(commandType, "toggle") == 0) {
    setLed(!ledOn);
  } else if (strcmp(commandType, "get_state") == 0) {
    reportLedState();
  }
}

void handleConnection(bool connected) {
  if (connected) {
    Serial.println("[MQTT] Connected — reporting LED state");
    reportLedState();
  }
}

// ---------- setup / loop ----------

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== Nexloza ESP8266 LED Controller ===");

  pinMode(LED_PIN, OUTPUT);
  writeLed(false);  // start with LED off

  // Connect to WiFi
  if (!NexlozaWiFi::begin(WIFI_SSID, WIFI_PASS)) {
    Serial.println("WiFi failed, restarting in 10 s...");
    delay(10000);
    ESP.restart();
  }

  // Configure and connect to Nexloza MQTT
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

  // Periodic telemetry
  unsigned long now = millis();
  if (now - lastTelemetry >= TELEMETRY_INTERVAL_MS) {
    lastTelemetry = now;
    publishTelemetry();
  }

  delay(10);
}
