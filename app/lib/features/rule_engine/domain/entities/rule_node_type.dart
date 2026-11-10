import 'package:flutter/material.dart';

enum RuleNodeCategory {
  trigger,
  condition,
  action,
  flow;

  String get displayName => switch (this) {
        trigger => 'Triggers',
        condition => 'Conditions',
        action => 'Actions',
        flow => 'Flow Control',
      };

  IconData get icon => switch (this) {
        trigger => Icons.bolt,
        condition => Icons.rule,
        action => Icons.play_circle,
        flow => Icons.call_split,
      };

  Color get color => switch (this) {
        trigger => const Color(0xFFE65100),
        condition => const Color(0xFF1565C0),
        action => const Color(0xFF2E7D32),
        flow => const Color(0xFF6A1B9A),
      };
}

enum RuleNodeType {
  // Triggers
  telemetryReceived(RuleNodeCategory.trigger, 'Telemetry Received',
      'Fires when any telemetry arrives from a device'),
  sensorValueChanged(RuleNodeCategory.trigger, 'Sensor Value Changed',
      'Fires when a specific sensor value changes'),
  sensorAboveThreshold(RuleNodeCategory.trigger, 'Sensor Above Threshold',
      'Fires when a sensor reading crosses above a value'),
  sensorBelowThreshold(RuleNodeCategory.trigger, 'Sensor Below Threshold',
      'Fires when a sensor reading crosses below a value'),
  deviceOnlineTrigger(RuleNodeCategory.trigger, 'Device Online',
      'Fires when a device comes online'),
  deviceOfflineTrigger(RuleNodeCategory.trigger, 'Device Offline',
      'Fires when a device goes offline'),
  deviceStatusChanged(RuleNodeCategory.trigger, 'Device Status Changed',
      'Fires when device online/offline status changes'),
  twinReportedChanged(RuleNodeCategory.trigger, 'Twin Reported Changed',
      'Fires when Digital Twin reported state updates'),
  twinDesiredChanged(RuleNodeCategory.trigger, 'Twin Desired Changed',
      'Fires when Digital Twin desired state updates'),
  manualTrigger(RuleNodeCategory.trigger, 'Manual Trigger',
      'Fires only when manually triggered by a user'),
  scheduledTrigger(RuleNodeCategory.trigger, 'Scheduled Trigger',
      'Fires on a time-based schedule'),

  // Conditions
  equalTo(
      RuleNodeCategory.condition, 'Equal To', 'Checks if a value equals X'),
  notEqualTo(RuleNodeCategory.condition, 'Not Equal To',
      'Checks if a value does not equal X'),
  greaterThan(RuleNodeCategory.condition, 'Greater Than',
      'Checks if a value is greater than X'),
  greaterThanOrEqual(RuleNodeCategory.condition, 'Greater Than or Equal',
      'Checks if a value is >= X'),
  lessThan(RuleNodeCategory.condition, 'Less Than',
      'Checks if a value is less than X'),
  lessThanOrEqual(RuleNodeCategory.condition, 'Less Than or Equal',
      'Checks if a value is <= X'),
  betweenRange(RuleNodeCategory.condition, 'Between Range',
      'Checks if a value is between min and max'),
  booleanCheck(RuleNodeCategory.condition, 'Boolean Check',
      'Checks if a value is true or false'),
  andGate(RuleNodeCategory.condition, 'AND',
      'All inputs must be true to pass'),
  orGate(RuleNodeCategory.condition, 'OR',
      'At least one input must be true to pass'),
  notGate(RuleNodeCategory.condition, 'NOT', 'Inverts the input value'),
  deviceOnlineCheck(RuleNodeCategory.condition, 'Device Online Check',
      'Checks if a device is currently online'),
  twinDesiredVsReported(RuleNodeCategory.condition, 'Twin State Comparison',
      'Compares Digital Twin desired vs reported state'),

  // Actions
  sendCommand(RuleNodeCategory.action, 'Send Command',
      'Sends a command to a device'),
  setActuator(RuleNodeCategory.action, 'Set Actuator',
      'Sets an actuator to a specified value'),
  updateTwinDesired(RuleNodeCategory.action, 'Update Twin Desired',
      'Updates the Digital Twin desired state'),
  executeScene(RuleNodeCategory.action, 'Execute Scene',
      'Activates an existing scene'),
  recordEvent(RuleNodeCategory.action, 'Record Event',
      'Records an automation event for monitoring'),
  logResult(
      RuleNodeCategory.action, 'Log Result', 'Logs a message to history'),
  stopFlow(RuleNodeCategory.action, 'Stop Flow',
      'Immediately stops the current rule execution'),

