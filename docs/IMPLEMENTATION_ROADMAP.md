# NEXLOZA Implementation Roadmap

**Created:** 2026-11-09
**Baseline:** 53/53 tests passing, 0 errors, 8 commits on main

---

## Current State Summary

The project has a solid foundation:
- Complete database schema (28 tables, 15 migrations, comprehensive RLS)
- 6 working Edge Functions
- Flutter app with auth, projects, devices, automations, AI chat
- NexlozaClient firmware SDK with 9 hardware examples
- EMQX broker configuration with ACL
- CI pipeline with 5 jobs

**The critical gap is the middle layer:** the DB schema and Edge Functions exist, but they are not wired together end-to-end. Commands go into the DB but not to MQTT. Automations evaluate triggers but don't dispatch actions. Dashboards have tables but no UI.

---

## Phase 3: Universal Device Architecture & MQTT Communication

**Goal:** Make devices truly controllable end-to-end (app -> backend -> MQTT -> device -> response -> app).

**Prerequisites:** Commit uncommitted work. Fix 11 formatting issues. Fix 2 deprecation warnings.

### 3.1 Commit & Stabilize Current Work
- Commit all uncommitted changes (5 modified + 7 new directories)
- Fix dart format issues
- Fix deprecated `value` parameter in DropdownButtonFormField
- Fix license inconsistency (README/CONTRIBUTING say MIT, LICENSE is Apache 2.0)
- Update CHANGELOG.md

### 3.2 MQTT-Supabase Bridge
- Create a bridge service that subscribes to MQTT telemetry topics and writes to Supabase
- Wire device-command Edge Function to publish commands to MQTT (not just DB insert)
- Wire automation-engine to actually dispatch actions:
  - `device_command` action -> publish MQTT command
  - `notification` action -> insert notification record
  - `webhook` action -> HTTP POST to configured URL
- Handle command acknowledgements from MQTT -> update device_commands status

### 3.3 Device Management Screens (Complete)
- Device edit/rename screen
- Device detail screen with real-time telemetry display
- Sensor/actuator management screens (CRUD linked to device)
- Device credential provisioning UI (generate API key/secret)
- MQTT connection status in app (wire MqttService to UI)

### 3.4 Tests
- Widget tests for device screens
- Integration test for device command round-trip
- Edge Function tests for device-command MQTT publish
- MQTT connection/subscribe/publish unit tests

**Deliverable:** A user can add a device, configure sensors/actuators, send commands from the app, and see live telemetry.

---

## Phase 4: Dashboard System

**Goal:** Blynk-like customizable dashboard editor.

### 4.1 Dashboard UI Foundation
- DashboardScreen (list dashboards per project)
- CreateDashboard screen
- DashboardEditor with grid layout
- DashboardRepository and DashboardProvider

### 4.2 Widget System
- Base widget rendering framework (position, size, config from DB)
- Implement priority widgets: Switch, Button, Slider, Gauge, Value Display, LED Indicator
- Chart widgets: Line Chart, Bar Chart (using fl_chart)
- Status widgets: Device Status Card, Temperature Card, Humidity Card
- Widget configuration dialog (data source binding, colors, thresholds)

### 4.3 Real-Time Data Binding
- Supabase Realtime subscription for telemetry
- Widget auto-refresh based on data changes
- Actuator widgets publish commands via device-command Edge Function

### 4.4 Tests
- Widget rendering tests
- Dashboard layout persistence tests
- Real-time update integration tests

**Deliverable:** Users can create custom dashboards with drag-and-drop widgets showing live device data.

---

## Phase 5: Sensor/Actuator Configuration & Advanced Widgets

**Goal:** Universal sensor/actuator setup and remaining dashboard widgets.

### 5.1 Sensor/Actuator Management
- SensorListScreen, AddSensorScreen, SensorDetailScreen
- ActuatorListScreen, AddActuatorScreen, ActuatorDetailScreen
- Threshold and calibration configuration
- Sensor data type, unit, min/max, sampling interval configuration

