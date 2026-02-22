import 'screen_query.dart';

final _filterPattern = RegExp(r'^\{\{filters\.([a-zA-Z_][a-zA-Z0-9_]*)\}\}$');
final _templatePattern = RegExp(r'^\{\{([a-zA-Z_][a-zA-Z0-9_]*)\}\}$');
final _reactivePattern = RegExp(r'^\$([a-zA-Z_][a-zA-Z0-9_]*)$');

/// Resolves query param expressions against screen state.
///
/// Three param syntaxes are supported:
///   `:paramName`    — SQL binding only (handled by QueryExecutor/MutationExecutor)
///   `{{fieldName}}` — template strings resolved from screenParams
///   `$componentId`  — reactive bindings resolved from formValues (live component state)
///
/// Given queries with params like {"category": "{{filters.category}}"},
/// looks up "category" in screenParams. Falls back to query.defaults.
///
/// When [formValues] is provided, `$componentId` references are resolved
/// from live form state, enabling queries to react to user input.
Map<String, Object> resolveQueryParams(
  List<ScreenQuery> queries,
  Map<String, dynamic> screenParams, {
  Map<String, dynamic> formValues = const {},
}) {
  final resolved = <String, Object>{};

  for (final query in queries) {
    for (final entry in query.params.entries) {
      final paramName = entry.key;
      final expression = entry.value;

      // $componentId — resolve from formValues
      final reactiveMatch = _reactivePattern.firstMatch(expression);
      if (reactiveMatch != null) {
        final componentId = reactiveMatch.group(1)!;
        final value = formValues[componentId];
        if (value != null) {
          resolved[paramName] = value as Object;
          continue;
        }
        // Fall through to defaults
      }

      // {{filters.fieldName}} — resolve from screenParams
      final filterMatch = _filterPattern.firstMatch(expression);
      if (filterMatch != null) {
        final filterKey = filterMatch.group(1)!;
        final value = screenParams[filterKey];
        if (value != null) {
          resolved[paramName] = value as Object;
          continue;
        }
      }

      // {{fieldName}} — resolve from screenParams directly
      final templateMatch = _templatePattern.firstMatch(expression);
      if (templateMatch != null) {
        final fieldName = templateMatch.group(1)!;
        final value = screenParams[fieldName];
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
