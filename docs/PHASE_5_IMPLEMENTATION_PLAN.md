# Phase 5 Implementation Plan

## Approach
Reuse all existing working code. Enhance screens, add missing UI, wire up existing providers. No unnecessary rewrites.

## Step 1: Cleanup — Consolidate Duplicate Entities
- Delete stale `lib/features/sensors/domain/entities/sensor_entity.dart`
- Delete stale `lib/features/actuators/domain/entities/actuator_entity.dart`
- Update any imports referencing the old paths
- Verify no screens exist in those feature dirs (confirmed empty)

## Step 2: Project Management Enhancements
- Add search bar and category filter to ProjectsScreen
- Add project templates to CreateProjectScreen (template selector step before form)
- Enhance ProjectDetailScreen with device count, online count, sensors, activity section
- Add archive toggle (is_active) to project detail
- Add project members section (read-only, using project_members table)
- Populate deviceCount via Supabase count query or join
- Enhance ProjectCard with device count and status indicators

## Step 3: Device Management Enhancements
- Refactor DevicesScreen to filter by current project context OR show all with project labels
- Add search bar and hardware platform filter
- Add device grouping support (using existing device_groups table)
- Enhance device cards with last-seen, firmware version

## Step 4: Device Onboarding Wizard
- Replace placeholder DevicePairingScreen with multi-step wizard
- Step 1: Select project
- Step 2: Select hardware platform (visual cards)
- Step 3: Hardware-specific setup instructions (wiring, SDK install)
- Step 4: Create device + provision credentials via existing backend
- Step 5: Display credentials with copy (existing dialog logic, enhanced)
- Step 6: Show firmware configuration instructions
- Step 7: Wait for device auth (poll device online status)
- Step 8: Success screen with links to sensor/actuator setup
- Add QR code generation for credentials (add qr_flutter package)
- Timeout and retry support
- Manual pairing code fallback

## Step 5: Device Detail Improvements
- Reorganize into tabbed layout (Overview, Sensors, Actuators, Commands, Config)
- Add MQTT connection status indicator (wire DeviceMqttController)
- Add command state tracking on actuator controls (pending → ack → success/fail)
- Add diagnostics section (connection log, error history)
- Add stale-data indicator when device is offline
- Auto-subscribe to device MQTT topics when viewing detail

## Step 6: Sensor Management Enhancements
- Add edit dialog (all fields: name, type, unit, sampling, min/max, thresholds, calibration)
- Add threshold configuration with visual indicators
- Add sampling interval picker
- Show latest reading and sensor status
- Show availability indicator

## Step 7: Actuator Management Enhancements
- Add edit dialog (all fields: name, type, control type, command key, min/max, step, safety)
- Add command state tracking (pending/ack/executed/failed/timeout badges)
- Show actual state from MQTT state topic
- Safety limits configuration
- Prevent command when device is offline (with override option)

## Step 8: MQTT Status in UI
- Add connection status indicator to AppScaffold or home screen
- Show MQTT status on device cards
- Wire DeviceMqttController into device detail lifecycle
- Display pending command count
- Stale data warnings when last-seen exceeds threshold

## Step 9: Testing
- Preserve existing 224 tests
- Add project entity tests (templates, categories enhancement)
- Add device onboarding flow tests
- Add sensor/actuator entity enhancement tests
- Add command state tests
- Add MQTT constants coverage for new functionality
- Add widget tests for key screens where feasible without Supabase

## Step 10: Documentation
- docs/PROJECT_MANAGEMENT_GUIDE.md
- docs/DEVICE_MANAGEMENT_GUIDE.md
- docs/DEVICE_PAIRING_GUIDE.md
- docs/SENSOR_CONFIGURATION_GUIDE.md
- docs/ACTUATOR_CONFIGURATION_GUIDE.md
- docs/ANDROID_SETUP.md
- docs/DEVICE_TROUBLESHOOTING.md

## Step 11: Final Verification
- dart format
- flutter analyze
- flutter test
- Create PHASE_5_COMPLETION_REPORT.md
- Commit and push

## Constraints
- PlatformIO not installed — firmware compilation deferred to CI workflow
- No physical hardware — all testing via emulator and MQTT test clients
- Preserve all 224 existing tests
- Never expose credentials in Flutter
- Never bypass device authentication
