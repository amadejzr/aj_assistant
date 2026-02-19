import 'package:equatable/equatable.dart';

import 'blueprint_action.dart';

/// Type-safe builder for blueprint JSON.
///
/// Each subclass corresponds to a widget type and produces valid JSON
/// via [toJson]. Use [RawBlueprint] for node types not yet covered.
sealed class Blueprint extends Equatable {
  const Blueprint();
  Map<String, dynamic> toJson();
}

// ─── Layout ───

class BpAppBar extends Blueprint {
  final String? title;
  final List<Blueprint> actions;
  final bool showBack;

  const BpAppBar({this.title, this.actions = const [], this.showBack = true});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'app_bar',
        if (title != null) 'title': title,
        if (actions.isNotEmpty)
          'actions': [for (final a in actions) a.toJson()],
        if (!showBack) 'showBack': false,
      };

  @override
  List<Object?> get props => [title, actions, showBack];
}

class BpScreen extends Blueprint {
  final String? title;
  final List<Blueprint> children;
  final BpFab? fab;
  final BpAppBar? appBar;

  const BpScreen({
    this.title,
    this.children = const [],
    this.fab,
    this.appBar,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'screen',
        if (title != null) 'title': title,
        'children': [for (final c in children) c.toJson()],
        if (fab != null) 'fab': fab!.toJson(),
        if (appBar != null) 'appBar': appBar!.toJson(),
      };

  @override
  List<Object?> get props => [title, children, fab, appBar];
}

class BpFormScreen extends Blueprint {
  final String? title;
  final String submitLabel;
  final String? editLabel;
  final Map<String, dynamic> defaults;
  final List<Blueprint> children;

  const BpFormScreen({
    this.title,
    this.submitLabel = 'Save',
    this.editLabel,
    this.defaults = const {},
    this.children = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'form_screen',
        if (title != null) 'title': title,
        'submitLabel': submitLabel,
        if (editLabel != null) 'editLabel': editLabel,
        if (defaults.isNotEmpty) 'defaults': defaults,
        'children': [for (final c in children) c.toJson()],
      };

  @override
  List<Object?> get props => [title, submitLabel, editLabel, defaults, children];
}

class BpTabScreen extends Blueprint {
  final String? title;
  final List<BpTabDef> tabs;
  final BpFab? fab;
  final BpAppBar? appBar;

  const BpTabScreen({
    this.title,
    this.tabs = const [],
    this.fab,
    this.appBar,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tab_screen',
        if (title != null) 'title': title,
        'tabs': [for (final t in tabs) t.toJson()],
        if (fab != null) 'fab': fab!.toJson(),
        if (appBar != null) 'appBar': appBar!.toJson(),
      };

  @override
  List<Object?> get props => [title, tabs, fab, appBar];
}

class BpTabDef extends Equatable {
  final String label;
  final String? icon;
  final Blueprint content;

  const BpTabDef({required this.label, this.icon, required this.content});

  Map<String, dynamic> toJson() => {
        'label': label,
        if (icon != null) 'icon': icon,
        'content': content.toJson(),
      };

  @override
  List<Object?> get props => [label, icon, content];
}

class BpScrollColumn extends Blueprint {
  final List<Blueprint> children;

  const BpScrollColumn({this.children = const []});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'scroll_column',
        'children': [for (final c in children) c.toJson()],
      };

  @override
  List<Object?> get props => [children];
}

class BpSection extends Blueprint {
  final String? title;
  final List<Blueprint> children;

  const BpSection({this.title, this.children = const []});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'section',
        if (title != null) 'title': title,
        'children': [for (final c in children) c.toJson()],
      };

  @override
  List<Object?> get props => [title, children];
}

class BpRow extends Blueprint {
  final List<Blueprint> children;

  const BpRow({this.children = const []});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'row',
        'children': [for (final c in children) c.toJson()],
      };

  @override
  List<Object?> get props => [children];
}

class BpColumn extends Blueprint {
  final List<Blueprint> children;

  const BpColumn({this.children = const []});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'column',
        'children': [for (final c in children) c.toJson()],
      };

  @override
  List<Object?> get props => [children];
}

class BpExpandable extends Blueprint {
  final String? title;
  final List<Blueprint> children;
  final bool initiallyExpanded;

