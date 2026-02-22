import 'action_builders.dart';

/// Static builders for display widgets.
///
/// Key: stat_card properties (source, valueKey, accent) are at the top level,
/// NOT nested in a `properties` sub-map.
class Display {
  Display._();

  static Json statCard({
    required String label,
    String stat = 'custom',
    String? format,
    String? source,
    String? valueKey,
    String? value,
    bool? accent,
    String? expression,
    dynamic filter,
  }) => {
    'type': 'stat_card',
    'label': label,
    'stat': stat,
    'format': ?format,
    'source': ?source,
    'valueKey': ?valueKey,
    'value': ?value,
    if (accent == true) 'accent': true,
    'expression': ?expression,
    'filter': ?filter,
  };

  static Json entryList({
    String? title,
    String? source,
    Json? emptyState,
    Json? itemLayout,
    int? pageSize,
    String? viewAllScreen,
    List<Json>? filters,
  }) => {
    'type': 'entry_list',
    'title': ?title,
    'source': ?source,
    'emptyState': ?emptyState,
    'itemLayout': ?itemLayout,
    'pageSize': ?pageSize,
    'viewAllScreen': ?viewAllScreen,
    'filters': ?filters,
  };

  static Json entryCard({
    String? title,
    String? subtitle,
    String? trailing,
    String? trailingFormat,
    Json? onTap,
    Map<String, dynamic>? swipeActions,
  }) => {
    'type': 'entry_card',
    'title': ?title,
    'subtitle': ?subtitle,
    'trailing': ?trailing,
    'trailingFormat': ?trailingFormat,
    'onTap': ?onTap,
    'swipeActions': ?swipeActions,
  };

  static Json textDisplay({
    String? label,
    String? value,
    String? text,
    String? style,
  }) => {
    'type': 'text_display',
    'label': ?label,
    'value': ?value,
    'text': ?text,
    'style': ?style,
  };

  static Json progressBar({
    String? label,
    String? value,
    String? max,
    String? expression,
    String? format,
    String? source,
    String? valueKey,
    String? maxKey,
    String? color,
    bool? showPercentage,
    dynamic filter,
  }) => {
    'type': 'progress_bar',
    'label': ?label,
    'value': ?value,
    'max': ?max,
    'expression': ?expression,
    'format': ?format,
    'source': ?source,
    'valueKey': ?valueKey,
    'maxKey': ?maxKey,
    'color': ?color,
    'showPercentage': ?showPercentage,
    'filter': ?filter,
  };

  static Json chart({
    String? chartType,
    String? source,
    String? groupBy,
    String? valueField,
    String? aggregate,
    String? expression,
    String? title,
    double? height,
    dynamic filter,
  }) => {
    'type': 'chart',
    'chartType': ?chartType,
    'source': ?source,
    'groupBy': ?groupBy,
    'valueField': ?valueField,
    'aggregate': ?aggregate,
    'expression': ?expression,
    'title': ?title,
    'height': ?height,
    'filter': ?filter,
  };

  static Json emptyState({
    String? message,
    String? icon,
    Json? action,
  }) => {
    'type': 'empty_state',
    'message': ?message,
    'icon': ?icon,
    'action': ?action,
  };

  static Json badge({
    required String text,
    String? expression,
    String? variant,
  }) => {
    'type': 'badge',
    'text': text,
    'expression': ?expression,
    'variant': ?variant,
  };

  static Json cardGrid({
    required String fieldKey,
    Json? action,
    List<String>? options,
    String? source,
  }) => {
    'type': 'card_grid',
    'fieldKey': fieldKey,
    'action': ?action,
    'options': ?options,
    'source': ?source,
  };

  static Json dateCalendar({
    String? dateField,
    String? source,
    Json? onEntryTap,
    List<String>? forwardFields,
    dynamic filter,
  }) => {
    'type': 'date_calendar',
    'dateField': ?dateField,
    'source': ?source,
    'onEntryTap': ?onEntryTap,
    'forwardFields': ?forwardFields,
    'filter': ?filter,
  };

  static Json divider() => {'type': 'divider'};

  static Json spacer({double? height}) => {
    'type': 'spacer',
    'height': ?height,
  };
}
