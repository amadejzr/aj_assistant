import 'package:aj_assistant/features/schema/models/field_definition.dart';
import 'package:aj_assistant/features/schema/models/field_type.dart';
import 'package:aj_assistant/features/schema/models/module_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModuleSchema', () {
    test('construction defaults: version=1, fields={}, label="", icon=null',
        () {
      const schema = ModuleSchema();
      expect(schema.version, 1);
      expect(schema.fields, isEmpty);
      expect(schema.label, '');
      expect(schema.icon, isNull);
    });

    test('construction with values', () {
      const schema = ModuleSchema(
        version: 2,
        label: 'Expense',
        icon: 'dollar',
        fields: {
          'amount': FieldDefinition(
            key: 'amount',
            type: FieldType.number,
            label: 'Amount',
          ),
        },
      );
      expect(schema.version, 2);
      expect(schema.label, 'Expense');
      expect(schema.icon, 'dollar');
      expect(schema.fields, hasLength(1));
      expect(schema.fields['amount']!.type, FieldType.number);
    });

    test('equality — same fields are equal', () {
      const a = ModuleSchema(label: 'A', icon: 'star');
      const b = ModuleSchema(label: 'A', icon: 'star');
      expect(a, equals(b));
    });

    test('inequality — different labels are not equal', () {
      const a = ModuleSchema(label: 'A');
      const b = ModuleSchema(label: 'B');
      expect(a, isNot(equals(b)));
    });

    test('copyWith — change label, keep everything else', () {
      const original = ModuleSchema(
        version: 2,
        label: 'Old',
        icon: 'star',
        fields: {
          'f': FieldDefinition(
            key: 'f',
            type: FieldType.text,
            label: 'F',
          ),
        },
      );
      final copied = original.copyWith(label: 'New');
      expect(copied.label, 'New');
      expect(copied.version, 2);
      expect(copied.icon, 'star');
      expect(copied.fields, hasLength(1));
    });

    test('copyWith — change fields map, keep label', () {
      const original = ModuleSchema(label: 'Keep');
      final copied = original.copyWith(fields: {
        'x': const FieldDefinition(
          key: 'x',
          type: FieldType.text,
          label: 'X',
        ),
      });
      expect(copied.label, 'Keep');
      expect(copied.fields, hasLength(1));
      expect(copied.fields['x']!.label, 'X');
    });

    test('copyWith — no args returns equal copy', () {
      const original = ModuleSchema(label: 'Same', icon: 'check');
      final copied = original.copyWith();
      expect(copied, equals(original));
    });

    test('toJson / fromJson roundtrip', () {
      const original = ModuleSchema(
        version: 3,
        label: 'Expense',
        icon: 'dollar',
        fields: {
          'amount': FieldDefinition(
            key: 'amount',
            type: FieldType.currency,
            label: 'Amount',
            required: true,
          ),
        },
      );
      final json = original.toJson();
      final restored = ModuleSchema.fromJson(json);
      expect(restored, equals(original));
    });

    test('fromJson backward compat — missing label/icon defaults', () {
      final json = {
        'version': 1,
        'fields': <String, dynamic>{},
      };
      final schema = ModuleSchema.fromJson(json);
      expect(schema.label, '');
      expect(schema.icon, isNull);
    });
  });
}