  // Flow control
  delay(RuleNodeCategory.flow, 'Delay',
      'Waits for a specified duration before continuing'),
  conditionalBranch(RuleNodeCategory.flow, 'Conditional Branch',
      'Routes execution based on a true/false condition'),
  merge(RuleNodeCategory.flow, 'Merge',
      'Merges multiple execution paths into one'),
  terminate(RuleNodeCategory.flow, 'Terminate',
      'Ends the flow and records the final result');

  final RuleNodeCategory category;
  final String displayName;
  final String description;

  const RuleNodeType(this.category, this.displayName, this.description);

  String get dbValue => name;

  IconData get icon => switch (this) {
        telemetryReceived => Icons.sensors,
        sensorValueChanged => Icons.change_circle,
        sensorAboveThreshold => Icons.arrow_upward,
        sensorBelowThreshold => Icons.arrow_downward,
        deviceOnlineTrigger => Icons.wifi,
        deviceOfflineTrigger => Icons.wifi_off,
        deviceStatusChanged => Icons.swap_horiz,
        twinReportedChanged => Icons.cloud_upload,
        twinDesiredChanged => Icons.cloud_download,
        manualTrigger => Icons.touch_app,
        scheduledTrigger => Icons.schedule,
        equalTo => Icons.drag_handle,
        notEqualTo => Icons.do_not_disturb_on,
        greaterThan => Icons.keyboard_arrow_right,
        greaterThanOrEqual => Icons.chevron_right,
        lessThan => Icons.keyboard_arrow_left,
        lessThanOrEqual => Icons.chevron_left,
        betweenRange => Icons.unfold_more,
        booleanCheck => Icons.toggle_on,
        andGate => Icons.join_full,
        orGate => Icons.join_inner,
        notGate => Icons.block,
        deviceOnlineCheck => Icons.wifi_find,
        twinDesiredVsReported => Icons.compare_arrows,
        sendCommand => Icons.send,
        setActuator => Icons.tune,
        updateTwinDesired => Icons.cloud_sync,
        executeScene => Icons.movie,
        recordEvent => Icons.event_note,
        logResult => Icons.receipt_long,
        stopFlow => Icons.stop_circle,
        delay => Icons.hourglass_empty,
        conditionalBranch => Icons.call_split,
        merge => Icons.call_merge,
        terminate => Icons.cancel,
      };

  bool get isTrigger => category == RuleNodeCategory.trigger;
  bool get isCondition => category == RuleNodeCategory.condition;
  bool get isAction => category == RuleNodeCategory.action;
  bool get isFlow => category == RuleNodeCategory.flow;

  static RuleNodeType fromString(String value) {
    return RuleNodeType.values.firstWhere(
      (t) => t.name == value || t.dbValue == value,
      orElse: () => RuleNodeType.manualTrigger,
    );
  }

  List<NodePortDef> get inputPorts => switch (this) {
        // Triggers have no inputs
        telemetryReceived ||
        sensorValueChanged ||
        sensorAboveThreshold ||
        sensorBelowThreshold ||
        deviceOnlineTrigger ||
        deviceOfflineTrigger ||
        deviceStatusChanged ||
        twinReportedChanged ||
        twinDesiredChanged ||
        manualTrigger ||
        scheduledTrigger =>
          [],
        // AND/OR gates accept multiple boolean inputs
        andGate || orGate => [
            const NodePortDef(id: 'in_a', label: 'A', dataType: PortDataType.boolean),
            const NodePortDef(id: 'in_b', label: 'B', dataType: PortDataType.boolean),
          ],
        // NOT gate accepts single boolean
        notGate => [
            const NodePortDef(
                id: 'in', label: 'Input', dataType: PortDataType.boolean),
          ],
        // Conditions accept an event/value input
        equalTo ||
        notEqualTo ||
        greaterThan ||
        greaterThanOrEqual ||
        lessThan ||
        lessThanOrEqual ||
        betweenRange ||
        booleanCheck ||
        deviceOnlineCheck ||
        twinDesiredVsReported =>
          [
            const NodePortDef(
                id: 'in', label: 'Input', dataType: PortDataType.any),
          ],
        // Conditional branch takes a boolean
        conditionalBranch => [
            const NodePortDef(
                id: 'in', label: 'Condition', dataType: PortDataType.boolean),
          ],
        // Merge takes two inputs
        merge => [
            const NodePortDef(id: 'in_a', label: 'A', dataType: PortDataType.any),
            const NodePortDef(id: 'in_b', label: 'B', dataType: PortDataType.any),
          ],
        // Actions and flow control take a flow input
        sendCommand ||
        setActuator ||
        updateTwinDesired ||
        executeScene ||
        recordEvent ||
        logResult ||
        stopFlow ||
        delay ||
        terminate =>
          [
            const NodePortDef(
                id: 'in', label: 'Input', dataType: PortDataType.any),
          ],
      };

