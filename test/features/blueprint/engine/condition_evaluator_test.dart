import 'package:aj_assistant/features/blueprint/engine/condition_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConditionEvaluator', () {
    // ═══════════════════════════════════════════════
    //  isEmpty operator
    // ═══════════════════════════════════════════════
    group('isEmpty', () {
      test('with null value returns true', () {
        final result = ConditionEvaluator.evaluate(
          {'field': 'notes', 'op': 'isEmpty'},
          {'notes': null},
        );

        expect(result, isTrue);
      });

      test('with missing field returns true', () {
        final result = ConditionEvaluator.evaluate(
          {'field': 'notes', 'op': 'isEmpty'},
          {}, // 'notes' not in context at all
        );

        expect(result, isTrue);
      });

      test('with empty string returns true', () {
        final result = ConditionEvaluator.evaluate(
          {'field': 'notes', 'op': 'isEmpty'},
          {'notes': ''},
        );

        expect(result, isTrue);
      });

      test('with empty list returns true', () {
        final result = ConditionEvaluator.evaluate(
          {'field': 'tags', 'op': 'isEmpty'},
          {'tags': []},
        );

        expect(result, isTrue);
      });

      test('with non-empty string returns false', () {
        final result = ConditionEvaluator.evaluate(
          {'field': 'notes', 'op': 'isEmpty'},
          {'notes': 'some text'},
        );

        expect(result, isFalse);
      });

      test('with non-empty list returns false', () {
        final result = ConditionEvaluator.evaluate(
          {'field': 'tags', 'op': 'isEmpty'},
          {'tags': ['urgent']},
        );

        expect(result, isFalse);
      });
    });

    // ═══════════════════════════════════════════════
    //  isNotEmpty operator
    // ═══════════════════════════════════════════════
    group('isNotEmpty', () {
      test('with value returns true', () {
        final result = ConditionEvaluator.evaluate(
          {'field': 'name', 'op': 'isNotEmpty'},
          {'name': 'Alice'},
        );

        expect(result, isTrue);
      });

      test('with null returns false', () {
        final result = ConditionEvaluator.evaluate(
          {'field': 'name', 'op': 'isNotEmpty'},
          {'name': null},
        );

        expect(result, isFalse);
      });

      test('with empty string returns false', () {
        final result = ConditionEvaluator.evaluate(
          {'field': 'name', 'op': 'isNotEmpty'},
          {'name': ''},
        );

        expect(result, isFalse);
      });

      test('with missing field returns false', () {
        final result = ConditionEvaluator.evaluate(
          {'field': 'name', 'op': 'isNotEmpty'},
          {},
        );

        expect(result, isFalse);
      });
    });

    // ═══════════════════════════════════════════════
    //  in operator
    // ═══════════════════════════════════════════════
    group('in', () {
      test('with value in list returns true', () {
        final result = ConditionEvaluator.evaluate(
          {
            'field': 'status',
            'op': 'in',
            'value': ['active', 'pending'],
          },
          {'status': 'active'},
        );

        expect(result, isTrue);
      });

      test('with value not in list returns false', () {
        final result = ConditionEvaluator.evaluate(
          {
            'field': 'status',
            'op': 'in',
            'value': ['active', 'pending'],
          },
          {'status': 'archived'},
        );

        expect(result, isFalse);
      });

      test('with null actual value returns false', () {
        final result = ConditionEvaluator.evaluate(
          {
            'field': 'status',
            'op': 'in',
            'value': ['active', 'pending'],
          },
          {'status': null},
        );

        expect(result, isFalse);
      });

      test('with numeric values in list', () {
        final result = ConditionEvaluator.evaluate(
          {
            'field': 'priority',
            'op': 'in',
            'value': [1, 2, 3],
          },
          {'priority': 2},
        );

        expect(result, isTrue);
      });
    });

    // ═══════════════════════════════════════════════
    //  notIn operator
    // ═══════════════════════════════════════════════
    group('notIn', () {
      test('with value not in list returns true', () {
        final result = ConditionEvaluator.evaluate(
          {
            'field': 'status',
            'op': 'notIn',
            'value': ['deleted', 'archived'],
          },
          {'status': 'active'},
        );

        expect(result, isTrue);
      });

      test('with value in list returns false', () {
        final result = ConditionEvaluator.evaluate(
          {
            'field': 'status',
            'op': 'notIn',
            'value': ['deleted', 'archived'],
          },
          {'status': 'deleted'},
        );

        expect(result, isFalse);
      });

      test('with null actual value returns true (not found in list)', () {
        // _isIn returns false for null, so notIn (which is !_isIn) returns true
        final result = ConditionEvaluator.evaluate(
          {
            'field': 'status',
            'op': 'notIn',
            'value': ['deleted', 'archived'],
          },
          {'status': null},
        );

        expect(result, isTrue);
      });
    });

    // ═══════════════════════════════════════════════
    //  Existing operators still work
    // ═══════════════════════════════════════════════
    group('existing operators', () {
      test('== operator', () {
        expect(
          ConditionEvaluator.evaluate(
            {'field': 'type', 'op': '==', 'value': 'expense'},
            {'type': 'expense'},
          ),
          isTrue,
        );
        expect(
          ConditionEvaluator.evaluate(
            {'field': 'type', 'op': '==', 'value': 'expense'},
            {'type': 'income'},
          ),
          isFalse,
        );
      });

      test('!= operator', () {
        expect(
          ConditionEvaluator.evaluate(
            {'field': 'type', 'op': '!=', 'value': 'expense'},
            {'type': 'income'},
          ),
          isTrue,
        );
        expect(
          ConditionEvaluator.evaluate(
            {'field': 'type', 'op': '!=', 'value': 'expense'},
            {'type': 'expense'},
          ),
          isFalse,
        );
      });

      test('> operator', () {
        expect(
          ConditionEvaluator.evaluate(
            {'field': 'amount', 'op': '>', 'value': 100},
            {'amount': 150},
          ),
          isTrue,
        );
        expect(
          ConditionEvaluator.evaluate(
            {'field': 'amount', 'op': '>', 'value': 100},
            {'amount': 50},
          ),
          isFalse,
        );
      });

      test('< operator', () {
        expect(
          ConditionEvaluator.evaluate(
            {'field': 'amount', 'op': '<', 'value': 100},
            {'amount': 50},
          ),
          isTrue,
        );
        expect(
          ConditionEvaluator.evaluate(
            {'field': 'amount', 'op': '<', 'value': 100},
            {'amount': 150},
          ),
          isFalse,
        );
      });

      test('>= operator', () {
        expect(
          ConditionEvaluator.evaluate(
            {'field': 'amount', 'op': '>=', 'value': 100},
            {'amount': 100},
          ),
          isTrue,
        );
        expect(
          ConditionEvaluator.evaluate(
            {'field': 'amount', 'op': '>=', 'value': 100},
            {'amount': 99},
          ),
          isFalse,
        );
      });

      test('<= operator', () {
        expect(
          ConditionEvaluator.evaluate(
            {'field': 'amount', 'op': '<=', 'value': 100},
            {'amount': 100},
          ),
          isTrue,
        );
        expect(
          ConditionEvaluator.evaluate(
            {'field': 'amount', 'op': '<=', 'value': 100},
            {'amount': 101},
          ),
          isFalse,
        );
      });

      test('is_null operator', () {
        expect(
          ConditionEvaluator.evaluate(
            {'field': 'notes', 'op': 'is_null'},
            {'notes': null},
          ),
          isTrue,
        );
        expect(
          ConditionEvaluator.evaluate(
            {'field': 'notes', 'op': 'is_null'},
            {'notes': 'hello'},
          ),
          isFalse,
        );
      });

      test('not_null operator', () {
        expect(
          ConditionEvaluator.evaluate(
            {'field': 'notes', 'op': 'not_null'},
            {'notes': 'hello'},
          ),
          isTrue,
        );
        expect(
          ConditionEvaluator.evaluate(
            {'field': 'notes', 'op': 'not_null'},
            {'notes': null},
          ),
          isFalse,
        );
      });
    });

    // ═══════════════════════════════════════════════
    //  Multiple conditions (AND)
    // ═══════════════════════════════════════════════
    group('multiple conditions (AND) with new operators', () {
      test('all conditions pass returns true', () {
        final result = ConditionEvaluator.evaluate(
          [
            {'field': 'name', 'op': 'isNotEmpty'},
            {
              'field': 'status',
              'op': 'in',
              'value': ['active', 'pending'],
            },
            {
              'field': 'deleted',
              'op': 'isEmpty',
            },
          ],
          {
            'name': 'Alice',
            'status': 'active',
            'deleted': null,
          },
        );

        expect(result, isTrue);
      });

      test('one condition fails returns false', () {
        final result = ConditionEvaluator.evaluate(
          [
            {'field': 'name', 'op': 'isNotEmpty'},
            {
              'field': 'status',
              'op': 'in',
              'value': ['active', 'pending'],
            },
          ],
          {
            'name': 'Alice',
            'status': 'archived', // not in the list
          },
        );

        expect(result, isFalse);
      });

      test('mixing new and old operators', () {
        final result = ConditionEvaluator.evaluate(
          [
            {'field': 'type', 'op': '==', 'value': 'expense'},
            {'field': 'notes', 'op': 'isNotEmpty'},
            {
              'field': 'category',
              'op': 'notIn',
              'value': ['Hidden', 'Internal'],
            },
          ],
          {
            'type': 'expense',
            'notes': 'Coffee',
            'category': 'Food',
          },
        );

        expect(result, isTrue);
      });
    });

    // ═══════════════════════════════════════════════
    //  Null / default behavior
    // ═══════════════════════════════════════════════
    group('null and default behavior', () {
      test('null visible returns true (always visible)', () {
        final result = ConditionEvaluator.evaluate(null, {'a': 1});

        expect(result, isTrue);
      });

      test('missing field key in condition defaults to true', () {
        // No 'field' key → condition is skipped (returns true)
        final result = ConditionEvaluator.evaluate(
          {'op': '==', 'value': 'test'},
          {'something': 'test'},
        );

        expect(result, isTrue);
      });

      test('missing op defaults to == comparison', () {
        final result = ConditionEvaluator.evaluate(
          {'field': 'status', 'value': 'active'},
          {'status': 'active'},
        );

        expect(result, isTrue);
      });
    });

    // ═══════════════════════════════════════════════
    //  visibleWhen format note
    // ═══════════════════════════════════════════════
    group('visibleWhen format', () {
      // visibleWhen uses the same condition format as visible.
      // The widget registry reads the property name, but the evaluation
      // logic is identical. We verify the evaluate() function works with
      // the same structure that would be passed from either property.
      test('same condition structure works regardless of property name', () {
        final condition = {
          'field': 'type',
          'op': '==',
          'value': 'expense',
        };

        // Both visible and visibleWhen would pass this same map
        expect(
          ConditionEvaluator.evaluate(condition, {'type': 'expense'}),
          isTrue,
        );
        expect(
          ConditionEvaluator.evaluate(condition, {'type': 'income'}),
          isFalse,
        );
      });
    });
  });
}
