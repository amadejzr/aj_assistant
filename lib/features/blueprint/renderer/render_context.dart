import '../../../core/models/entry.dart';
import '../../schema/models/field_definition.dart';
import '../../../core/models/module.dart';

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
  });

  FieldDefinition? getFieldDefinition(String fieldKey, {String? schemaKey}) {
    if (schemaKey != null) return module.schemas[schemaKey]?.fields[fieldKey];
    return module.schema.fields[fieldKey];
  }

  Map<String, FieldDefinition> getSchemaFields(String schemaKey) {
    return module.schemas[schemaKey]?.fields ?? {};
  }

  dynamic getFormValue(String fieldKey) {
    return formValues[fieldKey];
  }
}

typedef VoidFormCallback = void Function();
