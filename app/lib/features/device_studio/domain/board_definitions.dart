class BoardDefinition {
  final String id;
  final String name;
  final String description;
  final List<GpioPin> gpioPins;
  final List<String> features;
  final String platformioBoard;
  final String includeHeader;

  const BoardDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.gpioPins,
    required this.features,
    required this.platformioBoard,
    required this.includeHeader,
  });
}

class GpioPin {
  final int number;
  final String label;
  final bool isAnalog;
  final bool isPwm;
  final bool isI2c;
  final bool isSpi;

  const GpioPin({
    required this.number,
    required this.label,
    this.isAnalog = false,
    this.isPwm = false,
    this.isI2c = false,
    this.isSpi = false,
  });
}

class SensorDefinition {
  final String id;
  final String name;
  final String type;
  final String library;
  final String description;
  final List<String> readings;
  final String exampleWiring;
  final String initCode;
  final String readCode;

  const SensorDefinition({
    required this.id,
    required this.name,
    required this.type,
    required this.library,
    required this.description,
    required this.readings,
    required this.exampleWiring,
    required this.initCode,
    required this.readCode,
  });
}

class ActuatorDefinition {
  final String id;
  final String name;
  final String type;
  final String description;
  final String exampleWiring;
  final String controlCode;

  const ActuatorDefinition({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.exampleWiring,
    required this.controlCode,
  });
}

abstract final class Boards {
  static const esp32 = BoardDefinition(
    id: 'esp32',
    name: 'ESP32 DevKit V1',
    description: 'Dual-core 240MHz, Wi-Fi + BLE, 34 GPIO pins',
    platformioBoard: 'esp32dev',
    includeHeader: '#include <WiFi.h>',
    features: ['Wi-Fi', 'Bluetooth', 'ADC', 'DAC', 'PWM', 'I2C', 'SPI'],
    gpioPins: [
      GpioPin(number: 2, label: 'D2 (LED)', isPwm: true),
      GpioPin(number: 4, label: 'D4', isPwm: true),
      GpioPin(number: 5, label: 'D5', isPwm: true, isSpi: true),
      GpioPin(number: 12, label: 'D12', isPwm: true),
      GpioPin(number: 13, label: 'D13', isPwm: true),
      GpioPin(number: 14, label: 'D14', isPwm: true),
      GpioPin(number: 15, label: 'D15', isPwm: true),
      GpioPin(number: 16, label: 'D16 (RX2)', isPwm: true),
      GpioPin(number: 17, label: 'D17 (TX2)', isPwm: true),
      GpioPin(number: 18, label: 'D18', isPwm: true, isSpi: true),
      GpioPin(number: 19, label: 'D19', isPwm: true, isSpi: true),
      GpioPin(number: 21, label: 'D21 (SDA)', isPwm: true, isI2c: true),
      GpioPin(number: 22, label: 'D22 (SCL)', isPwm: true, isI2c: true),
      GpioPin(number: 23, label: 'D23', isPwm: true, isSpi: true),
      GpioPin(number: 25, label: 'D25 (DAC1)', isPwm: true, isAnalog: true),
      GpioPin(number: 26, label: 'D26 (DAC2)', isPwm: true, isAnalog: true),
      GpioPin(number: 27, label: 'D27', isPwm: true),
      GpioPin(number: 32, label: 'D32', isPwm: true, isAnalog: true),
      GpioPin(number: 33, label: 'D33', isPwm: true, isAnalog: true),
      GpioPin(number: 34, label: 'D34 (input only)', isAnalog: true),
      GpioPin(number: 35, label: 'D35 (input only)', isAnalog: true),
    ],
  );

