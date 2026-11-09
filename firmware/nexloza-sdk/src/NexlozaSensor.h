#ifndef NEXLOZA_SENSOR_H
#define NEXLOZA_SENSOR_H

#include <Arduino.h>
#include <ArduinoJson.h>

struct SensorConfig {
  const char* id;
  const char* name;
  const char* type;
  const char* unit;
  float minValue;
  float maxValue;
  float precision;
  uint32_t readIntervalMs;
};

enum class SensorStatus : uint8_t {
  OK,
  READ_ERROR,
  NOT_AVAILABLE,
  CALIBRATING,
  OUT_OF_RANGE
};

class NexlozaSensor {
public:
  NexlozaSensor() : _lastRead(0), _status(SensorStatus::NOT_AVAILABLE) {}
  virtual ~NexlozaSensor() {}

  void configure(const SensorConfig& cfg) {
    _config = cfg;
    if (_config.readIntervalMs == 0) _config.readIntervalMs = 10000;
  }

  const SensorConfig& config() const { return _config; }
  const char* id() const { return _config.id; }
  const char* name() const { return _config.name; }
  SensorStatus status() const { return _status; }
  float lastValue() const { return _lastValue; }

  virtual bool begin() { return true; }

  virtual float read() = 0;

  virtual bool isAvailable() { return _status != SensorStatus::NOT_AVAILABLE; }

  bool shouldRead() {
    return (millis() - _lastRead) >= _config.readIntervalMs;
  }

  float readIfDue() {
    if (!shouldRead()) return _lastValue;
    return performRead();
  }

  float performRead() {
    float val = read();
    _lastRead = millis();
    if (isnan(val)) {
      _status = SensorStatus::READ_ERROR;
      return NAN;
    }
    if (val < _config.minValue || val > _config.maxValue) {
      _status = SensorStatus::OUT_OF_RANGE;
    } else {
      _status = SensorStatus::OK;
    }
    _lastValue = val;
    return val;
  }

  void fillTelemetry(JsonDocument& doc) {
    doc["sensor_id"] = _config.id;
    doc["value"] = _lastValue;
    doc["unit"] = _config.unit;
    doc["status"] = statusString();
  }

  const char* statusString() const {
    switch (_status) {
      case SensorStatus::OK:            return "ok";
      case SensorStatus::READ_ERROR:    return "read_error";
      case SensorStatus::NOT_AVAILABLE: return "not_available";
      case SensorStatus::CALIBRATING:   return "calibrating";
      case SensorStatus::OUT_OF_RANGE:  return "out_of_range";
      default:                          return "unknown";
    }
  }

protected:
  SensorConfig _config;
  unsigned long _lastRead;
  float _lastValue = NAN;
  SensorStatus _status;
};

// Analog sensor — reads from an ADC pin, converts to engineering units
class AnalogSensor : public NexlozaSensor {
public:
  AnalogSensor(uint8_t pin, float scale = 1.0f, float offset = 0.0f)
    : _pin(pin), _scale(scale), _offset(offset) {}

  bool begin() override {
    pinMode(_pin, INPUT);
    _status = SensorStatus::OK;
    return true;
  }

  float read() override {
    int raw = analogRead(_pin);
    return (float)raw * _scale + _offset;
  }

  bool isAvailable() override { return true; }

  void setCalibration(float scale, float offset) {
    _scale = scale;
    _offset = offset;
  }

protected:
  uint8_t _pin;
  float _scale;
  float _offset;
};

// Digital sensor — reads a digital pin (e.g., PIR, button, reed switch)
class DigitalSensor : public NexlozaSensor {
public:
  DigitalSensor(uint8_t pin, bool activeLow = false)
    : _pin(pin), _activeLow(activeLow) {}

  bool begin() override {
    pinMode(_pin, INPUT);
    _status = SensorStatus::OK;
    return true;
  }

  float read() override {
    bool raw = digitalRead(_pin);
    if (_activeLow) raw = !raw;
    return raw ? 1.0f : 0.0f;
  }

  bool isAvailable() override { return true; }

protected:
  uint8_t _pin;
  bool _activeLow;
};

#endif
