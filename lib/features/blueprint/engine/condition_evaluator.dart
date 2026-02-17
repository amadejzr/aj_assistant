/// Evaluates `visible` and `visibleWhen` conditions on blueprint nodes.
///
/// Single condition:
///   `{"field": "completed", "op": "==", "value": "true"}`
///
/// Multiple conditions (AND):
///   `[{"field": "completed", "op": "==", "value": "true"}, ...]`
///
/// Evaluates against merged screenParams + formValues.
///
/// Supported operators:
///   `==`, `!=`, `>`, `<`, `>=`, `<=`,
///   `is_null`, `not_null`, `isEmpty`, `isNotEmpty`,
///   `in`, `notIn`
class ConditionEvaluator {
  const ConditionEvaluator._();

  /// Returns true if the widget should be visible.
  /// If `visible` is null, defaults to true (always visible).
  static bool evaluate(
    dynamic visible,
    Map<String, dynamic> context,
  ) {
    if (visible == null) return true;

    if (visible is List) {
      // All conditions must pass (AND)
      for (final item in visible) {
        if (item is Map<String, dynamic>) {
          if (!_evaluateSingle(item, context)) return false;
        }
      }
      return true;
    }

    if (visible is Map<String, dynamic>) {
      return _evaluateSingle(visible, context);
    }

    return true;
  }

  static bool _evaluateSingle(
    Map<String, dynamic> condition,
    Map<String, dynamic> context,
  ) {
    final field = condition['field'] as String?;
    if (field == null) return true;

    final op = condition['op'] as String? ?? '==';
    final expected = condition['value'];
    final actual = context[field];

    return switch (op) {
      '==' => _toString(actual) == _toString(expected),
      '!=' => _toString(actual) != _toString(expected),
      'is_null' => actual == null,
      'not_null' => actual != null,
      'isEmpty' => _isEmpty(actual),
      'isNotEmpty' => !_isEmpty(actual),
      'in' => _isIn(actual, expected),
      'notIn' => !_isIn(actual, expected),
      '>' => _compareNum(actual, expected, (a, b) => a > b),
      '<' => _compareNum(actual, expected, (a, b) => a < b),
      '>=' => _compareNum(actual, expected, (a, b) => a >= b),
      '<=' => _compareNum(actual, expected, (a, b) => a <= b),
      _ => _toString(actual) == _toString(expected),
    };
  }

  static bool _isEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.isEmpty;
    if (value is List) return value.isEmpty;
    return false;
  }

  static bool _isIn(dynamic actual, dynamic expected) {
    if (actual == null) return false;
    if (expected is List) {
      return expected.any((e) => _toString(e) == _toString(actual));
    }
    return false;
  }

  static String? _toString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static bool _compareNum(
    dynamic a,
    dynamic b,
    bool Function(num, num) compare,
  ) {
    final na = _toNum(a);
    final nb = _toNum(b);
    if (na == null || nb == null) return false;
    return compare(na, nb);
  }

  static num? _toNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}
