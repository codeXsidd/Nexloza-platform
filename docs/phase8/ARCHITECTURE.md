# Phase 8 — Rule Engine Architecture

## Overview

Phase 8 introduces a visual, event-driven, graph-based rule engine that extends the existing Phase 3 automation system. Rules are authored as directed acyclic graphs (DAGs) in a Flutter visual editor, stored as JSONB in the `automations` table, and evaluated server-side by the `automation-engine` Supabase Edge Function.

The design follows two principles:

1. **Extend, don't replace** — the existing `automations`, `automation_triggers`, `automation_conditions`, `automation_actions`, and `automation_executions` tables and the legacy sensor-threshold evaluation path are preserved. Graph-based rules coexist with legacy trigger-based automations.
2. **Backend-only execution** — rule graphs are evaluated exclusively in the Edge Function using the Supabase service-role key. The Flutter client never executes rule logic or holds privileged credentials.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Flutter Application                          │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────────┐ │
│  │ Rules List   │  │ Rule Detail  │  │ Visual Graph Editor       │ │
│  │ Screen       │  │ Screen       │  │ (InteractiveViewer +      │ │
│  │              │  │              │  │  CustomPainter canvas)    │ │
│  └──────┬───────┘  └──────┬───────┘  └────────────┬──────────────┘ │
│         │                 │                        │                │
│  ┌──────┴─────────────────┴────────────────────────┴──────────────┐ │
│  │                   Riverpod Providers                            │ │
│  │  rulesProvider · ruleEditorProvider · ruleControllerProvider    │ │
│  └──────────────────────────┬─────────────────────────────────────┘ │
│                             │ Supabase Client (JWT auth)            │
└─────────────────────────────┼───────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     Supabase Backend                                │
│                                                                     │
│  ┌──────────────────────┐   ┌──────────────────────────────────┐   │
│  │ telemetry-ingest     │──▶│ automation-engine Edge Function  │   │
│  │ Edge Function        │   │                                  │   │
│  │ (API key + secret)   │   │  ┌────────────────────────────┐  │   │
│  └──────────────────────┘   │  │ Legacy Trigger Evaluator   │  │   │
│                             │  │ (sensor_threshold path)    │  │   │
│  ┌──────────────────────┐   │  └────────────────────────────┘  │   │
│  │ device-command       │   │  ┌────────────────────────────┐  │   │
│  │ Edge Function        │   │  │ Graph Rule Evaluator       │  │   │
│  │ (JWT auth)           │   │  │ • Topological sort         │  │   │
│  └──────────────────────┘   │  │ • Per-node evaluation      │  │   │
│                             │  │ • Loop prevention          │  │   │
│                             │  │ • Dry-run support          │  │   │
│                             │  └────────────────────────────┘  │   │
│                             └──────────────┬───────────────────┘   │
│                                            │                       │
│  ┌─────────────────────────────────────────┼─────────────────────┐ │
│  │              PostgreSQL                 ▼                     │ │
│  │  automations (+ rule_graph, status, graph_version)           │ │
│  │  rule_versions (immutable published snapshots)               │ │
│  │  rule_events (durable event inbox with idempotency)          │ │
│  │  automation_executions (+ correlation_id, node_results)      │ │
│  │  device_commands · device_twin_state · scenes                │ │
│  └──────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Components

### 1. Rule Graph Model (Flutter domain layer)

Located in `app/lib/features/rule_engine/domain/entities/`:

| File | Purpose |
|---|---|
| `rule_node_type.dart` | 35 node types across 4 categories (trigger, condition, action, flow), port definitions, data types |
| `rule_graph.dart` | `RuleNode`, `RuleEdge`, `RuleGraph` (schema versioned), `RuleStatus` enum, `RuleVersion` entity |
| `rule_validation.dart` | `RuleGraphValidator` — trigger count, config keys, edge validity, cycle detection (DFS), port type compatibility |
| `rule_execution.dart` | `RuleExecution`, `RuleEvent`, `NodeResult`, execution/event status enums |

### 2. Edge Function — automation-engine

File: `backend/supabase/functions/automation-engine/index.ts`

The function handles two request modes:

- **Legacy path**: Receives `{ device_id, sensor_key, value }`, evaluates `sensor_threshold` trigger-based automations (no `rule_graph`). Also forwards the event to graph-based rules as a `telemetry_received` event.
- **New rule event path**: Receives `{ event_type, device_id, project_id, organization_id, ... }`, processes through the graph evaluator with idempotency checking, depth limits, cooldown, and rate limiting.

Graph evaluation:
1. Topological sort of all nodes
2. Iterate nodes in topological order
3. Trigger nodes: evaluate against the incoming event; if the trigger doesn't fire, abort
4. Condition nodes: evaluate synchronously (comparisons, logic gates) or asynchronously (device online check, twin state comparison via DB lookup)
5. Action nodes: execute side effects (insert device_commands, update twin state, activate scenes, record events) — skipped in dry-run mode
6. Flow control nodes: conditional branching (routes true/false ports), delay (simulated up to 10s), merge, terminate

### 3. Visual Editor (Flutter presentation layer)

Located in `app/lib/features/rule_engine/presentation/widgets/`:

