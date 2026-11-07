#ifndef NEXLOZA_CLIENT_H
#define NEXLOZA_CLIENT_H

#include <Arduino.h>
#include <ArduinoJson.h>

#if defined(ESP32)
  #include <WiFi.h>
  #include <PubSubClient.h>
  #include <WiFiClientSecure.h>
  #include <HTTPClient.h>
#elif defined(ESP8266)
  #include <ESP8266WiFi.h>
  #include <PubSubClient.h>
  #include <WiFiClientSecure.h>
  #include <ESP8266HTTPClient.h>
#endif

typedef void (*CommandCallback)(const char* commandType, JsonObject& payload);
typedef void (*ConnectionCallback)(bool connected);

struct NexlozaConfig {
  const char* serverHost;
  uint16_t mqttPort;
  const char* deviceId;
  const char* apiKey;
  const char* apiSecret;
  const char* projectId;
  bool useTLS;
  uint32_t heartbeatIntervalMs;
  uint32_t reconnectIntervalMs;
  uint8_t maxReconnectAttempts;
};

class NexlozaClient {
public:
  NexlozaClient();

  void begin(NexlozaConfig& config);
  void loop();

  bool connect();
  void disconnect();
  bool isConnected();

  bool publishTelemetry(const char* sensorKey, float value);
  bool publishTelemetry(const char* sensorKey, const char* value);
  bool publishTelemetry(JsonDocument& data);

  bool reportState(const char* actuatorKey, JsonDocument& state);
  bool reportDeviceInfo(const char* firmwareVersion, uint32_t freeHeap, int8_t rssi);

  void onCommand(CommandCallback callback);
  void onConnectionChange(ConnectionCallback callback);
  bool acknowledgeCommand(const char* commandId, bool success, const char* message = nullptr);

  void enableOTA(bool enable);
  void checkForUpdate();

private:
  NexlozaConfig _config;
  WiFiClient _wifiClient;
  WiFiClientSecure _wifiSecureClient;
  PubSubClient _mqttClient;
  CommandCallback _commandCallback;
  ConnectionCallback _connectionCallback;

  unsigned long _lastHeartbeat;
  unsigned long _lastReconnectAttempt;
  uint8_t _reconnectCount;
  bool _otaEnabled;
  bool _wasConnected;

  String _mqttUser;
  String _mqttPass;

  String _telemetryTopic;
  String _commandTopic;
  String _stateTopic;
  String _heartbeatTopic;
  String _otaTopic;
  String _commandResultTopic;

  void _setupTopics();
  void _mqttCallback(char* topic, byte* payload, unsigned int length);
  bool _authenticate();
  void _sendHeartbeat();
  void _handleReconnect();

  static NexlozaClient* _instance;
  static void _staticMqttCallback(char* topic, byte* payload, unsigned int length);
};

#endif
