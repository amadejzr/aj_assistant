# Savings Goals Template Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a "Savings Goals" template to the marketplace seed script with two schemas, reference effects, bottom nav, and six screens.

**Architecture:** Single-file data change — add a Dart map literal to the `templates` map in `scripts/seed_marketplace.dart`. The template follows the `ModuleTemplate.toFirestore()` format (raw `Map<String, dynamic>`).

**Tech Stack:** Dart, Firestore seed script

---

### Task 1: Add Savings Goals template to seed script

**Files:**
- Modify: `scripts/seed_marketplace.dart:25-26` (empty `templates` map)

**Step 1: Add the template entry**

Replace the empty `templates` map with the full Savings Goals template. The template key is `'savings_goals'`.

```dart
final templates = {
  'savings_goals': {
    'name': 'Savings Goals',
    'description': 'Set targets, log deposits, watch your savings grow',
    'longDescription':
        'Track multiple savings goals with automatic progress tracking. '
        'Log each deposit and see your progress at a glance. Whether you\'re '
        'saving for an emergency fund, a vacation, or a big purchase — set '
        'your target, log your deposits, and watch the progress bars fill up.',
    'icon': 'piggy-bank',
    'color': '#2E7D32',
    'category': 'Finance',
    'tags': ['savings', 'goals', 'money', 'finance', 'budget', 'deposits'],
    'featured': true,
    'sortOrder': 1,
    'installCount': 0,
    'version': 1,
    'settings': <String, dynamic>{},
    'guide': [
      {
        'title': 'Create a Goal',
        'body':
            'Tap + to add a savings goal. Give it a name, set your target '
            'amount, and optionally pick a deadline.',
      },
      {
        'title': 'Log Deposits',
        'body':
            'Switch to the History tab and tap + to log a deposit. Pick '
            'which goal it\'s for, enter the amount, and it\'s automatically '
            'tracked.',
      },
      {
        'title': 'Track Progress',
        'body':
            'The Dashboard shows your total savings and progress bars for '
            'each active goal. Watch them fill up as you save!',
      },
    ],
    'navigation': {
      'bottomNav': {
        'items': [
          {'label': 'Dashboard', 'icon': 'chart-line-up', 'screenId': 'main'},
          {'label': 'Goals', 'icon': 'target', 'screenId': 'goals_list'},
          {
            'label': 'History',
            'icon': 'clock-counter-clockwise',
            'screenId': 'history',
          },
        ],
      },
    },
    'schemas': {
      'goals': {
        'version': 1,
        'label': 'Goal',
        'icon': 'target',
        'displayField': 'name',
        'fields': {
          'name': {
            'type': 'text',
            'label': 'Goal Name',
            'required': true,
          },
          'target_amount': {
            'type': 'currency',
            'label': 'Target',
            'required': true,
            'constraints': {'min': 0, 'defaultCurrency': 'USD'},
          },
          'saved_amount': {
            'type': 'currency',
            'label': 'Saved',
            'required': false,
            'constraints': {'min': 0, 'defaultCurrency': 'USD'},
          },
          'deadline': {
            'type': 'datetime',
            'label': 'Target Date',
            'required': false,
            'constraints': {'dateOnly': true, 'allowPast': false},
          },
          'category': {
            'type': 'enumType',
            'label': 'Category',
            'required': false,
            'options': [
              'Emergency',
              'Travel',
              'Purchase',
              'Education',
              'Retirement',
              'Other',
            ],
          },
          'status': {
            'type': 'enumType',
            'label': 'Status',
            'required': false,
            'options': ['Active', 'Completed', 'Paused'],
          },
          'notes': {
            'type': 'text',
            'label': 'Notes',
            'required': false,
            'constraints': {'multiline': true},
          },
        },
      },
      'deposits': {
        'version': 1,
        'label': 'Deposit',
        'icon': 'coins',
        'displayField': 'note',
        'effects': [
          {
            'type': 'adjust_reference',
            'referenceField': 'goal',
            'targetField': 'saved_amount',
            'operation': 'add',
            'amountField': 'amount',
            'min': 0,
          },
        ],
        'fields': {
          'amount': {
            'type': 'currency',
            'label': 'Amount',
            'required': true,
            'constraints': {'min': 0.01, 'defaultCurrency': 'USD'},
          },
          'goal': {
            'type': 'reference',
            'label': 'Goal',
            'required': true,
            'constraints': {
              'targetSchema': 'goals',
              'schemaKey': 'goals',
              'displayField': 'name',
              'onDelete': 'cascade',
            },
          },
          'date': {
            'type': 'datetime',
            'label': 'Date',
            'required': true,
            'constraints': {'dateOnly': true},
          },
          'note': {
            'type': 'text',
            'label': 'Note',
            'required': false,
          },
        },
      },
    },
    'screens': {
      // ── Dashboard ──
      'main': {
        'type': 'screen',
        'title': 'Savings Goals',
        'children': [
          {
            'type': 'row',
            'children': [
              {
                'type': 'stat_card',
                'label': 'Total Saved',
                'value': '{{sum:goals.saved_amount}}',
                'icon': 'piggy-bank',
                'prefix': '\$',
              },
              {
                'type': 'stat_card',
                'label': 'Active Goals',
                'value': '{{count:goals?status=Active}}',
                'icon': 'target',
              },
            ],
          },
          {
            'type': 'section',
            'title': 'Active Goals',
            'children': [
              {
                'type': 'entry_list',
                'schema': 'goals',
                'filter': [
                  {'field': 'status', 'op': '==', 'value': 'Active'},
                ],
                'query': {'orderBy': 'name', 'direction': 'asc'},
                'itemLayout': {
                  'type': 'entry_card',
                  'title': '{{name}}',
                  'subtitle': '\${{saved_amount}} / \${{target_amount}}',
                  'trailing': '{{category}}',
                  'onTap': {
                    'type': 'navigate',
                    'screen': 'view_goal',
                  },
                },
              },
            ],
          },
        ],
        'fab': {
          'type': 'fab',
          'icon': 'plus',
          'action': {'type': 'navigate', 'screen': 'add_goal'},
        },
      },

      // ── Goals List ──
      'goals_list': {
        'type': 'screen',
        'title': 'Goals',
        'children': [
          {
            'type': 'entry_list',
            'schema': 'goals',
            'query': {'orderBy': 'deadline', 'direction': 'asc'},
            'itemLayout': {
              'type': 'entry_card',
              'title': '{{name}}',
              'subtitle': '{{deadline}}',
              'trailing': '{{status}}',
              'onTap': {
                'type': 'navigate',
                'screen': 'view_goal',
              },
            },
          },
        ],
        'fab': {
          'type': 'fab',
          'icon': 'plus',
          'action': {'type': 'navigate', 'screen': 'add_goal'},
        },
      },

      // ── History ──
      'history': {
        'type': 'screen',
        'title': 'History',
        'children': [
          {
            'type': 'entry_list',
            'schema': 'deposits',
            'query': {'orderBy': 'date', 'direction': 'desc'},
            'itemLayout': {
              'type': 'entry_card',
              'title': '\${{amount}}',
              'subtitle': '{{note}}',
              'trailing': '{{date}}',
            },
          },
        ],
        'fab': {
          'type': 'fab',
          'icon': 'plus',
          'action': {'type': 'navigate', 'screen': 'add_deposit'},
        },
      },

      // ── Add Goal ──
      'add_goal': {
        'type': 'form_screen',
        'title': 'New Goal',
        'editTitle': 'Edit Goal',
        'schema': 'goals',
        'submitLabel': 'Save Goal',
        'defaults': {'status': 'Active'},
        'children': [
          {'type': 'text_input', 'fieldKey': 'name'},
          {'type': 'currency_input', 'fieldKey': 'target_amount'},
          {'type': 'date_picker', 'fieldKey': 'deadline'},
          {'type': 'enum_selector', 'fieldKey': 'category'},
          {'type': 'enum_selector', 'fieldKey': 'status'},
          {'type': 'text_input', 'fieldKey': 'notes'},
        ],
      },

      // ── Add Deposit ──
      'add_deposit': {
        'type': 'form_screen',
        'title': 'New Deposit',
        'editTitle': 'Edit Deposit',
        'schema': 'deposits',
        'submitLabel': 'Save Deposit',
        'children': [
          {'type': 'reference_picker', 'fieldKey': 'goal'},
          {'type': 'currency_input', 'fieldKey': 'amount'},
          {'type': 'date_picker', 'fieldKey': 'date'},
          {'type': 'text_input', 'fieldKey': 'note'},
        ],
      },

      // ── View Goal ──
      'view_goal': {
        'type': 'screen',
        'title': '{{name}}',
        'children': [
          {
            'type': 'section',
            'title': 'Progress',
            'children': [
              {
                'type': 'progress_bar',
                'label': 'Saved',
                'value': '{{saved_amount}}',
                'max': '{{target_amount}}',
              },
              {
                'type': 'row',
                'children': [
                  {
                    'type': 'stat_card',
                    'label': 'Saved',
                    'value': '{{saved_amount}}',
                    'prefix': '\$',
                  },
                  {
                    'type': 'stat_card',
                    'label': 'Target',
                    'value': '{{target_amount}}',
                    'prefix': '\$',
                  },
                ],
              },
            ],
          },
          {
            'type': 'section',
            'title': 'Details',
            'children': [
              {
                'type': 'text_display',
                'label': 'Category',
                'value': '{{category}}',
              },
              {
                'type': 'text_display',
                'label': 'Deadline',
                'value': '{{deadline}}',
              },
              {
                'type': 'text_display',
                'label': 'Status',
                'value': '{{status}}',
              },
              {
                'type': 'text_display',
                'label': 'Notes',
                'value': '{{notes}}',
              },
            ],
          },
          {
            'type': 'section',
            'title': 'Deposits',
            'children': [
              {
                'type': 'entry_list',
                'schema': 'deposits',
                'filter': [
                  {'field': 'goal', 'op': '==', 'value': '{{_entryId}}'},
                ],
                'query': {'orderBy': 'date', 'direction': 'desc'},
                'itemLayout': {
                  'type': 'entry_card',
                  'title': '\${{amount}}',
                  'subtitle': '{{note}}',
                  'trailing': '{{date}}',
                },
              },
            ],
          },
        ],
        'fab': {
          'type': 'fab',
          'icon': 'plus',
          'action': {'type': 'navigate', 'screen': 'add_deposit'},
        },
        'appBarActions': [
          {
            'type': 'icon_button',
            'icon': 'pencil',
            'action': {
              'type': 'navigate',
              'screen': 'add_goal',
            },
          },
          {
            'type': 'icon_button',
            'icon': 'trash',
            'action': {
              'type': 'delete_entry',
              'confirm': true,
            },
          },
        ],
      },
    },
  },
};
```

