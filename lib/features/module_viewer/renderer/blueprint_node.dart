import 'package:equatable/equatable.dart';

/// Base sealed class for all blueprint nodes.
sealed class BlueprintNode extends Equatable {
  final String type;
  final Map<String, dynamic> properties;

  const BlueprintNode({required this.type, this.properties = const {}});

  @override
  List<Object?> get props => [type, properties];
}

// ─── Layout Nodes ───

class ScreenNode extends BlueprintNode {
  final String? title;
  final List<BlueprintNode> children;
  final BlueprintNode? fab;

  const ScreenNode({
    this.title,
    this.children = const [],
    this.fab,
    super.properties,
  }) : super(type: 'screen');
}

class FormScreenNode extends BlueprintNode {
  final String? title;
  final List<BlueprintNode> children;
  final String submitLabel;
  final String? editLabel;
  final Map<String, dynamic> submitAction;
  final Map<String, dynamic> defaults;
  final BlueprintNode? nav;

  const FormScreenNode({
    this.title,
    this.children = const [],
    this.submitLabel = 'Save',
    this.editLabel,
    this.submitAction = const {},
    this.defaults = const {},
    this.nav,
    super.properties,
  }) : super(type: 'form_screen');
}

class ScrollColumnNode extends BlueprintNode {
  final List<BlueprintNode> children;

  const ScrollColumnNode({
    this.children = const [],
    super.properties,
  }) : super(type: 'scroll_column');
}

class SectionNode extends BlueprintNode {
  final String? title;
  final List<BlueprintNode> children;

  const SectionNode({
    this.title,
    this.children = const [],
    super.properties,
  }) : super(type: 'section');
}

class ColumnNode extends BlueprintNode {
  final List<BlueprintNode> children;

  const ColumnNode({
    this.children = const [],
    super.properties,
  }) : super(type: 'column');
}

class RowNode extends BlueprintNode {
  final List<BlueprintNode> children;

  const RowNode({
    this.children = const [],
    super.properties,
  }) : super(type: 'row');
}

class TabScreenNode extends BlueprintNode {
  final String? title;
  final List<TabDef> tabs;
  final BlueprintNode? fab;

  const TabScreenNode({
    this.title,
    this.tabs = const [],
    this.fab,
    super.properties,
  }) : super(type: 'tab_screen');
}

class TabDef {
  final String label;
  final String? icon;
  final BlueprintNode content;

  const TabDef({
    required this.label,
    this.icon,
    required this.content,
  });
}

// ─── Input Nodes ───

class TextInputNode extends BlueprintNode {
  final String fieldKey;
  final bool multiline;

  const TextInputNode({
    required this.fieldKey,
    this.multiline = false,
    super.properties,
  }) : super(type: 'text_input');
}

class NumberInputNode extends BlueprintNode {
  final String fieldKey;

  const NumberInputNode({
    required this.fieldKey,
    super.properties,
  }) : super(type: 'number_input');
}

class DatePickerNode extends BlueprintNode {
  final String fieldKey;

  const DatePickerNode({
    required this.fieldKey,
    super.properties,
  }) : super(type: 'date_picker');
}

class TimePickerNode extends BlueprintNode {
  final String fieldKey;

  const TimePickerNode({
    required this.fieldKey,
    super.properties,
  }) : super(type: 'time_picker');
}

class EnumSelectorNode extends BlueprintNode {
  final String fieldKey;
  final bool multiSelect;

  const EnumSelectorNode({
    required this.fieldKey,
    this.multiSelect = false,
    super.properties,
  }) : super(type: 'enum_selector');
}

class ToggleNode extends BlueprintNode {
  final String fieldKey;

  const ToggleNode({
    required this.fieldKey,
    super.properties,
  }) : super(type: 'toggle');
}

class SliderNode extends BlueprintNode {
  final String fieldKey;

  const SliderNode({
    required this.fieldKey,
    super.properties,
  }) : super(type: 'slider');
}

class RatingInputNode extends BlueprintNode {
  final String fieldKey;

