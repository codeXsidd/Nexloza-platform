# Phase 9 — Alarm Data Model and Lifecycle

## Alarm Lifecycle

```
             raise / re-raise
                  |
                  v
             +---------+
             |  ACTIVE  |
             +---------+
              |       |
   acknowledge|       | clear (with reason)
              v       v
     +-------------+  +---------+
     | ACKNOWLEDGED |->| CLEARED |
     +-------------+  +---------+
              clear
```

### Key Invariant

**Acknowledged is NOT cleared.** An acknowledged alarm remains visible and actionable. Only an explicit clear (with a recorded reason) transitions an alarm to the cleared state.

A user cannot manually clear a condition that should remain active without recording that it was manually cleared.

## Alarm Fields

| Field | Type | Purpose |
|-------|------|---------|
| id | uuid | Primary key |
| alarm_key | text | Stable key for deduplication (unique per project) |
| project_id | uuid | Owning project (FK, RLS boundary) |
| device_id | uuid | Source device (nullable) |
| organization_id | uuid | Owning organization |
| severity | enum | critical / high / medium / warning / informational |
| status | enum | active / acknowledged / cleared |
| source | enum | One of 9 alarm sources |
| title | text | Human-readable alarm title |
| message | text | Optional detail message |
| category | text | User-defined grouping (e.g. "temperature") |
| condition_value | float | Value that triggered the alarm |
| threshold_value | float | Configured threshold |
| hysteresis_clear_value | float | Value at which alarm auto-clears |
| acknowledged_by | uuid | User who acknowledged |
| acknowledged_at | timestamptz | When acknowledged |
| cleared_by | uuid | User or system that cleared |
| cleared_at | timestamptz | When cleared |
| cleared_reason | text | Required reason for clearing |
| occurrence_count | int | How many times this alarm was raised |
| first_occurred_at | timestamptz | First raise timestamp |
| last_occurred_at | timestamptz | Most recent raise timestamp |
| data | jsonb | Arbitrary metadata |
| escalation_policy_id | uuid | Linked escalation policy |
| escalation_stage | int | Current escalation stage |

## Stable Alarm Key

The alarm key prevents alarm storms by deduplicating re-raises. Format:

```
{source}:{project_id}:{device_id}:{sensor_key}:{category}
```

When a `raiseAlarm` action fires with a key that matches an active or acknowledged alarm, the existing alarm's `occurrence_count` is incremented and `last_occurred_at` is updated. No duplicate alarm is created.

## Severity Levels

| Severity | Sort Order | Color | Use Case |
|----------|-----------|-------|----------|
| critical | 0 | Red | Immediate action required |
| high | 1 | Deep Orange | Urgent but not immediate |
| medium | 2 | Orange | Notable condition |
| warning | 3 | Amber | Informational warning |
| informational | 4 | Blue | Record-keeping only |

## AlarmStats

Computed from active + acknowledged alarms for dashboard display:
- totalActive, criticalCount, highCount, mediumCount, warningCount, informationalCount
- acknowledgedCount (acknowledged but not cleared)
- unacknowledgedCount (active only, not yet acknowledged)