**Step 2: Verify the script compiles**

Run: `cd scripts && dart compile exe seed_marketplace.dart 2>&1 || dart analyze seed_marketplace.dart`

If compile errors occur, they'll be type issues in the map literal. Fix any issues.

**Step 3: Verify the template round-trips through ModuleTemplate**

Write a quick smoke test to confirm the template data parses correctly:

Run: `flutter test test/features/marketplace/savings_goals_template_test.dart`

Create test file `test/features/marketplace/savings_goals_template_test.dart`:

```dart
import 'package:aj_assistant/core/models/module_template.dart';
import 'package:aj_assistant/features/modules/models/field_type.dart';
import 'package:aj_assistant/features/modules/models/schema_effect.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal map matching the seed script's savings_goals template.
/// This verifies the JSON round-trips through ModuleTemplate cleanly.
final _raw = <String, dynamic>{
  'name': 'Savings Goals',
  'description': 'Set targets, log deposits, watch your savings grow',
  'icon': 'piggy-bank',
  'color': '#2E7D32',
  'category': 'Finance',
  'tags': ['savings', 'goals', 'money', 'finance', 'budget', 'deposits'],
  'featured': true,
  'version': 1,
  'schemas': {
    'goals': {
      'version': 1,
      'label': 'Goal',
      'icon': 'target',
      'displayField': 'name',
      'fields': {
        'name': {'type': 'text', 'label': 'Goal Name', 'required': true},
        'target_amount': {
          'type': 'currency',
          'label': 'Target',
          'required': true,
          'constraints': {'min': 0, 'defaultCurrency': 'USD'},
        },
        'saved_amount': {
          'type': 'currency',
          'label': 'Saved',
          'constraints': {'min': 0, 'defaultCurrency': 'USD'},
        },
        'category': {
          'type': 'enumType',
          'label': 'Category',
          'options': [
            'Emergency',
            'Travel',
            'Purchase',
            'Education',
            'Retirement',
            'Other',
          ],
        },
        'status': {
          'type': 'enumType',
          'label': 'Status',
          'options': ['Active', 'Completed', 'Paused'],
        },
      },
    },
    'deposits': {
      'version': 1,
      'label': 'Deposit',
      'icon': 'coins',
      'displayField': 'note',
      'effects': [
        {
          'type': 'adjust_reference',
          'referenceField': 'goal',
          'targetField': 'saved_amount',
          'operation': 'add',
          'amountField': 'amount',
          'min': 0,
        },
      ],
      'fields': {
        'amount': {
          'type': 'currency',
          'label': 'Amount',
          'required': true,
          'constraints': {'min': 0.01, 'defaultCurrency': 'USD'},
        },
        'goal': {
          'type': 'reference',
          'label': 'Goal',
          'required': true,
          'constraints': {
            'targetSchema': 'goals',
            'displayField': 'name',
            'onDelete': 'cascade',
          },
        },
        'date': {
          'type': 'datetime',
          'label': 'Date',
          'required': true,
          'constraints': {'dateOnly': true},
        },
        'note': {'type': 'text', 'label': 'Note'},
      },
    },
  },
  'screens': {
    'main': {'type': 'screen', 'title': 'Savings Goals'},
    'add_goal': {'type': 'form_screen', 'title': 'New Goal', 'schema': 'goals'},
    'add_deposit': {
      'type': 'form_screen',
      'title': 'New Deposit',
      'schema': 'deposits',
    },
  },
  'navigation': {
    'bottomNav': {
      'items': [
        {'label': 'Dashboard', 'icon': 'chart-line-up', 'screenId': 'main'},
        {'label': 'Goals', 'icon': 'target', 'screenId': 'goals_list'},
        {
          'label': 'History',
          'icon': 'clock-counter-clockwise',
          'screenId': 'history',
        },
      ],
    },
  },
};

void main() {
  group('Savings Goals template', () {
    test('parses schemas correctly', () {
      final tpl = ModuleTemplate(
        id: 'savings_goals',
        name: _raw['name'] as String,
        schemas: ModuleTemplate.parseSchemas(_raw['schemas']),
      );

      expect(tpl.schemas.keys, containsAll(['goals', 'deposits']));

      final goals = tpl.schemas['goals']!;
      expect(goals.label, 'Goal');
      expect(goals.displayField, 'name');
      expect(goals.fields['target_amount']!.type, FieldType.currency);
      expect(goals.fields['category']!.type, FieldType.enumType);

      final deposits = tpl.schemas['deposits']!;
      expect(deposits.label, 'Deposit');
      expect(deposits.effects, hasLength(1));
      expect(deposits.effects.first, isA<AdjustReferenceEffect>());

      final effect = deposits.effects.first as AdjustReferenceEffect;
      expect(effect.referenceField, 'goal');
      expect(effect.targetField, 'saved_amount');
      expect(effect.operation, 'add');
      expect(effect.amountField, 'amount');
    });

    test('converts to Module', () {
      final tpl = ModuleTemplate(
        id: 'savings_goals',
        name: 'Savings Goals',
        schemas: ModuleTemplate.parseSchemas(_raw['schemas']),
        screens: ModuleTemplate.parseScreens(_raw['screens']),
      );

      final module = tpl.toModule('user_123');
      expect(module.id, 'user_123');
      expect(module.name, 'Savings Goals');
      expect(module.schemas.keys, containsAll(['goals', 'deposits']));
      expect(module.screens.keys, containsAll(['main', 'add_goal', 'add_deposit']));
    });
  });
}
```

Note: `ModuleTemplate._parseSchemas` and `._parseScreens` are private. If the test can't access them, parse via the `ModuleSchema.fromJson` / map utilities directly. Adjust imports as needed.

**Step 4: Run the test**

Run: `flutter test test/features/marketplace/savings_goals_template_test.dart -v`
Expected: PASS
