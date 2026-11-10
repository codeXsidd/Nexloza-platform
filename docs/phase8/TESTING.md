# Phase 8 — Test Coverage Report

## Overview

Phase 8 includes 7 test files covering domain model, validation, execution entities, editor state management, integration scenarios, and security edge cases.

## Test Files

### 1. Domain Model Tests — `rule_graph_test.dart`

Tests for `RuleGraph`, `RuleNode`, `RuleEdge`, `RuleStatus`, and `RuleVersion`.

| Test Group | Tests | Coverage |
|---|---|---|
| RuleNode | constructor, copyWith (position/config/label), toJson/fromJson round-trip, fromJson with missing fields | Serialization correctness, immutability of copyWith |
| RuleEdge | constructor, toJson/fromJson round-trip | Serialization correctness |
| RuleGraph | constructor defaults, toJson/fromJson, findNode (found/not found), edgesFrom, edgesTo, triggerNodes, empty constant | Graph traversal, query methods |
| RuleStatus | fromString for all 6 values, unknown defaults to draft, isEditable, isActive, canPublish, canEnable, displayName | Lifecycle state machine correctness |
| RuleVersion | fromJson | Deserialization |

### 2. Node Type Tests — `rule_node_type_test.dart`

Tests for `RuleNodeType`, `RuleNodeCategory`, `NodePortDef`, and `PortDataType`.

| Test Group | Tests | Coverage |
|---|---|---|
| RuleNodeType enum | 35 values exist, each has non-empty displayName/description/dbValue | Enum completeness |
| Category distribution | 11 triggers, 13 conditions, 7 actions, 4 flow control | Category mapping |
| Category helpers | isTrigger, isCondition, isAction, isFlowControl | Convenience methods |
| fromString | Round-trip for all 35 values, unknown returns telemetryReceived | Serialization safety |
| RuleNodeCategory | 4 values with color, icon, displayName | Category metadata |
| PortDataType.canConnectTo | any↔any, same↔same, any↔specific, incompatible pairs | Connection validation logic |
| NodePortDef | Constructor with id, label, dataType | Port definition structure |

### 3. Validation Tests — `rule_validation_test.dart`

Tests for `RuleGraphValidator`.

| Test Group | Tests | Coverage |
|---|---|---|
| Trigger count | Empty graph error, single trigger passes, two triggers error | Entry point validation |
| Config validation | Missing required keys, comparison value types, betweenRange min>max, delay out of bounds | Config completeness and bounds |
| Edge validation | Self-referencing edge, invalid source/target node, invalid source/target port | Connection integrity |
| Disconnected nodes | Non-trigger node with no edges produces error | Graph connectivity |
| Cycle detection | A→B→C→A cycle detected | DAG enforcement |
| Port types | boolean→number incompatibility error | Type safety |
| Complete valid graph | trigger→condition→action with proper edges: no errors | Happy path |

### 4. Execution Entity Tests — `rule_execution_test.dart`

Tests for `ExecutionStatus`, `EventStatus`, `NodeResult`, `RuleExecution`, and `RuleEvent`.

| Test Group | Tests | Coverage |
|---|---|---|
| ExecutionStatus | fromString for all values, unknown defaults to failed, displayName | Status enum |
| EventStatus | fromString for all values, unknown defaults to pending | Status enum |
| NodeResult | Constructor, toJson/fromJson round-trip | Serialization |
| RuleExecution | Constructor defaults, fromJson with full data, fromJson with minimal data, dryRun default false | Entity deserialization |
| RuleEvent | Constructor defaults, fromJson with full data, fromJson with minimal data | Entity deserialization |

### 5. Editor State Tests — `rule_editor_state_test.dart`

Tests for `RuleEditorNotifier`.

| Test Group | Tests | Coverage |
|---|---|---|
| loadGraph | Populates nodes/edges maps from RuleGraph | State initialization |
| addNode | Generates unique ID, stores node, pushes undo | Node creation |
| moveNode | Updates position with delta offset | Node positioning |
| updateNodeConfig | Replaces config map, pushes undo | Config editing |
| deleteNode | Removes node and all connected edges, clears selection if deleted | Node removal |
| duplicateNode | Creates copy with offset position and "(copy)" label | Node duplication |
| selectNode | Sets/clears selectedNodeId | Selection management |
| addEdge | Creates edge, rejects self-connections (null), rejects duplicate target ports (null) | Edge creation with constraints |
| undo/redo | Add node → undo removes → redo restores | History management |
| validate | Empty graph produces trigger error | Design-time validation |
| clearDirty | Resets isDirty flag | State management |
| Connection flow | startConnection → completeConnection creates edge, cancelConnection clears pending | Drag-to-connect |

### 6. Integration Tests — `rule_engine_integration_test.dart`

End-to-end graph building and validation.

| Test Group | Tests | Coverage |
|---|---|---|
| Complete graph | Build trigger→condition→action, validate: no errors | Full pipeline |
| Serialization round-trip | Serialize to JSON, deserialize, validate: still no errors | Data persistence correctness |
| Cycle introduction | Add back-edge, validate: produces cycle error | Loop detection |
| Disconnected node | Add isolated condition, validate: produces disconnected error | Graph integrity |

### 7. Security Tests — `rule_security_test.dart`

Security and robustness edge cases.

| Test Group | Tests | Coverage |
|---|---|---|
| Unknown node type | fromString returns default, graph still validates | Input sanitization |
| Large graph | 1000 nodes: validates without crashing | Performance bounds |
| Deep edge chain | 100 sequential nodes: topological sort works | Scalability |
| Nested config | Deeply nested JSON in config: no crash | Input robustness |
| XSS-like label | Script tags in label: stored as-is (Flutter text rendering immune) | XSS prevention |
| Missing config | Empty config on nodes with required keys: produces validation errors | Validation completeness |
| Null config values | null values for required keys: produces errors | Null safety |

## Running Tests

```bash
# Run all Phase 8 tests
cd app
flutter test test/features/rule_engine/

# Run specific test file
flutter test test/features/rule_engine/domain/rule_graph_test.dart

# Run with verbose output
flutter test test/features/rule_engine/ --reporter expanded

# Run with coverage
flutter test test/features/rule_engine/ --coverage
```

## Test Counts

| File | Approximate Test Count |
|---|---|
| rule_graph_test.dart | ~20 |
| rule_node_type_test.dart | ~15 |
| rule_validation_test.dart | ~15 |
| rule_execution_test.dart | ~15 |
| rule_editor_state_test.dart | ~15 |
| rule_engine_integration_test.dart | ~8 |
| rule_security_test.dart | ~10 |
| **Total** | **~100** |

## Known Limitations

1. **Edge Function tests**: The automation-engine Edge Function requires a running Supabase local development environment (Deno, PostgreSQL) to test. These are not included in the Flutter test suite. Test the Edge Function using `supabase functions serve` and curl/Postman.

2. **Widget tests**: Full widget tests for the visual editor screens require `WidgetTester.pumpWidget()` with properly configured `ProviderScope` and mock repositories. The current test suite covers domain logic and state management; widget rendering tests can be added using `mocktail` for repository mocking.

3. **Supabase integration**: Repository tests (data layer) would require either a live Supabase instance or mocked Supabase client. The current tests focus on the domain and presentation layers which are independent of Supabase.

4. **MQTT integration**: Rule actions that result in device commands ultimately produce MQTT messages via the device-command Edge Function. End-to-end MQTT flow testing requires the full NanoMQ + Supabase stack.
