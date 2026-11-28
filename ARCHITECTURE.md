# Nexloza Platform Architecture

## High-Level System Overview

Nexloza is a universal IoT platform built with a modular, layered architecture. The system connects IoT hardware devices to a cloud backend through an MQTT broker, managed via a Flutter mobile application with an AI-powered assistant.

```
+------------------------------------------------------------------+
|                      Flutter Mobile App                           |
|  +--------+ +----------+ +---------+ +------+ +--------------+   |
|  |  Auth  | | Projects | | Devices | | Auto | | AI Assistant |   |
|  +---+----+ +----+-----+ +----+----+ +--+---+ +------+-------+   |
+------+----------+-------------+----------+------------+-----------+
       |          |             |          |            |
       v          v             v          v            v
+------------------------------------------------------------------+
|                         Supabase                                  |
|  +------+ +------------+ +----------+ +---------+ +------------+ |
|  | Auth | | PostgreSQL | | Realtime | | Storage | |    Edge     | |
|  |      | |   + RLS    | |          | |         | | Functions  | |
|  +------+ +------------+ +----------+ +---------+ +-----+------+ |
+--------------------------------------------------+-------+-------+
                                                   |       |
                +----------------------------------+       |
                |                  |                        |
                v                  v                        v
       +---------------+  +----------------+  +--------------------+
       |  EMQX MQTT    |  |  AWS Bedrock   |  | Alexa / Google     |
       |  Broker       |  |  (Claude AI)   |  | Home Cloud         |
       +-------+-------+  +----------------+  +--------------------+
               |
               v
+------------------------------------------------------------------+
|            IoT Devices (ESP32, ESP8266, Raspberry Pi)             |
|  +-----------+ +-------------+ +----------+ +--------------+     |
|  |  Sensors  | |  Actuators  | |  Relays  | |    Custom    |     |
|  +-----------+ +-------------+ +----------+ +--------------+     |
+------------------------------------------------------------------+
```

### Core Components

- **Flutter Mobile App** -- Cross-platform mobile application (Android, iOS, Web) using feature-first clean architecture with Riverpod state management.
- **Supabase Backend** -- PostgreSQL database with Row Level Security, real-time subscriptions, authentication, file storage, and Edge Functions for server-side logic.
- **EMQX MQTT Broker** -- Enterprise-grade MQTT broker handling device-to-cloud communication with TLS, JWT-based device authentication, and topic ACLs.
- **Firmware SDK** -- Arduino/PlatformIO libraries for ESP32 and ESP8266 to connect devices to the platform. Planned for future milestone.
- **AI Assistant** -- Claude-powered conversational interface for device management, automation suggestions, and troubleshooting, accessed via AWS Bedrock.

## Directory Structure

```
nexloza/
|-- app/                        # Flutter mobile application
|   |-- lib/
|   |   |-- config/             # Environment and app configuration
|   |   |-- core/               # Constants, errors, extensions, utils
|   |   |-- features/           # Feature modules (see below)
|   |   |-- routing/            # GoRouter navigation
|   |   |-- shared/             # Shared models, providers, widgets
|   |   |-- theme/              # Colors, typography, spacing, theme
|   |   |-- app.dart            # Root MaterialApp widget
|   |   +-- main.dart           # Entry point
|   |-- test/                   # Unit and widget tests
|   +-- pubspec.yaml
|-- backend/
|   +-- supabase/
|       |-- migrations/         # 14 SQL migration files
|       |-- functions/          # Supabase Edge Functions
|       +-- seed.sql            # Development seed data
|-- mqtt/
|   |-- broker/                 # MQTT broker configuration (EMQX/Mosquitto)
|   +-- configuration/          # Client and topic configuration
|-- scripts/                    # Development and deployment scripts
|-- integrations/               # Third-party integrations
|   |-- home-assistant/         # Home Assistant (planned)
|   +-- node-red/               # Node-RED (planned)
|-- docs/                       # Documentation
|   |-- api/                    # API and protocol documentation
|   |-- architecture/           # Architecture and database docs
|   |-- setup/                  # Setup and development guides
|   |-- getting-started/        # Getting started tutorials
|   |-- backend/                # Backend documentation
|   |-- firmware/               # Firmware and hardware guides
|   |-- integrations/           # Integration guides
|   +-- security/               # Security documentation
|-- ARCHITECTURE.md             # This file
|-- LICENSE                     # Apache License 2.0
+-- README.md                   # Project overview
```

## Data Flow

### Device Telemetry (Sensor Data Ingestion)

