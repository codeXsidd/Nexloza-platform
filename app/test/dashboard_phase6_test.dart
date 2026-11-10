import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/features/dashboards/domain/entities/dashboard_entity.dart';
import 'package:nexloza/features/dashboards/domain/entities/dashboard_widget_entity.dart';
import 'package:nexloza/features/dashboards/domain/entities/data_source.dart';
import 'package:nexloza/features/dashboards/domain/entities/widget_type.dart';
import 'package:nexloza/features/dashboards/domain/widget_registry.dart';
import 'package:nexloza/features/dashboards/presentation/widgets/renderers/widget_registrations.dart';

void main() {
  // ── NexWidgetType ──────────────────────────────────────────────

  group('NexWidgetType', () {
    test('has exactly 47 values', () {
      expect(NexWidgetType.values.length, 47);
    });

    test('fromTypeId resolves known ids', () {
      expect(NexWidgetType.fromTypeId('switch'), NexWidgetType.switchControl);
      expect(NexWidgetType.fromTypeId('line_chart'), NexWidgetType.lineChart);
      expect(NexWidgetType.fromTypeId('gauge'), NexWidgetType.gauge);
      expect(NexWidgetType.fromTypeId('tank_level'), NexWidgetType.tankLevel);
      expect(
        NexWidgetType.fromTypeId('temperature_card'),
        NexWidgetType.temperatureCard,
      );
      expect(
        NexWidgetType.fromTypeId('device_status'),
        NexWidgetType.deviceStatus,
      );
      expect(NexWidgetType.fromTypeId('text_widget'), NexWidgetType.textWidget);
    });

    test('fromTypeId falls back to textWidget for unknown ids', () {
      expect(NexWidgetType.fromTypeId('nonexistent'), NexWidgetType.textWidget);
      expect(NexWidgetType.fromTypeId(''), NexWidgetType.textWidget);
      expect(NexWidgetType.fromTypeId('foobar'), NexWidgetType.textWidget);
    });

    test('byCategory returns correct counts', () {
      expect(NexWidgetType.byCategory(WidgetCategory.control).length, 8);
      expect(NexWidgetType.byCategory(WidgetCategory.sensor).length, 10);
      expect(NexWidgetType.byCategory(WidgetCategory.chart).length, 8);
      expect(NexWidgetType.byCategory(WidgetCategory.status).length, 11);
      expect(NexWidgetType.byCategory(WidgetCategory.industrial).length, 5);
      expect(NexWidgetType.byCategory(WidgetCategory.info).length, 5);
    });

    test('every value has a non-empty typeId and displayName', () {
      for (final t in NexWidgetType.values) {
        expect(t.typeId, isNotEmpty, reason: '${t.name} has empty typeId');
        expect(
          t.displayName,
          isNotEmpty,
          reason: '${t.name} has empty displayName',
        );
      }
    });

    test('every value has an icon', () {
      for (final t in NexWidgetType.values) {
        expect(t.icon, isNotNull, reason: '${t.name} has null icon');
      }
    });

    test('all typeIds are unique', () {
      final ids = NexWidgetType.values.map((t) => t.typeId).toSet();
      expect(ids.length, NexWidgetType.values.length);
    });

    test('isControl is true only for control category', () {
      for (final t in NexWidgetType.values) {
        if (t.category == WidgetCategory.control) {
          expect(t.isControl, isTrue, reason: '${t.name} should be control');
        } else {
          expect(
            t.isControl,
            isFalse,
            reason: '${t.name} should not be control',
          );
        }
      }
    });

    test('needsDataSource is false for info widgets except eventLog and deviceList', () {
      final infoTypes = NexWidgetType.byCategory(WidgetCategory.info);
      for (final t in infoTypes) {
        if (t == NexWidgetType.eventLog || t == NexWidgetType.deviceList) {
          expect(
            t.needsDataSource,
            isTrue,
            reason: '${t.name} should need data source',
          );
        } else {
          expect(
            t.needsDataSource,
            isFalse,
            reason: '${t.name} should not need data source',
          );
        }
      }
    });

    test('defaultWidth for chart types is 2, for control is 1', () {
      for (final t in NexWidgetType.byCategory(WidgetCategory.chart)) {
        expect(t.defaultWidth, 2, reason: '${t.name} chart defaultWidth');
      }
      for (final t in NexWidgetType.byCategory(WidgetCategory.control)) {
        expect(t.defaultWidth, 1, reason: '${t.name} control defaultWidth');
      }
    });

    test('defaultHeight for chart types is 2', () {
      for (final t in NexWidgetType.byCategory(WidgetCategory.chart)) {
        expect(t.defaultHeight, 2, reason: '${t.name} chart defaultHeight');
      }
    });
  });

  // ── WidgetCategory ─────────────────────────────────────────────

  group('WidgetCategory', () {
    test('has exactly 6 values', () {
      expect(WidgetCategory.values.length, 6);
    });

    test('contains expected categories', () {
      expect(
        WidgetCategory.values,
        containsAll([
          WidgetCategory.control,
          WidgetCategory.sensor,
          WidgetCategory.chart,
          WidgetCategory.status,
          WidgetCategory.industrial,
          WidgetCategory.info,
        ]),
      );
    });

    test('each has a non-empty displayName', () {
      for (final c in WidgetCategory.values) {
        expect(
          c.displayName,
          isNotEmpty,
          reason: '${c.name} has empty displayName',
        );
      }
    });

    test('each has an icon', () {
      for (final c in WidgetCategory.values) {
        expect(c.icon, isNotNull, reason: '${c.name} has null icon');
      }
    });
  });

  // ── DataSource ─────────────────────────────────────────────────

  group('DataSource', () {
    test('default constructor creates unbound source', () {
      const ds = DataSource();
      expect(ds.isBound, isFalse);
      expect(ds.hasDevice, isFalse);
      expect(ds.hasSensor, isFalse);
      expect(ds.hasActuator, isFalse);
    });

    test('isBound requires deviceId + sensorKey', () {
      const ds = DataSource(deviceId: 'dev1', sensorKey: 'temp');
      expect(ds.isBound, isTrue);
    });

    test('isBound requires deviceId + actuatorKey', () {
      const ds = DataSource(deviceId: 'dev1', actuatorKey: 'relay');
      expect(ds.isBound, isTrue);
    });

    test('isBound is false with only deviceId', () {
      const ds = DataSource(deviceId: 'dev1');
      expect(ds.isBound, isFalse);
    });

    test('isBound is false with only sensorKey', () {
      const ds = DataSource(sensorKey: 'temp');
      expect(ds.isBound, isFalse);
    });

    test('fromJson / toJson roundtrip', () {
      const original = DataSource(
        projectId: 'p1',
        deviceId: 'd1',
        sensorKey: 'temp',
        actuatorKey: 'relay',
        telemetryKey: 'temperature',
      );
      final json = original.toJson();
      final restored = DataSource.fromJson(json);
      expect(restored.projectId, 'p1');
      expect(restored.deviceId, 'd1');
      expect(restored.sensorKey, 'temp');
      expect(restored.actuatorKey, 'relay');
      expect(restored.telemetryKey, 'temperature');
    });

    test('toJson omits null fields', () {
      const ds = DataSource(deviceId: 'd1');
      final json = ds.toJson();
      expect(json.containsKey('device_id'), isTrue);
      expect(json.containsKey('project_id'), isFalse);
      expect(json.containsKey('sensor_key'), isFalse);
    });

    test('effectiveKey priority: telemetryKey > sensorKey > actuatorKey', () {
      expect(
        const DataSource(
          telemetryKey: 'tele',
          sensorKey: 'sens',
          actuatorKey: 'act',
        ).effectiveKey,
        'tele',
      );
      expect(
        const DataSource(sensorKey: 'sens', actuatorKey: 'act').effectiveKey,
        'sens',
      );
      expect(const DataSource(actuatorKey: 'act').effectiveKey, 'act');
      expect(const DataSource().effectiveKey, '');
    });

    test('copyWith preserves unmodified fields', () {
      const original = DataSource(
        projectId: 'p1',
        deviceId: 'd1',
        sensorKey: 'temp',
      );
      final modified = original.copyWith(sensorKey: 'humidity');
      expect(modified.projectId, 'p1');
      expect(modified.deviceId, 'd1');
      expect(modified.sensorKey, 'humidity');
    });

    test('hasDevice / hasSensor / hasActuator correctness', () {
      const ds = DataSource(
        deviceId: 'dev',
        sensorKey: 'temp',
        actuatorKey: 'relay',
      );
      expect(ds.hasDevice, isTrue);
      expect(ds.hasSensor, isTrue);
      expect(ds.hasActuator, isTrue);
    });

    test('empty string counts as no value', () {
      const ds = DataSource(deviceId: '', sensorKey: '');
      expect(ds.hasDevice, isFalse);
      expect(ds.hasSensor, isFalse);
      expect(ds.isBound, isFalse);
    });
  });

  // ── WidgetDataState ────────────────────────────────────────────

  group('WidgetDataState', () {
    test('numericValue converts num', () {
      const state = WidgetDataState(currentValue: 42.5);
      expect(state.numericValue, 42.5);
    });

    test('numericValue converts String', () {
      const state = WidgetDataState(currentValue: '123.4');
      expect(state.numericValue, 123.4);
    });

    test('numericValue defaults to 0 for null', () {
      const state = WidgetDataState();
      expect(state.numericValue, 0);
    });

    test('numericValue defaults to 0 for non-numeric string', () {
      const state = WidgetDataState(currentValue: 'hello');
      expect(state.numericValue, 0);
    });

    test('boolValue converts bool', () {
      const state = WidgetDataState(currentValue: true);
      expect(state.boolValue, isTrue);
    });

    test('boolValue converts num (0=false, 1=true)', () {
      const stateOn = WidgetDataState(currentValue: 1);
      const stateOff = WidgetDataState(currentValue: 0);
      expect(stateOn.boolValue, isTrue);
      expect(stateOff.boolValue, isFalse);
    });

    test('boolValue converts String', () {
      const stateTrue = WidgetDataState(currentValue: 'true');
      const stateOne = WidgetDataState(currentValue: '1');
      const stateFalse = WidgetDataState(currentValue: 'false');
      expect(stateTrue.boolValue, isTrue);
      expect(stateOne.boolValue, isTrue);
      expect(stateFalse.boolValue, isFalse);
    });

    test('stringValue defaults to -- when null', () {
      const state = WidgetDataState();
      expect(state.stringValue, '--');
    });

    test('stringValue converts value to string', () {
      const state = WidgetDataState(currentValue: 42);
      expect(state.stringValue, '42');
    });

    test('hasData is true when currentValue is not null', () {
      const withData = WidgetDataState(currentValue: 'x');
      const withoutData = WidgetDataState();
      expect(withData.hasData, isTrue);
      expect(withoutData.hasData, isFalse);
    });

    test('hasError is true when error is set', () {
      const withError = WidgetDataState(error: 'fail');
      const noError = WidgetDataState();
      expect(withError.hasError, isTrue);
      expect(noError.hasError, isFalse);
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

  // ── WidgetRegistry ─────────────────────────────────────────────

  group('WidgetRegistry', () {
    test('singleton returns same instance', () {
      final a = WidgetRegistry();
      final b = WidgetRegistry();
      expect(identical(a, b), isTrue);
    });

    test('register and isRegistered', () {
      final registry = WidgetRegistry();
      final reg = WidgetRegistration(
        type: NexWidgetType.clockWidget,
        builder: (ctx, w, d) => const SizedBox(),
      );
      registry.register(reg);
      expect(registry.isRegistered(NexWidgetType.clockWidget), isTrue);
    });

    test('registeredTypes includes registered types', () {
      final registry = WidgetRegistry();
      registry.register(
        WidgetRegistration(
          type: NexWidgetType.clockWidget,
          builder: (ctx, w, d) => const SizedBox(),
        ),
      );
      expect(registry.registeredTypes, contains(NexWidgetType.clockWidget));
    });

    testWidgets('build returns registered builder widget', (tester) async {
      final registry = WidgetRegistry();
      registry.register(
        WidgetRegistration(
          type: NexWidgetType.textWidget,
          builder: (ctx, w, d) => const Text('test-output'),
        ),
      );

      final dashWidget = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.textWidget,
        title: 'T',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) =>
                  registry.build(context, dashWidget, const WidgetDataState()),
            ),
          ),
        ),
      );

      expect(find.text('test-output'), findsOneWidget);
    });

    testWidgets('build returns fallback for unregistered type', (tester) async {
      final registry = WidgetRegistry();

      final widget = DashboardWidget(
        id: 'w2',
        dashboardId: 'd1',
        widgetType: NexWidgetType.markdownWidget,
        title: 'MD',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) =>
                  registry.build(context, widget, const WidgetDataState()),
            ),
          ),
        ),
      );

      expect(find.text('Markdown'), findsOneWidget);
    });

    test('registeredByCategory filters correctly', () {
      final registry = WidgetRegistry();
      registerAllWidgets();
      final controlTypes = registry.registeredByCategory(
        WidgetCategory.control,
      );
      for (final t in controlTypes) {
        expect(t.category, WidgetCategory.control);
      }
    });
  });

  // ── Dashboard Entity ───────────────────────────────────────────

  group('Dashboard Entity', () {
    test('fromJson parses all fields', () {
      final json = <String, dynamic>{
        'id': 'd1',
        'project_id': 'p1',
        'name': 'Test',
        'description': 'desc',
        'layout': {'columns': 3, 'row_height': 100},
        'is_default': true,
        'sort_order': 5,
        'is_archived': true,
        'variables': {'filter': 'all'},
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-06-01T00:00:00Z',
      };
      final d = Dashboard.fromJson(json);
      expect(d.id, 'd1');
      expect(d.projectId, 'p1');
      expect(d.name, 'Test');
      expect(d.isDefault, isTrue);
      expect(d.isArchived, isTrue);
      expect(d.variables['filter'], 'all');
      expect(d.columns, 3);
      expect(d.sortOrder, 5);
    });

    test('fromJson handles defaults', () {
      final json = <String, dynamic>{
        'id': 'd2',
        'project_id': 'p2',
        'name': 'Min',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };
      final d = Dashboard.fromJson(json);
      expect(d.isDefault, isFalse);
      expect(d.isArchived, isFalse);
      expect(d.variables, isEmpty);
      expect(d.columns, 2);
      expect(d.sortOrder, 0);
    });

    test('copyWith works for isArchived and variables', () {
      final d = Dashboard(
        id: 'd1',
        projectId: 'p1',
        name: 'Test',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final archived = d.copyWith(isArchived: true);
      expect(archived.isArchived, isTrue);
      expect(archived.name, 'Test');

      final withVars = d.copyWith(variables: {'x': 1});
      expect(withVars.variables['x'], 1);
    });

    test('columns getter reads from layout', () {
      final d = Dashboard(
        id: 'd1',
        projectId: 'p1',
        name: 'T',
        layout: const {'columns': 4, 'row_height': 80},
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      expect(d.columns, 4);
    });

    test('templates has 10 entries', () {
      expect(Dashboard.templates.length, 10);
    });

    test('each template has non-empty name, description, icon, category', () {
      for (final t in Dashboard.templates) {
        expect(t.name, isNotEmpty);
        expect(t.description, isNotEmpty);
        expect(t.icon, isNotEmpty);
        expect(t.category, isNotEmpty);
      }
    });

    test('toJson includes expected keys', () {
      final d = Dashboard(
        id: 'd1',
        projectId: 'p1',
        name: 'Test',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      final json = d.toJson();
      expect(json['project_id'], 'p1');
      expect(json['name'], 'Test');
      expect(json.containsKey('layout'), isTrue);
    });
  });

  // ── DashboardWidget Entity ─────────────────────────────────────

  group('DashboardWidget Entity', () {
    test('dataSource getter parses config', () {
      final widget = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.temperatureCard,
        title: 'Temp',
        config: const {
          'data_source': {'device_id': 'dev1', 'sensor_key': 'temperature'},
        },
      );
      expect(widget.dataSource.deviceId, 'dev1');
      expect(widget.dataSource.sensorKey, 'temperature');
      expect(widget.dataSource.isBound, isTrue);
    });

    test('dataSource returns empty DataSource when config missing', () {
      const widget = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.textWidget,
        title: 'T',
      );
      expect(widget.dataSource.isBound, isFalse);
    });

    test('rangeMin / rangeMax from config', () {
      final widget = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.gauge,
        title: 'G',
        config: const {
          'range': {'min': 10.0, 'max': 200.0},
        },
      );
      expect(widget.rangeMin, 10.0);
      expect(widget.rangeMax, 200.0);
    });

    test('rangeMin / rangeMax defaults when missing', () {
      const widget = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.gauge,
        title: 'G',
      );
      expect(widget.rangeMin, 0);
      expect(widget.rangeMax, 100);
    });

    test('unit and decimals from displayConfig', () {
      final widget = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.temperatureCard,
        title: 'T',
        config: const {
          'display': {'unit': '°C', 'decimals': 2},
        },
      );
      expect(widget.unit, '°C');
      expect(widget.decimals, 2);
    });

    test('unit defaults to empty, decimals to 1', () {
      const widget = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.temperatureCard,
        title: 'T',
      );
      expect(widget.unit, '');
      expect(widget.decimals, 1);
    });

    test('thresholds getter parses list', () {
      final widget = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.temperatureCard,
        title: 'T',
        config: const {
          'thresholds': [
            {'value': 30, 'color': '#FF0000'},
            {'value': 20, 'color': '#00FF00'},
          ],
        },
      );
      expect(widget.thresholds.length, 2);
      expect(widget.thresholds[0]['value'], 30);
    });

    test('thresholds returns empty list when missing', () {
      const widget = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.gauge,
        title: 'G',
      );
      expect(widget.thresholds, isEmpty);
    });

    test('toJson uses typeId string', () {
      const widget = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.lineChart,
        title: 'Chart',
      );
      final json = widget.toJson();
      expect(json['widget_type'], 'line_chart');
    });

    test('fromJson roundtrip preserves data', () {
      const original = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.gauge,
        title: 'Gauge',
        gridX: 2,
        gridY: 3,
        gridW: 2,
        gridH: 2,
        sortOrder: 5,
        isVisible: false,
      );
      final json = original.toJson();
      json['id'] = 'w1';
      final restored = DashboardWidget.fromJson(json);
      expect(restored.widgetType, NexWidgetType.gauge);
      expect(restored.title, 'Gauge');
      expect(restored.gridX, 2);
      expect(restored.gridY, 3);
      expect(restored.gridW, 2);
      expect(restored.gridH, 2);
      expect(restored.sortOrder, 5);
      expect(restored.isVisible, isFalse);
    });

    test('copyWith creates modified copy', () {
      const original = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.textWidget,
        title: 'Original',
      );
      final copy = original.copyWith(title: 'Modified', gridW: 3);
      expect(copy.title, 'Modified');
      expect(copy.gridW, 3);
      expect(copy.id, 'w1');
    });

    test('colorHex from displayConfig', () {
      final widget = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: NexWidgetType.gauge,
        title: 'G',
        config: const {
          'display': {'color': '#FF5733'},
        },
      );
      expect(widget.colorHex, '#FF5733');
    });
  });

  // ── Widget Registrations ───────────────────────────────────────

  group('Widget Registrations', () {
    test('registerAllWidgets registers all 42 types', () {
      registerAllWidgets();
      final registry = WidgetRegistry();
      for (final t in NexWidgetType.values) {
        expect(
          registry.isRegistered(t),
          isTrue,
          reason: '${t.name} (${t.typeId}) not registered',
        );
      }
    });

    test('registry count equals NexWidgetType.values.length', () {
      registerAllWidgets();
      final registry = WidgetRegistry();
      expect(registry.registeredTypes.length, NexWidgetType.values.length);
    });

    test('each category has registered types', () {
      registerAllWidgets();
      final registry = WidgetRegistry();
      for (final cat in WidgetCategory.values) {
        final types = registry.registeredByCategory(cat);
        expect(
          types,
          isNotEmpty,
          reason: '${cat.name} has no registered types',
        );
      }
    });
  });
}
