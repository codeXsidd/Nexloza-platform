# Phase 8 — Visual Rule Builder User Guide

## Getting Started

The Visual Rule Builder lets you create automation rules using a drag-and-drop graph editor. Rules are composed of connected nodes that define triggers, conditions, actions, and flow control logic.

Navigate to the **Rules** section from the automations area in your project.

## Creating a Rule

1. Tap the **+** floating action button on the Rules list screen
2. Enter a **name** for your rule (required)
3. Optionally add a **description**
4. Select the **project** this rule belongs to
5. Tap **Create** — you'll be taken to the visual graph editor

## The Visual Editor

### Canvas Controls

- **Pan**: Drag on the canvas background to move the viewport
- **Zoom**: Pinch (touch) or scroll (mouse) to zoom in/out (0.3×–3.0×)
- **Select node**: Tap a node to select it (highlighted border)
- **Move node**: Drag a node to reposition it on the canvas
- **Deselect**: Tap the canvas background to deselect

### Adding Nodes

1. Tap the **Add Node** floating action button
2. Browse the node catalog organized by category, or use the search bar
3. Tap a node type to add it to the canvas at the default position
4. Drag the node to your desired location

### Connecting Nodes

Nodes have **input ports** (left side) and **output ports** (right side):

1. Tap and hold an **output port** (right side circle) on a source node
2. Drag to an **input port** (left side circle) on a target node
3. Release to create the connection

A dashed line follows your finger/cursor while dragging. Connections appear as smooth bezier curves between nodes.

**Connection rules:**
- You cannot connect a node to itself
- Each input port accepts only one incoming connection
- Port data types must be compatible (e.g., boolean output can connect to boolean input, `any` type connects to anything)

### Configuring Nodes

1. Tap a node to select it
2. The configuration panel opens as a bottom sheet
3. Fill in the required fields for that node type (device ID, sensor key, threshold value, etc.)
4. Changes are applied immediately
5. You can rename the node using the **Node Label** field
6. Tap **Delete** to remove the node

### Toolbar Actions

The editor toolbar (app bar) provides:

- **Undo** / **Redo** — reverse or reapply changes
- **Validate** — check the graph for errors (missing config, invalid connections, cycles)
- **Save** — persist the current graph to the database

## Node Categories

### Triggers (Green)
Trigger nodes start rule evaluation when an event matches. Every rule must have exactly one trigger node.

| Node | Description |
|---|---|
| Telemetry Received | Fires when any telemetry arrives from a device |
| Sensor Value Changed | Fires when a specific sensor value changes |
| Sensor Above Threshold | Fires when a sensor value exceeds a threshold |
| Sensor Below Threshold | Fires when a sensor value drops below a threshold |
| Device Online | Fires when a device comes online |
| Device Offline | Fires when a device goes offline |
| Device Status Changed | Fires on any device status transition |
| Twin Reported Changed | Fires when a device's reported twin state changes |
| Twin Desired Changed | Fires when a device's desired twin state changes |
| Scheduled Trigger | Fires on a cron schedule |
| Manual Trigger | Fires when triggered manually or via dry-run |

### Conditions (Blue)
Condition nodes evaluate data and produce boolean outputs.

| Node | Description |
|---|---|
| Equal To | Checks if the input value equals a configured value |
| Not Equal To | Checks if the input value differs from a configured value |
| Greater Than | Checks if a numeric input exceeds a threshold |
| Greater Than or Equal | Checks if a numeric input meets or exceeds a threshold |
| Less Than | Checks if a numeric input is below a threshold |
| Less Than or Equal | Checks if a numeric input is at or below a threshold |
| Between Range | Checks if a numeric input falls within min/max bounds |
| Boolean Check | Checks if a boolean input matches an expected value |
| AND Gate | Outputs true only if all connected inputs are true |
| OR Gate | Outputs true if any connected input is true |
| NOT Gate | Inverts a boolean input |
| Device Online Check | Queries the database to check if a device is currently online |
| Twin Desired vs Reported | Compares a twin attribute's desired and reported values |

### Actions (Orange)
Action nodes perform side effects.

