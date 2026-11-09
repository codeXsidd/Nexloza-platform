# Phase 5 Audit — Flutter Project, Device Management and Onboarding

**Date:** 2026-11-09
**Baseline:** commit db2cd21, branch main, 224/224 tests passing

## Existing Architecture

### Flutter App Structure
- **Architecture:** Clean Architecture, feature-first
- **State Management:** Riverpod (AsyncNotifier, StateNotifier, FutureProvider, StreamProvider)
- **Navigation:** GoRouter with StatefulShellRoute (5-tab bottom nav: Home, Projects, Devices, Automations, AI)
- **Backend:** Supabase (Auth, PostgreSQL, Realtime, Edge Functions, RLS)
- **MQTT:** mqtt_client 10.6.0 with MqttService singleton
- **Theme:** Material 3 with light/dark support

### Supabase Backend (26+ tables, 6 Edge Functions)
- Tables: profiles, organizations, organization_members, projects, project_members, devices, device_credentials, device_groups, device_group_members, sensor_definitions, actuator_definitions, telemetry, device_commands, command_results, dashboards, dashboard_widgets, automations (4 tables), scenes (2 tables), notifications (2 tables), integrations (2 tables), ai_conversations, ai_messages, audit_logs, firmware_versions, ota_deployments, invitations
- Edge Functions: device-auth, device-command, telemetry-ingest, ai-assistant, automation-engine, webhook-handler
- All tables have RLS enabled with helper functions (is_org_member, is_project_member, can_modify_project)

### Shared Widgets (13 files)
- AppButton, AppTextField, AppScaffold, ConfirmationDialog, EmptyStateWidget, AppErrorWidget, LoadingIndicator, StatusBadge, NotFoundScreen
- Models: Result (sealed), AppUser
- Providers: supabase_provider, connectivity_provider

---

## Feature Inventory

### 1. Authentication — COMPLETE
- Login, Register, Forgot Password, Email Verification, Splash
- Auth state via StateNotifier with onAuthStateChange listener
- GoRouter redirect guards for auth/unauth routes

### 2. Project Management — BASIC CRUD EXISTS
**Working:**
- List projects (paginated)
- Create project (name, description, category dropdown)
- View project detail (name, category, description, created date, device count, active status)
- Edit project (name, description, category, active toggle)
- Delete project with confirmation
- Project entity has: id, name, description, category, icon, organizationId, ownerId, settings, isActive, createdAt, updatedAt, deviceCount, onlineDeviceCount
- Categories: Smart Home, Smart Agriculture, Industrial Monitoring, Smart Irrigation, Weather Monitoring, Smart Energy, Water Management, Health & Environment, Security, Custom

**Missing:**
- Search and filter on projects screen
- Archive functionality (soft deactivate)
- Duplicate project
- Project templates with suggested configurations
- Project switching (active project context)
- Project member management UI (table exists: project_members)
- Project settings screen
- Project activity view
- Device/sensor counts on project cards (deviceCount field exists but not populated from query)
- Online device count display

### 3. Device Management — GOOD FOUNDATION
**Working:**
- Device CRUD (add, list, detail, edit, delete)
- Device entity: id, projectId, name, deviceType, hardwarePlatform, firmwareVersion, macAddress, isOnline, lastSeenAt, metadata
- HardwarePlatform enum: esp32, esp8266, raspberryPi, arduino, genericMqtt, other
- Credential provisioning (apiKey nxl_xxx, apiSecret, SHA-256 hash)
- Credential display dialog with copy
- Device repository with realtime watch
- DevicesNotifier (AsyncNotifier) with full CRUD
- projectDevicesProvider (family by projectId)

**Missing:**
- Devices screen shows ALL devices (not project-filtered) — uses devicesProvider instead of projectDevicesProvider
- No search or filter
- No device grouping (table device_groups exists, no UI)
- No device categories UI
- Device pairing screen is PLACEHOLDER (both buttons are no-ops)
- No wizard-style onboarding flow
- No QR code support (qr_flutter not installed)
- No hardware-specific setup instructions in app
- No connection diagnostics
- No MQTT connection status displayed
- No signal strength display
- No stale-data indicators

### 4. Device Detail Screen — FUNCTIONAL BUT INCOMPLETE
**Working (752 lines):**
- Device info card (name, status badge, platform, type, firmware, MAC, last-seen)
- Telemetry section (latest readings per sensor key)
- Sensors list with type and latest value
- Actuators list with inline controls (Switch for toggle, dialog for others)
- Commands section (recent 5 with status icons)
- Send Command dialog (type + JSON payload)
- Popup menu: credentials, manage sensors, manage actuators, delete
- Credential management (list, generate new, copy, revoke)

