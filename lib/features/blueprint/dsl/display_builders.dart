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
    if (format != null) 'format': format,
    if (source != null) 'source': source,
    if (valueKey != null) 'valueKey': valueKey,
    if (value != null) 'value': value,
    if (accent == true) 'accent': true,
    if (expression != null) 'expression': expression,
    if (filter != null) 'filter': filter,
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
    if (title != null) 'title': title,
    if (source != null) 'source': source,
    if (emptyState != null) 'emptyState': emptyState,
    if (itemLayout != null) 'itemLayout': itemLayout,
    if (pageSize != null) 'pageSize': pageSize,
    if (viewAllScreen != null) 'viewAllScreen': viewAllScreen,
    if (filters != null) 'filters': filters,
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
    if (title != null) 'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    if (trailing != null) 'trailing': trailing,
    if (trailingFormat != null) 'trailingFormat': trailingFormat,
    if (onTap != null) 'onTap': onTap,
    if (swipeActions != null) 'swipeActions': swipeActions,
  };

  static Json textDisplay({
    String? label,
    String? value,
    String? text,
    String? style,
  }) => {
    'type': 'text_display',
    if (label != null) 'label': label,
    if (value != null) 'value': value,
    if (text != null) 'text': text,
    if (style != null) 'style': style,
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
    if (label != null) 'label': label,
    if (value != null) 'value': value,
    if (max != null) 'max': max,
    if (expression != null) 'expression': expression,
    if (format != null) 'format': format,
    if (source != null) 'source': source,
    if (valueKey != null) 'valueKey': valueKey,
    if (maxKey != null) 'maxKey': maxKey,
    if (color != null) 'color': color,
    if (showPercentage != null) 'showPercentage': showPercentage,
    if (filter != null) 'filter': filter,
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
    if (chartType != null) 'chartType': chartType,
    if (source != null) 'source': source,
    if (groupBy != null) 'groupBy': groupBy,
    if (valueField != null) 'valueField': valueField,
    if (aggregate != null) 'aggregate': aggregate,
    if (expression != null) 'expression': expression,
    if (title != null) 'title': title,
    if (height != null) 'height': height,
    if (filter != null) 'filter': filter,
  };

  static Json emptyState({
    String? message,
    String? icon,
    Json? action,
  }) => {
    'type': 'empty_state',
    if (message != null) 'message': message,
    if (icon != null) 'icon': icon,
    if (action != null) 'action': action,
  };

  static Json badge({
    required String text,
    String? expression,
    String? variant,
  }) => {
    'type': 'badge',
    'text': text,
    if (expression != null) 'expression': expression,
    if (variant != null) 'variant': variant,
  };

  static Json cardGrid({
    required String fieldKey,
    Json? action,
    List<String>? options,
    String? source,
  }) => {
    'type': 'card_grid',
    'fieldKey': fieldKey,
    if (action != null) 'action': action,
    if (options != null) 'options': options,
    if (source != null) 'source': source,
  };

  static Json dateCalendar({
    String? dateField,
    String? source,
    Json? onEntryTap,
    List<String>? forwardFields,
    dynamic filter,
  }) => {
    'type': 'date_calendar',
    if (dateField != null) 'dateField': dateField,
    if (source != null) 'source': source,
    if (onEntryTap != null) 'onEntryTap': onEntryTap,
    if (forwardFields != null) 'forwardFields': forwardFields,
    if (filter != null) 'filter': filter,
  };

  static Json divider() => {'type': 'divider'};

  static Json spacer({double? height}) => {
    'type': 'spacer',
    if (height != null) 'height': height,
  };
}