  static const esp32c3 = BoardDefinition(
    id: 'esp32c3',
    name: 'ESP32-C3',
    description: 'RISC-V single-core 160MHz, Wi-Fi + BLE 5',
    platformioBoard: 'esp32-c3-devkitm-1',
    includeHeader: '#include <WiFi.h>',
    features: ['Wi-Fi', 'BLE 5', 'ADC', 'PWM', 'I2C', 'SPI'],
    gpioPins: [
      GpioPin(number: 0, label: 'GPIO0', isAnalog: true, isPwm: true),
      GpioPin(number: 1, label: 'GPIO1', isAnalog: true, isPwm: true),
      GpioPin(number: 2, label: 'GPIO2', isAnalog: true, isPwm: true),
      GpioPin(number: 3, label: 'GPIO3', isAnalog: true, isPwm: true),
      GpioPin(number: 4, label: 'GPIO4', isPwm: true, isI2c: true),
      GpioPin(number: 5, label: 'GPIO5', isPwm: true, isI2c: true),
      GpioPin(number: 6, label: 'GPIO6', isPwm: true, isSpi: true),
      GpioPin(number: 7, label: 'GPIO7', isPwm: true, isSpi: true),
      GpioPin(number: 8, label: 'GPIO8 (LED)', isPwm: true),
      GpioPin(number: 9, label: 'GPIO9 (BOOT)', isPwm: true),
      GpioPin(number: 10, label: 'GPIO10', isPwm: true),
    ],
  );

  static const esp32s3 = BoardDefinition(
    id: 'esp32s3',
    name: 'ESP32-S3',
    description: 'Dual-core 240MHz, Wi-Fi + BLE 5, USB OTG',
    platformioBoard: 'esp32-s3-devkitc-1',
    includeHeader: '#include <WiFi.h>',
    features: ['Wi-Fi', 'BLE 5', 'USB OTG', 'ADC', 'PWM', 'I2C', 'SPI'],
    gpioPins: [
      GpioPin(number: 1, label: 'GPIO1', isAnalog: true, isPwm: true),
      GpioPin(number: 2, label: 'GPIO2', isAnalog: true, isPwm: true),
      GpioPin(number: 3, label: 'GPIO3', isPwm: true),
      GpioPin(number: 4, label: 'GPIO4', isPwm: true, isI2c: true),
      GpioPin(number: 5, label: 'GPIO5', isPwm: true, isI2c: true),
      GpioPin(number: 6, label: 'GPIO6', isPwm: true),
      GpioPin(number: 7, label: 'GPIO7', isPwm: true),
      GpioPin(number: 8, label: 'GPIO8', isPwm: true),
      GpioPin(number: 9, label: 'GPIO9', isPwm: true),
      GpioPin(number: 10, label: 'GPIO10', isPwm: true),
      GpioPin(number: 48, label: 'GPIO48 (LED)', isPwm: true),
    ],
  );

  static const esp8266 = BoardDefinition(
    id: 'esp8266',
    name: 'ESP8266 NodeMCU',
    description: 'Single-core 80MHz, Wi-Fi, 11 GPIO pins',
    platformioBoard: 'nodemcuv2',
    includeHeader: '#include <ESP8266WiFi.h>',
    features: ['Wi-Fi', 'ADC (1 ch)', 'PWM', 'I2C', 'SPI'],
    gpioPins: [
      GpioPin(number: 0, label: 'D3 (GPIO0)', isPwm: true),
      GpioPin(number: 2, label: 'D4 (GPIO2, LED)', isPwm: true),
      GpioPin(number: 4, label: 'D2 (GPIO4, SDA)', isPwm: true, isI2c: true),
      GpioPin(number: 5, label: 'D1 (GPIO5, SCL)', isPwm: true, isI2c: true),
      GpioPin(number: 12, label: 'D6 (GPIO12)', isPwm: true, isSpi: true),
      GpioPin(number: 13, label: 'D7 (GPIO13)', isPwm: true, isSpi: true),
      GpioPin(number: 14, label: 'D5 (GPIO14)', isPwm: true, isSpi: true),
      GpioPin(number: 15, label: 'D8 (GPIO15)', isPwm: true, isSpi: true),
      GpioPin(number: 16, label: 'D0 (GPIO16)', isPwm: false),
    ],
  );

  static const all = [esp32, esp32c3, esp32s3, esp8266];
}

abstract final class Sensors {
  static const dht22 = SensorDefinition(
    id: 'dht22',
    name: 'DHT22',
    type: 'Temperature & Humidity',
    library: 'DHT sensor library',
    description:
        'Digital temperature and humidity sensor. Range: -40-80°C, 0-100% RH',
    readings: ['temperature', 'humidity'],
    exampleWiring: 'VCC→3.3V, GND→GND, DATA→GPIO4 (10K pull-up to VCC)',
    initCode: 'DHT dht(DHT_PIN, DHT22);\nvoid setup() { dht.begin(); }',
    readCode:
        'float temp = dht.readTemperature();\nfloat hum = dht.readHumidity();',
  );

