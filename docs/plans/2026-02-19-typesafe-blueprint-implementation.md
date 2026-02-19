# Type-Safe Blueprint Builders Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create sealed class hierarchies for type-safe blueprint JSON construction, plus a ModuleNavigation model for bottom nav and drawer.

**Architecture:** `Blueprint` sealed class with `toJson()` for layout nodes, `BlueprintAction` sealed class for actions, `ModuleNavigation` model on `Module`. Builders produce `Map<String, dynamic>` for Firestore storage. `RawBlueprint` escape hatch for uncovered node types.

**Tech Stack:** Dart, Equatable, Flutter test

---

### Task 1: BlueprintAction sealed class

**Files:**
- Create: `lib/features/blueprint/models/blueprint_action.dart`
- Create: `test/features/blueprint/models/blueprint_action_test.dart`

**Context:** Actions are used by buttons and FABs. They describe what happens on tap — navigate to screen, go back, submit form, delete entry, show form sheet. This is a dependency for the Blueprint builders (Task 2).

**Step 1: Create the sealed class**

```dart
// lib/features/blueprint/models/blueprint_action.dart
import 'package:equatable/equatable.dart';

/// Type-safe actions used by buttons, FABs, and other interactive nodes.
sealed class BlueprintAction extends Equatable {
  const BlueprintAction();
  Map<String, dynamic> toJson();

  static BlueprintAction fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'navigate' => NavigateAction.fromJson(json),
      'navigate_back' => const NavigateBackAction(),
      'submit' => const SubmitAction(),
      'delete_entry' => DeleteEntryAction.fromJson(json),
      'show_form_sheet' => ShowFormSheetAction.fromJson(json),
      _ => RawAction(json),
    };
  }
}

class NavigateAction extends BlueprintAction {
  final String screen;
  final Map<String, dynamic> params;
  final List<String> forwardFields;

  const NavigateAction({
    required this.screen,
    this.params = const {},
    this.forwardFields = const [],
  });

  factory NavigateAction.fromJson(Map<String, dynamic> json) {
    return NavigateAction(
      screen: json['screen'] as String? ?? '',
      params: Map<String, dynamic>.from(json['params'] as Map? ?? {}),
      forwardFields: List<String>.from(json['forwardFields'] as List? ?? []),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'navigate',
        'screen': screen,
        if (params.isNotEmpty) 'params': params,
        if (forwardFields.isNotEmpty) 'forwardFields': forwardFields,
      };

  @override
  List<Object?> get props => [screen, params, forwardFields];
}

class NavigateBackAction extends BlueprintAction {
  const NavigateBackAction();

  @override
  Map<String, dynamic> toJson() => {'type': 'navigate_back'};

  @override
  List<Object?> get props => [];
}

class SubmitAction extends BlueprintAction {
  const SubmitAction();

  @override
  Map<String, dynamic> toJson() => {'type': 'submit'};

  @override
  List<Object?> get props => [];
}

class DeleteEntryAction extends BlueprintAction {
  final bool confirm;
  final String? confirmMessage;

  const DeleteEntryAction({this.confirm = false, this.confirmMessage});

  factory DeleteEntryAction.fromJson(Map<String, dynamic> json) {
    return DeleteEntryAction(
      confirm: json['confirm'] as bool? ?? false,
      confirmMessage: json['confirmMessage'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'delete_entry',
        if (confirm) 'confirm': confirm,
        if (confirmMessage != null) 'confirmMessage': confirmMessage,
      };

  @override
  List<Object?> get props => [confirm, confirmMessage];
}

class ShowFormSheetAction extends BlueprintAction {
  final String screen;
  final String? title;

  const ShowFormSheetAction({required this.screen, this.title});

  factory ShowFormSheetAction.fromJson(Map<String, dynamic> json) {
    return ShowFormSheetAction(
      screen: json['screen'] as String? ?? '',
      title: json['title'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'show_form_sheet',
        'screen': screen,
        if (title != null) 'title': title,
      };

  @override
  List<Object?> get props => [screen, title];
}

/// Passthrough for unrecognized action types.
class RawAction extends BlueprintAction {
  final Map<String, dynamic> json;
  const RawAction(this.json);

  @override
  Map<String, dynamic> toJson() => json;

  @override
  List<Object?> get props => [json];
}
```

**Step 2: Write tests**

