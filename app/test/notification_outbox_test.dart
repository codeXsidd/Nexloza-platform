import 'package:flutter_test/flutter_test.dart';

import 'package:nexloza/features/notifications/domain/entities/notification_entity.dart';

void main() {
  Map<String, dynamic> makeNotificationJson({
    String? alarmId,
    String? navigationTarget,
    String? readAt,
    bool isRead = false,
    String category = 'alert',
    String severity = 'warning',
  }) =>
      {
        'id': 'notif-1',
        'user_id': 'user-1',
        'project_id': 'proj-1',
        'title': 'Test Notification',
        'body': 'Something happened',
        'category': category,
        'severity': severity,
        'is_read': isRead,
        'read_at': readAt,
        'data': {'extra': 'info'},
        'alarm_id': alarmId,
        'navigation_target': navigationTarget,
        'created_at': '2026-11-10T10:00:00Z',
      };

  group('AppNotification — alarm linking', () {
    test('isAlarmLinked is true when alarmId is present', () {
      final notif = AppNotification.fromJson(
          makeNotificationJson(alarmId: 'alarm-1'));
      expect(notif.isAlarmLinked, true);
      expect(notif.alarmId, 'alarm-1');
    });

    test('isAlarmLinked is false when alarmId is null', () {
      final notif = AppNotification.fromJson(makeNotificationJson());
      expect(notif.isAlarmLinked, false);
      expect(notif.alarmId, isNull);
    });

    test('navigationTarget is preserved', () {
      final notif = AppNotification.fromJson(
          makeNotificationJson(navigationTarget: '/alarms/alarm-1'));
      expect(notif.navigationTarget, '/alarms/alarm-1');
    });
  });

  group('AppNotification — readAt field', () {
    test('readAt is null for unread notification', () {
      final notif = AppNotification.fromJson(makeNotificationJson());
      expect(notif.readAt, isNull);
      expect(notif.isRead, false);
    });

    test('readAt is parsed for read notification', () {
      final notif = AppNotification.fromJson(makeNotificationJson(
        isRead: true,
        readAt: '2026-11-10T10:05:00Z',
      ));
      expect(notif.readAt, isNotNull);
      expect(notif.isRead, true);
    });
  });

  group('AppNotification — category', () {
    test('alert category resolves correctly', () {
      final notif = AppNotification.fromJson(
          makeNotificationJson(category: 'alert'));
      expect(notif.category, NotificationCategory.alert);
    });

    test('device category resolves correctly', () {
      final notif = AppNotification.fromJson(
          makeNotificationJson(category: 'device'));
      expect(notif.category, NotificationCategory.device);
    });

    test('automation category resolves correctly', () {
      final notif = AppNotification.fromJson(
          makeNotificationJson(category: 'automation'));
      expect(notif.category, NotificationCategory.automation);
    });

    test('security category resolves correctly', () {
      final notif = AppNotification.fromJson(
          makeNotificationJson(category: 'security'));
      expect(notif.category, NotificationCategory.security);
    });

    test('unknown category defaults to system', () {
      final notif = AppNotification.fromJson(
          makeNotificationJson(category: 'unknown'));
      expect(notif.category, NotificationCategory.system);
    });
  });

  group('AppNotification — severity', () {
    test('warning severity resolves correctly', () {
      final notif = AppNotification.fromJson(
          makeNotificationJson(severity: 'warning'));
      expect(notif.severity, NotificationSeverity.warning);
    });

    test('critical severity resolves correctly', () {
      final notif = AppNotification.fromJson(
          makeNotificationJson(severity: 'critical'));
      expect(notif.severity, NotificationSeverity.critical);
    });

    test('info severity resolves correctly', () {
      final notif = AppNotification.fromJson(
          makeNotificationJson(severity: 'info'));
      expect(notif.severity, NotificationSeverity.info);
    });

    test('unknown severity defaults to info', () {
      final notif = AppNotification.fromJson(
          makeNotificationJson(severity: 'unknown'));
      expect(notif.severity, NotificationSeverity.info);
    });
  });

  group('AppNotification — data field', () {
    test('data map is preserved', () {
      final notif = AppNotification.fromJson(makeNotificationJson());
      expect(notif.data, isNotNull);
      expect(notif.data!['extra'], 'info');
    });

    test('null data field is handled', () {
      final json = makeNotificationJson();
      json['data'] = null;
      final notif = AppNotification.fromJson(json);
      expect(notif.data, isNull);
    });
  });

  group('AppNotification — fromJson with minimal fields', () {
    test('parses with only required fields', () {
      final json = {
        'id': 'n-1',
        'user_id': 'u-1',
        'title': 'Minimal',
        'body': 'Minimal body',
        'created_at': '2026-11-10T10:00:00Z',
      };
      final notif = AppNotification.fromJson(json);
      expect(notif.id, 'n-1');
      expect(notif.category, NotificationCategory.system);
      expect(notif.severity, NotificationSeverity.info);
      expect(notif.isRead, false);
      expect(notif.alarmId, isNull);
      expect(notif.navigationTarget, isNull);
      expect(notif.projectId, isNull);
    });
  });
}
