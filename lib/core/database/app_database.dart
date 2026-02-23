import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/blueprint/navigation/module_navigation.dart';
import 'converters.dart';
import 'module_database.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Modules, Capabilities, Conversations, ChatMessages])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDefault());

  static QueryExecutor _openDefault() {
    return driftDatabase(name: 'aj_assistant');
  }

  @override
  int get schemaVersion => 6;

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
      if (from < 4) {
        // Recreate modules table: remove schemas column, add database column.
        await customStatement('ALTER TABLE modules RENAME TO modules_old');
        await m.createTable(modules);
        await customStatement('''
          INSERT INTO modules (id, name, description, icon, color, sort_order,
            screens, settings, guide, navigation, version, created_at, updated_at)
          SELECT id, name, description, icon, color, sort_order,
            screens, settings, guide, navigation, version, created_at, updated_at
          FROM modules_old
        ''');
        await customStatement('DROP TABLE modules_old');
      }
      if (from < 5) {
        await customStatement('DROP TABLE IF EXISTS entries');
      }
      if (from < 6) {
        await m.createTable(conversations);
        await m.createTable(chatMessages);
      }
    },
  );
}