```dart
// test/features/blueprint/models/blueprint_action_test.dart
import 'package:aj_assistant/features/blueprint/models/blueprint_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NavigateAction', () {
    test('toJson with screen only', () {
      const action = NavigateAction(screen: 'add_entry');
      expect(action.toJson(), {'type': 'navigate', 'screen': 'add_entry'});
    });

    test('toJson with params and forwardFields', () {
      const action = NavigateAction(
        screen: 'edit_entry',
        params: {'_entryId': '123'},
        forwardFields: ['title', 'note'],
      );
      expect(action.toJson(), {
        'type': 'navigate',
        'screen': 'edit_entry',
        'params': {'_entryId': '123'},
        'forwardFields': ['title', 'note'],
      });
    });

    test('fromJson roundtrip', () {
      const original = NavigateAction(screen: 'main', params: {'tab': 0});
      final restored = BlueprintAction.fromJson(original.toJson());
      expect(restored, equals(original));
    });
  });

  group('NavigateBackAction', () {
    test('toJson', () {
      const action = NavigateBackAction();
      expect(action.toJson(), {'type': 'navigate_back'});
    });
  });

  group('SubmitAction', () {
    test('toJson', () {
      const action = SubmitAction();
      expect(action.toJson(), {'type': 'submit'});
    });
  });

  group('DeleteEntryAction', () {
    test('toJson with confirm', () {
      const action = DeleteEntryAction(confirm: true, confirmMessage: 'Delete this?');
      expect(action.toJson(), {
        'type': 'delete_entry',
        'confirm': true,
        'confirmMessage': 'Delete this?',
      });
    });

    test('toJson without confirm omits keys', () {
      const action = DeleteEntryAction();
      expect(action.toJson(), {'type': 'delete_entry'});
    });
  });

  group('ShowFormSheetAction', () {
    test('toJson', () {
      const action = ShowFormSheetAction(screen: 'quick_add', title: 'Quick Add');
      expect(action.toJson(), {
        'type': 'show_form_sheet',
        'screen': 'quick_add',
        'title': 'Quick Add',
      });
    });
  });

  group('RawAction', () {
    test('passes through unknown action JSON', () {
      final action = RawAction(const {'type': 'toast', 'message': 'hello'});
      expect(action.toJson(), {'type': 'toast', 'message': 'hello'});
    });
  });

  group('BlueprintAction.fromJson', () {
    test('unknown type becomes RawAction', () {
      final action = BlueprintAction.fromJson({'type': 'future_action', 'data': 1});
      expect(action, isA<RawAction>());
    });
  });
}
```

**Step 3: Run tests**

Run: `flutter test test/features/blueprint/models/blueprint_action_test.dart`
Expected: All tests pass.

**Step 4: Commit**

```bash
git add lib/features/blueprint/models/blueprint_action.dart test/features/blueprint/models/blueprint_action_test.dart
git commit -m "feat: add BlueprintAction sealed class with toJson/fromJson"
```

---

### Task 2: Blueprint sealed class (layout nodes)

**Files:**
- Create: `lib/features/blueprint/models/blueprint.dart`
- Create: `test/features/blueprint/models/blueprint_test.dart`

**Context:** These are the builder classes — the reverse of `BlueprintNode`. Each class represents a widget type and produces JSON via `toJson()`. Children are `List<Blueprint>` so only valid blueprints can be nested. `RawBlueprint` allows uncovered node types (inputs, displays) to be included as raw JSON.

**Step 1: Create the sealed class**

```dart
// lib/features/blueprint/models/blueprint.dart
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
  final String? style; // 'elevated', 'outlined', 'destructive'
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
```

**Step 2: Write tests**

