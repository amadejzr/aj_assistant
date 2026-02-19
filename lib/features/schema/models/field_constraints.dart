import 'package:equatable/equatable.dart';

import 'field_type.dart';

/// Type-safe constraints for each [FieldType].
///
/// Instead of `Map<String, dynamic>`, every field type maps to a specific
/// subclass with typed fields. Use [FieldConstraints.fromJson] to
/// deserialize — it uses [FieldType] as the discriminator.
sealed class FieldConstraints extends Equatable {
  const FieldConstraints();

  Map<String, dynamic> toJson();

  /// Deserializes constraints using [type] as discriminator.
  ///
  /// The [json] map is the `constraints` value from the FieldDefinition JSON.
  /// For enum types, pass `options` merged in under the `'options'` key.
  static FieldConstraints fromJson(FieldType type, Map<String, dynamic> json) {
    return switch (type) {
      FieldType.text => TextConstraints.fromJson(json),
      FieldType.number => NumberConstraints.fromJson(json),
      FieldType.currency => CurrencyConstraints.fromJson(json),
      FieldType.datetime => DateTimeConstraints.fromJson(json),
      FieldType.enumType || FieldType.multiEnum => EnumConstraints.fromJson(json),
      FieldType.rating => RatingConstraints.fromJson(json),
      FieldType.duration => DurationConstraints.fromJson(json),
      FieldType.reference => ReferenceConstraints.fromJson(json),
      _ => const EmptyConstraints(),
    };
  }
}

// ── Text ──

class TextConstraints extends FieldConstraints {
  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final bool multiline;

  const TextConstraints({
    this.minLength,
    this.maxLength,
    this.pattern,
    this.multiline = false,
  });

