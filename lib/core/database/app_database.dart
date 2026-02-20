import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/blueprint/navigation/module_navigation.dart';
import '../../features/schema/models/module_schema.dart';
import 'converters.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Modules, Entries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDefault());

  static QueryExecutor _openDefault() {
    return driftDatabase(name: 'aj_assistant');
  }

  @override
  int get schemaVersion => 1;
}
