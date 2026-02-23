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
  TextColumn get screens => text().map(const ScreensConverter())();
  TextColumn get settings =>
      text().withDefault(const Constant('{}')).map(const JsonMapConverter())();
  TextColumn get guide =>
      text().withDefault(const Constant('[]')).map(const GuideConverter())();
  TextColumn get navigation =>
      text().nullable().map(const NavigationConverter())();
  TextColumn get database =>
      text().nullable().map(const ModuleDatabaseConverter())();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CapabilityRow')
class Capabilities extends Table {
  TextColumn get id => text()();
  TextColumn get moduleId => text().nullable()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get message => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get config =>
      text().withDefault(const Constant('{}')).map(const JsonMapConverter())();
  IntColumn get lastFiredAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Conversation')
class Conversations extends Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer()();
  IntColumn get lastMessageAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ChatMessage')
class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId =>
      text().references(Conversations, #id)();
  TextColumn get role => text()(); // 'user' or 'assistant'
  TextColumn get content => text()();
  TextColumn get toolCalls =>
      text().nullable()(); // JSON-encoded list, nullable
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
