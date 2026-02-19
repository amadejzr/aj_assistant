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
