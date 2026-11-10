# Phase 9 — Security Model

## Row-Level Security (RLS)

All alarm tables use Supabase RLS policies enforced at the database level.

### Helper Functions

Phase 9 reuses the RLS helper functions defined in `00003_projects.sql`:

- `is_project_member(project_id)` — Returns true if `auth.uid()` belongs to the project
- `can_modify_project(project_id)` — Returns true if `auth.uid()` has write access

### Policy Matrix

| Table | SELECT | INSERT | UPDATE | DELETE |
|-------|--------|--------|--------|--------|
| alarms | is_project_member | can_modify_project | can_modify_project | can_modify_project |
| alarm_configurations | is_project_member | can_modify_project | can_modify_project | can_modify_project |
| alarm_activity | is_project_member | can_modify_project | — | — |
| escalation_policies | is_project_member | can_modify_project | can_modify_project | can_modify_project |
| escalation_stages | is_project_member | can_modify_project | can_modify_project | can_modify_project |
| escalation_tasks | is_project_member | — | can_modify_project | — |
| notification_outbox | is_project_member | — | — | — |

### Notification Preferences

Notification preferences use per-user RLS:
- SELECT: `user_id = auth.uid()`
- INSERT/UPDATE: `user_id = auth.uid()`

Users can only view and modify their own preferences.

## Authorization Constraints

### Organization Boundary

- Users can only view alarms within projects they belong to
- Users can only create/modify alarm configurations for authorized projects
- Escalation policies are scoped to organizations and projects

### Escalation Target Validation

- Notification recipients are validated against organization membership before delivery
- The alarm-processor checks `is_project_member` for each target user in an escalation stage
- Unauthorized targets are skipped and logged — they do not receive notifications

### Escalation Policy Scope

- Policies cannot target users outside the organization
- Stage `notify_user_ids` are validated at execution time, not just creation time
- This prevents privilege escalation via stale user lists

## Credential Security

### Service-Role Keys

- Service-role credentials are used only in Edge Functions (server-side)
- Never exposed in Flutter application code
- Never exposed in logs, assets, or committed configuration

### MQTT Credentials

- Not exposed to alarm screens or escalation UI
- Alarm data flows through Supabase, not direct MQTT connections

### API Keys

- No API credentials are exposed in the Flutter application
- All sensitive operations go through Supabase Edge Functions

## Audit Trail

Every alarm lifecycle event is recorded in `alarm_activity`:

| Activity Type | Recorded Data |
|--------------|---------------|
| created | Source, initial severity, triggering values |
| acknowledged | User ID, timestamp |
| cleared | User ID, reason, timestamp |
| severity_changed | Old severity, new severity |
| escalated | Stage number, notified users |
| comment_added | Comment text, user ID |
| configuration_changed | What changed |

The audit trail is append-only — entries cannot be updated or deleted through normal operations.

## Manual Clear Recording

A user cannot manually clear a condition that should remain active without recording that it was manually cleared. The `cleared_reason` field is required when clearing an alarm, and the activity entry records who cleared it and when.

## Failure Isolation

- Notification delivery failures do not block telemetry ingestion or rule evaluation
- A failed escalation task does not prevent other tasks from processing
- Dead-lettered notifications are preserved for investigation
- One broken alarm widget does not crash the entire dashboard
