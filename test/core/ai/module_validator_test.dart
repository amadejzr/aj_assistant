import 'package:bowerlab/core/ai/module_validator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns a complete valid createModule input (habit tracker with main,
/// add_entry, and edit_entry screens). Each test clones this and modifies
/// one thing to trigger a specific validation error.
Map<String, dynamic> validInput() => {
      'name': 'Habit Tracker',
      'tables': {
        'default': {
          'columns': [
            {'name': 'title', 'type': 'text', 'required': true},
            {'name': 'completed', 'type': 'boolean'},
            {'name': 'streak', 'type': 'number'},
            {'name': 'category', 'type': 'text'},
            {'name': 'notes', 'type': 'text'},
          ],
        },
      },
      'screens': {
        'main': {
          'type': 'screen',
          'title': 'Habits',
          'queries': {
            'entries': {
              'sql':
                  'SELECT id, title, completed, streak FROM "{{default}}" ORDER BY created_at DESC',
            },
            'total': {
              'sql': 'SELECT COUNT(*) as count FROM "{{default}}"',
            },
          },
          'children': [
            {
              'type': 'stat_card',
              'label': 'Total Habits',
              'source': 'total',
              'valueKey': 'count',
            },
            {
              'type': 'entry_list',
              'source': 'entries',
              'itemLayout': {
                'type': 'entry_card',
                'title': '{{title}}',
                'subtitle': 'Streak: {{streak}}',
                'onTap': {
                  'type': 'navigate',
                  'screen': 'edit_entry',
                },
                'swipeActions': {
                  'right': {
                    'type': 'delete',
                  },
                },
              },
            },
          ],
          'fab': {
            'type': 'fab',
            'icon': 'plus',
            'action': {
              'type': 'navigate',
              'screen': 'add_entry',
            },
          },
        },
        'add_entry': {
          'type': 'form_screen',
          'title': 'Add Habit',
          'table': 'default',
          'submitLabel': 'Save',
          'children': [
            {
              'type': 'text_input',
              'fieldKey': 'title',
              'label': 'Habit Name',
            },
            {
              'type': 'enum_selector',
              'fieldKey': 'category',
              'label': 'Category',
              'options': ['Health', 'Fitness', 'Learning', 'Mindfulness'],
            },
            {
              'type': 'text_input',
              'fieldKey': 'notes',
              'label': 'Notes',
            },
          ],
        },
        'edit_entry': {
          'type': 'form_screen',
          'title': 'Edit Habit',
          'table': 'default',
          'submitLabel': 'Update',
          'children': [
            {
              'type': 'text_input',
              'fieldKey': 'title',
              'label': 'Habit Name',
            },
            {
              'type': 'enum_selector',
              'fieldKey': 'category',
              'label': 'Category',
              'options': ['Health', 'Fitness', 'Learning', 'Mindfulness'],
            },
            {
              'type': 'text_input',
              'fieldKey': 'notes',
              'label': 'Notes',
            },
          ],
        },
      },
    };

