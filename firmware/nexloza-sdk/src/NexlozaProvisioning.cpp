#include "NexlozaProvisioning.h"

#if defined(ESP8266)
  #define EEPROM_SIZE 512
  #define EEPROM_MAGIC 0x4E58 // "NX"
#endif

NexlozaProvisioning::NexlozaProvisioning() : _server(80), _complete(false) {}

void NexlozaProvisioning::beginAP(const char* apName, const char* apPassword) {
  WiFi.mode(WIFI_AP);
  if (apPassword && strlen(apPassword) >= 8) {
    WiFi.softAP(apName, apPassword);
  } else {
    WiFi.softAP(apName);
  }

  _dns.start(53, "*", WiFi.softAPIP());

  _server.on("/", [this]() { _handleRoot(); });
  _server.on("/save", HTTP_POST, [this]() { _handleSave(); });
  _server.on("/reset", [this]() { _handleReset(); });
  _server.onNotFound([this]() { _handleRoot(); });

  _server.begin();

  Serial.print("[Nexloza Provisioning] AP started: ");
  Serial.println(apName);
  Serial.print("[Nexloza Provisioning] Portal IP: ");
  Serial.println(WiFi.softAPIP());
}

void NexlozaProvisioning::handleClient() {
  _dns.processNextRequest();
  _server.handleClient();
}

bool NexlozaProvisioning::isComplete() {
  return _complete;
}

bool NexlozaProvisioning::isProvisioned() {
  ProvisioningData data = loadCredentials();
  return data.valid;
}

ProvisioningData NexlozaProvisioning::loadCredentials() {
  ProvisioningData data;
  memset(&data, 0, sizeof(data));
  data.valid = false;

#if defined(ESP32)
  _prefs.begin("nexloza", true);
  if (_prefs.getBool("provisioned", false)) {
    String ssid = _prefs.getString("wifi_ssid", "");
    String pass = _prefs.getString("wifi_pass", "");
    String host = _prefs.getString("server_host", "");
    data.mqttPort = _prefs.getUShort("mqtt_port", 1883);
    String devId = _prefs.getString("device_id", "");
    String apiKey = _prefs.getString("api_key", "");
    String apiSec = _prefs.getString("api_secret", "");
    String projId = _prefs.getString("project_id", "");

    strlcpy(data.wifiSSID, ssid.c_str(), sizeof(data.wifiSSID));
    strlcpy(data.wifiPassword, pass.c_str(), sizeof(data.wifiPassword));
    strlcpy(data.serverHost, host.c_str(), sizeof(data.serverHost));
    strlcpy(data.deviceId, devId.c_str(), sizeof(data.deviceId));
    strlcpy(data.apiKey, apiKey.c_str(), sizeof(data.apiKey));
    strlcpy(data.apiSecret, apiSec.c_str(), sizeof(data.apiSecret));
    strlcpy(data.projectId, projId.c_str(), sizeof(data.projectId));
    data.valid = ssid.length() > 0 && devId.length() > 0;
  }
  _prefs.end();
#elif defined(ESP8266)
  EEPROM.begin(EEPROM_SIZE);
  uint16_t magic;
  EEPROM.get(0, magic);
  if (magic == EEPROM_MAGIC) {
    EEPROM.get(2, data);
    data.valid = strlen(data.wifiSSID) > 0 && strlen(data.deviceId) > 0;
  }
  EEPROM.end();
#endif

  return data;
}

void NexlozaProvisioning::saveCredentials(const ProvisioningData& data) {
#if defined(ESP32)
  _prefs.begin("nexloza", false);
  _prefs.putBool("provisioned", true);
  _prefs.putString("wifi_ssid", data.wifiSSID);
  _prefs.putString("wifi_pass", data.wifiPassword);
  _prefs.putString("server_host", data.serverHost);
  _prefs.putUShort("mqtt_port", data.mqttPort);
  _prefs.putString("device_id", data.deviceId);
  _prefs.putString("api_key", data.apiKey);
  _prefs.putString("api_secret", data.apiSecret);
  _prefs.putString("project_id", data.projectId);
  _prefs.end();
#elif defined(ESP8266)
  EEPROM.begin(EEPROM_SIZE);
  uint16_t magic = EEPROM_MAGIC;
  EEPROM.put(0, magic);
  EEPROM.put(2, data);
  EEPROM.commit();
  EEPROM.end();
#endif
  Serial.println("[Nexloza Provisioning] Credentials saved");
}

void NexlozaProvisioning::clearCredentials() {
#if defined(ESP32)
  _prefs.begin("nexloza", false);
  _prefs.clear();
  _prefs.end();
#elif defined(ESP8266)
  EEPROM.begin(EEPROM_SIZE);
  for (int i = 0; i < EEPROM_SIZE; i++) EEPROM.write(i, 0);
  EEPROM.commit();
  EEPROM.end();
#endif
  Serial.println("[Nexloza Provisioning] Credentials cleared");
}

