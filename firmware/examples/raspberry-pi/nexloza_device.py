#!/usr/bin/env python3
"""Nexloza Raspberry Pi Device Client

A complete Raspberry Pi example using MQTT for telemetry, commands, and state.
Uses paho-mqtt and psutil for system metrics. GPIO support via RPi.GPIO (optional).

Install:
    pip install paho-mqtt psutil requests
    pip install RPi.GPIO  # only on real Raspberry Pi hardware

Usage:
    export NEXLOZA_SERVER="mqtt.nexloza.com"
    export NEXLOZA_DEVICE_ID="rpi-001"
    export NEXLOZA_API_KEY="YOUR_API_KEY"
    export NEXLOZA_API_SECRET="YOUR_API_SECRET"
    export NEXLOZA_ORG_ID="YOUR_ORG_ID"
    export NEXLOZA_PROJECT_ID="YOUR_PROJECT_ID"
    export NEXLOZA_AUTH_URL="https://your-project.supabase.co/functions/v1/device-auth"
    python nexloza_device.py
"""

import json
import os
import signal
import sys
import time
from datetime import datetime, timezone

import paho.mqtt.client as mqtt
import psutil
import requests

try:
    import RPi.GPIO as GPIO
    GPIO_AVAILABLE = True
except ImportError:
    GPIO_AVAILABLE = False

# --- Configuration from environment ---

SERVER = os.environ.get("NEXLOZA_SERVER", "mqtt.nexloza.com")
MQTT_PORT = int(os.environ.get("NEXLOZA_MQTT_PORT", "1883"))
DEVICE_ID = os.environ["NEXLOZA_DEVICE_ID"]
API_KEY = os.environ["NEXLOZA_API_KEY"]
API_SECRET = os.environ["NEXLOZA_API_SECRET"]
ORG_ID = os.environ.get("NEXLOZA_ORG_ID", "default")
PROJECT_ID = os.environ["NEXLOZA_PROJECT_ID"]
AUTH_URL = os.environ["NEXLOZA_AUTH_URL"]

TELEMETRY_INTERVAL = int(os.environ.get("NEXLOZA_TELEMETRY_INTERVAL", "15"))

# Optional GPIO pins
LED_PIN = int(os.environ.get("LED_PIN", "17"))
RELAY_PIN = int(os.environ.get("RELAY_PIN", "27"))

# --- MQTT Topics (canonical v1 format) ---

TOPIC_BASE = f"nexloza/v1/{ORG_ID}/{PROJECT_ID}/{DEVICE_ID}"
TOPIC_TELEMETRY = f"{TOPIC_BASE}/telemetry"
TOPIC_COMMAND = f"{TOPIC_BASE}/command"
TOPIC_COMMAND_ACK = f"{TOPIC_BASE}/command-ack"
TOPIC_STATE = f"{TOPIC_BASE}/state"
TOPIC_STATUS = f"{TOPIC_BASE}/status"
TOPIC_CONFIG = f"{TOPIC_BASE}/config"

# --- State ---

relay_state = False
led_state = False
running = True


def authenticate():
    """Authenticate with the Nexloza backend to validate credentials."""
    resp = requests.post(
        AUTH_URL,
        headers={"x-api-key": API_KEY, "x-api-secret": API_SECRET},
        json={},
        timeout=10,
    )
    if resp.status_code != 200:
        raise RuntimeError(f"Authentication failed: {resp.status_code} {resp.text}")
    print("[AUTH] Authenticated successfully")
    return resp.json()