  const BpExpandable({
    this.title,
    this.children = const [],
    this.initiallyExpanded = false,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'expandable',
        if (title != null) 'title': title,
        'children': [for (final c in children) c.toJson()],
        if (initiallyExpanded) 'initiallyExpanded': true,
      };

  @override
  List<Object?> get props => [title, children, initiallyExpanded];
}

// ─── Conditional ───

class BpConditional extends Blueprint {
  final dynamic condition;
  final List<Blueprint> thenChildren;
  final List<Blueprint> elseChildren;

  const BpConditional({
    required this.condition,
    this.thenChildren = const [],
    this.elseChildren = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'conditional',
        'condition': condition,
        'then': [for (final c in thenChildren) c.toJson()],
        if (elseChildren.isNotEmpty)
          'else': [for (final c in elseChildren) c.toJson()],
      };

  @override
  List<Object?> get props => [condition, thenChildren, elseChildren];
}

// ─── Actions ───

class BpFab extends Blueprint {
  final String icon;
  final BlueprintAction action;

  const BpFab({required this.icon, required this.action});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'fab',
        'icon': icon,
        'action': action.toJson(),
      };

  @override
  List<Object?> get props => [icon, action];
}

class BpButton extends Blueprint {
  final String label;
  final BlueprintAction action;
  final String? style;
  final String? icon;

  const BpButton({
    required this.label,
    required this.action,
    this.style,
    this.icon,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'button',
        'label': label,
        'action': action.toJson(),
        if (style != null) 'style': style,
        if (icon != null) 'icon': icon,
      };

  @override
  List<Object?> get props => [label, action, style, icon];
}

// ─── Inputs ───

class BpTextInput extends Blueprint {
  final String fieldKey;
  final bool multiline;

  const BpTextInput({required this.fieldKey, this.multiline = false});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text_input',
        'fieldKey': fieldKey,
        if (multiline) 'multiline': true,
      };

  @override
  List<Object?> get props => [fieldKey, multiline];
}

class BpNumberInput extends Blueprint {
  final String fieldKey;

  const BpNumberInput({required this.fieldKey});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'number_input',
        'fieldKey': fieldKey,
      };

  @override
  List<Object?> get props => [fieldKey];
}

class BpCurrencyInput extends Blueprint {
  final String fieldKey;
  final String currencySymbol;
  final int decimalPlaces;

  const BpCurrencyInput({
    required this.fieldKey,
    this.currencySymbol = '\$',
    this.decimalPlaces = 2,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'currency_input',
        'fieldKey': fieldKey,
        if (currencySymbol != '\$') 'currencySymbol': currencySymbol,
        if (decimalPlaces != 2) 'decimalPlaces': decimalPlaces,
      };

  @override
  List<Object?> get props => [fieldKey, currencySymbol, decimalPlaces];
}

class BpDatePicker extends Blueprint {
  final String fieldKey;

  const BpDatePicker({required this.fieldKey});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'date_picker',
        'fieldKey': fieldKey,
      };

  @override
  List<Object?> get props => [fieldKey];
}

class BpTimePicker extends Blueprint {
  final String fieldKey;

  const BpTimePicker({required this.fieldKey});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'time_picker',
        'fieldKey': fieldKey,
      };

  @override
  List<Object?> get props => [fieldKey];
}

class BpEnumSelector extends Blueprint {
  final String fieldKey;

  const BpEnumSelector({required this.fieldKey});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'enum_selector',
        'fieldKey': fieldKey,
      };

  @override
  List<Object?> get props => [fieldKey];
}

class BpMultiEnumSelector extends Blueprint {
  final String fieldKey;

  const BpMultiEnumSelector({required this.fieldKey});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'multi_enum_selector',
        'fieldKey': fieldKey,
      };

  @override
  List<Object?> get props => [fieldKey];
}

class BpToggle extends Blueprint {
  final String fieldKey;

  const BpToggle({required this.fieldKey});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'toggle',
        'fieldKey': fieldKey,
      };

  @override
  List<Object?> get props => [fieldKey];
}

class BpSlider extends Blueprint {
  final String fieldKey;

  const BpSlider({required this.fieldKey});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'slider',
        'fieldKey': fieldKey,
      };

  @override
  List<Object?> get props => [fieldKey];
}

