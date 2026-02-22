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
    'title': ?title,
    'appBar': ?appBar,
    'queries': ?queries,
    'mutations': ?mutations,
    'children': ?children,
    'fab': ?fab,
    'appBarActions': ?appBarActions,
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
    'title': ?title,
    'submitLabel': ?submitLabel,
    'editLabel': ?editLabel,
    'defaults': ?defaults,
    'queries': ?queries,
    'mutations': ?mutations,
    'children': ?children,
  };

  static Json tabScreen({
    String? title,
    Json? appBar,
    Map<String, Json>? queries,
    List<Json>? tabs,
    Json? fab,
  }) => {
    'type': 'tab_screen',
    'title': ?title,
    'appBar': ?appBar,
    'queries': ?queries,
    'tabs': ?tabs,
    'fab': ?fab,
  };

  static Json scrollColumn({List<Json>? children}) => {
    'type': 'scroll_column',
    'children': ?children,
  };

  static Json row({List<Json>? children}) => {
    'type': 'row',
    'children': ?children,
  };

  static Json column({List<Json>? children}) => {
    'type': 'column',
    'children': ?children,
  };

  static Json section({String? title, List<Json>? children}) => {
    'type': 'section',
    'title': ?title,
    'children': ?children,
  };

  static Json expandable({
    String? title,
    bool? initiallyExpanded,
    List<Json>? children,
  }) => {
    'type': 'expandable',
    'title': ?title,
    'initiallyExpanded': ?initiallyExpanded,
    'children': ?children,
  };

  static Json conditional({
    required dynamic condition,
    List<Json>? thenChildren,
    List<Json>? elseChildren,
  }) => {
    'type': 'conditional',
    'condition': condition,
    'then': ?thenChildren,
    'else': ?elseChildren,
  };

  static Json appBar({
    String? title,
    bool? showBack,
    List<Json>? actions,
  }) => {
    'type': 'app_bar',
    'title': ?title,
    'showBack': ?showBack,
    'actions': ?actions,
  };
}