def read_system_telemetry():
    """Read system metrics using psutil."""
    cpu_temp = None
    try:
        temps = psutil.sensors_temperatures()
        if "cpu_thermal" in temps:
            cpu_temp = temps["cpu_thermal"][0].current
    except Exception:
        pass

    return {
        "version": 1,
        "device_id": DEVICE_ID,
        "cpu_percent": psutil.cpu_percent(interval=0.5),
        "memory_percent": psutil.virtual_memory().percent,
        "disk_percent": psutil.disk_usage("/").percent,
        "cpu_temp": cpu_temp,
        "uptime_s": int(time.time() - psutil.boot_time()),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


def build_state():
    return {
        "version": 1,
        "device_id": DEVICE_ID,
        "relay": relay_state,
        "led": led_state,
        "uptime_s": int(time.time() - psutil.boot_time()),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


def on_connect(client, userdata, flags, rc, properties=None):
    if rc == 0:
        print(f"[MQTT] Connected to {SERVER}:{MQTT_PORT}")
        client.subscribe(TOPIC_COMMAND)
        client.subscribe(TOPIC_CONFIG)
        client.publish(
            TOPIC_STATUS,
            json.dumps({
                "version": 1,
                "device_id": DEVICE_ID,
                "status": "online",
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }),
            retain=True,
        )
    else:
        print(f"[MQTT] Connection failed: rc={rc}")


def on_message(client, userdata, msg):
    global relay_state, led_state

    command_id = None
    try:
        payload = json.loads(msg.payload.decode())
        command_id = payload.get("command_id")
        command_type = payload.get("command_type", "")
        cmd_payload = payload.get("payload", {})

        print(f"[CMD] Received: {command_type} (id={command_id})")

        success = True
        message = "OK"

        if command_type == "relay":
            relay_state = bool(cmd_payload.get("value", False))
            if GPIO_AVAILABLE:
                GPIO.output(RELAY_PIN, GPIO.HIGH if relay_state else GPIO.LOW)
            print(f"[CMD] Relay -> {'ON' if relay_state else 'OFF'}")

        elif command_type == "led":
            led_state = bool(cmd_payload.get("value", False))
            if GPIO_AVAILABLE:
                GPIO.output(LED_PIN, GPIO.HIGH if led_state else GPIO.LOW)
            print(f"[CMD] LED -> {'ON' if led_state else 'OFF'}")

        elif command_type == "get_reading":
            telemetry = read_system_telemetry()
            client.publish(TOPIC_TELEMETRY, json.dumps(telemetry))
            print("[CMD] Published on-demand telemetry")

        elif command_type == "restart":
            print("[CMD] Restart requested")
            if command_id:
                ack = {
                    "version": 1,
                    "command_id": command_id,
                    "status": "success",
                    "message": "Restarting...",
                }
                client.publish(TOPIC_COMMAND_ACK, json.dumps(ack))
            time.sleep(0.5)
            os.execv(sys.executable, [sys.executable] + sys.argv)

        else:
            success = False
            message = f"Unknown command: {command_type}"
            print(f"[CMD] Unknown: {command_type}")

        if command_id:
            ack = {
                "version": 1,
                "command_id": command_id,
                "status": "success" if success else "failed",
                "message": message,
            }
            client.publish(TOPIC_COMMAND_ACK, json.dumps(ack))

        client.publish(TOPIC_STATE, json.dumps(build_state()), retain=True)

    except Exception as e:
        print(f"[CMD] Error handling command: {e}")
        if command_id:
            ack = {
                "version": 1,
                "command_id": command_id,
                "status": "failed",
                "message": str(e),
            }
            client.publish(TOPIC_COMMAND_ACK, json.dumps(ack))


def setup_gpio():
    if not GPIO_AVAILABLE:
        print("[GPIO] RPi.GPIO not available, GPIO commands will be no-ops")
        return
    GPIO.setmode(GPIO.BCM)
    GPIO.setwarnings(False)
    GPIO.setup(LED_PIN, GPIO.OUT, initial=GPIO.LOW)
    GPIO.setup(RELAY_PIN, GPIO.OUT, initial=GPIO.LOW)
    print(f"[GPIO] LED={LED_PIN} RELAY={RELAY_PIN}")


def cleanup(signum=None, frame=None):
    global running
    running = False
    print("\n[MAIN] Shutting down...")
    if GPIO_AVAILABLE:
        GPIO.cleanup()


def main():
    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)

    print("=== Nexloza Raspberry Pi Device ===")
    print(f"Device: {DEVICE_ID} | Org: {ORG_ID} | Project: {PROJECT_ID}")

    auth_data = authenticate()
    mqtt_username = auth_data.get("mqtt", {}).get("username", DEVICE_ID)
    setup_gpio()

    client = mqtt.Client(
        client_id=f"nexloza_rpi_{DEVICE_ID}",
        callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
    )
    client.username_pw_set(mqtt_username, API_SECRET)
    client.will_set(
        TOPIC_STATUS,
        json.dumps({
            "version": 1,
            "device_id": DEVICE_ID,
            "status": "offline",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }),
        retain=True,
    )
    client.on_connect = on_connect
    client.on_message = on_message

    print(f"[MQTT] Connecting to {SERVER}:{MQTT_PORT}...")
    client.connect(SERVER, MQTT_PORT, keepalive=60)
    client.loop_start()

    last_telemetry = 0
    last_heartbeat = 0

    try:
        while running:
            now = time.time()

            if now - last_telemetry >= TELEMETRY_INTERVAL:
                telemetry = read_system_telemetry()
                client.publish(TOPIC_TELEMETRY, json.dumps(telemetry))
                print(f"[Telemetry] CPU={telemetry['cpu_percent']}% "
                      f"Mem={telemetry['memory_percent']}% "
                      f"Temp={telemetry.get('cpu_temp', 'N/A')}")
                last_telemetry = now

            if now - last_heartbeat >= 30:
                client.publish(TOPIC_STATUS, json.dumps({
                    "version": 1,
                    "device_id": DEVICE_ID,
                    "status": "online",
                    "uptime_s": int(now - psutil.boot_time()),
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                }), retain=True)
                last_heartbeat = now

            time.sleep(1)

    finally:
        client.publish(
            TOPIC_STATUS,
            json.dumps({
                "version": 1,
                "device_id": DEVICE_ID,
                "status": "offline",
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }),
            retain=True,
        )
        client.loop_stop()
        client.disconnect()
        if GPIO_AVAILABLE:
            GPIO.cleanup()
        print("[MAIN] Disconnected")


if __name__ == "__main__":
    main()
