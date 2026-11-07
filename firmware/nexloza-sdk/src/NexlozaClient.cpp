#include "NexlozaClient.h"

NexlozaClient* NexlozaClient::_instance = nullptr;

NexlozaClient::NexlozaClient()
    : _mqttClient(_wifiClient),
      _commandCallback(nullptr),
      _connectionCallback(nullptr),
      _lastHeartbeat(0),
      _lastReconnectAttempt(0),
      _reconnectCount(0),
      _otaEnabled(false),
      _wasConnected(false) {
  _instance = this;
}

void NexlozaClient::begin(NexlozaConfig& config) {
  _config = config;

  if (_config.heartbeatIntervalMs == 0) _config.heartbeatIntervalMs = 30000;
  if (_config.reconnectIntervalMs == 0) _config.reconnectIntervalMs = 5000;
  if (_config.maxReconnectAttempts == 0) _config.maxReconnectAttempts = 10;

  _setupTopics();

  if (_config.useTLS) {
    _wifiSecureClient.setInsecure();
    _mqttClient.setClient(_wifiSecureClient);
  } else {
    _mqttClient.setClient(_wifiClient);
  }

  _mqttClient.setServer(_config.serverHost, _config.mqttPort);
  _mqttClient.setCallback(_staticMqttCallback);
  _mqttClient.setBufferSize(1024);
}

void NexlozaClient::_setupTopics() {
  String prefix = String("nexloza/") + _config.projectId + "/" + _config.deviceId;
  _telemetryTopic = prefix + "/telemetry";
  _commandTopic = prefix + "/command";
  _stateTopic = prefix + "/state";
  _heartbeatTopic = prefix + "/heartbeat";
  _otaTopic = prefix + "/ota";
  _commandResultTopic = prefix + "/command/result";
}

bool NexlozaClient::connect() {
  if (_mqttClient.connected()) return true;

  Serial.println("[Nexloza] Authenticating device...");
  if (!_authenticate()) {
    Serial.println("[Nexloza] Authentication failed");
    return false;
  }

  Serial.print("[Nexloza] Connecting to MQTT broker at ");
  Serial.print(_config.serverHost);
  Serial.print(":");
  Serial.println(_config.mqttPort);

  String clientId = String("nexloza-") + _config.deviceId;

  // Build LWT (Last Will and Testament) payload
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
      _heartbeatTopic.c_str(),
      1,    // QoS 1
      true, // retain
      lwtBuf);

  if (connected) {
    Serial.println("[Nexloza] MQTT connected");
    _mqttClient.subscribe(_commandTopic.c_str(), 1);
    if (_otaEnabled) {
      _mqttClient.subscribe(_otaTopic.c_str(), 1);
    }
    _reconnectCount = 0;
    _sendHeartbeat();

    if (!_wasConnected && _connectionCallback) {
      _connectionCallback(true);
    }
    _wasConnected = true;
    return true;
  }

  Serial.print("[Nexloza] MQTT connect failed, rc=");
  Serial.println(_mqttClient.state());
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
    _mqttClient.publish(_heartbeatTopic.c_str(), buf, len, true);
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
    _sendHeartbeat();
    _lastHeartbeat = now;
  }
}

bool NexlozaClient::publishTelemetry(const char* sensorKey, float value) {
  if (!_mqttClient.connected()) return false;

  JsonDocument doc;
  doc["device_id"] = _config.deviceId;
  doc["sensor_key"] = sensorKey;
  doc["value"] = value;
  doc["timestamp"] = millis();

  char buf[256];
  size_t len = serializeJson(doc, buf, sizeof(buf));
  return _mqttClient.publish(_telemetryTopic.c_str(), buf, len);
}

bool NexlozaClient::publishTelemetry(const char* sensorKey, const char* value) {
  if (!_mqttClient.connected()) return false;

  JsonDocument doc;
  doc["device_id"] = _config.deviceId;
  doc["sensor_key"] = sensorKey;
  doc["value"] = value;
  doc["timestamp"] = millis();

  char buf[256];
  size_t len = serializeJson(doc, buf, sizeof(buf));
  return _mqttClient.publish(_telemetryTopic.c_str(), buf, len);
}

bool NexlozaClient::publishTelemetry(JsonDocument& data) {
  if (!_mqttClient.connected()) return false;

  data["device_id"] = _config.deviceId;
  data["timestamp"] = millis();

  char buf[512];
  size_t len = serializeJson(data, buf, sizeof(buf));
  return _mqttClient.publish(_telemetryTopic.c_str(), buf, len);
}

bool NexlozaClient::reportState(const char* actuatorKey, JsonDocument& state) {
  if (!_mqttClient.connected()) return false;

  JsonDocument doc;
  doc["device_id"] = _config.deviceId;
  doc["actuator_key"] = actuatorKey;
  doc["state"] = state;
  doc["timestamp"] = millis();

  char buf[512];
  size_t len = serializeJson(doc, buf, sizeof(buf));
  return _mqttClient.publish(_stateTopic.c_str(), buf, len, true);
}

bool NexlozaClient::reportDeviceInfo(const char* firmwareVersion, uint32_t freeHeap, int8_t rssi) {
  if (!_mqttClient.connected()) return false;

  JsonDocument doc;
  doc["device_id"] = _config.deviceId;
  doc["firmware_version"] = firmwareVersion;
  doc["free_heap"] = freeHeap;
  doc["rssi"] = rssi;
  doc["uptime_ms"] = millis();
  doc["timestamp"] = millis();

  char buf[256];
  size_t len = serializeJson(doc, buf, sizeof(buf));
  return _mqttClient.publish(_heartbeatTopic.c_str(), buf, len, true);
}

