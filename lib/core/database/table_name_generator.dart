/// Generates safe SQL identifiers from module names and IDs.
class TableNameGenerator {
  TableNameGenerator._();

  /// Generates a table name: `m_{sanitized_name}_{first_8_of_id}`.
  static String moduleTable(String moduleId, String moduleName) {
    final name = _sanitize(moduleName);
    final shortId = _sanitizeId(moduleId);
    return 'm_${name}_$shortId';
  }

  /// Generates a safe column name from a field label or key.
  static String columnName(String fieldName) => _sanitize(fieldName);

  static String _sanitize(String input) {
    final cleaned = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '') // strip non-ASCII (emojis)
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '') // keep only alphanumeric + space
        .trim()
        .replaceAll(RegExp(r'\s+'), '_'); // spaces → underscores

    // Collapse multiple underscores
    return cleaned.replaceAll(RegExp(r'_+'), '_');
  }

  static String _sanitizeId(String id) {
    final cleaned = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return cleaned.length > 8 ? cleaned.substring(0, 8) : cleaned;
  }
}
