import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/features/rule_engine/domain/entities/rule_execution.dart';

void main() {
  group('ExecutionStatus', () {
    test('fromString resolves all values', () {
      expect(ExecutionStatus.fromString('running'), ExecutionStatus.running);
      expect(ExecutionStatus.fromString('completed'), ExecutionStatus.completed);
      expect(ExecutionStatus.fromString('failed'), ExecutionStatus.failed);
      expect(ExecutionStatus.fromString('cancelled'), ExecutionStatus.cancelled);
    });

    test('fromString unknown defaults to failed', () {
      expect(ExecutionStatus.fromString('bogus'), ExecutionStatus.failed);
      expect(ExecutionStatus.fromString(''), ExecutionStatus.failed);
    });

    test('displayName for each value', () {
      expect(ExecutionStatus.running.displayName, 'Running');
      expect(ExecutionStatus.completed.displayName, 'Completed');
      expect(ExecutionStatus.failed.displayName, 'Failed');
      expect(ExecutionStatus.cancelled.displayName, 'Cancelled');
    });
  });

  group('EventStatus', () {
    test('fromString resolves all values', () {
      expect(EventStatus.fromString('pending'), EventStatus.pending);
      expect(EventStatus.fromString('processing'), EventStatus.processing);
      expect(EventStatus.fromString('completed'), EventStatus.completed);
      expect(EventStatus.fromString('failed'), EventStatus.failed);
      expect(EventStatus.fromString('skipped'), EventStatus.skipped);
    });

    test('fromString unknown defaults to pending', () {
      expect(EventStatus.fromString('xyz'), EventStatus.pending);
    });
  });

  group('NodeResult', () {
    test('constructor sets all fields', () {
      final nr = NodeResult(
        nodeId: 'n1',
        nodeType: 'greaterThan',
        status: 'evaluated',
        output: true,
        error: null,
        evaluatedAt: DateTime(2026, 11, 10),
      );
      expect(nr.nodeId, 'n1');
      expect(nr.nodeType, 'greaterThan');
      expect(nr.status, 'evaluated');
      expect(nr.output, true);
      expect(nr.error, isNull);
    });

    test('toJson and fromJson round-trip', () {
      final original = NodeResult(
        nodeId: 'n2',
        nodeType: 'sendCommand',
        status: 'failed',
        output: {'device_id': 'd1'},
        error: 'timeout',
        evaluatedAt: DateTime.utc(2026, 11, 10, 12, 0),
      );
      final json = original.toJson();
      final restored = NodeResult.fromJson(json);
      expect(restored.nodeId, 'n2');
      expect(restored.nodeType, 'sendCommand');
      expect(restored.status, 'failed');
      expect(restored.error, 'timeout');
      expect(restored.evaluatedAt.year, 2026);
    });
  });

  group('RuleExecution', () {
    test('constructor defaults', () {
      final exec = RuleExecution(
        id: 'ex1',
        automationId: 'a1',
        status: ExecutionStatus.completed,
        startedAt: DateTime.now(),
      );
      expect(exec.triggerData, isEmpty);
      expect(exec.actionsExecuted, isEmpty);
      expect(exec.executionDepth, 0);
      expect(exec.nodeResults, isEmpty);
      expect(exec.dryRun, isFalse);
      expect(exec.correlationId, isNull);
      expect(exec.ruleVersionId, isNull);
    });

    test('fromJson with full data', () {
      final exec = RuleExecution.fromJson({
        'id': 'ex1',
        'automation_id': 'a1',
        'trigger_id': 't1',
        'trigger_data': {'device_id': 'd1', 'value': 42},
        'status': 'completed',
        'started_at': '2026-11-10T10:00:00Z',
        'completed_at': '2026-11-10T10:00:01Z',
        'error_message': null,
        'actions_executed': [
          {'action_id': 'act1', 'status': 'completed'},
        ],
        'duration_ms': 1000,
        'correlation_id': 'corr1',
        'execution_depth': 2,
        'node_results': [
          {
            'node_id': 'n1',
            'node_type': 'manualTrigger',
            'status': 'evaluated',
            'output': true,
            'evaluated_at': '2026-11-10T10:00:00Z',
          },
        ],
        'rule_version_id': 'rv1',
        'dry_run': true,
      });
      expect(exec.id, 'ex1');
      expect(exec.triggerId, 't1');
      expect(exec.triggerData['value'], 42);
      expect(exec.status, ExecutionStatus.completed);
      expect(exec.durationMs, 1000);
      expect(exec.correlationId, 'corr1');
      expect(exec.executionDepth, 2);
      expect(exec.nodeResults.length, 1);
      expect(exec.nodeResults.first.nodeId, 'n1');
      expect(exec.ruleVersionId, 'rv1');
      expect(exec.dryRun, isTrue);
    });

    test('fromJson with minimal data', () {
      final exec = RuleExecution.fromJson({
        'id': 'ex2',
        'automation_id': 'a2',
        'status': 'running',
        'started_at': '2026-11-10T10:00:00Z',
      });
      expect(exec.id, 'ex2');
      expect(exec.status, ExecutionStatus.running);
      expect(exec.triggerData, isEmpty);
      expect(exec.actionsExecuted, isEmpty);
      expect(exec.nodeResults, isEmpty);
      expect(exec.dryRun, isFalse);
      expect(exec.executionDepth, 0);
    });
  });

  group('RuleEvent', () {
    test('fromJson with full data', () {
      final event = RuleEvent.fromJson({
        'id': 'ev1',
        'event_type': 'telemetry_received',
        'device_id': 'd1',
        'project_id': 'p1',
        'organization_id': 'o1',
        'payload': {'sensor_key': 'temp', 'value': 30},
        'idempotency_key': 'idem1',
        'correlation_id': 'corr1',
        'causation_id': 'cause1',
        'depth': 3,
        'status': 'completed',
        'processed_at': '2026-11-10T10:01:00Z',
        'error_message': null,
        'created_at': '2026-11-10T10:00:00Z',
      });
      expect(event.id, 'ev1');
      expect(event.eventType, 'telemetry_received');
      expect(event.deviceId, 'd1');
      expect(event.projectId, 'p1');
      expect(event.organizationId, 'o1');
      expect(event.payload['sensor_key'], 'temp');
      expect(event.idempotencyKey, 'idem1');
      expect(event.correlationId, 'corr1');
      expect(event.causationId, 'cause1');
      expect(event.depth, 3);
      expect(event.status, EventStatus.completed);
      expect(event.processedAt, isNotNull);
    });

    test('fromJson with minimal data', () {
      final event = RuleEvent.fromJson({
        'id': 'ev2',
        'event_type': 'manual_trigger',
        'project_id': 'p1',
        'organization_id': 'o1',
        'correlation_id': 'corr2',
        'created_at': '2026-11-10T10:00:00Z',
      });
      expect(event.deviceId, isNull);
      expect(event.payload, isEmpty);
      expect(event.idempotencyKey, isNull);
      expect(event.causationId, isNull);
      expect(event.depth, 0);
      expect(event.status, EventStatus.pending);
      expect(event.processedAt, isNull);
      expect(event.errorMessage, isNull);
    });
  });
}
