import 'package:equatable/equatable.dart';

/// Type-safe effect declarations for [ModuleSchema].
///
/// Effects are side-effects that run when entries are created or deleted.
/// They are executed by `PostSubmitEffectExecutor`.
sealed class SchemaEffect extends Equatable {
  const SchemaEffect();

  String get type;

  Map<String, dynamic> toJson();

  /// Deserializes an effect from its JSON representation.
  ///
  /// Falls back to [UnknownEffect] for unrecognized types so old data
  /// never causes a crash.
  static SchemaEffect fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'adjust_reference' => AdjustReferenceEffect.fromJson(json),
      'set_reference' => SetReferenceEffect.fromJson(json),
      _ => UnknownEffect(json),
    };
  }
}

/// Adjusts a numeric field on a referenced entry (add/subtract).
class AdjustReferenceEffect extends SchemaEffect {
  @override
  String get type => 'adjust_reference';

  final String referenceField;
  final String targetField;
  final String operation; // 'add' or 'subtract'
  final String? amountField;
  final num? amount;
  final num? min;

  const AdjustReferenceEffect({
    required this.referenceField,
    required this.targetField,
    required this.operation,
    this.amountField,
    this.amount,
    this.min,
  });

  /// Returns a copy with the operation inverted (add↔subtract).
  AdjustReferenceEffect inverted() => AdjustReferenceEffect(
        referenceField: referenceField,
        targetField: targetField,
        operation: operation == 'add' ? 'subtract' : 'add',
        amountField: amountField,
        amount: amount,
        min: min,
      );

  factory AdjustReferenceEffect.fromJson(Map<String, dynamic> json) {
    return AdjustReferenceEffect(
      referenceField: json['referenceField'] as String? ?? '',
      targetField: json['targetField'] as String? ?? '',
      operation: json['operation'] as String? ?? 'add',
      amountField: json['amountField'] as String?,
      amount: json['amount'] as num?,
      min: json['min'] as num?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'referenceField': referenceField,
        'targetField': targetField,
        'operation': operation,
        if (amountField != null) 'amountField': amountField,
        if (amount != null) 'amount': amount,
        if (min != null) 'min': min,
      };

  @override
  List<Object?> get props =>
      [referenceField, targetField, operation, amountField, amount, min];
}

/// Sets a field on a referenced entry to a literal value or form value.
class SetReferenceEffect extends SchemaEffect {
  @override
  String get type => 'set_reference';

  final String referenceField;
  final String targetField;
  final String? sourceField;
  final dynamic value;

  const SetReferenceEffect({
    required this.referenceField,
    required this.targetField,
    this.sourceField,
    this.value,
  });

  factory SetReferenceEffect.fromJson(Map<String, dynamic> json) {
    return SetReferenceEffect(
      referenceField: json['referenceField'] as String? ?? '',
      targetField: json['targetField'] as String? ?? '',
      sourceField: json['sourceField'] as String?,
      value: json['value'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'referenceField': referenceField,
        'targetField': targetField,
        if (sourceField != null) 'sourceField': sourceField,
        if (value != null) 'value': value,
      };

  @override
  List<Object?> get props => [referenceField, targetField, sourceField, value];
}

/// Preserves unrecognized effect types so data is never lost.
class UnknownEffect extends SchemaEffect {
  @override
  String get type => _json['type'] as String? ?? 'unknown';

  final Map<String, dynamic> _json;

  const UnknownEffect(this._json);

  @override
  Map<String, dynamic> toJson() => _json;

  @override
  List<Object?> get props => [_json];
}
