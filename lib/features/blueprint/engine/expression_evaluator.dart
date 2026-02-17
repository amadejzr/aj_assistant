import '../../../core/models/entry.dart';

/// Evaluates expression strings against entries.
///
/// Syntax: `functionName(args)` — args are field names or nested calls.
///
/// Functions:
///   `count()` — number of entries
///   `sum(field)` — sum of numeric field
///   `avg(field)` — average of numeric field
///   `min(field)` / `max(field)` — min/max value
///   `streak(dateField)` — consecutive days from today
///   `value(key)` — reads from params or settings
///   `subtract(a, b)` — a - b
///   `percentage(a, b)` — a / b * 100
class ExpressionEvaluator {
  final List<Entry> entries;
  final Map<String, dynamic> params;

  const ExpressionEvaluator({
    required this.entries,
    this.params = const {},
  });

  /// Evaluate an expression string. Returns a num or null.
  num? evaluate(String expression) {
    final trimmed = expression.trim();
    if (trimmed.isEmpty) return null;

    try {
      return _eval(trimmed);
    } catch (_) {
      return null;
    }
  }

  num? _eval(String expr) {
    // Find the function name and arguments
    final parenIndex = expr.indexOf('(');
    if (parenIndex == -1) {
      // Bare field name or number literal
      return num.tryParse(expr);
    }

    final funcName = expr.substring(0, parenIndex).trim();
    final argsStr = expr.substring(parenIndex + 1, expr.length - 1).trim();
    final args = _splitArgs(argsStr);

    return switch (funcName) {
      'count' => _count(),
      'sum' => _sum(args.isNotEmpty ? args[0] : ''),
      'avg' => _avg(args.isNotEmpty ? args[0] : ''),
      'min' => _min(args.isNotEmpty ? args[0] : ''),
      'max' => _max(args.isNotEmpty ? args[0] : ''),
      'streak' => _streak(args.isNotEmpty ? args[0] : 'date'),
      'value' => _value(args.isNotEmpty ? args[0] : ''),
      'subtract' =>
        args.length >= 2 ? _subtract(args[0], args[1]) : null,
      'percentage' =>
        args.length >= 2 ? _percentage(args[0], args[1]) : null,
      _ => null,
    };
  }

  /// Split top-level arguments by comma, respecting nested parentheses.
  List<String> _splitArgs(String str) {
    if (str.isEmpty) return [];
    final args = <String>[];
    var depth = 0;
    var start = 0;

    for (var i = 0; i < str.length; i++) {
      switch (str[i]) {
        case '(':
          depth++;
        case ')':
          depth--;
        case ',':
          if (depth == 0) {
            args.add(str.substring(start, i).trim());
            start = i + 1;
          }
      }
    }
    args.add(str.substring(start).trim());
    return args;
  }

  /// Resolve an argument — if it contains `(`, evaluate as sub-expression,
  /// otherwise treat as a literal field name.
  num? _resolveArg(String arg) {
    if (arg.contains('(')) return _eval(arg);
    return num.tryParse(arg);
  }

  num _count() => entries.length;

  num? _sum(String field) {
    if (field.isEmpty) return null;
    final values = _numericValues(field);
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b);
  }

  num? _avg(String field) {
    if (field.isEmpty) return null;
    final values = _numericValues(field);
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  num? _min(String field) {
    if (field.isEmpty) return null;
    final values = _numericValues(field);
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a < b ? a : b);
  }

  num? _max(String field) {
    if (field.isEmpty) return null;
    final values = _numericValues(field);
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a > b ? a : b);
  }

  num _streak(String dateField) {
    if (entries.isEmpty) return 0;

    final dates = entries
        .map((e) => e.data[dateField] as String?)
        .where((d) => d != null)
        .map((d) => DateTime.tryParse(d!))
        .where((d) => d != null)
        .map((d) => DateTime(d!.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) return 0;

    var streak = 0;
    var check = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    for (final date in dates) {
      if (date == check) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else if (date.isBefore(check)) {
        break;
      }
    }
    return streak;
  }

  num? _value(String key) {
    final v = params[key];
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }

  num? _subtract(String aExpr, String bExpr) {
    final a = _resolveArg(aExpr);
    final b = _resolveArg(bExpr);
    if (a == null || b == null) return null;
    return a - b;
  }

  num? _percentage(String aExpr, String bExpr) {
    final a = _resolveArg(aExpr);
    final b = _resolveArg(bExpr);
    if (a == null || b == null || b == 0) return null;
    return a / b * 100;
  }

  List<num> _numericValues(String field) {
    return entries
        .map((e) {
          final v = e.data[field];
          if (v is num) return v;
          if (v is String) return num.tryParse(v);
          return null;
        })
        .where((v) => v != null)
        .cast<num>()
        .toList();
  }
}
