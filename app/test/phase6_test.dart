import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/features/dashboards/domain/entities/dashboard_entity.dart';
import 'package:nexloza/features/dashboards/domain/entities/dashboard_widget_entity.dart';
import 'package:nexloza/features/dashboards/domain/entities/data_source.dart';
import 'package:nexloza/features/dashboards/domain/entities/widget_type.dart';
import 'package:nexloza/features/dashboards/domain/widget_registry.dart';
import 'package:nexloza/features/dashboards/presentation/widgets/renderers/widget_registrations.dart';

void main() {
  group('NexWidgetType', () {
    test('47 widget types are defined', () {
      expect(NexWidgetType.values.length, 47);
    });

    test('6 categories are defined', () {
      expect(WidgetCategory.values.length, 6);
    });

    test('8 control widgets', () {
      expect(NexWidgetType.byCategory(WidgetCategory.control).length, 8);
    });

    test('10 sensor widgets', () {
      expect(NexWidgetType.byCategory(WidgetCategory.sensor).length, 10);
    });

    test('8 chart widgets', () {
      expect(NexWidgetType.byCategory(WidgetCategory.chart).length, 8);
    });

    test('11 status widgets', () {
      expect(NexWidgetType.byCategory(WidgetCategory.status).length, 11);
    });

    test('5 industrial widgets', () {
      expect(NexWidgetType.byCategory(WidgetCategory.industrial).length, 5);
    });

    test('5 info widgets', () {
      expect(NexWidgetType.byCategory(WidgetCategory.info).length, 5);
    });

    test('every type has a unique typeId', () {
      final ids = NexWidgetType.values.map((t) => t.typeId).toSet();
      expect(ids.length, NexWidgetType.values.length);
    });

    test('every type has displayName and icon', () {
      for (final t in NexWidgetType.values) {
        expect(t.displayName, isNotEmpty);
        expect(t.icon, isNotNull);
      }
    });

    test('fromTypeId resolves known types', () {
      expect(NexWidgetType.fromTypeId('switch'), NexWidgetType.switchControl);
      expect(NexWidgetType.fromTypeId('gauge'), NexWidgetType.gauge);
      expect(NexWidgetType.fromTypeId('tank_level'), NexWidgetType.tankLevel);
      expect(
        NexWidgetType.fromTypeId('clock_widget'),
        NexWidgetType.clockWidget,
      );
    });

    test('fromTypeId falls back to textWidget for unknown', () {
      expect(NexWidgetType.fromTypeId('nonexistent'), NexWidgetType.textWidget);
    });

    test('defaultWidth is 2 for charts and industrial', () {
      expect(NexWidgetType.lineChart.defaultWidth, 2);
      expect(NexWidgetType.tankLevel.defaultWidth, 2);
    });

    test('defaultWidth is 1 for control and sensor', () {
      expect(NexWidgetType.switchControl.defaultWidth, 1);
      expect(NexWidgetType.temperatureCard.defaultWidth, 1);
    });

    test('isControl returns true only for control category', () {
      expect(NexWidgetType.switchControl.isControl, isTrue);
      expect(NexWidgetType.slider.isControl, isTrue);
      expect(NexWidgetType.gauge.isControl, isFalse);
      expect(NexWidgetType.textWidget.isControl, isFalse);
    });

    test('needsDataSource returns false for most info widgets', () {
      expect(NexWidgetType.textWidget.needsDataSource, isFalse);
      expect(NexWidgetType.clockWidget.needsDataSource, isFalse);
      expect(NexWidgetType.markdownWidget.needsDataSource, isFalse);
    });

    test('needsDataSource returns true for eventLog and deviceList', () {
      expect(NexWidgetType.eventLog.needsDataSource, isTrue);
      expect(NexWidgetType.deviceList.needsDataSource, isTrue);
    });

    test('all categories have display names', () {
      for (final cat in WidgetCategory.values) {
        expect(cat.displayName, isNotEmpty);
        expect(cat.icon, isNotNull);
      }
    });
  });

  group('DataSource', () {
    test('default DataSource is unbound', () {
      const ds = DataSource();
      expect(ds.isBound, isFalse);
      expect(ds.hasDevice, isFalse);
      expect(ds.hasSensor, isFalse);
      expect(ds.hasActuator, isFalse);
    });

    test('DataSource with sensor is bound', () {
      const ds = DataSource(
        projectId: 'p1',
        deviceId: 'd1',
        sensorKey: 'temp',
        telemetryKey: 'temp',
      );
      expect(ds.isBound, isTrue);
      expect(ds.hasDevice, isTrue);
      expect(ds.hasSensor, isTrue);
      expect(ds.effectiveKey, 'temp');
    });

    test('DataSource with actuator is bound', () {
      const ds = DataSource(
        projectId: 'p1',
        deviceId: 'd1',
        actuatorKey: 'relay1',
        telemetryKey: 'relay1',
      );
      expect(ds.isBound, isTrue);
      expect(ds.hasActuator, isTrue);
      expect(ds.effectiveKey, 'relay1');
    });

    test('toJson and fromJson round-trip', () {
      const original = DataSource(
        projectId: 'p1',
        deviceId: 'd1',
        sensorKey: 'temp',
        telemetryKey: 'temp',
      );
      final json = original.toJson();
      final restored = DataSource.fromJson(json);
      expect(restored.projectId, 'p1');
      expect(restored.deviceId, 'd1');
      expect(restored.sensorKey, 'temp');
      expect(restored.telemetryKey, 'temp');
    });

    test('copyWith updates fields', () {
      const ds = DataSource(projectId: 'p1');
      final updated = ds.copyWith(deviceId: 'd1');
      expect(updated.projectId, 'p1');
      expect(updated.deviceId, 'd1');
    });

    test('effectiveKey prefers telemetryKey', () {
      const ds = DataSource(
        deviceId: 'd1',
        sensorKey: 'sensor',
        actuatorKey: 'actuator',
        telemetryKey: 'telem',
      );
      expect(ds.effectiveKey, 'telem');
    });
  });

  group('WidgetDataState', () {
    test('numericValue from double', () {
      const state = WidgetDataState(currentValue: 42.5);
      expect(state.numericValue, 42.5);
    });

    test('numericValue from int', () {
      const state = WidgetDataState(currentValue: 10);
      expect(state.numericValue, 10.0);
    });

    test('numericValue from string', () {
      const state = WidgetDataState(currentValue: '25.5');
      expect(state.numericValue, 25.5);
    });

    test('numericValue from non-numeric returns 0', () {
      const state = WidgetDataState(currentValue: 'hello');
      expect(state.numericValue, 0);
    });

    test('boolValue from bool', () {
      const state = WidgetDataState(currentValue: true);
      expect(state.boolValue, isTrue);
    });

    test('boolValue from int 1', () {
      const state = WidgetDataState(currentValue: 1);
      expect(state.boolValue, isTrue);
    });

    test('boolValue from int 0', () {
      const state = WidgetDataState(currentValue: 0);
      expect(state.boolValue, isFalse);
    });

    test('boolValue from string "true"', () {
      const state = WidgetDataState(currentValue: 'true');
      expect(state.boolValue, isTrue);
    });

    test('boolValue from string "1"', () {
      const state = WidgetDataState(currentValue: '1');
      expect(state.boolValue, isTrue);
    });

    test('stringValue returns toString of value', () {
      const state = WidgetDataState(currentValue: 42);
      expect(state.stringValue, '42');
    });

    test('stringValue returns -- for null', () {
      const state = WidgetDataState();
      expect(state.stringValue, '--');
    });

    test('hasData is true when value exists', () {
      const state = WidgetDataState(currentValue: 'test');
      expect(state.hasData, isTrue);
    });

    test('hasData is false when null', () {
      const state = WidgetDataState();
      expect(state.hasData, isFalse);
    });

    test('hasError is true when error set', () {
      const state = WidgetDataState(error: 'Connection lost');
      expect(state.hasError, isTrue);
    });

    test('isLoading defaults to false', () {
      const state = WidgetDataState();
      expect(state.isLoading, isFalse);
    });

    test('isStale defaults to false', () {
      const state = WidgetDataState();
      expect(state.isStale, isFalse);
    });

    test('history defaults to empty', () {
      const state = WidgetDataState();
      expect(state.history, isEmpty);
    });
  });

  group('WidgetRegistry', () {
    test('singleton returns same instance', () {
      final a = WidgetRegistry();
      final b = WidgetRegistry();
      expect(identical(a, b), isTrue);
    });

    test('registerAllWidgets registers all 47 types', () {
      registerAllWidgets();
      final registry = WidgetRegistry();
      expect(registry.registeredTypes.length, 47);
    });

    test('isRegistered returns true for registered types', () {
      registerAllWidgets();
      final registry = WidgetRegistry();
      expect(registry.isRegistered(NexWidgetType.switchControl), isTrue);
      expect(registry.isRegistered(NexWidgetType.gauge), isTrue);
      expect(registry.isRegistered(NexWidgetType.tankLevel), isTrue);
      expect(registry.isRegistered(NexWidgetType.clockWidget), isTrue);
    });

    test('registeredByCategory returns correct counts', () {
      registerAllWidgets();
      final registry = WidgetRegistry();
      expect(registry.registeredByCategory(WidgetCategory.control).length, 8);
      expect(registry.registeredByCategory(WidgetCategory.sensor).length, 10);
      expect(registry.registeredByCategory(WidgetCategory.chart).length, 8);
      expect(registry.registeredByCategory(WidgetCategory.status).length, 11);
      expect(
        registry.registeredByCategory(WidgetCategory.industrial).length,
        5,
      );
      expect(registry.registeredByCategory(WidgetCategory.info).length, 5);
    });

    testWidgets('build returns widget for registered type', (
      WidgetTester tester,
    ) async {
      registerAllWidgets();
      final registry = WidgetRegistry();
      const dashWidget = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.temperatureCard,
        title: 'Temperature',
      );
      const data = WidgetDataState(currentValue: 25.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => SizedBox(
                width: 200,
                height: 200,
                child: registry.build(context, dashWidget, data),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('DashboardWidget entity', () {
    test('dataSource from config', () {
      final w = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.temperatureCard,
        title: 'Temp',
        config: const {
          'data_source': {
            'project_id': 'p1',
            'device_id': 'd1',
            'sensor_key': 'temp',
            'telemetry_key': 'temp',
          },
        },
      );
      expect(w.dataSource.isBound, isTrue);
      expect(w.dataSource.sensorKey, 'temp');
    });

    test('dataSource returns empty when no config', () {
      const w = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.textWidget,
        title: 'Text',
      );
      expect(w.dataSource.isBound, isFalse);
    });

    test('displayConfig getter', () {
      final w = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.gauge,
        title: 'Gauge',
        config: const {
          'display': {'unit': '°C', 'decimals': 2},
        },
      );
      expect(w.unit, '°C');
      expect(w.decimals, 2);
    });

    test('rangeConfig defaults', () {
      const w = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.slider,
        title: 'Slider',
      );
      expect(w.rangeMin, 0);
      expect(w.rangeMax, 100);
    });

    test('thresholds parsing', () {
      final w = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.temperatureCard,
        title: 'Temp',
        config: const {
          'thresholds': [
            {'value': 30, 'color': '#FF0000'},
            {'value': 20, 'color': '#00FF00'},
          ],
        },
      );
      expect(w.thresholds.length, 2);
    });

    test('isVisible defaults to true', () {
      const w = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.textWidget,
        title: 'Text',
      );
      expect(w.isVisible, isTrue);
    });
  });

  group('Dashboard entity', () {
    test('10 templates defined', () {
      expect(Dashboard.templates.length, 10);
    });

    test('templates have names and descriptions', () {
      for (final t in Dashboard.templates) {
        expect(t.name, isNotEmpty);
        expect(t.description, isNotEmpty);
        expect(t.icon, isNotEmpty);
        expect(t.category, isNotEmpty);
      }
    });

    test('columns getter defaults to 2', () {
      final d = Dashboard(
        id: 'd1',
        projectId: 'p1',
        name: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(d.columns, 2);
    });

    test('copyWith preserves fields', () {
      final now = DateTime.now();
      final d = Dashboard(
        id: 'd1',
        projectId: 'p1',
        name: 'Original',
        description: 'Desc',
        createdAt: now,
        updatedAt: now,
      );
      final copy = d.copyWith(name: 'Modified');
      expect(copy.name, 'Modified');
      expect(copy.projectId, 'p1');
      expect(copy.description, 'Desc');
    });

    test('isArchived defaults to false', () {
      final d = Dashboard(
        id: 'd1',
        projectId: 'p1',
        name: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(d.isArchived, isFalse);
    });

    test('fromJson parses isArchived', () {
      final now = DateTime.now().toIso8601String();
      final d = Dashboard.fromJson({
        'id': 'd1',
        'project_id': 'p1',
        'name': 'Test',
        'is_archived': true,
        'created_at': now,
        'updated_at': now,
      });
      expect(d.isArchived, isTrue);
    });

    test('toJson includes required fields', () {
      final d = Dashboard(
        id: 'd1',
        projectId: 'p1',
        name: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final json = d.toJson();
      expect(json['project_id'], 'p1');
      expect(json['name'], 'Test');
      expect(json.containsKey('layout'), isTrue);
    });

    test('variables defaults to empty map', () {
      final d = Dashboard(
        id: 'd1',
        projectId: 'p1',
        name: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(d.variables, isEmpty);
    });
  });

  group('Widget Renderers', () {
    setUp(() {
      registerAllWidgets();
    });

    testWidgets('switch control renders', (WidgetTester tester) async {
      await _renderWidget(
        tester,
        NexWidgetType.switchControl,
        'Switch',
        const WidgetDataState(currentValue: true),
      );
      expect(find.text('ON'), findsOneWidget);
    });

    testWidgets('button renders', (WidgetTester tester) async {
      await _renderWidget(
        tester,
        NexWidgetType.button,
        'Action',
        const WidgetDataState(),
      );
      expect(find.text('Execute'), findsOneWidget);
    });

    testWidgets('temperature card renders value', (WidgetTester tester) async {
      await _renderWidget(
        tester,
        NexWidgetType.temperatureCard,
        'Temperature',
        const WidgetDataState(currentValue: 25.0),
        config: const {
          'display': {'unit': '°C', 'decimals': 1},
        },
      );
      expect(find.text('25.0°C'), findsOneWidget);
    });

    testWidgets('motion card shows detected state', (
      WidgetTester tester,
    ) async {
      await _renderWidget(
        tester,
        NexWidgetType.motionCard,
        'Motion',
        const WidgetDataState(currentValue: true),
      );
      expect(find.text('Motion Detected'), findsOneWidget);
    });

    testWidgets('device status shows online', (WidgetTester tester) async {
      await _renderWidget(
        tester,
        NexWidgetType.deviceStatus,
        'Device',
        const WidgetDataState(currentValue: true),
      );
      expect(find.text('Online'), findsOneWidget);
    });

    testWidgets('alarm indicator shows active', (WidgetTester tester) async {
      await _renderWidget(
        tester,
        NexWidgetType.alarmIndicator,
        'Fire Alarm',
        const WidgetDataState(currentValue: true),
      );
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets('text widget renders config text', (WidgetTester tester) async {
      await _renderWidget(
        tester,
        NexWidgetType.textWidget,
        'Info',
        const WidgetDataState(),
        config: const {'text': 'Hello World'},
      );
      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('clock widget renders time', (WidgetTester tester) async {
      await _renderWidget(
        tester,
        NexWidgetType.clockWidget,
        'Clock',
        const WidgetDataState(),
      );
      // Clock renders current time, at minimum should show a colon
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('loading state shows progress indicator', (
      WidgetTester tester,
    ) async {
      await _renderWidget(
        tester,
        NexWidgetType.temperatureCard,
        'Loading',
        const WidgetDataState(isLoading: true),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('gauge renders value text', (WidgetTester tester) async {
      await _renderWidget(
        tester,
        NexWidgetType.gauge,
        'Speed',
        const WidgetDataState(currentValue: 75.0),
        config: const {
          'display': {'unit': 'km/h', 'decimals': 0},
          'range': {'min': 0, 'max': 200},
        },
      );
      expect(find.text('75km/h'), findsOneWidget);
    });

    testWidgets('progress bar renders', (WidgetTester tester) async {
      await _renderWidget(
        tester,
        NexWidgetType.progressBar,
        'Fill Level',
        const WidgetDataState(currentValue: 60.0),
        config: const {
          'display': {'unit': '%', 'decimals': 0},
          'range': {'min': 0, 'max': 100},
        },
      );
      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('machine status renders', (WidgetTester tester) async {
      await _renderWidget(
        tester,
        NexWidgetType.machineStatus,
        'CNC Mill',
        const WidgetDataState(currentValue: 'Running'),
      );
      expect(find.text('Running'), findsOneWidget);
    });
  });
}

Future<void> _renderWidget(
  WidgetTester tester,
  NexWidgetType type,
  String title,
  WidgetDataState data, {
  Map<String, dynamic> config = const {},
}) async {
  final registry = WidgetRegistry();
  final dashWidget = DashboardWidget(
    id: 'test-w',
    dashboardId: 'test-d',
    widgetType: type,
    title: title,
    config: config,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => SizedBox(
            width: 300,
            height: 200,
            child: registry.build(context, dashWidget, data),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
