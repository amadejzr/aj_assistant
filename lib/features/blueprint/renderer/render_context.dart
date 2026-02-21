import '../../../core/models/entry.dart';
import '../../modules/models/field_definition.dart';
import '../../../core/models/module.dart';
import 'field_meta.dart';

class RenderContext {
  final Module module;
  final List<Entry> entries;
  final List<Entry> allEntries;
  final Map<String, dynamic> formValues;
  final Map<String, dynamic> screenParams;
  final bool canGoBack;
  final void Function(String fieldKey, dynamic value) onFormValueChanged;
  final VoidFormCallback? onFormSubmit;
  final void Function(String screenId, {Map<String, dynamic> params}) onNavigateToScreen;
  final VoidFormCallback? onNavigateBack;
  final void Function(String entryId)? onDeleteEntry;
  final Map<String, dynamic> resolvedExpressions;
  final Future<String?> Function(String schemaKey, Map<String, dynamic> data)? onCreateEntry;
  final Future<void> Function(String entryId, String schemaKey, Map<String, dynamic> data)? onUpdateEntry;
  final void Function(String key, dynamic value)? onScreenParamChanged;
  final VoidFormCallback? onOpenDrawer;
  final Map<String, List<Map<String, dynamic>>> queryResults;

  const RenderContext({
    required this.module,
    this.entries = const [],
    this.allEntries = const [],
    this.formValues = const {},
    this.screenParams = const {},
    this.canGoBack = false,
    required this.onFormValueChanged,
    this.onFormSubmit,
    required this.onNavigateToScreen,
    this.onNavigateBack,
    this.onDeleteEntry,
    this.resolvedExpressions = const {},
    this.onCreateEntry,
    this.onUpdateEntry,
    this.onScreenParamChanged,
    this.onOpenDrawer,
    this.queryResults = const {},
  });

  FieldDefinition? getFieldDefinition(String fieldKey, {String? schemaKey}) {
    if (schemaKey != null) return module.schemas[schemaKey]?.fields[fieldKey];
    // Fall back to _schemaKey from screenParams for multi-schema modules
    final contextSchemaKey = screenParams['_schemaKey'] as String?;
    if (contextSchemaKey != null) {
      return module.schemas[contextSchemaKey]?.fields[fieldKey];
    }
    return module.schema.fields[fieldKey];
  }

  Map<String, FieldDefinition> getSchemaFields(String schemaKey) {
    return module.schemas[schemaKey]?.fields ?? {};
  }

  dynamic getFormValue(String fieldKey) {
    return formValues[fieldKey];
  }

  /// Resolves field metadata from inline node properties only.
  ///
  /// No schema fallback — all metadata lives on the blueprint node.
  FieldMeta resolveFieldMeta(String fieldKey, Map<String, dynamic> properties) {
    return FieldMeta(
      label: properties['label'] as String? ?? fieldKey,
      required: properties['required'] as bool? ?? false,
      options: (properties['options'] as List?)?.cast<String>() ?? const [],
      min: properties['min'] as num?,
      max: properties['max'] as num?,
      step: properties['step'] as num?,
      divisions: properties['divisions'] as int?,
      maxLength: properties['maxLength'] as int?,
      minLength: properties['minLength'] as int?,
      maxRating: properties['maxRating'] as int?,
      multiline: properties['multiline'] as bool? ?? false,
      targetSchema: properties['targetSchema'] as String?,
    );
  }
}

typedef VoidFormCallback = void Function();
