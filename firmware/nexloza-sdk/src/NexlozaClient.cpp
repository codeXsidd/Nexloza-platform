#include "NexlozaClient.h"

static const char* TAG = "Nexloza";

NexlozaClient* NexlozaClient::_instance = nullptr;

NexlozaClient::NexlozaClient()
    : _mqttClient(_wifiClient),
      _commandCallback(nullptr),
      _connectionCallback(nullptr),
      _errorCallback(nullptr),
      _lastHeartbeat(0),
      _lastReconnectAttempt(0),
      _reconnectCount(0),
      _otaEnabled(false),
      _wasConnected(false),
      _messageCounter(0),
      _sensorCount(0),
      _actuatorCount(0) {
  _instance = this;
  memset(_sensors, 0, sizeof(_sensors));
  memset(_actuators, 0, sizeof(_actuators));
}

void NexlozaClient::begin(NexlozaConfig& config) {
  _config = config;

  if (_config.heartbeatIntervalMs == 0) _config.heartbeatIntervalMs = 30000;
  if (_config.reconnectIntervalMs == 0) _config.reconnectIntervalMs = 5000;
  if (_config.maxReconnectAttempts == 0) _config.maxReconnectAttempts = 10;

  _setupTopics();

  if (_config.useTLS) {
    _wifiSecureClient.setInsecure(); // TODO: Add CA certificate provisioning
    _mqttClient.setClient(_wifiSecureClient);
  } else {
    _mqttClient.setClient(_wifiClient);
  }

  _mqttClient.setServer(_config.serverHost, _config.mqttPort);
  _mqttClient.setCallback(_staticMqttCallback);
  _mqttClient.setBufferSize(1024);

  NexlozaLogger::info(TAG, "SDK initialized");
}

void NexlozaClient::_setupTopics() {
  String prefix = String("nexloza/v1/") +
                  _config.organizationId + "/" +
                  _config.projectId + "/" +
                  _config.deviceId;
  _telemetryTopic = prefix + "/telemetry";
  _commandTopic = prefix + "/command";
  _commandAckTopic = prefix + "/command-ack";
  _stateTopic = prefix + "/state";
  _statusTopic = prefix + "/status";
  _configTopic = prefix + "/config";
}

bool NexlozaClient::connect() {
  if (_mqttClient.connected()) return true;

  NexlozaLogger::info(TAG, "Authenticating device...");
  if (!_authenticate()) {
    NexlozaLogger::error(TAG, "Authentication failed");
    _emitError(ERR_AUTH_FAILED, "Authentication failed");
    return false;
  }

  NexlozaLogger::info(TAG, String("Connecting to MQTT ") + _config.serverHost + ":" + String(_config.mqttPort));

  String clientId = String("nexloza-") + _config.deviceId;

  JsonDocument lwt;
  lwt["device_id"] = _config.deviceId;
  lwt["status"] = "offline";
  lwt["timestamp"] = millis();
  char lwtBuf[128];
  serializeJson(lwt, lwtBuf, sizeof(lwtBuf));

  bool connected = _mqttClient.connect(
      clientId.c_str(),
      _mqttUser.c_str(),
      _mqttPass.c_str(),
      _statusTopic.c_str(),
      1,
      true,
      lwtBuf);

  if (connected) {
    NexlozaLogger::info(TAG, "MQTT connected");
    _mqttClient.subscribe(_commandTopic.c_str(), 1);
    _mqttClient.subscribe(_configTopic.c_str(), 1);
    if (_otaEnabled) {
      _mqttClient.subscribe((_statusTopic + "/ota").c_str(), 1);
    }
    _reconnectCount = 0;
    heartbeat();

    // Register all sensors and actuators
    for (uint8_t i = 0; i < _sensorCount; i++) {
      if (_sensors[i]) {
        registerSensor(_sensors[i]->config().id,
                       _sensors[i]->config().type,
                       _sensors[i]->config().unit);
      }
    }
    for (uint8_t i = 0; i < _actuatorCount; i++) {
      if (_actuators[i]) {
        registerActuator(_actuators[i]->config().id,
                         _actuators[i]->config().type);
      }
    }

    if (!_wasConnected && _connectionCallback) {
      _connectionCallback(true);
    }
    _wasConnected = true;
    return true;
  }

  NexlozaLogger::error(TAG, String("MQTT connect failed, rc=") + String(_mqttClient.state()));
  _emitError(ERR_MQTT_CONNECT_FAILED, "MQTT connection failed");
  return false;
}

