// Nexloza ESP8266 Multi-Sensor Example
// ======================================
//
// DHT22 on GPIO 4 (D2) + LDR on A0.
// Publishes batch telemetry with temperature, humidity, and light level.
//
// Wiring (NodeMCU):
//   D2 (GPIO 4) ──► DHT22 DATA (10kΩ pull-up to 3.3V)
//   3.3V        ──► DHT22 VCC
//   GND         ──► DHT22 GND
//
//   A0 ──► LDR voltage divider:
//          3.3V ─── [LDR] ─── A0 ─── [10kΩ] ─── GND
//          Brighter light = higher reading.

#include <Arduino.h>
#include <DHT.h>
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

#define DHT_PIN    4       // GPIO 4 = D2 on NodeMCU
#define DHT_TYPE   DHT22
#define LDR_PIN    A0

#define READ_INTERVAL_MS 30000
#define FIRMWARE_VERSION "1.0.0"

DHT dht(DHT_PIN, DHT_TYPE);
NexlozaClient nexloza;

unsigned long lastRead = 0;

float readLightPercent() {
  int raw = analogRead(LDR_PIN);
  // ESP8266 ADC: 0–1023
  return (float)raw / 1023.0 * 100.0;
}

void readAndPublish() {
  float temp = dht.readTemperature();
  float humidity = dht.readHumidity();
  float light = readLightPercent();

  if (!isnan(temp)) {
    nexloza.publishTelemetry("temperature", temp);
    Serial.printf("[DHT22] Temp=%.1f°C\n", temp);
  } else {
    Serial.println("[DHT22] Temperature read error");
  }

  if (!isnan(humidity)) {
    nexloza.publishTelemetry("humidity", humidity);
    Serial.printf("[DHT22] Humidity=%.1f%%\n", humidity);
  } else {
    Serial.println("[DHT22] Humidity read error");
  }

  nexloza.publishTelemetry("light_intensity", light);
  Serial.printf("[LDR] Light=%.1f%%\n", light);

  // Batch telemetry
  JsonDocument batch;
  if (!isnan(temp)) batch["temperature"] = temp;
  if (!isnan(humidity)) batch["humidity"] = humidity;
  batch["light_intensity"] = light;
  batch["sensor_count"] = isnan(temp) || isnan(humidity) ? 1 : 3;
  nexloza.publishTelemetry(batch);
}

void handleCommand(const char* commandType, JsonObject& payload) {
  if (strcmp(commandType, "get_reading") == 0) {
    readAndPublish();
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== Nexloza ESP8266 Multi-Sensor ===");

  dht.begin();

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
