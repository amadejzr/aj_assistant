import '../../../core/models/entry.dart';

/// Computes entry updates from `onSubmit` effects declared in form_screen
/// blueprints.
///
/// This is a pure computation class with no side effects — it takes the
/// effect definitions, submitted form data, and current entries, then returns
/// a map of entry updates the caller should apply.
///
/// ## Supported effect types
///
/// ### `adjust_reference`
/// Add or subtract a numeric value on a referenced entry's field.
/// ```json
/// {
///   "type": "adjust_reference",
///   "referenceField": "account",   // form field holding target entry ID
///   "targetField": "balance",       // field on the referenced entry
///   "amountField": "amount",        // form field holding the numeric value
///   "operation": "add"              // "add" or "subtract"
/// }
/// ```
/// Use `amount` instead of `amountField` for a literal value:
/// ```json
/// {
///   "type": "adjust_reference",
///   "referenceField": "program",
///   "targetField": "sessionsCompleted",
///   "amount": 1,
///   "operation": "add"
/// }
/// ```
///
/// ### `set_reference`
/// Set a field on a referenced entry to a literal value or a value copied
/// from the submitted form.
/// ```json
/// {
///   "type": "set_reference",
///   "referenceField": "goal",       // form field holding target entry ID
///   "targetField": "status",        // field on the referenced entry
///   "value": "completed"            // literal value to set
/// }
/// ```
/// Use `sourceField` instead of `value` to copy from the form:
/// ```json
/// {
///   "type": "set_reference",
///   "referenceField": "goal",
///   "targetField": "priority",
///   "sourceField": "newPriority"    // form field to copy value from
/// }
/// ```
class PostSubmitEffectExecutor {
  const PostSubmitEffectExecutor();

  /// Computes entry updates for the given effects.
  ///
  /// Returns `{entryId: {field: newValue, ...}, ...}`.
  /// Multiple effects can target the same entry — later effects see the
  /// accumulated state from earlier ones.
  Map<String, Map<String, dynamic>> computeUpdates({
    required List<dynamic> effects,
    required Map<String, dynamic> formData,
    required List<Entry> entries,
  }) {
    final entryById = {for (final e in entries) e.id: e};
    final updates = <String, Map<String, dynamic>>{};

    for (final effect in effects) {
      if (effect is! Map<String, dynamic>) continue;

      final type = effect['type'] as String?;
      switch (type) {
        case 'adjust_reference':
          _applyAdjust(effect, formData, entryById, updates);
        case 'set_reference':
          _applySet(effect, formData, entryById, updates);
      }
    }

    return updates;
  }

  void _applyAdjust(
    Map<String, dynamic> effect,
    Map<String, dynamic> formData,
    Map<String, Entry> entryById,
    Map<String, Map<String, dynamic>> updates,
  ) {
    final referenceField = effect['referenceField'] as String?;
    final targetField = effect['targetField'] as String?;
    final operation = effect['operation'] as String?;

    if (referenceField == null || targetField == null || operation == null) {
      return;
    }
    if (operation != 'add' && operation != 'subtract') return;

    final entryId = formData[referenceField]?.toString();
    if (entryId == null || entryId.isEmpty) return;

    final entry = entryById[entryId];
    if (entry == null) return;

    // Resolve amount: literal `amount` takes precedence, then `amountField`
    final num? amount;
    if (effect.containsKey('amount')) {
      amount = _toNum(effect['amount']);
    } else {
      final amountField = effect['amountField'] as String?;
      if (amountField == null) return;
      amount = _toNum(formData[amountField]);
    }
    if (amount == null) return;

    // Read current value from accumulated updates or original entry data
    final accumulated = updates[entryId] ?? {};
    final currentRaw = accumulated.containsKey(targetField)
        ? accumulated[targetField]
        : entry.data[targetField];
    final current = _toNum(currentRaw) ?? 0;

    final newValue = operation == 'add' ? current + amount : current - amount;

    updates.putIfAbsent(entryId, () => {});
    updates[entryId]![targetField] = newValue;
  }

  void _applySet(
    Map<String, dynamic> effect,
    Map<String, dynamic> formData,
    Map<String, Entry> entryById,
    Map<String, Map<String, dynamic>> updates,
  ) {
    final referenceField = effect['referenceField'] as String?;
    final targetField = effect['targetField'] as String?;

    if (referenceField == null || targetField == null) return;

    final entryId = formData[referenceField]?.toString();
    if (entryId == null || entryId.isEmpty) return;

    final entry = entryById[entryId];
    if (entry == null) return;

    // sourceField overrides value
    final dynamic newValue;
    final sourceField = effect['sourceField'] as String?;
    if (sourceField != null) {
      newValue = formData[sourceField];
    } else {
      newValue = effect['value'];
    }
    if (newValue == null) return;

    updates.putIfAbsent(entryId, () => {});
    updates[entryId]![targetField] = newValue;
  }

  static num? _toNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}
