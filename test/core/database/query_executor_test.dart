import 'package:aj_assistant/core/database/app_database.dart';
import 'package:aj_assistant/core/database/module_database.dart';
import 'package:aj_assistant/core/database/query_executor.dart';
import 'package:aj_assistant/core/database/schema_manager.dart';
import 'package:aj_assistant/core/database/screen_query.dart';
import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/features/modules/models/field_definition.dart';
import 'package:aj_assistant/features/modules/models/field_type.dart';
import 'package:aj_assistant/features/modules/models/module_schema.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull, QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SchemaManager manager;
  late QueryExecutor queryExecutor;

  setUp(() async {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    manager = SchemaManager(db: db);
    await manager.installModule(budgetModule());

    queryExecutor = QueryExecutor(
      db: db,
      moduleTableNames: budgetModule().database!.tableNames.values.toSet(),
    );

    // Seed test data
    await db.customStatement(
      'INSERT INTO "m_budget_accounts" (id, name, balance, created_at, updated_at) '
      "VALUES ('a1', 'Checking', 2000.0, 1000, 1000)",
    );
    await db.customStatement(
      'INSERT INTO "m_budget_accounts" (id, name, balance, created_at, updated_at) '
      "VALUES ('a2', 'Savings', 5000.0, 1000, 1000)",
    );
    await db.customStatement(
      'INSERT INTO "m_budget_expenses" (id, amount, description, category, account_id, date, created_at, updated_at) '
      "VALUES ('e1', 50.0, 'Coffee', 'Food', 'a1', 1708531200000, 1000, 1000)",
    );
    await db.customStatement(
      'INSERT INTO "m_budget_expenses" (id, amount, description, category, account_id, date, created_at, updated_at) '
      "VALUES ('e2', 200.0, 'Dinner', 'Food', 'a1', 1708617600000, 2000, 2000)",
    );
    await db.customStatement(
      'INSERT INTO "m_budget_expenses" (id, amount, description, category, account_id, date, created_at, updated_at) '
      "VALUES ('e3', 30.0, 'Bus', 'Transport', 'a1', 1708704000000, 3000, 3000)",
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('execute', () {
    test('simple query returns list of maps', () async {
      final query = ScreenQuery(
        name: 'all_accounts',
        sql: 'SELECT id, name, balance FROM "m_budget_accounts" ORDER BY name',
      );

      final results = await queryExecutor.execute(query, {});

      expect(results, hasLength(2));
      expect(results[0]['name'], 'Checking');
      expect(results[0]['balance'], 1720.0); // 2000 - 50 - 200 - 30 (triggers)
      expect(results[1]['name'], 'Savings');
    });

    test('query with :param filters correctly', () async {
      final query = ScreenQuery(
        name: 'expenses_by_category',
        sql:
            'SELECT description, amount FROM "m_budget_expenses" WHERE category = :category ORDER BY amount',
      );

      final results = await queryExecutor.execute(query, {'category': 'Food'});

      expect(results, hasLength(2));
      expect(results[0]['description'], 'Coffee');
      expect(results[1]['description'], 'Dinner');
    });

    test('same param used twice in SQL — both replaced', () async {
      final query = ScreenQuery(
        name: 'filtered_expenses',
        sql:
            'SELECT * FROM "m_budget_expenses" WHERE (:category = \'all\' OR category = :category)',
        defaults: {'category': 'all'},
      );

      // With default 'all' — matches all rows
      final allResults = await queryExecutor.execute(query, {});
      expect(allResults, hasLength(3));

      // With specific category
      final foodResults =
          await queryExecutor.execute(query, {'category': 'Food'});
      expect(foodResults, hasLength(2));
    });

    test('param defaults used when not in resolvedParams', () async {
      final query = ScreenQuery(
        name: 'with_defaults',
        sql:
            'SELECT * FROM "m_budget_expenses" WHERE (:category = \'all\' OR category = :category)',
        defaults: {'category': 'all'},
      );

      final results = await queryExecutor.execute(query, {});
      expect(results, hasLength(3));
    });

    test('empty result returns empty list', () async {
      final query = ScreenQuery(
        name: 'no_results',
        sql:
            'SELECT * FROM "m_budget_expenses" WHERE category = :category',
      );

      final results =
          await queryExecutor.execute(query, {'category': 'NonExistent'});
      expect(results, isEmpty);
    });

    test('query with JOIN returns joined columns', () async {
      final query = ScreenQuery(
        name: 'expenses_with_account',
        sql:
            'SELECT e.description, e.amount, a.name AS account_name '
            'FROM "m_budget_expenses" e '
            'JOIN "m_budget_accounts" a ON e.account_id = a.id '
            'ORDER BY e.amount',
      );

      final results = await queryExecutor.execute(query, {});

      expect(results, hasLength(3));
      expect(results[0]['description'], 'Bus');
      expect(results[0]['account_name'], 'Checking');
      expect(results[2]['description'], 'Dinner');
      expect(results[2]['amount'], 200.0);
    });
  });
}

// ── Shared budget module definition ──

Module budgetModule() => const Module(
      id: 'budget-001',
      name: 'Budget Tracker',
      schemas: {
        'account': ModuleSchema(
          label: 'Account',
          fields: {
            'name': FieldDefinition(
                key: 'name', type: FieldType.text, label: 'Name'),
            'balance': FieldDefinition(
                key: 'balance', type: FieldType.currency, label: 'Balance'),
          },
        ),
        'expense': ModuleSchema(
          label: 'Expense',
          fields: {
            'amount': FieldDefinition(
                key: 'amount', type: FieldType.currency, label: 'Amount'),
            'description': FieldDefinition(
                key: 'description', type: FieldType.text, label: 'Description'),
            'category': FieldDefinition(
                key: 'category', type: FieldType.text, label: 'Category'),
            'account_id': FieldDefinition(
                key: 'account_id',
                type: FieldType.reference,
                label: 'Account'),
            'date': FieldDefinition(
                key: 'date', type: FieldType.datetime, label: 'Date'),
          },
        ),
      },
      database: ModuleDatabase(
        tableNames: {
          'account': 'm_budget_accounts',
          'expense': 'm_budget_expenses',
        },
        setup: [
          '''
          CREATE TABLE IF NOT EXISTS "m_budget_accounts" (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            balance REAL NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
          ''',
          '''
          CREATE TABLE IF NOT EXISTS "m_budget_expenses" (
            id TEXT PRIMARY KEY,
            amount REAL NOT NULL,
            description TEXT,
            category TEXT,
            account_id TEXT NOT NULL REFERENCES "m_budget_accounts"(id) ON DELETE RESTRICT,
            date INTEGER,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
          ''',
          'CREATE INDEX IF NOT EXISTS "idx_expenses_account" ON "m_budget_expenses" (account_id)',
          'CREATE INDEX IF NOT EXISTS "idx_expenses_category" ON "m_budget_expenses" (category)',
          'CREATE INDEX IF NOT EXISTS "idx_expenses_date" ON "m_budget_expenses" (date)',
          '''
          CREATE TRIGGER IF NOT EXISTS "trg_expense_deduct"
          AFTER INSERT ON "m_budget_expenses"
          FOR EACH ROW BEGIN
            UPDATE "m_budget_accounts"
            SET balance = balance - NEW.amount
            WHERE id = NEW.account_id;
          END
          ''',
          '''
          CREATE TRIGGER IF NOT EXISTS "trg_expense_refund"
          AFTER DELETE ON "m_budget_expenses"
          FOR EACH ROW BEGIN
            UPDATE "m_budget_accounts"
            SET balance = balance + OLD.amount
            WHERE id = OLD.account_id;
          END
          ''',
          '''
          CREATE TRIGGER IF NOT EXISTS "trg_expense_update"
          AFTER UPDATE OF amount ON "m_budget_expenses"
          FOR EACH ROW BEGIN
            UPDATE "m_budget_accounts"
            SET balance = balance - (NEW.amount - OLD.amount)
            WHERE id = NEW.account_id;
          END
          ''',
        ],
        teardown: [
          'DROP TABLE IF EXISTS "m_budget_expenses"',
          'DROP TABLE IF EXISTS "m_budget_accounts"',
        ],
      ),
    );
