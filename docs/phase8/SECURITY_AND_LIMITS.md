# Phase 8 — Security Model and Rate Limits

## Backend-Only Execution

Rule graphs are evaluated exclusively in the `automation-engine` Supabase Edge Function. The Flutter application is a graph editor and monitoring client only — it never evaluates rule logic, sends device commands directly, or holds the credentials required to do so.

```
Flutter Client                    Supabase Edge Function
┌─────────────────┐              ┌─────────────────────┐
│ Visual Editor   │   JWT auth   │ automation-engine    │
│ (read/write     │──────────▶  │ (service-role key)   │
│  rule_graph)    │              │                      │
│                 │              │ Evaluates graph      │
│ Execution       │              │ Inserts commands     │
│ Viewer          │              │ Updates twin state   │
│ (read only)     │              │ Activates scenes     │
└─────────────────┘              └─────────────────────┘
```

**Why this matters**: If rule evaluation ran in Flutter, a malicious actor could tamper with evaluation logic, bypass conditions, or execute unauthorized commands. Server-side execution ensures the evaluation path is not modifiable by the client.

## Service Role Isolation

| Credential | Location | Exposure |
|---|---|---|
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Function environment only | Never sent to Flutter, never in source code |
| `SUPABASE_ANON_KEY` | Flutter app | Public key, safe to embed |
| JWT (user token) | Flutter ↔ Edge Function | Used to authenticate the user, verify project membership |

The Edge Function authenticates the user via their JWT, then uses the service-role key to perform privileged operations (inserting `device_commands`, updating `device_twin_state`, reading across RLS boundaries for rule evaluation).

**Security invariant**: The Flutter application never holds or transmits the service-role key.

## Row-Level Security (RLS)

All Phase 8 tables have RLS policies that enforce project membership:

### automations
```sql
-- SELECT: user must be a project member
CREATE POLICY "automations_select" ON automations
  FOR SELECT USING (is_project_member(auth.uid(), project_id));

-- INSERT/UPDATE/DELETE: user must have modify permission
CREATE POLICY "automations_modify" ON automations
  FOR ALL USING (can_modify_project(auth.uid(), project_id));
```

### rule_versions
```sql
-- SELECT: accessible if the parent automation is accessible
CREATE POLICY "rule_versions_select" ON rule_versions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM automations
      WHERE id = rule_versions.automation_id
        AND is_project_member(auth.uid(), project_id)
    )
  );

-- INSERT: only via Edge Function (service role bypasses RLS)
```

### rule_events
```sql
-- SELECT: user must be a project member
CREATE POLICY "rule_events_select" ON rule_events
  FOR SELECT USING (is_project_member(auth.uid(), project_id));

-- INSERT: only via Edge Function
```

### automation_executions
```sql
-- SELECT: accessible via parent automation's project membership
CREATE POLICY "executions_select" ON automation_executions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM automations
      WHERE id = automation_executions.automation_id
        AND is_project_member(auth.uid(), project_id)
    )
  );
```

## Graph Import Validation

When a graph is saved or imported, the `RuleGraphValidator` runs before persisting:

| Check | Prevents |
|---|---|
| Trigger count (exactly 1) | Malformed graphs with no entry point or multiple competing triggers |
| Required config keys | Nodes that would fail at runtime due to missing configuration |
| Edge validity | References to non-existent nodes or ports |
| Self-referencing edges | Trivial infinite loops |
| Cycle detection (DFS) | Non-trivial infinite loops |
| Port type compatibility | Wiring mismatches that would produce runtime errors |
| Disconnected nodes | Orphaned logic that would never execute |

**No executable code**: Rule graphs are pure data structures (JSON with node types, edges, and config values). There is no mechanism to embed or execute arbitrary code through a graph. Node types are a fixed enum — unknown types default to `telemetryReceived` (the safest default, as it simply matches events).

## Device Scope Enforcement

Commands sent by rule actions are scoped to the automation's project:

