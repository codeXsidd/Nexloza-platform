# NEXLOZA — Phase 9 Implementation Plan

## Alarm Engine, Escalation and Notification System

**Date:** 2026-11-10
**Baseline:** 7fc7c12 (594 tests, 0 issues)

---

## Layer 1: Database Schema (Migration 00020)

### New Tables
1. **alarms** — Core alarm records
   - id, alarm_key (unique stable key for deduplication), project_id, device_id, organization_id
   - severity (critical/high/medium/warning/informational), status (active/acknowledged/cleared)
   - source (sensor_threshold/repeated_telemetry/device_offline/stale_data/twin_mismatch/actuator_failure/virtual_device_fault/rule_action/manual)
   - title, message, category, condition_value, threshold_value
   - hysteresis_clear_value, acknowledged_by, acknowledged_at, cleared_by, cleared_at, cleared_reason
   - occurrence_count, first_occurred_at, last_occurred_at, data (jsonb)
   - escalation_policy_id, escalation_stage, escalated_at
   - created_at, updated_at

2. **alarm_configurations** — Per-device or per-project alarm rules
   - id, project_id, device_id (nullable), organization_id
   - name, source, sensor_key, condition_operator, threshold_value
   - hysteresis_enabled, hysteresis_clear_value, debounce_seconds, cooldown_seconds
   - severity, category, message_template, is_enabled
   - created_at, updated_at

3. **alarm_activity** — Audit trail for alarm lifecycle events
   - id, alarm_id, activity_type (created/acknowledged/escalated/cleared/severity_changed/comment_added/suppressed)
   - performed_by, comment, previous_severity, new_severity, data (jsonb)
   - created_at

4. **escalation_policies** — Escalation policy definitions
   - id, project_id, organization_id, name, description, is_enabled
   - created_at, updated_at

5. **escalation_stages** — Ordered stages within a policy
   - id, policy_id, stage_number, delay_minutes
   - notification_targets (jsonb array of user_ids)
   - action_type (notify/reassign/auto_acknowledge)
   - created_at

6. **escalation_tasks** — Durable scheduled escalation work items
   - id, alarm_id, policy_id, stage_id, scheduled_at, executed_at
   - status (pending/executed/cancelled), result (jsonb)
   - created_at

7. **notification_outbox** — Outbox pattern for reliable notification delivery
   - id, notification_id (FK notifications), channel (in_app/email/push)
   - recipient_user_id, payload (jsonb)
   - status (pending/processing/delivered/failed/dead_letter)
   - attempts, max_attempts, last_attempt_at, next_retry_at
   - idempotency_key (unique), error_message
   - created_at

### Extended Tables
- **notifications**: Add `alarm_id` (FK alarms, nullable), `read_at` (timestamptz), `navigation_target` (text)

### RLS Policies
All alarm tables use `is_project_member(project_id)` for SELECT and `can_modify_project(project_id)` for INSERT/UPDATE/DELETE. Escalation policies follow the same pattern.

---

## Layer 2: Domain Entities

### New files in `app/lib/features/alarms/domain/entities/`
1. **alarm_severity.dart** — `AlarmSeverity` enum (critical, high, medium, warning, informational)
2. **alarm_status.dart** — `AlarmStatus` enum (active, acknowledged, cleared)
3. **alarm_source.dart** — `AlarmSource` enum (9 sources)
4. **alarm_entity.dart** — `Alarm` class with fromJson, toAlarmKey(), severity color mapping
5. **alarm_configuration_entity.dart** — `AlarmConfiguration` class with fromJson
6. **alarm_activity_entity.dart** — `AlarmActivity` class with ActivityType enum
7. **escalation_policy_entity.dart** — `EscalationPolicy` class with stages

---

## Layer 3: Data Layer

