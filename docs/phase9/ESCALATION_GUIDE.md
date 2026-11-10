# Phase 9 — Escalation Engine Guide

## Overview

The escalation engine ensures that unresolved alarms are automatically escalated to additional personnel at configurable intervals. Escalation is durable — it survives Edge Function restarts because all scheduling state lives in PostgreSQL.

## Data Model

### Escalation Policy

A named policy attached to a project and organization. Each policy contains an ordered list of stages.

| Field | Purpose |
|-------|---------|
| name | Human-readable policy name |
| description | Optional explanation |
| project_id | Owning project (RLS boundary) |
| organization_id | Owning organization |
| is_enabled | Toggle on/off |
| repeat_after_all_stages | Whether to cycle back to stage 1 after all stages complete |

### Escalation Stage

An ordered step within a policy.

| Field | Purpose |
|-------|---------|
| stage_order | 1-based index within the policy |
| delay_minutes | Minutes to wait before executing this stage |
| notify_user_ids | UUID array of users to notify |
| notify_channel | Notification channel (in_app, email, push) |

### Escalation Task

A durable work item representing a scheduled notification.

| Field | Purpose |
|-------|---------|
| alarm_id | The alarm being escalated |
| escalation_policy_id | The governing policy |
| escalation_stage_id | Which stage this task belongs to |
| stage_order | Stage number |
| status | pending / processing / completed / cancelled / failed |
| scheduled_at | When this task should execute |
| processed_at | When it was actually processed |
| error_message | Failure details (if any) |

## How Escalation Works

1. When an alarm is raised with an `escalation_policy_id`, the alarm-processor `start_escalation` endpoint creates escalation tasks for all stages of the policy.
2. Each task's `scheduled_at` is computed as: `alarm.created_at + SUM(delay_minutes for stages 1..N)`.
3. The `process_escalations` action polls for tasks where `scheduled_at <= NOW()` and `status = 'pending'`.
4. For each due task:
   - Validate that the alarm is still active or acknowledged (not cleared).
   - Validate each target user is a member of the alarm's project.
   - Check quiet hours for each recipient.
   - Create notification records and outbox entries.
   - Update the alarm's `escalation_stage`.
   - Mark the task as completed.
5. If the alarm is cleared, all remaining pending tasks are cancelled.

## Quiet Hours

Escalation respects per-user quiet hours configured in `notification_preferences`:
- `quiet_hours_enabled`: boolean toggle
- `quiet_hours_start` / `quiet_hours_end`: time values (e.g., 22:00 to 07:00)
- `timezone`: IANA timezone string

During quiet hours, non-critical notifications are deferred. Critical alarm notifications (severity = critical) bypass quiet hours.

## Cancellation

When an alarm is cleared (via UI, rule engine, or auto-clear):
- The `clearAlarm` handler in automation-engine sets all pending escalation tasks to `cancelled`.
- No further notifications are sent for that alarm.

## Policy Repeat

If `repeat_after_all_stages` is true and the alarm remains unresolved after all stages complete, escalation restarts from stage 1. This continues until the alarm is cleared.

## Limitations

- Email and push notification channels are stub implementations. In-app notifications are fully functional.
- A notification recorded in the database is not proof that an email or push notification reached a user's device.
- Escalation task polling frequency depends on how often the alarm-processor function is invoked (e.g., via cron or external trigger).
