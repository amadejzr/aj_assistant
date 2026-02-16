import 'package:aj_assistant/core/models/field_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FieldType', () {
    test('fromString("reference") returns FieldType.reference', () {
      expect(FieldType.fromString('reference'), FieldType.reference);
    });

    test('toJson() for reference returns "reference"', () {
      expect(FieldType.reference.toJson(), 'reference');
    });

    test('fromString round-trip for all types', () {
      for (final type in FieldType.values) {
        final json = type.toJson();
        final restored = FieldType.fromString(json);
        expect(restored, type, reason: 'Failed round-trip for $type');
      }
    });

    test('fromString unknown falls back to text', () {
      expect(FieldType.fromString('nonexistent'), FieldType.text);
    });
  });
}
