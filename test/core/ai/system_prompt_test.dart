import 'package:flutter_test/flutter_test.dart';
import 'package:aj_assistant/core/ai/system_prompt.dart';
import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/core/database/module_database.dart';

void main() {
  group('buildSystemPrompt', () {
    test('includes base instructions', () {
      final prompt = buildSystemPrompt([]);
      expect(prompt, contains('You are AJ'));
      expect(prompt, contains('personal assistant'));
    });

    test('includes today date', () {
      final prompt = buildSystemPrompt([]);
      expect(prompt, matches(RegExp(r'\d{4}-\d{2}-\d{2}')));
    });

    test('shows no modules message when empty', () {
      final prompt = buildSystemPrompt([]);
      expect(prompt, contains('no modules yet'));
    });

    test('includes module name and description', () {
      final module = Module(
        id: 'expenses',
        name: 'Expense Tracker',
        description: 'Track daily spending',
        database: const ModuleDatabase(
          tableNames: {'default': 'expenses_default'},
          setup: [
            'CREATE TABLE "expenses_default" (id TEXT PRIMARY KEY, amount REAL, category TEXT)',
          ],
        ),
      );
      final prompt = buildSystemPrompt([module]);
      expect(prompt, contains('Expense Tracker'));
      expect(prompt, contains('Track daily spending'));
      expect(prompt, contains('expenses_default'));
      expect(prompt, contains('CREATE TABLE'));
    });

    test('includes rules section', () {
      final prompt = buildSystemPrompt([]);
      expect(prompt, contains('RULES'));
      expect(prompt, contains('ONLY operate on modules'));
    });
  });
}