```
IoT Device
    |
    | MQTT PUBLISH nexloza/v1/{organization_id}/{project_id}/{device_id}/telemetry
    v
MQTT broker
    |
    | Scoped MQTT bridge
    v
Supabase Edge Function (telemetry-ingest)
    |
    | Validates the device credential and parses the readings
    v
PostgreSQL (telemetry table)
    |
    | Supabase Realtime broadcast
    v
Flutter App (live dashboard update)
```

### Device Commands (App to Device)

```
Flutter App
    |
    | Supabase RPC / Edge Function call
    v
PostgreSQL (device_commands table, status: pending)
    |
    | Scoped bridge dispatches pending commands
    v
NanoMQ broker (disposable test runtime)
    |
    | MQTT DELIVER nexloza/v1/{organization_id}/{project_id}/{device_id}/command
    v
IoT Device
    |
    | Executes command, publishes ACK
    v
NanoMQ --> scoped bridge --> Edge Function --> PostgreSQL (command_results)
    |
    | Realtime notification
    v
Flutter App (command status updated)
```

For the disposable virtual-device runtime, the Edge Function queues a command under the caller's project permissions. A device-scoped bridge polls pending commands, publishes to the exact device topic and forwards acknowledgements. Postgres atomically records completion and reported state after a matching acknowledgement. The bridge also persists online/offline MQTT status, including the device's retained Last Will. See the [runtime test report](docs/test-results/VIRTUAL_IOT_E2E_TEST.md).

### Offline persistence

The app uses account-scoped SQLite snapshots and a transactional outbox for version-checked project edits. See the [SQLite architecture](docs/OFFLINE_SQLITE_ARCHITECTURE.md) for platform setup, retention, and replay semantics.

### Automation Execution

```
Telemetry arrives
    |
    v
Automation Engine (Edge Function)
    |
    | Evaluate triggers: sensor_threshold, device_state_change, schedule
    v
Check conditions: value_comparison, time_window, device_status
    |
    | Conditions met?
    v
Execute actions: device_command, notification, email, webhook, run_scene
    |
    v
Log execution in automation_executions table
```

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Mobile App | Flutter 3.47+ / Dart | Cross-platform UI |
| State Management | Riverpod | Reactive state, dependency injection |
| Navigation | GoRouter | Declarative routing |
| Backend | Supabase (self-hosted or cloud) | Auth, DB, Realtime, Storage, Functions |
| Database | PostgreSQL 15+ | Primary data store with RLS |
| MQTT Broker | EMQX 5.x (or Mosquitto) | Device communication |
| AI | AWS Bedrock (Claude) | Conversational assistant |
| Firmware | Arduino / PlatformIO | ESP32, ESP8266 device firmware |
| CI/CD | GitHub Actions | Automated testing and deployment |
| Containerization | Docker Compose | Local development environment |

## Flutter Feature-First Clean Architecture

Each feature module follows a layered structure to maintain separation of concerns:

```
features/
+-- authentication/
|   +-- presentation/
|       |-- screens/        # Full-page UI screens
|       |-- widgets/        # Feature-specific widgets
|       +-- providers/      # Riverpod providers (state + logic)
+-- devices/
|   |-- domain/
|   |   +-- entities/       # Pure Dart data classes
|   +-- presentation/
|       |-- screens/
|       +-- widgets/
+-- automations/
|   |-- domain/
|   |   +-- entities/
|   +-- presentation/
|       +-- screens/
+-- (other features follow the same pattern)
```

### Architecture Layers

- **Domain** -- Business entities and logic. Pure Dart, no framework dependencies. Entities define the data structures used across the app.
- **Presentation** -- UI screens, widgets, and Riverpod providers. Providers manage state, call Supabase APIs, and expose reactive streams to the UI.
- **Shared** -- Cross-cutting concerns: common widgets (buttons, text fields, loading indicators), shared models (Result, AppUser), and providers (Supabase client, connectivity).
- **Core** -- Constants, error types, extensions, utilities, and network info. Imported by all layers.

### Key Design Decisions

1. **Feature isolation** -- Each feature is a self-contained directory. Features communicate through shared providers, not direct imports.
2. **Riverpod over BLoC** -- Chosen for compile-time safety, simpler testing, and better support for async data (AsyncValue).
3. **Supabase direct calls** -- Presentation providers call Supabase directly rather than through a repository layer, reducing boilerplate for this project's scale. Repository abstraction can be added per-feature as complexity grows.
4. **Offline-first** -- Local storage (Hive/Isar) caches critical data for offline access. Sync logic runs on connectivity restoration.