  const RatingInputNode({
    required this.fieldKey,
    super.properties,
  }) : super(type: 'rating_input');
}

// ─── Display Nodes ───

class EntryListNode extends BlueprintNode {
  final Map<String, dynamic> query;
  final dynamic filter;
  final BlueprintNode? itemLayout;

  const EntryListNode({
    this.query = const {},
    this.filter = const {},
    this.itemLayout,
    super.properties,
  }) : super(type: 'entry_list');
}

class EntryCardNode extends BlueprintNode {
  final String? titleTemplate;
  final String? subtitleTemplate;
  final String? trailingTemplate;
  final String? trailingFormat;
  final Map<String, dynamic> onTap;
  final Map<String, dynamic> swipeActions;

  const EntryCardNode({
    this.titleTemplate,
    this.subtitleTemplate,
    this.trailingTemplate,
    this.trailingFormat,
    this.onTap = const {},
    this.swipeActions = const {},
    super.properties,
  }) : super(type: 'entry_card');
}

class TextDisplayNode extends BlueprintNode {
  final String text;
  final String? style;

  const TextDisplayNode({
    required this.text,
    this.style,
    super.properties,
  }) : super(type: 'text_display');
}

class EmptyStateNode extends BlueprintNode {
  final String? icon;
  final String? title;
  final String? subtitle;

  const EmptyStateNode({
    this.icon,
    this.title,
    this.subtitle,
    super.properties,
  }) : super(type: 'empty_state');
}

class StatCardNode extends BlueprintNode {
  final String label;
  final String stat;
  final String? expression;
  final String? format;
  final dynamic filter;

  const StatCardNode({
    required this.label,
    required this.stat,
    this.expression,
    this.format,
    this.filter = const {},
    super.properties,
  }) : super(type: 'stat_card');
}

// ─── Action Nodes ───

class ButtonNode extends BlueprintNode {
  final String label;
  final Map<String, dynamic> action;
  final String? buttonStyle;

  const ButtonNode({
    required this.label,
    this.action = const {},
    this.buttonStyle,
    super.properties,
  }) : super(type: 'button');
}

class FabNode extends BlueprintNode {
  final String? icon;
  final Map<String, dynamic> action;

  const FabNode({
    this.icon,
    this.action = const {},
    super.properties,
  }) : super(type: 'fab');
}

// ─── Dynamic Nodes ───

class CardGridNode extends BlueprintNode {
  final String fieldKey;
  final Map<String, dynamic> action;

  const CardGridNode({
    required this.fieldKey,
    this.action = const {},
    super.properties,
  }) : super(type: 'card_grid');
}

class DateCalendarNode extends BlueprintNode {
  final String dateField;
  final dynamic filter;

  const DateCalendarNode({
    this.dateField = 'date',
    this.filter = const {},
    super.properties,
  }) : super(type: 'date_calendar');
}

// ─── Conditional ───

class ConditionalNode extends BlueprintNode {
  final dynamic condition;
  final List<BlueprintNode> thenChildren;
  final List<BlueprintNode> elseChildren;

  const ConditionalNode({
    required this.condition,
    this.thenChildren = const [],
    this.elseChildren = const [],
    super.properties,
  }) : super(type: 'conditional');
}

// ─── Progress & Charts ───

class ProgressBarNode extends BlueprintNode {
  final String? label;
  final String? expression;
  final String? format;

  const ProgressBarNode({
    this.label,
    this.expression,
    this.format,
    super.properties,
  }) : super(type: 'progress_bar');
}

class ChartNode extends BlueprintNode {
  final String chartType;
  final String? groupBy;
  final String? aggregate;
  final dynamic filter;

  const ChartNode({
    this.chartType = 'donut',
    this.groupBy,
    this.aggregate,
    this.filter,
    super.properties,
  }) : super(type: 'chart');
}

class DividerNode extends BlueprintNode {
  const DividerNode({super.properties}) : super(type: 'divider');
}

// ─── Fallback ───

class UnknownNode extends BlueprintNode {
  const UnknownNode({required super.type, super.properties});
}
