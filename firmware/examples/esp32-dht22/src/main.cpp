// Nexloza ESP32 DHT22 Temperature & Humidity Sensor Example
// DHT22 data pin on GPIO 4, 10kΩ pull-up to 3.3V recommended

#include <Arduino.h>
#include <DHT.h>
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

#define DHT_PIN  4
#define DHT_TYPE DHT22

#define READ_INTERVAL_MS   30000
#define TEMP_WARN_HIGH     40.0
#define HUMIDITY_WARN_HIGH 90.0
#define FIRMWARE_VERSION   "1.0.0"

DHT dht(DHT_PIN, DHT_TYPE);
NexlozaClient nexloza;

unsigned long lastRead = 0;
float lastTemp = NAN;
float lastHumidity = NAN;

void readAndPublish() {
  float temp = dht.readTemperature();
  float humidity = dht.readHumidity();

  if (isnan(temp) || isnan(humidity)) {
    Serial.println("[DHT22] Read error — check wiring");
    return;
  }

  lastTemp = temp;
  lastHumidity = humidity;

  Serial.printf("[DHT22] Temp=%.1f°C Humidity=%.1f%%\n", temp, humidity);

  nexloza.publishTelemetry("temperature", temp);
  nexloza.publishTelemetry("humidity", humidity);

  if (temp > TEMP_WARN_HIGH) {
    Serial.printf("[DHT22] WARNING: Temperature %.1f°C exceeds threshold %.1f°C\n", temp, TEMP_WARN_HIGH);
    JsonDocument alert;
    alert["type"] = "threshold_exceeded";
    alert["sensor_key"] = "temperature";
    alert["value"] = temp;
    alert["threshold"] = TEMP_WARN_HIGH;
    nexloza.publishTelemetry(alert);
  }

  if (humidity > HUMIDITY_WARN_HIGH) {
    Serial.printf("[DHT22] WARNING: Humidity %.1f%% exceeds threshold %.1f%%\n", humidity, HUMIDITY_WARN_HIGH);
  }
}

void handleCommand(const char* commandType, JsonObject& payload) {
  if (strcmp(commandType, "get_reading") == 0) {
    readAndPublish();
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== Nexloza ESP32 DHT22 Sensor ===");

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
