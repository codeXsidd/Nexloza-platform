# Simulation Profiles

## Overview

NEXLOZA provides 6 simulation profiles, each defining a set of sensors and actuators with realistic value ranges. Profiles are used when creating virtual devices to auto-provision sensor definitions, actuator definitions, and initial simulation parameters.

## Profile Summary

| Profile | Sensors | Actuators | Primary Use Case |
|---------|---------|-----------|------------------|
| Smart Home | 4 | 2 | Room environment monitoring and control |
| Agriculture | 4 | 1 | Crop monitoring with irrigation |
| Weather Station | 5 | 0 | Outdoor environmental sensing |
| Energy Monitoring | 5 | 0 | Power grid monitoring |
| Industrial Equipment | 4 | 2 | Motor and machine monitoring |
| Water Management | 4 | 2 | Tank and pipe monitoring |

---

## Smart Home

### Sensors

| Name | Type | Telemetry Key | Unit | Min | Max | Initial |
|------|------|---------------|------|-----|-----|---------|
| Temperature | temperature | temperature | C | 18 | 30 | 22 |
| Humidity | humidity | humidity | % | 30 | 80 | 55 |
| Light Level | light | light_level | lux | 0 | 1000 | 400 |
| Motion | motion | motion | — | 0 | 1 | 0 |

### Actuators

| Name | Type | Control | Command Key | Min | Max | Step | Initial |
|------|------|---------|-------------|-----|-----|------|---------|
| Fan Speed | fan | slider | fan_speed | 0 | 100 | 5 | 0 |
| Light Switch | light | toggle | light_switch | 0 | 1 | 1 | 0 |

---

## Agriculture

### Sensors

| Name | Type | Telemetry Key | Unit | Min | Max | Initial |
|------|------|---------------|------|-----|-----|---------|
| Soil Moisture | soil_moisture | soil_moisture | % | 0 | 100 | 65 |
| Air Temperature | temperature | air_temperature | C | 10 | 45 | 28 |
| Humidity | humidity | humidity | % | 20 | 95 | 60 |
| Light Intensity | light | light_intensity | lux | 0 | 120000 | 50000 |

### Actuators

| Name | Type | Control | Command Key | Min | Max | Step | Initial |
|------|------|---------|-------------|-----|-----|------|---------|
| Water Pump | pump | toggle | water_pump | 0 | 1 | 1 | 0 |

---

## Weather Station

### Sensors

| Name | Type | Telemetry Key | Unit | Min | Max | Initial |
|------|------|---------------|------|-----|-----|---------|
| Temperature | temperature | temperature | C | -20 | 50 | 22 |
| Humidity | humidity | humidity | % | 0 | 100 | 55 |
| Atmospheric Pressure | pressure | pressure | hPa | 950 | 1050 | 1013 |
| Wind Speed | custom | wind_speed | km/h | 0 | 120 | 10 |
| Rainfall | custom | rainfall | mm | 0 | 50 | 0 |

### Actuators

None.

---

## Energy Monitoring

### Sensors

| Name | Type | Telemetry Key | Unit | Min | Max | Initial |
|------|------|---------------|------|-----|-----|---------|
| Voltage | voltage | voltage | V | 200 | 250 | 230 |
| Current | current | current | A | 0 | 30 | 5 |
| Power | energy | power | W | 0 | 7500 | 1150 |
| Energy Consumption | energy | energy | kWh | 0 | 999999 | 1250 |
| Power Factor | custom | power_factor | — | 0.5 | 1.0 | 0.92 |

### Actuators

None.

---

## Industrial Equipment

### Sensors

| Name | Type | Telemetry Key | Unit | Min | Max | Initial |
|------|------|---------------|------|-----|-----|---------|
| Motor Temperature | temperature | motor_temp | C | 20 | 120 | 45 |
| Vibration | vibration | vibration | mm/s | 0 | 25 | 2.5 |
| RPM | custom | rpm | RPM | 0 | 3600 | 1800 |
| Pressure | pressure | pressure | bar | 0 | 10 | 4 |

### Actuators

| Name | Type | Control | Command Key | Min | Max | Step | Initial |
|------|------|---------|-------------|-----|-----|------|---------|
| Motor Control | motor | toggle | motor_control | 0 | 1 | 1 | 0 |
| Motor Speed | motor | slider | motor_speed | 0 | 3600 | 100 | 0 |

---

## Water Management

### Sensors

| Name | Type | Telemetry Key | Unit | Min | Max | Initial |
|------|------|---------------|------|-----|-----|---------|
| Tank Level | water_level | tank_level | % | 0 | 100 | 75 |
| Flow Rate | flow_rate | flow_rate | L/min | 0 | 500 | 50 |
| Water Pressure | pressure | water_pressure | bar | 0 | 6 | 3 |
| Leak Detected | custom | leak_detected | — | 0 | 1 | 0 |

### Actuators

| Name | Type | Control | Command Key | Min | Max | Step | Initial |
|------|------|---------|-------------|-----|-----|------|---------|
| Pump Control | pump | toggle | pump_control | 0 | 1 | 1 | 0 |
| Valve Position | valve | slider | valve_position | 0 | 100 | 5 | 100 |

---

## Simulation Models

The `SimulatorEngine` applies different mathematical models depending on the sensor type:

| Model | Sensors | Behavior |
|-------|---------|----------|
| Gradual drift | temperature, humidity, pressure, wind_speed, rainfall | `current + (random - 0.5) * step`, clamped to bounds |
| Decay/recovery | soil_moisture | Decreases at -0.1/tick; increases +2.0 when water_pump is active |
| Binary event | motion, leak_detected | Random probability per tick (5% for motion, 1% for leak) |
| Correlated | vibration | Derived from RPM: `(rpm / 3600) * 5.0 + noise` |
| Step response | rpm | Ramps toward motor_speed target when motor is on; decays when off |
| Inflow/outflow | tank_level | Inflow 0.2/tick; outflow based on pump state and valve position |
| Fluctuation | voltage | Small random variation around 230V |
| Accumulation | energy | Monotonically increasing by small random increments |
| Actuator-linked | light_level | Responds to light_switch state |
| Fan cooling | temperature | Fan speed reduces temperature drift |
| Default | any unmatched | Random walk within 2% of range |

### Fault Injection Effects

| Fault | Effect on Sensor |
|-------|-----------------|
| sensorFailure | Sensor stops updating; retains last value |
| outOfRange | Generates values 20% above max bound |
| deviceOffline | All sensors stop updating |

## Deterministic Testing

Pass an integer `seed` to `SimulatorEngine.startSimulation()` to get reproducible value sequences. The engine creates a `Random(seed)` per device, making tests independent of execution timing.

## Adding a New Profile

1. Add a value to `SimulationProfileType` enum.
2. Define the `SimulationProfile` with sensors and actuators in `SimulationProfiles`.
3. Add the case to `SimulationProfiles.forType()`.
4. Add simulation model logic in `SimulatorEngine._computeValue()` if the new sensor keys require custom behavior.
