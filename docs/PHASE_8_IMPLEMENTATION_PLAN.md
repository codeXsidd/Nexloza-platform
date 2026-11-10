# NEXLOZA — Phase 8 Implementation Plan

## Visual Rule Engine and Advanced Automation

---

## Layer 1: Database Migration (00019)

### ALTER `automations` table
```sql
rule_graph JSONB                    -- visual rule graph (nodes + edges + positions)
status TEXT DEFAULT 'draft'         -- draft/validated/published/enabled/disabled/archived
graph_version INT DEFAULT 1         -- incremented on each save
published_at TIMESTAMPTZ
published_by UUID REFERENCES profiles(id)
```

### CREATE `rule_versions` table
Immutable published snapshots. A published rule executes from its version, not the live draft.
```
id, automation_id FK, version_number INT, graph_snapshot JSONB,
published_at, published_by, created_at
```

### CREATE `rule_events` table
Durable event inbox for reliable async processing with deduplication.
```
id, event_type TEXT, device_id UUID, project_id UUID, organization_id UUID,
payload JSONB, idempotency_key TEXT UNIQUE, correlation_id UUID,
causation_id UUID, depth INT DEFAULT 0, status TEXT DEFAULT 'pending',
processed_at TIMESTAMPTZ, error_message TEXT, created_at
```

### ALTER `automation_executions` table
```sql
correlation_id UUID                 -- traces event→rule→action chain
execution_depth INT DEFAULT 0       -- loop prevention depth counter
node_results JSONB DEFAULT '[]'     -- per-node evaluation trace
rule_version_id UUID                -- which published version was used
dry_run BOOLEAN DEFAULT false       -- dry-run executions don't send commands
```

### RLS, indexes, constraints on all new tables/columns.

---

## Layer 2: Domain Entities

### Rule Graph Model
- `RuleNodeType` enum — 4 categories × multiple types each
  - Triggers: telemetryReceived, sensorValueChanged, sensorAboveThreshold, sensorBelowThreshold, deviceOnline, deviceOffline, deviceStatusChanged, twinReportedChanged, twinDesiredChanged, manualTrigger, scheduledTrigger
  - Conditions: equal, notEqual, greaterThan, greaterThanOrEqual, lessThan, lessThanOrEqual, betweenRange, booleanCheck, andGate, orGate, notGate, deviceOnlineCheck, twinDesiredVsReported
  - Actions: sendCommand, setActuator, updateTwinDesired, executeScene, recordEvent, logResult, stopFlow
  - Flow: delay, conditionalBranch, merge, terminate
- `RuleNodeCategory` enum — trigger, condition, action, flow
- `NodePort` — id, label, dataType (any, boolean, number, string, device, event)
- `RuleNode` — id, type, position (x,y), config Map, label, ports
- `RuleEdge` — id, sourceNodeId, sourcePort, targetNodeId, targetPort
- `RuleGraph` — schemaVersion, nodes List, edges List
- `RuleStatus` enum — draft, validated, published, enabled, disabled, archived
- `RuleVersion` — id, automationId, versionNumber, graphSnapshot, publishedAt, publishedBy
- `RuleEvent` — id, eventType, deviceId, projectId, payload, idempotencyKey, correlationId, depth, status
- `RuleExecution` — extends AutomationExecution with correlationId, depth, nodeResults, dryRun
- `NodeResult` — nodeId, nodeType, status (evaluated/skipped/failed), output, error, evaluatedAt

### Graph Validation
- `RuleGraphValidator` — validates graph structure:
  - Exactly one trigger node
  - All edges connect valid ports
  - No disconnected non-trigger nodes
  - No cycles (topological sort)
  - Required config fields present per node type
  - Device/sensor references exist
  - Returns list of `ValidationError(nodeId, message)`

---

## Layer 3: Rule Engine Edge Function

Extend `automation-engine` to support graph-based rule evaluation.

### Processing Flow
1. Receive event (telemetry, device status, twin change, manual)
2. Validate event schema and authentication
3. Check idempotency_key for deduplication
4. Insert into rule_events table
5. Query published+enabled rules matching event type and project
6. For each matching rule:
   a. Load published graph_snapshot from rule_versions
   b. Check cooldown and rate limits
   c. Check execution depth (max 5) for loop prevention
   d. Topological-sort the graph nodes
   e. Evaluate trigger node against event
   f. Walk the graph: evaluate conditions, execute actions
   g. Record per-node results
   h. Record execution with correlation_id
7. Mark event as processed

### Dry-Run Mode
- Same evaluation path
- Actions are simulated (logged but not executed)
- Execution marked dry_run=true
- No side effects to devices, twin state, or commands

### Loop Prevention
- correlation_id propagated from source event
- depth incremented per chained rule trigger
- Max depth: 5 (configurable)
- Re-entry detection: skip rule if same rule+correlation already executing
- Per-device command throttling: max 1 command per device per 5s within same correlation

---

## Layer 4: Data Layer

### `RuleRepository` (extends AutomationRepository)
- saveGraph(automationId, graph) — saves draft
- validateGraph(automationId) — runs validator, updates status
- publishRule(automationId) — creates immutable rule_version, sets status=published
- enableRule / disableRule / archiveRule
- getVersionHistory(automationId)
- restoreVersion(automationId, versionId)
- importGraph(json) — validates before saving
- exportGraph(automationId) — returns safe JSON

