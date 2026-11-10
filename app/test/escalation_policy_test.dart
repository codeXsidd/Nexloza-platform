import 'package:flutter_test/flutter_test.dart';

import 'package:nexloza/features/alarms/domain/entities/escalation_policy_entity.dart';

void main() {
  Map<String, dynamic> makeStageJson({
    String id = 'stage-1',
    String policyId = 'policy-1',
    int stageNumber = 1,
    int delayMinutes = 15,
    List<String> targets = const ['user-a'],
    String actionType = 'notify',
  }) => {
    'id': id,
    'policy_id': policyId,
    'stage_number': stageNumber,
    'delay_minutes': delayMinutes,
    'notification_targets': targets,
    'action_type': actionType,
    'created_at': '2026-11-10T10:00:00Z',
  };

  Map<String, dynamic> makePolicyJson({
    String id = 'policy-1',
    String name = 'Default Escalation',
    String? description,
    bool isEnabled = true,
    List<Map<String, dynamic>>? stages,
  }) => {
    'id': id,
    'project_id': 'proj-1',
    'organization_id': 'org-1',
    'name': name,
    'description': description,
    'is_enabled': isEnabled,
    'escalation_stages':
        stages ??
        [
          makeStageJson(stageNumber: 1, delayMinutes: 5),
          makeStageJson(
            id: 'stage-2',
            stageNumber: 2,
            delayMinutes: 15,
            targets: ['user-b'],
          ),
          makeStageJson(
            id: 'stage-3',
            stageNumber: 3,
            delayMinutes: 30,
            targets: ['user-c'],
            actionType: 'reassign',
          ),
        ],
    'created_at': '2026-11-10T10:00:00Z',
    'updated_at': '2026-11-10T10:00:00Z',
  };

  group('EscalationPolicy — fromJson', () {
    test('parses all fields correctly', () {
      final policy = EscalationPolicy.fromJson(makePolicyJson());
      expect(policy.id, 'policy-1');
      expect(policy.name, 'Default Escalation');
      expect(policy.projectId, 'proj-1');
      expect(policy.organizationId, 'org-1');
      expect(policy.isEnabled, true);
      expect(policy.stages.length, 3);
    });

    test('stages are sorted by stageNumber', () {
      final policy = EscalationPolicy.fromJson(
        makePolicyJson(
          stages: [
            makeStageJson(id: 's3', stageNumber: 3, delayMinutes: 30),
            makeStageJson(id: 's1', stageNumber: 1, delayMinutes: 5),
            makeStageJson(id: 's2', stageNumber: 2, delayMinutes: 15),
          ],
        ),
      );
      expect(policy.stages[0].stageNumber, 1);
      expect(policy.stages[1].stageNumber, 2);
      expect(policy.stages[2].stageNumber, 3);
    });

    test('missing stages defaults to empty list', () {
      final json = makePolicyJson();
      json.remove('escalation_stages');
      final policy = EscalationPolicy.fromJson(json);
      expect(policy.stages, isEmpty);
    });

    test('description is nullable', () {
      final policy = EscalationPolicy.fromJson(makePolicyJson());
      expect(policy.description, isNull);

      final withDesc = EscalationPolicy.fromJson(
        makePolicyJson(description: 'High priority'),
      );
      expect(withDesc.description, 'High priority');
    });
  });

  group('EscalationPolicy — computed properties', () {
    test('stageCount returns number of stages', () {
      final policy = EscalationPolicy.fromJson(makePolicyJson());
      expect(policy.stageCount, 3);
    });

    test('totalEscalationMinutes sums all stage delays', () {
      final policy = EscalationPolicy.fromJson(makePolicyJson());
      expect(policy.totalEscalationMinutes, 50); // 5 + 15 + 30
    });

    test('empty stages yields 0 total minutes', () {
      final json = makePolicyJson();
      json['escalation_stages'] = [];
      final policy = EscalationPolicy.fromJson(json);
      expect(policy.totalEscalationMinutes, 0);
    });
  });

  group('EscalationPolicy — toJson', () {
    test('toJson includes required fields', () {
      final policy = EscalationPolicy.fromJson(makePolicyJson());
      final json = policy.toJson();
      expect(json['project_id'], 'proj-1');
      expect(json['organization_id'], 'org-1');
      expect(json['name'], 'Default Escalation');
      expect(json['is_enabled'], true);
    });
  });

  group('EscalationStage — fromJson', () {
    test('parses all fields correctly', () {
      final stage = EscalationStage.fromJson(makeStageJson());
      expect(stage.id, 'stage-1');
      expect(stage.policyId, 'policy-1');
      expect(stage.stageNumber, 1);
      expect(stage.delayMinutes, 15);
      expect(stage.notificationTargets, ['user-a']);
      expect(stage.actionType, 'notify');
    });

    test('notification_targets handles list of strings', () {
      final stage = EscalationStage.fromJson(
        makeStageJson(targets: ['user-a', 'user-b', 'user-c']),
      );
      expect(stage.notificationTargets.length, 3);
    });

    test('notification_targets handles non-list gracefully', () {
      final json = makeStageJson();
      json['notification_targets'] = 'not-a-list';
      final stage = EscalationStage.fromJson(json);
      expect(stage.notificationTargets, isEmpty);
    });

    test('notification_targets handles null gracefully', () {
      final json = makeStageJson();
      json['notification_targets'] = null;
      final stage = EscalationStage.fromJson(json);
      expect(stage.notificationTargets, isEmpty);
    });

    test('missing fields use defaults', () {
      final json = {
        'id': 'stage-x',
        'policy_id': 'policy-x',
        'created_at': '2026-11-10T10:00:00Z',
        'notification_targets': <String>[],
      };
      final stage = EscalationStage.fromJson(json);
      expect(stage.stageNumber, 1);
      expect(stage.delayMinutes, 15);
      expect(stage.actionType, 'notify');
    });
  });

  group('EscalationStage — actionDisplayName', () {
    test('notify displays as Notify', () {
      final stage = EscalationStage.fromJson(
        makeStageJson(actionType: 'notify'),
      );
      expect(stage.actionDisplayName, 'Notify');
    });

    test('reassign displays as Reassign', () {
      final stage = EscalationStage.fromJson(
        makeStageJson(actionType: 'reassign'),
      );
      expect(stage.actionDisplayName, 'Reassign');
    });

    test('auto_acknowledge displays as Auto Acknowledge', () {
      final stage = EscalationStage.fromJson(
        makeStageJson(actionType: 'auto_acknowledge'),
      );
      expect(stage.actionDisplayName, 'Auto Acknowledge');
    });

    test('unknown action type returns raw value', () {
      final stage = EscalationStage.fromJson(
        makeStageJson(actionType: 'custom_action'),
      );
      expect(stage.actionDisplayName, 'custom_action');
    });
  });

  group('EscalationStage — toJson', () {
    test('toJson includes required fields', () {
      final stage = EscalationStage.fromJson(makeStageJson());
      final json = stage.toJson();
      expect(json['policy_id'], 'policy-1');
      expect(json['stage_number'], 1);
      expect(json['delay_minutes'], 15);
      expect(json['notification_targets'], ['user-a']);
      expect(json['action_type'], 'notify');
    });
  });
}
