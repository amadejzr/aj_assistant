// Integration test that feeds raw module templates through the full
// Blueprint pipeline: JSON → BlueprintParser → node tree → WidgetRegistry.
//
// For each template it verifies:
//   1. Every screen parses without producing UnknownNode (no typos / missing types).
//   2. Every screen renders via WidgetRegistry without throwing.
//
// Add new templates to [_templates] and they're automatically covered.

import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/core/theme/app_theme.dart';
import 'package:aj_assistant/features/blueprint/navigation/module_navigation.dart';
import 'package:aj_assistant/features/blueprint/renderer/blueprint_node.dart';
import 'package:aj_assistant/features/blueprint/renderer/blueprint_parser.dart';
import 'package:aj_assistant/features/blueprint/renderer/render_context.dart';
import 'package:aj_assistant/features/blueprint/renderer/widget_registry.dart';
import 'package:aj_assistant/features/schema/models/module_schema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Templates ───
import '../../../../scripts/templates/finance_template.dart';
import '../../../../scripts/templates/fitness_template.dart';
import '../../../../scripts/templates/hiking_template.dart';
import '../../../../scripts/templates/meals_template.dart';
import '../../../../scripts/templates/projects_template.dart';
import '../../../../scripts/templates/reading_list_template.dart';
import '../../../../scripts/templates/tasks_template.dart';

// All templates under test. Add new entries here.
final _templates = {
  'finance': financeTemplate,
  'fitness': fitnessTemplate,
  'hiking': hikingTemplate,
  'meals': mealsTemplate,
  'projects': projectsTemplate,
  'reading_list': readingListTemplate,
  'tasks': tasksTemplate,
};

// ───────────────────────────────────────────────────
//  Helpers
// ───────────────────────────────────────────────────

const _parser = BlueprintParser();

/// Builds a [Module] from a raw template map, mirroring what Firestore does.
Module _moduleFromTemplate(String id, Map<String, dynamic> raw) {
  final schemasRaw = raw['schemas'] as Map<String, dynamic>? ?? {};
  final schemas = schemasRaw.map(
    (key, value) => MapEntry(
      key,
      ModuleSchema.fromJson(Map<String, dynamic>.from(value as Map)),
    ),
  );

  final screensRaw = raw['screens'] as Map<String, dynamic>? ?? {};
  final screens = screensRaw.map(
    (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)),
  );

  final navRaw = raw['navigation'] as Map<String, dynamic>?;

  return Module(
    id: id,
    name: raw['name'] as String? ?? id,
    schemas: schemas,
    screens: screens,
    settings: Map<String, dynamic>.from(raw['settings'] as Map? ?? {}),
    navigation: navRaw != null
        ? ModuleNavigation.fromJson(Map<String, dynamic>.from(navRaw))
        : null,
  );
}

/// Recursively collects every node in the tree (depth-first).
List<BlueprintNode> _collectNodes(BlueprintNode root) {
  final result = <BlueprintNode>[root];

  void walk(BlueprintNode node) {
    switch (node) {
      case ScreenNode():
        for (final c in node.children) {
          result.add(c);
          walk(c);
        }
        if (node.fab != null) {
          result.add(node.fab!);
          walk(node.fab!);
        }
        if (node.appBar != null) {
          result.add(node.appBar!);
          for (final a in node.appBar!.actions) {
            result.add(a);
            walk(a);
          }
        }
      case TabScreenNode():
        for (final tab in node.tabs) {
          result.add(tab.content);
          walk(tab.content);
        }
        if (node.fab != null) {
          result.add(node.fab!);
          walk(node.fab!);
        }
        if (node.appBar != null) {
          result.add(node.appBar!);
          for (final a in node.appBar!.actions) {
            result.add(a);
            walk(a);
          }
        }
      case FormScreenNode():
        for (final c in node.children) {
          result.add(c);
          walk(c);
        }
      case ScrollColumnNode():
        for (final c in node.children) {
          result.add(c);
          walk(c);
        }
      case SectionNode():
        for (final c in node.children) {
          result.add(c);
          walk(c);
        }
      case ColumnNode():
        for (final c in node.children) {
          result.add(c);
          walk(c);
        }
      case RowNode():
        for (final c in node.children) {
          result.add(c);
          walk(c);
        }
      case ConditionalNode():
        for (final c in node.thenChildren) {
          result.add(c);
          walk(c);
        }
        for (final c in node.elseChildren) {
          result.add(c);
          walk(c);
        }
      case ExpandableNode():
        for (final c in node.children) {
          result.add(c);
          walk(c);
        }
      case EntryListNode():
        if (node.itemLayout != null) {
          result.add(node.itemLayout!);
          walk(node.itemLayout!);
        }
      // Leaf nodes — no children to walk
      case EntryCardNode():
      case StatCardNode():
      case TextInputNode():
      case NumberInputNode():
      case DatePickerNode():
      case TimePickerNode():
      case EnumSelectorNode():
      case ToggleNode():
      case SliderNode():
      case RatingInputNode():
      case TextDisplayNode():
      case EmptyStateNode():
      case ButtonNode():
      case FabNode():
      case CardGridNode():
      case DateCalendarNode():
      case ProgressBarNode():
      case ChartNode():
      case DividerNode():
      case ReferencePickerNode():
      case CurrencyInputNode():
      case IconButtonNode():
      case ActionMenuNode():
      case BadgeNode():
      case AppBarNode():
      case UnknownNode():
        break;
    }
  }

  walk(root);
  return result;
}