  factory TextConstraints.fromJson(Map<String, dynamic> json) {
    return TextConstraints(
      minLength: json['minLength'] as int?,
      maxLength: json['maxLength'] as int?,
      pattern: json['pattern'] as String?,
      multiline: json['multiline'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (minLength != null) 'minLength': minLength,
        if (maxLength != null) 'maxLength': maxLength,
        if (pattern != null) 'pattern': pattern,
        if (multiline) 'multiline': multiline,
      };

  @override
  List<Object?> get props => [minLength, maxLength, pattern, multiline];
}

// ── Number ──

class NumberConstraints extends FieldConstraints {
  final num? min;
  final num? max;
  final num? step;
  final int? divisions;

  const NumberConstraints({this.min, this.max, this.step, this.divisions});

  factory NumberConstraints.fromJson(Map<String, dynamic> json) {
    return NumberConstraints(
      min: json['min'] as num?,
      max: json['max'] as num?,
      step: json['step'] as num?,
      divisions: json['divisions'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (min != null) 'min': min,
        if (max != null) 'max': max,
        if (step != null) 'step': step,
        if (divisions != null) 'divisions': divisions,
      };

  @override
  List<Object?> get props => [min, max, step, divisions];
}

// ── Currency ──

class CurrencyConstraints extends FieldConstraints {
  final String? defaultCurrency;
  final num? min;
  final num? max;

  const CurrencyConstraints({this.defaultCurrency, this.min, this.max});

  factory CurrencyConstraints.fromJson(Map<String, dynamic> json) {
    return CurrencyConstraints(
      defaultCurrency: json['defaultCurrency'] as String?,
      min: json['min'] as num?,
      max: json['max'] as num?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (defaultCurrency != null) 'defaultCurrency': defaultCurrency,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
      };

  @override
  List<Object?> get props => [defaultCurrency, min, max];
}

// ── DateTime ──

class DateTimeConstraints extends FieldConstraints {
  final bool dateOnly;
  final bool allowPast;
  final bool allowFuture;

  const DateTimeConstraints({
    this.dateOnly = false,
    this.allowPast = true,
    this.allowFuture = true,
  });

  factory DateTimeConstraints.fromJson(Map<String, dynamic> json) {
    return DateTimeConstraints(
      dateOnly: json['dateOnly'] as bool? ?? false,
      allowPast: json['allowPast'] as bool? ?? true,
      allowFuture: json['allowFuture'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (dateOnly) 'dateOnly': dateOnly,
        if (!allowPast) 'allowPast': allowPast,
        if (!allowFuture) 'allowFuture': allowFuture,
      };

  @override
  List<Object?> get props => [dateOnly, allowPast, allowFuture];
}

// ── Enum / MultiEnum ──

class EnumConstraints extends FieldConstraints {
  final List<String> options;

  const EnumConstraints({this.options = const []});

  factory EnumConstraints.fromJson(Map<String, dynamic> json) {
    return EnumConstraints(
      options: List<String>.from(json['options'] as List? ?? []),
    );
  }

  /// Options are serialized at the FieldDefinition level for backward compat,
  /// so this returns an empty map.
  @override
  Map<String, dynamic> toJson() => {};

  @override
  List<Object?> get props => [options];
}

// ── Rating ──

class RatingConstraints extends FieldConstraints {
  final int maxRating;
  final bool allowHalf;

  const RatingConstraints({this.maxRating = 5, this.allowHalf = false});

  factory RatingConstraints.fromJson(Map<String, dynamic> json) {
    return RatingConstraints(
      maxRating: (json['max'] as num?)?.toInt() ?? 5,
      allowHalf: json['allowHalf'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (maxRating != 5) 'max': maxRating,
        if (allowHalf) 'allowHalf': allowHalf,
      };

  @override
  List<Object?> get props => [maxRating, allowHalf];
}

// ── Duration ──

enum DurationUnit { seconds, minutes, hours }

class DurationConstraints extends FieldConstraints {
  final DurationUnit unit;

  const DurationConstraints({this.unit = DurationUnit.minutes});

  factory DurationConstraints.fromJson(Map<String, dynamic> json) {
    final unitStr = json['unit'] as String?;
    final unit = DurationUnit.values.firstWhere(
      (e) => e.name == unitStr,
      orElse: () => DurationUnit.minutes,
    );
    return DurationConstraints(unit: unit);
  }

  @override
  Map<String, dynamic> toJson() => {
        if (unit != DurationUnit.minutes) 'unit': unit.name,
      };

  @override
  List<Object?> get props => [unit];
}

// ── Reference ──

enum OnDeleteAction { cascade, setNull, restrict }

class ReferenceConstraints extends FieldConstraints {
  final String targetSchema;
  final String? displayField;
  final OnDeleteAction onDelete;
  final String? inverseLabel;

  const ReferenceConstraints({
    required this.targetSchema,
    this.displayField,
    this.onDelete = OnDeleteAction.restrict,
    this.inverseLabel,
  });

  factory ReferenceConstraints.fromJson(Map<String, dynamic> json) {
    // Backward compat: old key was 'schemaKey', new key is 'targetSchema'
    final target =
        json['targetSchema'] as String? ?? json['schemaKey'] as String? ?? '';

    final onDeleteStr = json['onDelete'] as String?;
    final onDelete = OnDeleteAction.values.firstWhere(
      (e) => e.name == onDeleteStr,
      orElse: () => OnDeleteAction.restrict,
    );

    return ReferenceConstraints(
      targetSchema: target,
      displayField: json['displayField'] as String?,
      onDelete: onDelete,
      inverseLabel: json['inverseLabel'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'targetSchema': targetSchema,
        // Also write 'schemaKey' for backward compat with blueprint readers
        'schemaKey': targetSchema,
        if (displayField != null) 'displayField': displayField,
        if (onDelete != OnDeleteAction.restrict) 'onDelete': onDelete.name,
        if (inverseLabel != null) 'inverseLabel': inverseLabel,
      };

  @override
  List<Object?> get props => [targetSchema, displayField, onDelete, inverseLabel];
}

// ── Empty (boolean, image, location, url, phone, email, list) ──

class EmptyConstraints extends FieldConstraints {
  const EmptyConstraints();

  @override
  Map<String, dynamic> toJson() => {};

  @override
  List<Object?> get props => [];
}
