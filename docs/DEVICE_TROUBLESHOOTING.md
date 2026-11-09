# Device Troubleshooting Guide

## Connection Issues

### Device Won't Come Online

**Symptoms**: Device appears in the app but shows "Offline" with no telemetry.

**Checklist**:
1. **Verify broker is running**: `docker ps | grep nanomq`
2. **Check device credentials**: Ensure `DEVICE_ID`, `DEVICE_KEY`, and `DEVICE_SECRET` match exactly what was generated during pairing
3. **Check network**: Device must reach the MQTT broker's host and port (default 1883)
4. **Check firmware**: Ensure the correct MQTT topic format is used:
   ```
   nexloza/v1/{org_id}/{project_id}/{device_id}/status
   ```
5. **Serial monitor**: Connect to the device's serial output to see connection error messages

### Intermittent Disconnections

**Symptoms**: Device alternates between online and offline.

**Possible causes**:
- **Wi-Fi signal**: Move device closer to access point or use an external antenna
- **Keep-alive timeout**: Default is 60 seconds; ensure firmware sends PINGREQ within this interval
- **Broker overload**: Check NanoMQ logs with `docker logs nanomq`
- **Power supply**: Unstable power causes ESP boards to brown-out and reset

### MQTT Badge Shows "Error"

The red MQTT badge in the app means the Flutter client itself couldn't connect to the broker.

**Check**:
- `MQTT_HOST` in `.env` is reachable from the phone/emulator
- Port 1883 is not blocked by firewall
- For Android emulator: use `10.0.2.2` instead of `localhost`
- For physical device: use the machine's LAN IP (e.g., `192.168.1.x`)

## Telemetry Issues

### No Sensor Readings

**Symptoms**: Device is online but sensor tiles show no data.

**Check**:
1. Sensor definitions exist for the device (Sensors tab > Manage Sensors)
2. Sensor `telemetry_key` matches the JSON field name in the MQTT payload
3. Device is publishing to the correct topic: `.../telemetry`
4. Payload is valid JSON:
   ```json
   {"temperature": 23.5, "humidity": 65.0}
   ```
5. Use an MQTT client (e.g., MQTTX) to subscribe to the device's telemetry topic and verify messages are arriving

### Stale Data Warning

The yellow "Data may be stale" card appears when a device is offline. The displayed readings are the last known values before disconnection.

## Command Issues

### Commands Stay "Pending"

**Symptoms**: You send a command but it never progresses past the pending state.

**Possible causes**:
- Device is offline and not receiving commands
- Device firmware doesn't subscribe to the `command` channel
- Device firmware doesn't publish to `command-ack`
- Command topic mismatch — verify the full topic path

### Commands Show "Failed"

The device received the command but reported a failure. Check:
- The command payload matches what the firmware expects
- The actuator's `command_key` matches the firmware's handler
- Physical constraints (e.g., trying to exceed motor limits)

## Pairing Wizard Issues

### Verification Timeout

If Step 6 (Verify Connection) times out after 120 seconds:
1. The device record is already created — don't re-run the wizard
2. Check serial monitor for connection errors
3. Verify credentials were copied correctly
4. Tap "Skip" and verify later from the device detail screen
5. Once the device connects, it will appear as online automatically

### Missing Credentials

If you closed the pairing wizard before copying the device secret:
- The secret cannot be retrieved — it's hashed server-side
- Delete the device from the app and re-run the pairing wizard
- New credentials will be generated

## NanoMQ Broker

### Starting the Broker

```bash
docker run -d --name nanomq \
  -p 1883:1883 \
  -p 8083:8083 \
  emqx/nanomq:0.22.6-slim
```

### Checking Broker Logs

```bash
docker logs -f nanomq
```

### Common Broker Issues

| Issue | Solution |
|-------|---------|
| Port already in use | Stop conflicting services: `docker stop nanomq` or check for other MQTT brokers |
| Container won't start | Check Docker daemon is running: `docker info` |
| Clients can't connect | Verify port mapping: `docker port nanomq` |

## Firmware Notes

Phase 4 firmware examples exist in the `firmware/` directory for all supported platforms. **Important**: These have not been compiled with PlatformIO or physically tested. They serve as reference implementations.

Before deploying firmware:
1. Install PlatformIO
2. Update `platformio.ini` with your board configuration
3. Set device credentials in the firmware config
4. Build and flash: `pio run -t upload`
