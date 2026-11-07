#include "NexlozaWiFi.h"

const char* NexlozaWiFi::_ssid = nullptr;
const char* NexlozaWiFi::_password = nullptr;

bool NexlozaWiFi::begin(const char* ssid, const char* password, uint32_t timeoutMs) {
  _ssid = ssid;
  _password = password;

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  Serial.print("[Nexloza WiFi] Connecting to ");
  Serial.print(ssid);

  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED) {
    if (millis() - start > timeoutMs) {
      Serial.println("\n[Nexloza WiFi] Connection timeout");
      return false;
    }
    delay(250);
    Serial.print(".");
  }

  Serial.println();
  Serial.print("[Nexloza WiFi] Connected, IP: ");
  Serial.println(WiFi.localIP());
  return true;
}

bool NexlozaWiFi::isConnected() {
  return WiFi.status() == WL_CONNECTED;
}

int8_t NexlozaWiFi::getSignalStrength() {
  return WiFi.RSSI();
}

String NexlozaWiFi::getLocalIP() {
  return WiFi.localIP().toString();
}

String NexlozaWiFi::getMacAddress() {
  return WiFi.macAddress();
}

bool NexlozaWiFi::reconnect(uint32_t timeoutMs) {
  if (isConnected()) return true;

  Serial.println("[Nexloza WiFi] Reconnecting...");
  WiFi.disconnect();
  delay(100);

  if (_ssid && _password) {
    return begin(_ssid, _password, timeoutMs);
  }
  return false;
}

void NexlozaWiFi::disconnect() {
  WiFi.disconnect(true);
}
