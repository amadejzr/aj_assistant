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
      'count' => _count(args),
      'sum' => _sum(args),
      'avg' => _avg(args),
      'min' => _min(args),
      'max' => _max(args),
      'streak' => _streak(args.isNotEmpty ? args[0] : 'date'),
      'value' => _value(args.isNotEmpty ? args[0] : ''),
      'subtract' =>
        args.length >= 2 ? _subtract(args[0], args[1]) : null,
      'multiply' =>
        args.length >= 2 ? _multiply(args[0], args[1]) : null,
      'divide' =>
        args.length >= 2 ? _divide(args[0], args[1]) : null,
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

  /// Apply where() and period() filters from args, returning
  /// the filtered entries and the remaining field-name arg (if any).
  ({List<Entry> filtered, String? field}) _applyFilters(List<String> args) {
    var filtered = entries;
    String? field;

    for (final arg in args) {
      if (arg.startsWith('where(')) {
        final inner = arg.substring(6, arg.length - 1).trim();
        final parts = _splitArgs(inner);
        if (parts.length >= 3) {
          final whereField = parts[0].trim();
          final op = parts[1].trim();
          final value = parts[2].trim();
          filtered = filtered.where((e) {
            // schemaKey lives on the Entry object, not inside entry.data
            final v = whereField == 'schemaKey'
                ? e.schemaKey
                : e.data[whereField];
            if (v == null) return false;
            final vStr = v.toString();
            return switch (op) {
              '==' => vStr == value,
              '!=' => vStr != value,
              '>' => (num.tryParse(vStr) ?? 0) > (num.tryParse(value) ?? 0),
              '<' => (num.tryParse(vStr) ?? 0) < (num.tryParse(value) ?? 0),
              '>=' => (num.tryParse(vStr) ?? 0) >= (num.tryParse(value) ?? 0),
              '<=' => (num.tryParse(vStr) ?? 0) <= (num.tryParse(value) ?? 0),
              _ => false,
            };
          }).toList();
        }
      } else if (arg.startsWith('period(')) {
        final period = arg.substring(7, arg.length - 1).trim();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        filtered = filtered.where((e) {
          final dateStr = e.data['date'] as String?;
          if (dateStr == null) return false;
          final date = DateTime.tryParse(dateStr);
          if (date == null) return false;
          final dateOnly = DateTime(date.year, date.month, date.day);
          return switch (period) {
            'today' => dateOnly == today,
            'week' => dateOnly.isAfter(today.subtract(const Duration(days: 7))),
            'month' => date.month == now.month && date.year == now.year,
            'year' => date.year == now.year,
            _ => true,
          };
        }).toList();
      } else if (arg.isNotEmpty) {
        field = arg;
      }
    }

    return (filtered: filtered, field: field);
  }

  num _count(List<String> args) {
    if (args.isEmpty) return entries.length;
    final result = _applyFilters(args);
    return result.filtered.length;
  }

  num? _sum(List<String> args) {
    final result = _applyFilters(args);
    final field = result.field;
    if (field == null || field.isEmpty) return null;
    final values = _numericValuesFrom(result.filtered, field);
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b);
  }

  num? _avg(List<String> args) {
    final result = _applyFilters(args);
    final field = result.field;
    if (field == null || field.isEmpty) return null;
    final values = _numericValuesFrom(result.filtered, field);
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  num? _min(List<String> args) {
    final result = _applyFilters(args);
    final field = result.field;
    if (field == null || field.isEmpty) return null;
    final values = _numericValuesFrom(result.filtered, field);
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a < b ? a : b);
  }

  num? _max(List<String> args) {
    final result = _applyFilters(args);
    final field = result.field;
    if (field == null || field.isEmpty) return null;
    final values = _numericValuesFrom(result.filtered, field);
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

  num? _multiply(String aExpr, String bExpr) {
    final a = _resolveArg(aExpr);
    final b = _resolveArg(bExpr);
    if (a == null || b == null) return null;
    return a * b;
  }

  num? _divide(String aExpr, String bExpr) {
    final a = _resolveArg(aExpr);
    final b = _resolveArg(bExpr);
    if (a == null || b == null || b == 0) return null;
    return a / b;
  }

  num? _percentage(String aExpr, String bExpr) {
    final a = _resolveArg(aExpr);
    final b = _resolveArg(bExpr);
    if (a == null || b == null || b == 0) return null;
    return a / b * 100;
  }

  List<num> _numericValuesFrom(List<Entry> source, String field) {
    return source
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
