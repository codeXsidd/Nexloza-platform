# Phase 9 — System Architecture

## Data Flow

```
Telemetry Ingest          Manual Action         Rule Engine
      |                        |                     |
      v                        v                     v
+------------------------------------------------------------------+
|                        ALARM ENGINE                               |
|  alarm_configurations   alarms (upsert by alarm_key)              |
|  alarm_activity (audit trail)                                     |
+------------------------------------------------------------------+
      |                                          |
      v                                          v
+-------------------------+        +----------------------------+
|   ESCALATION ENGINE     |        |   NOTIFICATION OUTBOX      |
|  escalation_policies    |------->|  notification_outbox       |
|  escalation_stages      |        |  (in_app / email / push)   |
|  escalation_tasks       |        +----------------------------+
+-------------------------+                     |
                                                v
                                    +---------------------+
                                    |     DELIVERY        |
                                    |  In-app: immediate  |
                                    |  Email: stub        |
                                    |  Push: stub         |
                                    +---------------------+
```

## Database Tables (Migration 00020)

| Table | Purpose |
|-------|---------|
| alarms | Core alarm records with lifecycle state |
| alarm_configurations | Threshold rules for automatic alarm generation |
| alarm_activity | Audit trail for every alarm lifecycle event |
| escalation_policies | Named escalation policy definitions |
| escalation_stages | Ordered stages within a policy |
| escalation_tasks | Durable scheduled escalation work items |
| notification_outbox | Reliable delivery via outbox pattern |

Extended tables: `notifications` (+alarm_id, read_at, navigation_target), `notification_preferences` (+quiet hours, timezone, min_severity).

## Edge Functions

| Function | Role |
|----------|------|
| automation-engine | Handles 4 alarm action nodes (raiseAlarm, updateAlarmSeverity, clearAlarm, addAlarmComment) within graph rule evaluation |
| alarm-processor | Processes pending escalation tasks and notification outbox entries. Supports `process_escalations`, `process_outbox`, `process_all`, and `start_escalation` actions |

## Flutter Layer

### Domain Entities (7 files)
alarm_severity, alarm_status, alarm_source, alarm_entity (+ AlarmStats), alarm_configuration_entity, alarm_activity_entity, escalation_policy_entity (+ EscalationStage)

### Data Layer (3 files)
alarm_repository, alarm_config_repository, escalation_repository

### Providers (1 file)
alarm_providers — activeAlarms, alarmHistory, alarmDetail, alarmActivity, alarmStats, alarmConfigs, escalationPolicies, escalationPolicyDetail, AlarmActionNotifier

### Screens (9 files)
alarms_overview, active_alarms, alarm_history, alarm_detail, alarm_config, create_alarm_config, escalation_policies, escalation_policy_detail, notification_preferences

### Dashboard Widgets (5 new + 2 enhanced)
alarmCount, criticalAlarmCount, unacknowledgedAlarmCount, alarmSeverityDistribution, recentAlarmActivity. Enhanced: alarmIndicator, alarmPanel.

### Rule Engine (4 new node types)
raiseAlarm, updateAlarmSeverity, clearAlarm, addAlarmComment — added to RuleNodeType enum (39 total), node_config_panel, and automation-engine Edge Function.

## Routes (9 new)
`/alarms`, `/alarms/active`, `/alarms/history`, `/alarms/:id`, `/alarms/configurations`, `/alarms/configurations/create`, `/alarms/escalation`, `/alarms/escalation/:id`, `/notifications/preferences`
