import 'package:bowerlab/core/database/param_resolver.dart';
import 'package:bowerlab/core/database/screen_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveQueryParams', () {
    test('resolves {{filters.category}} from screenParams', () {
      final queries = [
        const ScreenQuery(
          name: 'expenses',
          sql: 'SELECT * FROM expenses WHERE category = :category',
          params: {'category': '{{filters.category}}'},
          defaults: {'category': 'all'},
        ),
      ];

      final result = resolveQueryParams(queries, {'category': 'Food'});

      expect(result, {'category': 'Food'});
    });

    test('falls back to query defaults when screenParam missing', () {
      final queries = [
        const ScreenQuery(
          name: 'expenses',
          sql: 'SELECT * FROM expenses WHERE category = :category',
          params: {'category': '{{filters.category}}'},
          defaults: {'category': 'all'},
        ),
      ];

      final result = resolveQueryParams(queries, {});

      expect(result, {'category': 'all'});
    });

    test('handles multiple queries with different params', () {
      final queries = [
        const ScreenQuery(
          name: 'expenses',
          sql: 'SELECT * FROM expenses WHERE category = :category',
          params: {'category': '{{filters.category}}'},
          defaults: {'category': 'all'},
        ),
        const ScreenQuery(
          name: 'accounts',
          sql: 'SELECT * FROM accounts WHERE type = :type',
          params: {'type': '{{filters.type}}'},
          defaults: {'type': 'checking'},
        ),
      ];

      final result = resolveQueryParams(
        queries,
        {'category': 'Food', 'type': 'savings'},
      );

      expect(result, {'category': 'Food', 'type': 'savings'});
    });

    test('handles query with no params (returns empty map)', () {
      final queries = [
        const ScreenQuery(
          name: 'all_expenses',
          sql: 'SELECT * FROM expenses',
        ),
      ];

      final result = resolveQueryParams(queries, {'category': 'Food'});

      expect(result, isEmpty);
    });

    test('ignores unknown expression formats (returns default)', () {
      final queries = [
        const ScreenQuery(
          name: 'expenses',
          sql: 'SELECT * FROM expenses WHERE category = :category',
          params: {'category': '{{unknown.expression}}'},
          defaults: {'category': 'all'},
        ),
      ];

      final result = resolveQueryParams(queries, {'category': 'Food'});

      expect(result, {'category': 'all'});
    });
  });
}
