import 'package:aj_assistant/core/database/app_database.dart';
import 'package:aj_assistant/core/database/module_database.dart';
import 'package:aj_assistant/core/database/mutation_executor.dart';
import 'package:aj_assistant/core/database/query_executor.dart';
import 'package:aj_assistant/core/database/schema_manager.dart';
import 'package:aj_assistant/core/database/screen_query.dart';
import 'package:aj_assistant/core/models/module.dart';
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

  group('watch', () {
    test('emits initial result set', () async {
      final query = ScreenQuery(
        name: 'all_expenses',
        sql:
            'SELECT description FROM "m_budget_expenses" ORDER BY created_at',
      );

      final stream = queryExecutor.watch(query, {});
      final first = await stream.first;

      expect(first, hasLength(3));
      expect(first[0]['description'], 'Coffee');
      expect(first[1]['description'], 'Dinner');
      expect(first[2]['description'], 'Bus');
    });

    test('re-emits after INSERT into table', () async {
      final query = ScreenQuery(
        name: 'all_expenses',
        sql:
            'SELECT description FROM "m_budget_expenses" ORDER BY created_at',
      );

      final emissions = <List<Map<String, dynamic>>>[];
      final sub = queryExecutor.watch(query, {}).listen(emissions.add);

      // Wait for initial emission
      await pumpEventQueue();
      expect(emissions, hasLength(1));
      expect(emissions[0], hasLength(3));

      // Insert and notify
      await db.customInsert(
        'INSERT INTO "m_budget_expenses" (id, amount, description, category, account_id, date, created_at, updated_at) '
        "VALUES ('e4', 15.0, 'Snack', 'Food', 'a1', 1708790400000, 4000, 4000)",
        updates: queryExecutor.tableRefs,
      );
      await pumpEventQueue();

      expect(emissions, hasLength(2));
      expect(emissions[1], hasLength(4));
      expect(emissions[1][3]['description'], 'Snack');

      await sub.cancel();
    });

    test('re-emits after DELETE from table', () async {
      final query = ScreenQuery(
        name: 'all_expenses',
        sql:
            'SELECT description FROM "m_budget_expenses" ORDER BY created_at',
      );

      final emissions = <List<Map<String, dynamic>>>[];
      final sub = queryExecutor.watch(query, {}).listen(emissions.add);

      await pumpEventQueue();
      expect(emissions, hasLength(1));

      // Delete and notify
      await db.customUpdate(
        'DELETE FROM "m_budget_expenses" WHERE id = \'e3\'',
        updates: queryExecutor.tableRefs,
        updateKind: UpdateKind.delete,
      );
      await pumpEventQueue();

      expect(emissions, hasLength(2));
      expect(emissions[1], hasLength(2));

      await sub.cancel();
    });

    test('re-emits after UPDATE on table', () async {
      final query = ScreenQuery(
        name: 'all_expenses',
        sql:
            'SELECT description, amount FROM "m_budget_expenses" ORDER BY created_at',
      );

      final emissions = <List<Map<String, dynamic>>>[];
      final sub = queryExecutor.watch(query, {}).listen(emissions.add);

      await pumpEventQueue();
      expect(emissions, hasLength(1));
      expect(emissions[0][0]['amount'], 50.0);

      // Update and notify
      await db.customUpdate(
        'UPDATE "m_budget_expenses" SET amount = 99.0 WHERE id = \'e1\'',
        updates: queryExecutor.tableRefs,
        updateKind: UpdateKind.update,
      );
      await pumpEventQueue();

      expect(emissions, hasLength(2));
      expect(emissions[1][0]['amount'], 99.0);

      await sub.cancel();
    });

    test('trigger side-effects reflected in watched query', () async {
      // Watch accounts balance — trigger updates balance when expense is inserted
      final query = ScreenQuery(
        name: 'account_balance',
        sql: 'SELECT balance FROM "m_budget_accounts" WHERE id = \'a1\'',
      );

      final emissions = <List<Map<String, dynamic>>>[];
      final sub = queryExecutor.watch(query, {}).listen(emissions.add);

      await pumpEventQueue();
      expect(emissions, hasLength(1));
      expect(emissions[0][0]['balance'], 1720.0); // after seed expenses

      // Insert expense — trigger deducts from balance
      // Notify both tables since trigger affects accounts too
      await db.customInsert(
        'INSERT INTO "m_budget_expenses" (id, amount, description, category, account_id, date, created_at, updated_at) '
        "VALUES ('e4', 100.0, 'Gym', 'Health', 'a1', 1708790400000, 4000, 4000)",
        updates: queryExecutor.tableRefs,
      );
      await pumpEventQueue();

      expect(emissions, hasLength(2));
      expect(emissions[1][0]['balance'], 1620.0); // 1720 - 100

      await sub.cancel();
    });
  });

  group('executeAll', () {
    test('returns map with results for each query', () async {
      final queries = [
        const ScreenQuery(
          name: 'accounts',
          sql: 'SELECT name FROM "m_budget_accounts" ORDER BY name',
        ),
        const ScreenQuery(
          name: 'expense_count',
          sql: 'SELECT COUNT(*) as cnt FROM "m_budget_expenses"',
        ),
      ];

      final results = await queryExecutor.executeAll(queries, {});

      expect(results.keys, containsAll(['accounts', 'expense_count']));
      expect(results['accounts'], hasLength(2));
      expect(results['expense_count']![0]['cnt'], 3);
    });
  });

  group('watchAll', () {
    test('emits initial map with all query results', () async {
      final queries = [
        const ScreenQuery(
          name: 'accounts',
          sql: 'SELECT name FROM "m_budget_accounts" ORDER BY name',
        ),
        const ScreenQuery(
          name: 'total_balance',
          sql: 'SELECT SUM(balance) as total FROM "m_budget_accounts"',
        ),
      ];

      final stream = queryExecutor.watchAll(queries, {});
      final first = await stream.first;

      expect(first.results.keys, containsAll(['accounts', 'total_balance']));
      expect(first.results['accounts'], hasLength(2));
      expect(first.results['total_balance']![0]['total'], isNotNull);
    });

    test('re-emits when insert affects a query', () async {
      final queries = [
        const ScreenQuery(
          name: 'expenses',
          sql:
              'SELECT description FROM "m_budget_expenses" ORDER BY created_at',
        ),
        const ScreenQuery(
          name: 'total_balance',
          sql: 'SELECT SUM(balance) as total FROM "m_budget_accounts"',
        ),
      ];

      final emissions = <QueryWatchResult>[];
      final sub = queryExecutor.watchAll(queries, {}).listen(emissions.add);

      await pumpEventQueue();
      expect(emissions, hasLength(1));
      expect(emissions[0].results['expenses'], hasLength(3));

      // Insert expense — affects both queries (expense list + balance via trigger)
      await db.customInsert(
        'INSERT INTO "m_budget_expenses" (id, amount, description, category, account_id, date, created_at, updated_at) '
        "VALUES ('e4', 75.0, 'Taxi', 'Transport', 'a1', 1708790400000, 4000, 4000)",
        updates: queryExecutor.tableRefs,
      );
      await pumpEventQueue();

      // Should have at least one more emission with updated data
      expect(emissions.length, greaterThanOrEqualTo(2));
      final latest = emissions.last;
      expect(latest.results['expenses'], hasLength(4));
      expect(latest.results['expenses']![3]['description'], 'Taxi');

      await sub.cancel();
    });
  });

  // ── Integration: full budget scenario ──

  group('integration — full budget scenario', () {
    late AppDatabase freshDb;
    late QueryExecutor qe;
    late MutationExecutor me;

    setUp(() async {
      freshDb = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      final mgr = SchemaManager(db: freshDb);
      await mgr.installModule(budgetModule());

      final tableNames = budgetModule().database!.tableNames.values.toSet();
      qe = QueryExecutor(db: freshDb, moduleTableNames: tableNames);
      me = MutationExecutor(db: freshDb, moduleTableNames: tableNames);
    });

    tearDown(() async {
      await freshDb.close();
    });

    test('end-to-end: accounts, expenses, filters, triggers, streams',
        () async {
      // 1. Parse screen queries from JSON
      final queries = parseScreenQueries({
        'queries': {
          'accounts': {
            'sql':
                'SELECT id, name, balance FROM "m_budget_accounts" ORDER BY name',
          },
          'recent_expenses': {
            'sql':
                'SELECT e.description, e.amount, e.category, a.name as account_name '
                    'FROM "m_budget_expenses" e '
                    'JOIN "m_budget_accounts" a ON e.account_id = a.id '
                    'WHERE (:category = \'all\' OR e.category = :category) '
                    'ORDER BY e.created_at DESC',
            'params': {'category': '{{filters.category}}'},
            'defaults': {'category': 'all'},
          },
          'total_balance': {
            'sql':
                'SELECT SUM(balance) as total FROM "m_budget_accounts"',
          },
        },
      });
      expect(queries, hasLength(3));

      // 2. Parse mutations from JSON
      final mutations = ScreenMutations.fromJson({
        'create':
            'INSERT INTO "m_budget_expenses" (id, amount, description, category, account_id, created_at, updated_at) '
                'VALUES (:id, :amount, :description, :category, :account_id, :created_at, :updated_at)',
        'update':
            'UPDATE "m_budget_expenses" SET '
                'amount = COALESCE(:amount, amount), '
                'category = COALESCE(:category, category), '
                'description = COALESCE(:description, description), '
                'updated_at = :updated_at '
                'WHERE id = :id',
        'delete': 'DELETE FROM "m_budget_expenses" WHERE id = :id',
      });

      // 3. Start watchAll → verify initial empty results
      final emissions = <QueryWatchResult>[];
      final sub =
          qe.watchAll(queries, {'category': 'all'}).listen(emissions.add);

      await pumpEventQueue();
      expect(emissions, hasLength(1));
      expect(emissions[0].results['accounts'], isEmpty);
      expect(emissions[0].results['recent_expenses'], isEmpty);
      expect(emissions[0].results['total_balance']![0]['total'], isNull); // SUM of 0 rows

      // 4. Create 2 accounts via MutationExecutor
      final createAccount = ScreenMutation(
        sql:
            'INSERT INTO "m_budget_accounts" (id, name, balance, created_at, updated_at) '
            'VALUES (:id, :name, :balance, :created_at, :updated_at)',
      );
      final checkingId = await me.create(createAccount, {
        'name': 'Checking',
        'balance': 2000.0,
      });
      final savingsId = await me.create(createAccount, {
        'name': 'Savings',
        'balance': 5000.0,
      });
      await pumpEventQueue();

      // 5. Verify watchAll emits accounts
      expect(emissions.length, greaterThanOrEqualTo(2));
      var latest = emissions.last.results;
      expect(latest['accounts'], hasLength(2));
      expect(latest['total_balance']![0]['total'], 7000.0);

      // 6. Create 3 expenses (different categories, different accounts)
      final expenseIds = <String>[];
      expenseIds.add(await me.create(mutations.create!, {
        'amount': 50.0,
        'description': 'Coffee',
        'category': 'Food',
        'account_id': checkingId,
      }));
      expenseIds.add(await me.create(mutations.create!, {
        'amount': 200.0,
        'description': 'Dinner',
        'category': 'Food',
        'account_id': checkingId,
      }));
      expenseIds.add(await me.create(mutations.create!, {
        'amount': 30.0,
        'description': 'Bus',
        'category': 'Transport',
        'account_id': savingsId,
      }));
      await pumpEventQueue();

      // 7. Verify triggers: account balances deducted
      latest = emissions.last.results;
      final accounts = latest['accounts']!;
      final checking =
          accounts.firstWhere((a) => a['name'] == 'Checking');
      final savings =
          accounts.firstWhere((a) => a['name'] == 'Savings');
      expect(checking['balance'], 1750.0); // 2000 - 50 - 200
      expect(savings['balance'], 4970.0); // 5000 - 30

      // 8. Verify total_balance query shows correct sum
      expect(latest['total_balance']![0]['total'], 6720.0); // 1750 + 4970

      // 9. Verify all expenses visible with category = 'all'
      expect(latest['recent_expenses'], hasLength(3));

      // 10. Cancel and re-watch with category filter
      await sub.cancel();
      emissions.clear();

      final filteredSub = qe
          .watchAll(queries, {'category': 'Food'})
          .listen(emissions.add);
      await pumpEventQueue();

      expect(emissions, hasLength(1));
      expect(emissions[0].results['recent_expenses'], hasLength(2));
      expect(
        emissions[0].results['recent_expenses']!.every((e) => e['category'] == 'Food'),
        isTrue,
      );

      // 11. Update expense amount → verify balance adjusts
      await me.update(mutations.update!, expenseIds[0], {
        'amount': 100.0, // was 50 → +50 more deducted
      });
      await pumpEventQueue();

      latest = emissions.last.results;
      final updatedChecking =
          latest['accounts']!.firstWhere((a) => a['name'] == 'Checking');
      expect(updatedChecking['balance'], 1700.0); // 1750 - 50

      // 12. Delete expense → verify balance refunds
      await me.delete(mutations.delete!, expenseIds[1]); // 200 Dinner
      await pumpEventQueue();

      latest = emissions.last.results;
      final refundedChecking =
          latest['accounts']!.firstWhere((a) => a['name'] == 'Checking');
      expect(refundedChecking['balance'], 1900.0); // 1700 + 200

      // Only 1 food expense left (the updated Coffee)
      expect(latest['recent_expenses'], hasLength(1));
      expect(latest['recent_expenses']![0]['description'], 'Coffee');

      await filteredSub.cancel();
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
