# Wiring Diagrams

Pin connections and wiring notes for all Nexloza firmware examples.

> **SAFETY WARNING**: All examples use low-voltage DC loads (LEDs, small DC motors, buzzers).
> **Never connect relay modules directly to AC mains (110V/220V) without proper enclosure,
> fusing, and installation by a qualified electrician.**

---

## ESP32 Relay + Fan (`esp32-relay-fan`)

```
ESP32           Relay Module        Fan (DC, 5-12V)
──────          ────────────        ────────────────
GPIO 26  ────►  IN                  
3.3V     ────►  VCC                 
GND      ────►  GND                 
                COM  ────►          + (via relay NO)
                                    - ──── GND (power supply)

ESP32           Fan PWM (optional, for speed control on a DC fan)
──────          ──────────
GPIO 25  ────►  MOSFET gate (with pull-down resistor)
```

**Notes:**
- Relay module: use a 3.3V-compatible module or a level shifter
- PWM speed control requires a logic-level N-channel MOSFET (e.g., IRLZ44N)
- Power the fan from an external supply, not from the ESP32

---

## ESP32 Relay + Light (`esp32-relay-light`)

```
ESP32           Relay Module        Light (DC LED strip or bulb)
──────          ────────────        ─────────────────────────────
GPIO 27  ────►  IN
3.3V     ────►  VCC
GND      ────►  GND
                COM  ────►          + (via relay NO)
                                    - ──── GND (power supply)
```

---

## ESP32 DHT22 (`esp32-dht22`)

```
ESP32           DHT22
──────          ─────
GPIO 4   ────►  DATA (pin 2)
3.3V     ────►  VCC  (pin 1)
GND      ────►  GND  (pin 4)

            3.3V
             │
            [10kΩ]  ◄── Pull-up resistor
             │
GPIO 4 ──────┤
             │
          DHT22 DATA
```

**Notes:**
- A 10kΩ pull-up resistor between DATA and VCC is recommended
- Pin 3 of DHT22 is not connected (NC)
- Minimum 2-second interval between reads

---

## ESP32 Soil Moisture (`esp32-soil-moisture`)

```
ESP32           Capacitive Soil Moisture Sensor v1.2
──────          ──────────────────────────────────────
GPIO 34  ────►  AOUT (analog output)
3.3V     ────►  VCC
GND      ────►  GND
```

**Notes:**
- GPIO 34 is input-only on ESP32 (ADC1_CH6), suitable for analog reads
- Calibration values in code: dry air ≈ 4095, fully submerged ≈ 1200
- Adjust `CAL_DRY` and `CAL_WET` constants for your specific sensor
- Capacitive sensors are preferred over resistive (no corrosion)

---

## ESP32 PIR Motion (`esp32-pir-motion`)

```
ESP32           HC-SR501 PIR Sensor
──────          ───────────────────
GPIO 14  ────►  OUT
5V (Vin) ────►  VCC  (requires 5-20V)
GND      ────►  GND
```

**Notes:**
- HC-SR501 requires 5V power — use the ESP32 VIN pin (USB 5V passthrough)
- Output is 3.3V compatible, safe for ESP32 GPIO
- Adjust sensitivity and delay potentiometers on the module
- Allow 30 seconds for the PIR sensor to stabilize after power-on
- The code includes interrupt-based detection with debounce and cooldown

---

## ESP32 Multi-Sensor (`esp32-multi-sensor`)

```
ESP32           DHT22           BMP280 (I2C)         LDR + Resistor
──────          ─────           ────────────          ──────────────
GPIO 4   ────►  DATA            
GPIO 21  ────────────────────►  SDA
GPIO 22  ────────────────────►  SCL
GPIO 34  ──────────────────────────────────────────►  Voltage divider
3.3V     ────►  VCC      ────►  VCC
GND      ────►  GND      ────►  GND          ────►  GND

            3.3V                                3.3V
             │                                   │
            [10kΩ]  (DHT22 pull-up)             [LDR]
             │                                   │
          DHT22 DATA                      GPIO 34 ──── junction
                                                 │
                                                [10kΩ]
                                                 │
                                                GND
```

**Notes:**
- BMP280: Check I2C address — try 0x76 first, then 0x77
- BMP280: Add 10kΩ pull-ups on SDA/SCL if not on breakout board
- LDR voltage divider: brighter light = higher analog reading
- All three sensors share 3.3V power from the ESP32

---

## ESP8266 Relay (`esp8266-relay`)

```
NodeMCU/ESP8266     Relay Module        Load (DC)
───────────────     ────────────        ─────────
D1 (GPIO 5)  ────►  IN
3.3V         ────►  VCC
GND          ────►  GND
                    COM  ────►          + (via relay NO)
                                        - ──── GND (power supply)
```

**Notes:**
- NodeMCU D1 = GPIO 5
- Use a 3.3V-compatible relay module (many modules are 5V — check yours)
- ESP8266 GPIO pins can only source ~12mA; use relay modules with built-in drivers

---

## General Tips

1. **Power**: Never power motors, relays, or actuators directly from ESP32/ESP8266 GPIO pins.
   Use external power supplies with appropriate voltage and current ratings.

2. **Decoupling**: Add a 100µF capacitor near the ESP32/ESP8266 power pins to reduce noise
   from relay switching.

3. **Flyback diodes**: If driving inductive loads (motors, solenoids) through MOSFETs,
   always use a flyback diode across the load.

4. **Ground**: Connect all grounds together (ESP32, relay module, power supply, sensors).

5. **Wire lengths**: Keep sensor wires under 3 meters for analog signals. Use shielded cable
   for longer runs.
