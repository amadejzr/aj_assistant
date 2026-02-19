import '../../../core/models/entry.dart';
import '../../schema/models/schema_effect.dart';

/// Computes entry updates from effects declared in schema definitions.
///
/// This is a pure computation class with no side effects — it takes the
/// effect definitions, submitted form data, and current entries, then returns
/// a map of entry updates the caller should apply.
class PostSubmitEffectExecutor {
  const PostSubmitEffectExecutor();

  /// Computes entry updates for the given effects.
  ///
  /// Returns `{entryId: {field: newValue, ...}, ...}`.
  Map<String, Map<String, dynamic>> computeUpdates({
    required List<SchemaEffect> effects,
    required Map<String, dynamic> formData,
    required List<Entry> entries,
  }) {
    final entryById = {for (final e in entries) e.id: e};
    final updates = <String, Map<String, dynamic>>{};

    for (final effect in effects) {
      switch (effect) {
        case AdjustReferenceEffect():
          _applyAdjust(effect, formData, entryById, updates);
        case SetReferenceEffect():
          _applySet(effect, formData, entryById, updates);
        case UnknownEffect():
          break;
      }
    }

    return updates;
  }

  /// Checks `min` guards on `adjust_reference` effects.
  ///
  /// Returns an error message if any guard would be violated, or `null`
  /// if all effects are safe to apply.
  String? validateEffects({
    required List<SchemaEffect> effects,
    required Map<String, dynamic> formData,
    required List<Entry> entries,
  }) {
    final entryById = {for (final e in entries) e.id: e};

    for (final effect in effects) {
      if (effect is! AdjustReferenceEffect) continue;

      final min = effect.min;
      if (min == null) continue;

      final entryId = formData[effect.referenceField]?.toString();
      if (entryId == null || entryId.isEmpty) continue;

      final entry = entryById[entryId];
      if (entry == null) continue;

      final num? amount;
      if (effect.amount != null) {
        amount = effect.amount;
      } else if (effect.amountField != null) {
        amount = _toNum(formData[effect.amountField]);
      } else {
        continue;
      }
      if (amount == null) continue;

      final current = _toNum(entry.data[effect.targetField]) ?? 0;
      final newValue =
          effect.operation == 'add' ? current + amount : current - amount;

      if (newValue < min) {
        final name = entry.data['name']?.toString() ?? effect.referenceField;
        return 'Insufficient funds in $name';
      }
    }

    return null;
  }

  void _applyAdjust(
    AdjustReferenceEffect effect,
    Map<String, dynamic> formData,
    Map<String, Entry> entryById,
    Map<String, Map<String, dynamic>> updates,
  ) {
    if (effect.operation != 'add' && effect.operation != 'subtract') return;

    final entryId = formData[effect.referenceField]?.toString();
    if (entryId == null || entryId.isEmpty) return;

    final entry = entryById[entryId];
    if (entry == null) return;

    final num? amount;
    if (effect.amount != null) {
      amount = effect.amount;
    } else if (effect.amountField != null) {
      amount = _toNum(formData[effect.amountField]);
    } else {
      return;
    }
    if (amount == null) return;

    final accumulated = updates[entryId] ?? {};
    final currentRaw = accumulated.containsKey(effect.targetField)
        ? accumulated[effect.targetField]
        : entry.data[effect.targetField];
    final current = _toNum(currentRaw) ?? 0;

    final newValue =
        effect.operation == 'add' ? current + amount : current - amount;

    updates.putIfAbsent(entryId, () => {});
    updates[entryId]![effect.targetField] = newValue;
  }

  void _applySet(
    SetReferenceEffect effect,
    Map<String, dynamic> formData,
    Map<String, Entry> entryById,
    Map<String, Map<String, dynamic>> updates,
  ) {
    final entryId = formData[effect.referenceField]?.toString();
    if (entryId == null || entryId.isEmpty) return;

    final entry = entryById[entryId];
    if (entry == null) return;

    final dynamic newValue;
    if (effect.sourceField != null) {
      newValue = formData[effect.sourceField];
    } else {
      newValue = effect.value;
    }
    if (newValue == null) return;

    updates.putIfAbsent(entryId, () => {});
    updates[entryId]![effect.targetField] = newValue;
  }

  /// Computes entry updates for delete operations.
  ///
  /// For `adjust_reference`, the operation is auto-inverted.
  Map<String, Map<String, dynamic>> computeDeleteUpdates({
    required List<SchemaEffect> effects,
    required Map<String, dynamic> deletedEntryData,
    required List<Entry> entries,
  }) {
    final invertedEffects = effects.map((effect) {
      if (effect is AdjustReferenceEffect) return effect.inverted();
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