class BpRatingInput extends Blueprint {
  final String fieldKey;

  const BpRatingInput({required this.fieldKey});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'rating_input',
        'fieldKey': fieldKey,
      };

  @override
  List<Object?> get props => [fieldKey];
}

class BpReferencePicker extends Blueprint {
  final String fieldKey;
  final String schemaKey;
  final String displayField;

  const BpReferencePicker({
    required this.fieldKey,
    required this.schemaKey,
    this.displayField = 'name',
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'reference_picker',
        'fieldKey': fieldKey,
        'schemaKey': schemaKey,
        if (displayField != 'name') 'displayField': displayField,
      };

  @override
  List<Object?> get props => [fieldKey, schemaKey, displayField];
}

// ─── Supporting types ───

class BpFilter extends Equatable {
  final String field;
  final String op;
  final dynamic value;

  const BpFilter({required this.field, this.op = '==', required this.value});

  Map<String, dynamic> toJson() => {
        'field': field,
        'op': op,
        'value': value,
      };

  @override
  List<Object?> get props => [field, op, value];
}

class BpQuery extends Equatable {
  final String? orderBy;
  final String direction;
  final int? limit;

  const BpQuery({this.orderBy, this.direction = 'desc', this.limit});

  Map<String, dynamic> toJson() => {
        if (orderBy != null) 'orderBy': orderBy,
        'direction': direction,
        if (limit != null) 'limit': limit,
      };

  @override
  List<Object?> get props => [orderBy, direction, limit];
}

class BpSwipeActions extends Equatable {
  final BlueprintAction? left;
  final BlueprintAction? right;

  const BpSwipeActions({this.left, this.right});

  Map<String, dynamic> toJson() => {
        if (left != null) 'left': left!.toJson(),
        if (right != null) 'right': right!.toJson(),
      };

  @override
  List<Object?> get props => [left, right];
}

// ─── Display ───

class BpStatCard extends Blueprint {
  final String label;
  final String expression;
  final String? format;
  final List<BpFilter> filter;

  const BpStatCard({
    required this.label,
    required this.expression,
    this.format,
    this.filter = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'stat_card',
        'label': label,
        'expression': expression,
        if (format != null) 'format': format,
        if (filter.isNotEmpty) 'filter': [for (final f in filter) f.toJson()],
      };

  @override
  List<Object?> get props => [label, expression, format, filter];
}

class BpEntryList extends Blueprint {
  final BpQuery? query;
  final List<BpFilter> filter;
  final BpEntryCard? itemLayout;

  const BpEntryList({this.query, this.filter = const [], this.itemLayout});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'entry_list',
        if (query != null) 'query': query!.toJson(),
        if (filter.isNotEmpty) 'filter': [for (final f in filter) f.toJson()],
        if (itemLayout != null) 'itemLayout': itemLayout!.toJson(),
      };

  @override
  List<Object?> get props => [query, filter, itemLayout];
}

class BpEntryCard extends Blueprint {
  final String? title;
  final String? subtitle;
  final String? trailing;
  final String? trailingFormat;
  final BlueprintAction? onTap;
  final BpSwipeActions? swipeActions;

  const BpEntryCard({
    this.title,
    this.subtitle,
    this.trailing,
    this.trailingFormat,
    this.onTap,
    this.swipeActions,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'entry_card',
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (trailing != null) 'trailing': trailing,
        if (trailingFormat != null) 'trailingFormat': trailingFormat,
        if (onTap != null) 'onTap': onTap!.toJson(),
        if (swipeActions != null) 'swipeActions': swipeActions!.toJson(),
      };

  @override
  List<Object?> get props =>
      [title, subtitle, trailing, trailingFormat, onTap, swipeActions];
}

class BpChart extends Blueprint {
  final String chartType;
  final String? groupBy;
  final String? aggregate;
  final String? expression;
  final List<BpFilter> filter;

  const BpChart({
    this.chartType = 'donut',
    this.groupBy,
    this.aggregate,
    this.expression,
    this.filter = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'chart',
        'chartType': chartType,
        if (groupBy != null) 'groupBy': groupBy,
        if (aggregate != null) 'aggregate': aggregate,
        if (expression != null) 'expression': expression,
        if (filter.isNotEmpty) 'filter': [for (final f in filter) f.toJson()],
      };

  @override
  List<Object?> get props => [chartType, groupBy, aggregate, expression, filter];
}

class BpProgressBar extends Blueprint {
  final String? label;
  final String? expression;
  final String? format;
  final List<BpFilter> filter;

