import 'package:equatable/equatable.dart';

import 'field_constraints.dart';
import 'field_type.dart';

class FieldDefinition extends Equatable {
  final String key;
  final FieldType type;
  final String label;
  final bool required;
  final FieldConstraints constraints;

  const FieldDefinition({
    required this.key,
    required this.type,
    required this.label,
    this.required = false,
    this.constraints = const EmptyConstraints(),
  });

  /// Convenience accessor — returns enum options if this is an enum field.
  List<String> get options => switch (constraints) {
        EnumConstraints(:final options) => options,
        _ => const [],
      };

  factory FieldDefinition.fromJson(String key, Map<String, dynamic> json) {
    final type = FieldType.fromString(json['type'] as String? ?? 'text');

    // Read the raw constraints map
    final constraintsJson = Map<String, dynamic>.from(
      json['constraints'] as Map? ?? {},
    );

    // Backward compat: merge top-level 'options' into constraints for enum types
    final options = json['options'] as List?;
    if (options != null &&
        (type == FieldType.enumType || type == FieldType.multiEnum)) {
      constraintsJson['options'] = options;
    }

    return FieldDefinition(
      key: key,
      type: type,
      label: json['label'] as String? ?? key,
      required: json['required'] as bool? ?? false,
      constraints: FieldConstraints.fromJson(type, constraintsJson),
    );
  }

  FieldDefinition copyWith({
    String? key,
    FieldType? type,
    String? label,
    bool? required,
    FieldConstraints? constraints,
  }) {
    return FieldDefinition(
      key: key ?? this.key,
      type: type ?? this.type,
      label: label ?? this.label,
      required: required ?? this.required,
      constraints: constraints ?? this.constraints,
    );
  }

  Map<String, dynamic> toJson() {
    final constraintsJson = constraints.toJson();

    return {
      'type': type.toJson(),
      'label': label,
      'required': required,
      if (constraintsJson.isNotEmpty) 'constraints': constraintsJson,
      // Write options at field level for backward compat
      if (options.isNotEmpty) 'options': options,
    };
  }

  @override
  List<Object?> get props => [key, type, label, required, constraints];
}
