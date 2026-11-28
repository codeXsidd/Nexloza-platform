"""Disposable, loopback-only MQTT bridge and integration checks."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import secrets
import subprocess
import threading
import time
from datetime import datetime, timezone
from urllib.error import HTTPError
from urllib.request import Request, urlopen
from uuid import uuid4

import paho.mqtt.client as mqtt

ROOT = Path(__file__).resolve().parents[2]
STATE = ROOT / ".nexloza-iot"
GATEWAY = "http://127.0.0.1:54321"
COMPOSE = ["docker", "compose", "-p", "nexloza-iot", "-f",
           str(ROOT / "scripts/iot/compose.yml")]
SESSION = STATE / "session.json"


def api(path, key, payload=None, token=None):
    headers = {"apikey": key, "Authorization": f"Bearer {token or key}"}
    data = None
    if payload is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(payload).encode()
    try:
        with urlopen(Request(GATEWAY + path, data, headers), timeout=10) as response:
            return json.loads(response.read() or b"null")
    except HTTPError as error:
        raise RuntimeError(f"{path.split('?')[0]} returned HTTP {error.code}") from None


def load():
    return json.loads(SESSION.read_text(encoding="utf-8"))


def write_broker(device):
    STATE.mkdir(mode=0o700, exist_ok=True)
    (STATE / "nanomq.conf").write_text(
        'listeners.tcp { bind = "0.0.0.0:1883" }\n'
        'auth {\n allow_anonymous = false\n no_match = deny\n deny_action = disconnect\n'
        ' password = {include "/run/nexloza/pw.conf"}\n'
        ' acl = {include "/run/nexloza/acl.conf"}\n}\n', encoding="utf-8")
    (STATE / "pw.conf").write_text(
        f'{json.dumps(device["key"])}: {json.dumps(device["secret"])}\n'
        f'"bridge": {json.dumps(device["bridge_secret"])}\n', encoding="utf-8")
    rules = [
        {"permit": "allow", "username": device["key"], "action": "publish",
         "topics": [device["topic"]]},
        {"permit": "allow", "username": "bridge", "action": "subscribe",
         "topics": [device["topic"]]},
    ]
    if "other_topic" in device:
        rules.extend([
            {"permit": "allow", "username": "bridge", "action": "subscribe",
             "topics": [device["other_topic"]]},
            {"permit": "allow", "username": "bridge", "action": "publish",
             "topics": [device["other_topic"]]},
        ])
    rules.append({"permit": "deny"})
    (STATE / "acl.conf").write_text("rules = " + json.dumps(rules), encoding="utf-8")


def broker_env():
    return {**os.environ, "NEXLOZA_BROKER_CONFIG": str(STATE)}


def provision(public_key):
    if SESSION.exists():
        print("Reusing existing disposable fixture")
        return
    suffix = uuid4().hex[:12]
    email = f"iot-{suffix}@example.com"
    password = secrets.token_urlsafe(24)
    owner = api("/auth/v1/signup", public_key, {"email": email, "password": password})
    token = owner["access_token"]
    user = owner["user"]["id"]
    org, project, device = [str(uuid4()) for _ in range(3)]
    key, secret = secrets.token_hex(16), secrets.token_hex(32)
    def insert(table, row):
        api(f"/rest/v1/{table}", public_key, row, token)

    insert("organizations", {"id": org, "name": "IoT Smoke", "slug": f"iot-{suffix}",
                             "created_by": user})
    insert("projects", {"id": project, "organization_id": org, "owner_id": user,
                        "name": "IoT Smoke", "category": "smart_home"})
    insert("devices", {"id": device, "project_id": project, "name": "IoT Temperature",
                       "device_type": "virtual_smart_home", "hardware_platform": "generic_mqtt",
                       "is_virtual": True, "simulation_profile": "smart_home"})
    insert("sensor_definitions", {"device_id": device, "project_id": project,
                                  "name": "Temperature", "sensor_type": "temperature",
                                  "telemetry_key": "temperature", "unit": "°C"})
    insert("device_credentials", {"device_id": device, "api_key": key,
                                  "secret_hash": hashlib.sha256(secret.encode()).hexdigest()})
    fixture = {"public_key": public_key, "email": email, "password": password,
               "key": key, "secret": secret, "bridge_secret": secrets.token_hex(32),
               "device": device, "project": project, "org": org,
               "topic": f"nexloza/v1/{org}/{project}/{device}/telemetry"}
    write_broker(fixture)
    fd = os.open(SESSION, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as file:
        json.dump(fixture, file)
    print("Created disposable user, organization, project and virtual temperature device")


def connect(username, password, client_id=None):
    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id=client_id or "",
                         clean_session=client_id is None)
    if username is not None:
        client.username_pw_set(username, password)
    client.connect("127.0.0.1", int(os.environ.get("NEXLOZA_MQTT_PORT", "1883")), 15)
    return client


def forward(fixture, payload):
    data = json.loads(payload)
    if data["device_id"] != fixture["device"] or not data.get("message_id"):
        raise ValueError("Device scope or message ID mismatch")
    request = Request(GATEWAY + "/functions/v1/telemetry-ingest", payload, {
        "Content-Type": "application/json", "x-api-key": fixture["key"],
        "x-api-secret": fixture["secret"],
    })
    with urlopen(request, timeout=10) as response:
        if not json.load(response).get("success"):
            raise RuntimeError("Ingest rejected reading")
    return data["message_id"]


def worker():
    fixture = load()
    client = connect("bridge", fixture["bridge_secret"], "nexloza-smoke-bridge")
    client.manual_ack_set(True)

    def on_connect(connection, _, flags, reason, properties):
        if reason.is_failure:
            raise RuntimeError(f"Bridge authentication rejected ({reason})")
        connection.subscribe(fixture["topic"], qos=1)

    def on_subscribe(_, data, mid, reasons, properties):
        if any(reason.is_failure for reason in reasons):
            raise RuntimeError("Bridge subscription rejected")
        print("Bridge subscribed to the scoped telemetry topic", flush=True)

    def on_message(connection, _, message):
        if message.topic != fixture["topic"]:
            raise RuntimeError("Unexpected broker topic")
        try:
            message_id = forward(fixture, message.payload)
        except (ValueError, KeyError, TypeError, HTTPError) as error:
            if isinstance(error, HTTPError) and (
                error.code >= 500 or error.code == 429
            ):
                raise RuntimeError(f"Retryable ingest HTTP {error.code}") from None
            print("Rejected invalid telemetry", flush=True)
            connection.ack(message.mid, message.qos)
            return
        connection.ack(message.mid, message.qos)
        print(f"Ingested message {message_id}", flush=True)

    client.on_connect = on_connect
    client.on_subscribe = on_subscribe
    client.on_message = on_message
    client.loop_forever()


def assert_auth(user, password, allowed):
    client = connect(user, password)
    done = threading.Event()
    results = []

    def on_connect(_, data, flags, reason, properties):
        results.append(not reason.is_failure)
        done.set()

    client.on_connect = on_connect
    client.loop_start()
    done.wait(5)
    client.disconnect()
    client.loop_stop()
    if results != [allowed]:
        raise RuntimeError("Broker authentication did not match expectation")


def broker_check(fixture):
    assert_auth(None, None, False)
    assert_auth(fixture["key"], "incorrect", False)
    assert_auth(fixture["key"], fixture["secret"], True)
    bridge = connect("bridge", fixture["bridge_secret"])
    device = connect(fixture["key"], fixture["secret"])
    ready, received, outside = (threading.Event() for _ in range(3))
    receipt = uuid4().hex.encode()
    other = fixture.get("other_topic")
    subscriptions = [(fixture["topic"], 1)]
    if other:
        subscriptions.append((other, 1))
    bridge.on_connect = lambda c, *_: c.subscribe(subscriptions)
    bridge.on_subscribe = lambda c, data, mid, reasons, props: (
        ready.set() if not any(reason.is_failure for reason in reasons) else None
    )
    bridge.on_message = lambda c, data, message: (
        (outside if message.topic == other else received).set()
        if message.payload == receipt else None
    )
    bridge.loop_start()
    device.loop_start()
    try:
        if not ready.wait(5):
            raise RuntimeError("Scoped subscribe failed")
        device.publish(fixture["topic"], receipt, qos=1)
        if not received.wait(5):
            raise RuntimeError("Scoped publish failed")
        if other:
            bridge.publish(other, receipt, qos=1)
            if not outside.wait(5):
                raise RuntimeError("Cross-project observer did not receive its control message")
            outside.clear()
            device.publish(other, receipt, qos=1)
            if outside.wait(2):
                raise RuntimeError("Cross-project publish was delivered")
    finally:
        bridge.disconnect()
        device.disconnect()
        bridge.loop_stop()
        device.loop_stop()
    assert_auth(fixture["key"], fixture["secret"], True)
    print("PASS: authenticated round trip, anonymous and wrong-password rejection, reconnect")
    if other:
        print("PASS: cross-project publish denied")


def rows(fixture, message_id=None, token=None):
    if token is None:
        token = api("/auth/v1/token?grant_type=password", fixture["public_key"],
                    {"email": fixture["email"], "password": fixture["password"]})["access_token"]
    query = f'/rest/v1/telemetry?device_id=eq.{fixture["device"]}&order=received_at.desc&limit=40'
    if message_id:
        query += f"&message_id=eq.{message_id}"
    return api(query, fixture["public_key"], token=token)


def e2e():
    fixture = load()
    message_id = str(uuid4())
    timestamp = datetime.now(timezone.utc)
    body = json.dumps({"device_id": fixture["device"], "message_id": message_id,
                       "readings": [{"key": "temperature", "value": 23.875,
                                     "timestamp": timestamp.isoformat()}]})
    client = connect(fixture["key"], fixture["secret"])
    client.loop_start()
    try:
        for _ in range(2):
            result = client.publish(fixture["topic"], body, qos=1)
            result.wait_for_publish(timeout=5)
            if not result.is_published():
                raise RuntimeError("MQTT publish did not receive acknowledgement")
    finally:
        client.disconnect()
        client.loop_stop()

    deadline = time.monotonic() + 20
    while not rows(fixture, message_id):
        if time.monotonic() >= deadline:
            raise RuntimeError("MQTT bridge did not persist the reading")
        time.sleep(1)
    # Confirm the second request through the same idempotent Edge Function contract.
    forward(fixture, body.encode())
    result = rows(fixture, message_id)
    if (len(result) != 1 or result[0]["value_numeric"] != 23.875
            or result[0]["sensor_key"] != "temperature"
            or datetime.fromisoformat(result[0]["recorded_at"]) != timestamp):
        raise RuntimeError("Expected exactly one matching temperature row")
    outsider = api("/auth/v1/signup", fixture["public_key"],
                   {"email": f"outsider-{uuid4().hex}@example.com",
                    "password": secrets.token_urlsafe(24)})["access_token"]
    if rows(fixture, message_id, outsider):
        raise RuntimeError("Cross-project JWT unexpectedly read telemetry")
    print(f"PASS: one persisted temperature row, message {message_id}; outsider denied")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["prepare", "broker", "worker", "e2e",
                                          "rows", "broker-smoke", "stop"])
    action = parser.parse_args().action
    if action == "prepare":
        provision(os.environ["NEXLOZA_PUBLIC_KEY"])
    elif action == "broker":
        subprocess.run([*COMPOSE, "up", "-d", "--wait"], env=broker_env(), check=True)
        broker_check(load())
    elif action == "worker":
        worker()
    elif action == "e2e":
        e2e()
    elif action == "rows":
        print(json.dumps(rows(load()), indent=2))
    elif action == "stop":
        subprocess.run([*COMPOSE, "down"], env=broker_env(), check=True)
    else:
        fixture = {"key": secrets.token_hex(16), "secret": secrets.token_hex(32),
                   "bridge_secret": secrets.token_hex(32),
                   "project": str(uuid4()),
                   "topic": f"nexloza/v1/{uuid4()}/PROJECT/{uuid4()}/telemetry"}
        fixture["topic"] = fixture["topic"].replace("PROJECT", fixture["project"])
        fixture["other_topic"] = fixture["topic"].replace(fixture["project"], str(uuid4()))
        if SESSION.exists():
            raise RuntimeError("Broker smoke requires a clean disposable fixture")
        write_broker(fixture)
        subprocess.run([*COMPOSE, "up", "-d", "--wait"], env=broker_env(), check=True)
        try:
            broker_check(fixture)
        finally:
            subprocess.run([*COMPOSE, "down"], env=broker_env(), check=True)


if __name__ == "__main__":
    main()
