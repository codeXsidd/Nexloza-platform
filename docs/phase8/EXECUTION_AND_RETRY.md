# Phase 8 — Execution Model and Retry Strategy

## Event Processing Flow

```
Event arrives (telemetry, device status, manual, scheduled)
    │
    ▼
┌───────────────────────────────┐
│ 1. Idempotency check          │
│    (rule_events.idempotency_  │
│     key UNIQUE constraint)    │
│    Duplicate? → reject        │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│ 2. Depth check                │
│    depth > 5? → reject        │
│    (prevents infinite loops)  │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│ 3. Insert into rule_events    │
│    status: 'processing'       │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│ 4. Query matching rules       │
│    project_id match           │
│    is_enabled = true          │
│    status IN (published,      │
│      enabled)                 │
│    rule_graph IS NOT NULL      │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│ 5. For each rule:             │
│    a. Re-entry check          │
│    b. Cooldown check          │
│    c. Rate limit check        │
│    d. Load published version  │
│    e. Evaluate graph          │
│    f. Record execution        │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│ 6. Update event status        │
│    status: 'completed'        │
│    processed_at: now()        │
└───────────────────────────────┘
```

## Graph Evaluation

### Topological Sort

Before evaluation, nodes are sorted in topological order using Kahn's algorithm (BFS-based). This ensures each node is evaluated only after all its upstream dependencies have been processed.

```
Trigger → Condition A → Condition B → Action
                    └→ Condition C → Action 2
```

In this example, the evaluation order would be: Trigger, Condition A, then Condition B and Condition C (both depend only on A), then the actions.

### Per-Node Evaluation

Each node is evaluated according to its category:

| Category | Behavior |
|---|---|
| **Trigger** | Compares the incoming event against the trigger's config (device_id, sensor_key, threshold). If the trigger doesn't fire, the entire rule execution aborts. |
| **Condition** | Evaluates the input value against the node's config. Synchronous conditions (comparisons, logic gates) compute immediately. Asynchronous conditions (deviceOnlineCheck, twinDesiredVsReported) perform database lookups. |
| **Action** | Executes side effects (device commands, twin updates, scene activations). Skipped in dry-run mode. Each action records success/failure in its node result. |
| **Flow Control** | Manages execution paths. `conditionalBranch` routes to true/false outputs. `delay` pauses execution. `merge` combines paths. `terminate` stops all execution. |

### Branch Skipping

When a `conditionalBranch` node evaluates, it marks the not-taken branch as skipped. All downstream nodes on a skipped branch are also skipped, and this propagation continues through the graph.

A node is skipped if **all** its incoming edges originate from skipped branches. If a node has multiple incoming edges and at least one is from a non-skipped path, the node is evaluated.

### Input Value Resolution

Each node receives an input value from its upstream connections:

1. The evaluator collects outputs from all nodes connected via incoming edges
2. The first non-null upstream output is used as the input value
3. For logic gate nodes (AND, OR), all incoming edge values are collected and evaluated together

## Loop Prevention

Five mechanisms prevent infinite loops:

### 1. Maximum Execution Depth (5)

Every event carries a `depth` counter. When a rule's action triggers another event (e.g., a `recordEvent` action), the child event's depth is incremented. If depth exceeds 5, the event is rejected.

```
Event (depth=0) → Rule A triggers → Event (depth=1) → Rule B triggers → ... → depth=5 → BLOCKED
```

### 2. Correlation IDs

Every event chain shares a single `correlation_id` (UUID). The first event in a chain generates the correlation ID; all downstream events inherit it. This allows tracing the complete execution lineage.

### 3. Re-Entry Detection

Before evaluating a rule, the engine checks if the same rule is already running for the same correlation ID:

```sql
SELECT id FROM automation_executions
WHERE automation_id = $rule_id
  AND correlation_id = $correlation_id
  AND status = 'running'
LIMIT 1
```

If a running execution is found, the rule is skipped for this event.

### 4. Per-Device Command Throttle

Within the same correlation, each device can receive at most one command per 5 seconds:

```
Throttle key: {correlation_id}:{device_id}
If last command was < 5000ms ago → throttled
```

This prevents a rule from rapid-firing commands to the same device.

### 5. Cycle Detection (Design Time)

