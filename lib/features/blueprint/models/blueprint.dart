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

class BpScreen extends Blueprint {
  final String? title;
  final List<Blueprint> children;
  final BpFab? fab;

  const BpScreen({this.title, this.children = const [], this.fab});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'screen',
        if (title != null) 'title': title,
        'children': [for (final c in children) c.toJson()],
        if (fab != null) 'fab': fab!.toJson(),
      };

  @override
  List<Object?> get props => [title, children, fab];
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

  const BpTabScreen({this.title, this.tabs = const [], this.fab});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tab_screen',
        if (title != null) 'title': title,
        'tabs': [for (final t in tabs) t.toJson()],
        if (fab != null) 'fab': fab!.toJson(),
      };

  @override
  List<Object?> get props => [title, tabs, fab];
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
