# Actuator Development Guide

## Actuator Framework

The SDK provides a `NexlozaActuator` base class that handles command routing, state reporting, safe defaults, and acknowledgements. You implement `execute()` and `getState()` for your hardware.

## Built-in Actuator Types

### DigitalActuator

Controls a digital output pin (relay, LED, buzzer).

```cpp
#include <NexlozaActuator.h>

DigitalActuator relay(26, false);  // pin, activeLow

ActuatorConfig cfg;
cfg.id = "relay_1";
cfg.name = "Main Relay";
cfg.type = "relay";
cfg.safeDefault = false;       // OFF on boot
cfg.commandTimeoutMs = 5000;

relay.configure(cfg);
nexloza.addActuator(&relay);
```

Commands are automatically routed when the MQTT command payload includes `"actuator_id": "relay_1"`.

### PwmActuator

Controls a PWM output (fan speed, LED brightness, servo).

```cpp
PwmActuator fan(25, 25000, 8);  // pin, frequency, resolution

ActuatorConfig cfg;
cfg.id = "fan";
cfg.name = "Cooling Fan";
cfg.type = "fan";
cfg.safeDefault = false;
cfg.commandTimeoutMs = 5000;

fan.configure(cfg);
nexloza.addActuator(&fan);
```

## Creating a Custom Actuator

Subclass `NexlozaActuator` and implement `execute()`, `getState()`, and optionally `applySafeDefault()`:

```cpp
class ServoActuator : public NexlozaActuator {
public:
  ServoActuator(uint8_t pin) : _pin(pin), _angle(90) {}

  bool begin() override {
    // Initialize servo library
    _servo.attach(_pin);
    applySafeDefault();
    return true;
  }

  bool execute(JsonObject& command) override {
    _status = ActuatorStatus::EXECUTING;
    int angle = command["value"] | 90;
    _angle = constrain(angle, 0, 180);
    _servo.write(_angle);
    _status = ActuatorStatus::SUCCESS;
    return true;
  }

  void getState(JsonDocument& state) override {
    state["angle"] = _angle;
  }

  void applySafeDefault() override {
    _angle = 90;  // center position
    _servo.write(_angle);
  }

private:
  uint8_t _pin;
  int _angle;
  Servo _servo;
};
```

## How Command Routing Works

When the SDK receives a command on the MQTT command topic:

1. It checks if the command has expired (`expires_at` field)
2. It looks for an `actuator_id` in the payload
3. If found, it calls `execute()` on the matching actuator
4. It sends a command acknowledgement (success/failed)
5. It publishes the actual state after execution

If no actuator matches, the command falls through to the user's `onCommand()` callback.

## ActuatorConfig Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | `const char*` | Unique actuator identifier |
| `name` | `const char*` | Human-readable name |
| `type` | `const char*` | Actuator type (relay, led, fan, servo, etc.) |
| `safeDefault` | `bool` | Default state on boot (false = OFF) |
| `commandTimeoutMs` | `uint32_t` | Command execution timeout (default: 5000) |

## Safe Defaults

Every actuator's `applySafeDefault()` runs on `begin()`. This ensures:

- Relays start OFF (prevents unexpected activation after restart)
- PWM outputs start at 0 (fan/motor off)
- Servos return to center position

Override `applySafeDefault()` to customize the boot behavior.

## State Reporting

After every command execution, the SDK automatically:
1. Calls `getState()` on the actuator
2. Publishes the state to the MQTT `state` topic (retained)

This ensures the dashboard always reflects the **actual** hardware state, not just the commanded state.

## Manual Control

You can control actuators directly in your code:

```cpp
// DigitalActuator
relay.setOutput(true);   // turn on
relay.toggle();           // flip state
bool isOn = relay.isOn();

// PwmActuator
fan.setDuty(128);        // set duty cycle
uint16_t d = fan.duty(); // current duty
```

## Maximum Actuators

The SDK supports up to 16 actuators per device (`NEXLOZA_MAX_ACTUATORS`).

## Safety Warning

**Relay and actuator examples use low-voltage DC loads (3.3V–12V) for testing.**

Household AC mains wiring (110V/220V) must be installed by a qualified electrician with proper enclosures, fuses, and RCD/GFCI protection. Never work with exposed mains voltage.