void NexlozaClient::onCommand(CommandCallback callback) {
  _commandCallback = callback;
}

void NexlozaClient::onConnectionChange(ConnectionCallback callback) {
  _connectionCallback = callback;
}

bool NexlozaClient::acknowledgeCommand(const char* commandId, bool success, const char* message) {
  if (!_mqttClient.connected()) return false;

  JsonDocument doc;
  doc["device_id"] = _config.deviceId;
  doc["command_id"] = commandId;
  doc["success"] = success;
  if (message) doc["message"] = message;
  doc["timestamp"] = millis();

  char buf[256];
  size_t len = serializeJson(doc, buf, sizeof(buf));
  return _mqttClient.publish(_commandResultTopic.c_str(), buf, len);
}

void NexlozaClient::enableOTA(bool enable) {
  _otaEnabled = enable;
  if (_mqttClient.connected()) {
    if (enable) {
      _mqttClient.subscribe(_otaTopic.c_str(), 1);
    } else {
      _mqttClient.unsubscribe(_otaTopic.c_str());
    }
  }
}

void NexlozaClient::checkForUpdate() {
  if (!_mqttClient.connected()) return;

  JsonDocument doc;
  doc["device_id"] = _config.deviceId;
  doc["action"] = "check_update";
  doc["timestamp"] = millis();

  char buf[128];
  size_t len = serializeJson(doc, buf, sizeof(buf));
  _mqttClient.publish(_otaTopic.c_str(), buf, len);
}

bool NexlozaClient::_authenticate() {
  HTTPClient http;
  String url = String("http") + (_config.useTLS ? "s" : "") + "://" +
               _config.serverHost + "/api/v1/devices/auth";

  if (_config.useTLS) {
    http.begin(_wifiSecureClient, url);
  } else {
    http.begin(_wifiClient, url);
  }

  http.addHeader("Content-Type", "application/json");

  JsonDocument doc;
  doc["device_id"] = _config.deviceId;
  doc["api_key"] = _config.apiKey;
  doc["api_secret"] = _config.apiSecret;

  char buf[256];
  serializeJson(doc, buf, sizeof(buf));

  int httpCode = http.POST(buf);

  if (httpCode == 200) {
    String response = http.getString();
    JsonDocument resDoc;
    DeserializationError err = deserializeJson(resDoc, response);
    if (!err) {
      _mqttUser = resDoc["mqtt_user"].as<String>();
      _mqttPass = resDoc["mqtt_pass"].as<String>();
      http.end();
      return true;
    }
  }

  // Fallback: use api_key/api_secret directly as MQTT credentials
  _mqttUser = _config.apiKey;
  _mqttPass = _config.apiSecret;
  http.end();
  return true;
}

void NexlozaClient::_sendHeartbeat() {
  JsonDocument doc;
  doc["device_id"] = _config.deviceId;
  doc["status"] = "online";
  doc["uptime_ms"] = millis();
  doc["free_heap"] = ESP.getFreeHeap();
  doc["rssi"] = WiFi.RSSI();
  doc["timestamp"] = millis();

  char buf[256];
  size_t len = serializeJson(doc, buf, sizeof(buf));
  _mqttClient.publish(_heartbeatTopic.c_str(), buf, len, true);
}

void NexlozaClient::_handleReconnect() {
  unsigned long now = millis();
  uint32_t backoff = _config.reconnectIntervalMs * (1 << min(_reconnectCount, (uint8_t)6));
  if (backoff > 60000) backoff = 60000;

  if (now - _lastReconnectAttempt < backoff) return;
  _lastReconnectAttempt = now;

  if (_reconnectCount >= _config.maxReconnectAttempts) {
    Serial.println("[Nexloza] Max reconnect attempts reached, resetting counter");
    _reconnectCount = 0;
    return;
  }

  Serial.print("[Nexloza] Reconnect attempt ");
  Serial.print(_reconnectCount + 1);
  Serial.print("/");
  Serial.println(_config.maxReconnectAttempts);

  if (connect()) {
    _reconnectCount = 0;
  } else {
    _reconnectCount++;
  }
}

void NexlozaClient::_staticMqttCallback(char* topic, byte* payload, unsigned int length) {
  if (_instance) {
    _instance->_mqttCallback(topic, payload, length);
  }
}

void NexlozaClient::_mqttCallback(char* topic, byte* payload, unsigned int length) {
  char message[length + 1];
  memcpy(message, payload, length);
  message[length] = '\0';

  JsonDocument doc;
  DeserializationError err = deserializeJson(doc, message);
  if (err) {
    Serial.print("[Nexloza] JSON parse error: ");
    Serial.println(err.c_str());
    return;
  }

  String topicStr(topic);

  if (topicStr == _commandTopic && _commandCallback) {
    const char* commandType = doc["command_type"] | "unknown";
    JsonObject payload = doc["payload"].as<JsonObject>();
    _commandCallback(commandType, payload);

    if (doc["command_id"]) {
      acknowledgeCommand(doc["command_id"], true);
    }
  } else if (topicStr == _otaTopic && _otaEnabled) {
    Serial.println("[Nexloza] OTA update notification received");
    // OTA handling would trigger HTTP download from a URL in the payload
  }
}
