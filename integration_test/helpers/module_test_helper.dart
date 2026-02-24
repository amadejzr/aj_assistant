import 'package:bowerlab/core/database/app_database.dart';
import 'package:bowerlab/core/database/mutation_executor.dart';
import 'package:bowerlab/core/database/query_executor.dart';
import 'package:bowerlab/core/database/schema_manager.dart';
import 'package:bowerlab/core/models/module.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull, QueryExecutor;
import 'package:drift/native.dart';

class ModuleTestHarness {
  late AppDatabase db;
  late SchemaManager schemaManager;
  late MutationExecutor mutationExecutor;
  late QueryExecutor queryExecutor;

  Future<void> setUp(Module module) async {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    schemaManager = SchemaManager(db: db);
    await schemaManager.installModule(module);

    final tableNames = module.database!.tableNames.values.toSet();
    mutationExecutor = MutationExecutor(
      db: db,
      moduleTableNames: tableNames,
    );
    queryExecutor = QueryExecutor(
      db: db,
      moduleTableNames: tableNames,
    );
  }

  Future<void> tearDown() async {
    await db.close();
  }

  Future<List<Map<String, dynamic>>> queryRows(String sql) async {
    final rows = await db.customSelect(sql).get();
    return rows.map((r) => r.data).toList();
  }

  Future<Map<String, dynamic>> queryRow(String sql) async {
    final row = await db.customSelect(sql).getSingle();
    return row.data;
  }
}
