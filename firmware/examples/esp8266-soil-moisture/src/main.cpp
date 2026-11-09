// Nexloza ESP8266 Soil Moisture Sensor Example
// ==============================================
//
// Capacitive soil moisture sensor on A0 (the ESP8266's single analog pin).
// ESP8266 ADC range: 0–1023 (10-bit), input max 1.0V on bare chip,
// but NodeMCU boards have a voltage divider that maps 0–3.3V → 0–1023.
//
// Wiring (NodeMCU):
//   A0   ──► Sensor AOUT
//   3.3V ──► Sensor VCC
//   GND  ──► Sensor GND
//
// Calibration: dry air ≈ 1023 (0%), submerged ≈ 300 (100%).
// Adjust CAL_DRY and CAL_WET for your specific sensor.

#include <Arduino.h>
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

#define SENSOR_PIN   A0
#define NUM_SAMPLES  10
#define READ_INTERVAL_MS 60000
#define FIRMWARE_VERSION "1.0.0"

// Calibration — measure your sensor in dry air and submerged in water
#define CAL_DRY  1023
#define CAL_WET  300

NexlozaClient nexloza;
unsigned long lastRead = 0;

int readSmoothed() {
  long sum = 0;
  for (int i = 0; i < NUM_SAMPLES; i++) {
    sum += analogRead(SENSOR_PIN);
    delay(10);
  }
  return sum / NUM_SAMPLES;
}

float rawToPercent(int raw) {
  float pct = (float)(CAL_DRY - raw) / (float)(CAL_DRY - CAL_WET) * 100.0;
  if (pct < 0.0) pct = 0.0;
  if (pct > 100.0) pct = 100.0;
  return pct;
}

void readAndPublish() {
  int raw = readSmoothed();
  float moisture = rawToPercent(raw);

  Serial.printf("[Soil] Raw=%d Moisture=%.1f%%\n", raw, moisture);

  nexloza.publishTelemetry("soil_moisture", moisture);
  nexloza.publishTelemetry("soil_moisture_raw", (float)raw);
}

void handleCommand(const char* commandType, JsonObject& payload) {
  if (strcmp(commandType, "get_reading") == 0) {
    readAndPublish();
  } else if (strcmp(commandType, "calibrate") == 0) {
    Serial.println("[Soil] Calibration: measure dry/wet ADC values and update CAL_DRY/CAL_WET");
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== Nexloza ESP8266 Soil Moisture Sensor ===");

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

  if (!NexlozaWiFi::begin(WIFI_SSID, WIFI_PASS)) {
    Serial.println("WiFi failed, restarting in 10s...");
    delay(10000);
    ESP.restart();
  }

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
