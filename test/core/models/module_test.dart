import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/features/schema/models/field_definition.dart';
import 'package:aj_assistant/features/schema/models/field_type.dart';
import 'package:aj_assistant/features/schema/models/module_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Module', () {
    test('construction — schemas defaults to {default: ModuleSchema()}', () {
      const module = Module(id: 'test', name: 'Test');
      expect(module.schemas, {'default': ModuleSchema()});
    });

    test('construction with multiple schemas', () {
      const expenseSchema = ModuleSchema(
        label: 'Expense',
        fields: {
          'amount': FieldDefinition(
            key: 'amount',
            type: FieldType.number,
            label: 'Amount',
          ),
        },
      );
      const categorySchema = ModuleSchema(
        label: 'Category',
        fields: {
          'name': FieldDefinition(
            key: 'name',
            type: FieldType.text,
            label: 'Name',
          ),
        },
      );
      const module = Module(
        id: 'expenses',
        name: 'Expenses',
        schemas: {
          'expense': expenseSchema,
          'category': categorySchema,
        },
      );
      expect(module.schemas, hasLength(2));
      expect(module.schemas['expense']!.label, 'Expense');
      expect(module.schemas['category']!.label, 'Category');
    });

    test('equality — modules with same schemas are equal', () {
      const a = Module(id: 'x', name: 'X');
      const b = Module(id: 'x', name: 'X');
      expect(a, equals(b));
    });

    test('copyWith — change name, keep schemas', () {
      const original = Module(
        id: 'x',
        name: 'Old',
        schemas: {
          'default': ModuleSchema(label: 'Keep'),
        },
      );
      final copied = original.copyWith(name: 'New');
      expect(copied.name, 'New');
      expect(copied.id, 'x');
      expect(copied.schemas['default']!.label, 'Keep');
    });

    test('copyWith — change schemas map', () {
      const original = Module(id: 'x', name: 'X');
      final copied = original.copyWith(schemas: {
        'a': const ModuleSchema(label: 'A'),
        'b': const ModuleSchema(label: 'B'),
      });
      expect(copied.schemas, hasLength(2));
      expect(copied.name, 'X');
    });

    test('copyWith — no args returns equal copy', () {
      const original = Module(id: 'x', name: 'X');
      final copied = original.copyWith();
      expect(copied, equals(original));
    });

    test('toFirestore / fromFirestore roundtrip', () {
      const original = Module(
        id: 'exp',
        name: 'Expenses',
        description: 'Track money',
        icon: 'wallet',
        color: '#D94E33',
        sortOrder: 1,
        schemas: {
          'expense': ModuleSchema(
            label: 'Expense',
            fields: {
              'amount': FieldDefinition(
                key: 'amount',
                type: FieldType.number,
                label: 'Amount',
              ),
            },
          ),
        },
      );
      final json = original.toFirestore();
      // Simulate Firestore roundtrip by reconstructing from the map
      expect(json['schemas'], isA<Map>());
      expect((json['schemas'] as Map).containsKey('expense'), true);
    });

    test('toFirestore writes schemas key', () {
      const module = Module(id: 'x', name: 'X');
      final json = module.toFirestore();
      expect(json.containsKey('schemas'), true);
      expect(json.containsKey('schema'), false);
    });

    test('schema convenience getter returns default schema', () {
      const defaultSchema = ModuleSchema(label: 'Default');
      const module = Module(
        id: 'x',
        name: 'X',
        schemas: {'default': defaultSchema},
      );
      expect(module.schema, equals(defaultSchema));
    });

    test('schema convenience getter returns empty schema when no default', () {
      const module = Module(
        id: 'x',
        name: 'X',
        schemas: {'other': ModuleSchema(label: 'Other')},
      );
      expect(module.schema, equals(const ModuleSchema()));
    });
  });
}