### 5.2 Advanced Dashboard Widgets
- Historical Chart (time-range selector)
- Map widget (GPS devices)
- Alarm indicator
- Progress bar / circular progress
- Sparkline
- Camera/video placeholder
- Terminal/log viewer

### 5.3 Dashboard Templates
- Pre-built templates for common use cases (smart home, agriculture, weather)
- Dashboard duplication
- Dashboard import/export (JSON)

**Deliverable:** Full sensor/actuator management with all 22+ widget types.

---

## Phase 6: Visual Automation Engine

**Goal:** IFTTT-like visual rule builder.

### 6.1 Visual Rule Builder UI
- Trigger picker (sensor threshold, device state, schedule, webhook, manual)
- Condition builder (comparison operators, AND/OR, time window)
- Action picker (device command, notification, email, webhook, run scene)
- Delay and schedule configuration

### 6.2 Automation Backend Completion
- Schedule trigger evaluation (cron-based)
- Device online/offline triggers
- Multiple triggers per automation
- Multiple conditions with compound logic
- Action delay execution
- Loop prevention and idempotency

### 6.3 Automation Management
- Automation history/execution log screen
- Automation enable/disable toggle (already in DB)
- Automation templates
- Automation versioning

### 6.4 Scenes
- Scene management screens
- Scene activation (execute all scene actions)
- Scene shortcuts on home screen

**Deliverable:** Users build automations visually without code. Schedule, threshold, and webhook triggers all work.

---

## Phase 7: AI Assistant Enhancement

**Goal:** Full Claude Bedrock and Grok integration with tool calling.

### 7.1 AI Tool Calling
- Define tool schemas (create_automation, send_command, query_telemetry)
- Implement tool execution in ai-assistant Edge Function
- Confirmation flow for destructive actions
- AI-generated automation proposals

### 7.2 Streaming Responses
- Server-sent events from Edge Function
- Streaming chat UI in Flutter

### 7.3 AI Features
- Token/cost tracking (fill usage_records table)
- Usage limits per user/project
- Model selection (Claude Sonnet vs Opus, Grok models)
- Prompt versioning
- Provider fallback (if Claude fails, try Grok)

### 7.4 AI Context
- Inject recent telemetry data into context
- Inject automation definitions
- Inject dashboard configuration
- Firmware generation assistance

**Deliverable:** AI assistant can analyze data, suggest automations, control devices (with confirmation), and generate firmware code.

---

## Phase 8: Integrations (Alexa, Google Home)

**Goal:** Voice control and third-party integrations.

### 8.1 Alexa Smart Home
- Lambda handler for Smart Home Skill API
- OAuth 2.0 account linking
- Device discovery (SYNC)
- PowerController, RangeController
- State reporting
- Setup documentation

### 8.2 Google Home Cloud-to-cloud
- Fulfillment endpoint (SYNC, QUERY, EXECUTE, DISCONNECT)
- OAuth account linking
- Device trait mapping
- Setup documentation

### 8.3 Integration Management UI
- Integration list screen
- Integration configuration screens
- Integration event log

**Deliverable:** Voice control via Alexa and Google Home. Integration management in-app.

---

## Phase 9: Hardware Lab & Beginner Guides

**Goal:** Complete the "Learn IoT" experience.

### 9.1 Device Studio Enhancement
- Interactive pin assignment UI
- Wiring diagram generator
- Code preview with syntax highlighting
- One-click copy/download generated firmware
- Library dependency list

### 9.2 Arduino IDE Tutorials
- Step-by-step tutorial screens for each supported board
- Board overview, setup, connection, pairing flow
- Troubleshooting guides with common error solutions

### 9.3 Documentation
- docs/ARDUINO_GUIDE.md
- docs/ESP32_GUIDE.md
- docs/ESP8266_GUIDE.md
- firmware/WIRING.md expansion (currently exists, needs per-example diagrams)

