import 'package:drift/drift.dart';

import 'converters.dart';

@DataClassName('ModuleRow')
class Modules extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get icon => text().withDefault(const Constant('cube'))();
  TextColumn get color => text().withDefault(const Constant('#D94E33'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get schemas => text().map(const SchemasConverter())();
  TextColumn get screens => text().map(const ScreensConverter())();
  TextColumn get settings =>
      text().withDefault(const Constant('{}')).map(const JsonMapConverter())();
  TextColumn get guide =>
      text().withDefault(const Constant('[]')).map(const GuideConverter())();
  TextColumn get navigation =>
      text().nullable().map(const NavigationConverter())();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EntryRow')
class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get moduleId => text().references(Modules, #id)();
  TextColumn get schemaKey => text().withDefault(const Constant('default'))();
  TextColumn get data => text().map(const JsonMapConverter())();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
