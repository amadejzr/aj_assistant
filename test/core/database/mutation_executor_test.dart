import 'package:bowerlab/core/database/app_database.dart';
import 'package:bowerlab/core/database/module_database.dart';
import 'package:bowerlab/core/database/mutation_executor.dart';
import 'package:bowerlab/core/database/query_executor.dart';
import 'package:bowerlab/core/database/schema_manager.dart';
import 'package:bowerlab/core/database/screen_query.dart';
import 'package:bowerlab/core/models/module.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull, QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SchemaManager manager;
  late MutationExecutor mutationExecutor;

  setUp(() async {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    manager = SchemaManager(db: db);
    await manager.installModule(budgetModule());

    mutationExecutor = MutationExecutor(
      db: db,
      moduleTableNames: budgetModule().database!.tableNames.values.toSet(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  // ── Helpers ──

  Future<List<Map<String, dynamic>>> queryRows(String sql) async {
    final rows = await db.customSelect(sql).get();
    return rows.map((r) => r.data).toList();
  }

  Future<Map<String, dynamic>> queryRow(String sql) async {
    final row = await db.customSelect(sql).getSingle();
    return row.data;
  }

  // ── Create ──

  group('create', () {
    final createAccount = ScreenMutation(
      sql:
          'INSERT INTO "m_budget_accounts" (id, name, balance, created_at, updated_at) '
          'VALUES (:id, :name, :balance, :created_at, :updated_at)',
    );

    test('inserts row and returns generated ID', () async {
      final id = await mutationExecutor.create(createAccount, {
        'name': 'Checking',
        'balance': 1000.0,
      });

      expect(id, isNotEmpty);

      final rows =
          await queryRows('SELECT * FROM "m_budget_accounts" WHERE id = \'$id\'');
      expect(rows, hasLength(1));
      expect(rows[0]['name'], 'Checking');
      expect(rows[0]['balance'], 1000.0);
    });

    test('sets created_at and updated_at', () async {
      final before = DateTime.now().millisecondsSinceEpoch;
      final id = await mutationExecutor.create(createAccount, {
        'name': 'Savings',
        'balance': 5000.0,
      });
      final after = DateTime.now().millisecondsSinceEpoch;

      final row = await queryRow(
          'SELECT created_at, updated_at FROM "m_budget_accounts" WHERE id = \'$id\'');
      expect(row['created_at'], greaterThanOrEqualTo(before));
      expect(row['created_at'], lessThanOrEqualTo(after));
      expect(row['updated_at'], row['created_at']);
    });

    test('triggers fire on create', () async {
      // Create an account first
      final accountId = await mutationExecutor.create(createAccount, {
        'name': 'Checking',
        'balance': 1000.0,
      });

      // Create an expense — trigger should deduct from balance
      final createExpense = ScreenMutation(
        sql:
            'INSERT INTO "m_budget_expenses" (id, amount, description, category, account_id, created_at, updated_at) '
            'VALUES (:id, :amount, :description, :category, :account_id, :created_at, :updated_at)',
      );

      await mutationExecutor.create(createExpense, {
        'amount': 250.0,
        'description': 'Groceries',
        'category': 'Food',
        'account_id': accountId,
      });

      final row = await queryRow(
          'SELECT balance FROM "m_budget_accounts" WHERE id = \'$accountId\'');
      expect(row['balance'], 750.0); // 1000 - 250
    });
  });

  // ── Update ──

  group('update', () {
    late String accountId;
    late String expenseId;

    final createAccount = ScreenMutation(
      sql:
          'INSERT INTO "m_budget_accounts" (id, name, balance, created_at, updated_at) '
          'VALUES (:id, :name, :balance, :created_at, :updated_at)',
    );
    final createExpense = ScreenMutation(
      sql:
          'INSERT INTO "m_budget_expenses" (id, amount, description, category, account_id, created_at, updated_at) '
          'VALUES (:id, :amount, :description, :category, :account_id, :created_at, :updated_at)',
    );
    final updateExpense = ScreenMutation(
      sql:
          'UPDATE "m_budget_expenses" SET '
          'amount = COALESCE(:amount, amount), '
          'category = COALESCE(:category, category), '
          'description = COALESCE(:description, description), '
          'updated_at = :updated_at '
          'WHERE id = :id',
    );

    setUp(() async {
      accountId = await mutationExecutor.create(createAccount, {
        'name': 'Checking',
        'balance': 1000.0,
      });
      expenseId = await mutationExecutor.create(createExpense, {
        'amount': 200.0,
        'description': 'Dinner',
        'category': 'Food',
        'account_id': accountId,
      });
    });

    test('modifies row and refreshes updated_at', () async {
      final beforeUpdate = DateTime.now().millisecondsSinceEpoch;
      await mutationExecutor.update(updateExpense, expenseId, {
        'amount': 350.0,
      });

      final row = await queryRow(
          'SELECT amount, updated_at FROM "m_budget_expenses" WHERE id = \'$expenseId\'');
      expect(row['amount'], 350.0);
      expect(row['updated_at'], greaterThanOrEqualTo(beforeUpdate));
    });

    test('COALESCE keeps existing values for null params', () async {
      await mutationExecutor.update(updateExpense, expenseId, {
        'description': 'Fancy Dinner',
        // amount and category not provided — COALESCE keeps originals
      });

      final row = await queryRow(
          'SELECT amount, description, category FROM "m_budget_expenses" WHERE id = \'$expenseId\'');
      expect(row['amount'], 200.0); // unchanged
      expect(row['description'], 'Fancy Dinner'); // updated
      expect(row['category'], 'Food'); // unchanged
    });

    test('triggers fire on update — balance adjusts', () async {
      // Balance is 800 (1000 - 200)
      await mutationExecutor.update(updateExpense, expenseId, {
        'amount': 350.0,
      });

      final row = await queryRow(
          'SELECT balance FROM "m_budget_accounts" WHERE id = \'$accountId\'');
      expect(row['balance'], 650.0); // 1000 - 350
    });
  });

  // ── Delete ──

  group('delete', () {
    late String accountId;
    late String expenseId;

    final createAccount = ScreenMutation(
      sql:
          'INSERT INTO "m_budget_accounts" (id, name, balance, created_at, updated_at) '
          'VALUES (:id, :name, :balance, :created_at, :updated_at)',
    );
    final createExpense = ScreenMutation(
      sql:
          'INSERT INTO "m_budget_expenses" (id, amount, description, category, account_id, created_at, updated_at) '
          'VALUES (:id, :amount, :description, :category, :account_id, :created_at, :updated_at)',
    );
    final deleteExpense = ScreenMutation(
      sql: 'DELETE FROM "m_budget_expenses" WHERE id = :id',
    );

    setUp(() async {
      accountId = await mutationExecutor.create(createAccount, {
        'name': 'Checking',
        'balance': 1000.0,
      });
      expenseId = await mutationExecutor.create(createExpense, {
        'amount': 300.0,
        'description': 'Shoes',
        'category': 'Shopping',
        'account_id': accountId,
      });
    });

    test('removes row', () async {
      await mutationExecutor.delete(deleteExpense, expenseId);

      final rows = await queryRows(
          'SELECT * FROM "m_budget_expenses" WHERE id = \'$expenseId\'');
      expect(rows, isEmpty);
    });

    test('triggers fire on delete — balance refunds', () async {
      // Balance is 700 (1000 - 300)
      await mutationExecutor.delete(deleteExpense, expenseId);

      final row = await queryRow(
          'SELECT balance FROM "m_budget_accounts" WHERE id = \'$accountId\'');
      expect(row['balance'], 1000.0); // refunded
    });

    test('FK violation throws', () async {
      final deleteAccount = ScreenMutation(
        sql: 'DELETE FROM "m_budget_accounts" WHERE id = :id',
      );

      expect(
        () => mutationExecutor.delete(deleteAccount, accountId),
        throwsA(anything),
      );
    });
  });

  // ── Stream integration ──

  group('stream integration', () {
    test('query stream re-emits after mutation', () async {
      final queryExec = QueryExecutor(
        db: db,
        moduleTableNames: budgetModule().database!.tableNames.values.toSet(),
      );

      final query = ScreenQuery(
        name: 'all_accounts',
        sql: 'SELECT name, balance FROM "m_budget_accounts" ORDER BY name',
      );

      final emissions = <List<Map<String, dynamic>>>[];
      final sub = queryExec.watch(query, {}).listen(emissions.add);

      await pumpEventQueue();
      expect(emissions, hasLength(1));
      expect(emissions[0], isEmpty); // no accounts yet

      // Create account via MutationExecutor
      final createAccount = ScreenMutation(
        sql:
            'INSERT INTO "m_budget_accounts" (id, name, balance, created_at, updated_at) '
            'VALUES (:id, :name, :balance, :created_at, :updated_at)',
      );
      await mutationExecutor.create(createAccount, {
        'name': 'Checking',
        'balance': 1000.0,
      });
      await pumpEventQueue();

      expect(emissions, hasLength(2));
      expect(emissions[1], hasLength(1));
      expect(emissions[1][0]['name'], 'Checking');

      await sub.cancel();
    });
  });
}

// ── Shared budget module definition ──

Module budgetModule() => const Module(
      id: 'budget-001',
      name: 'Budget Tracker',
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
