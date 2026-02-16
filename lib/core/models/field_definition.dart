import 'package:equatable/equatable.dart';

import 'field_type.dart';

class FieldDefinition extends Equatable {
  final String key;
  final FieldType type;
  final String label;
  final bool required;
  final Map<String, dynamic> constraints;
  final List<String> options;

  const FieldDefinition({
    required this.key,
    required this.type,
    required this.label,
    this.required = false,
    this.constraints = const {},
    this.options = const [],
  });

  factory FieldDefinition.fromJson(String key, Map<String, dynamic> json) {
    return FieldDefinition(
      key: key,
      type: FieldType.fromString(json['type'] as String? ?? 'text'),
      label: json['label'] as String? ?? key,
      required: json['required'] as bool? ?? false,
      constraints: Map<String, dynamic>.from(
        json['constraints'] as Map? ?? {},
      ),
      options: List<String>.from(json['options'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toJson(),
      'label': label,
      'required': required,
      if (constraints.isNotEmpty) 'constraints': constraints,
      if (options.isNotEmpty) 'options': options,
    };
  }

  @override
  List<Object?> get props => [key, type, label, required, constraints, options];
}
