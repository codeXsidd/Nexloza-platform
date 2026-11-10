# NEXLOZA — Phase 9 Audit Report

## Alarm Engine, Escalation and Notification System

**Date:** 2026-11-10
**Phase:** 9 of planned multi-phase delivery
**Baseline commit:** 7fc7c12 (Phase 8 — Visual Rule Engine, 594 tests passing)
**Branch:** main
**Git state:** Clean, pushed to origin

---

## 1. Baseline Verification

| Check | Result |
|-------|--------|
| Analyzer issues | 0 |
| Test count | 594 passing, 0 failing |
| Git status | Clean working tree |
| Remote sync | Up to date with origin/main |

---

## 2. Database Migrations (19 total)

| # | File | Purpose |
|---|------|---------|
| 00001 | profiles.sql | User profiles |
| 00002 | organizations.sql | Organizations and membership |
| 00003 | projects.sql | Projects, project_members, RLS helpers (`is_project_member`, `can_modify_project`) |
| 00004 | devices.sql | Devices table with `is_online`, `last_seen_at` |
| 00005 | sensors_actuators.sql | Sensors and actuators |
| 00006 | telemetry.sql | Telemetry ingestion |
| 00007 | dashboards.sql | Dashboard tables |
| 00008 | automations.sql | Automations, triggers, actions |
| 00009 | scenes.sql | Scenes |
| 00010 | notifications.sql | Notifications and notification_preferences |
| 00011 | integrations.sql | Integrations |
| 00012 | ai.sql | AI assistant |
| 00013 | audit.sql | Audit log |
| 00014 | firmware.sql | Firmware metadata |
| 00015 | validation_fixes.sql | Validation fixes |
| 00016 | invitations.sql | Invitations |
| 00017 | dashboard_phase6.sql | Phase 6 dashboard builder |
| 00018 | virtual_devices_phase7.sql | Virtual devices, Digital Twin (`device_twin_state`) |
| 00019 | rule_engine_phase8.sql | Rule engine graph model, versions, event inbox, execution tracing |

**Next migration:** 00020_alarm_engine_phase9.sql

---

## 3. Edge Functions (6 total)

| Function | Purpose |
|----------|---------|
| webhook-handler | External webhook processing |
| ai-assistant | Grok AI integration |
| telemetry-ingest | Telemetry ingestion pipeline |
| device-auth | Device authentication |
| device-command | Device command dispatch |
| automation-engine | Rule engine + legacy automation evaluation (1194 lines) |

**Phase 9 plan:** Add `alarm-processor` Edge Function for escalation scheduling and notification outbox processing. Extend `automation-engine` with alarm action handlers.

---

## 4. RLS Helper Functions

Defined in migration 00003:

```sql
-- is_project_member(p_id uuid) → boolean
-- Returns true if auth.uid() is the project owner OR a project_member
-- Used by: SELECT policies across devices, sensors, telemetry, dashboards, automations,
--          scenes, notifications, rule_versions, rule_events, device_twin_state

-- can_modify_project(p_id uuid) → boolean
-- Returns true if auth.uid() is the project owner OR has role 'admin'/'developer'
-- Used by: INSERT/UPDATE/DELETE policies for modifiable resources
```

Phase 9 alarm tables will use these same helpers for RLS.

---

## 5. Existing Notification Infrastructure

### Schema (migration 00010)
- **notifications** table: id, user_id (FK profiles, NOT NULL), project_id (FK projects), title, body, category (enum: device/automation/security/system/alert), severity (enum: info/warning/critical), is_read, data (jsonb), created_at
- **notification_preferences** table: id, user_id, category, push_enabled, email_enabled, in_app_enabled, unique(user_id, category)
- RLS: users view/update own notifications, manage own preferences
- Indexes: user+created_at desc, unread filter

### Key observations for Phase 9:
- `user_id` is NOT NULL — notification requires a specific target user
- No `alarm_id` column — must add via migration
- No `read_at` timestamp — only boolean `is_read`
- No `navigation_target` — no deep-link support yet
- Severity enum has only 3 values (info/warning/critical) — alarm severity needs 5 levels (critical/high/medium/warning/informational), handled in alarm entity, mapped to notification severity
- Category enum already has 'alert' — can use for alarm notifications

### Flutter entities (notification_entity.dart)
- `NotificationCategory` enum: device, automation, security, system, alert
- `NotificationSeverity` enum: info, warning, critical
- `AppNotification` class with `fromJson` factory

### Repository (notification_repository.dart)
- `getNotifications()` — fetches for current user, limit 50
- `markAsRead(id)`, `markAllAsRead()`, `deleteNotification(id)`
- Provider: `notificationRepositoryProvider`

### Screen (notifications_screen.dart)
- Full notification list with mark-all-read, dismissible tiles, severity colors, category icons
- Phase 9 will extend this with alarm-linked notifications and navigation targets

---

## 6. Existing Dashboard Widgets

### Widget Types (widget_type.dart)
- 42 widget types in 6 categories (control, sensor, chart, status, industrial, info)
- Already registered: `alarmIndicator` (status category), `alarmPanel` (industrial category)

