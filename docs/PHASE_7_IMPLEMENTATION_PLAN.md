# Phase 7 Implementation Plan — Virtual Devices and Digital Twin System

**Date:** 2026-11-09
**Baseline:** 403 tests, 0 analyzer issues, commit `5c2dd10`

---

## Layer 1: Database Migration (00018)

**File:** `backend/supabase/migrations/00018_virtual_devices_phase7.sql`

Changes to `devices` table:
- `is_virtual BOOLEAN DEFAULT false NOT NULL`
- `simulation_profile TEXT` (nullable — only set for virtual devices)

New table `device_twin_state`:
- `id UUID PK`
- `device_id UUID FK → devices(id) ON DELETE CASCADE` (unique)
- `reported_state JSONB DEFAULT '{}'`
- `desired_state JSONB DEFAULT '{}'`
- `reported_version INT DEFAULT 0`
- `desired_version INT DEFAULT 0`
- `reported_at TIMESTAMPTZ`
- `desired_at TIMESTAMPTZ`
- `sync_status TEXT DEFAULT 'synced'` (synced, pending, failed, stale)
- `last_sync_at TIMESTAMPTZ`
- `created_at TIMESTAMPTZ DEFAULT now()`
- `updated_at TIMESTAMPTZ DEFAULT now()`

RLS policies for `device_twin_state`:
- Project members can view (via device → project join)
- Project developers can insert/update/delete

Index: `device_id` (unique), `sync_status`

## Layer 2: Domain Entities

**Simulation profiles** — 6 profiles defining sensors, actuators, value ranges, simulation models:
1. Smart Home
2. Agriculture
3. Weather Station
4. Energy Monitoring
5. Industrial Equipment
6. Water Management

**Digital twin entities:**
- `DigitalTwinState` — reported/desired JSONB, versions, sync status, timestamps
- `TwinSyncStatus` enum — synced, pending, failed, stale
- `TwinAttribute` — key, value, updatedAt for individual attributes

**Simulator entities:**
- `SimulatorState` enum — idle, running, paused, stopped
- `FaultScenario` enum — deviceOffline, sensorFailure, outOfRange, networkInterrupt, commandTimeout
- `SimulatedSensor` — current value, model parameters, active faults

## Layer 3: Simulation Engine

`SimulatorEngine` — manages per-device simulation timers:
- `startSimulation(deviceId, profile)` — creates timer, initializes state
- `pauseSimulation(deviceId)` — pauses timer, preserves state
- `resumeSimulation(deviceId)` — resumes timer
- `stopSimulation(deviceId)` — stops timer, cleans up
- `resetSimulation(deviceId)` — resets to initial profile values
- `setSpeed(deviceId, multiplier)` — 0.5x to 10x
- `enableFault(deviceId, sensorKey, fault)` / `disableFault()`
- Deterministic value generation with controllable seed
- Bounded telemetry publishing (configurable interval, default 5s)

**Value models:**
- Gradual drift (temperature) — random walk within bounds
- Decay/recovery (soil moisture) — decreases over time, increases on irrigation
- Binary response (motion) — random events with configurable probability
- Correlated (motor vibration ↔ RPM) — linked variables
- Step response (fan speed) — responds to command with transition time

## Layer 4: Digital Twin Service

`DigitalTwinRepository` — Supabase CRUD:
- `getState(deviceId)` → `DigitalTwinState`
- `updateDesired(deviceId, attributes, version)` → with version check
- `updateReported(deviceId, attributes)` → from simulator/device
- `setSyncStatus(deviceId, status)`

`DigitalTwinService` — business logic:
- `reconcile(deviceId)` — compare desired vs reported, identify mismatches
- `handleCommandAck(deviceId, commandKey, success)` — update sync status
- `checkStale(deviceId, threshold)` — mark stale if reported_at too old

## Layer 5: Virtual Device Repository

`VirtualDeviceRepository` — extends device provisioning:
- `createVirtualDevice(projectId, name, profileType)`:
  1. Insert device with `is_virtual=true`, `hardware_platform='generic_mqtt'`
  2. Create sensor definitions from profile
  3. Create actuator definitions from profile
  4. Provision device credentials
  5. Initialize twin state
  6. Return complete virtual device info
- `getVirtualDevices(projectId)` — filter `is_virtual=true`
- `deleteVirtualDevice(deviceId)` — cascade handles cleanup

## Layer 6: Presentation

**Screens:**
- `VirtualDevicesScreen` — list with create FAB, profile badges
- `CreateVirtualDeviceScreen` — profile selector, name/description form
- `SimulatorControlScreen` — start/pause/stop, speed, per-sensor enable, fault controls
- `DigitalTwinScreen` — desired vs reported comparison, sync status, command history

**Providers (Riverpod):**
- `virtualDevicesProvider` — list per project
- `simulatorEngineProvider` — singleton engine
- `simulatorStateProvider(deviceId)` — per-device state
- `digitalTwinProvider(deviceId)` — twin state

**Routes:**
- `/virtual-devices` — list
- `/virtual-devices/create` — create flow
- `/virtual-devices/:id/simulator` — simulator controls
- `/virtual-devices/:id/twin` — digital twin view

## Layer 7: Dashboard Integration

No changes needed to Phase 6 dashboard code. Virtual devices are standard devices with `is_virtual=true`, so:
- `DataSourceSelector` already lists devices from `projectDevicesProvider`
- `TelemetryDataService` already subscribes to telemetry by device_id
- Widget renderers already consume `WidgetDataState`

Add visual indicator in `DataSourceSelector` for virtual devices (icon badge).

## Layer 8: Tests

Target: 403 existing + ~120 new Phase 7 tests:
- Simulation profile definitions (6 × ~5 tests)
- Simulator engine (start/pause/stop/reset/speed/fault ~20 tests)
- Digital twin state (CRUD, versioning, reconciliation ~15 tests)
- Virtual device provisioning (~10 tests)
- Domain entities (fromJson/toJson, enums, validation ~20 tests)
- Widget/screen tests (~15 tests)
- Integration/regression tests (~10 tests)

## Execution Order

1. Migration → Domain entities → Tests (verify entities)
2. Simulation engine → Digital twin service → Tests (verify services)
3. Virtual device repository → Presentation → Tests (verify UI)
4. Dashboard integration verification
5. Full test suite + analyzer + build
6. Documentation
7. Commit and push