```dart
// test/features/blueprint/models/blueprint_test.dart
import 'package:aj_assistant/features/blueprint/models/blueprint.dart';
import 'package:aj_assistant/features/blueprint/models/blueprint_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BpScreen', () {
    test('minimal screen', () {
      const screen = BpScreen(title: 'Home');
      expect(screen.toJson(), {
        'type': 'screen',
        'title': 'Home',
        'children': [],
      });
    });

    test('screen with children and fab', () {
      const screen = BpScreen(
        title: 'Tasks',
        children: [BpSection(title: 'Urgent')],
        fab: BpFab(icon: 'add', action: NavigateAction(screen: 'add')),
      );
      final json = screen.toJson();
      expect(json['type'], 'screen');
      expect(json['title'], 'Tasks');
      expect((json['children'] as List).length, 1);
      expect(json['fab']['icon'], 'add');
    });
  });

  group('BpFormScreen', () {
    test('form with defaults and children', () {
      const form = BpFormScreen(
        title: 'New Task',
        submitLabel: 'Save',
        defaults: {'status': 'todo'},
        children: [
          RawBlueprint({'type': 'text_input', 'fieldKey': 'title'}),
        ],
      );
      final json = form.toJson();
      expect(json['type'], 'form_screen');
      expect(json['title'], 'New Task');
      expect(json['submitLabel'], 'Save');
      expect(json['defaults'], {'status': 'todo'});
      expect((json['children'] as List).length, 1);
    });

    test('edit form with editLabel', () {
      const form = BpFormScreen(
        title: 'Edit Task',
        editLabel: 'Update',
      );
      expect(form.toJson()['editLabel'], 'Update');
    });
  });

  group('BpTabScreen', () {
    test('tab screen with two tabs', () {
      const tabs = BpTabScreen(
        title: 'Tasks',
        tabs: [
          BpTabDef(
            label: 'Active',
            icon: 'pending',
            content: BpScrollColumn(),
          ),
          BpTabDef(
            label: 'Done',
            icon: 'check',
            content: BpScrollColumn(),
          ),
        ],
        fab: BpFab(icon: 'add', action: NavigateAction(screen: 'add')),
      );
      final json = tabs.toJson();
      expect(json['type'], 'tab_screen');
      expect((json['tabs'] as List).length, 2);
      expect((json['tabs'] as List)[0]['label'], 'Active');
      expect(json['fab'], isNotNull);
    });
  });

  group('BpScrollColumn', () {
    test('empty scroll column', () {
      const col = BpScrollColumn();
      expect(col.toJson(), {'type': 'scroll_column', 'children': []});
    });
  });

  group('BpSection', () {
    test('section with title and children', () {
      const section = BpSection(
        title: 'Stats',
        children: [
          RawBlueprint({'type': 'stat_card', 'label': 'Total', 'expression': 'count()'}),
        ],
      );
      final json = section.toJson();
      expect(json['title'], 'Stats');
      expect((json['children'] as List).first['type'], 'stat_card');
    });
  });

  group('BpRow', () {
    test('row serializes children', () {
      const row = BpRow(children: [
        RawBlueprint({'type': 'stat_card', 'label': 'A'}),
        RawBlueprint({'type': 'stat_card', 'label': 'B'}),
      ]);
      expect((row.toJson()['children'] as List).length, 2);
    });
  });

  group('BpColumn', () {
    test('column serializes children', () {
      const col = BpColumn(children: [RawBlueprint({'type': 'divider'})]);
      expect((col.toJson()['children'] as List).length, 1);
    });
  });

  group('BpExpandable', () {
    test('expandable with initiallyExpanded', () {
      const exp = BpExpandable(
        title: 'Details',
        initiallyExpanded: true,
      );
      final json = exp.toJson();
      expect(json['type'], 'expandable');
      expect(json['title'], 'Details');
      expect(json['initiallyExpanded'], true);
    });

    test('initiallyExpanded false is omitted', () {
      const exp = BpExpandable(title: 'Details');
      expect(exp.toJson().containsKey('initiallyExpanded'), false);
    });
  });

  group('BpFab', () {
    test('fab with navigate action', () {
      const fab = BpFab(icon: 'add', action: NavigateAction(screen: 'form'));
      final json = fab.toJson();
      expect(json, {
        'type': 'fab',
        'icon': 'add',
        'action': {'type': 'navigate', 'screen': 'form'},
      });
    });
  });

  group('BpButton', () {
    test('button with style and action', () {
      const btn = BpButton(
        label: 'View Calendar',
        action: NavigateAction(screen: 'calendar'),
        style: 'outlined',
      );
      final json = btn.toJson();
      expect(json['type'], 'button');
      expect(json['label'], 'View Calendar');
      expect(json['style'], 'outlined');
      expect(json['action']['screen'], 'calendar');
    });
  });

  group('RawBlueprint', () {
    test('passes through arbitrary JSON', () {
      const raw = RawBlueprint({
        'type': 'chart',
        'chartType': 'donut',
        'expression': 'group(category, sum(amount))',
      });
      expect(raw.toJson()['type'], 'chart');
      expect(raw.toJson()['chartType'], 'donut');
    });
  });

  group('nested tree', () {
    test('complex nested structure serializes correctly', () {
      const tree = BpScreen(
        title: 'Finance',
        children: [
          BpScrollColumn(children: [
            BpRow(children: [
              RawBlueprint({'type': 'stat_card', 'label': 'Balance'}),
              RawBlueprint({'type': 'stat_card', 'label': 'Spent'}),
            ]),
            BpSection(
              title: 'Recent',
              children: [
                RawBlueprint({'type': 'entry_list', 'filter': []}),
              ],
            ),
          ]),
        ],
        fab: BpFab(icon: 'add', action: NavigateAction(screen: 'add_expense')),
      );

      final json = tree.toJson();
      expect(json['type'], 'screen');
      final scrollCol = (json['children'] as List).first as Map;
      expect(scrollCol['type'], 'scroll_column');
      final row = (scrollCol['children'] as List).first as Map;
      expect(row['type'], 'row');
      expect((row['children'] as List).length, 2);
    });
  });
}
```

