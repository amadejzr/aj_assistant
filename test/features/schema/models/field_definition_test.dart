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
      expect(field.constraints, isEmpty);
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

    test('copyWith — change options list', () {
      const original = FieldDefinition(
        key: 'cat',
        type: FieldType.enumType,
        label: 'Category',
        options: ['A', 'B'],
      );
      final copied = original.copyWith(options: ['X', 'Y', 'Z']);
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
        options: ['a'],
        constraints: {'min': 0},
      );
      final copied = original.copyWith();
      expect(copied, equals(original));
    });

    test('toJson / fromJson roundtrip', () {
      const original = FieldDefinition(
        key: 'amount',
        type: FieldType.currency,
        label: 'Amount',
        required: true,
        constraints: {'min': 0, 'max': 10000},
        options: ['USD', 'EUR'],
      );
      final json = original.toJson();
      final restored = FieldDefinition.fromJson('amount', json);
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
      expect(field.constraints, isEmpty);
      expect(field.options, isEmpty);
    });
  });
}
