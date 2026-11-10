# NexIoza Web Developer Console Architecture

## Overview

The web developer console provides a desktop-first SaaS experience for IoT developers, organization administrators, and project owners. It uses the same Flutter application with responsive layouts that adapt to desktop screen sizes.

## Layout Structure

```
+------------------+----------------------------------------+
| Sidebar (260px)  |  Content Area                          |
|                  |  +----------------------------------+  |
| [N] NexIoza  [<] |  | AppBar with title                |  |
|                  |  +----------------------------------+  |
| Overview         |  |                                  |  |
| Organizations    |  |  Main content                    |  |
| Projects         |  |  (scrollable)                    |  |
|                  |  |                                  |  |
| DEVICE MGMT      |  |                                  |  |
| Devices          |  +----------------------------------+  |
| Templates        |                                        |
| Virtual Devices  |                                        |
|                  |                                        |
| INTELLIGENCE     |                                        |
| Dashboard Builder|                                        |
| Telemetry        |                                        |
| Automation       |                                        |
| Alerts           |                                        |
|                  |                                        |
| PLATFORM         |                                        |
| Integrations     |                                        |
| Firmware & OTA   |                                        |
| API & Dev Tools  |                                        |
|                  |                                        |
| Settings         |                                        |
+------------------+----------------------------------------+
```

## Sidebar Navigation

The sidebar is implemented in `WebConsoleSidebar` (`lib/shared/widgets/web_console_sidebar.dart`).

### Features

- **Collapsible:** Toggles between 260px expanded and 72px collapsed (icon-only with tooltips)
- **Sections:** Device Management, Intelligence, Platform — with section labels
- **Active state:** Highlighted with primary container color
- **NexIoza branding:** Logo badge + product name in header

### Navigation Items

5 items map to shell branches (same state as bottom nav):
- Overview → Branch 0 (Home)
- Devices → Branch 1
- Telemetry & Analytics → Branch 3
- Automation & Rules → Branch 2
- Settings → Branch 4

Remaining items navigate via `pushNamed`:
- Organizations, Projects, Device Templates, Virtual Devices
- Dashboard Builder, Alerts & Notifications
- Integrations, Firmware & OTA, API & Developer Tools

## Breakpoint Behavior

| Width | Layout |
|---|---|
| < 600px | Mobile bottom nav (no sidebar) |
| 600–899px | Tablet navigation rail |
| 900–1199px | Tablet navigation rail |
| ≥ 1200px | Full sidebar + content area |

## New Web Console Pages

### Device Templates (`/device-templates`)
- Catalogs supported hardware: ESP32, ESP32-C3, ESP32-S3, ESP8266
- Protocol templates: Generic MQTT, HTTP REST, Raspberry Pi, Arduino
- Displays GPIO pins, PlatformIO board IDs, features

### Firmware & OTA (`/firmware`)
- Honest "coming soon" placeholder
- Backend migration exists but no management API yet

### Developer Tools (`/developer`)
- API Keys navigation
- MQTT broker connection info and topic format reference
- Device Studio link
- Integration and webhook management links

## Shared Codebase

The web console uses the same:
- Domain models and entities
- Repository layer (Supabase, MQTT)
- Riverpod providers
- GoRouter configuration
- Design system tokens and components
- Authentication and authorization

No separate web frontend exists — this is a single Flutter application that adapts its navigation shell based on screen size.
