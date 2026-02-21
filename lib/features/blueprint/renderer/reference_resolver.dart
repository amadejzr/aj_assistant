import '../../../core/models/module.dart';

/// Resolves reference field values to display text.
///
/// With SQL-only modules, references are resolved via JOINs in queries.
/// This class provides a simple fallback that does basic ID-to-display-text
/// resolution using allEntries (as Maps).
class ReferenceResolver {
  final Module module;
  final List<Map<String, dynamic>> allEntries;

  const ReferenceResolver({required this.module, required this.allEntries});

  /// Resolves a reference field value (entry ID) to its display text.
  /// Looks up the entry by ID and returns its "name" field (or the raw value).
  String resolve(String fieldKey, dynamic rawValue, {String? schemaKey}) {
    if (rawValue == null) return '';

    final refEntry = allEntries
        .where((e) => e['id'] == rawValue.toString())
        .firstOrNull;
    if (refEntry == null) return rawValue.toString();

    // Convention: use "name" field as display text
    return refEntry['name']?.toString() ?? rawValue.toString();
  }

  /// Resolves a dot-notation reference like `category.name`:
  /// looks up the referenced entry via [fieldKey] and returns [subField] from it.
  String resolveField(
    String fieldKey,
    String subField,
    dynamic rawValue, {
    String? schemaKey,
  }) {
    if (rawValue == null) return '';

    final refEntry = allEntries
        .where((e) => e['id'] == rawValue.toString())
        .firstOrNull;
    if (refEntry == null) return '';

    return refEntry[subField]?.toString() ?? '';
  }
}