  static const bme280 = SensorDefinition(
    id: 'bme280',
    name: 'BME280',
    type: 'Temp/Humidity/Pressure',
    library: 'Adafruit BME280 Library',
    description: 'I2C sensor for temperature, humidity and barometric pressure',
    readings: ['temperature', 'humidity', 'pressure'],
    exampleWiring: 'VCC→3.3V, GND→GND, SDA→GPIO21, SCL→GPIO22',
    initCode: 'Adafruit_BME280 bme;\nvoid setup() { bme.begin(0x76); }',
    readCode: 'float temp = bme.readTemperature();\nfloat hum = bme.readHumidity();\nfloat pres = bme.readPressure() / 100.0;',
  );

  static const soilMoisture = SensorDefinition(
    id: 'soil_moisture',
    name: 'Capacitive Soil Moisture',
    type: 'Soil Moisture',
    library: 'Built-in analogRead',
    description: 'Analog soil moisture sensor. Output: 0-4095 (ESP32)',
    readings: ['soil_moisture'],
    exampleWiring: 'VCC→3.3V, GND→GND, AOUT→GPIO34',
    initCode: 'const int SOIL_PIN = 34;',
    readCode: 'int raw = analogRead(SOIL_PIN);\nfloat moisture = map(raw, 4095, 0, 0, 100);',
  );

  static const ultrasonic = SensorDefinition(
    id: 'hcsr04',
    name: 'HC-SR04',
    type: 'Distance/Water Level',
    library: 'NewPing',
    description: 'Ultrasonic distance sensor. Range: 2-400cm',
    readings: ['distance'],
    exampleWiring: 'VCC→5V, GND→GND, TRIG→GPIO12, ECHO→GPIO13',
    initCode: 'NewPing sonar(TRIG_PIN, ECHO_PIN, MAX_DISTANCE);',
    readCode: 'float distance = sonar.ping_cm();',
  );

  static const pir = SensorDefinition(
    id: 'pir',
    name: 'HC-SR501 PIR',
    type: 'Motion',
    library: 'Built-in digitalRead',
    description: 'Passive infrared motion sensor. Digital output.',
    readings: ['motion'],
    exampleWiring: 'VCC→5V, GND→GND, OUT→GPIO14',
    initCode:
        'const int PIR_PIN = 14;\nvoid setup() { pinMode(PIR_PIN, INPUT); }',
    readCode: 'bool motion = digitalRead(PIR_PIN);',
  );

  static const all = [dht22, bme280, soilMoisture, ultrasonic, pir];
}

abstract final class Actuators {
  static const relay = ActuatorDefinition(
    id: 'relay',
    name: 'Relay Module',
    type: 'Switch',
    description: 'Controls high-voltage devices (lights, pumps, motors)',
    exampleWiring: 'VCC→5V, GND→GND, IN→GPIO2',
    controlCode: 'digitalWrite(RELAY_PIN, state ? LOW : HIGH);',
  );

  static const led = ActuatorDefinition(
    id: 'led',
    name: 'LED',
    type: 'Light',
    description: 'Simple LED indicator or PWM-dimmable LED',
    exampleWiring: 'Anode→GPIO2 (with 220Ω resistor), Cathode→GND',
    controlCode: 'analogWrite(LED_PIN, brightness);',
  );

  static const servo = ActuatorDefinition(
    id: 'servo',
    name: 'Servo Motor',
    type: 'Motor',
    description: 'Positional servo motor (0-180°)',
    exampleWiring: 'VCC→5V, GND→GND, Signal→GPIO13',
    controlCode: 'myServo.write(angle);',
  );

  static const buzzer = ActuatorDefinition(
    id: 'buzzer',
    name: 'Buzzer',
    type: 'Audio',
    description: 'Piezo buzzer for audio alerts',
    exampleWiring: 'Positive→GPIO15 (with 100Ω resistor), Negative→GND',
    controlCode: 'tone(BUZZER_PIN, frequency, duration);',
  );

  static const all = [relay, led, servo, buzzer];
}
