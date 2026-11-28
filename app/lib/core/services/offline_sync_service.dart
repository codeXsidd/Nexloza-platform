import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../shared/providers/connectivity_provider.dart';
import '../../shared/providers/supabase_provider.dart';
import '../storage/offline_database.dart';
import '../utils/logger.dart';

class OfflineSyncService {
  final SupabaseClient _client;
  final Future<OfflineDatabase> Function() _open;
  Future<OfflineDatabase>? _database;
  bool _syncing = false;
  bool _resyncRequested = false;
  bool _closed = false;
  final _changes = StreamController<void>.broadcast();

  OfflineSyncService(this._client, {Future<OfflineDatabase> Function()? open})
    : _open = open ?? OfflineDatabase.open;

  String? get account => _client.auth.currentUser?.id;
  Future<OfflineDatabase> _store() => _database ??= _open();

  static bool isTransportError(Object error) =>
      error is http.ClientException || error is TimeoutException;

  bool _sameAccount(String account) => !_closed && this.account == account;

  Future<Object> readThrough({
    required String kind,
    required String scope,
    required String query,
    required Future<Object> Function() load,
  }) async {
    final user = account;
    try {
      final result = await load();
      if (user != null) {
        if (!_sameAccount(user)) throw StateError('Session changed');
        await _bestEffort((store) {
          if (!_sameAccount(user)) return Future<void>.value();
          return store.write(user, kind, scope, query, result);
        });
        if (!_sameAccount(user)) throw StateError('Session changed');
      }
      return result;
    } catch (error) {
      if (user != null && _sameAccount(user) && isTransportError(error)) {
        Object? cached;
        await _bestEffort((store) async {
          if (_sameAccount(user)) {
            cached = store.read(user, kind, scope, query);
            if (kind == 'projects') cached = store.projectPreview(user, cached);
          }
        });
        if (_sameAccount(user) && cached != null) return cached!;
      }
      rethrow;
    }
  }

  Future<void> invalidate(String? account, String kind) async {
    if (account != null) {
      await _bestEffort((store) => store.invalidate(account, kind));
    }
  }

  Future<void> _bestEffort(
    Future<void> Function(OfflineDatabase) action,
  ) async {
    if (_closed) return;
    try {
      await action(await _store());
    } catch (_) {
      AppLogger.warning('Offline storage is unavailable');
    }
  }

  Future<void> queueProjectEdit({
    required String account,
    required String projectId,
    required String expectedVersion,
    required JsonMap changes,
  }) async {
    final store = await _store();
    if (!_sameAccount(account)) throw StateError('Session changed');
    await store.queueProjectEdit(
      account: account,
      operationId: const Uuid().v4(),
      projectId: projectId,
      expectedVersion: expectedVersion,
      changes: changes,
    );
    if (!_closed) _changes.add(null);
  }

  Stream<({int pending, int conflicts})> watchSummary(String user) async* {
    yield await summary(user);
    await for (final _ in _changes.stream) {
      if (!_sameAccount(user)) break;
      yield await summary(user);
    }
  }

  Future<({int pending, int conflicts})> summary(String account) async {
    final store = await _store();
    if (!_sameAccount(account)) throw StateError('Session changed');
    return (
      pending: store.pending(account).length,
      conflicts: store.conflicts(account).length,
    );
  }

  Future<void> syncAll() async {
    final user = account;
    if (user == null || _closed) return;
    if (_syncing) {
      _resyncRequested = true;
      return;
    }
    _syncing = true;
    try {
      final store = await _store();
      for (final row in store.pending(user)) {
        if (!_sameAccount(user)) break;
        final id = row['operation_id'] as String;
        final payload = jsonDecode(row['body'] as String) as JsonMap;
        try {
          final result = await _client.rpc<bool>(
            'apply_offline_project_edit',
            params: {
              'p_account': user,
              'p_operation': id,
              'p_project': row['project_id'] as String,
              'p_expected_version': row['expected_version'] as String,
              'p_changes': payload,
            },
          );
          await store.settle(
            user,
            id,
            conflict: result
                ? null
                : 'Project changed or is no longer accessible',
          );
        } on PostgrestException catch (error) {
          // Permanent input and permission errors require user action.
          if (const {
            '42501',
            '22023',
            '22P02',
            '23502',
            '23514',
          }.contains(error.code)) {
            await store.settle(user, id, conflict: 'Project edit was rejected');
          } else {
            await store.retry(user, id);
            break;
          }
        } catch (_) {
          await store.retry(user, id);
          break;
        }
      }
    } catch (_) {
      AppLogger.warning('Offline synchronization is unavailable');
    } finally {
      _syncing = false;
      if (!_closed) _changes.add(null);
      if (_resyncRequested) {
        _resyncRequested = false;
        unawaited(syncAll());
      }
    }
  }

  Future<void> dispose() async {
    _closed = true;
    unawaited(_changes.close());
    try {
      await (await _database)?.close();
    } catch (_) {
      AppLogger.warning('Offline storage could not be closed');
    }
  }
}

final offlineSyncProvider = Provider<OfflineSyncService>((ref) {
  final service = OfflineSyncService(ref.watch(supabaseClientProvider));
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final offlineSyncControllerProvider = Provider<void>((ref) {
  final service = ref.watch(offlineSyncProvider);
  ref.watch(authStateProvider);
  if (ref.watch(isOnlineProvider) && service.account != null) {
    unawaited(service.syncAll());
  }
});

Future<Object> cachedRead(
  OfflineSyncService? offline,
  String kind,
  String scope,
  String query,
  Future<Object> Function() load,
) =>
    offline?.readThrough(kind: kind, scope: scope, query: query, load: load) ??
    load();

final offlineAccountProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider.select((user) => user?.id)),
);

final offlineStatusProvider =
    StreamProvider.autoDispose<({int pending, int conflicts})>((ref) {
      final user = ref.watch(offlineAccountProvider);
      return user == null
          ? const Stream.empty()
          : ref.watch(offlineSyncProvider).watchSummary(user);
    });
