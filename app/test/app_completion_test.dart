import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/features/dashboards/domain/entities/dashboard_entity.dart';
import 'package:nexloza/features/dashboards/domain/entities/dashboard_widget_entity.dart';
import 'package:nexloza/features/automations/domain/entities/automation_entity.dart';
import 'package:nexloza/features/automations/domain/entities/trigger_entity.dart';
import 'package:nexloza/features/automations/domain/entities/action_entity.dart';
import 'package:nexloza/features/ai_assistant/data/ai_repository.dart';
import 'package:nexloza/features/ai_assistant/presentation/providers/ai_provider.dart';
import 'package:nexloza/features/notifications/domain/entities/notification_entity.dart';
import 'package:nexloza/features/scenes/domain/entities/scene_entity.dart';
import 'package:nexloza/features/device_studio/domain/board_definitions.dart';
import 'package:nexloza/features/device_studio/domain/code_generator.dart';
import 'package:nexloza/routing/route_names.dart';

void main() {
  group('Dashboard Entity', () {
    test('fromJson creates valid Dashboard', () {
      final json = <String, dynamic>{
        'id': 'd1',
        'project_id': 'p1',
        'name': 'My Dashboard',
        'description': 'Test description',
        'is_default': true,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };

      final dashboard = Dashboard.fromJson(json);
      expect(dashboard.id, 'd1');
      expect(dashboard.projectId, 'p1');
      expect(dashboard.name, 'My Dashboard');
      expect(dashboard.description, 'Test description');
      expect(dashboard.isDefault, true);
    });

    test('fromJson handles missing optional fields', () {
      final json = <String, dynamic>{
        'id': 'd2',
        'project_id': 'p1',
        'name': 'Minimal',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final dashboard = Dashboard.fromJson(json);
      expect(dashboard.description, isNull);
      expect(dashboard.isDefault, false);
    });

    test('toJson produces correct map', () {
      final dashboard = Dashboard(
        id: 'd1',
        projectId: 'p1',
        name: 'Test',
        description: 'Desc',
        isDefault: true,
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );

      final json = dashboard.toJson();
      expect(json['project_id'], 'p1');
      expect(json['name'], 'Test');
      expect(json['description'], 'Desc');
      expect(json['is_default'], true);
    });
  });

  group('DashboardWidget Entity', () {
    test('fromJson creates valid widget', () {
      final json = <String, dynamic>{
        'id': 'w1',
        'dashboard_id': 'd1',
        'widget_type': 'gauge',
        'title': 'Temperature',
        'grid_x': 0,
        'grid_y': 0,
        'grid_w': 2,
        'grid_h': 2,
        'config': <String, dynamic>{
          'value': 42.5,
          'unit': '°C',
          'min': 0,
          'max': 100,
        },
        'sort_order': 0,
      };

      final widget = DashboardWidget.fromJson(json);
      expect(widget.id, 'w1');
      expect(widget.dashboardId, 'd1');
      expect(widget.widgetType, DashboardWidgetType.gauge);
      expect(widget.title, 'Temperature');
      expect(widget.config['value'], 42.5);
      expect(widget.config['unit'], '°C');
    });

    test('fromJson defaults to valueDisplay for unknown type', () {
      final json = <String, dynamic>{
        'id': 'w2',
        'dashboard_id': 'd1',
        'widget_type': 'unknown_widget',
        'title': 'Test',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final widget = DashboardWidget.fromJson(json);
      expect(widget.widgetType, DashboardWidgetType.valueDisplay);
    });

    test('all widget types have display names', () {
      for (final type in DashboardWidgetType.values) {
        expect(type.displayName, isNotEmpty);
      }
    });

    test('toJson produces correct map', () {
      final widget = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: DashboardWidgetType.toggle,
        title: 'Relay',
        gridX: 2,
        gridY: 0,
        gridW: 1,
        gridH: 1,
        config: const <String, dynamic>{'value': true},
      );

      final json = widget.toJson();
      expect(json['dashboard_id'], 'd1');
      expect(json['widget_type'], 'toggle');
      expect(json['title'], 'Relay');
      expect(json['grid_x'], 2);
      expect(json['grid_w'], 1);
    });

    test('copyWith creates modified copy', () {
      final original = DashboardWidget(
        id: 'w1',
        dashboardId: 'd1',
        widgetType: DashboardWidgetType.valueDisplay,
        title: 'Original',
      );

      final copy = original.copyWith(title: 'Modified', gridX: 5);
      expect(copy.title, 'Modified');
      expect(copy.gridX, 5);
      expect(copy.id, 'w1');
      expect(copy.widgetType, DashboardWidgetType.valueDisplay);
    });

    test('fromJson handles missing grid values', () {
      final json = <String, dynamic>{
        'id': 'w3',
        'dashboard_id': 'd1',
        'widget_type': 'lineChart',
        'title': 'Chart',
      };

      final widget = DashboardWidget.fromJson(json);
      expect(widget.gridX, 0);
      expect(widget.gridY, 0);
      expect(widget.gridW, 2);
      expect(widget.gridH, 2);
      expect(widget.sortOrder, 0);
      expect(widget.config, isEmpty);
    });
  });

  group('TriggerType', () {
    test('all trigger types have display names', () {
      for (final t in TriggerType.values) {
        expect(t.displayName, isNotEmpty);
      }
    });

    test('fromJson creates valid trigger', () {
      final json = <String, dynamic>{
        'id': 't1',
        'automation_id': 'a1',
        'trigger_type': 'sensorThreshold',
        'config': <String, dynamic>{'threshold': 25.0},
      };

      final trigger = AutomationTrigger.fromJson(json);
      expect(trigger.triggerType, TriggerType.sensorThreshold);
      expect(trigger.config['threshold'], 25.0);
    });

    test('unknown trigger type defaults to manual', () {
      final json = <String, dynamic>{
        'id': 't2',
        'automation_id': 'a1',
        'trigger_type': 'nonexistent',
        'config': <String, dynamic>{},
      };

      final trigger = AutomationTrigger.fromJson(json);
      expect(trigger.triggerType, TriggerType.manual);
    });
  });

  group('ActionType', () {
    test('all action types have display names', () {
      for (final a in ActionType.values) {
        expect(a.displayName, isNotEmpty);
      }
    });

    test('fromJson creates valid action', () {
      final json = <String, dynamic>{
        'id': 'act1',
        'automation_id': 'a1',
        'action_type': 'notification',
        'config': <String, dynamic>{'message': 'Alert!'},
        'sort_order': 1,
        'delay_seconds': 5,
      };

      final action = AutomationAction.fromJson(json);
      expect(action.actionType, ActionType.notification);
      expect(action.sortOrder, 1);
      expect(action.delaySeconds, 5);
    });

    test('unknown action type defaults to notification', () {
      final json = <String, dynamic>{
        'id': 'act2',
        'automation_id': 'a1',
        'action_type': 'nonexistent',
        'config': <String, dynamic>{},
      };

      final action = AutomationAction.fromJson(json);
      expect(action.actionType, ActionType.notification);
    });
  });

  group('AiChatState', () {
    test('default state has empty messages', () {
      const state = AiChatState();
      expect(state.messages, isEmpty);
      expect(state.conversationId, isNull);
      expect(state.provider, AiProvider.claude);
      expect(state.isSending, false);
      expect(state.error, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const state = AiChatState(provider: AiProvider.grok);
      final updated = state.copyWith(isSending: true);
      expect(updated.provider, AiProvider.grok);
      expect(updated.isSending, true);
    });

    test('ChatMessage stores text and role', () {
      final msg = ChatMessage(text: 'Hello', isUser: true);
      expect(msg.text, 'Hello');
      expect(msg.isUser, true);
      expect(msg.timestamp, isNotNull);
    });
  });

  group('AiProvider enum', () {
    test('all providers have display names', () {
      for (final p in AiProvider.values) {
        expect(p.displayName, isNotEmpty);
      }
    });

    test('all providers have keys', () {
      expect(AiProvider.claude.key, 'claude');
      expect(AiProvider.grok.key, 'grok');
    });
  });

  group('AiConversation', () {
    test('fromJson creates valid conversation', () {
      final json = <String, dynamic>{
        'id': 'conv1',
        'title': 'Test Chat',
        'project_id': 'p1',
        'model_id': 'claude',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final conv = AiConversation.fromJson(json);
      expect(conv.id, 'conv1');
      expect(conv.title, 'Test Chat');
      expect(conv.projectId, 'p1');
      expect(conv.modelId, 'claude');
    });

    test('fromJson handles null optional fields', () {
      final json = <String, dynamic>{
        'id': 'conv2',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final conv = AiConversation.fromJson(json);
      expect(conv.title, isNull);
      expect(conv.projectId, isNull);
      expect(conv.modelId, isNull);
    });
  });

  group('AiMessage', () {
    test('fromJson creates valid message', () {
      final json = <String, dynamic>{
        'id': 'm1',
        'role': 'user',
        'content': 'Hello AI',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final msg = AiMessage.fromJson(json);
      expect(msg.role, 'user');
      expect(msg.content, 'Hello AI');
    });
  });

  group('Automation Entity', () {
    test('fromJson creates valid automation', () {
      final json = <String, dynamic>{
        'id': 'a1',
        'project_id': 'p1',
        'name': 'Temperature Alert',
        'description': 'Alerts when temp > 30',
        'is_enabled': true,
        'priority': 5,
        'cooldown_seconds': 120,
        'max_executions_per_hour': 30,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };

      final automation = Automation.fromJson(json);
      expect(automation.name, 'Temperature Alert');
      expect(automation.isEnabled, true);
      expect(automation.priority, 5);
      expect(automation.cooldownSeconds, 120);
      expect(automation.maxExecutionsPerHour, 30);
    });

    test('fromJson handles defaults', () {
      final json = <String, dynamic>{
        'id': 'a2',
        'project_id': 'p1',
        'name': 'Minimal',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final automation = Automation.fromJson(json);
      expect(automation.isEnabled, true);
      expect(automation.priority, 0);
      expect(automation.cooldownSeconds, 60);
      expect(automation.maxExecutionsPerHour, 60);
    });
  });

  group('Board Definitions', () {
    test('all boards are defined', () {
      expect(Boards.all.length, 4);
      expect(
        Boards.all.map((b) => b.id),
        containsAll(['esp32', 'esp32c3', 'esp32s3', 'esp8266']),
      );
    });

    test('each board has GPIO pins', () {
      for (final board in Boards.all) {
        expect(board.gpioPins, isNotEmpty);
        expect(board.name, isNotEmpty);
        expect(board.platformioBoard, isNotEmpty);
      }
    });

    test('ESP32 has expected features', () {
      expect(Boards.esp32.features, contains('Wi-Fi'));
      expect(Boards.esp32.features, contains('Bluetooth'));
      expect(Boards.esp32.gpioPins.length, greaterThan(15));
    });

    test('ESP8266 has fewer pins than ESP32', () {
      expect(
        Boards.esp8266.gpioPins.length,
        lessThan(Boards.esp32.gpioPins.length),
      );
    });
  });

  group('Sensor Definitions', () {
    test('all sensors are defined', () {
      expect(Sensors.all.length, 5);
    });

    test('each sensor has required fields', () {
      for (final sensor in Sensors.all) {
        expect(sensor.id, isNotEmpty);
        expect(sensor.name, isNotEmpty);
        expect(sensor.type, isNotEmpty);
        expect(sensor.library, isNotEmpty);
        expect(sensor.readings, isNotEmpty);
        expect(sensor.exampleWiring, isNotEmpty);
        expect(sensor.initCode, isNotEmpty);
        expect(sensor.readCode, isNotEmpty);
      }
    });

    test('DHT22 reads temperature and humidity', () {
      expect(Sensors.dht22.readings, containsAll(['temperature', 'humidity']));
    });

    test('BME280 reads three values', () {
      expect(
        Sensors.bme280.readings,
        containsAll(['temperature', 'humidity', 'pressure']),
      );
    });
  });

  group('Actuator Definitions', () {
    test('all actuators are defined', () {
      expect(Actuators.all.length, 4);
    });

    test('each actuator has required fields', () {
      for (final actuator in Actuators.all) {
        expect(actuator.id, isNotEmpty);
        expect(actuator.name, isNotEmpty);
        expect(actuator.type, isNotEmpty);
        expect(actuator.exampleWiring, isNotEmpty);
        expect(actuator.controlCode, isNotEmpty);
      }
    });
  });

  group('Code Generator', () {
    test('generates firmware code for ESP32 with DHT22', () {
      final config = FirmwareConfig(
        board: Boards.esp32,
        sensors: [Sensors.dht22],
        actuators: [Actuators.relay],
        pinAssignments: <String, int>{'dht22': 4, 'relay': 2},
      );

      final code = CodeGenerator.generate(config);
      expect(code, contains('Generated by Nexloza Device Studio'));
      expect(code, contains('Board: ESP32 DevKit V1'));
      expect(code, contains('#include <WiFi.h>'));
      expect(code, contains('#include <PubSubClient.h>'));
      expect(code, contains('#include <DHT.h>'));
      expect(code, contains('DHT22_PIN'));
      expect(code, contains('RELAY_PIN'));
      expect(code, contains('void setup()'));
      expect(code, contains('void loop()'));
      expect(code, contains('mqtt.loop()'));
      expect(code, contains('connectWiFi'));
      expect(code, contains('connectMQTT'));
    });

    test('generates code for ESP8266', () {
      final config = FirmwareConfig(
        board: Boards.esp8266,
        sensors: [Sensors.pir],
        actuators: [Actuators.led],
      );

      final code = CodeGenerator.generate(config);
      expect(code, contains('#include <ESP8266WiFi.h>'));
      expect(code, contains('Board: ESP8266 NodeMCU'));
    });

    test('generates code with BME280', () {
      final config = FirmwareConfig(
        board: Boards.esp32,
        sensors: [Sensors.bme280],
      );

      final code = CodeGenerator.generate(config);
      expect(code, contains('#include <Wire.h>'));
      expect(code, contains('#include <Adafruit_BME280.h>'));
      expect(code, contains('bme.readTemperature()'));
      expect(code, contains('bme.readHumidity()'));
      expect(code, contains('bme.readPressure()'));
    });

    test('generates code with ultrasonic sensor', () {
      final config = FirmwareConfig(
        board: Boards.esp32,
        sensors: [Sensors.ultrasonic],
      );

      final code = CodeGenerator.generate(config);
      expect(code, contains('#include <NewPing.h>'));
      expect(code, contains('sonar.ping_cm()'));
    });

    test('generates code with multiple actuators', () {
      final config = FirmwareConfig(
        board: Boards.esp32,
        actuators: [Actuators.relay, Actuators.servo, Actuators.buzzer],
      );

      final code = CodeGenerator.generate(config);
      expect(code, contains('RELAY_PIN'));
      expect(code, contains('SERVO_PIN'));
      expect(code, contains('BUZZER_PIN'));
    });

    test('includes MQTT topic definitions', () {
      final config = FirmwareConfig(board: Boards.esp32);
      final code = CodeGenerator.generate(config);
      expect(code, contains('telemetryTopic'));
      expect(code, contains('commandTopic'));
      expect(code, contains('statusTopic'));
    });
  });

  group('Route Names', () {
    test('dashboard routes exist', () {
      expect(RouteNames.dashboards, 'dashboards');
      expect(RouteNames.createDashboard, 'createDashboard');
      expect(RouteNames.dashboardEditor, 'dashboardEditor');
    });

    test('device studio route exists', () {
      expect(RouteNames.deviceStudio, 'deviceStudio');
    });

    test('api keys route exists', () {
      expect(RouteNames.apiKeys, 'apiKeys');
    });

    test('all core routes are defined', () {
      expect(RouteNames.home, isNotEmpty);
      expect(RouteNames.projects, isNotEmpty);
      expect(RouteNames.devices, isNotEmpty);
      expect(RouteNames.automations, isNotEmpty);
      expect(RouteNames.aiAssistant, isNotEmpty);
      expect(RouteNames.notifications, isNotEmpty);
      expect(RouteNames.settings, isNotEmpty);
      expect(RouteNames.profile, isNotEmpty);
      expect(RouteNames.organizations, isNotEmpty);
      expect(RouteNames.invitations, isNotEmpty);
    });
  });

  group('Notification Entity', () {
    test('all categories are defined', () {
      expect(NotificationCategory.values.length, 5);
    });

    test('all severities are defined', () {
      expect(NotificationSeverity.values.length, 3);
    });

    test('fromJson handles unknown category', () {
      final json = <String, dynamic>{
        'id': 'n1',
        'user_id': 'u1',
        'title': 'Test',
        'body': 'Body',
        'category': 'nonexistent',
        'severity': 'info',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final n = AppNotification.fromJson(json);
      expect(n.category, NotificationCategory.system);
    });

    test('fromJson handles unknown severity', () {
      final json = <String, dynamic>{
        'id': 'n2',
        'user_id': 'u1',
        'title': 'Test',
        'body': 'Body',
        'severity': 'nonexistent',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final n = AppNotification.fromJson(json);
      expect(n.severity, NotificationSeverity.info);
    });
  });

  group('Scene Entity', () {
    test('fromJson creates valid scene', () {
      final json = <String, dynamic>{
        'id': 's1',
        'project_id': 'p1',
        'name': 'Night Mode',
        'description': 'Dims all lights',
        'icon': 'moon',
        'is_active': true,
        'created_at': '2024-01-01T00:00:00Z',
      };

      final scene = Scene.fromJson(json);
      expect(scene.name, 'Night Mode');
      expect(scene.isActive, true);
    });

    test('presets list is non-empty', () {
      expect(Scene.presets, isNotEmpty);
      expect(Scene.presets, contains('Night Mode'));
      expect(Scene.presets, contains('Away Mode'));
    });
  });

  group('DashboardWidgetType', () {
    test('all types have valid display names', () {
      for (final type in DashboardWidgetType.values) {
        expect(type.displayName, isNotEmpty);
        expect(type.icon, isNotEmpty);
      }
    });

    test('gauge type properties', () {
      expect(DashboardWidgetType.gauge.displayName, 'Gauge');
    });

    test('toggle type properties', () {
      expect(DashboardWidgetType.toggle.displayName, 'Toggle Control');
    });

    test('chart types', () {
      expect(DashboardWidgetType.lineChart.displayName, 'Line Chart');
      expect(DashboardWidgetType.barChart.displayName, 'Bar Chart');
    });
  });
}
