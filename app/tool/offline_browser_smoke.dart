import 'package:nexloza/core/storage/offline_database.dart';
import 'package:web/web.dart' as web;

Future<void> main() async {
  final body = web.document.body!;
  try {
    final original = await OfflineDatabase.open();
    try {
      var locked = false;
      try {
        final second = await OfflineDatabase.open();
        await second.close();
      } on StateError {
        locked = true;
      }
      if (!locked) throw StateError('Browser opened two SQLite writers');
      await original.write('alice', 'projects', 'org-a', 'list', ['project']);
    } finally {
      await original.close();
    }

    final reopened = await OfflineDatabase.open();
    try {
      final stored = reopened.read('alice', 'projects', 'org-a', 'list');
      if (stored is! List || stored.single != 'project') {
        throw StateError('Browser SQLite snapshot was not durable');
      }
      if (reopened.read('bob', 'projects', 'org-a', 'list') != null) {
        throw StateError('Browser SQLite exposed another account');
      }
    } finally {
      await reopened.close();
    }
    body.textContent = 'PASS: browser SQLite persistence and single writer';
  } catch (error) {
    body.textContent = 'FAIL: $error';
  }
}
