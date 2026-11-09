// Nexloza ESP32 Smart Home Demo
// ===============================
//
// A combined example demonstrating multiple sensors and actuators
// in a single device — typical of a smart home controller.
//
// Components:
//   DHT22          -> GPIO 4  (temperature + humidity)
//   Relay          -> GPIO 26 (light/appliance control)
//   PIR HC-SR501   -> GPIO 14 (motion detection)
//   Built-in LED   -> GPIO 2  (status/indicator)
//
// Wiring:
//   DHT22: DATA->GPIO4, VCC->3.3V, GND->GND (10kΩ pull-up on DATA)
//   Relay: IN->GPIO26, VCC->3.3V, GND->GND
//   PIR:   OUT->GPIO14, VCC->5V (VIN), GND->GND
//
// WARNING: Use low-voltage DC loads on the relay for testing.
// AC mains wiring (110V/220V) must be installed by a qualified
// electrician with appropriate protection.
//
// MQTT Commands:
//   { "command_type": "set_state", "payload": { "actuator_key": "relay", "state": true } }
//   { "command_type": "set_state", "payload": { "actuator_key": "led",   "state": true } }
//   { "command_type": "toggle",    "payload": { "actuator_key": "relay" } }
//   { "command_type": "get_state" }
//   { "command_type": "get_reading" }

#include <Arduino.h>
#include <DHT.h>
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

#define DHT_PIN   4
#define DHT_TYPE  DHT22
#define RELAY_PIN 26
#define PIR_PIN   14
#define LED_PIN   2

#define SENSOR_INTERVAL_MS  30000
#define MOTION_COOLDOWN_MS  10000
#define FIRMWARE_VERSION    "1.0.0"

DHT dht(DHT_PIN, DHT_TYPE);
NexlozaClient nexloza;

bool relayOn = false;
bool ledOn = false;
unsigned long lastSensorRead = 0;
unsigned long lastMotionPublished = 0;
uint32_t motionCount = 0;

volatile bool motionFlag = false;

void IRAM_ATTR onMotion() {
  motionFlag = true;
}

// --- State reporting ---

void reportFullState() {
  JsonDocument state;
  state["relay"] = relayOn;
  state["led"] = ledOn;
  state["motion_count"] = motionCount;
  state["uptime_s"] = millis() / 1000;
  nexloza.reportState("smart_home", state);
}

// --- Actuator helpers ---

void setRelay(bool on) {
  relayOn = on;
  digitalWrite(RELAY_PIN, relayOn ? HIGH : LOW);
  Serial.printf("[Relay] %s\n", relayOn ? "ON" : "OFF");
  reportFullState();
}

void setLed(bool on) {
  ledOn = on;
  digitalWrite(LED_PIN, ledOn ? HIGH : LOW);
  Serial.printf("[LED] %s\n", ledOn ? "ON" : "OFF");
  reportFullState();
}

// --- Sensor reading ---

void readAndPublishSensors() {
  float temp = dht.readTemperature();
  float humidity = dht.readHumidity();

  if (!isnan(temp) && !isnan(humidity)) {
    Serial.printf("[DHT22] Temp=%.1f°C Humidity=%.1f%%\n", temp, humidity);
    nexloza.publishTelemetry("temperature", temp);
    nexloza.publishTelemetry("humidity", humidity);
  } else {
    Serial.println("[DHT22] Read error — check wiring");
  }

  // Batch telemetry with all sensor data
  JsonDocument batch;
  if (!isnan(temp)) batch["temperature"] = temp;
  if (!isnan(humidity)) batch["humidity"] = humidity;
  batch["relay"] = relayOn;
  batch["led"] = ledOn;
  batch["motion_count"] = motionCount;
  batch["free_heap"] = ESP.getFreeHeap();
  batch["wifi_rssi"] = WiFi.RSSI();
  nexloza.publishTelemetry(batch);
}

// --- Command handling ---

void handleCommand(const char* commandType, JsonObject& payload) {
  const char* key = payload["actuator_key"] | "";

  if (strcmp(commandType, "set_state") == 0) {
    bool on = payload["state"] | false;
    if (strcmp(key, "relay") == 0) {
      setRelay(on);
    } else if (strcmp(key, "led") == 0) {
      setLed(on);
    }
    if (payload["command_id"]) {
      nexloza.acknowledgeCommand(payload["command_id"], true);
    }
  } else if (strcmp(commandType, "toggle") == 0) {
    if (strcmp(key, "relay") == 0) {
      setRelay(!relayOn);
    } else if (strcmp(key, "led") == 0) {
      setLed(!ledOn);
    }
  } else if (strcmp(commandType, "get_state") == 0) {
    reportFullState();
  } else if (strcmp(commandType, "get_reading") == 0) {
    readAndPublishSensors();
  }
}

void handleConnection(bool connected) {
  Serial.printf("[CONN] %s\n", connected ? "Connected" : "Disconnected");
  if (connected) reportFullState();
}

// --- Setup & Loop ---

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== Nexloza ESP32 Smart Home Demo ===");

  pinMode(RELAY_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  pinMode(PIR_PIN, INPUT);
  digitalWrite(RELAY_PIN, LOW);
  digitalWrite(LED_PIN, LOW);

  dht.begin();

  // Let PIR stabilize
  Serial.println("[PIR] Stabilizing sensor (15s)...");
  delay(15000);
  attachInterrupt(digitalPinToInterrupt(PIR_PIN), onMotion, RISING);
  Serial.println("[PIR] Ready");

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
  nexloza.onConnectionChange(handleConnection);
  nexloza.connect();
  nexloza.reportDeviceInfo(FIRMWARE_VERSION, ESP.getFreeHeap(), WiFi.RSSI());

  readAndPublishSensors();
  lastSensorRead = millis();
}

void loop() {
  if (!NexlozaWiFi::isConnected()) NexlozaWiFi::reconnect();
  nexloza.loop();

  // Motion detection
  if (motionFlag) {
    motionFlag = false;
    unsigned long now = millis();
    if (now - lastMotionPublished >= MOTION_COOLDOWN_MS) {
      motionCount++;
      Serial.printf("[PIR] Motion detected (#%u)\n", motionCount);
      nexloza.publishTelemetry("motion", 1.0f);
      lastMotionPublished = now;
    }
  }

  // Periodic sensor reads
  unsigned long now = millis();
  if (now - lastSensorRead >= SENSOR_INTERVAL_MS) {
    readAndPublishSensors();
    lastSensorRead = now;
  }

  delay(10);
}