**Step 3: Run tests**

Run: `flutter test test/features/blueprint/models/blueprint_test.dart`
Expected: All tests pass.

**Step 4: Commit**

```bash
git add lib/features/blueprint/models/blueprint.dart test/features/blueprint/models/blueprint_test.dart
git commit -m "feat: add Blueprint sealed class with layout builders and toJson"
```

---

### Task 3: ModuleNavigation model

**Files:**
- Create: `lib/features/blueprint/navigation/module_navigation.dart`
- Create: `test/features/blueprint/navigation/module_navigation_test.dart`

**Context:** Typed navigation config that lives on Module. Defines bottom nav items and drawer items, each pointing to a screen ID.

**Step 1: Create the model**

```dart
// lib/features/blueprint/navigation/module_navigation.dart
import 'package:equatable/equatable.dart';

/// Navigation configuration for a module.
///
/// When set on [Module], the module viewer renders bottom nav / drawer
/// instead of a flat screen stack.
class ModuleNavigation extends Equatable {
  final BottomNav? bottomNav;
  final DrawerNav? drawer;

  const ModuleNavigation({this.bottomNav, this.drawer});

  factory ModuleNavigation.fromJson(Map<String, dynamic> json) {
    return ModuleNavigation(
      bottomNav: json['bottomNav'] != null
          ? BottomNav.fromJson(Map<String, dynamic>.from(json['bottomNav'] as Map))
          : null,
      drawer: json['drawer'] != null
          ? DrawerNav.fromJson(Map<String, dynamic>.from(json['drawer'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (bottomNav != null) 'bottomNav': bottomNav!.toJson(),
        if (drawer != null) 'drawer': drawer!.toJson(),
      };

  @override
  List<Object?> get props => [bottomNav, drawer];
}

class BottomNav extends Equatable {
  final List<NavItem> items;

  const BottomNav({required this.items});

  factory BottomNav.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?)
            ?.map((e) => NavItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];
    return BottomNav(items: items);
  }

  Map<String, dynamic> toJson() => {
        'items': [for (final item in items) item.toJson()],
      };

  @override
  List<Object?> get props => [items];
}

class DrawerNav extends Equatable {
  final List<NavItem> items;
  final String? header;

  const DrawerNav({required this.items, this.header});

  factory DrawerNav.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?)
            ?.map((e) => NavItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];
    return DrawerNav(
      items: items,
      header: json['header'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': [for (final item in items) item.toJson()],
        if (header != null) 'header': header,
      };

  @override
  List<Object?> get props => [items, header];
}

class NavItem extends Equatable {
  final String label;
  final String icon;
  final String screenId;

  const NavItem({
    required this.label,
    required this.icon,
    required this.screenId,
  });

  factory NavItem.fromJson(Map<String, dynamic> json) {
    return NavItem(
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      screenId: json['screenId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'icon': icon,
        'screenId': screenId,
      };

  @override
  List<Object?> get props => [label, icon, screenId];
}
```

**Step 2: Write tests**

