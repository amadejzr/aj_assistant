import 'package:aj_assistant/core/database/app_database.dart';
import 'package:aj_assistant/core/database/module_database.dart';
import 'package:aj_assistant/core/database/schema_manager.dart';
import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/features/modules/models/field_definition.dart';
import 'package:aj_assistant/features/modules/models/field_type.dart';
import 'package:aj_assistant/features/modules/models/module_schema.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SchemaManager manager;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    manager = SchemaManager(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  // ── The module definition — exactly what Claude / marketplace would produce ──

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
                  key: 'description',
                  type: FieldType.text,
                  label: 'Description'),
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
            // Accounts table
            '''
            CREATE TABLE IF NOT EXISTS "m_budget_accounts" (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              balance REAL NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
            ''',

            // Expenses table with FK to accounts
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

            // Indices
            'CREATE INDEX IF NOT EXISTS "idx_expenses_account" ON "m_budget_expenses" (account_id)',
            'CREATE INDEX IF NOT EXISTS "idx_expenses_category" ON "m_budget_expenses" (category)',
            'CREATE INDEX IF NOT EXISTS "idx_expenses_date" ON "m_budget_expenses" (date)',

            // Trigger: deduct from account on expense insert
            '''
            CREATE TRIGGER IF NOT EXISTS "trg_expense_deduct"
            AFTER INSERT ON "m_budget_expenses"
            FOR EACH ROW BEGIN
              UPDATE "m_budget_accounts"
              SET balance = balance - NEW.amount
              WHERE id = NEW.account_id;
            END
            ''',

            // Trigger: refund account on expense delete
            '''
            CREATE TRIGGER IF NOT EXISTS "trg_expense_refund"
            AFTER DELETE ON "m_budget_expenses"
            FOR EACH ROW BEGIN
              UPDATE "m_budget_accounts"
              SET balance = balance + OLD.amount
              WHERE id = OLD.account_id;
            END
            ''',

            // Trigger: adjust account on expense amount update
            '''
            CREATE TRIGGER IF NOT EXISTS "trg_expense_update"
            AFTER UPDATE OF amount ON "m_budget_expenses"
            FOR EACH ROW BEGIN
              UPDATE "m_budget_accounts"
              SET balance = balance - (NEW.amount - OLD.amount)
              WHERE id = NEW.account_id;
            END
            ''',

            // Trigger: auto-update updated_at on accounts
            '''
            CREATE TRIGGER IF NOT EXISTS "trg_accounts_updated_at"
            AFTER UPDATE ON "m_budget_accounts"
            FOR EACH ROW BEGIN
              UPDATE "m_budget_accounts"
              SET updated_at = CAST(strftime('%s', 'now') AS INTEGER) * 1000
              WHERE id = NEW.id;
            END
            ''',
          ],
          teardown: [
            'DROP TABLE IF EXISTS "m_budget_expenses"',
            'DROP TABLE IF EXISTS "m_budget_accounts"',
          ],
        ),
      );

  // ── Helpers ──

  Future<bool> tableExists(String name) async {
    final rows = await db.customSelect(
      "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
      variables: [Variable.withString(name)],
    ).get();
    return rows.isNotEmpty;
  }

  // ── Install / uninstall ──

  group('installModule', () {
    test('creates both tables', () async {
      await manager.installModule(budgetModule());

      expect(await tableExists('m_budget_accounts'), true);
      expect(await tableExists('m_budget_expenses'), true);
    });

    test('is idempotent', () async {
      await manager.installModule(budgetModule());
      await expectLater(manager.installModule(budgetModule()), completes);
    });

    test('creates indices', () async {
      await manager.installModule(budgetModule());

      final indices = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='m_budget_expenses'",
      ).get();
      final names = indices.map((r) => r.read<String>('name')).toList();

      expect(names, contains('idx_expenses_account'));
      expect(names, contains('idx_expenses_category'));
      expect(names, contains('idx_expenses_date'));
    });

    test('creates triggers', () async {
      await manager.installModule(budgetModule());

      final triggers = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='trigger'",
      ).get();
      final names = triggers.map((r) => r.read<String>('name')).toSet();

      expect(names, contains('trg_expense_deduct'));
      expect(names, contains('trg_expense_refund'));
      expect(names, contains('trg_expense_update'));
      expect(names, contains('trg_accounts_updated_at'));
    });

    test('tableNameFor resolves schema to table', () {
      final module = budgetModule();
      expect(manager.tableNameFor(module, 'account'), 'm_budget_accounts');
      expect(manager.tableNameFor(module, 'expense'), 'm_budget_expenses');
      expect(manager.tableNameFor(module, 'nope'), isNull);
    });
  });

  group('uninstallModule', () {
    test('drops both tables', () async {
      await manager.installModule(budgetModule());
      await manager.uninstallModule(budgetModule());

      expect(await tableExists('m_budget_accounts'), false);
      expect(await tableExists('m_budget_expenses'), false);
    });

    test('is safe to call twice', () async {
      await manager.installModule(budgetModule());
      await manager.uninstallModule(budgetModule());
      await expectLater(manager.uninstallModule(budgetModule()), completes);
    });
  });

  group('module without database field', () {
    test('installModule is a no-op', () async {
      const module = Module(id: 'x', name: 'X');
      await expectLater(manager.installModule(module), completes);
    });

    test('uninstallModule is a no-op', () async {
      const module = Module(id: 'x', name: 'X');
      await expectLater(manager.uninstallModule(module), completes);
    });
  });

  // ── FK enforcement ──

  group('foreign keys', () {
    test('cannot insert expense with bad account_id', () async {
      await manager.installModule(budgetModule());

      expect(
        () => db.customStatement(
          'INSERT INTO "m_budget_expenses" '
          '(id, amount, description, account_id, created_at, updated_at) '
          "VALUES ('e1', 50.0, 'Coffee', 'ghost', 1000, 1000)",
        ),
        throwsA(anything),
      );
    });

    test('cannot delete account that has expenses (RESTRICT)', () async {
      await manager.installModule(budgetModule());

      await db.customStatement(
        'INSERT INTO "m_budget_accounts" '
        '(id, name, balance, created_at, updated_at) '
        "VALUES ('a1', 'Checking', 1000.0, 1000, 1000)",
      );
      await db.customStatement(
        'INSERT INTO "m_budget_expenses" '
        '(id, amount, description, account_id, created_at, updated_at) '
        "VALUES ('e1', 50.0, 'Coffee', 'a1', 1000, 1000)",
      );

      expect(
        () => db.customStatement(
          'DELETE FROM "m_budget_accounts" WHERE id = \'a1\'',
        ),
        throwsA(anything),
      );
    });

    test('can delete account after expenses are removed', () async {
      await manager.installModule(budgetModule());

      await db.customStatement(
        'INSERT INTO "m_budget_accounts" '
        '(id, name, balance, created_at, updated_at) '
        "VALUES ('a1', 'Checking', 1000.0, 1000, 1000)",
      );
      await db.customStatement(
        'INSERT INTO "m_budget_expenses" '
        '(id, amount, description, account_id, created_at, updated_at) '
        "VALUES ('e1', 50.0, 'Coffee', 'a1', 1000, 1000)",
      );

      await db.customStatement(
        'DELETE FROM "m_budget_expenses" WHERE id = \'e1\'',
      );
      await db.customStatement(
        'DELETE FROM "m_budget_accounts" WHERE id = \'a1\'',
      );

      final rows = await db.customSelect(
        'SELECT * FROM "m_budget_accounts"',
      ).get();
      expect(rows, isEmpty);
    });
  });

  // ── Trigger: auto-deduct balance ──

  group('balance triggers', () {
    setUp(() async {
      await manager.installModule(budgetModule());

      await db.customStatement(
        'INSERT INTO "m_budget_accounts" '
        '(id, name, balance, created_at, updated_at) '
        "VALUES ('a1', 'Checking', 1000.0, 1000, 1000)",
      );
    });

    Future<double> getBalance(String accountId) async {
      final row = await db.customSelect(
        'SELECT balance FROM "m_budget_accounts" WHERE id = ?',
        variables: [Variable.withString(accountId)],
      ).getSingle();
      return row.read<double>('balance');
    }

    test('insert expense deducts from balance', () async {
      await db.customStatement(
        'INSERT INTO "m_budget_expenses" '
        '(id, amount, description, account_id, created_at, updated_at) '
        "VALUES ('e1', 250.0, 'Groceries', 'a1', 1000, 1000)",
      );

      expect(await getBalance('a1'), 750.0);
    });

    test('multiple expenses deduct correctly', () async {
      await db.customStatement(
        'INSERT INTO "m_budget_expenses" '
        '(id, amount, description, account_id, created_at, updated_at) '
        "VALUES ('e1', 100.0, 'Coffee', 'a1', 1000, 1000)",
      );
      await db.customStatement(
        'INSERT INTO "m_budget_expenses" '
        '(id, amount, description, account_id, created_at, updated_at) '
        "VALUES ('e2', 300.0, 'Dinner', 'a1', 2000, 2000)",
      );
      await db.customStatement(
        'INSERT INTO "m_budget_expenses" '
        '(id, amount, description, account_id, created_at, updated_at) '
        "VALUES ('e3', 50.0, 'Bus', 'a1', 3000, 3000)",
      );

      // 1000 - 100 - 300 - 50 = 550
      expect(await getBalance('a1'), 550.0);
    });

    test('delete expense refunds balance', () async {
      await db.customStatement(
        'INSERT INTO "m_budget_expenses" '
        '(id, amount, description, account_id, created_at, updated_at) '
        "VALUES ('e1', 200.0, 'Shoes', 'a1', 1000, 1000)",
      );
      expect(await getBalance('a1'), 800.0);

      await db.customStatement(
        'DELETE FROM "m_budget_expenses" WHERE id = \'e1\'',
      );
      expect(await getBalance('a1'), 1000.0);
    });

    test('update expense amount adjusts difference', () async {
      await db.customStatement(
        'INSERT INTO "m_budget_expenses" '
        '(id, amount, description, account_id, created_at, updated_at) '
        "VALUES ('e1', 200.0, 'Shoes', 'a1', 1000, 1000)",
      );
      expect(await getBalance('a1'), 800.0);

      // Change from 200 to 350 — should deduct 150 more
      await db.customStatement(
        'UPDATE "m_budget_expenses" SET amount = 350.0 WHERE id = \'e1\'',
      );
      expect(await getBalance('a1'), 650.0);
    });

    test('multiple accounts stay independent', () async {
      await db.customStatement(
        'INSERT INTO "m_budget_accounts" '
        '(id, name, balance, created_at, updated_at) '
        "VALUES ('a2', 'Savings', 5000.0, 1000, 1000)",
      );

      await db.customStatement(
        'INSERT INTO "m_budget_expenses" '
        '(id, amount, description, account_id, created_at, updated_at) '
        "VALUES ('e1', 100.0, 'Coffee', 'a1', 1000, 1000)",
      );

      expect(await getBalance('a1'), 900.0);
      expect(await getBalance('a2'), 5000.0); // untouched
    });
  });

  // ── Queries: JOINs, aggregation ──

  group('queries', () {
    setUp(() async {
      await manager.installModule(budgetModule());

      await db.customStatement(
        'INSERT INTO "m_budget_accounts" '
        '(id, name, balance, created_at, updated_at) '
        "VALUES ('a1', 'Checking', 2000.0, 1000, 1000)",
      );
      await db.customStatement(
        'INSERT INTO "m_budget_accounts" '
        '(id, name, balance, created_at, updated_at) '
        "VALUES ('a2', 'Savings', 5000.0, 1000, 1000)",
      );

      await db.customStatement(
        'INSERT INTO "m_budget_expenses" '
        '(id, amount, description, category, account_id, date, created_at, updated_at) '
        "VALUES ('e1', 50.0, 'Coffee', 'Food', 'a1', 1708531200000, 1000, 1000)",
      );
      await db.customStatement(
        'INSERT INTO "m_budget_expenses" '
        '(id, amount, description, category, account_id, date, created_at, updated_at) '
        "VALUES ('e2', 200.0, 'Dinner', 'Food', 'a1', 1708617600000, 2000, 2000)",
      );
      await db.customStatement(
        'INSERT INTO "m_budget_expenses" '
        '(id, amount, description, category, account_id, date, created_at, updated_at) '
        "VALUES ('e3', 30.0, 'Bus', 'Transport', 'a1', 1708704000000, 3000, 3000)",
      );
      await db.customStatement(
        'INSERT INTO "m_budget_expenses" '
        '(id, amount, description, category, account_id, date, created_at, updated_at) '
        "VALUES ('e4', 100.0, 'Gym', 'Health', 'a2', 1708531200000, 4000, 4000)",
      );
    });

    test('JOIN — expenses with account name', () async {
      final rows = await db.customSelect(
        'SELECT e.description, e.amount, a.name AS account_name '
        'FROM "m_budget_expenses" e '
        'JOIN "m_budget_accounts" a ON e.account_id = a.id '
        'ORDER BY e.amount',
      ).get();

      expect(rows, hasLength(4));
      expect(rows[0].read<String>('description'), 'Bus');
      expect(rows[0].read<String>('account_name'), 'Checking');
      expect(rows[3].read<String>('description'), 'Dinner');
    });

    test('SUM per account', () async {
      final rows = await db.customSelect(
        'SELECT a.name, SUM(e.amount) AS total_spent '
        'FROM "m_budget_expenses" e '
        'JOIN "m_budget_accounts" a ON e.account_id = a.id '
        'GROUP BY a.name ORDER BY a.name',
      ).get();

      expect(rows, hasLength(2));
      expect(rows[0].read<String>('name'), 'Checking');
      expect(rows[0].read<double>('total_spent'), 280.0);
      expect(rows[1].read<String>('name'), 'Savings');
      expect(rows[1].read<double>('total_spent'), 100.0);
    });

    test('SUM per category', () async {
      final rows = await db.customSelect(
        'SELECT category, SUM(amount) AS total '
        'FROM "m_budget_expenses" '
        'GROUP BY category ORDER BY total DESC',
      ).get();

      expect(rows, hasLength(3));
      expect(rows[0].read<String>('category'), 'Food');
      expect(rows[0].read<double>('total'), 250.0);
      expect(rows[1].read<String>('category'), 'Health');
      expect(rows[1].read<double>('total'), 100.0);
      expect(rows[2].read<String>('category'), 'Transport');
      expect(rows[2].read<double>('total'), 30.0);
    });

    test('WHERE + ORDER BY + LIMIT — recent Food expenses', () async {
      final rows = await db.customSelect(
        'SELECT description, amount FROM "m_budget_expenses" '
        "WHERE category = 'Food' ORDER BY date DESC LIMIT 1",
      ).get();

      expect(rows, hasLength(1));
      expect(rows.first.read<String>('description'), 'Dinner');
      expect(rows.first.read<double>('amount'), 200.0);
    });

    test('COUNT per category', () async {
      final rows = await db.customSelect(
        'SELECT category, COUNT(*) AS cnt FROM "m_budget_expenses" '
        'GROUP BY category ORDER BY cnt DESC',
      ).get();

      expect(rows[0].read<String>('category'), 'Food');
      expect(rows[0].read<int>('cnt'), 2);
    });

    test('balance matches initial minus sum of expenses', () async {
      final accRow = await db.customSelect(
        'SELECT balance FROM "m_budget_accounts" WHERE id = ?',
        variables: [Variable.withString('a1')],
      ).getSingle();
      final sumRow = await db.customSelect(
        'SELECT SUM(amount) AS total FROM "m_budget_expenses" WHERE account_id = ?',
        variables: [Variable.withString('a1')],
      ).getSingle();

      expect(accRow.read<double>('balance'),
          2000.0 - sumRow.read<double>('total'));
    });
  });
}