void NexlozaClient::disconnect() {
  if (_mqttClient.connected()) {
    JsonDocument doc;
    doc["device_id"] = _config.deviceId;
    doc["status"] = "offline";
    doc["timestamp"] = millis();
    char buf[128];
    size_t len = serializeJson(doc, buf, sizeof(buf));
    _mqttClient.publish(_statusTopic.c_str(), buf, len, true);
    _mqttClient.disconnect();
  }
  _wasConnected = false;
  if (_connectionCallback) _connectionCallback(false);
}

bool NexlozaClient::isConnected() {
  return _mqttClient.connected();
}

void NexlozaClient::loop() {
  if (!_mqttClient.connected()) {
    if (_wasConnected && _connectionCallback) {
      _connectionCallback(false);
      _wasConnected = false;
    }
    _handleReconnect();
    return;
  }

  _mqttClient.loop();

  unsigned long now = millis();
  if (now - _lastHeartbeat >= _config.heartbeatIntervalMs) {
    heartbeat();
    _lastHeartbeat = now;
  }

  updateSensors();
}

// --- Telemetry ---

bool NexlozaClient::publishTelemetry(const char* sensorKey, float value) {
  if (!_mqttClient.connected()) return false;

  JsonDocument doc;
  doc["version"] = 1;
  doc["message_id"] = _generateMessageId();
  doc["device_id"] = _config.deviceId;
  doc["sensor_id"] = sensorKey;
  doc["value"] = value;
  doc["timestamp"] = millis();

  char buf[256];
  size_t len = serializeJson(doc, buf, sizeof(buf));
  bool ok = _mqttClient.publish(_telemetryTopic.c_str(), buf, len);
  if (!ok) _emitError(ERR_MQTT_PUBLISH_FAILED, "Telemetry publish failed");
  return ok;
}

bool NexlozaClient::publishTelemetry(const char* sensorKey, const char* value) {
  if (!_mqttClient.connected()) return false;

  JsonDocument doc;
  doc["version"] = 1;
  doc["message_id"] = _generateMessageId();
  doc["device_id"] = _config.deviceId;
  doc["sensor_id"] = sensorKey;
  doc["value"] = value;
  doc["timestamp"] = millis();

  char buf[256];
  size_t len = serializeJson(doc, buf, sizeof(buf));
  bool ok = _mqttClient.publish(_telemetryTopic.c_str(), buf, len);
  if (!ok) _emitError(ERR_MQTT_PUBLISH_FAILED, "Telemetry publish failed");
  return ok;
}

bool NexlozaClient::publishTelemetry(JsonDocument& data) {
  if (!_mqttClient.connected()) return false;

  data["version"] = 1;
  data["message_id"] = _generateMessageId();
  data["device_id"] = _config.deviceId;
  data["timestamp"] = millis();

  char buf[512];
  size_t len = serializeJson(data, buf, sizeof(buf));
  if (len >= sizeof(buf)) {
    _emitError(ERR_BUFFER_OVERFLOW, "Telemetry too large");
    return false;
  }
  bool ok = _mqttClient.publish(_telemetryTopic.c_str(), buf, len);
  if (!ok) _emitError(ERR_MQTT_PUBLISH_FAILED, "Telemetry publish failed");
  return ok;
}

// --- State ---

bool NexlozaClient::reportState(const char* actuatorKey, JsonDocument& state) {
  if (!_mqttClient.connected()) return false;

  JsonDocument doc;
  doc["version"] = 1;
  doc["device_id"] = _config.deviceId;
  doc["actuator_id"] = actuatorKey;
  doc["state"] = state;
  doc["timestamp"] = millis();

  char buf[512];
  size_t len = serializeJson(doc, buf, sizeof(buf));
  return _mqttClient.publish(_stateTopic.c_str(), buf, len, true);
}

