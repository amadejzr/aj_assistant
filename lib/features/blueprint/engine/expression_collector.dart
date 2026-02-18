/// Walks a blueprint JSON map and collects all expression strings from
/// nodes that don't have their own filter (i.e. nodes that operate on
/// the full entry set and can therefore share a single evaluation pass).
class ExpressionCollector {
  const ExpressionCollector();

  /// Node types whose `expression` field should be collected.
  static const _expressionTypes = {
    'stat_card',
    'chart',
    'progress_bar',
    'badge',
  };

  /// Returns the set of expression strings found in [blueprint].
  Set<String> collect(Map<String, dynamic> blueprint) {
    final result = <String>{};
    _walk(blueprint, result);
    return result;
  }

  void _walk(Map<String, dynamic> node, Set<String> out) {
    final type = node['type'] as String?;

    if (type != null && _expressionTypes.contains(type)) {
      if (!_hasFilter(node)) {
        final expr = node['expression'] as String?;
        if (expr != null && expr.isNotEmpty) {
          out.add(expr);
        }
      }
    }

    // Recurse into known child structures
    _walkChild(node['layout'], out);
    _walkChild(node['fab'], out);
    _walkChild(node['nav'], out);
    _walkChildren(node['children'], out);
    _walkChildren(node['thenChildren'], out);
    _walkChildren(node['elseChildren'], out);

    // Tab screen tabs
    final tabs = node['tabs'];
    if (tabs is List) {
      for (final tab in tabs) {
        if (tab is Map<String, dynamic>) {
          _walkChild(tab['content'], out);
        }
      }
    }
  }

  void _walkChild(dynamic child, Set<String> out) {
    if (child is Map<String, dynamic>) {
      _walk(child, out);
    }
  }

  void _walkChildren(dynamic children, Set<String> out) {
    if (children is List) {
      for (final child in children) {
        if (child is Map<String, dynamic>) {
          _walk(child, out);
        }
      }
    }
  }

  /// Returns true if the node has a non-null, non-empty filter property.
  bool _hasFilter(Map<String, dynamic> node) {
    final filter = node['filter'];
    if (filter == null) return false;
    if (filter is Map && filter.isEmpty) return false;
    if (filter is List && filter.isEmpty) return false;
    return true;
  }
}