The `RuleGraphValidator` uses depth-first search to detect cycles in the graph at design time. A graph with a cycle cannot be saved or published.

## Cooldown and Rate Limiting

### Per-Automation Cooldown

Each automation has a `cooldown_seconds` setting (default: 60). Before executing a rule, the engine checks for recent non-dry-run executions:

```sql
SELECT id FROM automation_executions
WHERE automation_id = $id
  AND dry_run = false
  AND started_at >= NOW() - INTERVAL '$cooldown_seconds seconds'
LIMIT 1
```

If a recent execution exists, the rule is skipped.

### Hourly Rate Limit

Each automation has a `max_executions_per_hour` setting (default: 60). The engine counts executions in the last hour:

```sql
SELECT COUNT(*) FROM automation_executions
WHERE automation_id = $id
  AND dry_run = false
  AND started_at >= NOW() - INTERVAL '1 hour'
```

If the count meets or exceeds the limit, the rule is skipped.

**Note**: Both cooldown and rate limit checks are bypassed for dry-run executions.

## Dry-Run Mode

Dry-run mode performs full graph evaluation without side effects:

| Component | Dry-Run Behavior |
|---|---|
| Trigger evaluation | Normal — fires or doesn't based on event |
| Condition evaluation | Normal — evaluates to true/false |
| sendCommand | Skips `device_commands` INSERT, reports what would have been sent |
| setActuator | Skips `device_commands` INSERT, reports what would have been set |
| updateTwinDesired | Skips `device_twin_state` UPDATE, reports what would have changed |
| executeScene | Skips scene activation, reports scene_id |
| recordEvent | Skips `rule_events` INSERT, reports event_name |
| Execution record | Created with `dry_run: true` — excluded from cooldown/rate-limit counts |

Dry-run is triggered by setting `dry_run: true` in the request body to the automation-engine Edge Function.

## Error Handling

### Per-Node Error Capture

Each node's evaluation result is captured in `node_results`:

```json
{
  "node_id": "node_3",
  "node_type": "sendCommand",
  "status": "failed",
  "output": null,
  "error": "Missing device_id",
  "evaluated_at": "2026-11-10T12:00:00Z"
}
```

If a node fails, subsequent nodes may still execute (unless the failed node was on their critical path).

### Execution-Level Error

If the entire graph evaluation throws an unhandled exception, the execution record is updated:

```json
{
  "status": "failed",
  "error_message": "Unhandled error during graph evaluation",
  "completed_at": "2026-11-10T12:00:01Z"
}
```

### Event-Level Error

If event processing fails entirely (before any rule evaluation), the `rule_events` record status remains `processing`. A future monitoring system could detect stale `processing` events and alert operators.

## Legacy Compatibility

The automation-engine Edge Function supports two request modes:

### Legacy Mode (no `event_type` field)

Receives `{ device_id, sensor_key, value }`:

1. Queries `automation_triggers` with `trigger_type = 'sensor_threshold'`
2. Evaluates gt/lt/eq/gte/lte/between operators against the value
3. Checks cooldown and rate limits
4. Executes `device_command` and `notification` actions
5. Records execution in `automation_executions`
6. **Also** forwards the event as a `telemetry_received` graph event for graph-based rules

### New Mode (`event_type` field present)

Full graph-based evaluation as described above.

Both modes coexist — a project can have legacy trigger-based automations and graph-based rules running simultaneously.

## Rule Versioning

### Immutable Published Versions

When a rule is published, an immutable snapshot is created in `rule_versions`:

```sql
INSERT INTO rule_versions (automation_id, version_number, graph_snapshot, published_at, published_by)
VALUES ($id, $next_version, $rule_graph_json, NOW(), $user_id)
```

### Execution Version Binding

The execution engine loads the latest published version for evaluation:

```sql
SELECT id, graph_snapshot FROM rule_versions
WHERE automation_id = $id
ORDER BY version_number DESC
LIMIT 1
```

If no published version exists, it falls back to the `rule_graph` column on the automation.

Each execution record stores `rule_version_id` to permanently record which version was used. This ensures post-hoc auditing can determine exactly what logic ran.

### Version History

Users can view the full version history of a rule from the rule detail screen. Each version shows:
- Version number
- Published timestamp
- Published by (user)
- Graph snapshot (viewable but not editable)