bool NexlozaClient::reportDeviceInfo(const char* firmwareVersion, uint32_t freeHeap, int8_t rssi) {
  if (!_mqttClient.connected()) return false;

  JsonDocument doc;
  doc["version"] = 1;
  doc["device_id"] = _config.deviceId;
  doc["firmware_version"] = firmwareVersion;
  doc["free_heap"] = freeHeap;
  doc["rssi"] = rssi;
  doc["uptime_ms"] = millis();
  doc["timestamp"] = millis();

  char buf[256];
  size_t len = serializeJson(doc, buf, sizeof(buf));
  return _mqttClient.publish(_statusTopic.c_str(), buf, len, true);
}

// --- Sensor/Actuator framework ---

bool NexlozaClient::addSensor(NexlozaSensor* sensor) {
  if (_sensorCount >= NEXLOZA_MAX_SENSORS) return false;
  sensor->begin();
  _sensors[_sensorCount++] = sensor;
  NexlozaLogger::info(TAG, String("Sensor added: ") + sensor->id());
  return true;
}

bool NexlozaClient::addActuator(NexlozaActuator* actuator) {
  if (_actuatorCount >= NEXLOZA_MAX_ACTUATORS) return false;
  actuator->begin();
  _actuators[_actuatorCount++] = actuator;
  NexlozaLogger::info(TAG, String("Actuator added: ") + actuator->id());
  return true;
}

void NexlozaClient::updateSensors() {
  for (uint8_t i = 0; i < _sensorCount; i++) {
    NexlozaSensor* s = _sensors[i];
    if (s && s->shouldRead()) {
      float val = s->performRead();
      if (!isnan(val) && _mqttClient.connected()) {
        publishTelemetry(s->config().id, val);
      } else if (isnan(val)) {
        _emitError(ERR_SENSOR_READ, s->config().id);
      }
    }
  }
}

bool NexlozaClient::registerSensor(const char* sensorKey, const char* sensorType, const char* unit) {
  if (!_mqttClient.connected()) return false;

  JsonDocument doc;
  doc["version"] = 1;
  doc["device_id"] = _config.deviceId;
  doc["action"] = "register_sensor";
  doc["sensor_id"] = sensorKey;
  doc["sensor_type"] = sensorType;
  doc["unit"] = unit;
  doc["timestamp"] = millis();

  char buf[256];
  size_t len = serializeJson(doc, buf, sizeof(buf));
  return _mqttClient.publish(_stateTopic.c_str(), buf, len);
}

bool NexlozaClient::registerActuator(const char* actuatorKey, const char* actuatorType) {
  if (!_mqttClient.connected()) return false;

  JsonDocument doc;
  doc["version"] = 1;
  doc["device_id"] = _config.deviceId;
  doc["action"] = "register_actuator";
  doc["actuator_id"] = actuatorKey;
  doc["actuator_type"] = actuatorType;
  doc["timestamp"] = millis();

  char buf[256];
  size_t len = serializeJson(doc, buf, sizeof(buf));
  return _mqttClient.publish(_stateTopic.c_str(), buf, len);
}

// --- Commands ---

bool NexlozaClient::sendCommand(const char* targetDeviceId, const char* commandType, JsonDocument& payload) {
  if (!_mqttClient.connected()) return false;

  String targetTopic = String("nexloza/v1/") +
                       _config.organizationId + "/" +
                       _config.projectId + "/" +
                       targetDeviceId + "/command";

  JsonDocument doc;
  doc["version"] = 1;
  doc["command_id"] = _generateMessageId();
  doc["command_type"] = commandType;
  doc["payload"] = payload;
  doc["source_device"] = _config.deviceId;
  doc["timestamp"] = millis();

  char buf[512];
  size_t len = serializeJson(doc, buf, sizeof(buf));
  return _mqttClient.publish(targetTopic.c_str(), buf, len);
}

bool NexlozaClient::acknowledgeCommand(const char* commandId, bool success, const char* message) {
  if (!_mqttClient.connected()) return false;

  JsonDocument doc;
  doc["version"] = 1;
  doc["device_id"] = _config.deviceId;
  doc["command_id"] = commandId;
  doc["status"] = success ? "success" : "failed";
  if (message) doc["message"] = message;
  doc["timestamp"] = millis();

  char buf[256];
  size_t len = serializeJson(doc, buf, sizeof(buf));
  return _mqttClient.publish(_commandAckTopic.c_str(), buf, len);
}

