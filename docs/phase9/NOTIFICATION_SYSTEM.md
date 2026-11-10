# Phase 9 — Notification System

## Architecture

The notification system uses the **outbox pattern** for reliable delivery. Every notification is first written to the database, then a corresponding outbox entry handles actual delivery with retry semantics.

```
Alarm Event / Escalation Task
        |
        v
  notifications table (INSERT)
        |
        v
  notification_outbox table (INSERT)
        |
        v
  alarm-processor: process_outbox
        |
        +--> in_app: mark delivered (immediate)
        +--> email: stub (logged, marked delivered)
        +--> push: stub (logged, marked delivered)
```

## Outbox Entry Lifecycle

| Status | Meaning |
|--------|---------|
| pending | Awaiting first delivery attempt |
| processing | Currently being processed |
| delivered | Successfully delivered |
| failed | Delivery attempted but failed (will retry) |
| dead_letter | Failed after max retries (3 attempts) |

## Idempotency

Each outbox entry has an `idempotency_key` (UUID). This prevents duplicate deliveries if the processor is interrupted and retried. The key is checked before processing — if an entry with the same key is already delivered, it is skipped.

## Retry Logic

- Maximum 3 attempts per outbox entry.
- Exponential backoff: `next_attempt_at = NOW() + (2^attempt_count * 60 seconds)`.
- After 3 failed attempts, the entry moves to `dead_letter` status.
- Dead-lettered entries are preserved for investigation — they are never deleted.

## Notification Channels

### In-App (Fully Implemented)
- Written to the `notifications` table.
- Includes `alarm_id` for linking to the alarm detail screen.
- Includes `navigation_target` for deep linking (e.g., `/alarms/{alarm_id}`).
- `read_at` timestamp tracks when the user viewed it.
- Delivered via Supabase Realtime subscription.

### Email (Stub)
- Outbox entries with `channel = 'email'` are created and logged.
- No actual email is sent — this requires provider integration (SendGrid, SES, etc.).
- Do not claim email support is production-ready.

### Push (Stub)
- Outbox entries with `channel = 'push'` are created and logged.
- No actual push notification is sent — this requires FCM/APNs integration.
- Do not claim push support is production-ready.

## Notification Preferences

Users configure preferences per category:

| Field | Type | Purpose |
|-------|------|---------|
| push_enabled | boolean | Receive push notifications for this category |
| email_enabled | boolean | Receive email for this category |
| in_app_enabled | boolean | Receive in-app for this category |
| quiet_hours_enabled | boolean | Enable quiet hours |
| quiet_hours_start | time | Start of quiet period |
| quiet_hours_end | time | End of quiet period |
| timezone | text | IANA timezone for quiet hours |
| min_severity | text | Minimum severity to receive |

Categories: device, automation, security, system, alert.

## Failure Isolation

Notification delivery failures do not block:
- Telemetry ingestion
- Rule evaluation
- Alarm lifecycle operations

The outbox pattern decouples delivery from alarm processing. If the notification system is down, alarms continue to function and outbox entries accumulate for later processing.

## Extensions to Existing Notification Entity

The `AppNotification` class in Flutter gained:
- `alarmId`: links the notification to a specific alarm
- `readAt`: tracks when the notification was read
- `navigationTarget`: enables deep linking to alarm detail
- `isAlarmLinked`: computed getter for UI display logic