## Database Schema Overview

The database is defined across 14 migration files creating 30+ tables. All tables enforce Row Level Security (RLS) for project-level data isolation.

| Migration | Tables | Purpose |
|-----------|--------|---------|
| 00001 | profiles | User profiles extending Supabase Auth |
| 00002 | organizations, organization_members | Multi-user organizations with roles |
| 00003 | projects, project_members | IoT projects -- primary isolation boundary |
| 00004 | devices, device_credentials, device_groups, device_group_members | Device registry and authentication |
| 00005 | sensor_definitions, actuator_definitions | Sensor/actuator metadata and thresholds |
| 00006 | telemetry, device_commands, command_results | Time-series data and device control |
| 00007 | dashboards, dashboard_widgets | Custom dashboard layouts with 20+ widget types |
| 00008 | automations, automation_triggers, automation_conditions, automation_actions, automation_executions | Rule engine with triggers, conditions, actions |
| 00009 | scenes, scene_actions | Multi-device state presets |
| 00010 | notifications, notification_preferences | In-app notifications with per-category settings |
| 00011 | integrations, integration_events | Third-party service connections |
| 00012 | ai_conversations, ai_messages | AI assistant chat history |
| 00013 | audit_logs | Security and change audit trail |
| 00014 | firmware_versions, ota_deployments | Firmware management and OTA updates |

For full schema details, see [docs/architecture/database.md](docs/architecture/database.md).

## MQTT Topic Conventions

All MQTT topics follow a hierarchical structure:

```
nexloza/{org_id}/{project_id}/{device_id}/{channel}
```

### Channels

| Channel | Direction | QoS | Description |
|---------|-----------|-----|-------------|
| `telemetry/{sensor_key}` | Device --> Cloud | 1 | Sensor readings |
| `commands` | Cloud --> Device | 1 | Commands from app or automations |
| `state` | Device --> Cloud | 1 | Device/actuator state reports |
| `heartbeat` | Device --> Cloud | 0 | Periodic health check (uptime, heap, RSSI) |
| `ota` | Cloud --> Device | 1 | Firmware update notifications |

### Topic Examples

```
nexloza/org_abc/proj_123/dev_456/telemetry/temperature
nexloza/org_abc/proj_123/dev_456/commands
nexloza/org_abc/proj_123/dev_456/state
nexloza/org_abc/proj_123/dev_456/heartbeat
nexloza/org_abc/proj_123/dev_456/ota
```

### Wildcards (Backend Only)

- `nexloza/+/+/+/telemetry/#` -- Subscribe to all telemetry across all devices
- `nexloza/{org_id}/{project_id}/+/heartbeat` -- Monitor all device heartbeats in a project

Devices are restricted to their own topics via JWT-encoded ACLs. Only backend services using the superuser account may subscribe to wildcard topics.

For full MQTT protocol details including payload formats, see [docs/api/mqtt-protocol.md](docs/api/mqtt-protocol.md).

## Security Model

### Row Level Security (RLS)

Every table has RLS enabled. Access is enforced at the database level:

| Role | Access |
|------|--------|
| Project owner | Full CRUD on project and all child resources |
| Project admin | Full CRUD except project deletion |
| Project developer | Read/write on devices, sensors, commands, dashboards, automations |
| Project viewer | Read-only on all project resources |
| Non-member | No access to any project resource |
| Service role | System operations only (telemetry ingest, automation execution) |

### Device Authentication

1. Each device receives a unique API key (UUID) and secret (random 256-bit).
2. Secret is stored as a bcrypt hash -- never in plaintext.
3. Device authenticates via a REST endpoint, receiving a short-lived MQTT JWT (default: 24 hours).
4. The JWT encodes device_id, project_id, and allowed MQTT topics.
5. EMQX validates the JWT on every CONNECT.
6. Credentials can be rotated without downtime and revoked instantly.

### JWT Authentication (Users)

- Supabase Auth issues JWT access tokens (1-hour expiry) and refresh tokens (7-day expiry).
- Refresh token rotation invalidates previous tokens on each refresh.
- Secure storage on mobile (flutter_secure_storage); httpOnly cookies on web.
- All RLS policies reference `auth.uid()` from the JWT.

### Transport Security

- MQTT: TLS 1.2+ required in production (port 8883). Unencrypted only for local development.
- HTTPS: All Supabase and Edge Function endpoints use HTTPS.
- CORS: Restricted to known application origins.

For the complete security architecture including AI safety measures, secret management, and the security checklist, see [docs/architecture/security.md](docs/architecture/security.md).
