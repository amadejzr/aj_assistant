import 'package:equatable/equatable.dart';

/// Inline field metadata resolved from blueprint node properties.
///
/// Replaces schema-based [FieldDefinition] lookups in input builders.
/// All values come from the node's `properties` map — no schema fallback.
class FieldMeta extends Equatable {
  final String label;
  final bool required;
  final List<String> options;
  final num? min;
  final num? max;
  final num? step;
  final int? divisions;
  final int? maxLength;
  final int? minLength;
  final int? maxRating;
  final bool multiline;
  final String? targetSchema;

  const FieldMeta({
    required this.label,
    this.required = false,
    this.options = const [],
    this.min,
    this.max,
    this.step,
    this.divisions,
    this.maxLength,
    this.minLength,
    this.maxRating,
    this.multiline = false,
    this.targetSchema,
  });

  @override
  List<Object?> get props => [
        label,
        required,
        options,
        min,
        max,
        step,
        divisions,
        maxLength,
        minLength,
        maxRating,
        multiline,
        targetSchema,
      ];
}
