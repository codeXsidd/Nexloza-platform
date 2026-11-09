#ifndef NEXLOZA_ACTUATOR_H
#define NEXLOZA_ACTUATOR_H

#include <Arduino.h>
#include <ArduinoJson.h>

struct ActuatorConfig {
  const char* id;
  const char* name;
  const char* type;
  bool safeDefault;
  uint32_t commandTimeoutMs;
};

enum class ActuatorStatus : uint8_t {
  IDLE,
  EXECUTING,
  SUCCESS,
  FAILED,
  TIMEOUT
};

class NexlozaActuator {
public:
  NexlozaActuator() : _status(ActuatorStatus::IDLE) {}
  virtual ~NexlozaActuator() {}

  void configure(const ActuatorConfig& cfg) {
    _config = cfg;
    if (_config.commandTimeoutMs == 0) _config.commandTimeoutMs = 5000;
  }

  const ActuatorConfig& config() const { return _config; }
  const char* id() const { return _config.id; }
  const char* name() const { return _config.name; }
  ActuatorStatus status() const { return _status; }

  virtual bool begin() {
    applySafeDefault();
    return true;
  }

  virtual bool execute(JsonObject& command) = 0;

  virtual void getState(JsonDocument& state) = 0;

  virtual void applySafeDefault() {}

  const char* statusString() const {
    switch (_status) {
      case ActuatorStatus::IDLE:      return "idle";
      case ActuatorStatus::EXECUTING: return "executing";
      case ActuatorStatus::SUCCESS:   return "success";
      case ActuatorStatus::FAILED:    return "failed";
      case ActuatorStatus::TIMEOUT:   return "timeout";
      default:                        return "unknown";
    }
  }

protected:
  ActuatorConfig _config;
  ActuatorStatus _status;
};

// Digital output actuator — relay, LED, buzzer, etc.
class DigitalActuator : public NexlozaActuator {
public:
  DigitalActuator(uint8_t pin, bool activeLow = false)
    : _pin(pin), _activeLow(activeLow), _on(false) {}

  bool begin() override {
    pinMode(_pin, OUTPUT);
    applySafeDefault();
    return true;
  }

  bool execute(JsonObject& command) override {
    _status = ActuatorStatus::EXECUTING;
    bool value = command["value"] | command["state"] | false;
    setOutput(value);
    _status = ActuatorStatus::SUCCESS;
    return true;
  }

  void getState(JsonDocument& state) override {
    state["on"] = _on;
  }

  void applySafeDefault() override {
    setOutput(_config.safeDefault);
  }

  bool isOn() const { return _on; }

  void setOutput(bool on) {
    _on = on;
    if (_activeLow) {
      digitalWrite(_pin, _on ? LOW : HIGH);
    } else {
      digitalWrite(_pin, _on ? HIGH : LOW);
    }
  }

  void toggle() { setOutput(!_on); }

protected:
  uint8_t _pin;
  bool _activeLow;
  bool _on;
};

// PWM actuator — fan speed, LED brightness, servo angle, etc.
class PwmActuator : public NexlozaActuator {
public:
  PwmActuator(uint8_t pin, uint32_t freq = 5000, uint8_t resolution = 8)
    : _pin(pin), _freq(freq), _resolution(resolution), _duty(0) {}

  bool begin() override {
#if defined(ESP32)
    ledcAttach(_pin, _freq, _resolution);
#endif
    applySafeDefault();
    return true;
  }

  bool execute(JsonObject& command) override {
    _status = ActuatorStatus::EXECUTING;
    int value = command["value"] | 0;
    uint16_t maxDuty = (1 << _resolution) - 1;
    _duty = constrain(value, 0, maxDuty);
#if defined(ESP32)
    ledcWrite(_pin, _duty);
#elif defined(ESP8266)
    analogWrite(_pin, _duty);
#endif
    _status = ActuatorStatus::SUCCESS;
    return true;
  }

  void getState(JsonDocument& state) override {
    state["duty"] = _duty;
    state["on"] = _duty > 0;
  }

  void applySafeDefault() override {
    _duty = 0;
#if defined(ESP32)
    ledcWrite(_pin, 0);
#elif defined(ESP8266)
    analogWrite(_pin, 0);
#endif
  }

  void setDuty(uint16_t duty) {
    uint16_t maxDuty = (1 << _resolution) - 1;
    _duty = constrain(duty, (uint16_t)0, maxDuty);
#if defined(ESP32)
    ledcWrite(_pin, _duty);
#elif defined(ESP8266)
    analogWrite(_pin, _duty);
#endif
  }

  uint16_t duty() const { return _duty; }

protected:
  uint8_t _pin;
  uint32_t _freq;
  uint8_t _resolution;
  uint16_t _duty;
};

#endif
