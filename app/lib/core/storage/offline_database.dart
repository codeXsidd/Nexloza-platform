import 'dart:convert';

import 'package:sqlite3/common.dart';

import 'offline_connection.dart';
import 'offline_connection_native.dart'
    if (dart.library.js_interop) 'offline_connection_web.dart';

typedef JsonMap = Map<String, dynamic>;

/// An authenticated namespace within a versioned local SQLite database.
class OfflineDatabase {
  static const schemaVersion = 1;
  static const cacheLifetime = Duration(days: 7);
  static const telemetryLifetime = Duration(hours: 48);
  static const maxTelemetryQueries = 40;
  static const maxSnapshots = 400;
  static const maxSnapshotBytes = 256 * 1024;
  static const maxAccounts = 5;

  final OfflineConnection _connection;
  final DateTime Function() _clock;
  CommonDatabase get _db => _connection.database;

  OfflineDatabase(this._connection, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    final version = _db.userVersion;
    if (version > schemaVersion) {
      throw UnsupportedError('Offline database is newer than this app');
    }
    if (version == 0) {
      _transaction(() {
        _db.execute('''
          CREATE TABLE snapshots (
            account TEXT NOT NULL, kind TEXT NOT NULL, scope TEXT NOT NULL,
            query_key TEXT NOT NULL, body TEXT NOT NULL, saved_at INTEGER NOT NULL,
            PRIMARY KEY (account, kind, scope, query_key)
          );
          CREATE INDEX snapshot_retention ON snapshots(account, kind, saved_at);

          CREATE TABLE outbox (
            account TEXT NOT NULL, operation_id TEXT NOT NULL,
            project_id TEXT NOT NULL, expected_version TEXT NOT NULL,
            body TEXT NOT NULL, created_at INTEGER NOT NULL, attempts INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (account, operation_id), UNIQUE (account, project_id)
          );
          CREATE INDEX outbox_order ON outbox(account, created_at, operation_id);

          CREATE TABLE sync_conflicts (
            account TEXT NOT NULL, operation_id TEXT NOT NULL,
            project_id TEXT NOT NULL, body TEXT NOT NULL, reason TEXT NOT NULL,
            created_at INTEGER NOT NULL, PRIMARY KEY(account, operation_id)
          );
          CREATE TABLE sync_metadata (
            account TEXT NOT NULL, key TEXT NOT NULL, value TEXT NOT NULL,
            PRIMARY KEY(account, key)
          );
        ''');
        _db.userVersion = schemaVersion;
      });
    }
  }

  static Future<OfflineDatabase> open() async {
    final connection = await openOfflineConnection();
    try {
      final database = OfflineDatabase(connection);
      await connection.flush();
      return database;
    } catch (_) {
      await connection.close();
      rethrow;
    }
  }

  int get _now => _clock().millisecondsSinceEpoch;

  Object? read(String account, String kind, String scope, String query) {
    final maxAge = kind == 'telemetry' ? telemetryLifetime : cacheLifetime;
    final rows = _db.select(
      'SELECT body FROM snapshots WHERE account = ? AND kind = ? AND scope = ? '
      'AND query_key = ? AND saved_at >= ?',
      [account, kind, scope, query, _now - maxAge.inMilliseconds],
    );
    return rows.isEmpty ? null : jsonDecode(rows.single['body'] as String);
  }

  Future<void> write(
    String account,
    String kind,
    String scope,
    String query,
    Object body,
  ) async {
    final encoded = jsonEncode(_redact(body));
    final now = _now;
    _transaction(() {
      _db.execute(
        'DELETE FROM snapshots WHERE saved_at < ? OR '
        '(kind = \'telemetry\' AND saved_at < ?)',
        [
          now - cacheLifetime.inMilliseconds,
          now - telemetryLifetime.inMilliseconds,
        ],
      );
      if (utf8.encode(encoded).length > maxSnapshotBytes) {
        _db.execute(
          'DELETE FROM snapshots WHERE account = ? AND kind = ? AND scope = ? '
          'AND query_key = ?',
          [account, kind, scope, query],
        );
        return;
      }
      _db.execute(
        'INSERT OR REPLACE INTO snapshots VALUES (?, ?, ?, ?, ?, ?)',
        [account, kind, scope, query, encoded, now],
      );
      _db.execute(
        'DELETE FROM snapshots WHERE rowid IN (SELECT rowid FROM snapshots '
        'WHERE account = ? AND kind = \'telemetry\' ORDER BY saved_at DESC, '
        'rowid DESC LIMIT -1 OFFSET ?)',
        [account, maxTelemetryQueries],
      );
      _db.execute(
        'DELETE FROM snapshots WHERE rowid IN (SELECT rowid FROM snapshots '
        'WHERE account = ? ORDER BY saved_at DESC, rowid DESC LIMIT -1 OFFSET ?)',
        [account, maxSnapshots],
      );
      _db.execute(
        'DELETE FROM snapshots WHERE account IN (SELECT account FROM snapshots '
        'GROUP BY account ORDER BY max(saved_at) DESC, account LIMIT -1 OFFSET ?)',
        [maxAccounts],
      );
    });
    await _connection.flush();
  }

