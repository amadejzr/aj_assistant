import 'package:aj_assistant/core/models/entry.dart';
import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/features/blueprint/renderer/reference_resolver.dart';
import 'package:aj_assistant/features/schema/models/field_definition.dart';
import 'package:aj_assistant/features/schema/models/field_type.dart';
import 'package:aj_assistant/features/schema/models/module_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testModule = Module(
    id: 'expenses',
    name: 'Finances',
    schemas: {
      'category': ModuleSchema(
        label: 'Category',
        fields: {
          'name': FieldDefinition(
            key: 'name',
            type: FieldType.text,
            label: 'Category Name',
          ),
        },
      ),
      'account': ModuleSchema(
        label: 'Account',
        fields: {
          'title': FieldDefinition(
            key: 'title',
            type: FieldType.text,
            label: 'Account Title',
          ),
          'balance': FieldDefinition(
            key: 'balance',
            type: FieldType.number,
            label: 'Balance',
          ),
        },
      ),
      'expense': ModuleSchema(
        label: 'Expense',
        fields: {
          'note': FieldDefinition(
            key: 'note',
            type: FieldType.text,
            label: 'Note',
          ),
          'category': FieldDefinition(
            key: 'category',
            type: FieldType.reference,
            label: 'Category',
            constraints: {'schemaKey': 'category'},
          ),
          'account': FieldDefinition(
            key: 'account',
            type: FieldType.reference,
            label: 'Account',
            constraints: {'schemaKey': 'account'},
          ),
          'amount': FieldDefinition(
            key: 'amount',
            type: FieldType.number,
            label: 'Amount',
          ),
        },
      ),
    },
  );

  const allEntries = [
    Entry(id: 'cat1', data: {'name': 'Food'}, schemaKey: 'category'),
    Entry(id: 'cat2', data: {'name': 'Transport'}, schemaKey: 'category'),
    Entry(id: 'acc1', data: {'title': 'Checking', 'balance': 1000}, schemaKey: 'account'),
    Entry(id: 'exp1', data: {'note': 'Lunch', 'category': 'cat1', 'amount': 15}, schemaKey: 'expense'),
  ];

  late ReferenceResolver resolver;

  setUp(() {
    resolver = const ReferenceResolver(
      module: testModule,
      allEntries: allEntries,
    );
  });

  group('ReferenceResolver', () {
    test('resolves reference field to display value', () {
      final result = resolver.resolve('category', 'cat1', schemaKey: 'expense');
      expect(result, 'Food');
    });

    test('resolves different reference field', () {
      final result = resolver.resolve('category', 'cat2', schemaKey: 'expense');
      expect(result, 'Transport');
    });

    test('resolves account reference using first text field', () {
      // account schema has no "name" field, so it should find "title" as first text field
      final result = resolver.resolve('account', 'acc1', schemaKey: 'expense');
      expect(result, 'Checking');
    });

    test('returns raw value for non-reference fields', () {
      final result = resolver.resolve('amount', 42, schemaKey: 'expense');
      expect(result, '42');
    });

    test('returns raw value for non-reference field types', () {
      final result = resolver.resolve('note', 'Lunch', schemaKey: 'expense');
      expect(result, 'Lunch');
    });

    test('returns empty string for null value', () {
      final result = resolver.resolve('category', null, schemaKey: 'expense');
      expect(result, '');
    });

    test('returns raw ID when referenced entry not found', () {
      final result = resolver.resolve('category', 'cat_nonexistent', schemaKey: 'expense');
      expect(result, 'cat_nonexistent');
    });

    test('searches all schemas when schemaKey not provided', () {
      // Should still find 'category' field in 'expense' schema
      final result = resolver.resolve('category', 'cat1');
      expect(result, 'Food');
    });

    test('returns raw value when field not found in any schema', () {
      final result = resolver.resolve('nonexistent_field', 'some_value');
      expect(result, 'some_value');
    });

    test('returns raw value when target schema does not exist', () {
      const badModule = Module(
        id: 'test',
        name: 'Test',
        schemas: {
          'default': ModuleSchema(
            fields: {
              'ref': FieldDefinition(
                key: 'ref',
                type: FieldType.reference,
                label: 'Ref',
                constraints: {'schemaKey': 'nonexistent'},
              ),
            },
          ),
        },
      );

      final badResolver = const ReferenceResolver(
        module: badModule,
        allEntries: allEntries,
      );

      final result = badResolver.resolve('ref', 'cat1', schemaKey: 'default');
      expect(result, 'cat1');
    });
  });
}
