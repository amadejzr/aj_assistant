import 'package:aj_assistant/core/database/type_mapping.dart';
import 'package:aj_assistant/features/modules/models/field_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TypeMapping', () {
    group('sqlType', () {
      test('text types map to TEXT', () {
        for (final type in [
          FieldType.text,
          FieldType.url,
          FieldType.phone,
          FieldType.email,
        ]) {
          expect(TypeMapping.sqlType(type), 'TEXT', reason: '$type → TEXT');
        }
      });

      test('numeric types map to REAL', () {
        for (final type in [
          FieldType.number,
          FieldType.currency,
          FieldType.duration,
          FieldType.rating,
        ]) {
          expect(TypeMapping.sqlType(type), 'REAL', reason: '$type → REAL');
        }
      });

      test('datetime maps to INTEGER', () {
        expect(TypeMapping.sqlType(FieldType.datetime), 'INTEGER');
      });

      test('enumType maps to TEXT', () {
        expect(TypeMapping.sqlType(FieldType.enumType), 'TEXT');
      });

      test('boolean maps to INTEGER', () {
        expect(TypeMapping.sqlType(FieldType.boolean), 'INTEGER');
      });

      test('reference maps to TEXT', () {
        expect(TypeMapping.sqlType(FieldType.reference), 'TEXT');
      });

      test('complex types map to TEXT (JSON-encoded)', () {
        for (final type in [
          FieldType.image,
          FieldType.location,
          FieldType.list,
          FieldType.multiEnum,
        ]) {
          expect(TypeMapping.sqlType(type), 'TEXT', reason: '$type → TEXT');
        }
      });

      test('every FieldType has a mapping', () {
        for (final type in FieldType.values) {
          expect(
            () => TypeMapping.sqlType(type),
            returnsNormally,
            reason: '$type should have a SQL type mapping',
          );
        }
      });
    });

    group('toSqlValue', () {
      test('passes through text as-is', () {
        expect(TypeMapping.toSqlValue(FieldType.text, 'hello'), 'hello');
      });

      test('passes through number as-is', () {
        expect(TypeMapping.toSqlValue(FieldType.number, 42.5), 42.5);
      });

      test('converts DateTime to milliseconds since epoch', () {
        final dt = DateTime.utc(2026, 2, 21, 12, 0);
        expect(
          TypeMapping.toSqlValue(FieldType.datetime, dt.toIso8601String()),
          dt.millisecondsSinceEpoch,
        );
      });

      test('passes through epoch int for datetime', () {
        expect(TypeMapping.toSqlValue(FieldType.datetime, 1000), 1000);
      });

      test('converts boolean true to 1', () {
        expect(TypeMapping.toSqlValue(FieldType.boolean, true), 1);
      });

      test('converts boolean false to 0', () {
        expect(TypeMapping.toSqlValue(FieldType.boolean, false), 0);
      });

      test('converts list to JSON string', () {
        expect(
          TypeMapping.toSqlValue(FieldType.list, ['a', 'b']),
          '["a","b"]',
        );
      });

      test('converts multiEnum to JSON string', () {
        expect(
          TypeMapping.toSqlValue(FieldType.multiEnum, ['x', 'y']),
          '["x","y"]',
        );
      });

      test('returns null for null input', () {
        expect(TypeMapping.toSqlValue(FieldType.text, null), isNull);
      });
    });

    group('fromSqlValue', () {
      test('passes through text as-is', () {
        expect(TypeMapping.fromSqlValue(FieldType.text, 'hello'), 'hello');
      });

      test('passes through number as-is', () {
        expect(TypeMapping.fromSqlValue(FieldType.number, 42.5), 42.5);
      });

      test('converts epoch millis to ISO string for datetime', () {
        final dt = DateTime.utc(2026, 2, 21, 12, 0);
        expect(
          TypeMapping.fromSqlValue(FieldType.datetime, dt.millisecondsSinceEpoch),
          dt.toIso8601String(),
        );
      });

      test('converts 1 to true for boolean', () {
        expect(TypeMapping.fromSqlValue(FieldType.boolean, 1), true);
      });

      test('converts 0 to false for boolean', () {
        expect(TypeMapping.fromSqlValue(FieldType.boolean, 0), false);
      });

      test('decodes JSON string to list', () {
        expect(
          TypeMapping.fromSqlValue(FieldType.list, '["a","b"]'),
          ['a', 'b'],
        );
      });

      test('decodes JSON string for multiEnum', () {
        expect(
          TypeMapping.fromSqlValue(FieldType.multiEnum, '["x","y"]'),
          ['x', 'y'],
        );
      });

      test('returns null for null input', () {
        expect(TypeMapping.fromSqlValue(FieldType.text, null), isNull);
      });
    });

    group('round-trip', () {
      test('text round-trips', () {
        const value = 'hello world';
        final sql = TypeMapping.toSqlValue(FieldType.text, value);
        expect(TypeMapping.fromSqlValue(FieldType.text, sql), value);
      });

      test('number round-trips', () {
        const value = 99.9;
        final sql = TypeMapping.toSqlValue(FieldType.number, value);
        expect(TypeMapping.fromSqlValue(FieldType.number, sql), value);
      });

      test('datetime round-trips', () {
        final dt = DateTime.utc(2026, 2, 21, 12, 0);
        final sql = TypeMapping.toSqlValue(FieldType.datetime, dt.toIso8601String());
        expect(TypeMapping.fromSqlValue(FieldType.datetime, sql), dt.toIso8601String());
      });

      test('boolean round-trips', () {
        final sql = TypeMapping.toSqlValue(FieldType.boolean, true);
        expect(TypeMapping.fromSqlValue(FieldType.boolean, sql), true);
      });

      test('list round-trips', () {
        final value = ['a', 'b', 'c'];
        final sql = TypeMapping.toSqlValue(FieldType.list, value);
        expect(TypeMapping.fromSqlValue(FieldType.list, sql), value);
      });
    });
  });
}
