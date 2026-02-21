import 'blueprint_node.dart';

class BlueprintParser {
  final Map<String, List<Map<String, dynamic>>> fieldSets;

  const BlueprintParser({this.fieldSets = const {}});

  BlueprintNode parse(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    final properties = Map<String, dynamic>.from(json);

    return switch (type) {
      'screen' => _parseScreen(properties),
      'tab_screen' => _parseTabScreen(properties),
      'form_screen' => _parseFormScreen(properties),
      'scroll_column' => _parseScrollColumn(properties),
      'section' => _parseSection(properties),
      'column' => _parseColumn(properties),
      'row' => _parseRow(properties),
      'text_input' => _parseTextInput(properties),
      'number_input' => _parseNumberInput(properties),
      'date_picker' => _parseDatePicker(properties),
      'time_picker' => _parseTimePicker(properties),
      'enum_selector' => _parseEnumSelector(properties),
      'multi_enum_selector' => _parseMultiEnumSelector(properties),
      'toggle' => _parseToggle(properties),
      'slider' => _parseSlider(properties),
      'rating_input' => _parseRatingInput(properties),
      'duration_picker' => _parseNumberInput(properties),
      'stat_card' => _parseStatCard(properties),
      'entry_list' => _parseEntryList(properties),
      'entry_card' => _parseEntryCard(properties),
      'text_display' => _parseTextDisplay(properties),
      'empty_state' => _parseEmptyState(properties),
      'button' => _parseButton(properties),
      'fab' => _parseFab(properties),
      'card_grid' => _parseCardGrid(properties),
      'date_calendar' => _parseDateCalendar(properties),
      'conditional' => _parseConditional(properties),
      'progress_bar' => _parseProgressBar(properties),
      'chart' => _parseChart(properties),
      'divider' => _parseDivider(properties),
      'reference_picker' => _parseReferencePicker(properties),
      'currency_input' => _parseCurrencyInput(properties),
      'icon_button' => _parseIconButton(properties),
      'action_menu' => _parseActionMenu(properties),
      'badge' => _parseBadge(properties),
      'expandable' => _parseExpandable(properties),
      _ => UnknownNode(type: type, properties: properties),
    };
  }

  List<BlueprintNode> _parseChildren(dynamic raw) {
    if (raw == null) return [];
    if (raw is! List) return [];

    final nodes = <BlueprintNode>[];
    for (final element in raw) {
      // $fieldSetName — expand from fieldSets map
      if (element is String && element.startsWith(r'$')) {
        final key = element.substring(1);
        final fields = fieldSets[key];
        if (fields != null) {
          for (final field in fields) {
            nodes.add(parse(Map<String, dynamic>.from(field)));
          }
        }
        continue;
      }
      if (element is Map<String, dynamic>) {
        nodes.add(parse(element));
      }
    }
    return nodes;
  }

