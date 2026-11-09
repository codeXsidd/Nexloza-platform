import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/providers/connectivity_provider.dart';
import '../../shared/providers/supabase_provider.dart';
import '../utils/logger.dart';

class PendingOperation {
  final String id;
  final String table;
  final String method;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? filters;
  final DateTime createdAt;
  final int retryCount;

  const PendingOperation({
    required this.id,
    required this.table,
    required this.method,
    required this.data,
    this.filters,
    required this.createdAt,
    this.retryCount = 0,
  });

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'] as String,
      table: json['table'] as String,
      method: json['method'] as String,
      data: json['data'] as Map<String, dynamic>,
      filters: json['filters'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      retryCount: json['retry_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'table': table,
    'method': method,
    'data': data,
    'filters': filters,
    'created_at': createdAt.toIso8601String(),
    'retry_count': retryCount,
  };

  PendingOperation incrementRetry() => PendingOperation(
    id: id,
    table: table,
    method: method,
    data: data,
    filters: filters,
    createdAt: createdAt,
    retryCount: retryCount + 1,
  );
}

class OfflineSyncService {
  static const _queueKey = 'nexloza_offline_queue';
  static const _maxRetries = 5;

  final SupabaseClient _client;
  final SharedPreferences _prefs;
  bool _isSyncing = false;

  OfflineSyncService(this._client, this._prefs);

  List<PendingOperation> get pendingOperations {
    final raw = _prefs.getStringList(_queueKey) ?? [];
    return raw
        .map(
          (s) =>
              PendingOperation.fromJson(json.decode(s) as Map<String, dynamic>),
        )
        .toList();
  }

  int get pendingCount => pendingOperations.length;

  Future<void> enqueue(PendingOperation op) async {
    final ops = pendingOperations;
    ops.add(op);
    await _saveQueue(ops);
    AppLogger.info('Offline queue: enqueued ${op.method} on ${op.table}');
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final ops = pendingOperations;
      if (ops.isEmpty) return;

      AppLogger.info('Offline sync: processing ${ops.length} operations');
      final failed = <PendingOperation>[];

      for (final op in ops) {
        try {
          await _executeOperation(op);
        } catch (e) {
          AppLogger.error('Offline sync failed for ${op.id}: $e');
          final retried = op.incrementRetry();
          if (retried.retryCount < _maxRetries) {
            failed.add(retried);
          } else {
            AppLogger.error(
              'Offline sync: dropping ${op.id} after max retries',
            );
          }
        }
      }

      await _saveQueue(failed);
      AppLogger.info(
        'Offline sync complete: ${ops.length - failed.length} succeeded, ${failed.length} pending',
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _executeOperation(PendingOperation op) async {
    switch (op.method) {
      case 'insert':
        await _client.from(op.table).insert(op.data);
      case 'update':
        var query = _client.from(op.table).update(op.data);
        if (op.filters != null) {
          for (final entry in op.filters!.entries) {
            query = query.eq(entry.key, entry.value);
          }
        }
        await query;
      case 'delete':
        var query = _client.from(op.table).delete();
        if (op.filters != null) {
          for (final entry in op.filters!.entries) {
            query = query.eq(entry.key, entry.value);
          }
        }
        await query;
      case 'upsert':
        await _client.from(op.table).upsert(op.data);
    }
  }

  Future<void> _saveQueue(List<PendingOperation> ops) async {
    final encoded = ops.map((op) => json.encode(op.toJson())).toList();
    await _prefs.setStringList(_queueKey, encoded);
  }

  Future<void> clearQueue() async {
    await _prefs.remove(_queueKey);
  }
}

final offlineSyncInitProvider = FutureProvider<OfflineSyncService>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final prefs = await SharedPreferences.getInstance();
  return OfflineSyncService(client, prefs);
});

final offlineSyncControllerProvider = Provider<void>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  if (isOnline) {
    ref.read(offlineSyncInitProvider).whenData((sync) => sync.syncAll());
  }
});
