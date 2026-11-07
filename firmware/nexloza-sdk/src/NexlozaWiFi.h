#ifndef NEXLOZA_WIFI_H
#define NEXLOZA_WIFI_H

#include <Arduino.h>

#if defined(ESP32)
  #include <WiFi.h>
#elif defined(ESP8266)
  #include <ESP8266WiFi.h>
#endif

class NexlozaWiFi {
public:
  static bool begin(const char* ssid, const char* password, uint32_t timeoutMs = 15000);
  static bool isConnected();
  static int8_t getSignalStrength();
  static String getLocalIP();
  static String getMacAddress();
  static bool reconnect(uint32_t timeoutMs = 10000);
  static void disconnect();

private:
  static const char* _ssid;
  static const char* _password;
};

#endif
