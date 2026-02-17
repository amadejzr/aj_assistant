import '../../../core/models/entry.dart';
import '../../../core/models/module.dart';
import '../../schema/models/field_type.dart';
import '../../schema/models/module_schema.dart';

class ReferenceResolver {
  final Module module;
  final List<Entry> allEntries;

  const ReferenceResolver({required this.module, required this.allEntries});

  /// Resolves a reference field value (entry ID) to its display text.
  /// Returns raw value as string if not a reference or resolution fails.
  String resolve(String fieldKey, dynamic rawValue, {String? schemaKey}) {
    if (rawValue == null) return '';
    final field = _getField(fieldKey, schemaKey);
    if (field == null || field.type != FieldType.reference) {
      return rawValue.toString();
    }

    final targetSchemaKey = field.constraints['schemaKey'] as String?;
    if (targetSchemaKey == null) return rawValue.toString();

    final targetSchema = module.schemas[targetSchemaKey];
    if (targetSchema == null) return rawValue.toString();

    final refEntry = allEntries
        .where(
            (e) => e.id == rawValue.toString() && e.schemaKey == targetSchemaKey)
        .firstOrNull;
    if (refEntry == null) return rawValue.toString();

    final displayField = _findDisplayField(targetSchema);
    return refEntry.data[displayField]?.toString() ?? rawValue.toString();
  }

  dynamic _getField(String fieldKey, String? schemaKey) {
    if (schemaKey != null) {
      return module.schemas[schemaKey]?.fields[fieldKey];
    }
    // Search all schemas
    for (final schema in module.schemas.values) {
      final field = schema.fields[fieldKey];
      if (field != null) return field;
    }
    return null;
  }

  String _findDisplayField(ModuleSchema schema) {
    if (schema.fields.containsKey('name')) return 'name';
    for (final e in schema.fields.entries) {
      if (e.value.type == FieldType.text) return e.key;
    }
    return schema.fields.keys.first;
  }
}
