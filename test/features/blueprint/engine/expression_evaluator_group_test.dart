import 'package:aj_assistant/features/blueprint/engine/expression_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Helper entries ──
  const entries = [
    {'category': 'Food', 'amount': 100},
    {'category': 'Food', 'amount': 200},
    {'category': 'Transport', 'amount': 50},
  ];

  group('evaluateGroup', () {
    test('basic grouping with sum', () {
      const evaluator = ExpressionEvaluator(entries: entries);

      final result = evaluator.evaluateGroup('group(category, sum(amount))');

      expect(result, {
        'Food': 300,
        'Transport': 50,
      });
    });

    test('grouping with count', () {
      const evaluator = ExpressionEvaluator(entries: entries);

      final result = evaluator.evaluateGroup('group(category, count())');

      expect(result, {
        'Food': 2,
        'Transport': 1,
      });
    });

    test('empty entries returns empty map', () {
      const evaluator = ExpressionEvaluator(entries: []);

      final result = evaluator.evaluateGroup('group(category, sum(amount))');

      expect(result, isEmpty);
    });

    test('missing field values group under "Unknown"', () {
      const entriesWithMissing = [
        {'category': 'Food', 'amount': 100},
        {'amount': 75}, // no category
        {'category': 'Food', 'amount': 50},
        {'amount': 25}, // no category
      ];
      const evaluator = ExpressionEvaluator(entries: entriesWithMissing);

      final result = evaluator.evaluateGroup('group(category, sum(amount))');

      expect(result, {
        'Food': 150,
        'Unknown': 100,
      });
    });

    test('returns null for non-group expressions', () {
      const evaluator = ExpressionEvaluator(entries: entries);

      expect(evaluator.evaluateGroup('sum(amount)'), isNull);
      expect(evaluator.evaluateGroup('count()'), isNull);
      expect(evaluator.evaluateGroup('avg(amount)'), isNull);
    });

    test('returns null for empty string', () {
      const evaluator = ExpressionEvaluator(entries: entries);

      final result = evaluator.evaluateGroup('');

      expect(result, isNull);
    });

    test('grouping with avg aggregation', () {
      const evaluator = ExpressionEvaluator(entries: entries);

      final result = evaluator.evaluateGroup('group(category, avg(amount))');

      expect(result, {
        'Food': 150, // (100 + 200) / 2
        'Transport': 50, // 50 / 1
      });
    });

    test('single group collects all entries', () {
      const sameCategory = [
        {'category': 'Food', 'amount': 10},
        {'category': 'Food', 'amount': 20},
        {'category': 'Food', 'amount': 30},
      ];
      const evaluator = ExpressionEvaluator(entries: sameCategory);

      final result = evaluator.evaluateGroup('group(category, sum(amount))');

      expect(result, {'Food': 60});
    });

    test('each unique value gets its own group', () {
      const manyCategories = [
        {'type': 'A', 'value': 1},
        {'type': 'B', 'value': 2},
        {'type': 'C', 'value': 3},
        {'type': 'D', 'value': 4},
      ];
      const evaluator = ExpressionEvaluator(entries: manyCategories);

      final result = evaluator.evaluateGroup('group(type, sum(value))');

      expect(result, {'A': 1, 'B': 2, 'C': 3, 'D': 4});
    });

    test('whitespace in expression is trimmed', () {
      const evaluator = ExpressionEvaluator(entries: entries);

      final result =
          evaluator.evaluateGroup('  group( category , sum(amount) )  ');

      expect(result, {
        'Food': 300,
        'Transport': 50,
      });
    });
  });
}