### New files in `app/lib/features/alarms/data/`
1. **alarm_repository.dart** — AlarmRepository
   - getActiveAlarms(projectId), getAlarmHistory(projectId), getAlarmById(id)
   - acknowledgeAlarm(id), clearAlarm(id, reason), addComment(id, comment)
   - getAlarmStats(projectId) — counts by severity/status
   - Provider: alarmRepositoryProvider

2. **alarm_config_repository.dart** — AlarmConfigRepository
   - getConfigurations(projectId), createConfiguration(), updateConfiguration(), deleteConfiguration()
   - Provider: alarmConfigRepositoryProvider

3. **escalation_repository.dart** — EscalationRepository
   - getPolicies(projectId), createPolicy(), updatePolicy(), deletePolicy()
   - getStages(policyId), addStage(), updateStage(), removeStage()
   - Provider: escalationRepositoryProvider

### Extended files
4. **notification_repository.dart** — Extend with:
   - getNotificationsWithAlarm() — join notifications + alarms
   - getDeliveryHistory(notificationId)
   - updatePreferences() with quiet hours support

---

## Layer 4: Rule Engine Integration

### Dart (rule_node_type.dart)
Add 4 new action node types:
- `raiseAlarm` — Raises or re-raises an alarm with configurable severity/message
- `updateAlarmSeverity` — Changes severity of an existing alarm
- `clearAlarm` — Clears an alarm with reason
- `addAlarmComment` — Adds a comment to an alarm's activity log

Update icon mapping, port definitions, config keys for all 4.

### Edge Function (automation-engine/index.ts)
1. Add `"raiseAlarm", "updateAlarmSeverity", "clearAlarm", "addAlarmComment"` to `getNodeCategory()` actions array
2. Add 4 case handlers to `executeAction()` switch:
   - **raiseAlarm**: Upsert alarm by alarm_key (deduplication), increment occurrence_count if existing, insert alarm_activity
   - **updateAlarmSeverity**: Update severity on existing alarm, record activity
   - **clearAlarm**: Set status='cleared', record activity with reason
   - **addAlarmComment**: Insert alarm_activity with type 'comment_added'
3. All 4 respect dryRun flag

---

## Layer 5: Alarm Processor Edge Function

New Edge Function: `alarm-processor`
- **Escalation scheduler**: Polls escalation_tasks where scheduled_at <= now and status = 'pending', executes stage actions (create notifications for targets), advances to next stage
- **Outbox processor**: Polls notification_outbox where status = 'pending' or (status = 'failed' and next_retry_at <= now), processes each entry:
  - in_app: Already inserted in notifications table, mark delivered
  - email: Provider abstraction (stub — not production-ready without real provider)
  - push: Provider abstraction (stub — not production-ready without real provider)
- Bounded retry with exponential backoff, max 3 attempts, then dead_letter
- Idempotency via outbox idempotency_key

---

## Layer 6: Flutter Screens

### New files in `app/lib/features/alarms/presentation/`

**Providers (1 file):**
1. **alarm_providers.dart** — activeAlarmsProvider, alarmHistoryProvider, alarmDetailProvider, alarmStatsProvider, alarmConfigsProvider, escalationPoliciesProvider, AlarmActionNotifier

**Screens (9 files):**
1. **alarms_overview_screen.dart** — Summary dashboard: alarm counts by severity, quick filters
2. **active_alarms_screen.dart** — List of active alarms with severity sorting, bulk acknowledge
3. **alarm_history_screen.dart** — All alarms including cleared, filterable by status/severity/date
4. **alarm_detail_screen.dart** — Full alarm detail with activity timeline, acknowledge/clear actions
5. **alarm_config_screen.dart** — List alarm configurations, enable/disable, create new
6. **create_alarm_config_screen.dart** — Form: source, sensor_key, threshold, hysteresis, severity, template
7. **escalation_policies_screen.dart** — List policies, create/edit/delete
8. **escalation_policy_detail_screen.dart** — Policy stages editor, add/remove/reorder stages
9. **notification_preferences_screen.dart** — Per-category preferences with quiet hours, timezone