| Widget | Purpose |
|---|---|
| `rule_canvas.dart` | `InteractiveViewer` (zoom 0.3×–3.0×, pan), `Stack` of grid + edges + nodes, pending connection drag |
| `node_widget.dart` | Category-colored header, icon + label, input/output port circles, selection/error indicators |
| `edge_painter.dart` | `CustomPainter` for bezier curve connections with arrowheads, dashed pending line |
| `node_catalog_sheet.dart` | Modal bottom sheet with all 35 node types grouped by category, search filter |
| `node_config_panel.dart` | Per-type configuration forms (device picker, threshold, cron, JSON, severity dropdown) |

### 4. Event Inbox/Outbox

The `rule_events` table acts as a durable event inbox:

1. Events are inserted with `status: 'processing'` before evaluation begins
2. Idempotency is enforced via the `idempotency_key` UNIQUE constraint — duplicate events are rejected
3. After processing completes, the event status is updated to `completed` or `failed`
4. Correlation IDs link cascading events across rule chains

## Data Flow

### Telemetry → Rule Evaluation → Command

```
Device publishes telemetry
        │
        ▼
telemetry-ingest Edge Function
  (validates API key + secret, rate limits, bulk inserts)
        │
        ▼
Calls automation-engine Edge Function
  (or automation-engine is called directly for manual/scheduled triggers)
        │
        ▼
automation-engine receives event
        │
        ├── Legacy path: evaluates sensor_threshold triggers
        │
        └── Graph path:
              1. Idempotency check (rule_events.idempotency_key)
              2. Depth check (max 5)
              3. Insert event into rule_events inbox
              4. Query enabled graph-based automations for project
              5. For each matching rule:
              │   a. Re-entry detection (same rule + correlation)
              │   b. Cooldown check
              │   c. Rate limit check
              │   d. Load published version graph (or rule_graph fallback)
              │   e. Create execution record (status: running)
              │   f. Topological sort → evaluate nodes
              │   g. Update execution record (status: completed/failed/cancelled)
              │
              └── Side effects (if not dry-run):
                    • device_commands inserts
                    • device_twin_state updates
                    • scene activations
                    • rule_events inserts (for recordEvent action)
```

## Database Schema

### Extended Tables (migration 00019)

**automations** — new columns:
| Column | Type | Description |
|---|---|---|
| `rule_graph` | `JSONB` | The rule graph (nodes, edges, schema_version) |
| `status` | `TEXT` | Rule lifecycle: draft, validated, published, enabled, disabled, archived |
| `graph_version` | `INTEGER` | Incremented on each graph save |
| `published_at` | `TIMESTAMPTZ` | When the rule was last published |
| `published_by` | `UUID` | User who published |

**automation_executions** — new columns:
| Column | Type | Description |
|---|---|---|
| `correlation_id` | `UUID` | Links cascading executions |
| `execution_depth` | `INTEGER` | Current depth in execution chain (max 5) |
| `node_results` | `JSONB` | Per-node evaluation results array |
| `rule_version_id` | `UUID` | FK to rule_versions |
| `dry_run` | `BOOLEAN` | Whether this was a dry-run execution |

### New Tables

**rule_versions** — immutable published snapshots:
| Column | Type | Description |
|---|---|---|
| `id` | `UUID` | Primary key |
| `automation_id` | `UUID` | FK to automations |
| `version_number` | `INTEGER` | Sequential per automation |
| `graph_snapshot` | `JSONB` | Frozen copy of rule_graph at publish time |
| `published_at` | `TIMESTAMPTZ` | Publish timestamp |
| `published_by` | `UUID` | User who published |

**rule_events** — durable event inbox:
| Column | Type | Description |
|---|---|---|
| `id` | `UUID` | Primary key |
| `event_type` | `TEXT` | Event type string |
| `device_id` | `UUID` | Optional device reference |
| `project_id` | `UUID` | Project scope |
| `organization_id` | `UUID` | Organization scope |
| `payload` | `JSONB` | Event data |
| `idempotency_key` | `TEXT` | UNIQUE — prevents duplicate processing |
| `correlation_id` | `UUID` | Links related events |
| `causation_id` | `UUID` | Parent event that caused this one |
| `depth` | `INTEGER` | Execution chain depth |
| `status` | `TEXT` | pending, processing, completed, failed, skipped |
| `processed_at` | `TIMESTAMPTZ` | When processing completed |
| `error_message` | `TEXT` | Error details if failed |

All tables have RLS policies enforcing `is_project_member` access control.

## Security Model

| Concern | Mitigation |
|---|---|
| Rule execution location | Edge Function only — never in Flutter |
| Service role key | Server-side only, never exposed to client |
| Graph import safety | Full `RuleGraphValidator` runs before save/publish — no executable code in graphs |
| Device scope | Commands only target devices within the automation's project (RLS enforced) |
| MQTT credentials | Never exposed to visual editor |
| Cascading loops | Max depth 5, correlation ID re-entry detection, per-device command throttle |
| Rate abuse | Cooldown per automation, max executions per hour, idempotency deduplication |
| Supabase Realtime | Not used as a job queue — events go through rule_events table |