void NexlozaProvisioning::_handleRoot() {
  _server.send(200, "text/html", _buildPage());
}

void NexlozaProvisioning::_handleSave() {
  ProvisioningData data;
  memset(&data, 0, sizeof(data));

  strlcpy(data.wifiSSID, _server.arg("ssid").c_str(), sizeof(data.wifiSSID));
  strlcpy(data.wifiPassword, _server.arg("pass").c_str(), sizeof(data.wifiPassword));
  strlcpy(data.serverHost, _server.arg("host").c_str(), sizeof(data.serverHost));
  data.mqttPort = _server.arg("mqtt_port").toInt();
  if (data.mqttPort == 0) data.mqttPort = 1883;
  strlcpy(data.deviceId, _server.arg("device_id").c_str(), sizeof(data.deviceId));
  strlcpy(data.apiKey, _server.arg("api_key").c_str(), sizeof(data.apiKey));
  strlcpy(data.apiSecret, _server.arg("api_secret").c_str(), sizeof(data.apiSecret));
  strlcpy(data.projectId, _server.arg("project_id").c_str(), sizeof(data.projectId));
  data.valid = true;

  saveCredentials(data);
  _complete = true;

  String html = "<!DOCTYPE html><html><head><meta charset='UTF-8'>"
                "<meta name='viewport' content='width=device-width,initial-scale=1'>"
                "<title>Nexloza Setup</title>"
                "<style>body{font-family:sans-serif;text-align:center;padding:40px;background:#1a1a2e;color:#eee}"
                ".ok{background:#00b894;padding:20px;border-radius:12px;margin:20px auto;max-width:400px}</style>"
                "</head><body><div class='ok'><h2>Saved!</h2>"
                "<p>Device will restart and connect.</p></div></body></html>";
  _server.send(200, "text/html", html);
}

void NexlozaProvisioning::_handleReset() {
  clearCredentials();
  _server.send(200, "text/html",
    "<!DOCTYPE html><html><body style='text-align:center;padding:40px;background:#1a1a2e;color:#eee'>"
    "<h2>Reset complete</h2><p><a href='/' style='color:#00cec9'>Return to setup</a></p></body></html>");
}

String NexlozaProvisioning::_buildPage() {
  return String(
    "<!DOCTYPE html><html><head><meta charset='UTF-8'>"
    "<meta name='viewport' content='width=device-width,initial-scale=1'>"
    "<title>Nexloza Device Setup</title>"
    "<style>"
    "body{font-family:-apple-system,BlinkMacSystemFont,sans-serif;margin:0;padding:20px;"
    "background:#1a1a2e;color:#eee;min-height:100vh}"
    ".c{max-width:420px;margin:0 auto}"
    "h1{color:#00cec9;text-align:center;margin-bottom:8px}"
    "p.sub{text-align:center;color:#888;margin-top:0}"
    "label{display:block;margin-top:16px;font-size:14px;color:#aaa}"
    "input{width:100%;padding:12px;margin-top:4px;border:1px solid #333;border-radius:8px;"
    "background:#16213e;color:#eee;font-size:16px;box-sizing:border-box}"
    "input:focus{outline:none;border-color:#00cec9}"
    "button{width:100%;padding:14px;margin-top:24px;background:#00cec9;color:#1a1a2e;"
    "border:none;border-radius:8px;font-size:16px;font-weight:bold;cursor:pointer}"
    "button:hover{background:#00b894}"
    "hr{border:0;border-top:1px solid #333;margin:20px 0}"
    ".s{font-size:12px;text-align:center;color:#666}"
    "</style></head><body><div class='c'>"
    "<h1>Nexloza</h1>"
    "<p class='sub'>Device Setup Portal</p>"
    "<form method='POST' action='/save'>"
    "<label>WiFi Network Name (SSID)</label>"
    "<input name='ssid' required>"
    "<label>WiFi Password</label>"
    "<input name='pass' type='password'>"
    "<hr>"
    "<label>Server Host</label>"
    "<input name='host' placeholder='mqtt.nexloza.com' required>"
    "<label>MQTT Port</label>"
    "<input name='mqtt_port' type='number' value='1883'>"
    "<label>Device ID</label>"
    "<input name='device_id' required>"
    "<label>API Key</label>"
    "<input name='api_key' required>"
    "<label>API Secret</label>"
    "<input name='api_secret' type='password' required>"
    "<label>Project ID</label>"
    "<input name='project_id' required>"
    "<button type='submit'>Save &amp; Connect</button>"
    "</form>"
    "<p class='s' style='margin-top:20px'><a href='/reset' style='color:#e17055'>Reset Credentials</a></p>"
    "</div></body></html>");
}
