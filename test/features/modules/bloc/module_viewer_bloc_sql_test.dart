import 'package:aj_assistant/core/database/app_database.dart';
import 'package:aj_assistant/core/database/module_database.dart';
import 'package:aj_assistant/core/database/schema_manager.dart';
import 'package:aj_assistant/core/models/entry.dart';
import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/core/repositories/entry_repository.dart';
import 'package:aj_assistant/core/repositories/module_repository.dart';
import 'package:aj_assistant/features/modules/bloc/module_viewer_bloc.dart';
import 'package:aj_assistant/features/modules/bloc/module_viewer_event.dart';
import 'package:aj_assistant/features/modules/bloc/module_viewer_state.dart';
import 'package:aj_assistant/features/modules/models/field_definition.dart';
import 'package:aj_assistant/features/modules/models/field_type.dart';
import 'package:aj_assistant/features/modules/models/module_schema.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockModuleRepository extends Mock implements ModuleRepository {}

class MockEntryRepository extends Mock implements EntryRepository {}

void main() {
  late AppDatabase db;
  late MockModuleRepository moduleRepo;
  late MockEntryRepository entryRepo;

  setUp(() async {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    moduleRepo = MockModuleRepository();
    entryRepo = MockEntryRepository();
  });

  tearDown(() async {
    await db.close();
  });

  Module _budgetModule() => const Module(
        id: 'budget-001',
        name: 'Budget Tracker',
        schemas: {
          'expense': ModuleSchema(
            label: 'Expense',
            fields: {
              'amount': FieldDefinition(
                  key: 'amount', type: FieldType.currency, label: 'Amount'),
              'description': FieldDefinition(
                  key: 'description',
                  type: FieldType.text,
                  label: 'Description'),
              'category': FieldDefinition(
                  key: 'category', type: FieldType.text, label: 'Category'),
            },
          ),
        },
        screens: {
          'main': {
            'type': 'screen',
            'queries': {
              'expenses': {
                'sql':
                    'SELECT id, amount, description, category FROM "m_budget_expenses" ORDER BY created_at DESC',
              },
              'total': {
                'sql':
                    'SELECT SUM(amount) as total_amount FROM "m_budget_expenses"',
              },
            },
          },
          'by_category': {
            'type': 'screen',
            'queries': {
              'filtered': {
                'sql':
                    'SELECT id, amount, description FROM "m_budget_expenses" WHERE category = :category',
                'params': {'category': '{{filters.category}}'},
                'defaults': {'category': 'Food'},
              },
            },
          },
        },
        database: ModuleDatabase(
          tableNames: {'expense': 'm_budget_expenses'},
          setup: [
            '''
            CREATE TABLE IF NOT EXISTS "m_budget_expenses" (
              id TEXT PRIMARY KEY,
              amount REAL NOT NULL,
              description TEXT,
              category TEXT,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
            ''',
          ],
          teardown: ['DROP TABLE IF EXISTS "m_budget_expenses"'],
        ),
      );

  Module _nonSqlModule() => const Module(
        id: 'simple-001',
        name: 'Simple Module',
        screens: {
          'main': {'type': 'screen'},
        },
      );

  group('SQL data loading', () {
    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'SQL module emits queryResults after start',
      setUp: () async {
        await SchemaManager(db: db).installModule(_budgetModule());
        // Seed data
        await db.customStatement(
          'INSERT INTO "m_budget_expenses" (id, amount, description, category, created_at, updated_at) '
          "VALUES ('e1', 50.0, 'Coffee', 'Food', 1000, 1000)",
        );
        when(() => moduleRepo.getModule('user1', 'budget-001'))
            .thenAnswer((_) async => _budgetModule());
      },
      build: () => ModuleViewerBloc(
        moduleRepository: moduleRepo,
        entryRepository: entryRepo,
        appDatabase: db,
        userId: 'user1',
      ),
      act: (bloc) => bloc.add(const ModuleViewerStarted('budget-001')),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<ModuleViewerLoading>(),
        isA<ModuleViewerLoaded>()
            .having((s) => s.queryResults, 'queryResults', isEmpty),
        isA<ModuleViewerLoaded>().having(
          (s) => s.queryResults,
          'queryResults',
          allOf(
            containsPair(
              'expenses',
              isA<List>().having((l) => l.length, 'length', 1),
            ),
            containsPair(
              'total',
              isA<List>().having(
                (l) => l.first['total_amount'],
                'total_amount',
                50.0,
              ),
            ),
          ),
        ),
      ],
    );

    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'screen change re-subscribes with new screen queries',
      setUp: () async {
        await SchemaManager(db: db).installModule(_budgetModule());
        await db.customStatement(
          'INSERT INTO "m_budget_expenses" (id, amount, description, category, created_at, updated_at) '
          "VALUES ('e1', 50.0, 'Coffee', 'Food', 1000, 1000)",
        );
        await db.customStatement(
          'INSERT INTO "m_budget_expenses" (id, amount, description, category, created_at, updated_at) '
          "VALUES ('e2', 30.0, 'Bus', 'Transport', 2000, 2000)",
        );
        when(() => moduleRepo.getModule('user1', 'budget-001'))
            .thenAnswer((_) async => _budgetModule());
      },
      build: () => ModuleViewerBloc(
        moduleRepository: moduleRepo,
        entryRepository: entryRepo,
        appDatabase: db,
        userId: 'user1',
      ),
      act: (bloc) async {
        bloc.add(const ModuleViewerStarted('budget-001'));
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(const ModuleViewerScreenChanged('by_category'));
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<ModuleViewerLoading>(),
        // Initial loaded (empty queryResults)
        isA<ModuleViewerLoaded>()
            .having((s) => s.queryResults, 'queryResults', isEmpty),
        // Main screen queryResults
        isA<ModuleViewerLoaded>().having(
          (s) => s.queryResults.containsKey('expenses'),
          'has expenses',
          true,
        ),
        // Screen changed to by_category
        isA<ModuleViewerLoaded>().having(
          (s) => s.currentScreenId,
          'screenId',
          'by_category',
        ),
        // by_category queryResults (default category=Food → 1 result)
        isA<ModuleViewerLoaded>().having(
          (s) => s.queryResults['filtered']?.length,
          'filtered count',
          1,
        ),
      ],
    );

    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'screen param change re-subscribes with new filter params',
      setUp: () async {
        await SchemaManager(db: db).installModule(_budgetModule());
        await db.customStatement(
          'INSERT INTO "m_budget_expenses" (id, amount, description, category, created_at, updated_at) '
          "VALUES ('e1', 50.0, 'Coffee', 'Food', 1000, 1000)",
        );
        await db.customStatement(
          'INSERT INTO "m_budget_expenses" (id, amount, description, category, created_at, updated_at) '
          "VALUES ('e2', 30.0, 'Bus', 'Transport', 2000, 2000)",
        );
        when(() => moduleRepo.getModule('user1', 'budget-001'))
            .thenAnswer((_) async => _budgetModule());
      },
      build: () => ModuleViewerBloc(
        moduleRepository: moduleRepo,
        entryRepository: entryRepo,
        appDatabase: db,
        userId: 'user1',
      ),
      act: (bloc) async {
        bloc.add(const ModuleViewerStarted('budget-001'));
        await Future.delayed(const Duration(milliseconds: 100));
        // Navigate to by_category screen (defaults to Food)
        bloc.add(const ModuleViewerScreenChanged('by_category'));
        await Future.delayed(const Duration(milliseconds: 100));
        // Change filter to Transport
        bloc.add(const ModuleViewerScreenParamChanged('category', 'Transport'));
        await Future.delayed(const Duration(milliseconds: 100));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        final state = bloc.state as ModuleViewerLoaded;
        // After changing to Transport, should have 1 result (Bus)
        expect(state.queryResults['filtered'], hasLength(1));
        expect(state.queryResults['filtered']![0]['description'], 'Bus');
      },
    );

    blocTest<ModuleViewerBloc, ModuleViewerState>(
      'non-SQL module ignores SQL path entirely',
      setUp: () {
        when(() => moduleRepo.getModule('user1', 'simple-001'))
            .thenAnswer((_) async => _nonSqlModule());
        when(() => entryRepo.watchEntries('user1', 'simple-001', limit: 500))
            .thenAnswer((_) => Stream.value(const <Entry>[]));
      },
      build: () => ModuleViewerBloc(
        moduleRepository: moduleRepo,
        entryRepository: entryRepo,
        appDatabase: db,
        userId: 'user1',
      ),
      act: (bloc) => bloc.add(const ModuleViewerStarted('simple-001')),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        final state = bloc.state as ModuleViewerLoaded;
        // Uses entry repo path, not SQL
        expect(state.queryResults, isEmpty);
        expect(state.entries, isEmpty);
        verify(() => entryRepo.watchEntries('user1', 'simple-001', limit: 500))
            .called(1);
      },
    );
  });
}
