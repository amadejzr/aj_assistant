import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/blueprint/navigation/module_navigation.dart';
import '../../features/modules/models/module_schema.dart';
import 'converters.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Modules, Entries, Capabilities])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDefault());

  static QueryExecutor _openDefault() {
    return driftDatabase(name: 'aj_assistant');
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(capabilities);
      }
      if (from < 3) {
        // SQLite doesn't support ALTER COLUMN to nullable,
        // so we recreate the capabilities table.
        await m.deleteTable('capabilities');
        await m.createTable(capabilities);
      }
    },
  );
}
