import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexloza/core/storage/offline_database.dart';
import 'package:sqlite3/sqlite3.dart';

OfflineDatabase open(String path, {DateTime Function()? clock}) {
  final database = sqlite3.open(path);
  return OfflineDatabase((
    database: database,
    flush: () async {},
    close: () async => database.close(),
  ), clock: clock);
}

void main() {
  test(
    'SQLite keeps profiles and query scopes isolated and removes secrets',
    () async {
      final store = open(':memory:');
      addTearDown(store.close);
      await store.write('alice', 'devices', 'project-a', 'list', [
        {
          'id': 'a',
          'metadata': {'api_key': 'secret', 'label': 'a'},
        },
      ]);
      expect(store.read('alice', 'devices', 'project-a', 'list'), [
        {
          'id': 'a',
          'metadata': {'label': 'a'},
        },
      ]);
      expect(store.read('alice', 'devices', 'project-b', 'list'), isNull);
      expect(store.read('bob', 'devices', 'project-a', 'list'), isNull);
    },
  );

  test(
    'outbox survives restart and atomically records a scoped conflict',
    () async {
      final folder = await Directory.systemTemp.createTemp('nexloza-offline-');
      addTearDown(() => folder.delete(recursive: true));
      final path = '${folder.path}${Platform.pathSeparator}offline.sqlite';
      final first = open(path);
      await first.queueProjectEdit(
        account: 'alice',
        operationId: 'op',
        projectId: 'project',
        expectedVersion: '2026-01-01T00:00:00Z',
        changes: {'name': 'Edited'},
      );
      await first.close();

      final second = open(path);
      addTearDown(second.close);
      expect(second.pending('bob'), isEmpty);
      expect(jsonDecode(second.pending('alice').single['body'] as String), {
        'name': 'Edited',
      });
      await second.retry('alice', 'op');
      expect(second.pending('alice').single['attempts'], 1);
      await second.settle('alice', 'op', conflict: 'Version conflict');
      expect(second.pending('alice'), isEmpty);
      expect(second.conflicts('alice').single['reason'], 'Version conflict');
      expect(second.conflicts('bob'), isEmpty);
    },
  );

  test('telemetry snapshots are bounded and expire independently', () async {
    var now = DateTime.utc(2026);
    final store = open(':memory:', clock: () => now);
    addTearDown(store.close);
    for (var index = 0; index <= OfflineDatabase.maxTelemetryQueries; index++) {
      await store.write('a', 'telemetry', 'device', '$index', [index]);
    }
    expect(store.read('a', 'telemetry', 'device', '0'), isNull);
    expect(store.read('a', 'telemetry', 'device', '1'), [1]);
    now = now.add(const Duration(days: 3));
    expect(store.read('a', 'telemetry', 'device', '1'), isNull);
  });

  test(
    'outbox refuses unsupported fields and duplicate pending edits',
    () async {
      final store = open(':memory:');
      addTearDown(store.close);
      Future<void> enqueue(String id, Map<String, dynamic> changes) =>
          store.queueProjectEdit(
            account: 'a',
            operationId: id,
            projectId: 'p',
            expectedVersion: '2026-01-01T00:00:00Z',
            changes: changes,
          );
      await expectLater(
        enqueue('1', {'password': 'test'}),
        throwsArgumentError,
      );
      await enqueue('2', {'name': 'Edited'});
      await expectLater(enqueue('3', {'name': 'Another'}), throwsStateError);
    },
  );
}