### `RuleExecutionRepository`
- getExecutions(automationId, filters, pagination)
- getExecutionDetail(executionId) — includes node_results
- getExecutionsByCorrelation(correlationId)

### `RuleEventService`
- submitEvent(event) — inserts into rule_events, invokes automation-engine
- submitDryRunEvent(event, automationId) — invokes in dry-run mode

---

## Layer 5: Visual Rule Editor

### Canvas Architecture
- `InteractiveViewer` for zoom/pan (bounded, with min/max scale)
- `CustomPainter` for drawing edge connections (bezier curves)
- `Stack` of positioned `NodeWidget`s
- GestureDetector on nodes for drag, tap-to-select, long-press menu
- GestureDetector on ports for connection drawing
- Grid background painter for visual alignment

### Editor State
- `RuleEditorNotifier` (Riverpod) managing:
  - nodes Map<String, RuleNode>
  - edges Map<String, RuleEdge>
  - selectedNodeId
  - pendingConnection (source port while dragging)
  - undoStack / redoStack
  - canvasOffset, canvasScale
  - validationErrors
  - isDirty (unsaved changes)

### Node Catalog
- Bottom sheet with categorized node list
- Search filter
- Tap to add node at center of viewport

### Node Configuration
- Side panel / bottom sheet per node type
- Device/sensor/actuator pickers (reuse DataSourceSelector pattern)
- Operator selectors for conditions
- Value inputs with type validation
- Threshold inputs for sensor triggers

### Phone Layout
- List-based node editor (sequential rather than canvas)
- Tap to configure, swipe to connect
- Connection shown as flow arrows between list items

---

## Layer 6: Presentation Layer

### New Routes
- `/rules` — rules list (extends automations)
- `/rules/create` — create rule wizard
- `/rules/:id/editor` — visual rule builder
- `/rules/:id/details` — rule details + version history
- `/rules/:id/test` — dry-run tester
- `/rules/:id/executions` — execution history
- `/rules/:id/executions/:execId` — execution detail

### Screens
1. **RulesScreen** — list with status chips, enable/disable, search/filter
2. **CreateRuleScreen** — name, project, description, template selection
3. **RuleEditorScreen** — visual canvas + node catalog + config panel
4. **NodeConfigPanel** — per-type configuration forms
5. **RuleValidationPanel** — validation results with node highlighting
6. **RulePreviewScreen** — read-only graph view with rule summary
7. **DryRunScreen** — virtual device selector, test value inputs, execution trace
8. **RuleDetailScreen** — rule info, version history, publish/enable controls
9. **ExecutionHistoryScreen** — paginated list with filters
10. **ExecutionDetailScreen** — timeline of node evaluations + action results

### Providers
- `rulesProvider` — list of rules with status
- `ruleDetailProvider(id)` — single rule with graph
- `ruleEditorProvider(id)` — editor state notifier
- `ruleExecutionsProvider(id)` — execution history
- `ruleValidationProvider(id)` — validation results

---

## Layer 7: Testing

Preserve 492 existing tests. Add:

### Graph Model Tests (~30)
- Node creation/serialization
- Edge validation
- Graph serialization/deserialization
- Schema version compatibility
- Cycle detection
- Disconnected node detection
- Required config validation

### Rule Engine Tests (~25)
- Trigger evaluation (all types)
- Condition evaluation (all comparison operators, AND/OR/NOT)
- Action execution recording
- Branching and flow control
- Loop detection
- Depth limiting
- Cooldown enforcement
- Idempotency/deduplication
- Dry-run isolation

### Integration Tests (~15)
- Virtual device telemetry → rule evaluation
- Rule action → device command
- Twin state → rule trigger
- End-to-end: create → validate → publish → execute
- Cross-rule loop prevention

### Security Tests (~10)
- RLS enforcement
- Cross-project access denial
- Unauthorized publish attempt
- Invalid graph import rejection

### Flutter Widget Tests (~20)
- Rule list and cards
- Node catalog
- Node configuration
- Validation display
- Execution history
- Editor state management

**Target: 492 + ~100 = ~592+ tests**

---

## Layer 8: Documentation

1. `PHASE_8_AUDIT_REPORT.md` — this audit
2. `PHASE_8_IMPLEMENTATION_PLAN.md` — this plan
3. `PHASE_8_COMPLETION_REPORT.md` — final results
4. `RULE_ENGINE_ARCHITECTURE.md` — event processing, graph evaluation, execution model
5. `VISUAL_RULE_BUILDER_GUIDE.md` — user guide for the visual editor
6. `RULE_NODE_REFERENCE.md` — all node types with config schemas
7. `RULE_GRAPH_SCHEMA.md` — graph JSON schema specification
8. `RULE_EXECUTION_AND_RETRY.md` — retry, timeout, deduplication, loop prevention
9. `RULE_SECURITY_AND_LIMITS.md` — RLS, tenant isolation, rate limits
10. `RULE_ENGINE_TESTING.md` — test strategy and coverage
