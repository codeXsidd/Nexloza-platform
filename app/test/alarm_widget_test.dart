import 'package:flutter_test/flutter_test.dart';

import 'package:nexloza/features/dashboards/domain/entities/widget_type.dart';

void main() {
  group('NexWidgetType — new alarm widget types exist', () {
    test('alarmCount exists', () {
      expect(NexWidgetType.alarmCount.typeId, 'alarm_count');
    });

    test('criticalAlarmCount exists', () {
      expect(NexWidgetType.criticalAlarmCount.typeId, 'critical_alarm_count');
    });

    test('unacknowledgedAlarmCount exists', () {
      expect(
        NexWidgetType.unacknowledgedAlarmCount.typeId,
        'unacknowledged_alarm_count',
      );
    });

    test('alarmSeverityDistribution exists', () {
      expect(
        NexWidgetType.alarmSeverityDistribution.typeId,
        'alarm_severity_distribution',
      );
    });

    test('recentAlarmActivity exists', () {
      expect(NexWidgetType.recentAlarmActivity.typeId, 'recent_alarm_activity');
    });
  });

  group('NexWidgetType — total count', () {
    test('total widget type count is 47 (42 + 5 new alarm)', () {
      expect(NexWidgetType.values.length, 47);
    });
  });

  group('NexWidgetType — alarm widgets are in status category', () {
    test('all 5 new alarm widgets are status category', () {
      expect(NexWidgetType.alarmCount.category, WidgetCategory.status);
      expect(NexWidgetType.criticalAlarmCount.category, WidgetCategory.status);
      expect(
        NexWidgetType.unacknowledgedAlarmCount.category,
        WidgetCategory.status,
      );
      expect(
        NexWidgetType.alarmSeverityDistribution.category,
        WidgetCategory.status,
      );
      expect(NexWidgetType.recentAlarmActivity.category, WidgetCategory.status);
    });
  });

  group('NexWidgetType — alarm widget sizes', () {
    test('alarmSeverityDistribution has defaultWidth of 2', () {
      expect(NexWidgetType.alarmSeverityDistribution.defaultWidth, 2);
    });

    test('recentAlarmActivity has defaultWidth of 2', () {
      expect(NexWidgetType.recentAlarmActivity.defaultWidth, 2);
    });

    test('recentAlarmActivity has defaultHeight of 2', () {
      expect(NexWidgetType.recentAlarmActivity.defaultHeight, 2);
    });

    test('alarmCount has default 1x1 size', () {
      expect(NexWidgetType.alarmCount.defaultWidth, 1);
      expect(NexWidgetType.alarmCount.defaultHeight, 1);
    });
  });

  group('NexWidgetType — fromTypeId for new alarm widgets', () {
    test('fromTypeId resolves all new alarm type IDs', () {
      expect(NexWidgetType.fromTypeId('alarm_count'), NexWidgetType.alarmCount);
      expect(
        NexWidgetType.fromTypeId('critical_alarm_count'),
        NexWidgetType.criticalAlarmCount,
      );
      expect(
        NexWidgetType.fromTypeId('unacknowledged_alarm_count'),
        NexWidgetType.unacknowledgedAlarmCount,
      );
      expect(
        NexWidgetType.fromTypeId('alarm_severity_distribution'),
        NexWidgetType.alarmSeverityDistribution,
      );
      expect(
        NexWidgetType.fromTypeId('recent_alarm_activity'),
        NexWidgetType.recentAlarmActivity,
      );
    });
  });

  group('NexWidgetType — existing alarm widgets unchanged', () {
    test('alarmIndicator still exists in status category', () {
      expect(NexWidgetType.alarmIndicator.category, WidgetCategory.status);
      expect(NexWidgetType.alarmIndicator.typeId, 'alarm_indicator');
    });

    test('alarmPanel still exists in industrial category', () {
      expect(NexWidgetType.alarmPanel.category, WidgetCategory.industrial);
      expect(NexWidgetType.alarmPanel.typeId, 'alarm_panel');
    });
  });
}
