// Nexloza ESP32 Multi-Sensor Example
// DHT22 on GPIO 4, BMP280 on I2C (SDA=21, SCL=22), LDR on GPIO 34
// Demonstrates publishing multiple telemetry keys from one device

#include <Arduino.h>
#include <Wire.h>
#include <DHT.h>
#include <Adafruit_BMP280.h>
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

#define DHT_PIN    4
#define DHT_TYPE   DHT22
#define LDR_PIN    34
#define I2C_SDA    21
#define I2C_SCL    22

#define READ_INTERVAL_MS 30000
#define FIRMWARE_VERSION "1.0.0"

DHT dht(DHT_PIN, DHT_TYPE);
Adafruit_BMP280 bmp;
NexlozaClient nexloza;

unsigned long lastRead = 0;
bool bmpAvailable = false;

float readLightPercent() {
  int raw = analogRead(LDR_PIN);
  return (float)raw / 4095.0 * 100.0;
}

void readAndPublish() {
  // DHT22
  float temp = dht.readTemperature();
  float humidity = dht.readHumidity();

  if (!isnan(temp)) {
    nexloza.publishTelemetry("temperature", temp);
    Serial.printf("[DHT22] Temp=%.1f°C\n", temp);
  }
  if (!isnan(humidity)) {
    nexloza.publishTelemetry("humidity", humidity);
    Serial.printf("[DHT22] Humidity=%.1f%%\n", humidity);
  }

  // BMP280
  if (bmpAvailable) {
    float pressure = bmp.readPressure() / 100.0; // hPa
    float bmpTemp = bmp.readTemperature();
    float altitude = bmp.readAltitude(1013.25);

    nexloza.publishTelemetry("pressure", pressure);
    nexloza.publishTelemetry("altitude", altitude);
    Serial.printf("[BMP280] Pressure=%.1f hPa Altitude=%.1f m Temp=%.1f°C\n",
                  pressure, altitude, bmpTemp);
  }

  // Light sensor
  float light = readLightPercent();
  nexloza.publishTelemetry("light_intensity", light);
  Serial.printf("[LDR] Light=%.1f%%\n", light);

  // Combined batch telemetry
  JsonDocument batch;
  if (!isnan(temp)) batch["temperature"] = temp;
  if (!isnan(humidity)) batch["humidity"] = humidity;
  if (bmpAvailable) {
    batch["pressure"] = bmp.readPressure() / 100.0;
    batch["altitude"] = bmp.readAltitude(1013.25);
  }
  batch["light_intensity"] = light;
  batch["sensor_count"] = bmpAvailable ? 5 : 3;
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
  Serial.println("\n=== Nexloza ESP32 Multi-Sensor ===");

  dht.begin();
  pinMode(LDR_PIN, INPUT);

  Wire.begin(I2C_SDA, I2C_SCL);
  bmpAvailable = bmp.begin(0x76);
  if (!bmpAvailable) {
    bmpAvailable = bmp.begin(0x77);
  }
  if (bmpAvailable) {
    bmp.setSampling(Adafruit_BMP280::MODE_NORMAL,
                    Adafruit_BMP280::SAMPLING_X2,
                    Adafruit_BMP280::SAMPLING_X16,
                    Adafruit_BMP280::FILTER_X16,
                    Adafruit_BMP280::STANDBY_MS_500);
    Serial.println("[BMP280] Sensor initialized");
  } else {
    Serial.println("[BMP280] Sensor not found, skipping");
  }

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