  const BpProgressBar({
    this.label,
    this.expression,
    this.format,
    this.filter = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'progress_bar',
        if (label != null) 'label': label,
        if (expression != null) 'expression': expression,
        if (format != null) 'format': format,
        if (filter.isNotEmpty) 'filter': [for (final f in filter) f.toJson()],
      };

  @override
  List<Object?> get props => [label, expression, format, filter];
}

class BpDateCalendar extends Blueprint {
  final String dateField;
  final List<BpFilter> filter;
  final BlueprintAction? onEntryTap;
  final List<String> forwardFields;

  const BpDateCalendar({
    this.dateField = 'date',
    this.filter = const [],
    this.onEntryTap,
    this.forwardFields = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'date_calendar',
        'dateField': dateField,
        if (filter.isNotEmpty) 'filter': [for (final f in filter) f.toJson()],
        if (onEntryTap != null) 'onEntryTap': onEntryTap!.toJson(),
        if (forwardFields.isNotEmpty) 'forwardFields': forwardFields,
      };

  @override
  List<Object?> get props => [dateField, filter, onEntryTap, forwardFields];
}

class BpTextDisplay extends Blueprint {
  final String text;
  final String? style;

  const BpTextDisplay({required this.text, this.style});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text_display',
        'text': text,
        if (style != null) 'style': style,
      };

  @override
  List<Object?> get props => [text, style];
}

class BpEmptyState extends Blueprint {
  final String? icon;
  final String? title;
  final String? subtitle;

  const BpEmptyState({this.icon, this.title, this.subtitle});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'empty_state',
        if (icon != null) 'icon': icon,
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
      };

  @override
  List<Object?> get props => [icon, title, subtitle];
}

class BpBadge extends Blueprint {
  final String text;
  final String? expression;
  final String variant;

  const BpBadge({
    required this.text,
    this.expression,
    this.variant = 'default',
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'badge',
        'text': text,
        if (expression != null) 'expression': expression,
        if (variant != 'default') 'variant': variant,
      };

  @override
  List<Object?> get props => [text, expression, variant];
}

class BpCardGrid extends Blueprint {
  final String fieldKey;
  final BlueprintAction? action;

  const BpCardGrid({required this.fieldKey, this.action});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'card_grid',
        'fieldKey': fieldKey,
        if (action != null) 'action': action!.toJson(),
      };

  @override
  List<Object?> get props => [fieldKey, action];
}

class BpDivider extends Blueprint {
  const BpDivider();

  @override
  Map<String, dynamic> toJson() => {'type': 'divider'};

  @override
  List<Object?> get props => [];
}

class BpIconButton extends Blueprint {
  final String icon;
  final BlueprintAction action;
  final String? tooltip;

  const BpIconButton({
    required this.icon,
    required this.action,
    this.tooltip,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'icon_button',
        'icon': icon,
        'action': action.toJson(),
        if (tooltip != null) 'tooltip': tooltip,
      };

  @override
  List<Object?> get props => [icon, action, tooltip];
}

class BpActionMenu extends Blueprint {
  final String icon;
  final List<BpActionMenuItem> items;

  const BpActionMenu({
    this.icon = 'more_vert',
    this.items = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'action_menu',
        'icon': icon,
        'items': [for (final item in items) item.toJson()],
      };

  @override
  List<Object?> get props => [icon, items];
}

class BpActionMenuItem extends Equatable {
  final String label;
  final String? icon;
  final BlueprintAction action;

  const BpActionMenuItem({
    required this.label,
    this.icon,
    required this.action,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        if (icon != null) 'icon': icon,
        'action': action.toJson(),
      };

  @override
  List<Object?> get props => [label, icon, action];
}

// ─── Escape hatch ───

/// Wraps raw JSON for node types not yet covered by typed builders.
class RawBlueprint extends Blueprint {
  final Map<String, dynamic> json;
  const RawBlueprint(this.json);

  @override
  Map<String, dynamic> toJson() => json;

  @override
  List<Object?> get props => [json];
}
