#ifndef NEXLOZA_LOGGER_H
#define NEXLOZA_LOGGER_H

#include <Arduino.h>

enum class NexlozaLogLevel : uint8_t {
  NONE  = 0,
  ERR   = 1,
  WARN  = 2,
  INFO  = 3,
  DEBUG = 4
};

class NexlozaLogger {
public:
  static void setLevel(NexlozaLogLevel level) { _level = level; }
  static NexlozaLogLevel getLevel() { return _level; }

  static void error(const char* tag, const char* msg) {
    if (_level >= NexlozaLogLevel::ERR) _print("ERROR", tag, msg);
  }

  static void warn(const char* tag, const char* msg) {
    if (_level >= NexlozaLogLevel::WARN) _print("WARN", tag, msg);
  }

  static void info(const char* tag, const char* msg) {
    if (_level >= NexlozaLogLevel::INFO) _print("INFO", tag, msg);
  }

  static void debug(const char* tag, const char* msg) {
    if (_level >= NexlozaLogLevel::DEBUG) _print("DEBUG", tag, msg);
  }

  static void error(const char* tag, const String& msg) { error(tag, msg.c_str()); }
  static void warn(const char* tag, const String& msg)  { warn(tag, msg.c_str()); }
  static void info(const char* tag, const String& msg)   { info(tag, msg.c_str()); }
  static void debug(const char* tag, const String& msg)  { debug(tag, msg.c_str()); }

private:
  static NexlozaLogLevel _level;

  static void _print(const char* level, const char* tag, const char* msg) {
    Serial.printf("[%s][%s] %s\n", level, tag, msg);
  }
};

#endif
