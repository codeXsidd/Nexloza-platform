#ifndef NEXLOZA_PROVISIONING_H
#define NEXLOZA_PROVISIONING_H

#include <Arduino.h>

#if defined(ESP32)
  #include <WiFi.h>
  #include <WebServer.h>
  #include <Preferences.h>
#elif defined(ESP8266)
  #include <ESP8266WiFi.h>
  #include <ESP8266WebServer.h>
  #include <EEPROM.h>
#endif

#include <DNSServer.h>

struct ProvisioningData {
  char wifiSSID[64];
  char wifiPassword[64];
  char serverHost[128];
  uint16_t mqttPort;
  char deviceId[64];
  char apiKey[64];
  char apiSecret[128];
  char organizationId[64];
  char projectId[64];
  bool valid;
};

class NexlozaProvisioning {
public:
  NexlozaProvisioning();

  void beginAP(const char* apName = "Nexloza-Setup", const char* apPassword = nullptr);
  void handleClient();
  bool isProvisioned();
  bool isComplete();
  ProvisioningData loadCredentials();
  void saveCredentials(const ProvisioningData& data);
  void clearCredentials();

private:
#if defined(ESP32)
  WebServer _server;
  Preferences _prefs;
#elif defined(ESP8266)
  ESP8266WebServer _server;
#endif
  DNSServer _dns;
  bool _complete;

  void _handleRoot();
  void _handleSave();
  void _handleReset();
  String _buildPage();
};

#endif