1. Each automation belongs to a `project_id`
2. The Edge Function queries only automations matching the event's `project_id`
3. Device commands are inserted via the service role, but the target `device_id` must be a device the automation's project has access to (enforced by the `device_commands` RLS policy)

A rule in Project A cannot send commands to devices in Project B.

## MQTT Credential Isolation

The visual rule editor operates entirely through the Supabase REST API. It never:

- Creates MQTT connections
- Reads MQTT credentials
- Subscribes to MQTT topics
- Publishes MQTT messages

MQTT communication happens only between:
- Physical/virtual devices and the NanoMQ broker
- The telemetry-ingest Edge Function (which triggers rule evaluation)

## Rate Limits

### Per-Automation Limits

| Limit | Default | Configurable | Description |
|---|---|---|---|
| Cooldown | 60 seconds | Yes (`cooldown_seconds`) | Minimum time between consecutive executions |
| Hourly rate | 60/hour | Yes (`max_executions_per_hour`) | Maximum executions in a rolling 1-hour window |

Both limits apply only to non-dry-run executions. Dry runs are unlimited.

### Per-Correlation Limits

| Limit | Value | Description |
|---|---|---|
| Command throttle | 5 seconds per device | Within the same correlation, a device can receive at most one command per 5 seconds |
| Re-entry block | 1 concurrent per rule | The same rule cannot run twice simultaneously for the same correlation |

### System-Wide Limits

| Limit | Value | Description |
|---|---|---|
| Max execution depth | 5 | Maximum levels of cascading rule triggers |
| Delay ceiling | 10 seconds actual | Delays > 10s are logged but not awaited (Edge Function timeout constraint) |

## Depth Limit

The maximum execution depth is **5**. This prevents cascading rule chains from running indefinitely:

```
Event (depth=0) → Rule A fires → recordEvent action inserts new event (depth=1)
  → Rule B fires → sendCommand (depth=2) → ...
    → depth reaches 5 → any further child events are REJECTED
```

The depth counter is carried in the event payload and incremented by the Edge Function when creating child events.

## Idempotency

The `rule_events` table has a UNIQUE constraint on `idempotency_key`:

```sql
ALTER TABLE rule_events ADD CONSTRAINT rule_events_idempotency_unique
  UNIQUE (idempotency_key);
```

When an event arrives with an `idempotency_key` that already exists in the table, the Edge Function returns immediately with `{ processed: false, reason: "duplicate_event" }`.

This prevents:
- Duplicate processing from retried HTTP requests
- Re-processing of events during Edge Function cold starts
- Double-execution from race conditions in concurrent event delivery

## Input Validation

The Edge Function validates all incoming requests:

### Legacy mode
| Field | Validation |
|---|---|
| `device_id` | Required, must be a string |
| `sensor_key` | Required, must be a string |
| `value` | Required, must be a finite number |

### New rule event mode
| Field | Validation |
|---|---|
| `event_type` | Required (presence triggers new mode) |
| `project_id` | Required |
| `organization_id` | Required |
| `depth` | Optional, defaults to 0, must be ≤ 5 |
| `dry_run` | Optional, defaults to false |

## Threat Model Summary

| Threat | Mitigation |
|---|---|
| Client-side rule evaluation bypass | Rules only evaluate server-side |
| Service-role key leak | Never in Flutter, never in source code |
| Cross-project command injection | RLS + project_id scoping on all queries |
| Infinite loop / resource exhaustion | Depth limit (5), cooldown, rate limit, re-entry detection, command throttle |
| Duplicate event processing | Idempotency key deduplication |
| Arbitrary code in graph import | Graphs are data-only JSON; node types are a fixed enum; full validation before save |
| MQTT credential exposure | MQTT never used by the visual editor |
| XSS via node labels | Flutter renders text widgets, not HTML — immune to XSS by design |
| Unauthorized rule modification | RLS `can_modify_project` policy on automations table |
