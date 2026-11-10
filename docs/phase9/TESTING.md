# Phase 9 — Testing Strategy

## Test Files

| File | Focus | Test Count |
|------|-------|-----------|
| alarm_entity_test.dart | Alarm entity, AlarmStats, severity, status, source enums | ~25 |
| alarm_configuration_test.dart | AlarmConfiguration entity, operators, hysteresis | ~15 |
| alarm_activity_test.dart | AlarmActivity entity, AlarmActivityType enum | ~10 |
| alarm_lifecycle_test.dart | Alarm lifecycle transitions, deduplication, escalation | ~15 |
| rule_engine_alarm_test.dart | 4 alarm action node types, config panel integration | ~20 |
| alarm_widget_test.dart | 5 dashboard alarm widget types, NexWidgetType enum | ~15 |
| alarm_security_test.dart | Authorization, RLS boundary, escalation target validation | ~15 |

## What Tests Cover

### Entity Tests
- Enum values: completeness, fromString, dbValue, color, icon, sortOrder
- fromJson / toJson round-trip fidelity
- Computed properties: isActive, isAcknowledged, isCleared, isCritical, isEscalated, duration
- AlarmStats.fromAlarms factory with mixed severity distributions
- generateAlarmKey format and uniqueness properties

### Configuration Tests
- All 8 operator types: gt, gte, lt, lte, eq, neq, between, outside
- operatorDisplayName getter
- Hysteresis value handling
- Debounce and cooldown defaults
- Enable/disable toggle behavior

### Activity Tests
- All 7 activity types: created, acknowledged, cleared, severity_changed, escalated, comment_added, configuration_changed
- fromJson parsing with nested details
- Timestamp handling

### Lifecycle Tests
- State transitions: active → acknowledged → cleared
- Invalid transitions (cleared → active should not happen)
- Alarm deduplication via alarm_key
- Occurrence count increment on re-raise
- Escalation stage progression
- Clear cancels pending escalation tasks

### Rule Engine Tests
- All 4 alarm node types registered in RuleNodeType enum
- Input/output port definitions
- Required config keys for each node type
- Node category assignment (all are "actions")
- Config panel field rendering for each node type

### Widget Tests
- All 5 new widget types registered in NexWidgetType enum
- Default width/height values
- Widget category assignment (all are "status")
- Renderer function existence in widget_registrations map

### Security Tests
- Users can only access alarms within their authorized projects
- Alarm modification requires can_modify_project
- Escalation targets validated against project membership
- Notification preferences scoped to authenticated user
- Service-role credentials not present in Flutter code
- MQTT credentials not exposed in alarm screens

## What Tests Do NOT Cover

- End-to-end integration with a live Supabase instance
- Actual email or push notification delivery
- Real MQTT broker communication
- Physical device firmware interaction
- Concurrent database access patterns
- Edge Function execution (tested via TypeScript, not Dart)

## Running Tests

```bash
cd app
flutter test
```

To run only Phase 9 tests:
```bash
flutter test test/alarm_entity_test.dart test/alarm_configuration_test.dart test/alarm_activity_test.dart test/alarm_lifecycle_test.dart test/rule_engine_alarm_test.dart test/alarm_widget_test.dart test/alarm_security_test.dart
```

## Test Principles

- No mocked tests reported as real-world integration tests
- No hidden failing tests or weakened assertions
- No skipped tests to obtain a green build
- No fabricated test results
- Tests verify actual entity behavior and enum completeness, not decorative assertions
