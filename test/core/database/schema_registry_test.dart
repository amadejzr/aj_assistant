import 'package:aj_assistant/core/database/schema_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SchemaRegistry', () {
    late SchemaRegistry registry;

    setUp(() {
      registry = SchemaRegistry();
    });

    test('hasTable returns false for unregistered module', () {
      expect(registry.hasTable('unknown'), false);
    });

    test('register and lookup', () {
      registry.register(
        moduleId: 'mod1',
        tableName: 'm_expenses_abc12345',
        columns: {
          'amount': 'REAL',
          'category': 'TEXT',
          'created_at': 'INTEGER',
        },
      );

      expect(registry.hasTable('mod1'), true);
      expect(registry.getTableName('mod1'), 'm_expenses_abc12345');
      expect(registry.getColumns('mod1'), {
        'amount': 'REAL',
        'category': 'TEXT',
        'created_at': 'INTEGER',
      });
    });

    test('getTableName returns null for unregistered module', () {
      expect(registry.getTableName('unknown'), isNull);
    });

    test('getColumns returns null for unregistered module', () {
      expect(registry.getColumns('unknown'), isNull);
    });

    test('isValidColumn returns true for registered column', () {
      registry.register(
        moduleId: 'mod1',
        tableName: 'm_test_abc12345',
        columns: {'amount': 'REAL', 'notes': 'TEXT'},
      );

      expect(registry.isValidColumn('mod1', 'amount'), true);
      expect(registry.isValidColumn('mod1', 'notes'), true);
    });

    test('isValidColumn returns false for unknown column', () {
      registry.register(
        moduleId: 'mod1',
        tableName: 'm_test_abc12345',
        columns: {'amount': 'REAL'},
      );

      expect(registry.isValidColumn('mod1', 'hacked'), false);
    });

    test('isValidColumn returns false for unregistered module', () {
      expect(registry.isValidColumn('unknown', 'amount'), false);
    });

    test('unregister removes the module', () {
      registry.register(
        moduleId: 'mod1',
        tableName: 'm_test_abc12345',
        columns: {'amount': 'REAL'},
      );

      registry.unregister('mod1');

      expect(registry.hasTable('mod1'), false);
      expect(registry.getTableName('mod1'), isNull);
      expect(registry.getColumns('mod1'), isNull);
    });

    test('unregister is safe for unknown module', () {
      expect(() => registry.unregister('unknown'), returnsNormally);
    });

    test('addColumn adds to existing registration', () {
      registry.register(
        moduleId: 'mod1',
        tableName: 'm_test_abc12345',
        columns: {'amount': 'REAL'},
      );

      registry.addColumn('mod1', 'notes', 'TEXT');

      expect(registry.getColumns('mod1'), {
        'amount': 'REAL',
        'notes': 'TEXT',
      });
      expect(registry.isValidColumn('mod1', 'notes'), true);
    });

    test('registeredModuleIds lists all registered', () {
      registry.register(
        moduleId: 'a',
        tableName: 't_a',
        columns: {},
      );
      registry.register(
        moduleId: 'b',
        tableName: 't_b',
        columns: {},
      );

      expect(registry.registeredModuleIds, containsAll(['a', 'b']));
    });
  });
}