```dart
// test/features/blueprint/navigation/module_navigation_test.dart
import 'package:aj_assistant/features/blueprint/navigation/module_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NavItem', () {
    test('toJson / fromJson roundtrip', () {
      const item = NavItem(label: 'Home', icon: 'home', screenId: 'main');
      final restored = NavItem.fromJson(item.toJson());
      expect(restored, equals(item));
    });
  });

  group('BottomNav', () {
    test('toJson / fromJson roundtrip', () {
      const nav = BottomNav(items: [
        NavItem(label: 'Tasks', icon: 'check', screenId: 'main'),
        NavItem(label: 'Calendar', icon: 'calendar', screenId: 'calendar'),
      ]);
      final restored = BottomNav.fromJson(nav.toJson());
      expect(restored, equals(nav));
      expect(restored.items.length, 2);
    });
  });

  group('DrawerNav', () {
    test('toJson / fromJson roundtrip with header', () {
      const drawer = DrawerNav(
        header: 'Finance',
        items: [
          NavItem(label: 'Settings', icon: 'settings', screenId: 'settings'),
        ],
      );
      final restored = DrawerNav.fromJson(drawer.toJson());
      expect(restored, equals(drawer));
      expect(restored.header, 'Finance');
    });

    test('header is optional', () {
      const drawer = DrawerNav(items: [
        NavItem(label: 'Info', icon: 'info', screenId: 'info'),
      ]);
      final json = drawer.toJson();
      expect(json.containsKey('header'), false);
    });
  });

  group('ModuleNavigation', () {
    test('toJson / fromJson roundtrip with both', () {
      const nav = ModuleNavigation(
        bottomNav: BottomNav(items: [
          NavItem(label: 'Home', icon: 'home', screenId: 'main'),
          NavItem(label: 'Stats', icon: 'chart', screenId: 'stats'),
        ]),
        drawer: DrawerNav(
          header: 'My Module',
          items: [
            NavItem(label: 'Settings', icon: 'gear', screenId: 'settings'),
          ],
        ),
      );
      final restored = ModuleNavigation.fromJson(nav.toJson());
      expect(restored, equals(nav));
    });

    test('toJson / fromJson with bottomNav only', () {
      const nav = ModuleNavigation(
        bottomNav: BottomNav(items: [
          NavItem(label: 'Home', icon: 'home', screenId: 'main'),
        ]),
      );
      final json = nav.toJson();
      expect(json.containsKey('drawer'), false);
      final restored = ModuleNavigation.fromJson(json);
      expect(restored.drawer, isNull);
      expect(restored.bottomNav, isNotNull);
    });

    test('fromJson with empty map returns null fields', () {
      final nav = ModuleNavigation.fromJson({});
      expect(nav.bottomNav, isNull);
      expect(nav.drawer, isNull);
    });
  });
}
```

**Step 3: Run tests**

Run: `flutter test test/features/blueprint/navigation/module_navigation_test.dart`
Expected: All tests pass.

**Step 4: Commit**

```bash
git add lib/features/blueprint/navigation/module_navigation.dart test/features/blueprint/navigation/module_navigation_test.dart
git commit -m "feat: add ModuleNavigation model with BottomNav, DrawerNav, NavItem"
```

---

### Task 4: Add navigation to Module

**Files:**
- Modify: `lib/core/models/module.dart`
- Modify: `test/core/models/module_test.dart`

**Context:** Add optional `ModuleNavigation? navigation` field to `Module`. Update `fromFirestore`, `toFirestore`, `copyWith`, and `props`. Backward compatible — null when not present in Firestore.

**Step 1: Update Module**

In `lib/core/models/module.dart`:

1. Add import: `import '../../features/blueprint/navigation/module_navigation.dart';`
2. Add field: `final ModuleNavigation? navigation;`
3. Add to constructor: `this.navigation,`
4. Add to `copyWith`: `ModuleNavigation? navigation,` → `navigation: navigation ?? this.navigation,`
5. Add to `fromFirestore`: `navigation: data['navigation'] != null ? ModuleNavigation.fromJson(Map<String, dynamic>.from(data['navigation'] as Map)) : null,`
6. Add to `toFirestore`: `if (navigation != null) 'navigation': navigation!.toJson(),`
7. Add to `props`: `navigation,`

**Step 2: Update Module test**

In `test/core/models/module_test.dart`, add tests:

