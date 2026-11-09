// Nexloza ESP32 PIR Motion Sensor Example
// HC-SR501 PIR sensor on GPIO 14
// Publishes motion_detected events with debounce and cooldown

#include <Arduino.h>
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

#define PIR_PIN  14
#define LED_PIN  2  // built-in LED for visual feedback

#define COOLDOWN_MS      10000  // minimum time between motion events
#define DEBOUNCE_MS      200
#define FIRMWARE_VERSION "1.0.0"

NexlozaClient nexloza;

volatile bool motionFlag = false;
unsigned long lastMotionPublished = 0;
unsigned long lastPinChange = 0;
uint32_t motionCount = 0;

void IRAM_ATTR onMotion() {
  unsigned long now = millis();
  if (now - lastPinChange > DEBOUNCE_MS) {
    motionFlag = true;
    lastPinChange = now;
  }
}

void publishMotion() {
  motionCount++;
  Serial.printf("[PIR] Motion detected (#%u)\n", motionCount);

  JsonDocument doc;
  doc["device_id"] = NEXLOZA_DEVICE_ID;
  doc["sensor_key"] = "motion";
  doc["value"] = true;
  doc["motion_count"] = motionCount;
  doc["timestamp"] = millis();
  nexloza.publishTelemetry(doc);

  lastMotionPublished = millis();
}

void handleCommand(const char* commandType, JsonObject& payload) {
  if (strcmp(commandType, "get_status") == 0) {
    JsonDocument doc;
    doc["sensor_key"] = "motion";
    doc["motion_count"] = motionCount;
    doc["current_state"] = digitalRead(PIR_PIN);
    nexloza.publishTelemetry(doc);
  } else if (strcmp(commandType, "reset_count") == 0) {
    motionCount = 0;
    Serial.println("[PIR] Motion counter reset");
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== Nexloza ESP32 PIR Motion Sensor ===");

  pinMode(PIR_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  // Let PIR stabilize
  Serial.println("[PIR] Stabilizing sensor (30s)...");
  delay(30000);
  Serial.println("[PIR] Sensor ready");

  attachInterrupt(digitalPinToInterrupt(PIR_PIN), onMotion, RISING);

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
  nexloza.connect();
  nexloza.reportDeviceInfo(FIRMWARE_VERSION, ESP.getFreeHeap(), WiFi.RSSI());
}

void loop() {
  if (!NexlozaWiFi::isConnected()) NexlozaWiFi::reconnect();
  nexloza.loop();

  if (motionFlag) {
    motionFlag = false;
    unsigned long now = millis();
    if (now - lastMotionPublished >= COOLDOWN_MS) {
      digitalWrite(LED_PIN, HIGH);
      publishMotion();
      delay(500);
      digitalWrite(LED_PIN, LOW);
    }
  }

  delay(10);
}
