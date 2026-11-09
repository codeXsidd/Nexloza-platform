# Digital Twin API

## Overview

The Digital Twin API is provided by `DigitalTwinRepository`, which performs CRUD operations on the `device_twin_state` table via Supabase. It is accessed in Flutter through the `digitalTwinRepositoryProvider` Riverpod provider.

## Repository Methods

### getState

```dart
Future<Result<DigitalTwinState>> getState(String deviceId)
```

Retrieves the twin state for a device. Returns `ResultFailure(ServerFailure(...))` if not found or on error.

### createState

```dart
Future<Result<DigitalTwinState>> createState(String deviceId)
```

Creates a new twin state row with empty reported/desired state, version 0, and sync_status 'synced'. Called automatically during virtual device provisioning.

### updateReported

```dart
Future<Result<DigitalTwinState>> updateReported(
  String deviceId,
  Map<String, dynamic> attributes,
)
```

Merges `attributes` into `reported_state`, increments `reported_version`, and performs automatic reconciliation:

1. Fetches current twin state.
2. Merges new attributes into existing `reported_state`.
3. Increments `reported_version` by 1.
4. Compares merged reported state against `desired_state`.
5. If all desired keys match reported values: sets `sync_status = 'synced'` and updates `last_sync_at`.
6. Otherwise: sets `sync_status = 'pending'`.
7. Updates the row and returns the new state.

### updateDesired

```dart
Future<Result<DigitalTwinState>> updateDesired(
  String deviceId,
  Map<String, dynamic> attributes, {
  required int expectedVersion,
})
```

Merges `attributes` into `desired_state` with optimistic concurrency control:

1. Fetches current twin state.
2. Compares `desired_version` against `expectedVersion`.
3. If mismatch: returns `ResultFailure(ValidationFailure('Version conflict'))`.
4. Merges new attributes into existing `desired_state`.
5. Increments `desired_version` by 1.
6. Sets `sync_status = 'pending'`.
7. Updates the row and returns the new state.

### setSyncStatus

```dart
Future<Result<void>> setSyncStatus(
  String deviceId,
  TwinSyncStatus status,
)
```

Directly sets the sync status. Used for marking a twin as 'failed' or 'stale' from external triggers (e.g., command timeout handler).

### watchState

```dart
Stream<DigitalTwinState> watchState(String deviceId)
```

Returns a Supabase Realtime stream that emits on any change to the twin state row. Used by `digitalTwinProvider` for live UI updates.

## Data Types

### DigitalTwinState

| Field | Type | Description |
|-------|------|-------------|
| id | String | UUID primary key |
| deviceId | String | Foreign key to devices table |
| reportedState | Map<String, dynamic> | Last known device state |
| desiredState | Map<String, dynamic> | Target device state |
| reportedVersion | int | Monotonically increasing version for reported |
| desiredVersion | int | Monotonically increasing version for desired |
| reportedAt | DateTime? | When reported state was last updated |
| desiredAt | DateTime? | When desired state was last updated |
| syncStatus | TwinSyncStatus | Current sync status |
| lastSyncAt | DateTime? | Last successful sync timestamp |
| createdAt | DateTime | Row creation timestamp |
| updatedAt | DateTime | Row update timestamp (auto-updated) |

### TwinSyncStatus

| Value | Description |
|-------|-------------|
| synced | Reported state matches all desired attributes |
| pending | Desired state updated but not yet confirmed |
| failed | Command failed or timed out |
| stale | Device has not reported within threshold |

### TwinAttribute

Helper class for individual state attributes:

| Field | Type | Description |
|-------|------|-------------|
| key | String | Attribute identifier |
| value | dynamic | Attribute value |
| updatedAt | DateTime | When this attribute was last set |

## Providers

### digitalTwinRepositoryProvider

```dart
final digitalTwinRepositoryProvider = Provider<DigitalTwinRepository>((ref) { ... });
```

Singleton repository instance. Depends on `supabaseClientProvider`.

### digitalTwinProvider

```dart
final digitalTwinProvider = FutureProvider.family<DigitalTwinState?, String>((ref, deviceId) { ... });
```

Fetches the current twin state for a given device ID. Returns null if not found.

## Error Handling

All repository methods return `Result<T>`:

- `Success<T>` — Operation succeeded with value.
- `ResultFailure` — Operation failed with a `Failure` subtype:
  - `ServerFailure` — Database or network error.
  - `ValidationFailure` — Version conflict or invalid input.

## RLS Policies

All operations are subject to Supabase Row Level Security:

| Operation | Required Role |
|-----------|--------------|
| SELECT | Project member (via device → project join) |
| INSERT | Project developer |
| UPDATE | Project developer |
| DELETE | Project developer |

## Concurrency Model

The twin uses optimistic concurrency control for desired state updates:

1. Client reads current `desired_version` when loading the twin.
2. Client sends update with `expectedVersion` matching what it read.
3. If another client updated between read and write, the version check fails.
4. The client must re-read and retry.

Reported state updates do not use version checks — the latest report from the device always wins.