**Missing:**
- MQTT connection state indicator
- Tabbed layout for better organization
- Diagnostics section
- Command pending/ack state on actuator controls
- Firmware version emphasis
- Config section
- Recent events timeline

### 5. Sensor Management — BASIC
**Working:**
- SensorDefinition entity: 24 sensor types, full field set (thresholds, calibration, sampling, metadata)
- SensorRepository: CRUD operations
- ManageSensorsScreen: add (name, telemetry key, type, unit) and delete with confirmation
- deviceSensorsProvider and projectSensorsProvider

**Missing:**
- Edit sensor dialog
- Threshold configuration UI (warningThresholdLow/High, criticalThresholdLow/High)
- Sampling interval configuration
- Calibration UI
- Min/max value configuration
- Precision configuration
- Sensor availability/error display
- Latest reading display in manage screen

### 6. Actuator Management — BASIC
**Working:**
- ActuatorDefinition entity: 16 actuator types, 6 control types, safety limits, current state
- ActuatorRepository: CRUD operations
- ManageActuatorsScreen: add (name, command key, actuator type, control type) and delete with confirmation
- deviceActuatorsProvider

**Missing:**
- Edit actuator dialog
- Min/max/step configuration
- Safety limits configuration
- Telemetry key configuration
- Command state tracking in UI (pending → ack → executed → failed)
- Actual-state feedback display

### 7. MQTT Integration — WELL-STRUCTURED
**Working:**
- MqttService: connect, subscribe, publish, disconnect, auto-reconnect
- Status stream (disconnected, connecting, connected, error)
- Message stream
- DeviceMqttController: subscribes to telemetry, status, command-ack, state topics (all v1 canonical)
- Command-ack processing (updates command status via repository)
- mqttStatusProvider and mqttMessagesProvider

**Missing:**
- MQTT connection status not shown in any UI
- No pending command indicators
- No stale data warnings
- DeviceMqttController not automatically activated when viewing device detail

### 8. Duplicate Entities — NEEDS CLEANUP
- `lib/features/sensors/domain/entities/sensor_entity.dart` (85 lines) — STALE duplicate of `lib/features/devices/domain/entities/sensor_entity.dart` (182 lines). Uses String type instead of enum, missing fields.
- `lib/features/actuators/domain/entities/actuator_entity.dart` (85 lines) — STALE duplicate of `lib/features/devices/domain/entities/actuator_entity.dart` (184 lines). Uses String type instead of enum, missing fields.
- Neither `lib/features/sensors/presentation/` nor `lib/features/actuators/presentation/` contains screens (empty dirs).

### 9. Tests — UNIT ONLY
- 224 tests in single file `test/widget_test.dart`
- All unit tests: AppConstants, MqttConstants, Validators, StringExtensions, DateTimeExtensions, Result, Exceptions, HardwarePlatform, Project, Device, Automation, AppNotification, Scene, Theme, RouteNames
- No widget tests, no provider tests, no integration tests

---

## Issues Found (23)

| # | Severity | Area | Issue |
|---|----------|------|-------|
| 1 | High | Devices | DevicesScreen uses unfiltered devicesProvider instead of projectDevicesProvider |
| 2 | High | Devices | Device pairing screen is placeholder (empty onPressed handlers) |
| 3 | High | Onboarding | No device onboarding wizard exists |
| 4 | Medium | Projects | No search or filter on projects screen |
| 5 | Medium | Projects | No project templates for beginners |
| 6 | Medium | Projects | No project member management UI |
| 7 | Medium | Projects | No archive/duplicate functionality |
| 8 | Medium | Devices | No search or filter on devices screen |
| 9 | Medium | Devices | No device grouping UI (backend table exists) |
| 10 | Medium | Sensors | No edit dialog for sensors |
| 11 | Medium | Sensors | No threshold/sampling/calibration configuration UI |
| 12 | Medium | Actuators | No edit dialog for actuators |
| 13 | Medium | Actuators | No min/max/step/safety limits configuration |
| 14 | Medium | Actuators | Command controls don't show pending/ack state |
| 15 | Medium | MQTT | No MQTT connection status in any UI screen |
| 16 | Medium | MQTT | DeviceMqttController not activated from device detail |
| 17 | Medium | Detail | Device detail lacks tabbed organization |
| 18 | Low | Entities | Duplicate stale sensor/actuator entities in separate feature dirs |
| 19 | Low | Projects | deviceCount not populated from query (always 0) |
| 20 | Low | Projects | No project activity view |
| 21 | Low | Detail | No diagnostics section |
| 22 | Low | UI | No stale-data indicators anywhere |
| 23 | Low | Tests | No widget, provider, or integration tests |
