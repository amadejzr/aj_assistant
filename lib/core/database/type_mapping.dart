import 'dart:convert';

import '../../features/modules/models/field_type.dart';

/// Maps [FieldType] values to SQLite column types and handles
/// Dart ↔ SQL value conversions.
class TypeMapping {
  TypeMapping._();

  /// Returns the SQLite column type for a [FieldType].
  static String sqlType(FieldType type) => switch (type) {
        FieldType.text ||
        FieldType.url ||
        FieldType.phone ||
        FieldType.email =>
          'TEXT',
        FieldType.number ||
        FieldType.currency ||
        FieldType.duration ||
        FieldType.rating =>
          'REAL',
        FieldType.datetime => 'INTEGER',
        FieldType.boolean => 'INTEGER',
        FieldType.enumType => 'TEXT',
        FieldType.reference => 'TEXT',
        FieldType.image ||
        FieldType.location ||
        FieldType.list ||
        FieldType.multiEnum =>
          'TEXT',
      };

  /// Converts a Dart value to its SQL representation.
  static Object? toSqlValue(FieldType type, Object? value) {
    if (value == null) return null;

    return switch (type) {
      FieldType.datetime => _toEpochMillis(value),
      FieldType.boolean => value == true ? 1 : 0,
      FieldType.list || FieldType.multiEnum => jsonEncode(value),
      _ => value,
    };
  }

  /// Converts a SQL value back to its Dart representation.
  static Object? fromSqlValue(FieldType type, Object? value) {
    if (value == null) return null;

    return switch (type) {
      FieldType.datetime => DateTime.fromMillisecondsSinceEpoch(
          value as int,
          isUtc: true,
        ).toIso8601String(),
      FieldType.boolean => value == 1,
      FieldType.list || FieldType.multiEnum => jsonDecode(value as String),
      _ => value,
    };
  }

  static int _toEpochMillis(Object value) {
    if (value is int) return value;
    if (value is String) return DateTime.parse(value).millisecondsSinceEpoch;
    throw ArgumentError('Cannot convert $value to epoch milliseconds');
  }
}
