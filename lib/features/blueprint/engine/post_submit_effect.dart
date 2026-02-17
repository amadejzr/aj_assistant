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
/// Optional guard: `"min": 0` rejects the operation if the result would
/// drop below the threshold. [validateEffects] checks guards before any
/// writes happen — if any guard fails the entire batch is rejected.
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

  /// Checks `min` / `max` guards on `adjust_reference` effects.
  ///
  /// Returns an error message if any guard would be violated, or `null`
  /// if all effects are safe to apply. Call this **before** creating the
  /// entry so nothing is written when validation fails.
  String? validateEffects({
    required List<dynamic> effects,
    required Map<String, dynamic> formData,
    required List<Entry> entries,
  }) {
    final entryById = {for (final e in entries) e.id: e};

    for (final effect in effects) {
      if (effect is! Map<String, dynamic>) continue;
      if (effect['type'] != 'adjust_reference') continue;

      final min = _toNum(effect['min']);
      if (min == null) continue; // no guard to check

      final referenceField = effect['referenceField'] as String?;
      final targetField = effect['targetField'] as String?;
      final operation = effect['operation'] as String?;
      if (referenceField == null ||
          targetField == null ||
          operation == null) {
        continue;
      }

      final entryId = formData[referenceField]?.toString();
      if (entryId == null || entryId.isEmpty) continue;

      final entry = entryById[entryId];
      if (entry == null) continue;

      final num? amount;
      if (effect.containsKey('amount')) {
        amount = _toNum(effect['amount']);
      } else {
        final amountField = effect['amountField'] as String?;
        if (amountField == null) continue;
        amount = _toNum(formData[amountField]);
      }
      if (amount == null) continue;

      final current = _toNum(entry.data[targetField]) ?? 0;
      final newValue =
          operation == 'add' ? current + amount : current - amount;

      if (newValue < min) {
        final name = entry.data['name']?.toString() ?? referenceField;
        return 'Insufficient funds in $name';
      }
    }

    return null;
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

  /// Computes entry updates for delete operations.
  ///
  /// The deleted entry's data is used as the "form data" — its fields
  /// are read to reverse the original effect. For `adjust_reference`,
  /// the operation is auto-inverted: "add" becomes "subtract" and vice versa.
  Map<String, Map<String, dynamic>> computeDeleteUpdates({
    required List<Map<String, dynamic>> effects,
    required Map<String, dynamic> deletedEntryData,
    required List<Entry> entries,
  }) {
    // Invert adjust_reference operations; pass through set_reference as-is
    final invertedEffects = effects.map((effect) {
      final type = effect['type'] as String?;
      if (type == 'adjust_reference') {
        final op = effect['operation'] as String?;
        final invertedOp = op == 'add' ? 'subtract' : 'add';
        return {...effect, 'operation': invertedOp};
      }
      return effect;
    }).toList();

    return computeUpdates(
      effects: invertedEffects,
      formData: deletedEntryData,
      entries: entries,
    );
  }

  static num? _toNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}