  List<NodePortDef> get outputPorts => switch (this) {
        // Triggers output an event
        telemetryReceived ||
        sensorValueChanged ||
        sensorAboveThreshold ||
        sensorBelowThreshold ||
        deviceOnlineTrigger ||
        deviceOfflineTrigger ||
        deviceStatusChanged ||
        twinReportedChanged ||
        twinDesiredChanged ||
        manualTrigger ||
        scheduledTrigger =>
          [
            const NodePortDef(
                id: 'out', label: 'Event', dataType: PortDataType.event),
          ],
        // Conditions output boolean
        equalTo ||
        notEqualTo ||
        greaterThan ||
        greaterThanOrEqual ||
        lessThan ||
        lessThanOrEqual ||
        betweenRange ||
        booleanCheck ||
        andGate ||
        orGate ||
        notGate ||
        deviceOnlineCheck ||
        twinDesiredVsReported =>
          [
            const NodePortDef(
                id: 'out', label: 'Result', dataType: PortDataType.boolean),
          ],
        // Conditional branch has true/false outputs
        conditionalBranch => [
            const NodePortDef(
                id: 'true', label: 'True', dataType: PortDataType.any),
            const NodePortDef(
                id: 'false', label: 'False', dataType: PortDataType.any),
          ],
        // Actions output flow
        sendCommand ||
        setActuator ||
        updateTwinDesired ||
        executeScene ||
        recordEvent ||
        logResult =>
          [
            const NodePortDef(
                id: 'out', label: 'Next', dataType: PortDataType.any),
          ],
        // Delay outputs after waiting
        delay => [
            const NodePortDef(
                id: 'out', label: 'After', dataType: PortDataType.any),
          ],
        // Merge outputs combined
        merge => [
            const NodePortDef(
                id: 'out', label: 'Output', dataType: PortDataType.any),
          ],
        // Terminal nodes have no output
        stopFlow || terminate => [],
      };

  List<String> get requiredConfigKeys => switch (this) {
        sensorAboveThreshold ||
        sensorBelowThreshold =>
          ['device_id', 'sensor_key', 'threshold'],
        sensorValueChanged => ['device_id', 'sensor_key'],
        telemetryReceived => ['device_id'],
        deviceOnlineTrigger ||
        deviceOfflineTrigger ||
        deviceStatusChanged =>
          ['device_id'],
        twinReportedChanged || twinDesiredChanged => ['device_id'],
        scheduledTrigger => ['cron_expression'],
        manualTrigger => [],
        equalTo ||
        notEqualTo ||
        greaterThan ||
        greaterThanOrEqual ||
        lessThan ||
        lessThanOrEqual =>
          ['value'],
        betweenRange => ['min_value', 'max_value'],
        booleanCheck => ['expected'],
        andGate || orGate || notGate => [],
        deviceOnlineCheck => ['device_id'],
        twinDesiredVsReported => ['device_id', 'attribute_key'],
        sendCommand => ['device_id', 'command_type'],
        setActuator => ['device_id', 'actuator_key', 'value'],
        updateTwinDesired => ['device_id', 'attributes'],
        executeScene => ['scene_id'],
        recordEvent => ['event_name'],
        logResult => ['message'],
        stopFlow || terminate => [],
        delay => ['duration_ms'],
        conditionalBranch => [],
        merge => [],
      };
}

enum PortDataType {
  any,
  boolean,
  number,
  string,
  event;

  bool canConnectTo(PortDataType target) {
    if (this == any || target == any) return true;
    if (this == event && target != event) return true;
    return this == target;
  }
}

class NodePortDef {
  final String id;
  final String label;
  final PortDataType dataType;

  const NodePortDef({
    required this.id,
    required this.label,
    required this.dataType,
  });
}
