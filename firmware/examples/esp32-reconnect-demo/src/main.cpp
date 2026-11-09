// Nexloza ESP32 Reconnection Demo
// =================================
//
// Demonstrates SDK reconnection handling:
//   - WiFi disconnect/reconnect detection
//   - MQTT reconnect with exponential backoff
//   - Error callback registration
//   - Connection state tracking
//   - Built-in LED shows connection status
//
// The LED blinks when disconnected and stays solid when connected.
// Serial output logs every state transition and error code.
//
// No external components required — just an ESP32 board.

#include <Arduino.h>
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

#define LED_PIN          2
#define FIRMWARE_VERSION "1.0.0"
#define STATUS_INTERVAL_MS 15000

NexlozaClient nexloza;

uint32_t connectCount = 0;
uint32_t disconnectCount = 0;
uint32_t errorCount = 0;
unsigned long lastStatus = 0;
bool mqttConnected = false;

void handleError(int code, const char* message) {
  errorCount++;
  Serial.printf("[ERROR] Code=%d Msg=%s (total errors: %u)\n", code, message, errorCount);
}

void handleConnection(bool connected) {
  mqttConnected = connected;
  if (connected) {
    connectCount++;
    Serial.printf("[CONN] MQTT connected (connects: %u, disconnects: %u)\n",
                  connectCount, disconnectCount);
    digitalWrite(LED_PIN, HIGH);
  } else {
    disconnectCount++;
    Serial.printf("[CONN] MQTT disconnected (connects: %u, disconnects: %u)\n",
                  connectCount, disconnectCount);
  }
}

void publishStatus() {
  JsonDocument doc;
  doc["connect_count"] = connectCount;
  doc["disconnect_count"] = disconnectCount;
  doc["error_count"] = errorCount;
  doc["wifi_rssi"] = WiFi.RSSI();
  doc["free_heap"] = ESP.getFreeHeap();
  doc["uptime_s"] = millis() / 1000;
  nexloza.publishTelemetry(doc);

  Serial.printf("[STATUS] Uptime=%lus Connects=%u Disconnects=%u Errors=%u RSSI=%d Heap=%u\n",
                millis() / 1000, connectCount, disconnectCount, errorCount,
                WiFi.RSSI(), ESP.getFreeHeap());
}

void handleCommand(const char* commandType, JsonObject& payload) {
  if (strcmp(commandType, "get_status") == 0) {
    publishStatus();
  } else if (strcmp(commandType, "force_reconnect") == 0) {
    Serial.println("[CMD] Forcing MQTT reconnect...");
    nexloza.disconnect();
    delay(1000);
    nexloza.reconnect();
  }
}

void blinkLed() {
  static unsigned long lastBlink = 0;
  static bool ledState = false;
  unsigned long now = millis();
  if (now - lastBlink >= 500) {
    ledState = !ledState;
    digitalWrite(LED_PIN, ledState ? HIGH : LOW);
    lastBlink = now;
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== Nexloza ESP32 Reconnection Demo ===");
  Serial.println("This demo tracks WiFi/MQTT connection events.");
  Serial.println("Unplug your router or change WiFi credentials to test.\n");

  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

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
  config.heartbeatIntervalMs  = 15000;
  config.reconnectIntervalMs  = 3000;
  config.maxReconnectAttempts = 20;

  nexloza.begin(config);
  nexloza.setLogLevel(NexlozaLogLevel::DEBUG);
  nexloza.onCommand(handleCommand);
  nexloza.onConnectionChange(handleConnection);
  nexloza.onError(handleError);
  nexloza.connect();
  nexloza.reportDeviceInfo(FIRMWARE_VERSION, ESP.getFreeHeap(), WiFi.RSSI());

  lastStatus = millis();
}

void loop() {
  if (!NexlozaWiFi::isConnected()) {
    Serial.println("[WIFI] Lost connection, reconnecting...");
    NexlozaWiFi::reconnect();
  }

  nexloza.loop();

  if (!mqttConnected) {
    blinkLed();
  }

  unsigned long now = millis();
  if (now - lastStatus >= STATUS_INTERVAL_MS && mqttConnected) {
    publishStatus();
    lastStatus = now;
  }

  delay(10);
}
