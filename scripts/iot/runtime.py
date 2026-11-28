"""Disposable, loopback-only MQTT bridge and integration checks."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import secrets
import socket
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


def api(path, key, payload=None, token=None, *, preserve_http_error=False):
    headers = {"apikey": key, "Authorization": f"Bearer {token or key}"}
    data = None
    if payload is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(payload).encode()
    try:
        with urlopen(Request(GATEWAY + path, data, headers), timeout=10) as response:
            return json.loads(response.read() or b"null")
    except HTTPError as error:
        if preserve_http_error:
            raise
        raise RuntimeError(f"{path.split('?')[0]} returned HTTP {error.code}") from None


def load():
    return json.loads(SESSION.read_text(encoding="utf-8"))


def channel(device, name):
    return device["topic"].rsplit("/", 1)[0] + "/" + name


ACTUATORS = {
    "relay": ("relay", "toggle", 1),
    "led": ("light", "toggle", 1),
    "fan_speed": ("fan", "slider", 100),
    "brightness": ("light", "slider", 100),
    "servo_angle": ("servo", "slider", 180),
}


def add_actuators(public_key, token, device, project):
    for name, (kind, control, maximum) in ACTUATORS.items():
        api("/rest/v1/actuator_definitions", public_key, {
            "device_id": device, "project_id": project, "name": name,
            "actuator_type": kind, "control_type": control,
            "command_key": name, "min_value": 0, "max_value": maximum,
        }, token)


def write_broker(device):
    STATE.mkdir(mode=0o700, exist_ok=True)
    (STATE / "nanomq.conf").write_text(
        'listeners.tcp { bind = "0.0.0.0:1883" }\n'
        'auth {\n allow_anonymous = false\n no_match = deny\n deny_action = disconnect\n'
        ' password = {include "/run/nexloza/pw.conf"}\n'
        ' acl = {include "/run/nexloza/acl.conf"}\n}\n', encoding="utf-8")
    devices = [device, *device.get("additional_devices", [])]
    credentials = {item["key"]: item["secret"] for item in devices}
    credentials["bridge"] = device["bridge_secret"]
    (STATE / "pw.conf").write_text(
        "".join(f"{json.dumps(key)}: {json.dumps(secret)}\n"
                for key, secret in credentials.items()), encoding="utf-8")
    rules = []
    for item in devices:
        published = [channel(item, name) for name in ("telemetry", "command-ack", "state", "status")]
        command = channel(item, "command")
        rules.extend([
            {"permit": "allow", "username": item["key"], "action": "publish", "topics": published},
            {"permit": "allow", "username": item["key"], "action": "subscribe", "topics": [command]},
            {"permit": "allow", "username": "bridge", "action": "subscribe", "topics": published},
            {"permit": "allow", "username": "bridge", "action": "publish", "topics": [command]},
        ])
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
    add_actuators(public_key, token, device, project)
    second_email = f"iot-second-{suffix}@example.com"
    second_password = secrets.token_urlsafe(24)
    second_owner = api("/auth/v1/signup", public_key, {
        "email": second_email, "password": second_password,
    })
    second_token = second_owner["access_token"]
    second_org, second_project, second_device = [str(uuid4()) for _ in range(3)]

    def insert_second(table, row):
        api(f"/rest/v1/{table}", public_key, row, second_token)

    insert_second("organizations", {"id": second_org, "name": "IoT Agriculture",
                                     "slug": f"farm-{suffix}", "created_by": second_owner["user"]["id"]})
    insert_second("projects", {"id": second_project, "organization_id": second_org,
                                "owner_id": second_owner["user"]["id"],
                                "name": "IoT Farm", "category": "smart_agriculture"})
    insert_second("devices", {"id": second_device, "project_id": second_project,
                               "name": "IoT Soil", "hardware_platform": "generic_mqtt",
                               "is_virtual": True, "simulation_profile": "agriculture"})
    insert_second("sensor_definitions", {"device_id": second_device, "project_id": second_project,
                                         "name": "Soil", "sensor_type": "soil_moisture",
                                         "telemetry_key": "soil_moisture"})
    key2, secret2 = secrets.token_hex(16), secrets.token_hex(32)
    insert_second("device_credentials", {"device_id": second_device, "api_key": key2,
                                         "secret_hash": hashlib.sha256(secret2.encode()).hexdigest()})
    fixture["additional_devices"] = [
        {"device": second_device, "project": second_project, "org": second_org,
         "public_key": public_key, "email": second_email, "password": second_password,
         "key": key2, "secret": secret2,
         "topic": f"nexloza/v1/{second_org}/{second_project}/{second_device}/telemetry"}
    ]
    write_broker(fixture)
    fd = os.open(SESSION, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as file:
        json.dump(fixture, file)
    print("Created disposable user, organization, project and virtual temperature device")


def connect(username, password, client_id=None, *, will=None):
    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id=client_id or "",
                         clean_session=client_id is None)
    if username is not None:
        client.username_pw_set(username, password)
    if will is not None:
        client.will_set(will, json.dumps({"online": False}), qos=1, retain=True)
    client.connect("127.0.0.1", int(os.environ.get("NEXLOZA_MQTT_PORT", "1883")), 15)
    return client


def forward(fixture, payload):
    data = json.loads(payload)
    if data["device_id"] != fixture["device"] or not data.get("message_id"):
        raise ValueError("Device scope or message ID mismatch")
    ingest(fixture["key"], fixture["secret"], payload)
    return data["message_id"]


def ingest(key, secret, payload):
    request = Request(GATEWAY + "/functions/v1/telemetry-ingest", payload, {
        "Content-Type": "application/json", "x-api-key": key, "x-api-secret": secret,
    })
    with urlopen(request, timeout=10) as response:
        if not json.load(response).get("success"):
            raise RuntimeError("Ingest rejected reading")


def device_runtime(fixture, action, **fields):
    payload = json.dumps({"action": action, "device_id": fixture["device"], **fields}).encode()
    request = Request(GATEWAY + "/functions/v1/virtual-device-runtime", payload, {
        "Content-Type": "application/json", "x-api-key": fixture["key"],
        "x-api-secret": fixture["secret"],
    })
    with urlopen(request, timeout=10) as response:
        return json.load(response)


def worker():
    fixture = load()
    devices = [fixture, *fixture.get("additional_devices", [])]
    routes = {
        channel(device, name): (device, name)
        for device in devices for name in ("telemetry", "command-ack", "state", "status")
    }
    client = connect("bridge", fixture["bridge_secret"], "nexloza-smoke-bridge")
    client.manual_ack_set(True)
    ready = threading.Event()
    stop = threading.Event()

    def on_connect(connection, _, flags, reason, properties):
        if reason.is_failure:
            raise RuntimeError(f"Bridge authentication rejected ({reason})")
        connection.subscribe([(topic, 1) for topic in routes])

    def on_subscribe(_, data, mid, reasons, properties):
        if any(reason.is_failure for reason in reasons):
            raise RuntimeError("Bridge subscription rejected")
        ready.set()
        print("Bridge subscribed to the scoped telemetry topics", flush=True)

    def on_message(connection, _, message):
        fixture, kind = routes[message.topic]
        try:
            if kind == "telemetry":
                message_id = forward(fixture, message.payload)
                print(f"Ingested message {message_id}", flush=True)
            elif kind == "command-ack":
                body = json.loads(message.payload)
                device_runtime(fixture, "ack", command_id=body["command_id"],
                               success=body["success"], value=body.get("value"))
            elif kind == "status":
                device_runtime(fixture, "availability", online=json.loads(message.payload)["online"])
            # Reported state changes are committed atomically from the matching ack.
        except (ValueError, KeyError, TypeError, HTTPError) as error:
            if isinstance(error, HTTPError) and (error.code >= 500 or error.code == 429):
                raise RuntimeError(f"Retryable device HTTP {error.code}") from None
            print(f"Rejected invalid {kind} event", flush=True)
        connection.ack(message.mid, message.qos)

    def dispatch():
        while not stop.wait(1):
            if not ready.is_set() or not client.is_connected():
                continue
            for device in devices:
                try:
                    for command in device_runtime(device, "dispatch")["commands"]:
                        payload = {
                            "command_id": command["id"], "command_type": command["command_type"],
                            "payload": command["payload"], "expires_at": command["expires_at"],
                        }
                        client.publish(channel(device, "command"), json.dumps(payload), qos=1)
                except (OSError, RuntimeError) as error:
                    status = f"HTTP {error.code}" if isinstance(error, HTTPError) else type(error).__name__
                    print(f"Command dispatch unavailable ({status})", flush=True)

    client.on_connect = on_connect
    client.on_subscribe = on_subscribe
    client.on_message = on_message
    thread = threading.Thread(target=dispatch, daemon=True)
    thread.start()
    try:
        client.loop_forever()
    finally:
        stop.set()


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


def sign_in(fixture):
    return api("/auth/v1/token?grant_type=password", fixture["public_key"],
               {"email": fixture["email"], "password": fixture["password"]})["access_token"]


def wait_for(check, description, seconds=20):
    end = time.monotonic() + seconds
    while time.monotonic() < end:
        result = check()
        if result:
            return result
        time.sleep(0.25)
    raise RuntimeError(f"Timed out waiting for {description}")


def command_e2e(fixture):
    other = fixture["additional_devices"][0]
    token = sign_in(fixture)
    public_key = fixture["public_key"]

    def send(name, value, command_id=None, owner=token, device=fixture["device"]):
        return api("/functions/v1/device-command", public_key,
                   {"device_id": device, "command_type": name, "payload": {"value": value},
                    "command_id": command_id or str(uuid4())}, owner, preserve_http_error=True)["command"]

    def reject(status, call):
        try:
            call()
        except HTTPError as error:
            if error.code == status:
                return
            raise RuntimeError(f"Expected HTTP {status}, got {error.code}") from None
        raise RuntimeError(f"Expected HTTP {status}")

    def select(table, query, owner=token):
        return api(f"/rest/v1/{table}?{query}", public_key, token=owner)

    def command_status(id, status):
        records = select("device_commands", f"id=eq.{id}")
        return records[0] if records and records[0]["status"] == status else None

    def online(value):
        records = select("devices", f'id=eq.{fixture["device"]}')
        return records and records[0]["is_online"] is value

    reject(404, lambda: send("relay", True, device=other["device"]))
    reject(400, lambda: send("fan_speed", 101))
    reject(400, lambda: send("unknown", 1))
    outsider = sign_in(other)
    reject(404, lambda: send("relay", True, owner=outsider))

    client = connect(fixture["key"], fixture["secret"], will=channel(fixture, "status"))
    client.reconnect_delay_set(min_delay=4, max_delay=4)
    client.on_connect = lambda c, *_: c.subscribe(channel(fixture, "command"), qos=1)
    client.on_subscribe = lambda c, *_: c.publish(
        channel(fixture, "status"), '{"online":true}', qos=1, retain=True)
    received = {}
    completed = set()

    def on_command(connection, _, message):
        body = json.loads(message.payload)
        received[body["command_id"]] = body
        if body["command_id"] in completed:
            acknowledge(body)

    def acknowledge(body, success=True):
        value = body["payload"]["value"]
        id = body["command_id"]
        ack = {"command_id": id, "success": success, "value": value + 0 if success else None}
        if success:
            client.publish(channel(fixture, "state"),
                           json.dumps({"command_id": id, body["command_type"]: value}), qos=1)
        client.publish(channel(fixture, "command-ack"), json.dumps(ack), qos=1)

    client.on_message = on_command
    client.loop_start()
    try:
        wait_for(lambda: online(True), "online")
        for key, value in (("relay", True), ("relay", False), ("led", True), ("led", False),
                           ("fan_speed", 60), ("brightness", 45), ("servo_angle", 90)):
            command = send(key, value)
            id = command["id"]
            delivered = wait_for(lambda: received.get(id), f"delivery of {key}")
            wait_for(lambda: command_status(id, "sent"), "unacknowledged status")
            if send(key, value, id)["id"] != id:
                raise RuntimeError("Command retry created a duplicate")
            completed.add(id)
            acknowledge(delivered)
            acknowledge(delivered)
            wait_for(lambda: command_status(id, "executed"), f"acknowledgement of {key}")
            twin = select("device_twin_state", f'device_id=eq.{fixture["device"]}')[0]
            results = select("command_results", f"command_id=eq.{id}")
            if twin["reported_state"][key] != value or len(results) != 1 or not results[0]["success"]:
                raise RuntimeError(f"Invalid reported state or duplicate result for {key}")

        rejected = send("relay", True)["id"]
        acknowledge(wait_for(lambda: received.get(rejected), "rejectable command"), False)
        wait_for(lambda: command_status(rejected, "failed"), "device rejection")

        timeout = send("relay", True)["id"]
        wait_for(lambda: received.get(timeout), "unanswered command")
        wait_for(lambda: command_status(timeout, "timeout"), "command timeout", seconds=40)
        if select("command_results", f"command_id=eq.{timeout}"):
            raise RuntimeError("Timed-out command generated a result")

        # Abort only this test client's connection. The broker publishes its Will.
        client.socket().shutdown(socket.SHUT_RDWR)
        wait_for(lambda: online(False), "Last Will offline")
        wait_for(lambda: online(True), "automatic reconnect online")

        soil_id = str(uuid4())
        soil = connect(other["key"], other["secret"])
        soil.loop_start()
        try:
            reading = {"device_id": other["device"], "message_id": soil_id,
                       "readings": [{"key": "soil_moisture", "value": 42.125,
                                     "timestamp": datetime.now(timezone.utc).isoformat()}]}
            soil.publish(other["topic"], json.dumps(reading), qos=1).wait_for_publish(timeout=5)
            found = wait_for(lambda: rows(other, soil_id, outsider), "soil moisture")
            if len(found) != 1 or found[0]["value_numeric"] != 42.125 or rows(other, soil_id, token):
                raise RuntimeError("Soil moisture value or account isolation mismatch")
        finally:
            soil.disconnect()
            soil.loop_stop()
    finally:
        client.disconnect()
        client.loop_stop()
    print("PASS: soil moisture, relay/LED ON/OFF, fan, brightness, servo, ack, replay, timeout, Will and reconnect")


def e2e():
    fixture = load()
    message_id = str(uuid4())
    timestamp = datetime.now(timezone.utc)
    body = json.dumps({"device_id": fixture["device"], "message_id": message_id,
                       "readings": [
                           {"key": key, "value": value, "timestamp": timestamp.isoformat()}
                           for key, value in {"temperature": 23.875, "humidity": 61.25}.items()
                       ]})
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
    # Replaying through HTTP additionally exercises the shared ingest contract.
    # The row above must already exist from the broker; HTTP cannot rescue it.
    forward(fixture, body.encode())
    result = rows(fixture, message_id)
    expected = {"temperature": 23.875, "humidity": 61.25}
    values = {row["sensor_key"]: row["value_numeric"] for row in result}
    if (len(result) != len(expected) or values != expected
            or any(datetime.fromisoformat(row["recorded_at"]) != timestamp for row in result)):
        raise RuntimeError("Expected exactly one matching row for each sensor")
    outsider = api("/auth/v1/signup", fixture["public_key"],
                   {"email": f"outsider-{uuid4().hex}@example.com",
                    "password": secrets.token_urlsafe(24)})["access_token"]
    if rows(fixture, message_id, outsider):
        raise RuntimeError("Cross-project JWT unexpectedly read telemetry")
    for secret, payload, expected in [
        ("invalid", body.encode(), 401),
        (fixture["secret"], body.replace(fixture["device"], str(uuid4())).encode(), 403),
    ]:
        try:
            ingest(fixture["key"], secret, payload)
        except HTTPError as error:
            if error.code != expected:
                raise RuntimeError(f"Expected HTTP {expected}, got {error.code}") from None
        else:
            raise RuntimeError(f"Expected ingestion rejection HTTP {expected}")
    print(f"PASS: one persisted row per sensor, message {message_id}; outsider denied")
    print("PASS: invalid device secret and mismatched device identity rejected")
    command_e2e(fixture)


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