void main() {
  group('ModuleValidator', () {
    test('valid input passes', () {
      final result = ModuleValidator.validate(validInput());
      expect(result, isNull);
    });

    test('empty name fails', () {
      final input = validInput();
      input['name'] = '';

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(errors, contains('Module name is required.'));
    });

    test('missing name fails', () {
      final input = validInput();
      input.remove('name');

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(errors, contains('Module name is required.'));
    });

    test('no tables fails', () {
      final input = validInput();
      input['tables'] = {};

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(errors, contains('At least one table is required.'));
    });

    test('missing tables key fails', () {
      final input = validInput();
      input.remove('tables');

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(errors, contains('At least one table is required.'));
    });

    test('invalid column type fails', () {
      final input = validInput();
      (input['tables'] as Map)['default'] = {
        'columns': [
          {'name': 'title', 'type': 'varchar'},
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors!.any(
          (e) =>
              e.contains("Column 'title' has invalid type 'varchar'") &&
              e.contains('Must be one of:'),
        ),
        isTrue,
      );
    });

    test('missing main screen fails', () {
      final input = validInput();
      final screens = Map<String, dynamic>.from(input['screens'] as Map);
      screens.remove('main');
      input['screens'] = screens;

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(errors, contains("Missing required 'main' screen."));
    });

    test('invalid screen type fails', () {
      final input = validInput();
      (input['screens'] as Map)['main'] = {
        'type': 'bad_type',
        'title': 'Test',
        'children': [],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(errors, contains("Screen 'main' has invalid type 'bad_type'."));
    });

    test('form_screen references nonexistent table fails', () {
      final input = validInput();
      (input['screens'] as Map)['add_entry'] = {
        'type': 'form_screen',
        'title': 'Add',
        'table': 'nonexistent',
        'submitLabel': 'Save',
        'children': [],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors,
        contains(
          "form_screen 'add_entry' references table 'nonexistent' "
          'which does not exist.',
        ),
      );
    });

    test('fieldKey not in columns fails', () {
      final input = validInput();
      (input['screens'] as Map)['add_entry'] = {
        'type': 'form_screen',
        'title': 'Add',
        'table': 'default',
        'submitLabel': 'Save',
        'children': [
          {
            'type': 'text_input',
            'fieldKey': 'nonexistent_field',
            'label': 'Bad Field',
          },
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors!.any(
          (e) =>
              e.contains("fieldKey 'nonexistent_field'") &&
              e.contains("screen 'add_entry'") &&
              e.contains('not found in table columns'),
        ),
        isTrue,
      );
    });

    test('entry_list missing source fails', () {
      final input = validInput();
      (input['screens'] as Map)['main'] = {
        'type': 'screen',
        'title': 'Habits',
        'queries': {
          'entries': {
            'sql': 'SELECT * FROM "{{default}}"',
          },
        },
        'children': [
          {
            'type': 'entry_list',
            // no 'source' key
          },
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors,
        contains("entry_list on screen 'main' missing 'source'."),
      );
    });

    test('source without matching query fails', () {
      final input = validInput();
      (input['screens'] as Map)['main'] = {
        'type': 'screen',
        'title': 'Habits',
        'queries': {
          'entries': {
            'sql': 'SELECT * FROM "{{default}}"',
          },
        },
        'children': [
          {
            'type': 'entry_list',
            'source': 'nonexistent_query',
          },
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors!.any(
          (e) =>
              e.contains("source 'nonexistent_query'") &&
              e.contains("screen 'main'") &&
              e.contains('no matching query'),
        ),
        isTrue,
      );
    });

    test('navigate to nonexistent screen fails', () {
      final input = validInput();
      // Replace the fab action to navigate to a nonexistent screen.
      (input['screens'] as Map)['main'] = {
        'type': 'screen',
        'title': 'Habits',
        'queries': {
          'entries': {
            'sql': 'SELECT * FROM "{{default}}"',
          },
        },
        'children': [
          {
            'type': 'button',
            'label': 'Go',
            'action': {
              'type': 'navigate',
              'screen': 'does_not_exist',
            },
          },
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors,
        contains(
          "Action on screen 'main' navigates to 'does_not_exist' "
          'but no such screen exists.',
        ),
      );
    });

    test('enum_selector without options fails', () {
      final input = validInput();
      (input['screens'] as Map)['add_entry'] = {
        'type': 'form_screen',
        'title': 'Add',
        'table': 'default',
        'submitLabel': 'Save',
        'children': [
          {
            'type': 'enum_selector',
            'fieldKey': 'category',
            'label': 'Category',
            // no 'options' key
          },
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors,
        contains("enum_selector 'category' missing options array."),
      );
    });

    test('multi_enum_selector without options fails', () {
      final input = validInput();
      (input['screens'] as Map)['add_entry'] = {
        'type': 'form_screen',
        'title': 'Add',
        'table': 'default',
        'submitLabel': 'Save',
        'children': [
          {
            'type': 'multi_enum_selector',
            'fieldKey': 'category',
            'label': 'Tags',
            // no 'options' key
          },
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors,
        contains("multi_enum_selector 'category' missing options array."),
      );
    });

    test('unknown widget type fails', () {
      final input = validInput();
      (input['screens'] as Map)['main'] = {
        'type': 'screen',
        'title': 'Test',
        'children': [
          {
            'type': 'text_field',
            'label': 'Bad Widget',
          },
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors,
        contains("Unknown widget type 'text_field' on screen 'main'."),
      );
    });

    test('unresolved {{placeholder}} in query fails', () {
      final input = validInput();
      (input['screens'] as Map)['main'] = {
        'type': 'screen',
        'title': 'Test',
        'queries': {
          'entries': {
            'sql': 'SELECT * FROM "{{nonexistent_table}}"',
          },
        },
        'children': [],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors,
        contains(
          "Query 'entries' on screen 'main' has unresolved "
          "placeholder '{{nonexistent_table}}'.",
        ),
      );
    });

    test('stat_card without source+valueKey or value fails', () {
      final input = validInput();
      (input['screens'] as Map)['main'] = {
        'type': 'screen',
        'title': 'Test',
        'queries': {
          'total': {
            'sql': 'SELECT COUNT(*) as count FROM "{{default}}"',
          },
        },
        'children': [
          {
            'type': 'stat_card',
            'label': 'Total',
            // no source, no valueKey, no value
          },
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors,
        contains("stat_card 'Total' needs source+valueKey or value."),
      );
    });

    test('stat_card with source but no valueKey fails', () {
      final input = validInput();
      (input['screens'] as Map)['main'] = {
        'type': 'screen',
        'title': 'Test',
        'queries': {
          'total': {
            'sql': 'SELECT COUNT(*) as count FROM "{{default}}"',
          },
        },
        'children': [
          {
            'type': 'stat_card',
            'label': 'Total',
            'source': 'total',
            // no valueKey, no value
          },
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors,
        contains("stat_card 'Total' needs source+valueKey or value."),
      );
    });

    test('stat_card with value but no source passes', () {
      final input = validInput();
      (input['screens'] as Map)['main'] = {
        'type': 'screen',
        'title': 'Test',
        'queries': {
          'entries': {
            'sql': 'SELECT * FROM "{{default}}"',
          },
        },
        'children': [
          {
            'type': 'stat_card',
            'label': 'Fixed',
            'value': '42',
          },
          {
            'type': 'entry_list',
            'source': 'entries',
          },
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNull);
    });

    test('navigate via onTap to nonexistent screen fails', () {
      final input = validInput();
      (input['screens'] as Map)['main'] = {
        'type': 'screen',
        'title': 'Test',
        'queries': {
          'entries': {
            'sql': 'SELECT * FROM "{{default}}"',
          },
        },
        'children': [
          {
            'type': 'entry_list',
            'source': 'entries',
            'itemLayout': {
              'type': 'entry_card',
              'title': '{{title}}',
              'onTap': {
                'type': 'navigate',
                'screen': 'phantom_screen',
              },
            },
          },
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors,
        contains(
          "Action on screen 'main' navigates to 'phantom_screen' "
          'but no such screen exists.',
        ),
      );
    });

    test('show_form_sheet to nonexistent screen fails', () {
      final input = validInput();
      (input['screens'] as Map)['main'] = {
        'type': 'screen',
        'title': 'Test',
        'children': [
          {
            'type': 'button',
            'label': 'Open Sheet',
            'action': {
              'type': 'show_form_sheet',
              'screen': 'ghost_form',
            },
          },
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors,
        contains(
          "Action on screen 'main' navigates to 'ghost_form' "
          'but no such screen exists.',
        ),
      );
    });

    test('navigate in confirm.onConfirm to nonexistent screen fails', () {
      final input = validInput();
      (input['screens'] as Map)['main'] = {
        'type': 'screen',
        'title': 'Test',
        'children': [
          {
            'type': 'button',
            'label': 'Delete',
            'action': {
              'type': 'delete',
              'confirm': {
                'title': 'Are you sure?',
                'onConfirm': {
                  'type': 'navigate',
                  'screen': 'nowhere',
                },
              },
            },
          },
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors,
        contains(
          "Action on screen 'main' navigates to 'nowhere' "
          'but no such screen exists.',
        ),
      );
    });

    test('widgets inside tab_screen tabs are validated', () {
      final input = validInput();
      (input['screens'] as Map)['main'] = {
        'type': 'tab_screen',
        'title': 'Tabs',
        'tabs': [
          {
            'label': 'Tab 1',
            'icon': 'house',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'unknown_widget_xyz',
                },
              ],
            },
          },
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors,
        contains(
          "Unknown widget type 'unknown_widget_xyz' on screen 'main'.",
        ),
      );
    });

    test('valid placeholder in query passes', () {
      final input = validInput();
      // The default validInput already uses {{default}} which exists.
      final errors = ModuleValidator.validate(input);
      expect(errors, isNull);
    });

    test('swipeActions navigate to nonexistent screen fails', () {
      final input = validInput();
      (input['screens'] as Map)['main'] = {
        'type': 'screen',
        'title': 'Test',
        'queries': {
          'entries': {
            'sql': 'SELECT * FROM "{{default}}"',
          },
        },
        'children': [
          {
            'type': 'entry_list',
            'source': 'entries',
            'itemLayout': {
              'type': 'entry_card',
              'title': '{{title}}',
              'swipeActions': {
                'left': {
                  'type': 'navigate',
                  'screen': 'missing_screen',
                },
              },
            },
          },
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors,
        contains(
          "Action on screen 'main' navigates to 'missing_screen' "
          'but no such screen exists.',
        ),
      );
    });

    test('action_menu items navigate to nonexistent screen fails', () {
      final input = validInput();
      (input['screens'] as Map)['main'] = {
        'type': 'screen',
        'title': 'Test',
        'children': [
          {
            'type': 'action_menu',
            'icon': 'dots-three',
            'items': [
              {
                'label': 'Edit',
                'action': {
                  'type': 'navigate',
                  'screen': 'no_such_screen',
                },
              },
            ],
          },
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(
        errors,
        contains(
          "Action on screen 'main' navigates to 'no_such_screen' "
          'but no such screen exists.',
        ),
      );
    });

    test('multiple errors are collected', () {
      final input = validInput();
      input['name'] = '';
      (input['screens'] as Map)['main'] = {
        'type': 'bad',
        'children': [
          {'type': 'fake_widget'},
        ],
      };

      final errors = ModuleValidator.validate(input);
      expect(errors, isNotNull);
      expect(errors!.length, greaterThanOrEqualTo(2));
    });
  });
}
