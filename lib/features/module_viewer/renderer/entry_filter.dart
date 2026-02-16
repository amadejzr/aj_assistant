import '../../../core/models/entry.dart';

/// Unified entry filtering — replaces duplicated inline filter logic.
///
/// Supports two formats (backward compatible):
///   Old: `{"completed": "true"}` → each key-value = equality check
///   New: `[{"field": "amount", "op": ">", "value": 100}]` → condition objects
///
/// Date-relative values (strings starting with `$`):
///   `$today`, `$startOfWeek`, `$startOfMonth`, `$startOfYear`
///
/// Meta keys (`_` prefixed) are extracted separately and not used as entry filters.
class EntryFilter {
  const EntryFilter._();

  /// Filter entries and extract meta keys in one call.
  static ({List<Entry> entries, Map<String, dynamic> meta}) filter(
    List<Entry> entries,
    dynamic filterDef,
    Map<String, dynamic> screenParams,
  ) {
    final meta = <String, dynamic>{};
    final conditions = <_Condition>[];

    if (filterDef is List) {
      // New array-of-objects format
      for (final item in filterDef) {
        if (item is Map<String, dynamic>) {
          final field = item['field'] as String?;
          final op = item['op'] as String? ?? '==';
          final value = item['value'];
          if (field != null) {
            if (field.startsWith('_')) {
              meta[field] = value;
            } else {
              conditions.add(_Condition(field: field, op: op, value: value));
            }
          }
        }
      }
    } else if (filterDef is Map) {
      // Old map format — merge with screenParams for backward compat
      final merged = {
        ...Map<String, dynamic>.from(filterDef),
        ...screenParams,
      };
      for (final entry in merged.entries) {
        if (entry.key.startsWith('_')) {
          meta[entry.key] = entry.value;
        } else {
          conditions.add(
            _Condition(field: entry.key, op: '==', value: entry.value),
          );
        }
      }
    }

    if (conditions.isEmpty) return (entries: entries, meta: meta);

    final filtered = entries.where((entry) {
      for (final c in conditions) {
        if (!_matches(entry.data[c.field], c.op, c.value)) return false;
      }
      return true;
    }).toList();

    return (entries: filtered, meta: meta);
  }

  static bool _matches(dynamic entryValue, String op, dynamic filterValue) {
    final resolved = _resolveValue(filterValue);

    switch (op) {
      case 'is_null':
        return entryValue == null;
      case 'not_null':
        return entryValue != null;
      case '==':
        return _toString(entryValue) == _toString(resolved);
      case '!=':
        return _toString(entryValue) != _toString(resolved);
      case '>':
      case '<':
      case '>=':
      case '<=':
        return _compareNumeric(entryValue, op, resolved);
      default:
        return _toString(entryValue) == _toString(resolved);
    }
  }

  static bool _compareNumeric(
    dynamic entryValue,
    String op,
    dynamic filterValue,
  ) {
    final a = _toNum(entryValue);
    final b = _toNum(filterValue);
    if (a == null || b == null) return false;

    return switch (op) {
      '>' => a > b,
      '<' => a < b,
      '>=' => a >= b,
      '<=' => a <= b,
      _ => false,
    };
  }

  static num? _toNum(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      final date = DateTime.tryParse(value);
      if (date != null) return date.millisecondsSinceEpoch;
      return num.tryParse(value);
    }
    return null;
  }

  static String? _toString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static dynamic _resolveValue(dynamic value) {
    if (value is! String || !value.startsWith(r'$')) return value;

    final now = DateTime.now();
    final resolved = switch (value) {
      r'$today' => DateTime(now.year, now.month, now.day),
      r'$startOfWeek' =>
        DateTime(now.year, now.month, now.day - (now.weekday - 1)),
      r'$startOfMonth' => DateTime(now.year, now.month, 1),
      r'$startOfYear' => DateTime(now.year, 1, 1),
      _ => null,
    };

    if (resolved != null) return resolved.toIso8601String();
    return value;
  }
}

class _Condition {
  final String field;
  final String op;
  final dynamic value;

  const _Condition({required this.field, required this.op, this.value});
}
