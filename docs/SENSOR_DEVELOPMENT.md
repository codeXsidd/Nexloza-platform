# Sensor Development Guide

## Sensor Framework

The SDK provides a `NexlozaSensor` base class that handles read scheduling, telemetry formatting, and status tracking. You implement the `read()` method for your specific hardware.

## Built-in Sensor Types

### AnalogSensor

Reads an ADC pin and applies a linear calibration (scale + offset).

```cpp
#include <NexlozaSensor.h>

AnalogSensor moisture(34, 100.0 / 4095.0, 0.0);  // pin, scale, offset

SensorConfig cfg;
cfg.id = "soil_moisture";
cfg.name = "Soil Moisture";
cfg.type = "soil_moisture";
cfg.unit = "percent";
cfg.minValue = 0;
cfg.maxValue = 100;
cfg.precision = 0.1;
cfg.readIntervalMs = 60000;  // every 60 seconds

moisture.configure(cfg);
nexloza.addSensor(&moisture);
```

### DigitalSensor

Reads a digital pin. Returns 1.0 (active) or 0.0 (inactive).

```cpp
DigitalSensor pir(14, false);  // pin, activeLow

SensorConfig cfg;
cfg.id = "motion";
cfg.name = "PIR Motion";
cfg.type = "pir";
cfg.unit = "boolean";
cfg.minValue = 0;
cfg.maxValue = 1;
cfg.readIntervalMs = 1000;

pir.configure(cfg);
nexloza.addSensor(&pir);
```

## Creating a Custom Sensor

Subclass `NexlozaSensor` and implement `read()`:

```cpp
#include <NexlozaSensor.h>
#include <DHT.h>

class DHTTemperatureSensor : public NexlozaSensor {
public:
  DHTTemperatureSensor(uint8_t pin, uint8_t type)
    : _dht(pin, type) {}

  bool begin() override {
    _dht.begin();
    _status = SensorStatus::OK;
    return true;
  }

  float read() override {
    float temp = _dht.readTemperature();
    if (isnan(temp)) return NAN;  // signals read error
    return temp;
  }

  bool isAvailable() override { return true; }

private:
  DHT _dht;
};
```

Usage:

```cpp
DHTTemperatureSensor tempSensor(4, DHT22);

SensorConfig cfg;
cfg.id = "temperature";
cfg.name = "Room Temperature";
cfg.type = "temperature";
cfg.unit = "celsius";
cfg.minValue = -40;
cfg.maxValue = 80;
cfg.precision = 0.1;
cfg.readIntervalMs = 30000;

tempSensor.configure(cfg);
nexloza.addSensor(&tempSensor);
```

The SDK will automatically:
1. Call `read()` at the configured interval
2. Publish telemetry if the value is valid
3. Track sensor status (OK, READ_ERROR, OUT_OF_RANGE)
4. Emit an error callback on read failures

## SensorConfig Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | `const char*` | Unique sensor identifier (used in telemetry) |
| `name` | `const char*` | Human-readable name |
| `type` | `const char*` | Sensor type (temperature, humidity, etc.) |
| `unit` | `const char*` | Measurement unit (celsius, percent, cm, etc.) |
| `minValue` | `float` | Expected minimum (values outside trigger OUT_OF_RANGE) |
| `maxValue` | `float` | Expected maximum |
| `precision` | `float` | Measurement precision |
| `readIntervalMs` | `uint32_t` | Milliseconds between reads (default: 10000) |

## Sensor Status

| Status | Meaning |
|--------|---------|
| OK | Last read succeeded and was in range |
| READ_ERROR | `read()` returned NAN |
| NOT_AVAILABLE | Sensor not initialized |
| CALIBRATING | Sensor is calibrating (set manually) |
| OUT_OF_RANGE | Value outside min/max bounds |

## Manual Reads

If you need to read outside the auto-publish schedule:

```cpp
float val = tempSensor.performRead();  // reads immediately
float last = tempSensor.lastValue();   // last successful value
```

## Maximum Sensors

The SDK supports up to 16 sensors per device (`NEXLOZA_MAX_SENSORS`).
