// Nexloza ESP32 Fan Control Example
// Relay on GPIO 26, PWM speed control on GPIO 25
// WARNING: Use low-voltage loads for testing. AC mains wiring must be
// installed by a qualified electrician with appropriate protection.

#include <Arduino.h>
#include <NexlozaClient.h>
#include <NexlozaWiFi.h>

#define RELAY_PIN    26
#define PWM_PIN      25
#define PWM_CHANNEL  0
#define PWM_FREQ     25000
#define PWM_RES      8

#define FIRMWARE_VERSION "1.0.0"

NexlozaClient nexloza;

bool fanOn = false;
uint8_t fanSpeed = 0; // 0-100

void reportFanState() {
  JsonDocument state;
  state["on"] = fanOn;
  state["speed"] = fanSpeed;
  nexloza.reportState("fan", state);
}

void setFan(bool on, uint8_t speed) {
  fanOn = on;
  fanSpeed = constrain(speed, 0, 100);

  if (fanOn) {
    digitalWrite(RELAY_PIN, HIGH);
    uint8_t duty = map(fanSpeed, 0, 100, 0, 255);
    ledcWrite(PWM_PIN, duty);
  } else {
    digitalWrite(RELAY_PIN, LOW);
    ledcWrite(PWM_PIN, 0);
  }

  Serial.printf("[Fan] state=%s speed=%d%%\n", fanOn ? "ON" : "OFF", fanSpeed);
  reportFanState();
}

void handleCommand(const char* commandType, JsonObject& payload) {
  Serial.printf("[Command] type=%s\n", commandType);

  if (strcmp(commandType, "set_state") == 0) {
    const char* key = payload["actuator_key"] | "";

    if (strcmp(key, "fan") == 0) {
      bool on = payload["state"] | fanOn;
      uint8_t speed = payload["speed"] | fanSpeed;
      setFan(on, speed);

      if (payload["command_id"]) {
        nexloza.acknowledgeCommand(payload["command_id"], true, "Fan state updated");
      }
    }
  } else if (strcmp(commandType, "get_state") == 0) {
    reportFanState();
  }
}

void handleConnection(bool connected) {
  Serial.printf("[Connection] %s\n", connected ? "Connected" : "Disconnected");
  if (connected) {
    reportFanState();
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n=== Nexloza ESP32 Fan Controller ===");

  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  ledcAttach(PWM_PIN, PWM_FREQ, PWM_RES);
  ledcWrite(PWM_PIN, 0);

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
  nexloza.onConnectionChange(handleConnection);

  if (!nexloza.connect()) {
    Serial.println("MQTT connection failed, will retry in loop");
  }

  nexloza.reportDeviceInfo(FIRMWARE_VERSION, ESP.getFreeHeap(), WiFi.RSSI());
}

void loop() {
  if (!NexlozaWiFi::isConnected()) {
    Serial.println("WiFi lost, reconnecting...");
    NexlozaWiFi::reconnect();
  }

  nexloza.loop();
  delay(10);
}