// --- Metadata ---

void NexlozaClient::setDeviceMetadata(const char* key, const char* value) {
  _metadata[key] = value;
}

// --- Callbacks ---

void NexlozaClient::onCommand(CommandCallback callback) {
  _commandCallback = callback;
}

void NexlozaClient::onConnectionChange(ConnectionCallback callback) {
  _connectionCallback = callback;
}

void NexlozaClient::onError(ErrorCallback callback) {
  _errorCallback = callback;
}

// --- Lifecycle ---

void NexlozaClient::heartbeat() {
  if (!_mqttClient.connected()) return;

  JsonDocument doc;
  doc["version"] = 1;
  doc["device_id"] = _config.deviceId;
  doc["status"] = "online";
  doc["uptime_ms"] = millis();
  doc["free_heap"] = ESP.getFreeHeap();
  doc["rssi"] = WiFi.RSSI();
  doc["timestamp"] = millis();

  if (_metadata.size() > 0) {
    doc["metadata"] = _metadata;
  }

  char buf[512];
  size_t len = serializeJson(doc, buf, sizeof(buf));
  _mqttClient.publish(_statusTopic.c_str(), buf, len, true);
}

bool NexlozaClient::reconnect() {
  if (_mqttClient.connected()) return true;
  _reconnectCount = 0;
  return connect();
}

void NexlozaClient::setLogLevel(NexlozaLogLevel level) {
  NexlozaLogger::setLevel(level);
}

// --- OTA ---

void NexlozaClient::enableOTA(bool enable) {
  _otaEnabled = enable;
  if (_mqttClient.connected()) {
    String otaTopic = _statusTopic + "/ota";
    if (enable) {
      _mqttClient.subscribe(otaTopic.c_str(), 1);
    } else {
      _mqttClient.unsubscribe(otaTopic.c_str());
    }
  }
}

void NexlozaClient::checkForUpdate() {
  if (!_mqttClient.connected()) return;

  JsonDocument doc;
  doc["device_id"] = _config.deviceId;
  doc["action"] = "check_update";
  doc["timestamp"] = millis();

  String otaTopic = _statusTopic + "/ota";
  char buf[128];
  size_t len = serializeJson(doc, buf, sizeof(buf));
  _mqttClient.publish(otaTopic.c_str(), buf, len);
}

// --- Private ---

bool NexlozaClient::_authenticate() {
  HTTPClient http;
  String url = String("http") + (_config.useTLS ? "s" : "") + "://" +
               _config.serverHost + "/functions/v1/device-auth";

  if (_config.useTLS) {
    http.begin(_wifiSecureClient, url);
  } else {
    http.begin(_wifiClient, url);
  }

  http.addHeader("Content-Type", "application/json");
  http.addHeader("x-api-key", _config.apiKey);
  http.addHeader("x-api-secret", _config.apiSecret);

  int httpCode = http.POST("{}");

  if (httpCode == 200) {
    String response = http.getString();
    JsonDocument resDoc;
    DeserializationError err = deserializeJson(resDoc, response);
    if (!err) {
      _mqttUser = resDoc["mqtt"]["username"].as<String>();
      _mqttPass = _config.apiSecret;
      http.end();
      NexlozaLogger::info(TAG, "Authentication successful");
      return true;
    }
    _emitError(ERR_JSON_PARSE, "Auth response parse error");
  } else {
    NexlozaLogger::error(TAG, String("Auth HTTP ") + String(httpCode));
    _emitError(ERR_AUTH_HTTP_ERROR, "Auth HTTP error");
  }

  http.end();
  return false;
}

void NexlozaClient::_handleReconnect() {
  unsigned long now = millis();
  uint32_t backoff = _config.reconnectIntervalMs * (1 << min(_reconnectCount, (uint8_t)6));
  if (backoff > 60000) backoff = 60000;

  if (now - _lastReconnectAttempt < backoff) return;
  _lastReconnectAttempt = now;

  if (_reconnectCount >= _config.maxReconnectAttempts) {
    NexlozaLogger::warn(TAG, "Max reconnect attempts reached, resetting counter");
    _reconnectCount = 0;
    return;
  }

  NexlozaLogger::info(TAG, String("Reconnect attempt ") + String(_reconnectCount + 1) +
                       "/" + String(_config.maxReconnectAttempts));

  if (connect()) {
    _reconnectCount = 0;
  } else {
    _reconnectCount++;
  }
}

