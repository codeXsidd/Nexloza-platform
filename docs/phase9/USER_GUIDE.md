# Phase 9 — User Guide

## Accessing Alarms

Navigate to **Alarms** from the home screen quick actions or the navigation menu.

### Alarms Overview

The overview screen shows:
- **Stats grid**: Total active, critical, high, medium, warning, acknowledged counts
- **Quick actions**: Navigate to active alarms, history, configurations, escalation policies, and notification preferences

### Active Alarms

View all currently active and acknowledged alarms sorted by severity.

- **Acknowledge**: Tap an alarm, then tap "Acknowledge" to indicate you've seen it. This does NOT clear the alarm — it remains active.
- **Bulk Acknowledge**: Select multiple alarms using checkboxes, then tap the bulk acknowledge button in the app bar.
- **View Detail**: Tap any alarm to see full details, activity timeline, and available actions.

### Alarm History

View all alarms including cleared ones. Use the status filter chips at the top to filter by active, acknowledged, or cleared.

### Alarm Detail

The detail screen shows:
- **Header**: Severity badge, status chip, title, and message
- **Info section**: Source, category, device, occurrence count, timestamps
- **Actions**: Acknowledge (if active), Clear (with required reason), Add Comment
- **Activity timeline**: Full audit trail of all lifecycle events

## Managing Alarm Configurations

Navigate to **Alarms > Configurations**.

### Creating a Configuration

1. Tap the floating action button (+)
2. Fill in:
   - **Name**: Human-readable name
   - **Sensor key**: Which sensor to monitor (e.g., "temperature")
   - **Operator**: Comparison type (>, >=, <, <=, =, !=, between, outside)
   - **Threshold**: Trigger value
   - **Hysteresis clear value** (optional): Value at which the alarm auto-clears
   - **Severity**: Alarm severity when triggered
   - **Category**: Grouping label
   - **Message template**: Notification message
3. Tap "Create"

### Toggling Configurations

Each configuration has an enable/disable toggle. Disabled configurations do not generate alarms.

### Deleting Configurations

Swipe a configuration card left to reveal the delete action.

## Escalation Policies

Navigate to **Alarms > Escalation Policies**.

### Creating a Policy

1. Tap the floating action button (+)
2. Enter a name and optional description
3. Toggle "Repeat after all stages" if desired
4. Tap "Create"

### Adding Stages

1. Open a policy detail screen
2. Tap "Add Stage"
3. Configure:
   - **Delay minutes**: How long to wait before this stage activates
   - **Notify users**: Select users from the organization
   - **Channel**: in_app, email, or push
4. Stages execute in order (stage 1 first, then stage 2, etc.)

## Notification Preferences

Navigate to **Notifications > Preferences** (or via Alarms overview).

### Category Toggles

For each category (Device, Automation, Security, System, Alert), toggle:
- **In-App**: Show in the notification panel
- **Email**: Send email (stub — not yet production-ready)
- **Push**: Send push notification (stub — not yet production-ready)

### Quiet Hours

Enable quiet hours to suppress non-critical notifications during specified times:
1. Toggle "Enable Quiet Hours"
2. Set start time (e.g., 10:00 PM)
3. Set end time (e.g., 7:00 AM)
4. Select your timezone

Critical alarm notifications always bypass quiet hours.

### Minimum Severity

Set the minimum severity threshold. Notifications below this severity are suppressed:
- **Info (all)**: Receive everything
- **Warning+**: Only warning and above
- **Critical only**: Only critical alarms

## Rule Engine Alarm Actions

In the visual rule engine (Phase 8), 4 new action nodes are available:

- **Raise Alarm**: Create or re-raise an alarm from a rule
- **Update Alarm Severity**: Change an existing alarm's severity
- **Clear Alarm**: Programmatically clear an alarm
- **Add Alarm Comment**: Add a note to an alarm's audit trail

These enable automated alarm management — for example, a rule that raises an alarm when temperature exceeds a threshold and clears it when temperature returns to normal.

## Dashboard Widgets

5 new widgets are available in the dashboard builder:

- **Alarm Count**: Total active alarms
- **Critical Alarm Count**: Critical alarms only
- **Unacknowledged Count**: Alarms needing attention
- **Severity Distribution**: Bar chart by severity
- **Recent Activity**: Latest alarm events
