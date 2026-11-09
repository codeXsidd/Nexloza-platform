// Nexloza ESP32 Universal Example
// Demonstrates all SDK capabilities: telemetry, commands, ACK, state, OTA
// No external sensor libraries needed — uses built-in ADC + GPIO

#include <Arduino.h>
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

#define FIRMWARE_VERSION "1.0.0"

#define ANALOG_PIN      34
#define LED_PIN         2
#define RELAY_PIN       26
#define TELEMETRY_MS    15000

NexlozaClient nexloza;

unsigned long lastTelemetry = 0;
bool relayState = false;
int ledBrightness = 0;

void reportState() {
  JsonDocument state;
  state["relay"] = relayState;
  state["led_brightness"] = ledBrightness;
  state["uptime_s"] = millis() / 1000;
  state["free_heap"] = ESP.getFreeHeap();
  nexloza.reportState("device_state", state);
}

void publishTelemetry() {
  int rawAdc = analogRead(ANALOG_PIN);
  float voltage = rawAdc * 3.3 / 4095.0;

  nexloza.publishTelemetry("adc_raw", (float)rawAdc);
  nexloza.publishTelemetry("voltage", voltage);

  JsonDocument batch;
  batch["adc_raw"] = rawAdc;
  batch["voltage"] = voltage;
  batch["wifi_rssi"] = WiFi.RSSI();
  batch["free_heap"] = ESP.getFreeHeap();
  nexloza.publishTelemetry(batch);

  Serial.printf("[Telemetry] ADC=%d Voltage=%.2fV RSSI=%d\n",
                rawAdc, voltage, WiFi.RSSI());
}

void handleCommand(const char* commandType, JsonObject& payload) {
  Serial.printf("[CMD] %s\n", commandType);

  if (strcmp(commandType, "relay") == 0) {
    bool value = payload["value"] | false;
    relayState = value;
    digitalWrite(RELAY_PIN, relayState ? HIGH : LOW);
    Serial.printf("[CMD] Relay -> %s\n", relayState ? "ON" : "OFF");
    reportState();
  }
  else if (strcmp(commandType, "led_brightness") == 0) {
    int value = payload["value"] | 0;
    ledBrightness = constrain(value, 0, 255);
    ledcWrite(LED_PIN, ledBrightness);
    Serial.printf("[CMD] LED brightness -> %d\n", ledBrightness);
    reportState();
  }
  else if (strcmp(commandType, "get_reading") == 0) {
    publishTelemetry();
  }
  else if (strcmp(commandType, "restart") == 0) {
    Serial.println("[CMD] Restarting...");
    delay(500);
    ESP.restart();
  }
  else if (strcmp(commandType, "set_interval") == 0) {
    // Dynamic telemetry interval — payload: {"interval_ms": 5000}
    // Not persisted across reboots for safety
    Serial.println("[CMD] set_interval acknowledged (demo only)");
  }
  else {
    Serial.printf("[CMD] Unknown command: %s\n", commandType);
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== Nexloza ESP32 Universal ===");

  ledcAttach(LED_PIN, 5000, 8);
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(ANALOG_PIN, INPUT);
  digitalWrite(RELAY_PIN, LOW);

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
  nexloza.enableOTA(true);
  nexloza.connect();
  nexloza.reportDeviceInfo(FIRMWARE_VERSION, ESP.getFreeHeap(), WiFi.RSSI());

  reportState();
  publishTelemetry();
  lastTelemetry = millis();
}

void loop() {
  if (!NexlozaWiFi::isConnected()) NexlozaWiFi::reconnect();
  nexloza.loop();

  unsigned long now = millis();
  if (now - lastTelemetry >= TELEMETRY_MS) {
    publishTelemetry();
    reportState();
    lastTelemetry = now;
  }

  delay(10);
}
