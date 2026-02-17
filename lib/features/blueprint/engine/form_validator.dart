/// Pure validation logic for form field blueprints.
///
/// Reads the `validation` property from a blueprint node's properties
/// and returns an error message or null if valid.
///
/// Supported rules:
///   `required` (`bool`) — field must not be empty
///   `min` (`num`) — minimum numeric value
///   `max` (`num`) — maximum numeric value
///   `minLength` (`int`) — minimum string length
///   `maxLength` (`int`) — maximum string length
///   `pattern` (`String`) — regex pattern the value must match
///   `message` (`String`) — custom error message (overrides default)
class FormValidator {
  const FormValidator._();

  /// Validates a string value against the validation rules.
  ///
  /// [value] is the raw string from the text field.
  /// [validation] is the validation map from the blueprint.
  /// [label] is the field label for default error messages.
  ///
  /// Returns null if valid, error message string if invalid.
  static String? validate({
    required String? value,
    required Map<String, dynamic>? validation,
    required String label,
  }) {
    if (validation == null || validation.isEmpty) return null;

    final customMessage = validation['message'] as String?;
    final isRequired = validation['required'] as bool? ?? false;

    // Required check
    if (isRequired && (value == null || value.trim().isEmpty)) {
      return customMessage ?? '$label is required';
    }

    // If value is empty and not required, skip remaining checks
    if (value == null || value.trim().isEmpty) return null;

    // Min length
    final minLength = validation['minLength'] as int?;
    if (minLength != null && value.length < minLength) {
      return customMessage ?? '$label must be at least $minLength characters';
    }

    // Max length
    final maxLength = validation['maxLength'] as int?;
    if (maxLength != null && value.length > maxLength) {
      return customMessage ?? '$label must be at most $maxLength characters';
    }

    // Pattern (regex)
    final pattern = validation['pattern'] as String?;
    if (pattern != null) {
      try {
        final regex = RegExp(pattern);
        if (!regex.hasMatch(value)) {
          return customMessage ?? '$label format is invalid';
        }
      } catch (_) {
        // Invalid regex — skip this check
      }
    }

    // Numeric min/max
    final min = _toNum(validation['min']);
    final max = _toNum(validation['max']);
    if (min != null || max != null) {
      final numValue = num.tryParse(value);
      if (numValue != null) {
        if (min != null && numValue < min) {
          return customMessage ?? '$label must be at least $min';
        }
        if (max != null && numValue > max) {
          return customMessage ?? '$label must be at most $max';
        }
      }
    }

    return null;
  }

  /// Validates a numeric value directly (for number inputs that parse before calling).
  static String? validateNumeric({
    required num? value,
    required Map<String, dynamic>? validation,
    required String label,
  }) {
    if (validation == null || validation.isEmpty) return null;

    final customMessage = validation['message'] as String?;
    final isRequired = validation['required'] as bool? ?? false;

    if (isRequired && value == null) {
      return customMessage ?? '$label is required';
    }

    if (value == null) return null;

    final min = _toNum(validation['min']);
    final max = _toNum(validation['max']);

    if (min != null && value < min) {
      return customMessage ?? '$label must be at least $min';
    }
    if (max != null && value > max) {
      return customMessage ?? '$label must be at most $max';
    }

    return null;
  }

  static num? _toNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}
