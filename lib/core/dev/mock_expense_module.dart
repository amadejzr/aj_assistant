import '../models/field_definition.dart';
import '../models/field_type.dart';
import '../models/module.dart';
import '../models/module_schema.dart';

Module createMockExpenseModule() {
  return const Module(
    id: 'expenses',
    name: 'Finances',
    description: 'Track expenses, income & budgets',
    icon: 'wallet',
    color: '#D94E33',
    sortOrder: 1,
    schema: ModuleSchema(
      version: 1,
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
          type: FieldType.enumType,
          label: 'Category',
          options: [
            'Food',
            'Transport',
            'Entertainment',
            'Utilities',
            'Shopping',
            'Subscriptions',
            'Health',
            'Other',
          ],
        ),
        'account': FieldDefinition(
          key: 'account',
          type: FieldType.enumType,
          label: 'Account',
          options: [
            'Emergency Fund',
            'Investing',
            'Travel Fund',
            'Golf Clubs',
          ],
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
                          'stat': 'sum_amount',
                          'filter': {'entryType': 'income'},
                        },
                        {
                          'type': 'stat_card',
                          'label': 'Expenses',
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
                          'stat': 'count',
                        },
                        {
                          'type': 'stat_card',
                          'label': 'Allocated',
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
                  'type': 'card_grid',
                  'fieldKey': 'account',
                  'action': {
                    'type': 'navigate',
                    'screen': 'account_detail',
                    'paramKey': 'account',
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
                  'dateField': 'date',
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

      // ─── Account Detail: filtered by account from screenParams ───
      'account_detail': {
        'type': 'tab_screen',
        'title': 'Account',
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
                          'stat': 'sum_amount',
                          'filter': {'entryType': 'allocation'},
                        },
                        {
                          'type': 'stat_card',
                          'label': 'Spent',
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
                          'stat': 'count',
                        },
                        {
                          'type': 'stat_card',
                          'label': 'This Month',
                          'stat': 'this_month',
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

      // ─── Add Expense ───
      'add_expense': {
        'type': 'form_screen',
        'title': 'Add Expense',
        'submitLabel': 'Save Expense',
        'defaults': {'entryType': 'expense'},
        'children': [
          {'type': 'number_input', 'fieldKey': 'amount'},
          {'type': 'enum_selector', 'fieldKey': 'category'},
          {'type': 'enum_selector', 'fieldKey': 'account'},
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
        'submitLabel': 'Allocate',
        'defaults': {'entryType': 'allocation'},
        'children': [
          {'type': 'number_input', 'fieldKey': 'amount'},
          {'type': 'enum_selector', 'fieldKey': 'account'},
          {'type': 'date_picker', 'fieldKey': 'date'},
          {'type': 'text_input', 'fieldKey': 'description'},
        ],
      },
    },
  );
}
