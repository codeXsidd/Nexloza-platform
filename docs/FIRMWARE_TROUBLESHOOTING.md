# Firmware Troubleshooting

## WiFi Issues

### WiFi won't connect

- Verify SSID and password are correct (case-sensitive)
- ESP32/ESP8266 only supports **2.4 GHz** WiFi — 5 GHz networks are invisible
- Move closer to the router during initial testing
- Check if your router blocks new devices (MAC filtering)
- Try a mobile hotspot to rule out router issues

### WiFi disconnects frequently

- Add a 100µF capacitor near the ESP power pins
- Avoid running WiFi near relay switching (electrical noise)
- Check `WiFi.RSSI()` — below -80 dBm is unreliable
- ESP8266 is less stable than ESP32 on congested networks

## MQTT Issues

### Authentication fails

- Verify API key and secret match the device credentials in Nexloza
- Check that the device is registered and active in your project
- Verify the server host URL is correct (includes protocol for auth endpoint)
- Check Serial Monitor for HTTP status codes:
  - 401: Invalid credentials
  - 404: Wrong server URL
  - 500: Backend error

### No telemetry appears in dashboard

- Verify MQTT is connected (check Serial Monitor for "MQTT connected")
- Verify organization_id and project_id are correct
- Check that topic format matches: `nexloza/v1/{org}/{project}/{device}/telemetry`
- Ensure `nexloza.loop()` is being called in your main loop

### Commands not received

- Verify the device subscribes to the command topic (happens automatically on connect)
- Check that `onCommand()` callback is registered before `connect()`
- Verify command is sent to the correct device_id

## Sensor Issues

### Sensor reads NaN

- Check wiring — loose connections cause intermittent failures
- DHT22: Wait at least 2 seconds between reads
- DHT22: Verify 10kΩ pull-up resistor on data line
- Analog sensors: Verify the pin is ADC-capable (ESP32: GPIO 32-39 for ADC1)

### Analog readings are wrong

- ESP32 ADC: 12-bit (0-4095), non-linear at extremes
- ESP8266 ADC: 10-bit (0-1023), only A0, 0-1V range
- Calibrate with known reference values
- Average multiple samples for stability

## Actuator Issues

### Relay won't switch

- Verify relay module is 3.3V-compatible (many are 5V)
- Check if relay needs active-LOW signal
- Measure GPIO output with multimeter — should be 3.3V HIGH
- ESP8266 GPIO can only source ~12mA — use relay modules with built-in drivers
- Power relay module from external 5V, not from ESP

### Relay clicks but load doesn't work

- Check COM/NO/NC connections on the relay module
- Verify external power supply for the load
- Test with a simple LED + resistor before connecting real loads

## Upload Issues

### Upload fails / timeout

- **ESP32**: Hold the BOOT button while uploading, release after "Connecting..."
- **ESP8266**: Disconnect sensors from GPIO 0, 2, 15 during upload
- Try a different USB cable (data cables, not charge-only)
- Try a different USB port
- Reduce upload speed in platformio.ini: `upload_speed = 115200`

### Serial Monitor shows gibberish

- Set baud rate to **115200** (must match `Serial.begin(115200)`)
- Try resetting the board with the RST button
- Disconnect and reconnect USB

## Memory Issues

### ESP crashes or restarts

- Check free heap with `ESP.getFreeHeap()` — below 10KB is dangerous
- Reduce JSON buffer sizes
- Avoid `String` concatenation in tight loops (causes fragmentation)
- ESP8266: Keep total dynamic memory under ~40KB

### "Out of memory" or stack overflow

- Reduce `PubSubClient` buffer: `_mqttClient.setBufferSize(512)` instead of 1024
- Avoid large local arrays in functions
- Use static or global buffers for serialization

## Error Codes

| Code | Name | Meaning |
|------|------|---------|
| 100 | ERR_WIFI_DISCONNECTED | WiFi connection lost |
| 200 | ERR_MQTT_CONNECT_FAILED | MQTT broker unreachable or rejected |
| 201 | ERR_MQTT_PUBLISH_FAILED | Message publish failed |
| 300 | ERR_AUTH_FAILED | Device authentication rejected |
| 301 | ERR_AUTH_HTTP_ERROR | HTTP error during authentication |
| 400 | ERR_COMMAND_EXPIRED | Received command past expiry time |
| 401 | ERR_COMMAND_INVALID | Command payload could not be parsed |
| 500 | ERR_SENSOR_READ | Sensor returned NaN or error |
| 501 | ERR_ACTUATOR_EXECUTE | Actuator execution failed |
| 600 | ERR_JSON_PARSE | JSON deserialization failed |
| 601 | ERR_BUFFER_OVERFLOW | Serialized payload exceeded buffer |

Register an error callback to handle these:

```cpp
void handleError(int code, const char* message) {
  Serial.printf("Error %d: %s\n", code, message);
}

nexloza.onError(handleError);
```
