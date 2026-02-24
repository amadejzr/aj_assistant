import 'package:bowerlab/core/database/screen_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScreenQuery.fromJson', () {
    test('parses query with sql, params, and defaults', () {
      final query = ScreenQuery.fromJson('recent_expenses', {
        'sql':
            'SELECT * FROM budget_expenses WHERE (:category = \'all\' OR category = :category) ORDER BY created_at DESC LIMIT 20',
        'params': {'category': '{{filters.category}}'},
        'defaults': {'category': 'all'},
      });

      expect(query.name, 'recent_expenses');
      expect(query.sql, contains('SELECT'));
      expect(query.params, {'category': '{{filters.category}}'});
      expect(query.defaults, {'category': 'all'});
    });

    test('parses query with sql only (no params or defaults)', () {
      final query = ScreenQuery.fromJson('total_balance', {
        'sql': 'SELECT SUM(balance) as total FROM budget_accounts',
      });

      expect(query.name, 'total_balance');
      expect(query.sql, 'SELECT SUM(balance) as total FROM budget_accounts');
      expect(query.params, isEmpty);
      expect(query.defaults, isEmpty);
    });
  });

  group('parseScreenQueries', () {
    test('parses multiple queries from screen JSON', () {
      final queries = parseScreenQueries({
        'queries': {
          'recent_expenses': {
            'sql': 'SELECT * FROM expenses ORDER BY created_at DESC',
            'params': {'category': '{{filters.category}}'},
            'defaults': {'category': 'all'},
          },
          'total_balance': {
            'sql': 'SELECT SUM(balance) as total FROM accounts',
          },
        },
      });

      expect(queries, hasLength(2));
      expect(queries.map((q) => q.name).toSet(),
          {'recent_expenses', 'total_balance'});
    });

    test('returns empty list when no queries key', () {
      final queries = parseScreenQueries({'screens': {}});
      expect(queries, isEmpty);
    });
  });

  group('ScreenMutation', () {
    test('parses all three mutations', () {
      final mutations = ScreenMutations.fromJson({
        'create': 'INSERT INTO expenses (id, amount) VALUES (:id, :amount)',
        'update': 'UPDATE expenses SET amount = :amount WHERE id = :id',
        'delete': 'DELETE FROM expenses WHERE id = :id',
      });

      expect(mutations.create, isNotNull);
      expect(mutations.create!.sql,
          'INSERT INTO expenses (id, amount) VALUES (:id, :amount)');
      expect(mutations.update, isNotNull);
      expect(mutations.update!.sql,
          'UPDATE expenses SET amount = :amount WHERE id = :id');
      expect(mutations.delete, isNotNull);
      expect(mutations.delete!.sql,
          'DELETE FROM expenses WHERE id = :id');
    });

    test('parses partial mutations (create + update only)', () {
      final mutations = ScreenMutations.fromJson({
        'create': 'INSERT INTO expenses (id, amount) VALUES (:id, :amount)',
        'update': 'UPDATE expenses SET amount = :amount WHERE id = :id',
      });

      expect(mutations.create, isNotNull);
      expect(mutations.update, isNotNull);
      expect(mutations.delete, isNull);
    });

    test('parses empty mutations', () {
      final mutations = ScreenMutations.fromJson({});

      expect(mutations.create, isNull);
      expect(mutations.update, isNull);
      expect(mutations.delete, isNull);
    });
  });
}