| Node | Description |
|---|---|
| Send Command | Sends a command to a device |
| Set Actuator | Sets a specific actuator value on a device |
| Update Twin Desired | Merges attributes into a device's desired twin state |
| Execute Scene | Activates a predefined scene |
| Record Event | Inserts an event record for audit/alerting |
| Log Result | Records a log message in the execution trace |
| Stop Flow | Stops further execution of the rule |

### Flow Control (Purple)
Flow control nodes manage execution paths.

| Node | Description |
|---|---|
| Conditional Branch | Routes execution to "true" or "false" output based on input |
| Delay | Pauses execution for a configured duration (ms) |
| Merge | Combines multiple execution paths |
| Terminate | Immediately ends all rule execution |

## Building Your First Rule

**Example: Turn off a fan when temperature drops below 20°C**

1. **Add a trigger**: Select "Sensor Below Threshold" from the catalog
   - Configure: set `device_id` to your temperature sensor, `sensor_key` to `temperature`, `threshold` to `20`

2. **Add a condition** (optional): Select "Greater Than" to add a secondary check
   - Configure: set `value` to `15` (only act if temperature is between 15–20, not freezing)

3. **Add an action**: Select "Send Command"
   - Configure: set `device_id` to your fan device, `command_type` to `set_state`, `payload` to `{"power": "off"}`

4. **Connect the nodes**:
   - Drag from the trigger's output port → condition's input port
   - Drag from the condition's `true` output → action's input port

5. **Validate**: Tap the validate button — fix any errors shown

6. **Save**: Tap save to persist the graph

7. **Publish**: Go back to the rule detail screen and tap "Publish"

8. **Enable**: Tap "Enable" to activate the rule

## Rule Lifecycle

```
Draft ──▶ Validated ──▶ Published ──▶ Enabled
                                         │
                                         ▼
                                      Disabled
                                         │
                                         ▼
                                      Archived
```

| Status | Description | Editable? |
|---|---|---|
| **Draft** | Initial state, graph can be modified | Yes |
| **Validated** | Graph passed all validation checks | Yes |
| **Published** | An immutable version snapshot was created | No |
| **Enabled** | Rule is actively evaluating incoming events | No |
| **Disabled** | Rule is paused, not evaluating events | No |
| **Archived** | Rule is retired and hidden from active lists | No |

- Editing a published rule resets its status to **Draft**
- Publishing creates an immutable version snapshot — the execution engine uses the latest published version
- You can view the version history from the rule detail screen

## Dry-Run Testing

Test your rules without affecting real devices:

1. Navigate to the rule's detail screen
2. Tap **Dry Run**
3. Configure a simulated event:
   - Select the event type (e.g., `telemetry_received`)
   - Enter a device ID (use a Phase 7 virtual device for safe testing)
   - Set sensor key and value
4. Tap **Run Dry Test**
5. View the results: each node shows whether it was evaluated, skipped, or failed, along with its output

Dry-run executions are recorded in the execution history with a "Dry Run" badge.

## Execution Monitoring

### Execution History

From the rule detail screen, tap **View Executions** to see:

- All past executions sorted by most recent
- Status indicators: completed (green), failed (red), running (blue), cancelled (grey)
- Duration in milliseconds
- Dry-run badge where applicable

### Execution Detail

Tap any execution to see the node-by-node trace:

- **Evaluated** (green): Node was processed and produced output
- **Skipped** (grey): Node was on a branch that wasn't taken
- **Failed** (red): Node encountered an error

Each node result shows:
- Node type and ID
- Output value
- Error message (if failed)
- Evaluation timestamp

## Tips and Best Practices

1. **Start simple** — begin with a single trigger → condition → action chain, then add complexity
2. **Use dry-run** — always test with dry-run before enabling a rule in production
3. **Use virtual devices** — Phase 7 virtual devices are ideal for testing rules safely
4. **Monitor executions** — check execution history regularly for failed runs
5. **Set appropriate cooldowns** — prevent rule spam by configuring `cooldown_seconds`
6. **One trigger per rule** — each rule must have exactly one trigger node; use separate rules for different event types
7. **Validate before publishing** — the validator catches cycles, disconnected nodes, missing config, and port type mismatches
8. **Version your rules** — publishing creates an immutable snapshot; you can always see what version was running when an execution occurred
