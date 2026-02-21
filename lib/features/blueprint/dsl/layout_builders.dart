import 'action_builders.dart';

/// Static builders for layout widgets.
class Layout {
  Layout._();

  static Json screen({
    String? title,
    Json? appBar,
    Map<String, Json>? queries,
    Map<String, dynamic>? mutations,
    List<Json>? children,
    Json? fab,
    List<Json>? appBarActions,
  }) => {
    'type': 'screen',
    if (title != null) 'title': title,
    if (appBar != null) 'appBar': appBar,
    if (queries != null) 'queries': queries,
    if (mutations != null) 'mutations': mutations,
    if (children != null) 'children': children,
    if (fab != null) 'fab': fab,
    if (appBarActions != null) 'appBarActions': appBarActions,
  };

  static Json formScreen({
    String? title,
    String? submitLabel,
    String? editLabel,
    Map<String, dynamic>? defaults,
    Map<String, Json>? queries,
    Map<String, dynamic>? mutations,
    List<Json>? children,
  }) => {
    'type': 'form_screen',
    if (title != null) 'title': title,
    if (submitLabel != null) 'submitLabel': submitLabel,
    if (editLabel != null) 'editLabel': editLabel,
    if (defaults != null) 'defaults': defaults,
    if (queries != null) 'queries': queries,
    if (mutations != null) 'mutations': mutations,
    if (children != null) 'children': children,
  };

  static Json tabScreen({
    String? title,
    Json? appBar,
    Map<String, Json>? queries,
    List<Json>? tabs,
    Json? fab,
  }) => {
    'type': 'tab_screen',
    if (title != null) 'title': title,
    if (appBar != null) 'appBar': appBar,
    if (queries != null) 'queries': queries,
    if (tabs != null) 'tabs': tabs,
    if (fab != null) 'fab': fab,
  };

  static Json scrollColumn({List<Json>? children}) => {
    'type': 'scroll_column',
    if (children != null) 'children': children,
  };

  static Json row({List<Json>? children}) => {
    'type': 'row',
    if (children != null) 'children': children,
  };

  static Json column({List<Json>? children}) => {
    'type': 'column',
    if (children != null) 'children': children,
  };

  static Json section({String? title, List<Json>? children}) => {
    'type': 'section',
    if (title != null) 'title': title,
    if (children != null) 'children': children,
  };

  static Json expandable({
    String? title,
    bool? initiallyExpanded,
    List<Json>? children,
  }) => {
    'type': 'expandable',
    if (title != null) 'title': title,
    if (initiallyExpanded != null) 'initiallyExpanded': initiallyExpanded,
    if (children != null) 'children': children,
  };

  static Json conditional({
    required dynamic condition,
    List<Json>? thenChildren,
    List<Json>? elseChildren,
  }) => {
    'type': 'conditional',
    'condition': condition,
    if (thenChildren != null) 'then': thenChildren,
    if (elseChildren != null) 'else': elseChildren,
  };

  static Json appBar({
    String? title,
    bool? showBack,
    List<Json>? actions,
  }) => {
    'type': 'app_bar',
    if (title != null) 'title': title,
    if (showBack != null) 'showBack': showBack,
    if (actions != null) 'actions': actions,
  };
}
