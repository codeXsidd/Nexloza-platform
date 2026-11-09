// Nexloza ESP8266 Reconnection Demonstration
// =============================================
//
// Demonstrates WiFi and MQTT reconnection handling with the NexlozaClient SDK.
// Uses the built-in LED on GPIO 2 (active-LOW on most ESP8266 boards) to
// indicate connection state:
//   - Solid ON   = connected to WiFi + MQTT
//   - Blinking   = reconnecting
//   - OFF        = disconnected
//
// Uses onError() callback to log error codes. The SDK handles reconnection
// automatically via exponential backoff in nexloza.loop().
//
// No external wiring required — just power the board via USB.

#include <Arduino.h>
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

#define LED_PIN          2       // GPIO 2 = D4 on NodeMCU, active-LOW
#define TELEMETRY_MS     15000
#define FIRMWARE_VERSION "1.0.0"

NexlozaClient nexloza;
unsigned long lastTelemetry = 0;
uint32_t connectCount = 0;
uint32_t disconnectCount = 0;
uint32_t errorCount = 0;

// --- LED helpers (active-LOW) ---

void ledOn()  { digitalWrite(LED_PIN, LOW); }
void ledOff() { digitalWrite(LED_PIN, HIGH); }

// --- Callbacks ---

void handleConnection(bool connected) {
  if (connected) {
    connectCount++;
    Serial.printf("[STATE] Connected (#%u)\n", connectCount);
    ledOn();
  } else {
    disconnectCount++;
    Serial.printf("[STATE] Disconnected (#%u)\n", disconnectCount);
    ledOff();
  }
}

void handleError(int code, const char* message) {
  errorCount++;
  Serial.printf("[ERROR] Code=%d Msg=%s (total errors: %u)\n", code, message, errorCount);
}

void handleCommand(const char* commandType, JsonObject& payload) {
  Serial.printf("[CMD] %s\n", commandType);

  if (strcmp(commandType, "get_status") == 0) {
    JsonDocument doc;
    doc["connect_count"] = connectCount;
    doc["disconnect_count"] = disconnectCount;
    doc["error_count"] = errorCount;
    doc["wifi_connected"] = NexlozaWiFi::isConnected();
    doc["mqtt_connected"] = nexloza.isConnected();
    doc["rssi"] = WiFi.RSSI();
    doc["free_heap"] = ESP.getFreeHeap();
    doc["uptime_ms"] = millis();
    nexloza.publishTelemetry(doc);
  }
}

void publishTelemetry() {
  JsonDocument doc;
  doc["wifi_connected"] = NexlozaWiFi::isConnected();
  doc["mqtt_connected"] = nexloza.isConnected();
  doc["rssi"] = WiFi.RSSI();
  doc["free_heap"] = ESP.getFreeHeap();
  doc["connect_count"] = connectCount;
  doc["disconnect_count"] = disconnectCount;
  doc["error_count"] = errorCount;
  doc["uptime_ms"] = millis();
  nexloza.publishTelemetry(doc);
}

// --- Blink pattern while reconnecting ---

unsigned long lastBlink = 0;
bool blinkState = false;

void blinkIfReconnecting() {
  if (nexloza.isConnected()) return;
  unsigned long now = millis();
  if (now - lastBlink >= 500) {
    blinkState = !blinkState;
    digitalWrite(LED_PIN, blinkState ? LOW : HIGH);
    lastBlink = now;
  }
}

// --- Main ---

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== Nexloza ESP8266 Reconnection Demo ===");

  pinMode(LED_PIN, OUTPUT);
  ledOff();

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
  config.reconnectIntervalMs  = 3000;
  config.maxReconnectAttempts = 20;

  nexloza.begin(config);
  nexloza.onCommand(handleCommand);
  nexloza.onConnectionChange(handleConnection);
  nexloza.onError(handleError);
  nexloza.connect();
  nexloza.reportDeviceInfo(FIRMWARE_VERSION, ESP.getFreeHeap(), WiFi.RSSI());

  lastTelemetry = millis();
}

void loop() {
  if (!NexlozaWiFi::isConnected()) {
    Serial.println("[WiFi] Lost connection, reconnecting...");
    NexlozaWiFi::reconnect();
  }

  nexloza.loop();
  blinkIfReconnecting();

  unsigned long now = millis();
  if (now - lastTelemetry >= TELEMETRY_MS) {
    publishTelemetry();
    lastTelemetry = now;
  }

  delay(10);
}
