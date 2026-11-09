import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/features/integrations/domain/entities/integration_entity.dart';
import 'package:nexloza/features/scenes/domain/entities/scene_entity.dart';
import 'package:nexloza/features/automations/domain/entities/automation_entity.dart';
import 'package:nexloza/features/projects/domain/entities/project_entity.dart';
import 'package:nexloza/routing/route_names.dart';

void main() {
  group('Integration Entity', () {
    test('fromJson creates valid Integration', () {
      final json = <String, dynamic>{
        'id': 'i1',
        'project_id': 'p1',
        'name': 'My Webhook',
        'integration_type': 'webhook',
        'config': <String, dynamic>{'url': 'https://example.com/hook'},
        'is_enabled': true,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };

      final integration = Integration.fromJson(json);
      expect(integration.id, 'i1');
      expect(integration.projectId, 'p1');
      expect(integration.name, 'My Webhook');
      expect(integration.integrationType, IntegrationType.webhook);
      expect(integration.config['url'], 'https://example.com/hook');
      expect(integration.isEnabled, true);
    });

    test('fromJson handles missing optional fields', () {
      final json = <String, dynamic>{
        'id': 'i2',
        'project_id': 'p1',
        'name': 'Minimal',
        'integration_type': 'mqtt',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final integration = Integration.fromJson(json);
      expect(integration.config, isEmpty);
      expect(integration.isEnabled, true);
      expect(integration.integrationType, IntegrationType.mqtt);
    });

    test('unknown integration type defaults to custom', () {
      final json = <String, dynamic>{
        'id': 'i3',
        'project_id': 'p1',
        'name': 'Unknown',
        'integration_type': 'nonexistent_type',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final integration = Integration.fromJson(json);
      expect(integration.integrationType, IntegrationType.custom);
    });

    test('all integration types have display names', () {
      for (final type in IntegrationType.values) {
        expect(type.displayName, isNotEmpty);
      }
    });

    test('all integration types have icon names', () {
      for (final type in IntegrationType.values) {
        expect(type.iconName, isNotEmpty);
      }
    });

    test('integration types include expected values', () {
      expect(IntegrationType.values.length, 7);
      expect(
        IntegrationType.values.map((t) => t.name),
        containsAll([
          'webhook',
          'mqtt',
          'httpApi',
          'slack',
          'email',
          'telegram',
          'custom',
        ]),
      );
    });

    test('each integration type has unique display name', () {
      final names = IntegrationType.values.map((t) => t.displayName).toSet();
      expect(names.length, IntegrationType.values.length);
    });
  });

  group('Scene Entity - extended', () {
    test('fromJson handles missing optional fields', () {
      final json = <String, dynamic>{
        'id': 's1',
        'project_id': 'p1',
        'name': 'Basic Scene',
        'created_at': '2024-01-01T00:00:00Z',
      };

      final scene = Scene.fromJson(json);
      expect(scene.description, isNull);
      expect(scene.icon, isNull);
      expect(scene.isActive, true);
    });

    test('fromJson parses inactive scene', () {
      final json = <String, dynamic>{
        'id': 's2',
        'project_id': 'p1',
        'name': 'Disabled',
        'is_active': false,
        'created_at': '2024-01-01T00:00:00Z',
      };

      final scene = Scene.fromJson(json);
      expect(scene.isActive, false);
    });

    test('presets contain standard IoT scenes', () {
      expect(Scene.presets, contains('Night Mode'));
      expect(Scene.presets, contains('Away Mode'));
      expect(Scene.presets, contains('Morning Mode'));
      expect(Scene.presets, contains('Security Mode'));
      expect(Scene.presets, contains('Energy Saving'));
      expect(Scene.presets, contains('Custom'));
      expect(Scene.presets.length, 6);
    });

    test('fromJson with all fields populated', () {
      final json = <String, dynamic>{
        'id': 's3',
        'project_id': 'p1',
        'name': 'Full Scene',
        'description': 'A complete scene',
        'icon': 'night',
        'is_active': true,
        'created_at': '2024-06-15T10:30:00Z',
      };

      final scene = Scene.fromJson(json);
      expect(scene.id, 's3');
      expect(scene.projectId, 'p1');
      expect(scene.name, 'Full Scene');
      expect(scene.description, 'A complete scene');
      expect(scene.icon, 'night');
      expect(scene.isActive, true);
      expect(scene.createdAt, DateTime.parse('2024-06-15T10:30:00Z'));
    });
  });

  group('Automation Detail', () {
    test('automation cooldown and execution limits', () {
      final json = <String, dynamic>{
        'id': 'a1',
        'project_id': 'p1',
        'name': 'Rate Limited',
        'cooldown_seconds': 300,
        'max_executions_per_hour': 10,
        'priority': 8,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final automation = Automation.fromJson(json);
      expect(automation.cooldownSeconds, 300);
      expect(automation.maxExecutionsPerHour, 10);
      expect(automation.priority, 8);
    });

    test('disabled automation', () {
      final json = <String, dynamic>{
        'id': 'a2',
        'project_id': 'p1',
        'name': 'Disabled',
        'is_enabled': false,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final automation = Automation.fromJson(json);
      expect(automation.isEnabled, false);
    });

    test('automation date parsing', () {
      final json = <String, dynamic>{
        'id': 'a3',
        'project_id': 'p1',
        'name': 'Dated',
        'created_at': '2024-06-15T10:30:00Z',
        'updated_at': '2024-06-20T14:00:00Z',
      };

      final automation = Automation.fromJson(json);
      expect(automation.createdAt.month, 6);
      expect(automation.createdAt.day, 15);
      expect(automation.updatedAt.day, 20);
    });
  });

  group('Project Entity - edit support', () {
    test('toJson produces editable fields', () {
      final project = Project(
        id: 'p1',
        name: 'Test Project',
        description: 'A project',
        category: 'smart_home',
        ownerId: 'u1',
        isActive: true,
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );

      final json = project.toJson();
      expect(json['name'], 'Test Project');
      expect(json['description'], 'A project');
      expect(json['category'], 'smart_home');
      expect(json['is_active'], true);
      expect(json.containsKey('id'), false);
    });

    test('categories include IoT types', () {
      expect(Project.categories, contains('Smart Home'));
      expect(Project.categories, contains('Smart Agriculture'));
      expect(Project.categories, contains('Industrial Monitoring'));
      expect(Project.categories, contains('Custom'));
      expect(Project.categories.length, greaterThanOrEqualTo(8));
    });

    test('fromJson handles all fields', () {
      final json = <String, dynamic>{
        'id': 'p1',
        'name': 'Full Project',
        'description': 'Desc',
        'category': 'smart_home',
        'icon': 'home',
        'organization_id': 'org1',
        'owner_id': 'u1',
        'settings': <String, dynamic>{'theme': 'dark'},
        'is_active': false,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };

      final project = Project.fromJson(json);
      expect(project.organizationId, 'org1');
      expect(project.icon, 'home');
      expect(project.settings['theme'], 'dark');
      expect(project.isActive, false);
    });
  });

  group('New Route Names', () {
    test('scenes routes exist', () {
      expect(RouteNames.scenes, 'scenes');
      expect(RouteNames.createScene, 'createScene');
    });

    test('analytics route exists', () {
      expect(RouteNames.analytics, 'analytics');
    });

    test('integrations route exists', () {
      expect(RouteNames.integrations, 'integrations');
    });

    test('edit project route exists', () {
      expect(RouteNames.editProject, 'editProject');
    });

    test('automation detail route exists', () {
      expect(RouteNames.automationDetail, 'automationDetail');
    });

    test('all route names are unique', () {
      final names = [
        RouteNames.splash,
        RouteNames.login,
        RouteNames.register,
        RouteNames.forgotPassword,
        RouteNames.emailVerification,
        RouteNames.home,
        RouteNames.projects,
        RouteNames.projectDetail,
        RouteNames.createProject,
        RouteNames.editProject,
        RouteNames.devices,
        RouteNames.deviceDetail,
        RouteNames.addDevice,
        RouteNames.editDevice,
        RouteNames.manageSensors,
        RouteNames.manageActuators,
        RouteNames.automations,
        RouteNames.automationDetail,
        RouteNames.createAutomation,
        RouteNames.aiAssistant,
        RouteNames.notifications,
        RouteNames.settings,
        RouteNames.profile,
        RouteNames.organizations,
        RouteNames.createOrganization,
        RouteNames.organizationDetail,
        RouteNames.invitations,
        RouteNames.apiKeys,
        RouteNames.dashboardEditor,
        RouteNames.scenes,
        RouteNames.createScene,
        RouteNames.analytics,
        RouteNames.integrations,
        RouteNames.deviceStudio,
        RouteNames.dashboards,
        RouteNames.createDashboard,
      ];
      expect(names.toSet().length, names.length);
    });
  });
}