RenderContext _testContext(Module module) {
  return RenderContext(
    module: module,
    entries: const [],
    allEntries: const [],
    formValues: const {},
    screenParams: const {},
    onFormValueChanged: (_, __) {},
    onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
    onNavigateBack: () {},
    onDeleteEntry: (_) {},
  );
}

// ───────────────────────────────────────────────────
//  Tests
// ───────────────────────────────────────────────────

void main() {
  setUpAll(() {
    WidgetRegistry.instance.registerDefaults();
  });

  for (final entry in _templates.entries) {
    final name = entry.key;
    final raw = entry.value;

    group('$name template', () {
      late Module module;

      setUp(() {
        module = _moduleFromTemplate('test_$name', raw);
      });

      // ── Parse-level checks ──

      test('all screens parse without UnknownNode', () {
        final unknown = <String, List<String>>{};

        for (final screenEntry in module.screens.entries) {
          final screenId = screenEntry.key;
          final json = screenEntry.value;
          final root = _parser.parse(json);
          final nodes = _collectNodes(root);

          final unknowns = nodes
              .whereType<UnknownNode>()
              .map((n) => n.type)
              .toList();

          if (unknowns.isNotEmpty) {
            unknown[screenId] = unknowns;
          }
        }

        expect(
          unknown,
          isEmpty,
          reason:
              'Screens with unrecognised widget types: $unknown',
        );
      });

      test('no duplicate screen IDs in template', () {
        // Screens map keys are unique by definition, but verify the
        // embedded 'id' field matches the map key.
        for (final screenEntry in module.screens.entries) {
          final embeddedId = screenEntry.value['id'] as String?;
          if (embeddedId != null) {
            expect(
              embeddedId,
              screenEntry.key,
              reason:
                  'Screen map key "${screenEntry.key}" does not match '
                  'embedded id "$embeddedId"',
            );
          }
        }
      });

      // ── Navigation checks ──

      test('navigation screen references point to existing screens', () {
        final nav = module.navigation;
        if (nav == null) return; // no nav configured is fine

        final screenIds = module.screens.keys.toSet();
        final missing = <String>[];

        for (final item in nav.bottomNav?.items ?? <NavItem>[]) {
          if (!screenIds.contains(item.screenId)) {
            missing.add('bottomNav → ${item.screenId}');
          }
        }
        for (final item in nav.drawer?.items ?? <NavItem>[]) {
          if (!screenIds.contains(item.screenId)) {
            missing.add('drawer → ${item.screenId}');
          }
        }

        expect(
          missing,
          isEmpty,
          reason: 'Navigation references non-existent screens: $missing',
        );
      });

      // ── Widget-level smoke test ──

      for (final screenEntry in (raw['screens'] as Map).entries) {
        final screenId = screenEntry.key as String;
        final screenJson =
            Map<String, dynamic>.from(screenEntry.value as Map);

        testWidgets('screen "$screenId" renders without error',
            (tester) async {
          final mod = _moduleFromTemplate('test_$name', raw);
          final ctx = _testContext(mod);
          final node = _parser.parse(screenJson);

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.dark(),
              home: WidgetRegistry.instance.build(node, ctx),
            ),
          );

          // Just pumping without error is the test.
          // If any builder crashes, the test fails here.
          await tester.pump();
        });
      }
    });
  }
}
