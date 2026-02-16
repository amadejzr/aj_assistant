import '../../features/schema/models/field_definition.dart';
import '../../features/schema/models/field_type.dart';
import '../../features/schema/models/module_schema.dart';
import '../models/module.dart';

Module createMockExpenseModule() {
  return const Module(
    id: 'expenses',
    name: 'Finances',
    description: 'Track expenses, income & budgets',
    icon: 'wallet',
    color: '#D94E33',
    sortOrder: 1,
    schemas: {
      // ─── Accounts: savings buckets / envelopes ───
      'account': ModuleSchema(
        label: 'Account',
        icon: 'piggyBank',
        fields: {
          'name': FieldDefinition(
            key: 'name',
            type: FieldType.text,
            label: 'Account Name',
            required: true,
          ),
          'goal': FieldDefinition(
            key: 'goal',
            type: FieldType.number,
            label: 'Goal Amount',
            constraints: {'min': 0},
          ),
          'color': FieldDefinition(
            key: 'color',
            type: FieldType.text,
            label: 'Color',
          ),
          'icon': FieldDefinition(
            key: 'icon',
            type: FieldType.text,
            label: 'Icon',
          ),
        },
      ),

      // ─── Categories ───
      'category': ModuleSchema(
        label: 'Category',
        icon: 'tag',
        fields: {
          'name': FieldDefinition(
            key: 'name',
            type: FieldType.text,
            label: 'Category Name',
            required: true,
          ),
          'icon': FieldDefinition(
            key: 'icon',
            type: FieldType.text,
            label: 'Icon',
          ),
          'color': FieldDefinition(
            key: 'color',
            type: FieldType.text,
            label: 'Color',
          ),
          'budget': FieldDefinition(
            key: 'budget',
            type: FieldType.number,
            label: 'Monthly Budget',
            constraints: {'min': 0},
          ),
        },
      ),

      // ─── Expenses / income / allocations ───
      'expense': ModuleSchema(
        label: 'Expense',
        icon: 'receipt',
        fields: {
          'entryType': FieldDefinition(
            key: 'entryType',
            type: FieldType.enumType,
            label: 'Type',
            required: true,
            options: ['expense', 'income', 'allocation'],
          ),
          'amount': FieldDefinition(
            key: 'amount',
            type: FieldType.number,
            label: 'Amount',
            required: true,
            constraints: {'min': 0},
          ),
          'date': FieldDefinition(
            key: 'date',
            type: FieldType.datetime,
            label: 'Date',
            required: true,
          ),
          'category': FieldDefinition(
            key: 'category',
            type: FieldType.reference,
            label: 'Category',
            constraints: {'schemaKey': 'category'},
          ),
          'account': FieldDefinition(
            key: 'account',
            type: FieldType.reference,
            label: 'Account',
            constraints: {'schemaKey': 'account'},
          ),
          'description': FieldDefinition(
            key: 'description',
            type: FieldType.text,
            label: 'Description',
          ),
          'notes': FieldDefinition(
            key: 'notes',
            type: FieldType.text,
            label: 'Notes',
          ),
        },
      ),
    },
    screens: {
      // ─── Main: Overview, Accounts, Calendar ───
      'main': {
        'type': 'tab_screen',
        'title': 'Finances',
        'tabs': [
          {
            'label': 'Overview',
            'icon': 'chart',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'section',
                  'title': 'This Month',
                  'children': [
                    {
                      'type': 'row',
                      'children': [
                        {
                          'type': 'stat_card',
                          'label': 'Income',
                          'schemaKey': 'expense',
                          'stat': 'sum_amount',
                          'filter': {'entryType': 'income'},
                        },
                        {
                          'type': 'stat_card',
                          'label': 'Expenses',
                          'schemaKey': 'expense',
                          'stat': 'sum_amount',
                          'filter': {'entryType': 'expense'},
                        },
                      ],
                    },
                    {
                      'type': 'row',
                      'children': [
                        {
                          'type': 'stat_card',
                          'label': 'Transactions',
                          'schemaKey': 'expense',
                          'stat': 'count',
                        },
                        {
                          'type': 'stat_card',
                          'label': 'Allocated',
                          'schemaKey': 'expense',
                          'stat': 'sum_amount',
                          'filter': {'entryType': 'allocation'},
                        },
                      ],
                    },
                  ],
                },
                {
                  'type': 'section',
                  'title': 'Recent',
                  'children': [
                    {
                      'type': 'entry_list',
                      'schemaKey': 'expense',
                      'query': {
                        'orderBy': 'date',
                        'direction': 'desc',
                        'limit': 10,
                      },
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{description}}',
                        'subtitle': '{{category}}',
                        'trailing': '{{amount}}',
                      },
                    },
                  ],
                },
              ],
            },
          },
          {
            'label': 'Accounts',
            'icon': 'list',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'button',
                  'label': 'New Account',
                  'icon': 'plus',
                  'style': 'outlined',
                  'action': {'type': 'navigate', 'screen': 'add_account'},
                },
                {
                  'type': 'entry_list',
                  'schemaKey': 'account',
                  'query': {'orderBy': 'name', 'direction': 'asc'},
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{name}}',
                    'subtitle': 'Goal: {{goal}}',
                    'onTap': {
                      'screen': 'account_detail',
                    },
                  },
                },
              ],
            },
          },
          {
            'label': 'Calendar',
            'icon': 'calendar',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'date_calendar',
                  'schemaKey': 'expense',
                  'dateField': 'date',
                },
              ],
            },
          },
          {
            'label': 'Categories',
            'icon': 'tag',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'button',
                  'label': 'New Category',
                  'icon': 'plus',
                  'style': 'outlined',
                  'action': {'type': 'navigate', 'screen': 'add_category'},
                },
                {
                  'type': 'entry_list',
                  'schemaKey': 'category',
                  'query': {'orderBy': 'name', 'direction': 'asc'},
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{name}}',
                    'subtitle': 'Budget: {{budget}}',
                  },
                },
              ],
            },
          },
        ],
        'fab': {
          'type': 'fab',
          'icon': 'add',
          'action': {'type': 'navigate', 'screen': 'add_expense'},
        },
      },

      // ─── Account Detail ───
      'account_detail': {
        'type': 'tab_screen',
        'title': '{{name}}',
        'tabs': [
          {
            'label': 'Activity',
            'icon': 'list',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'section',
                  'title': 'Allocations',
                  'children': [
                    {
                      'type': 'entry_list',
                      'schemaKey': 'expense',
                      'query': {
                        'orderBy': 'date',
                        'direction': 'desc',
                        'limit': 20,
                      },
                      'filter': {'entryType': 'allocation'},
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{description}}',
                        'subtitle': '{{entryType}}',
                        'trailing': '{{amount}}',
                      },
                    },
                  ],
                },
                {
                  'type': 'section',
                  'title': 'Expenses',
                  'children': [
                    {
                      'type': 'entry_list',
                      'schemaKey': 'expense',
                      'query': {
                        'orderBy': 'date',
                        'direction': 'desc',
                        'limit': 20,
                      },
                      'filter': {'entryType': 'expense'},
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{description}}',
                        'subtitle': '{{category}}',
                        'trailing': '{{amount}}',
                      },
                    },
                  ],
                },
              ],
            },
          },
          {
            'label': 'Stats',
            'icon': 'stats',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'section',
                  'title': 'Summary',
                  'children': [
                    {
                      'type': 'row',
                      'children': [
                        {
                          'type': 'stat_card',
                          'label': 'Allocated',
                          'schemaKey': 'expense',
                          'stat': 'sum_amount',
                          'filter': {'entryType': 'allocation'},
                        },
                        {
                          'type': 'stat_card',
                          'label': 'Spent',
                          'schemaKey': 'expense',
                          'stat': 'sum_amount',
                          'filter': {'entryType': 'expense'},
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          },
        ],
        'fab': {
          'type': 'fab',
          'icon': 'add',
          'action': {'type': 'navigate', 'screen': 'allocate'},
        },
      },

      // ─── Add Account ───
      'add_account': {
        'type': 'form_screen',
        'title': 'New Account',
        'schemaKey': 'account',
        'submitLabel': 'Create Account',
        'children': [
          {'type': 'text_input', 'fieldKey': 'name'},
          {'type': 'number_input', 'fieldKey': 'goal'},
        ],
      },

      // ─── Add Category ───
      'add_category': {
        'type': 'form_screen',
        'title': 'New Category',
        'schemaKey': 'category',
        'submitLabel': 'Create Category',
        'children': [
          {'type': 'text_input', 'fieldKey': 'name'},
          {'type': 'number_input', 'fieldKey': 'budget'},
        ],
      },

      // ─── Add Expense ───
      'add_expense': {
        'type': 'form_screen',
        'title': 'Add Expense',
        'schemaKey': 'expense',
        'submitLabel': 'Save Expense',
        'defaults': {'entryType': 'expense'},
        'children': [
          {'type': 'number_input', 'fieldKey': 'amount'},
          {'type': 'reference_picker', 'fieldKey': 'category', 'schemaKey': 'category'},
          {'type': 'reference_picker', 'fieldKey': 'account', 'schemaKey': 'account'},
          {'type': 'date_picker', 'fieldKey': 'date'},
          {'type': 'text_input', 'fieldKey': 'description'},
          {'type': 'text_input', 'fieldKey': 'notes', 'multiline': true},
        ],
        'nav': {
          'type': 'row',
          'children': [
            {
              'type': 'button',
              'label': 'Add Income',
              'style': 'outlined',
              'action': {'type': 'navigate', 'screen': 'add_income'},
            },
            {
              'type': 'button',
              'label': 'Allocate',
              'style': 'outlined',
              'action': {'type': 'navigate', 'screen': 'allocate'},
            },
          ],
        },
      },

      // ─── Add Income ───
      'add_income': {
        'type': 'form_screen',
        'title': 'Add Income',
        'schemaKey': 'expense',
        'submitLabel': 'Save Income',
        'defaults': {'entryType': 'income'},
        'children': [
          {'type': 'number_input', 'fieldKey': 'amount'},
          {'type': 'date_picker', 'fieldKey': 'date'},
          {'type': 'text_input', 'fieldKey': 'description'},
          {'type': 'text_input', 'fieldKey': 'notes', 'multiline': true},
        ],
        'nav': {
          'type': 'row',
          'children': [
            {
              'type': 'button',
              'label': 'Add Expense',
              'style': 'outlined',
              'action': {'type': 'navigate', 'screen': 'add_expense'},
            },
            {
              'type': 'button',
              'label': 'Allocate',
              'style': 'outlined',
              'action': {'type': 'navigate', 'screen': 'allocate'},
            },
          ],
        },
      },

      // ─── Allocate to Account ───
      'allocate': {
        'type': 'form_screen',
        'title': 'Allocate to Account',
        'schemaKey': 'expense',
        'submitLabel': 'Allocate',
        'defaults': {'entryType': 'allocation'},
        'children': [
          {'type': 'number_input', 'fieldKey': 'amount'},
          {'type': 'reference_picker', 'fieldKey': 'account', 'schemaKey': 'account'},
          {'type': 'date_picker', 'fieldKey': 'date'},
          {'type': 'text_input', 'fieldKey': 'description'},
        ],
      },
    },
  );
}