  Future<void> invalidate(String account, String kind) async {
    _db.execute('DELETE FROM snapshots WHERE account = ? AND kind = ?', [
      account,
      kind,
    ]);
    await _connection.flush();
  }

  Future<void> queueProjectEdit({
    required String account,
    required String operationId,
    required String projectId,
    required String expectedVersion,
    required JsonMap changes,
  }) async {
    if (account.isEmpty ||
        projectId.isEmpty ||
        DateTime.tryParse(expectedVersion) == null ||
        changes.isEmpty ||
        changes.entries.any(
          (entry) => entry.key == 'is_active'
              ? entry.value is! bool
              : !const {
                      'name',
                      'description',
                      'category',
                    }.contains(entry.key) ||
                    (entry.value != null && entry.value is! String),
        )) {
      throw ArgumentError('Unsupported offline project edit');
    }
    _db.execute(
      'INSERT INTO outbox (account, operation_id, project_id, expected_version, '
      'body, created_at) VALUES (?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(account, project_id) DO NOTHING',
      [
        account,
        operationId,
        projectId,
        expectedVersion,
        jsonEncode(changes),
        _now,
      ],
    );
    if (_db.updatedRows == 0) {
      throw StateError('A project edit is already waiting to synchronize');
    }
    await _connection.flush();
  }

  Object? projectPreview(String account, Object? snapshot) {
    final edits = {for (final row in pending(account)) row['project_id']: row};
    Object? overlay(Object? value) {
      if (value is! JsonMap) return value;
      final edit = edits[value['id']];
      final version = DateTime.tryParse(value['updated_at']?.toString() ?? '');
      if (edit == null ||
          version == null ||
          version != DateTime.tryParse(edit['expected_version'] as String)) {
        return value;
      }
      return {...value, ...jsonDecode(edit['body'] as String) as JsonMap};
    }

    return snapshot is List
        ? snapshot.map(overlay).toList()
        : overlay(snapshot);
  }

  List<Row> pending(String account) => _db.select(
    'SELECT * FROM outbox WHERE account = ? ORDER BY created_at, operation_id',
    [account],
  );

  List<Row> conflicts(String account) => _db.select(
    'SELECT * FROM sync_conflicts WHERE account = ? ORDER BY created_at',
    [account],
  );

  Future<void> retry(String account, String operationId) async {
    _db.execute(
      'UPDATE outbox SET attempts = attempts + 1 WHERE account = ? AND operation_id = ?',
      [account, operationId],
    );
    await _connection.flush();
  }

  Future<void> settle(
    String account,
    String operationId, {
    String? conflict,
  }) async {
    _transaction(() {
      if (conflict != null) {
        _db.execute(
          'INSERT INTO sync_conflicts SELECT account, operation_id, project_id, '
          'body, ?, ? FROM outbox WHERE account = ? AND operation_id = ?',
          [conflict, _now, account, operationId],
        );
      }
      _db.execute('DELETE FROM outbox WHERE account = ? AND operation_id = ?', [
        account,
        operationId,
      ]);
      _db.execute('DELETE FROM snapshots WHERE account = ? AND kind = ?', [
        account,
        'projects',
      ]);
      _db.execute('INSERT OR REPLACE INTO sync_metadata VALUES (?, ?, ?)', [
        account,
        'last_project_settlement',
        DateTime.fromMillisecondsSinceEpoch(
          _now,
          isUtc: true,
        ).toIso8601String(),
      ]);
    });
    await _connection.flush();
  }

  void _transaction(void Function() operation) {
    _db.execute('BEGIN IMMEDIATE');
    try {
      operation();
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  static Object? _redact(Object? value) => switch (value) {
    Map<String, dynamic> map => <String, dynamic>{
      for (final entry in map.entries)
        if (!_sensitive.hasMatch(entry.key)) entry.key: _redact(entry.value),
    },
    List<dynamic> list => list.map(_redact).toList(),
    _ => value,
  };

  static final _sensitive = RegExp(
    r'password|secret|token|credential|authorization|api.?key|private.?key',
    caseSensitive: false,
  );

  Future<void> close() => _connection.close();
}
