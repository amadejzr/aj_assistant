import 'dart:convert';

import 'package:aj_assistant/core/ai/tool_executor.dart';
import 'package:aj_assistant/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ToolExecutor executor;

  setUp(() async {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );

    // Create a test table
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS "test_expenses" (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Insert test data
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.customInsert(
      'INSERT INTO "test_expenses" (id, amount, category, note, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
      variables: [
        Variable('e1'),
        Variable(25.50),
        Variable('food'),
        Variable('lunch'),
        Variable(now),
        Variable(now),
      ],
    );
    await db.customInsert(
      'INSERT INTO "test_expenses" (id, amount, category, note, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
      variables: [
        Variable('e2'),
        Variable(100.00),
        Variable('transport'),
        Variable('uber'),
        Variable(now - 1000),
        Variable(now - 1000),
      ],
    );

    executor = ToolExecutor(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ToolExecutor', () {
    test('isReadOnly returns true for queryEntries', () {
      expect(ToolExecutor.isReadOnly('queryEntries'), isTrue);
    });

    test('isReadOnly returns true for getModuleSummary', () {
      expect(ToolExecutor.isReadOnly('getModuleSummary'), isTrue);
    });

    test('isReadOnly returns false for createEntry', () {
      expect(ToolExecutor.isReadOnly('createEntry'), isFalse);
    });

    test('queryEntries returns matching rows', () async {
      final result = await executor.executeReadOnly(
        'queryEntries',
        {'moduleId': 'test', 'tableName': 'test_expenses'},
      );
      final decoded = jsonDecode(result) as Map<String, dynamic>;
      expect(decoded['count'], 2);
    });

    test('queryEntries applies filters', () async {
      final result = await executor.executeReadOnly(
        'queryEntries',
        {
          'moduleId': 'test',
          'tableName': 'test_expenses',
          'filters': [
            {'field': 'category', 'op': '=', 'value': 'food'},
          ],
        },
      );
      final decoded = jsonDecode(result) as Map<String, dynamic>;
      expect(decoded['count'], 1);
      expect(result, contains('lunch'));
    });

    test('queryEntries respects limit', () async {
      final result = await executor.executeReadOnly(
        'queryEntries',
        {'moduleId': 'test', 'tableName': 'test_expenses', 'limit': 1},
      );
      final decoded = jsonDecode(result) as Map<String, dynamic>;
      expect(decoded['count'], 1);
    });

    test('queryEntries returns error for missing table', () async {
      final result = await executor.executeReadOnly(
        'queryEntries',
        {'moduleId': 'test'},
      );
      expect(result, contains('error'));
    });

    test('getModuleSummary returns count and recent entries', () async {
      final result = await executor.executeReadOnly(
        'getModuleSummary',
        {'moduleId': 'test', 'tableName': 'test_expenses'},
      );
      final decoded = jsonDecode(result) as Map<String, dynamic>;
      expect(decoded['totalEntries'], 2);
      expect(decoded['recentEntries'], isList);
      expect((decoded['recentEntries'] as List).length, 2);
    });

    test('unknown tool returns error', () async {
      final result = await executor.executeReadOnly(
        'unknownTool',
        {},
      );
      expect(result, contains('Unknown read-only tool'));
    });
  });
}
