import 'package:aj_assistant/core/models/entry.dart';
import 'package:aj_assistant/features/blueprint/engine/post_submit_effect.dart';
import 'package:aj_assistant/features/schema/models/schema_effect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const executor = PostSubmitEffectExecutor();

  // ── Helper entries ──
  const wallet = Entry(
    id: 'acc-wallet',
    data: {'name': 'Wallet', 'balance': 1000},
    schemaKey: 'account',
  );
  const savings = Entry(
    id: 'acc-savings',
    data: {'name': 'Savings', 'balance': 5000},
    schemaKey: 'account',
  );
  const goal = Entry(
    id: 'goal-1',
    data: {'name': 'Vacation', 'status': 'active', 'saved': 200},
    schemaKey: 'goal',
  );

  // ═══════════════════════════════════════════════
  //  adjust_reference
  // ═══════════════════════════════════════════════
  group('adjust_reference', () {
    const subtractEffect = AdjustReferenceEffect(
      referenceField: 'account',
      targetField: 'balance',
      amountField: 'amount',
      operation: 'subtract',
    );

    const addEffect = AdjustReferenceEffect(
      referenceField: 'account',
      targetField: 'balance',
      amountField: 'amount',
      operation: 'add',
    );

    test('subtracts amount from referenced entry field', () {
      final result = executor.computeUpdates(
        effects: [subtractEffect],
        formData: {'account': 'acc-wallet', 'amount': 150},
        entries: [wallet, savings],
      );

      expect(result, {
        'acc-wallet': {'balance': 850},
      });
    });

    test('adds amount to referenced entry field', () {
      final result = executor.computeUpdates(
        effects: [addEffect],
        formData: {'account': 'acc-savings', 'amount': 300},
        entries: [wallet, savings],
      );

      expect(result, {
        'acc-savings': {'balance': 5300},
      });
    });

    test('handles decimal amounts', () {
      final result = executor.computeUpdates(
        effects: [subtractEffect],
        formData: {'account': 'acc-wallet', 'amount': 19.99},
        entries: [wallet],
      );

      expect(result['acc-wallet']!['balance'], closeTo(980.01, 0.001));
    });

    test('handles string numeric amounts', () {
      final result = executor.computeUpdates(
        effects: [subtractEffect],
        formData: {'account': 'acc-wallet', 'amount': '250'},
        entries: [wallet],
      );

      expect(result, {
        'acc-wallet': {'balance': 750},
      });
    });

    test('handles string numeric balance on entry', () {
      const entryWithStringBalance = Entry(
        id: 'acc-str',
        data: {'balance': '800'},
        schemaKey: 'account',
      );

      final result = executor.computeUpdates(
        effects: [subtractEffect],
        formData: {'account': 'acc-str', 'amount': 100},
        entries: [entryWithStringBalance],
      );

      expect(result, {
        'acc-str': {'balance': 700},
      });
    });

    test('allows balance to go negative', () {
      final result = executor.computeUpdates(
        effects: [subtractEffect],
        formData: {'account': 'acc-wallet', 'amount': 1500},
        entries: [wallet],
      );

      expect(result, {
        'acc-wallet': {'balance': -500},
      });
    });

    test('handles negative amount (refund)', () {
      final result = executor.computeUpdates(
        effects: [subtractEffect],
        formData: {'account': 'acc-wallet', 'amount': -50},
        entries: [wallet],
      );

      // subtract(-50) = +50
      expect(result, {
        'acc-wallet': {'balance': 1050},
      });
    });

    test('creates target field if it does not exist on entry', () {
      const entryNoBalance = Entry(
        id: 'acc-new',
        data: {'name': 'New Account'},
        schemaKey: 'account',
      );

      final result = executor.computeUpdates(
        effects: [addEffect],
        formData: {'account': 'acc-new', 'amount': 100},
        entries: [entryNoBalance],
      );

      // 0 (default) + 100
      expect(result, {
        'acc-new': {'balance': 100},
      });
    });

    // ── Chaining: multiple effects on same entry ──
    test('chains multiple adjustments on the same entry', () {
      const feeEffect = AdjustReferenceEffect(
        referenceField: 'account',
        targetField: 'balance',
        amountField: 'fee',
        operation: 'subtract',
      );

      final result = executor.computeUpdates(
        effects: [subtractEffect, feeEffect],
        formData: {
          'account': 'acc-wallet',
          'amount': 100,
          'fee': 5,
        },
        entries: [wallet],
      );

      // 1000 - 100 - 5 = 895
      expect(result, {
        'acc-wallet': {'balance': 895},
      });
    });

    test('handles effects targeting different entries', () {
      const fromEffect = AdjustReferenceEffect(
        referenceField: 'fromAccount',
        targetField: 'balance',
        amountField: 'amount',
        operation: 'subtract',
      );
      const toEffect = AdjustReferenceEffect(
        referenceField: 'toAccount',
        targetField: 'balance',
        amountField: 'amount',
        operation: 'add',
      );

      final result = executor.computeUpdates(
        effects: [fromEffect, toEffect],
        formData: {
          'fromAccount': 'acc-wallet',
          'toAccount': 'acc-savings',
          'amount': 200,
        },
        entries: [wallet, savings],
      );

      expect(result, {
        'acc-wallet': {'balance': 800},
        'acc-savings': {'balance': 5200},
      });
    });

    // ── Skip conditions ──
    test('skips when referenceField is missing from form', () {
      final result = executor.computeUpdates(
        effects: [subtractEffect],
        formData: {'amount': 100}, // no 'account'
        entries: [wallet],
      );

      expect(result, isEmpty);
    });

    test('skips when reference ID is empty string', () {
      final result = executor.computeUpdates(
        effects: [subtractEffect],
        formData: {'account': '', 'amount': 100},
        entries: [wallet],
      );

      expect(result, isEmpty);
    });

    test('skips when referenced entry does not exist', () {
      final result = executor.computeUpdates(
        effects: [subtractEffect],
        formData: {'account': 'nonexistent', 'amount': 100},
        entries: [wallet],
      );

      expect(result, isEmpty);
    });

    test('skips when amount is null', () {
      final result = executor.computeUpdates(
        effects: [subtractEffect],
        formData: {'account': 'acc-wallet'},
        entries: [wallet],
      );

      expect(result, isEmpty);
    });

    test('skips when amount is non-numeric string', () {
      final result = executor.computeUpdates(
        effects: [subtractEffect],
        formData: {'account': 'acc-wallet', 'amount': 'abc'},
        entries: [wallet],
      );

      expect(result, isEmpty);
    });

    test('skips when operation is invalid', () {
      const invalidOp = AdjustReferenceEffect(
        referenceField: 'account',
        targetField: 'balance',
        amountField: 'amount',
        operation: 'multiply', // not supported
      );

      final result = executor.computeUpdates(
        effects: [invalidOp],
        formData: {'account': 'acc-wallet', 'amount': 100},
        entries: [wallet],
      );

      expect(result, isEmpty);
    });

    test('skips when neither amount nor amountField resolves', () {
      const noAmountEffect = AdjustReferenceEffect(
        referenceField: 'account',
        targetField: 'balance',
        operation: 'subtract',
      );

      final result = executor.computeUpdates(
        effects: [noAmountEffect],
        formData: {'account': 'acc-wallet'},
        entries: [wallet],
      );

      expect(result, isEmpty);
    });

    // ── Literal amount ──
    test('uses literal amount when provided', () {
      const literalEffect = AdjustReferenceEffect(
        referenceField: 'program',
        targetField: 'sessionsCompleted',
        amount: 1,
        operation: 'add',
      );

      final result = executor.computeUpdates(
        effects: [literalEffect],
        formData: {'program': 'goal-1'},
        entries: [goal],
      );

      // goal has no sessionsCompleted → 0 + 1
      expect(result, {
        'goal-1': {'sessionsCompleted': 1},
      });
    });

    test('literal amount takes precedence over amountField', () {
      const bothEffect = AdjustReferenceEffect(
        referenceField: 'account',
        targetField: 'balance',
        amount: 10,
        amountField: 'amount',
        operation: 'subtract',
      );

      final result = executor.computeUpdates(
        effects: [bothEffect],
        formData: {'account': 'acc-wallet', 'amount': 999},
        entries: [wallet],
      );

      // Should use literal 10, not form's 999
      expect(result, {
        'acc-wallet': {'balance': 990},
      });
    });
  });

  // ═══════════════════════════════════════════════
  //  set_reference
  // ═══════════════════════════════════════════════
  group('set_reference', () {
    test('sets field to a literal value', () {
      final result = executor.computeUpdates(
        effects: const [
          SetReferenceEffect(
            referenceField: 'goal',
            targetField: 'status',
            value: 'completed',
          ),
        ],
        formData: {'goal': 'goal-1'},
        entries: [goal],
      );

      expect(result, {
        'goal-1': {'status': 'completed'},
      });
    });

    test('sets field to a numeric literal', () {
      final result = executor.computeUpdates(
        effects: const [
          SetReferenceEffect(
            referenceField: 'goal',
            targetField: 'saved',
            value: 999,
          ),
        ],
        formData: {'goal': 'goal-1'},
        entries: [goal],
      );

      expect(result, {
        'goal-1': {'saved': 999},
      });
    });

    test('sets field to a boolean literal', () {
      final result = executor.computeUpdates(
        effects: const [
          SetReferenceEffect(
            referenceField: 'goal',
            targetField: 'archived',
            value: true,
          ),
        ],
        formData: {'goal': 'goal-1'},
        entries: [goal],
      );

      expect(result, {
        'goal-1': {'archived': true},
      });
    });

    test('copies value from form field via sourceField', () {
      final result = executor.computeUpdates(
        effects: const [
          SetReferenceEffect(
            referenceField: 'goal',
            targetField: 'status',
            sourceField: 'newStatus',
          ),
        ],
        formData: {'goal': 'goal-1', 'newStatus': 'paused'},
        entries: [goal],
      );

      expect(result, {
        'goal-1': {'status': 'paused'},
      });
    });

    test('sourceField overrides value when both present', () {
      final result = executor.computeUpdates(
        effects: const [
          SetReferenceEffect(
            referenceField: 'goal',
            targetField: 'status',
            value: 'completed',
            sourceField: 'newStatus',
          ),
        ],
        formData: {'goal': 'goal-1', 'newStatus': 'cancelled'},
        entries: [goal],
      );

      expect(result, {
        'goal-1': {'status': 'cancelled'},
      });
    });

    test('skips when sourceField value is null in form', () {
      final result = executor.computeUpdates(
        effects: const [
          SetReferenceEffect(
            referenceField: 'goal',
            targetField: 'status',
            sourceField: 'missing',
          ),
        ],
        formData: {'goal': 'goal-1'},
        entries: [goal],
      );

      expect(result, isEmpty);
    });

    test('skips when value is null and no sourceField', () {
      final result = executor.computeUpdates(
        effects: const [
          SetReferenceEffect(
            referenceField: 'goal',
            targetField: 'status',
          ),
        ],
        formData: {'goal': 'goal-1'},
        entries: [goal],
      );

      expect(result, isEmpty);
    });

    test('skips when referenced entry does not exist', () {
      final result = executor.computeUpdates(
        effects: const [
          SetReferenceEffect(
            referenceField: 'goal',
            targetField: 'status',
            value: 'completed',
          ),
        ],
        formData: {'goal': 'nonexistent'},
        entries: [goal],
      );

      expect(result, isEmpty);
    });

    test('skips when referenceField is missing from form', () {
      final result = executor.computeUpdates(
        effects: const [
          SetReferenceEffect(
            referenceField: 'goal',
            targetField: 'status',
            value: 'completed',
          ),
        ],
        formData: {},
        entries: [goal],
      );

      expect(result, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════
  //  Mixed effects & edge cases
  // ═══════════════════════════════════════════════
  group('mixed effects', () {
    test('adjust + set on same entry accumulates correctly', () {
      final result = executor.computeUpdates(
        effects: const [
          AdjustReferenceEffect(
            referenceField: 'goal',
            targetField: 'saved',
            amountField: 'contribution',
            operation: 'add',
          ),
          SetReferenceEffect(
            referenceField: 'goal',
            targetField: 'status',
            value: 'in_progress',
          ),
        ],
        formData: {'goal': 'goal-1', 'contribution': 50},
        entries: [goal],
      );

      expect(result, {
        'goal-1': {
          'saved': 250, // 200 + 50
          'status': 'in_progress',
        },
      });
    });

    test('effects on different entries stay separate', () {
      final result = executor.computeUpdates(
        effects: const [
          AdjustReferenceEffect(
            referenceField: 'account',
            targetField: 'balance',
            amountField: 'amount',
            operation: 'subtract',
          ),
          SetReferenceEffect(
            referenceField: 'goal',
            targetField: 'status',
            value: 'funded',
          ),
        ],
        formData: {
          'account': 'acc-wallet',
          'amount': 100,
          'goal': 'goal-1',
        },
        entries: [wallet, goal],
      );

      expect(result, {
        'acc-wallet': {'balance': 900},
        'goal-1': {'status': 'funded'},
      });
    });
  });

  group('general edge cases', () {
    test('empty effects list returns empty map', () {
      final result = executor.computeUpdates(
        effects: const [],
        formData: {'account': 'acc-wallet', 'amount': 100},
        entries: [wallet],
      );

      expect(result, isEmpty);
    });

    test('unknown effect type is silently skipped', () {
      final result = executor.computeUpdates(
        effects: [
          UnknownEffect(const {'type': 'send_notification', 'message': 'hello'}),
        ],
        formData: {'account': 'acc-wallet'},
        entries: [wallet],
      );

      expect(result, isEmpty);
    });

    test('empty entries list skips all effects gracefully', () {
      final result = executor.computeUpdates(
        effects: const [
          AdjustReferenceEffect(
            referenceField: 'account',
            targetField: 'balance',
            amountField: 'amount',
            operation: 'subtract',
          ),
        ],
        formData: {'account': 'acc-wallet', 'amount': 100},
        entries: [],
      );

      expect(result, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════
  //  Real-world finance scenarios
  // ═══════════════════════════════════════════════
  group('finance scenarios', () {
    test('expense subtracts from wallet', () {
      final result = executor.computeUpdates(
        effects: const [
          AdjustReferenceEffect(
            referenceField: 'account',
            targetField: 'balance',
            amountField: 'amount',
            operation: 'subtract',
          ),
        ],
        formData: {
          'account': 'acc-wallet',
          'amount': 42.50,
          'category': 'Needs',
          'note': 'Groceries',
        },
        entries: [wallet, savings],
      );

      expect(result['acc-wallet']!['balance'], closeTo(957.50, 0.001));
    });

    test('income deposits into savings', () {
      final result = executor.computeUpdates(
        effects: const [
          AdjustReferenceEffect(
            referenceField: 'account',
            targetField: 'balance',
            amountField: 'amount',
            operation: 'add',
          ),
        ],
        formData: {
          'account': 'acc-savings',
          'amount': 3000,
          'source': 'Salary',
        },
        entries: [wallet, savings],
      );

      expect(result, {
        'acc-savings': {'balance': 8000},
      });
    });

    test('transfer between accounts (two effects)', () {
      final result = executor.computeUpdates(
        effects: const [
          AdjustReferenceEffect(
            referenceField: 'fromAccount',
            targetField: 'balance',
            amountField: 'amount',
            operation: 'subtract',
          ),
          AdjustReferenceEffect(
            referenceField: 'toAccount',
            targetField: 'balance',
            amountField: 'amount',
            operation: 'add',
          ),
        ],
        formData: {
          'fromAccount': 'acc-wallet',
          'toAccount': 'acc-savings',
          'amount': 500,
        },
        entries: [wallet, savings],
      );

      expect(result, {
        'acc-wallet': {'balance': 500},
        'acc-savings': {'balance': 5500},
      });
    });

    test('expense without account selected does nothing', () {
      final result = executor.computeUpdates(
        effects: const [
          AdjustReferenceEffect(
            referenceField: 'account',
            targetField: 'balance',
            amountField: 'amount',
            operation: 'subtract',
          ),
        ],
        formData: {
          'amount': 100,
          'category': 'Wants',
          'note': 'Coffee',
        },
        entries: [wallet],
      );

      expect(result, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════
  //  validateEffects
  // ═══════════════════════════════════════════════
  group('validateEffects', () {
    test('returns null when no min guard', () {
      const effect = AdjustReferenceEffect(
        referenceField: 'account',
        targetField: 'balance',
        amountField: 'amount',
        operation: 'subtract',
      );

      final error = executor.validateEffects(
        effects: [effect],
        formData: {'account': 'acc-wallet', 'amount': 9999},
        entries: [wallet],
      );

      expect(error, isNull);
    });

    test('returns error when min guard would be violated', () {
      const effect = AdjustReferenceEffect(
        referenceField: 'account',
        targetField: 'balance',
        amountField: 'amount',
        operation: 'subtract',
        min: 0,
      );

      final error = executor.validateEffects(
        effects: [effect],
        formData: {'account': 'acc-wallet', 'amount': 1500},
        entries: [wallet],
      );

      expect(error, contains('Insufficient'));
    });

    test('returns null when min guard is satisfied', () {
      const effect = AdjustReferenceEffect(
        referenceField: 'account',
        targetField: 'balance',
        amountField: 'amount',
        operation: 'subtract',
        min: 0,
      );

      final error = executor.validateEffects(
        effects: [effect],
        formData: {'account': 'acc-wallet', 'amount': 500},
        entries: [wallet],
      );

      expect(error, isNull);
    });
  });
}