void NexlozaClient::_emitError(int code, const char* msg) {
  NexlozaLogger::error(TAG, String("Error ") + String(code) + ": " + msg);
  if (_errorCallback) _errorCallback(code, msg);
}

String NexlozaClient::_generateMessageId() {
  _messageCounter++;
  return String(_config.deviceId) + "-" + String(millis()) + "-" + String(_messageCounter);
}

bool NexlozaClient::_isCommandExpired(JsonObject& doc) {
  if (!doc.containsKey("expires_at")) return false;
  // expires_at is a Unix timestamp in seconds
  unsigned long expiresAt = doc["expires_at"].as<unsigned long>();
  // Compare with millis/1000 as a rough check (no RTC assumed)
  // If the command has an expires_at far in the past, skip it
  if (expiresAt > 0 && expiresAt < 1000000000UL) {
    // Looks like millis-based — compare to millis
    return millis() > expiresAt;
  }
  return false;
}

NexlozaActuator* NexlozaClient::_findActuator(const char* id) {
  for (uint8_t i = 0; i < _actuatorCount; i++) {
    if (_actuators[i] && strcmp(_actuators[i]->id(), id) == 0) {
      return _actuators[i];
    }
  }
  return nullptr;
}

void NexlozaClient::_staticMqttCallback(char* topic, byte* payload, unsigned int length) {
  if (_instance) {
    _instance->_mqttCallback(topic, payload, length);
  }
}

void NexlozaClient::_mqttCallback(char* topic, byte* payload, unsigned int length) {
  if (length > 1024) {
    NexlozaLogger::warn(TAG, "Message too large, ignoring");
    return;
  }

  char message[length + 1];
  memcpy(message, payload, length);
  message[length] = '\0';

  JsonDocument doc;
  DeserializationError err = deserializeJson(doc, message);
  if (err) {
    NexlozaLogger::error(TAG, String("JSON parse error: ") + err.c_str());
    _emitError(ERR_JSON_PARSE, err.c_str());
    return;
  }

  String topicStr(topic);

  if (topicStr == _commandTopic) {
    JsonObject obj = doc.as<JsonObject>();

    // Check command expiry
    if (_isCommandExpired(obj)) {
      NexlozaLogger::warn(TAG, "Expired command ignored");
      _emitError(ERR_COMMAND_EXPIRED, "Command expired");
      if (doc["command_id"]) {
        acknowledgeCommand(doc["command_id"], false, "Command expired");
      }
      return;
    }

    const char* commandType = doc["command_type"] | "unknown";

    // Try framework actuators first
    const char* actuatorId = doc["actuator_id"] | doc["payload"]["actuator_id"] | (const char*)nullptr;
    if (actuatorId) {
      NexlozaActuator* actuator = _findActuator(actuatorId);
      if (actuator) {
        JsonObject cmdPayload = doc["payload"].as<JsonObject>();
        bool ok = actuator->execute(cmdPayload);
        if (doc["command_id"]) {
          acknowledgeCommand(doc["command_id"], ok, ok ? "Executed" : "Actuator error");
        }
        // Report actual state after execution
        JsonDocument stateDoc;
        actuator->getState(stateDoc);
        reportState(actuator->id(), stateDoc);
        return;
      }
    }

    // Fall through to user callback
    if (_commandCallback) {
      JsonObject cmdPayload = doc["payload"].is<JsonObject>()
                                  ? doc["payload"].as<JsonObject>()
                                  : doc.as<JsonObject>();
      _commandCallback(commandType, cmdPayload);
    }

    // Auto-acknowledge only if no user callback handled it
    if (!_commandCallback && doc["command_id"]) {
      acknowledgeCommand(doc["command_id"], true);
    }

  } else if (topicStr == _configTopic) {
    NexlozaLogger::info(TAG, "Configuration update received");
  } else if (_otaEnabled && topicStr.endsWith("/ota")) {
    NexlozaLogger::info(TAG, "OTA update notification received");
  }
}
