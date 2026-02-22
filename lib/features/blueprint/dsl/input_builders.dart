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
    'label': ?label,
    'required': ?required,
    'multiline': ?multiline,
    'maxLength': ?maxLength,
    'minLength': ?minLength,
    'defaultValue': ?defaultValue,
    'validation': ?validation,
    'visibleWhen': ?visibleWhen,
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
    'label': ?label,
    'required': ?required,
    'min': ?min,
    'max': ?max,
    'step': ?step,
    'defaultValue': ?defaultValue,
    'validation': ?validation,
    'visibleWhen': ?visibleWhen,
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
    'label': ?label,
    'required': ?required,
    'currencySymbol': ?currencySymbol,
    'decimalPlaces': ?decimalPlaces,
    'min': ?min,
    'validation': ?validation,
    'visibleWhen': ?visibleWhen,
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
    'label': ?label,
    'required': ?required,
    'defaultValue': ?defaultValue,
    'validation': ?validation,
    'visibleWhen': ?visibleWhen,
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
    'label': ?label,
    'required': ?required,
    'defaultValue': ?defaultValue,
    'visibleWhen': ?visibleWhen,
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
    'label': ?label,
    'required': ?required,
    'options': ?options,
    'visibleWhen': ?visibleWhen,
  };

  static Json multiEnumSelector({
    required String fieldKey,
    String? label,
    List<String>? options,
    dynamic visibleWhen,
  }) => {
    'type': 'multi_enum_selector',
    'fieldKey': fieldKey,
    'label': ?label,
    'options': ?options,
    'visibleWhen': ?visibleWhen,
  };

  static Json toggle({
    required String fieldKey,
    String? label,
    dynamic visibleWhen,
  }) => {
    'type': 'toggle',
    'fieldKey': fieldKey,
    'label': ?label,
    'visibleWhen': ?visibleWhen,
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
    'label': ?label,
    'min': ?min,
    'max': ?max,
    'step': ?step,
    'divisions': ?divisions,
    'visibleWhen': ?visibleWhen,
  };

  static Json ratingInput({
    required String fieldKey,
    String? label,
    int? maxRating,
    dynamic visibleWhen,
  }) => {
    'type': 'rating_input',
    'fieldKey': fieldKey,
    'label': ?label,
    'maxRating': ?maxRating,
    'visibleWhen': ?visibleWhen,
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
    'displayField': ?displayField,
    'source': ?source,
    'label': ?label,
    'required': ?required,
    'emptyLabel': ?emptyLabel,
    'emptyAction': ?emptyAction,
    'visibleWhen': ?visibleWhen,
  };

  static Json colorPicker({
    required String fieldKey,
    String? label,
    dynamic visibleWhen,
  }) => {
    'type': 'color_picker',
    'fieldKey': fieldKey,
    'label': ?label,
    'visibleWhen': ?visibleWhen,
  };
}
