import 'dart:async';
import 'dart:js_interop';

import 'package:sqlite3/wasm.dart';
import 'package:web/web.dart' as web;

import 'offline_connection.dart';

Future<OfflineConnection> openOfflineConnection() async {
  final ready = Completer<OfflineConnection>();
  final release = Completer<JSAny?>();

  // IndexedDB VFS mirrors files in memory. Separate tabs must not open
  // independent writable copies of the same mirror.
  late final Future<JSAny?> lifetime;
  lifetime = web.window.navigator.locks
      .request(
        'nexloza-offline-sqlite',
        web.LockOptions(ifAvailable: true),
        ((web.Lock? lock) {
          unawaited(() async {
            IndexedDbFileSystem? fileSystem;
            try {
              if (lock == null) {
                throw StateError('Offline storage is open in another tab');
              }
              final sqlite = await WasmSqlite3.loadFromUrl(
                Uri.base.resolve('sqlite3.wasm'),
              );
              final fs = fileSystem = await IndexedDbFileSystem.open(
                dbName: 'nexloza-offline',
                writeAutomatically: false,
              );
              sqlite.registerVirtualFileSystem(fs, makeDefault: true);
              final database = sqlite.open('/nexloza.sqlite3');
              ready.complete((
                database: database,
                flush: fs.flush,
                close: () async {
                  try {
                    database.close();
                    await fs.close();
                  } finally {
                    release.complete(null);
                    await lifetime;
                  }
                },
              ));
            } catch (error, stack) {
              ready.completeError(error, stack);
              release.complete(null);
              await fileSystem?.close();
            }
          }());
          return release.future.toJS;
        }).toJS,
      )
      .toDart;
  unawaited(
    lifetime.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        if (!ready.isCompleted) ready.completeError(error, stack);
      },
    ),
  );
  return ready.future;
}