  BlueprintNode? _parseChild(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) return null;
    return parse(raw);
  }

  AppBarNode? _parseAppBar(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) return null;
    return AppBarNode(
      title: raw['title'] as String?,
      actions: _parseChildren(raw['actions']),
      showBack: raw['showBack'] as bool? ?? true,
      properties: Map<String, dynamic>.from(raw),
    );
  }

  // ─── Layout ───

  ScreenNode _parseScreen(Map<String, dynamic> json) {
    final layout = json['layout'] as Map<String, dynamic>?;
    final children = layout != null ? [parse(layout)] : _parseChildren(json['children']);
    return ScreenNode(
      title: json['title'] as String?,
      children: children,
      fab: _parseChild(json['fab']),
      appBar: _parseAppBar(json['appBar']),
      properties: json,
    );
  }

  TabScreenNode _parseTabScreen(Map<String, dynamic> json) {
    final tabsRaw = json['tabs'] as List? ?? [];
    final tabs = tabsRaw.whereType<Map<String, dynamic>>().map((t) {
      return TabDef(
        label: t['label'] as String? ?? '',
        icon: t['icon'] as String?,
        content: parse(Map<String, dynamic>.from(t['content'] as Map? ?? {'type': 'column'})),
      );
    }).toList();

    return TabScreenNode(
      title: json['title'] as String?,
      tabs: tabs,
      fab: _parseChild(json['fab']),
      appBar: _parseAppBar(json['appBar']),
      properties: json,
    );
  }

  FormScreenNode _parseFormScreen(Map<String, dynamic> json) {
    final layout = json['layout'] as Map<String, dynamic>?;
    final children = layout != null ? [parse(layout)] : _parseChildren(json['children']);
    return FormScreenNode(
      title: json['title'] as String?,
      children: children,
      submitLabel: json['submitLabel'] as String? ?? 'Save',
      editLabel: json['editLabel'] as String?,
      submitAction: Map<String, dynamic>.from(
        json['submitAction'] as Map? ?? {},
      ),
      defaults: Map<String, dynamic>.from(json['defaults'] as Map? ?? {}),
      nav: _parseChild(json['nav']),
      properties: json,
    );
  }

  ScrollColumnNode _parseScrollColumn(Map<String, dynamic> json) {
    return ScrollColumnNode(
      children: _parseChildren(json['children']),
      properties: json,
    );
  }

  SectionNode _parseSection(Map<String, dynamic> json) {
    return SectionNode(
      title: json['title'] as String?,
      children: _parseChildren(json['children']),
      properties: json,
    );
  }

  ColumnNode _parseColumn(Map<String, dynamic> json) {
    return ColumnNode(
      children: _parseChildren(json['children']),
      properties: json,
    );
  }

  RowNode _parseRow(Map<String, dynamic> json) {
    return RowNode(
      children: _parseChildren(json['children']),
      properties: json,
    );
  }

  // ─── Input ───

  TextInputNode _parseTextInput(Map<String, dynamic> json) {
    return TextInputNode(
      fieldKey: json['fieldKey'] as String? ?? '',
      multiline: json['multiline'] as bool? ?? false,
      properties: json,
    );
  }

  NumberInputNode _parseNumberInput(Map<String, dynamic> json) {
    return NumberInputNode(
      fieldKey: json['fieldKey'] as String? ?? '',
      properties: json,
    );
  }

  DatePickerNode _parseDatePicker(Map<String, dynamic> json) {
    return DatePickerNode(
      fieldKey: json['fieldKey'] as String? ?? '',
      properties: json,
    );
  }

  TimePickerNode _parseTimePicker(Map<String, dynamic> json) {
    return TimePickerNode(
      fieldKey: json['fieldKey'] as String? ?? '',
      properties: json,
    );
  }

  EnumSelectorNode _parseEnumSelector(Map<String, dynamic> json) {
    return EnumSelectorNode(
      fieldKey: json['fieldKey'] as String? ?? '',
      properties: json,
    );
  }

  EnumSelectorNode _parseMultiEnumSelector(Map<String, dynamic> json) {
    return EnumSelectorNode(
      fieldKey: json['fieldKey'] as String? ?? '',
      multiSelect: true,
      properties: json,
    );
  }

  ToggleNode _parseToggle(Map<String, dynamic> json) {
    return ToggleNode(
      fieldKey: json['fieldKey'] as String? ?? '',
      properties: json,
    );
  }

  SliderNode _parseSlider(Map<String, dynamic> json) {
    return SliderNode(
      fieldKey: json['fieldKey'] as String? ?? '',
      properties: json,
    );
  }

  RatingInputNode _parseRatingInput(Map<String, dynamic> json) {
    return RatingInputNode(
      fieldKey: json['fieldKey'] as String? ?? '',
      properties: json,
    );
  }

  // ─── Display ───

  StatCardNode _parseStatCard(Map<String, dynamic> json) {
    return StatCardNode(
      label: json['label'] as String? ?? '',
      stat: json['stat'] as String? ?? 'count',
      expression: json['expression'] as String?,
      format: json['format'] as String?,
      filter: json['filter'] ?? const <String, dynamic>{},
      properties: json,
    );
  }

  EntryListNode _parseEntryList(Map<String, dynamic> json) {
    return EntryListNode(
      query: Map<String, dynamic>.from(json['query'] as Map? ?? {}),
      filter: json['filter'] ?? const <String, dynamic>{},
      itemLayout: _parseChild(json['itemLayout']),
      title: json['title'] as String?,
      viewAllScreen: json['viewAllScreen'] as String?,
      pageSize: json['pageSize'] as int?,
      filters: (json['filters'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          const [],
      properties: json,
    );
  }

  EntryCardNode _parseEntryCard(Map<String, dynamic> json) {
    return EntryCardNode(
      titleTemplate: json['title'] as String?,
      subtitleTemplate: json['subtitle'] as String?,
      trailingTemplate: json['trailing'] as String?,
      trailingFormat: json['trailingFormat'] as String?,
      onTap: Map<String, dynamic>.from(json['onTap'] as Map? ?? {}),
      swipeActions: Map<String, dynamic>.from(
        json['swipeActions'] as Map? ?? {},
      ),
      properties: json,
    );
  }

  TextDisplayNode _parseTextDisplay(Map<String, dynamic> json) {
    return TextDisplayNode(
      text: json['text'] as String? ?? '',
      style: json['style'] as String?,
      properties: json,
    );
  }

  EmptyStateNode _parseEmptyState(Map<String, dynamic> json) {
    return EmptyStateNode(
      icon: json['icon'] as String?,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      properties: json,
    );
  }

  // ─── Action ───

  ButtonNode _parseButton(Map<String, dynamic> json) {
    return ButtonNode(
      label: json['label'] as String? ?? 'Button',
      action: Map<String, dynamic>.from(json['action'] as Map? ?? {}),
      buttonStyle: json['style'] as String?,
      properties: json,
    );
  }

  FabNode _parseFab(Map<String, dynamic> json) {
    return FabNode(
      icon: json['icon'] as String?,
      action: Map<String, dynamic>.from(json['action'] as Map? ?? {}),
      properties: json,
    );
  }

  // ─── Dynamic ───

  CardGridNode _parseCardGrid(Map<String, dynamic> json) {
    return CardGridNode(
      fieldKey: json['fieldKey'] as String? ?? '',
      action: Map<String, dynamic>.from(json['action'] as Map? ?? {}),
      properties: json,
    );
  }

  DateCalendarNode _parseDateCalendar(Map<String, dynamic> json) {
    return DateCalendarNode(
      dateField: json['dateField'] as String? ?? 'date',
      filter: json['filter'] ?? const <String, dynamic>{},
      onEntryTap: json['onEntryTap'] as Map<String, dynamic>?,
      forwardFields: List<String>.from(json['forwardFields'] as List? ?? []),
      properties: json,
    );
  }

  // ─── Conditional & New Types ───

  ConditionalNode _parseConditional(Map<String, dynamic> json) {
    return ConditionalNode(
      condition: json['condition'],
      thenChildren: _parseChildren(json['then']),
      elseChildren: _parseChildren(json['else']),
      properties: json,
    );
  }

  ProgressBarNode _parseProgressBar(Map<String, dynamic> json) {
    return ProgressBarNode(
      label: json['label'] as String?,
      expression: json['expression'] as String?,
      format: json['format'] as String?,
      filter: json['filter'],
      properties: json,
    );
  }

  ChartNode _parseChart(Map<String, dynamic> json) {
    return ChartNode(
      chartType: json['chartType'] as String? ?? 'donut',
      groupBy: json['groupBy'] as String?,
      aggregate: json['aggregate'] as String?,
      expression: json['expression'] as String?,
      filter: json['filter'],
      properties: json,
    );
  }

  DividerNode _parseDivider(Map<String, dynamic> json) {
    return DividerNode(properties: json);
  }

  // ─── Reference ───

  ReferencePickerNode _parseReferencePicker(Map<String, dynamic> json) {
    return ReferencePickerNode(
      fieldKey: json['fieldKey'] as String? ?? '',
      schemaKey: json['schemaKey'] as String? ?? '',
      displayField: json['displayField'] as String? ?? 'name',
      properties: json,
    );
  }

  // ─── New Builders ───

  CurrencyInputNode _parseCurrencyInput(Map<String, dynamic> json) {
    return CurrencyInputNode(
      fieldKey: json['fieldKey'] as String? ?? '',
      currencySymbol: json['currencySymbol'] as String? ?? '\$',
      decimalPlaces: json['decimalPlaces'] as int? ?? 2,
      properties: json,
    );
  }

  IconButtonNode _parseIconButton(Map<String, dynamic> json) {
    return IconButtonNode(
      icon: json['icon'] as String? ?? 'circle',
      action: Map<String, dynamic>.from(json['action'] as Map? ?? {}),
      tooltip: json['tooltip'] as String?,
      properties: json,
    );
  }

  ActionMenuNode _parseActionMenu(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return ActionMenuNode(
      icon: json['icon'] as String? ?? 'dots-three',
      items: items,
      properties: json,
    );
  }

  BadgeNode _parseBadge(Map<String, dynamic> json) {
    return BadgeNode(
      text: json['text'] as String? ?? '',
      expression: json['expression'] as String?,
      variant: json['variant'] as String? ?? 'default',
      properties: json,
    );
  }

  ExpandableNode _parseExpandable(Map<String, dynamic> json) {
    return ExpandableNode(
      title: json['title'] as String?,
      children: _parseChildren(json['children']),
      initiallyExpanded: json['initiallyExpanded'] as bool? ?? false,
      properties: json,
    );
  }
}
