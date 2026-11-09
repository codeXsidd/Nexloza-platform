// Nexloza ESP32 Water Level Sensor Example
// ==========================================
//
// Analog water level sensor on GPIO 34 (ADC1_CH6, input-only).
// The sensor outputs a voltage proportional to the water depth.
//
// Wiring:
//   S (signal) -> GPIO 34
//   + (VCC)    -> 3.3V
//   - (GND)    -> GND
//
// Calibration:
//   CAL_DRY  = ADC reading in air (no water) — typically ~0-200
//   CAL_WET  = ADC reading fully submerged   — typically ~2800-3500
//   Adjust these constants for your specific sensor.
//
// Publishes "water_level" (0-100%) every 30 seconds.

#include <Arduino.h>
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

#define SENSOR_PIN  34
#define NUM_SAMPLES 10
#define READ_INTERVAL_MS 30000

#define CAL_DRY  100
#define CAL_WET  3200

#define FIRMWARE_VERSION "1.0.0"

NexlozaClient nexloza;
unsigned long lastRead = 0;

int readSmoothed() {
  long sum = 0;
  for (int i = 0; i < NUM_SAMPLES; i++) {
    sum += analogRead(SENSOR_PIN);
    delay(10);
  }
  return (int)(sum / NUM_SAMPLES);
}

float rawToPercent(int raw) {
  float pct = (float)(raw - CAL_DRY) / (float)(CAL_WET - CAL_DRY) * 100.0f;
  return constrain(pct, 0.0f, 100.0f);
}

void readAndPublish() {
  int raw = readSmoothed();
  float level = rawToPercent(raw);

  Serial.printf("[Water] Raw=%d Level=%.1f%%\n", raw, level);

  nexloza.publishTelemetry("water_level", level);
  nexloza.publishTelemetry("water_level_raw", (float)raw);
}

void handleCommand(const char* commandType, JsonObject& payload) {
  if (strcmp(commandType, "get_reading") == 0) {
    readAndPublish();
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== Nexloza ESP32 Water Level Sensor ===");

  pinMode(SENSOR_PIN, INPUT);

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
