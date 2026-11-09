// Nexloza ESP32 HC-SR04 Ultrasonic Distance Sensor Example
// =========================================================
//
// HC-SR04 wiring:
//   VCC  -> 5V (ESP32 VIN pin — the sensor needs 5V)
//   Trig -> GPIO 12
//   Echo -> GPIO 14 (3.3V tolerant on most boards; add a voltage
//           divider if your Echo pin outputs 5V)
//   GND  -> GND
//
// Publishes distance in centimetres every 5 seconds.
// No external library required — uses pulseIn().
//
// MQTT Commands:
//   { "command_type": "get_reading" }  -> immediate publish

#include <Arduino.h>
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

#define TRIG_PIN 12
#define ECHO_PIN 14

#define READ_INTERVAL_MS   5000
#define MAX_DISTANCE_CM    400
#define FIRMWARE_VERSION   "1.0.0"

NexlozaClient nexloza;
unsigned long lastRead = 0;

float measureDistanceCm() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  unsigned long duration = pulseIn(ECHO_PIN, HIGH, 30000); // 30 ms timeout
  if (duration == 0) return NAN; // no echo received

  float cm = (float)duration * 0.0343f / 2.0f;
  if (cm > MAX_DISTANCE_CM) return NAN;
  return cm;
}

void readAndPublish() {
  float distance = measureDistanceCm();

  if (isnan(distance)) {
    Serial.println("[HC-SR04] No echo — check wiring or object out of range");
    return;
  }

  Serial.printf("[HC-SR04] Distance = %.1f cm\n", distance);
  nexloza.publishTelemetry("distance", distance);
}

void handleCommand(const char* commandType, JsonObject& payload) {
  if (strcmp(commandType, "get_reading") == 0) {
    readAndPublish();
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== Nexloza ESP32 Ultrasonic Sensor ===");

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

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
  nexloza.connect();
  nexloza.reportDeviceInfo(FIRMWARE_VERSION, ESP.getFreeHeap(), WiFi.RSSI());

  readAndPublish();
  lastRead = millis();
}

void loop() {
  if (!NexlozaWiFi::isConnected()) NexlozaWiFi::reconnect();
  nexloza.loop();

  unsigned long now = millis();
  if (now - lastRead >= READ_INTERVAL_MS) {
    readAndPublish();
    lastRead = now;
  }

  delay(10);
}