**Deliverable:** A beginner can follow in-app tutorials to connect their first ESP32/ESP8266.

---

## Phase 10: Notifications, OTA, Monitoring

**Goal:** Production-grade operational features.

### 10.1 Push Notifications
- Firebase Cloud Messaging setup
- Device offline alerts
- Sensor threshold alerts
- Automation failure alerts
- Notification preferences UI

### 10.2 OTA Architecture
- Firmware upload to Supabase Storage
- OTA deployment creation UI
- Device OTA notification via MQTT
- OTA progress tracking

### 10.3 Platform Features
- Organization management UI (create, invite, roles)
- API key management (user-level keys for external API access)
- Data export (CSV/JSON)
- User usage/quota dashboard
- Audit log viewer
- Admin dashboard

### 10.4 Monitoring
- System health endpoint
- Structured logging in Edge Functions
- MQTT broker metrics

**Deliverable:** Push notifications, OTA updates, org management, and admin tools.

---

## Phase 11: Security, Performance, QA

**Goal:** Production hardening.

### 11.1 Security
- Upgrade device credential hashing from SHA-256 to argon2
- Restrict CORS to production domains
- Add rate limiting to all user-facing Edge Functions
- Secret scanning in CI
- Dependency vulnerability scanning
- Input validation audit across all Edge Functions

### 11.2 Performance
- Database query optimization (EXPLAIN ANALYZE on hot paths)
- Telemetry table partitioning (by time)
- MQTT message batching
- Flutter app performance profiling
- Image/asset optimization

### 11.3 QA
- Widget tests for all screens (targeting >70% coverage)
- Integration tests (Flutter + Supabase)
- Edge Function automated tests
- PlatformIO compilation CI
- Firmware example verification
- End-to-end test: device registration -> telemetry -> automation -> notification

**Deliverable:** Hardened, tested, performance-optimized platform.

---

## Phase 12: Documentation & Release

**Goal:** Open-source GitHub release.

### 12.1 Documentation
- Complete all missing docs (INSTALLATION, API, DEPLOYMENT, TROUBLESHOOTING, etc.)
- THIRD_PARTY_NOTICES.md
- Fix license references (Apache 2.0 everywhere)
- Update CHANGELOG.md
- API reference documentation
- Deployment guide (Supabase Cloud, self-hosted)

### 12.2 Release Preparation
- Final test suite run
- Secret scan
- Build artifacts (APK, web, firmware)
- Release-readiness report
- GitHub release with artifacts
- Tag v0.2.0

**Deliverable:** Public GitHub release with complete documentation.

---

## Dependency Graph

```
Phase 3 (Devices + MQTT) ──┬──> Phase 4 (Dashboards)
                            ├──> Phase 5 (Sensors + Widgets)
                            ├──> Phase 6 (Automations)
                            └──> Phase 7 (AI Enhancement)
                                    │
Phase 8 (Integrations) <────────────┘
Phase 9 (Hardware Lab) ── independent, can parallel Phase 6-8
Phase 10 (Notifications + OTA) ── requires Phase 3+6
Phase 11 (Security + QA) ── after all features
Phase 12 (Docs + Release) ── final
```

---

## Estimated Effort

| Phase | Scope | Relative Size |
|---|---|---|
| Phase 3 | Device + MQTT end-to-end | Large |
| Phase 4 | Dashboard editor | Large |
| Phase 5 | Sensors + advanced widgets | Medium |
| Phase 6 | Visual automation builder | Large |
| Phase 7 | AI tool calling + streaming | Medium |
| Phase 8 | Alexa + Google Home | Large |
| Phase 9 | Hardware Lab + tutorials | Medium |
| Phase 10 | Notifications + OTA + org | Large |
| Phase 11 | Security + QA | Medium |
| Phase 12 | Docs + release | Small |
