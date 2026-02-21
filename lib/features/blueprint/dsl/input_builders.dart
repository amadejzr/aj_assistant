import 'action_builders.dart';

/// Static builders for input widgets.
class Inputs {
  Inputs._();

  static Json textInput({
    required String fieldKey,
    String? label,
    bool? required,
    bool? multiline,
    int? maxLength,
    int? minLength,
    dynamic defaultValue,
    Json? validation,
    dynamic visibleWhen,
  }) => {
    'type': 'text_input',
    'fieldKey': fieldKey,
    if (label != null) 'label': label,
    if (required != null) 'required': required,
    if (multiline != null) 'multiline': multiline,
    if (maxLength != null) 'maxLength': maxLength,
    if (minLength != null) 'minLength': minLength,
    if (defaultValue != null) 'defaultValue': defaultValue,
    if (validation != null) 'validation': validation,
    if (visibleWhen != null) 'visibleWhen': visibleWhen,
  };

  static Json numberInput({
    required String fieldKey,
    String? label,
    bool? required,
    num? min,
    num? max,
    num? step,
    dynamic defaultValue,
    Json? validation,
    dynamic visibleWhen,
  }) => {
    'type': 'number_input',
    'fieldKey': fieldKey,
    if (label != null) 'label': label,
    if (required != null) 'required': required,
    if (min != null) 'min': min,
    if (max != null) 'max': max,
    if (step != null) 'step': step,
    if (defaultValue != null) 'defaultValue': defaultValue,
    if (validation != null) 'validation': validation,
    if (visibleWhen != null) 'visibleWhen': visibleWhen,
  };

  static Json currencyInput({
    required String fieldKey,
    String? label,
    bool? required,
    String? currencySymbol,
    int? decimalPlaces,
    num? min,
    Json? validation,
    dynamic visibleWhen,
  }) => {
    'type': 'currency_input',
    'fieldKey': fieldKey,
    if (label != null) 'label': label,
    if (required != null) 'required': required,
    if (currencySymbol != null) 'currencySymbol': currencySymbol,
    if (decimalPlaces != null) 'decimalPlaces': decimalPlaces,
    if (min != null) 'min': min,
    if (validation != null) 'validation': validation,
    if (visibleWhen != null) 'visibleWhen': visibleWhen,
  };

  static Json datePicker({
    required String fieldKey,
    String? label,
    bool? required,
    dynamic defaultValue,
    Json? validation,
    dynamic visibleWhen,
  }) => {
    'type': 'date_picker',
    'fieldKey': fieldKey,
    if (label != null) 'label': label,
    if (required != null) 'required': required,
    if (defaultValue != null) 'defaultValue': defaultValue,
    if (validation != null) 'validation': validation,
    if (visibleWhen != null) 'visibleWhen': visibleWhen,
  };

  static Json timePicker({
    required String fieldKey,
    String? label,
    bool? required,
    dynamic defaultValue,
    dynamic visibleWhen,
  }) => {
    'type': 'time_picker',
    'fieldKey': fieldKey,
    if (label != null) 'label': label,
    if (required != null) 'required': required,
    if (defaultValue != null) 'defaultValue': defaultValue,
    if (visibleWhen != null) 'visibleWhen': visibleWhen,
  };

  static Json enumSelector({
    required String fieldKey,
    String? label,
    bool? required,
    List<String>? options,
    dynamic visibleWhen,
  }) => {
    'type': 'enum_selector',
    'fieldKey': fieldKey,
    if (label != null) 'label': label,
    if (required != null) 'required': required,
    if (options != null) 'options': options,
    if (visibleWhen != null) 'visibleWhen': visibleWhen,
  };

  static Json multiEnumSelector({
    required String fieldKey,
    String? label,
    List<String>? options,
    dynamic visibleWhen,
  }) => {
    'type': 'multi_enum_selector',
    'fieldKey': fieldKey,
    if (label != null) 'label': label,
    if (options != null) 'options': options,
    if (visibleWhen != null) 'visibleWhen': visibleWhen,
  };

  static Json toggle({
    required String fieldKey,
    String? label,
    dynamic visibleWhen,
  }) => {
    'type': 'toggle',
    'fieldKey': fieldKey,
    if (label != null) 'label': label,
    if (visibleWhen != null) 'visibleWhen': visibleWhen,
  };

  static Json slider({
    required String fieldKey,
    String? label,
    num? min,
    num? max,
    num? step,
    int? divisions,
    dynamic visibleWhen,
  }) => {
    'type': 'slider',
    'fieldKey': fieldKey,
    if (label != null) 'label': label,
    if (min != null) 'min': min,
    if (max != null) 'max': max,
    if (step != null) 'step': step,
    if (divisions != null) 'divisions': divisions,
    if (visibleWhen != null) 'visibleWhen': visibleWhen,
  };

  static Json ratingInput({
    required String fieldKey,
    String? label,
    int? maxRating,
    dynamic visibleWhen,
  }) => {
    'type': 'rating_input',
    'fieldKey': fieldKey,
    if (label != null) 'label': label,
    if (maxRating != null) 'maxRating': maxRating,
    if (visibleWhen != null) 'visibleWhen': visibleWhen,
  };

  static Json referencePicker({
    required String fieldKey,
    required String schemaKey,
    String? displayField,
    String? source,
    String? label,
    bool? required,
    String? emptyLabel,
    Json? emptyAction,
    dynamic visibleWhen,
  }) => {
    'type': 'reference_picker',
    'fieldKey': fieldKey,
    'schemaKey': schemaKey,
    if (displayField != null) 'displayField': displayField,
    if (source != null) 'source': source,
    if (label != null) 'label': label,
    if (required != null) 'required': required,
    if (emptyLabel != null) 'emptyLabel': emptyLabel,
    if (emptyAction != null) 'emptyAction': emptyAction,
    if (visibleWhen != null) 'visibleWhen': visibleWhen,
  };

  static Json colorPicker({
    required String fieldKey,
    String? label,
    dynamic visibleWhen,
  }) => {
    'type': 'color_picker',
    'fieldKey': fieldKey,
    if (label != null) 'label': label,
    if (visibleWhen != null) 'visibleWhen': visibleWhen,
  };
}
