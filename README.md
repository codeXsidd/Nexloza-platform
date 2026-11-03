# NexIoza

**One Platform. Unlimited IoT Possibilities.**

[![CI](https://github.com/codeXsidd/nexioza-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/codeXsidd/nexioza-platform/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B.svg?logo=flutter)](https://flutter.dev)

NexIoza is a universal, customizable, open-source IoT platform. Create and manage multiple independent IoT projects — smart agriculture, industrial monitoring, energy management, environmental sensing, and more — all from a single application.

## Features

- **Multi-Project Management** — Create unlimited independent IoT projects with custom configurations
- **Dynamic Dashboard Builder** — Drag-and-drop widgets: gauges, charts, switches, sliders, maps, and more
- **Automation Engine** — Visual WHEN/IF/THEN rule builder with scheduling, conditions, and chained actions
- **Device Management** — ESP32, ESP8266, Raspberry Pi, and any MQTT-compatible hardware
- **Real-Time Monitoring** — Live sensor data, historical charts, event logs, and CSV/JSON export
- **Secure Device Provisioning** — QR-based pairing with per-device MQTT credentials
- **Voice Control** — Amazon Alexa, Google Home, and in-app voice commands
- **AI Assistant** — Claude-powered assistant via Amazon Bedrock for automation drafting, troubleshooting, and data analysis
- **Offline-First** — Local storage, command queuing, and automatic sync
- **Multi-User Collaboration** — Project sharing with role-based permissions (Owner, Admin, Editor, Viewer)
- **OTA Firmware Updates** — Over-the-air update framework for connected devices
- **Notifications** — Push notifications via FCM with configurable thresholds and alerts

## Architecture

```
Flutter App ──── HTTPS/WS ────► Supabase Backend ──── MQTT ────► Devices
     │                              │                               │
     │                              ├── Edge Functions              ├── ESP32
     │                              ├── PostgreSQL + RLS            ├── ESP8266
     │                              ├── Realtime                    ├── Raspberry Pi
     │                              └── Storage                     └── Generic MQTT
     │
     ├── Claude AI ──► AWS Lambda ──► Amazon Bedrock
     ├── Alexa ──► Smart Home Skill ──► OAuth ──► Fulfillment
     └── Google Home ──► Cloud-to-cloud ──► Fulfillment
```

## Quick Start

### Prerequisites

- Flutter 3.47+ and Dart 3.13+
- Android SDK 34+
- Docker (for local Supabase and MQTT broker)
- Node.js 20+ (for device simulator and Edge Functions)

### Setup

```bash
# Clone the repository
git clone https://github.com/codeXsidd/nexioza-platform.git
cd nexioza-platform

# Copy environment template
cp .env.example .env

# Install Flutter dependencies
cd app
flutter pub get

# Run the app
flutter run
```

See [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) for complete setup instructions.

## Documentation

| Document | Description |
|---|---|
| [Architecture](docs/ARCHITECTURE.md) | System design and data flow |
| [Getting Started](docs/GETTING_STARTED.md) | First-time setup guide |
| [Flutter Setup](docs/FLUTTER_SETUP.md) | Mobile app development |
| [Supabase Setup](docs/SUPABASE_SETUP.md) | Backend configuration |
| [MQTT Protocol](docs/MQTT_PROTOCOL.md) | Device communication protocol |
| [Device SDK](docs/DEVICE_SDK.md) | Firmware library and examples |
| [Dashboard Builder](docs/DASHBOARD_BUILDER.md) | Widget system and layouts |
| [Automation Engine](docs/AUTOMATION_ENGINE.md) | Rule builder and scheduling |
| [Security Model](docs/SECURITY_MODEL.md) | Authentication, authorization, encryption |
| [API Reference](docs/API_REFERENCE.md) | Backend API endpoints |

## Device Support

| Platform | Protocol | Status |
|---|---|---|
| ESP32 | MQTT over TLS | Supported |
| ESP8266 | MQTT over TLS | Supported |
| Raspberry Pi | MQTT / HTTP | Supported |
| Generic MQTT | MQTT 3.1.1 / 5.0 | Supported |
| Custom HTTP | REST API | Planned |
| BLE Gateway | BLE → MQTT bridge | Planned |

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a pull request.

## Security

If you discover a security vulnerability, please follow our [security policy](SECURITY.md). Do not open a public issue.

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.

---

Built with Flutter, Supabase, MQTT, and Claude AI.
