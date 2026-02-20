import 'package:aj_assistant/core/models/entry.dart';
import 'package:aj_assistant/features/blueprint/engine/post_submit_effect.dart';
import 'package:aj_assistant/features/modules/models/schema_effect.dart';
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
  //  computeDeleteUpdates — adjust_reference inversion
  // ═══════════════════════════════════════════════
  group('computeDeleteUpdates', () {
    group('reverse balance on expense delete (subtract -> add)', () {
      test('restores balance when expense entry is deleted', () {
        // Original expense effect was subtract. On delete, it should add back.
        final result = executor.computeDeleteUpdates(
          effects: const [
            AdjustReferenceEffect(
              referenceField: 'account',
              targetField: 'balance',
              amountField: 'amount',
              operation: 'subtract',
            ),
          ],
          deletedEntryData: {
            'account': 'acc-wallet',
            'amount': 150,
            'category': 'Food',
            'note': 'Groceries',
          },
          entries: [wallet, savings],
        );

        // subtract inverted to add: 1000 + 150 = 1150
        expect(result, {
          'acc-wallet': {'balance': 1150},
        });
      });
    });

    group('reverse balance on income delete (add -> subtract)', () {
      test('removes deposited amount when income entry is deleted', () {
        // Original income effect was add. On delete, it should subtract.
        final result = executor.computeDeleteUpdates(
          effects: const [
            AdjustReferenceEffect(
              referenceField: 'account',
              targetField: 'balance',
              amountField: 'amount',
              operation: 'add',
            ),
          ],
          deletedEntryData: {
            'account': 'acc-savings',
            'amount': 3000,
            'source': 'Salary',
          },
          entries: [wallet, savings],
        );

        // add inverted to subtract: 5000 - 3000 = 2000
        expect(result, {
          'acc-savings': {'balance': 2000},
        });
      });
    });

    group('no effects defined', () {
      test('empty effects list returns empty map', () {
        final result = executor.computeDeleteUpdates(
          effects: const [],
          deletedEntryData: {
            'account': 'acc-wallet',
            'amount': 100,
          },
          entries: [wallet],
        );

        expect(result, isEmpty);
      });
    });

    group('missing referenced entry', () {
      test('skips gracefully when referenced entry does not exist', () {
        final result = executor.computeDeleteUpdates(
          effects: const [
            AdjustReferenceEffect(
              referenceField: 'account',
              targetField: 'balance',
              amountField: 'amount',
              operation: 'subtract',
            ),
          ],
          deletedEntryData: {
            'account': 'nonexistent-id',
            'amount': 100,
          },
          entries: [wallet, savings],
        );

        expect(result, isEmpty);
      });

      test('skips gracefully when reference field is missing from entry data',
          () {
        final result = executor.computeDeleteUpdates(
          effects: const [
            AdjustReferenceEffect(
              referenceField: 'account',
              targetField: 'balance',
              amountField: 'amount',
              operation: 'subtract',
            ),
          ],
          deletedEntryData: {
            'amount': 100,
            // 'account' is missing
          },
          entries: [wallet],
        );

        expect(result, isEmpty);
      });
    });

    group('set_reference effects pass through unchanged', () {
      test('set_reference is not inverted', () {
        final result = executor.computeDeleteUpdates(
          effects: const [
            SetReferenceEffect(
              referenceField: 'goal',
              targetField: 'status',
              value: 'reverted',
            ),
          ],
          deletedEntryData: {
            'goal': 'goal-1',
          },
          entries: [goal],
        );

        expect(result, {
          'goal-1': {'status': 'reverted'},
        });
      });

      test('set_reference with sourceField uses deleted entry data', () {
        final result = executor.computeDeleteUpdates(
          effects: const [
            SetReferenceEffect(
              referenceField: 'goal',
              targetField: 'status',
              sourceField: 'previousStatus',
            ),
          ],
          deletedEntryData: {
            'goal': 'goal-1',
            'previousStatus': 'paused',
          },
          entries: [goal],
        );

        expect(result, {
          'goal-1': {'status': 'paused'},
        });
      });
    });

    group('multiple effects applied correctly', () {
      test('inverts multiple adjust_reference effects on different entries',
          () {
        // Original: transfer from wallet to savings
        // Delete: reverse both — add back to wallet, subtract from savings
        final result = executor.computeDeleteUpdates(
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
          deletedEntryData: {
            'fromAccount': 'acc-wallet',
            'toAccount': 'acc-savings',
            'amount': 500,
          },
          entries: [wallet, savings],
        );

        // subtract inverted to add: 1000 + 500 = 1500
        // add inverted to subtract: 5000 - 500 = 4500
        expect(result, {
          'acc-wallet': {'balance': 1500},
          'acc-savings': {'balance': 4500},
        });
      });

      test('mixes inverted adjust with pass-through set on same entry', () {
        final result = executor.computeDeleteUpdates(
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
              value: 'active',
            ),
          ],
          deletedEntryData: {
            'goal': 'goal-1',
            'contribution': 50,
          },
          entries: [goal],
        );

        // add inverted to subtract: 200 - 50 = 150
        // set_reference passes through unchanged
        expect(result, {
          'goal-1': {
            'saved': 150,
            'status': 'active',
          },
        });
      });

      test('handles literal amount with inversion', () {
        final result = executor.computeDeleteUpdates(
          effects: const [
            AdjustReferenceEffect(
              referenceField: 'program',
              targetField: 'sessionsCompleted',
              amount: 1,
              operation: 'add',
            ),
          ],
          deletedEntryData: {
            'program': 'goal-1',
          },
          entries: [goal],
        );

        // add inverted to subtract: goal has no sessionsCompleted so 0 - 1 = -1
        expect(result, {
          'goal-1': {'sessionsCompleted': -1},
        });
      });

      test('handles decimal amounts with inversion', () {
        final result = executor.computeDeleteUpdates(
          effects: const [
            AdjustReferenceEffect(
              referenceField: 'account',
              targetField: 'balance',
              amountField: 'amount',
              operation: 'subtract',
            ),
          ],
          deletedEntryData: {
            'account': 'acc-wallet',
            'amount': 19.99,
          },
          entries: [wallet],
        );

        // subtract inverted to add: 1000 + 19.99 = 1019.99
        expect(result['acc-wallet']!['balance'], closeTo(1019.99, 0.001));
      });
    });
  });
}