```dart
test('Module with navigation roundtrips through Firestore', () {
  // Build a Module with navigation, call toFirestore(),
  // then verify the navigation JSON is present and correct.
  final module = Module(
    id: 'test',
    name: 'Test',
    navigation: const ModuleNavigation(
      bottomNav: BottomNav(items: [
        NavItem(label: 'Home', icon: 'home', screenId: 'main'),
        NavItem(label: 'Stats', icon: 'chart', screenId: 'stats'),
      ]),
    ),
  );
  final json = module.toFirestore();
  expect(json['navigation'], isNotNull);
  expect((json['navigation']['bottomNav']['items'] as List).length, 2);
});

test('Module without navigation — backward compat', () {
  final module = Module(id: 'test', name: 'Test');
  final json = module.toFirestore();
  expect(json.containsKey('navigation'), false);
});

test('copyWith navigation', () {
  final module = Module(id: 'test', name: 'Test');
  final updated = module.copyWith(
    navigation: const ModuleNavigation(
      bottomNav: BottomNav(items: [
        NavItem(label: 'Home', icon: 'home', screenId: 'main'),
      ]),
    ),
  );
  expect(updated.navigation, isNotNull);
  expect(updated.navigation!.bottomNav!.items.length, 1);
});
```

**Step 3: Run tests**

Run: `flutter test test/core/models/module_test.dart`
Expected: All tests pass.

**Step 4: Run dart analyze**

Run: `dart analyze lib/core/models/module.dart`
Expected: No issues found.

**Step 5: Commit**

```bash
git add lib/core/models/module.dart test/core/models/module_test.dart
git commit -m "feat: add optional navigation field to Module"
```

---

### Task 5: Migrate tasks_template to typed builders

**Files:**
- Modify: `scripts/templates/tasks_template.dart`

**Context:** Convert the tasks template from raw JSON maps to typed Blueprint builders. Layout nodes (screen, tab_screen, form_screen, scroll_column, section, row) become typed. Input/display nodes (text_input, stat_card, entry_list, etc.) use `RawBlueprint`. This validates the builder API works for a real template.

**Step 1: Rewrite the screens section**

Replace the `'screens'` map in `tasks_template.dart` with typed builders. Keep the `'schemas'` section as raw JSON (schema builders already exist but template uses raw JSON for Firestore seeding).

The screens section becomes:

```dart
import 'package:aj_assistant/features/blueprint/models/blueprint.dart';
import 'package:aj_assistant/features/blueprint/models/blueprint_action.dart';
import 'package:aj_assistant/features/blueprint/navigation/module_navigation.dart';
```

Then replace each screen's raw JSON with typed builders calling `.toJson()`.

Key conversions:
- `{'type': 'tab_screen', ...}` → `BpTabScreen(...).toJson()`
- `{'type': 'screen', ...}` → `BpScreen(...).toJson()`
- `{'type': 'form_screen', ...}` → `BpFormScreen(...).toJson()`
- `{'type': 'scroll_column', ...}` → `BpScrollColumn(...).toJson()`
- `{'type': 'section', ...}` → `BpSection(...).toJson()`
- `{'type': 'row', ...}` → `BpRow(...).toJson()`
- `{'type': 'button', ...}` → `BpButton(...).toJson()`
- `{'type': 'fab', ...}` → `BpFab(...).toJson()`
- Input/display nodes → `RawBlueprint({...})`
- Action maps → `NavigateAction(screen: '...')`

Also add the `navigation` field to the template.

**Step 2: Verify the output JSON is identical**

Write a small test or assertion that the new typed template produces the same JSON as the old raw template (for the layout structure). Minor key ordering differences are OK.

**Step 3: Run dart analyze**

Run: `dart analyze scripts/templates/tasks_template.dart`
Expected: No issues found.

**Step 4: Commit**

```bash
git add scripts/templates/tasks_template.dart
git commit -m "refactor: migrate tasks_template to typed Blueprint builders"
```

---

### Summary

| Task | What | Files |
|------|------|-------|
| 1 | BlueprintAction sealed class | `models/blueprint_action.dart` + test |
| 2 | Blueprint sealed class (layout) | `models/blueprint.dart` + test |
| 3 | ModuleNavigation model | `navigation/module_navigation.dart` + test |
| 4 | Add navigation to Module | `module.dart` + test |
| 5 | Migrate tasks_template | `tasks_template.dart` |