### Existing Alarm Widget Renderers

**buildAlarmIndicator** (status_widgets.dart:215-263):
- Simple active/clear boolean indicator
- Uses `data.boolValue` — currently expects true/false
- Shows warning icon (active) or check icon (clear)
- Phase 9: Enhance to query actual alarm count from alarm tables

**buildAlarmPanel** (industrial_widgets.dart:330-457):
- List-based alarm panel expecting `data.currentValue` as `List<Map<String, dynamic>>`
- Renders severity-colored alarm list with message text
- Shows "All Clear" when empty, count badge in header
- Phase 9: Connect to real alarm data source from alarms table

### Widget Registry (widget_registrations.dart)
- Already registers both alarm widgets — no registration changes needed
- Phase 9 will add new alarm-specific widget types (alarm count, severity distribution, recent activity)

---

## 7. Rule Engine (Phase 8)

### Node Types (rule_node_type.dart)
- 35 node types: 11 triggers, 13 conditions, 7 actions, 4 flow control
- Current action nodes: sendCommand, setActuator, updateTwinDesired, executeScene, recordEvent, logResult, stopFlow
- **Phase 9 additions:** raiseAlarm, updateAlarmSeverity, clearAlarm, addAlarmComment (4 new action nodes → 39 total)

### Edge Function (automation-engine/index.ts)
- `getNodeCategory()` — hardcoded arrays for triggers/conditions/actions; must add alarm action types to actions array
- `executeAction()` — switch statement handling 7 action types; must add 4 alarm action cases
- `processGraphRules()` — graph evaluation pipeline with cooldown, rate limiting, dry-run support
- All alarm actions must respect `dryRun` flag (no side effects in dry-run mode)

### Integration points:
1. Add alarm node types to `RuleNodeType` enum in Dart
2. Add node type entries to `getNodeCategory()` actions array in Edge Function
3. Add alarm action handlers to `executeAction()` switch statement
4. Alarm actions write to alarms table using service-role client (server-side only)

---

## 8. Digital Twin (Phase 7)

### Schema (migration 00018)
- `device_twin_state` table: device_id (unique), reported_state (jsonb), desired_state (jsonb), reported_version, desired_version, reported_at, desired_at, sync_status (synced/pending/failed/stale), last_sync_at
- Full RLS via device → project join using `is_project_member`/`can_modify_project`

### Phase 9 alarm sources from Digital Twin:
- **Device offline alarm:** Triggered when `devices.is_online = false` and last_seen_at exceeds threshold
- **Stale data alarm:** Triggered when `device_twin_state.reported_at` exceeds staleness threshold
- **Twin mismatch alarm:** Triggered when `sync_status = 'failed'` or desired ≠ reported beyond threshold

---

## 9. Devices Table

Key fields relevant to Phase 9:
- `is_online` (boolean, default false)
- `last_seen_at` (timestamptz, nullable)
- `is_virtual` (boolean, default false) — from Phase 7
- `simulation_profile` (text, nullable) — from Phase 7
- `project_id` (FK projects)

---

## 10. Files with Alarm/Notification References

55 files reference alarm or notification keywords. Key files that Phase 9 must modify or extend:
- `backend/supabase/functions/automation-engine/index.ts` — add alarm action handlers
- `app/lib/features/rule_engine/domain/entities/rule_node_type.dart` — add 4 alarm node types
- `app/lib/features/notifications/` — extend entity, repository, screen
- `app/lib/features/dashboards/presentation/widgets/renderers/status_widgets.dart` — enhance alarm indicator
- `app/lib/features/dashboards/presentation/widgets/renderers/industrial_widgets.dart` — enhance alarm panel
- `app/lib/features/dashboards/domain/entities/widget_type.dart` — add new alarm widget types
- `app/lib/routing/app_router.dart` — add alarm routes
- `app/lib/routing/route_names.dart` — add alarm route names
- `app/lib/features/home/presentation/widgets/quick_actions_widget.dart` — add Alarms quick action

---

## 11. Risk Assessment

| Risk | Mitigation |
|------|-----------|
| Alarm storms from noisy sensors | Stable alarm key deduplication + hysteresis + cooldown |
| Notification flooding | Outbox pattern with bounded retry + quiet hours |
| Escalation tasks lost on restart | Durable scheduling via database (escalation_tasks table) |
| RLS bypass on alarm data | Use existing `is_project_member`/`can_modify_project` helpers |
| Rule engine action failure blocking telemetry | Alarm actions are non-blocking; failures logged but don't halt pipeline |
| Unbounded notification streams | Pagination, retention limits, dead-letter for failed deliveries |

---

## 12. Conclusion

The codebase is in a clean, stable state at 594 tests with 0 analyzer issues. Existing infrastructure for notifications, dashboard widgets, rule engine, and Digital Twin provides solid integration points. The alarm engine can be built incrementally without disrupting existing functionality.

**Ready to proceed with Phase 9 implementation.**