### Extended screens
- **notifications_screen.dart** — Add alarm-linked notification badges, navigation to alarm detail

---

## Layer 7: Dashboard & Digital Twin Integration

### Dashboard widgets
- Add new widget types to `NexWidgetType` enum: alarmCountWidget, criticalAlarmCount, alarmSeverityDistribution, recentAlarmActivity, unacknowledgedCount
- Add widget renderers in new file `alarm_widgets.dart`
- Register in WidgetRegistry
- Enhance existing `buildAlarmIndicator` and `buildAlarmPanel` to query real alarm data

### Digital Twin integration
- Alarm sources that monitor device_twin_state:
  - Device offline: Check devices.is_online + last_seen_at threshold
  - Stale data: Check device_twin_state.reported_at staleness
  - Twin mismatch: Check sync_status = 'failed' or desired ≠ reported

---

## Layer 8: Routing & Navigation

### New route names (route_names.dart)
alarms, activeAlarms, alarmHistory, alarmDetail, alarmConfigurations, createAlarmConfig, escalationPolicies, escalationPolicyDetail, notificationPreferences

### New routes (app_router.dart)
- `/alarms` — Alarms overview
- `/alarms/active` — Active alarms list
- `/alarms/history` — Alarm history
- `/alarms/:id` — Alarm detail
- `/alarms/configurations` — Alarm configurations
- `/alarms/configurations/create` — Create alarm config
- `/alarms/escalation` — Escalation policies
- `/alarms/escalation/:id` — Escalation policy detail
- `/notifications/preferences` — Notification preferences

### Home screen
- Add "Alarms" quick action chip to QuickActionsWidget

---

## Layer 9: Tests

Target: 100+ new tests across:
1. **Alarm entity tests** — Alarm, AlarmConfiguration, AlarmActivity, EscalationPolicy serialization
2. **Alarm severity/status tests** — Enum values, ordering, color mapping
3. **Alarm lifecycle tests** — Active → Acknowledged → Cleared transitions, deduplication by alarm_key
4. **Alarm configuration tests** — Hysteresis, debounce, cooldown logic
5. **Rule engine integration tests** — raiseAlarm/updateAlarmSeverity/clearAlarm/addAlarmComment node types
6. **Escalation policy tests** — Stage ordering, target validation
7. **Notification outbox tests** — Outbox entry creation, retry logic, dead-letter
8. **Widget tests** — Alarm widget renderers
9. **Security tests** — RLS validation, org-scoped access

---

## Layer 10: Documentation

1. `docs/phase9/ARCHITECTURE.md` — System architecture and data flow
2. `docs/phase9/ALARM_MODEL.md` — Alarm data model and lifecycle
3. `docs/phase9/ALARM_SOURCES.md` — 9 alarm source types
4. `docs/phase9/ESCALATION_GUIDE.md` — Escalation policy configuration
5. `docs/phase9/NOTIFICATION_SYSTEM.md` — Notification delivery and outbox
6. `docs/phase9/RULE_ENGINE_INTEGRATION.md` — Alarm action nodes in rule engine
7. `docs/phase9/DASHBOARD_WIDGETS.md` — Alarm dashboard widgets
8. `docs/phase9/USER_GUIDE.md` — End-user alarm management guide
9. `docs/phase9/SECURITY.md` — Security model and tenant isolation
10. `docs/phase9/TESTING.md` — Test coverage report

---

## Implementation Order

1. Migration 00020 (schema foundation)
2. Domain entities (Dart models)
3. Data layer (repositories)
4. Rule engine integration (Dart node types + Edge Function handlers)
5. Alarm processor Edge Function
6. Flutter screens + providers
7. Notification system extension
8. Dashboard widget integration
9. Digital Twin integration
10. Routing and navigation
11. Tests
12. Documentation
13. Quality gates (analyzer, tests, APK build)
14. Completion report + commit
