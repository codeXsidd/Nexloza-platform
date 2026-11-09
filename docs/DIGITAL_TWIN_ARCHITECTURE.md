# Digital Twin Architecture

## Concept

A digital twin maintains two parallel representations of a device's state:

- **Reported state** — The last known state as reported by the device (or simulator). Read-only from the user's perspective.
- **Desired state** — The target state set by an authorized user or automation. Represents what the device should become.

When desired and reported states diverge, the system tracks the delta and synchronization progress.

## Database Schema

Table: `device_twin_state` (migration 00018)

| Column | Type | Default | Description |
|--------|------|---------|-------------|
| id | UUID | gen_random_uuid() | Primary key |
| device_id | UUID (FK) | — | References devices(id), unique, cascade delete |
| reported_state | JSONB | '{}' | Key-value map of reported attributes |
| desired_state | JSONB | '{}' | Key-value map of desired attributes |
| reported_version | INT | 0 | Increments on each reported update |
| desired_version | INT | 0 | Increments on each desired update |
| reported_at | TIMESTAMPTZ | NULL | Last time reported state was updated |
| desired_at | TIMESTAMPTZ | NULL | Last time desired state was updated |
| sync_status | TEXT | 'synced' | One of: synced, pending, failed, stale |
| last_sync_at | TIMESTAMPTZ | NULL | Last successful synchronization |
| created_at | TIMESTAMPTZ | now() | Row creation |
| updated_at | TIMESTAMPTZ | now() | Auto-updated via trigger |

Constraints:
- `device_id` is unique (one twin per device)
- `sync_status` is checked against valid values

Indexes:
- `idx_twin_state_device` on `device_id`
- `idx_twin_state_sync` on `sync_status` where not synced

## Sync Status Lifecycle

```
                   ┌─────────┐
           ┌──────>│ synced  │<──────┐
           │       └────┬────┘       │
           │            │            │
     reported matches   │ desired    │ reported matches
     desired            │ changed    │ new desired
           │            v            │
           │       ┌─────────┐       │
           └───────│ pending │───────┘
                   └────┬────┘
                        │
              command fails │ or timeout
                        v
                   ┌─────────┐
                   │ failed  │
                   └────┬────┘
                        │
              reported_at too old
                        v
                   ┌─────────┐
                   │  stale  │
                   └─────────┘
```

- **synced** — Reported state matches all desired attributes. `last_sync_at` is set.
- **pending** — Desired state was updated but reported has not yet confirmed. A command may be in flight.
- **failed** — A command failed or timed out before the device confirmed the change.
- **stale** — The device has not reported state within a configurable threshold.

## Version Concurrency

Both `reported_version` and `desired_version` are monotonically incrementing integers.

When updating desired state, the caller must provide an `expectedVersion`. If the current `desired_version` does not match, the update is rejected with a `ValidationFailure("Version conflict")`. This prevents older updates from silently overwriting newer desired state.

Reported state updates do not require version checks — they are always accepted as the latest device truth.

## State Reconciliation

`DigitalTwinRepository.updateReported()` performs automatic reconciliation:

1. Merge incoming attributes into existing `reported_state`.
2. Increment `reported_version`.
3. Compare merged reported state against `desired_state`.
4. If all desired keys match their reported counterparts, set `sync_status = 'synced'` and update `last_sync_at`.
5. Otherwise, keep `sync_status = 'pending'`.

The `getMismatches()` method on `DigitalTwinState` returns the list of keys where desired and reported values differ.

## Data Flow

```
User sets desired state
        │
        v
DigitalTwinRepository.updateDesired()
  ├── version check
  ├── merge into desired_state
  ├── set sync_status = 'pending'
  └── increment desired_version
        │
        v
Command sent via CommandRepository
        │
        v
MQTT: nexloza/v1/{org}/{proj}/{device}/command
        │
        v
Virtual device (SimulatorEngine) or physical device
  ├── validates command
  ├── updates internal state
  └── publishes telemetry with new values
        │
        v
Telemetry ingested (telemetry-ingest Edge Function or TelemetryPublisher)
        │
        v
DigitalTwinRepository.updateReported()
  ├── merge into reported_state
  ├── compare with desired_state
  └── set sync_status = 'synced' or 'pending'
```

## RLS Policies

| Operation | Policy |
|-----------|--------|
| SELECT | Project members can view (via device → project join) |
| INSERT | Project developers can create |
| UPDATE | Project developers can update |
| DELETE | Project developers can delete |

All policies join through the `devices` table to verify project membership via `is_project_member()` or `can_modify_project()`.

## Integration with Existing Pipeline

The digital twin does not replace the existing command or telemetry pipeline. It sits alongside them:

- Commands are still sent via the `device-command` Edge Function.
- Telemetry is still ingested via the `telemetry-ingest` Edge Function (for physical devices) or `TelemetryPublisher` (for virtual devices).
- The twin state is updated as a side effect of telemetry arrival and command issuance.
- Dashboard widgets continue to read from `TelemetryDataService`, not from the twin state directly.

The twin provides a state comparison view, not a replacement data source.
