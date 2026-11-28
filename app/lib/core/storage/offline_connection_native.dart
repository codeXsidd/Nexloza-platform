import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'offline_connection.dart';

Future<OfflineConnection> openOfflineConnection() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  final database = sqlite3.open(
    '${directory.path}${Platform.pathSeparator}nexloza-offline.sqlite3',
  );
  database.execute('PRAGMA busy_timeout = 5000');
  return (
    database: database,
    flush: () async {},
    close: () async => database.close(),
  );
}
