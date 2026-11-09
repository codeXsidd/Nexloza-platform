<p align="center">
  <img src="docs/assets/nexloza-logo.png" alt="NexLoza Logo" width="200" />
</p>

<h1 align="center">NexLoza</h1>

<p align="center">
  <strong>One Platform. Unlimited IoT Possibilities.</strong>
</p>

<p align="center">
  <a href="https://github.com/codeXsidd/nexioza-platform/actions"><img src="https://github.com/codeXsidd/nexioza-platform/actions/workflows/ci.yml/badge.svg" alt="CI" /></a>
  <a href="https://github.com/codeXsidd/nexioza-platform/blob/main/LICENSE"><img src="https://img.shields.io/github/license/codeXsidd/nexioza-platform" alt="License" /></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter" alt="Flutter" /></a>
  <a href="https://supabase.com"><img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase" alt="Supabase" /></a>
  <a href="https://www.emqx.io"><img src="https://img.shields.io/badge/EMQX-MQTT-5C2D91" alt="MQTT" /></a>
</p>

---

## What is NexLoza?

NexLoza is an open-source, universal IoT platform that lets anyone create and manage multiple independent IoT projects — smart home, agriculture, industrial monitoring, energy metering, and more — from a single application.

Think of it as **Blynk + IFTTT + Home Assistant + AWS IoT**, fully open-source and self-hostable.

## Features

- **Multi-Project Management** — Create unlimited IoT projects with isolated data, devices, and dashboards
- **Universal Device Support** — ESP32, ESP8266, Raspberry Pi, Arduino, and any MQTT-compatible device
- **Dynamic Dashboard Builder** — Drag-and-drop widgets: gauges, charts, switches, sliders, maps, and 20+ widget types
- **Automation Engine** — Visual trigger → condition → action builder with scheduling, webhooks, and scenes
- **AI Assistant** — Claude-powered IoT assistant via Amazon Bedrock for diagnostics, automation generation, and firmware help
- **Voice Control** — Alexa Smart Home and Google Home integration
- **Real-time Telemetry** — Live sensor data, historical analytics, and configurable alerts
- **Device SDK** — Arduino-compatible SDK for ESP32/ESP8266 with provisioning, OTA updates, and secure MQTT
- **Team Collaboration** — Organizations, project invitations, and role-based access (Owner, Admin, Developer, Viewer)
- **Offline Support** — Local caching, pending commands, and automatic reconnection

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile & Web | Flutter, Dart, Riverpod, GoRouter, Material 3 |
| Backend | Supabase (PostgreSQL, Auth, Realtime, Edge Functions, Storage) |
| IoT Communication | MQTT 3.1.1/5 via EMQX, WebSockets, REST |
| AI | Amazon Bedrock (Claude), Converse API, Tool Calling |
| Voice | Alexa Smart Home Skill, Google Home Cloud-to-Cloud |
| Firmware | ESP-IDF, Arduino, NexLoza Device SDK (C/C++) |
| Infrastructure | Docker Compose, GitHub Actions CI/CD |

## Quick Start

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) 3.47+
- [Docker](https://docs.docker.com/get-docker/) & Docker Compose
- [Supabase CLI](https://supabase.com/docs/guides/cli) (optional, for migrations)
- Git

### 1. Clone the Repository

```bash
git clone https://github.com/codeXsidd/nexioza-platform.git
cd nexioza-platform
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your Supabase, MQTT, and AWS credentials
```

### 3. Start Backend Services

```bash
docker compose up -d
```

This starts PostgreSQL, Supabase services, and the EMQX MQTT broker.

### 4. Run Database Migrations

```bash
cd backend/supabase
supabase db push
```

### 5. Run the App

```bash
cd app
flutter pub get
flutter run
```

## Architecture

```
nexloza/
├── app/                    # Flutter application
│   └── lib/
│       ├── core/           # Theme, routing, constants, shared utilities
│       └── features/       # Feature-first modules (auth, projects, devices, ...)
├── backend/
│   └── supabase/
│       ├── migrations/     # PostgreSQL migrations with RLS
│       └── functions/      # Supabase Edge Functions
├── firmware/
│   ├── nexloza-sdk/        # Device SDK (C/C++)
│   ├── esp32/              # ESP32 implementations
│   ├── esp8266/            # ESP8266 implementations
│   └── examples/           # Ready-to-flash example projects
├── mqtt/                   # EMQX broker configuration
├── integrations/           # Alexa, Google Home, webhooks
├── docs/                   # Architecture, API, setup guides
└── docker-compose.yml      # Local development stack
```

## Documentation

- [Architecture Overview](docs/architecture/)
- [Setup Guide](docs/setup/)
- [API Reference](docs/api/)
- [Firmware SDK Guide](docs/firmware/)
- [Security Policy](SECURITY.md)
- [Contributing Guide](CONTRIBUTING.md)

## Contributing

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md) before submitting a pull request.

## License

NexLoza is released under the [Apache License 2.0](LICENSE).

---

<p align="center">Built with purpose by the NexLoza community.</p>
