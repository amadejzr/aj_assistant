import 'screen_query.dart';

final _filterPattern = RegExp(r'^\{\{filters\.([a-zA-Z_][a-zA-Z0-9_]*)\}\}$');

/// Resolves query param expressions against screen state.
///
/// Given queries with params like {"category": "{{filters.category}}"},
/// looks up "category" in screenParams. Falls back to query.defaults.
Map<String, Object> resolveQueryParams(
  List<ScreenQuery> queries,
  Map<String, dynamic> screenParams,
) {
  final resolved = <String, Object>{};

  for (final query in queries) {
    for (final entry in query.params.entries) {
      final paramName = entry.key;
      final expression = entry.value;

      final match = _filterPattern.firstMatch(expression);
      if (match != null) {
        final filterKey = match.group(1)!;
        final value = screenParams[filterKey];
        if (value != null) {
          resolved[paramName] = value as Object;
          continue;
        }
      }

      // Fall back to query defaults
      final defaultValue = query.defaults[paramName];
      if (defaultValue != null) {
        resolved[paramName] = defaultValue;
      }
    }
  }

  return resolved;
}
