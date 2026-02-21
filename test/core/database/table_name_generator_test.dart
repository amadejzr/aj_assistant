import 'package:aj_assistant/core/database/table_name_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TableNameGenerator', () {
    group('moduleTable', () {
      test('generates expected format: m_{name}_{first8ofId}', () {
        expect(
          TableNameGenerator.moduleTable('abc123de-f456', 'Expense Tracker'),
          'm_expense_tracker_abc123de',
        );
      });

      test('lowercases the name', () {
        final result = TableNameGenerator.moduleTable('aaa11111', 'MY MODULE');
        expect(result, 'm_my_module_aaa11111');
      });

      test('replaces spaces with underscores', () {
        final result =
            TableNameGenerator.moduleTable('aaa11111', 'Habit Tracker');
        expect(result, 'm_habit_tracker_aaa11111');
      });

      test('strips special characters', () {
        final result =
            TableNameGenerator.moduleTable('aaa11111', 'My Module!@#\$%');
        expect(result, 'm_my_module_aaa11111');
      });

      test('strips emojis', () {
        final result =
            TableNameGenerator.moduleTable('aaa11111', 'Fitness 💪 Log');
        expect(result, 'm_fitness_log_aaa11111');
      });

      test('collapses multiple underscores', () {
        final result =
            TableNameGenerator.moduleTable('aaa11111', 'A   ---  B');
        expect(result, 'm_a_b_aaa11111');
      });

      test('trims leading/trailing underscores from name', () {
        final result =
            TableNameGenerator.moduleTable('aaa11111', '  !!Hello!!  ');
        expect(result, 'm_hello_aaa11111');
      });

      test('uses first 8 chars of id', () {
        final result = TableNameGenerator.moduleTable(
          'abcdefghijklmnop',
          'Test',
        );
        expect(result, 'm_test_abcdefgh');
      });

      test('handles short id (under 8 chars)', () {
        final result = TableNameGenerator.moduleTable('ab', 'Test');
        expect(result, 'm_test_ab');
      });

      test('strips hyphens from id', () {
        final result =
            TableNameGenerator.moduleTable('abc123-def', 'Expense Tracker');
        expect(result, 'm_expense_tracker_abc123de');
      });

      test('is deterministic — same input same output', () {
        final a = TableNameGenerator.moduleTable('abc', 'My Module');
        final b = TableNameGenerator.moduleTable('abc', 'My Module');
        expect(a, b);
      });
    });

    group('columnName', () {
      test('lowercases and replaces spaces', () {
        expect(TableNameGenerator.columnName('My Field'), 'my_field');
      });

      test('strips special characters', () {
        expect(TableNameGenerator.columnName('My Field!'), 'my_field');
      });

      test('handles already-clean names', () {
        expect(TableNameGenerator.columnName('amount'), 'amount');
      });

      test('strips emojis', () {
        expect(TableNameGenerator.columnName('💰 Amount'), 'amount');
      });

      test('collapses multiple underscores', () {
        expect(TableNameGenerator.columnName('a   b'), 'a_b');
      });
    });
  });
}
