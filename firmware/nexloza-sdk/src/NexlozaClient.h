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

#include "NexlozaLogger.h"
#include "NexlozaSensor.h"
#include "NexlozaActuator.h"

#define NEXLOZA_MAX_SENSORS   16
#define NEXLOZA_MAX_ACTUATORS 16

typedef void (*CommandCallback)(const char* commandType, JsonObject& payload);
typedef void (*ConnectionCallback)(bool connected);
typedef void (*ErrorCallback)(int code, const char* message);

enum NexlozaError {
  ERR_WIFI_DISCONNECTED = 100,
  ERR_MQTT_CONNECT_FAILED = 200,
  ERR_MQTT_PUBLISH_FAILED = 201,
  ERR_AUTH_FAILED = 300,
  ERR_AUTH_HTTP_ERROR = 301,
  ERR_COMMAND_EXPIRED = 400,
  ERR_COMMAND_INVALID = 401,
  ERR_SENSOR_READ = 500,
  ERR_ACTUATOR_EXECUTE = 501,
  ERR_JSON_PARSE = 600,
  ERR_BUFFER_OVERFLOW = 601
};

struct NexlozaConfig {
  const char* serverHost;
  uint16_t mqttPort;
  const char* deviceId;
  const char* apiKey;
  const char* apiSecret;
  const char* organizationId;
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

  // Telemetry
  bool publishTelemetry(const char* sensorKey, float value);
  bool publishTelemetry(const char* sensorKey, const char* value);
  bool publishTelemetry(JsonDocument& data);

  // State
  bool reportState(const char* actuatorKey, JsonDocument& state);
  bool reportDeviceInfo(const char* firmwareVersion, uint32_t freeHeap, int8_t rssi);

  // Sensor/Actuator framework
  bool addSensor(NexlozaSensor* sensor);
  bool addActuator(NexlozaActuator* actuator);
  bool registerSensor(const char* sensorKey, const char* sensorType, const char* unit);
  bool registerActuator(const char* actuatorKey, const char* actuatorType);
  void updateSensors();

  // Commands
  bool sendCommand(const char* targetDeviceId, const char* commandType, JsonDocument& payload);
  bool acknowledgeCommand(const char* commandId, bool success, const char* message = nullptr);

  // Metadata
  void setDeviceMetadata(const char* key, const char* value);

  // Callbacks
  void onCommand(CommandCallback callback);
  void onConnectionChange(ConnectionCallback callback);
  void onError(ErrorCallback callback);

  // Lifecycle
  void heartbeat();
  bool reconnect();
  void setLogLevel(NexlozaLogLevel level);

  // OTA
  void enableOTA(bool enable);
  void checkForUpdate();

private:
  NexlozaConfig _config;
  WiFiClient _wifiClient;
  WiFiClientSecure _wifiSecureClient;
  PubSubClient _mqttClient;
  CommandCallback _commandCallback;
  ConnectionCallback _connectionCallback;
  ErrorCallback _errorCallback;

  unsigned long _lastHeartbeat;
  unsigned long _lastReconnectAttempt;
  uint8_t _reconnectCount;
  bool _otaEnabled;
  bool _wasConnected;
  uint32_t _messageCounter;

  String _mqttUser;
  String _mqttPass;

  String _telemetryTopic;
  String _commandTopic;
  String _commandAckTopic;
  String _stateTopic;
  String _statusTopic;
  String _configTopic;

  JsonDocument _metadata;

  NexlozaSensor* _sensors[NEXLOZA_MAX_SENSORS];
  uint8_t _sensorCount;
  NexlozaActuator* _actuators[NEXLOZA_MAX_ACTUATORS];
  uint8_t _actuatorCount;

  void _setupTopics();
  void _mqttCallback(char* topic, byte* payload, unsigned int length);
  bool _authenticate();
  void _handleReconnect();
  void _emitError(int code, const char* msg);
  String _generateMessageId();
  bool _isCommandExpired(JsonObject& doc);
  NexlozaActuator* _findActuator(const char* id);

  static NexlozaClient* _instance;
  static void _staticMqttCallback(char* topic, byte* payload, unsigned int length);
};

#endif
