import 'package:aj_assistant/features/schema/models/field_constraints.dart';
import 'package:aj_assistant/features/schema/models/field_definition.dart';
import 'package:aj_assistant/features/schema/models/field_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FieldDefinition', () {
    test('construction — required fields and defaults', () {
      const field = FieldDefinition(
        key: 'amount',
        type: FieldType.number,
        label: 'Amount',
      );
      expect(field.key, 'amount');
      expect(field.type, FieldType.number);
      expect(field.label, 'Amount');
      expect(field.required, false);
      expect(field.constraints, isA<EmptyConstraints>());
      expect(field.options, isEmpty);
    });

    test('equality — same fields are equal', () {
      const a = FieldDefinition(
        key: 'x',
        type: FieldType.text,
        label: 'X',
      );
      const b = FieldDefinition(
        key: 'x',
        type: FieldType.text,
        label: 'X',
      );
      expect(a, equals(b));
    });

    test('copyWith — change label, keep type and key', () {
      const original = FieldDefinition(
        key: 'amount',
        type: FieldType.number,
        label: 'Old Label',
        required: true,
      );
      final copied = original.copyWith(label: 'New Label');
      expect(copied.label, 'New Label');
      expect(copied.key, 'amount');
      expect(copied.type, FieldType.number);
      expect(copied.required, true);
    });

    test('copyWith — change constraints for enum options', () {
      const original = FieldDefinition(
        key: 'cat',
        type: FieldType.enumType,
        label: 'Category',
        constraints: EnumConstraints(options: ['A', 'B']),
      );
      final copied = original.copyWith(
        constraints: const EnumConstraints(options: ['X', 'Y', 'Z']),
      );
      expect(copied.options, ['X', 'Y', 'Z']);
      expect(copied.key, 'cat');
    });

    test('copyWith — change required flag', () {
      const original = FieldDefinition(
        key: 'f',
        type: FieldType.text,
        label: 'F',
      );
      final copied = original.copyWith(required: true);
      expect(copied.required, true);
      expect(copied.key, 'f');
    });

    test('copyWith — no args returns equal copy', () {
      const original = FieldDefinition(
        key: 'f',
        type: FieldType.text,
        label: 'F',
        required: true,
        constraints: TextConstraints(maxLength: 100),
      );
      final copied = original.copyWith();
      expect(copied, equals(original));
    });

    test('options convenience getter returns enum options', () {
      const field = FieldDefinition(
        key: 'cat',
        type: FieldType.enumType,
        label: 'Category',
        constraints: EnumConstraints(options: ['A', 'B', 'C']),
      );
      expect(field.options, ['A', 'B', 'C']);
    });

    test('options convenience getter returns empty for non-enum', () {
      const field = FieldDefinition(
        key: 'name',
        type: FieldType.text,
        label: 'Name',
      );
      expect(field.options, isEmpty);
    });

    test('toJson / fromJson roundtrip — number with constraints', () {
      const original = FieldDefinition(
        key: 'amount',
        type: FieldType.currency,
        label: 'Amount',
        required: true,
        constraints: CurrencyConstraints(min: 0, max: 10000),
      );
      final json = original.toJson();
      final restored = FieldDefinition.fromJson('amount', json);
      expect(restored, equals(original));
    });

    test('toJson / fromJson roundtrip — enum with options', () {
      const original = FieldDefinition(
        key: 'category',
        type: FieldType.enumType,
        label: 'Category',
        constraints: EnumConstraints(options: ['Food', 'Transport']),
      );
      final json = original.toJson();
      final restored = FieldDefinition.fromJson('category', json);
      expect(restored.options, ['Food', 'Transport']);
      expect(restored, equals(original));
    });

    test('toJson / fromJson roundtrip — reference with constraints', () {
      const original = FieldDefinition(
        key: 'account',
        type: FieldType.reference,
        label: 'Account',
        constraints: ReferenceConstraints(
          targetSchema: 'accounts',
          displayField: 'name',
        ),
      );
      final json = original.toJson();
      final restored = FieldDefinition.fromJson('account', json);
      expect(restored, equals(original));
    });

    test('fromJson — handles missing optional fields', () {
      final json = <String, dynamic>{
        'type': 'text',
      };
      final field = FieldDefinition.fromJson('myKey', json);
      expect(field.key, 'myKey');
      expect(field.label, 'myKey'); // defaults to key
      expect(field.required, false);
      expect(field.constraints, isA<TextConstraints>());
      expect(field.options, isEmpty);
    });

    test('fromJson — backward compat with top-level options', () {
      final json = <String, dynamic>{
        'type': 'enumType',
        'label': 'Status',
        'options': ['active', 'inactive'],
      };
      final field = FieldDefinition.fromJson('status', json);
      expect(field.options, ['active', 'inactive']);
      expect(field.constraints, isA<EnumConstraints>());
    });

    test('fromJson — backward compat with schemaKey in constraints', () {
      final json = <String, dynamic>{
        'type': 'reference',
        'label': 'Account',
        'constraints': {'schemaKey': 'accounts'},
      };
      final field = FieldDefinition.fromJson('account', json);
      final ref = field.constraints as ReferenceConstraints;
      expect(ref.targetSchema, 'accounts');
    });
  });
}
