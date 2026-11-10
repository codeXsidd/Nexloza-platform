# Phase 8 — Rule Graph JSON Schema Reference

## Schema Version

Current schema version: **1**

The `schema_version` field is included in every serialized graph to support future migrations.

## Top-Level Structure: RuleGraph

```json
{
  "schema_version": 1,
  "nodes": [ ... ],
  "edges": [ ... ]
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `schema_version` | `integer` | Yes | Schema version, currently `1` |
| `nodes` | `array<RuleNode>` | Yes | All nodes in the graph |
| `edges` | `array<RuleEdge>` | Yes | All connections between nodes |

## RuleNode

```json
{
  "id": "node_1",
  "type": "sensorAboveThreshold",
  "position": { "x": 100.0, "y": 200.0 },
  "config": { "device_id": "...", "sensor_key": "temperature", "threshold": 30 },
  "label": "Temp > 30°C"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `string` | Yes | Unique node identifier within the graph |
| `type` | `string` | Yes | One of the 35 node type `dbValue` strings (see below) |
| `position` | `object` | Yes | Canvas position: `{ "x": number, "y": number }` |
| `config` | `object` | Yes | Node-specific configuration (may be empty `{}`) |
| `label` | `string` | No | Optional display label (defaults to node type display name) |

## RuleEdge

```json
{
  "id": "edge_1",
  "source_node_id": "node_1",
  "source_port": "out",
  "target_node_id": "node_2",
  "target_port": "in"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | `string` | Yes | Unique edge identifier within the graph |
| `source_node_id` | `string` | Yes | ID of the source node |
| `source_port` | `string` | Yes | Output port name on the source node |
| `target_node_id` | `string` | Yes | ID of the target node |
| `target_port` | `string` | Yes | Input port name on the target node |

## Node Type Values

All 35 valid `type` strings, organized by category:

### Triggers (11)
| dbValue | Display Name |
|---|---|
| `telemetryReceived` | Telemetry Received |
| `sensorValueChanged` | Sensor Value Changed |
| `sensorAboveThreshold` | Sensor Above Threshold |
| `sensorBelowThreshold` | Sensor Below Threshold |
| `deviceOnlineTrigger` | Device Online |
| `deviceOfflineTrigger` | Device Offline |
| `deviceStatusChanged` | Device Status Changed |
| `twinReportedChanged` | Twin Reported Changed |
| `twinDesiredChanged` | Twin Desired Changed |
| `scheduledTrigger` | Scheduled Trigger |
| `manualTrigger` | Manual Trigger |

### Conditions (13)
| dbValue | Display Name |
|---|---|
| `equalTo` | Equal To |
| `notEqualTo` | Not Equal To |
| `greaterThan` | Greater Than |
| `greaterThanOrEqual` | Greater Than or Equal |
| `lessThan` | Less Than |
| `lessThanOrEqual` | Less Than or Equal |
| `betweenRange` | Between Range |
| `booleanCheck` | Boolean Check |
| `andGate` | AND Gate |
| `orGate` | OR Gate |
| `notGate` | NOT Gate |
| `deviceOnlineCheck` | Device Online Check |
| `twinDesiredVsReported` | Twin Desired vs Reported |

### Actions (7)
| dbValue | Display Name |
|---|---|
| `sendCommand` | Send Command |
| `setActuator` | Set Actuator |
| `updateTwinDesired` | Update Twin Desired |
| `executeScene` | Execute Scene |
| `recordEvent` | Record Event |
| `logResult` | Log Result |
| `stopFlow` | Stop Flow |

### Flow Control (4)
| dbValue | Display Name |
|---|---|
| `conditionalBranch` | Conditional Branch |
| `delay` | Delay |
| `merge` | Merge |
| `terminate` | Terminate |

## Port Naming Conventions

| Port Name | Used By | Direction | Description |
|---|---|---|---|
| `out` | Most nodes | Output | Single output port |
| `in` | Most non-trigger nodes | Input | Single input port |
| `true` | conditionalBranch | Output | Taken when input is truthy |
| `false` | conditionalBranch | Output | Taken when input is falsy |
| `a` | andGate, orGate, merge | Input | First input |
| `b` | andGate, orGate, merge | Input | Second input |

## Port Data Types

| Type | Description | Compatible With |
|---|---|---|
| `any` | Accepts or produces any data type | All types |
| `boolean` | Boolean true/false | `boolean`, `any` |
| `number` | Numeric value | `number`, `any` |
| `string` | Text value | `string`, `any` |
| `event` | Event payload object | `event`, `any` |

**Compatibility rule**: A source port can connect to a target port if either port has type `any`, or both ports have the same type. `boolean` cannot connect to `number` directly; use a condition node to convert.

## Validation Rules

The `RuleGraphValidator` enforces these rules before a graph can be saved or published:

1. **Trigger count**: Exactly one trigger node required
2. **Required config**: Each node type's required config keys must be present and non-null
3. **Value types**: Comparison nodes require config values of type `num`, `bool`, or `String`
4. **Range validity**: `betweenRange` nodes require `min_value <= max_value`
5. **Delay bounds**: `delay` nodes require `duration_ms` between 100 and 3,600,000
6. **Edge validity**: Source and target nodes must exist, no self-referencing edges
7. **Port validity**: Source port must be a valid output port on the source node, target port must be a valid input port on the target node
8. **Connected nodes**: Non-trigger nodes must have at least one connected edge
9. **No cycles**: The graph must be a DAG — no directed cycles (detected via DFS)
10. **Port type compatibility**: Connected ports must have compatible data types

## Complete Example

Rule: "Turn off fan when temperature drops below 20°C"

```json
{
  "schema_version": 1,
  "nodes": [
    {
      "id": "node_1",
      "type": "sensorBelowThreshold",
      "position": { "x": 50, "y": 150 },
      "config": {
        "device_id": "aaa-bbb-ccc-sensor",
        "sensor_key": "temperature",
        "threshold": 20
      },
      "label": "Temp < 20°C"
    },
    {
      "id": "node_2",
      "type": "greaterThan",
      "position": { "x": 300, "y": 150 },
      "config": {
        "value": 5
      },
      "label": "Temp > 5°C (not freezing)"
    },
    {
      "id": "node_3",
      "type": "sendCommand",
      "position": { "x": 550, "y": 150 },
      "config": {
        "device_id": "ddd-eee-fff-fan",
        "command_type": "set_state",
        "payload": { "power": "off" }
      },
      "label": "Turn Off Fan"
    },
    {
      "id": "node_4",
      "type": "logResult",
      "position": { "x": 550, "y": 320 },
      "config": {
        "message": "Temperature too low for safety check"
      },
      "label": "Log Warning"
    },
    {
      "id": "node_5",
      "type": "conditionalBranch",
      "position": { "x": 300, "y": 300 },
      "config": {},
      "label": "Safe temp?"
    }
  ],
  "edges": [
    {
      "id": "edge_1",
      "source_node_id": "node_1",
      "source_port": "out",
      "target_node_id": "node_2",
      "target_port": "in"
    },
    {
      "id": "edge_2",
      "source_node_id": "node_2",
      "source_port": "out",
      "target_node_id": "node_5",
      "target_port": "in"
    },
    {
      "id": "edge_3",
      "source_node_id": "node_5",
      "source_port": "true",
      "target_node_id": "node_3",
      "target_port": "in"
    },
    {
      "id": "edge_4",
      "source_node_id": "node_5",
      "source_port": "false",
      "target_node_id": "node_4",
      "target_port": "in"
    }
  ]
}
```

This graph:
1. Triggers when temperature drops below 20°C
2. Checks if the value is still above 5°C (not dangerously cold)
3. Branches: if above 5°C (true) → sends fan-off command; if below 5°C (false) → logs a warning
