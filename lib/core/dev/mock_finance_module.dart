import '../../features/schema/models/field_definition.dart';
import '../../features/schema/models/field_type.dart';
import '../../features/schema/models/module_schema.dart';
import '../models/module.dart';

Module createMockFinanceModule() {
  const accountFields = ['name', 'balance', 'cap', 'icon'];
  const expenseFields = ['amount', 'bucket', 'note', 'date'];
  const incomeFields = ['amount', 'source', 'date'];

  return const Module(
    id: 'finance',
    name: 'Finance',
    description: 'Accounts, budgets & expense tracking',
    icon: 'wallet',
    color: '#C4803C',
    sortOrder: 3,
    settings: {},
    schemas: {
      'account': ModuleSchema(
        label: 'Account',
        icon: 'wallet',
        fields: {
          'name': FieldDefinition(
            key: 'name',
            type: FieldType.text,
            label: 'Account Name',
            required: true,
          ),
          'balance': FieldDefinition(
            key: 'balance',
            type: FieldType.number,
            label: 'Balance',
            required: true,
          ),
          'cap': FieldDefinition(
            key: 'cap',
            type: FieldType.number,
            label: 'Limit',
          ),
          'icon': FieldDefinition(
            key: 'icon',
            type: FieldType.enumType,
            label: 'Icon',
            options: [
              'shield',
              'airplane',
              'golf',
              'piggy_bank',
              'trending_up',
              'wallet',
            ],
          ),
        },
      ),
      'expense': ModuleSchema(
        label: 'Expense',
        icon: 'receipt',
        fields: {
          'amount': FieldDefinition(
            key: 'amount',
            type: FieldType.number,
            label: 'Amount',
            required: true,
          ),
          'bucket': FieldDefinition(
            key: 'bucket',
            type: FieldType.enumType,
            label: 'Category',
            required: true,
            options: ['Needs', 'Wants', 'Savings'],
          ),
          'note': FieldDefinition(
            key: 'note',
            type: FieldType.text,
            label: 'Note',
          ),
          'date': FieldDefinition(
            key: 'date',
            type: FieldType.datetime,
            label: 'Date',
            required: true,
          ),
        },
      ),
      'income': ModuleSchema(
        label: 'Income',
        icon: 'cash',
        fields: {
          'amount': FieldDefinition(
            key: 'amount',
            type: FieldType.number,
            label: 'Amount',
            required: true,
          ),
          'source': FieldDefinition(
            key: 'source',
            type: FieldType.text,
            label: 'Source',
          ),
          'date': FieldDefinition(
            key: 'date',
            type: FieldType.datetime,
            label: 'Date',
            required: true,
          ),
        },
      ),
    },
    screens: {
      // ─── Main: three-tab overview ───
      'main': {
        'id': 'main',
        'type': 'tab_screen',
        'title': 'Finance',
        'tabs': [
          // ────────────── Tab 1: Overview ──────────────
          {
            'label': 'Overview',
            'icon': 'chart',
            'content': {
              'type': 'scroll_column',
              'children': [
                // Top stats
                {
                  'type': 'row',
                  'children': [
                    {
                      'type': 'stat_card',
                      'label': 'Total Balance',
                      'expression': 'sum(balance)',
                      'format': 'currency',
                      'filter': [
                        {'field': 'schemaKey', 'op': '==', 'value': 'account'},
                      ],
                    },
                    {
                      'type': 'stat_card',
                      'label': 'Spent This Month',
                      'expression': 'sum(amount, period(month))',
                      'format': 'currency',
                      'filter': [
                        {'field': 'schemaKey', 'op': '==', 'value': 'expense'},
                      ],
                    },
                  ],
                },

                // Budget 50/30/20
                {
                  'type': 'section',
                  'title': 'Budget (50 / 30 / 20)',
                  'children': [
                    {
                      'type': 'progress_bar',
                      'label': 'Needs (50%)',
                      'expression':
                          'percentage(sum(amount, period(month), where(bucket, ==, Needs), where(schemaKey, ==, expense)), multiply(sum(amount, period(month), where(schemaKey, ==, income)), 0.5))',
                      'format': 'percentage',
                    },
                    {
                      'type': 'progress_bar',
                      'label': 'Wants (30%)',
                      'expression':
                          'percentage(sum(amount, period(month), where(bucket, ==, Wants), where(schemaKey, ==, expense)), multiply(sum(amount, period(month), where(schemaKey, ==, income)), 0.3))',
                      'format': 'percentage',
                    },
                    {
                      'type': 'progress_bar',
                      'label': 'Savings (20%)',
                      'expression':
                          'percentage(sum(amount, period(month), where(bucket, ==, Savings), where(schemaKey, ==, expense)), multiply(sum(amount, period(month), where(schemaKey, ==, income)), 0.2))',
                      'format': 'percentage',
                    },
                  ],
                },

                // Recent expenses
                {
                  'type': 'section',
                  'title': 'Recent Expenses',
                  'children': [
                    {
                      'type': 'entry_list',
                      'filter': [
                        {'field': 'schemaKey', 'op': '==', 'value': 'expense'},
                      ],
                      'query': {
                        'orderBy': 'date',
                        'direction': 'desc',
                        'limit': 5,
                      },
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{note}}',
                        'subtitle': '{{bucket}}',
                        'trailing': '{{amount}}',
                        'trailingFormat': 'currency',
                        'onTap': {
                          'type': 'navigate',
                          'screen': 'edit_expense',
                          'forwardFields': expenseFields,
                          'params': {'_schemaKey': 'expense'},
                        },
                        'swipeActions': {
                          'right': {
                            'type': 'delete_entry',
                            'confirm': true,
                            'confirmMessage': 'Delete this expense?',
                          },
                        },
                      },
                    },
                  ],
                },
              ],
            },
          },

          // ────────────── Tab 2: Accounts ──────────────
          {
            'label': 'Accounts',
            'icon': 'piggy_bank',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'button',
                  'label': 'Add Account',
                  'style': 'outlined',
                  'action': {
                    'type': 'navigate',
                    'screen': 'add_account',
                    'params': {'_schemaKey': 'account'},
                  },
                },
                {
                  'type': 'entry_list',
                  'filter': [
                    {'field': 'schemaKey', 'op': '==', 'value': 'account'},
                  ],
                  'query': {
                    'orderBy': 'name',
                    'direction': 'asc',
                  },
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{name}}',
                    'subtitle': '{{icon}}',
                    'trailing': '{{balance}}',
                    'trailingFormat': 'currency',
                    'onTap': {
                      'type': 'navigate',
                      'screen': 'edit_account',
                      'forwardFields': accountFields,
                      'params': {'_schemaKey': 'account'},
                    },
                    'swipeActions': {
                      'right': {
                        'type': 'delete_entry',
                        'confirm': true,
                        'confirmMessage': 'Delete this account?',
                      },
                    },
                  },
                },
              ],
            },
          },

          // ────────────── Tab 3: Income ──────────────
          {
            'label': 'Income',
            'icon': 'cash',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'row',
                  'children': [
                    {
                      'type': 'stat_card',
                      'label': 'This Month',
                      'expression': 'sum(amount, period(month))',
                      'format': 'currency',
                      'filter': [
                        {'field': 'schemaKey', 'op': '==', 'value': 'income'},
                      ],
                    },
                    {
                      'type': 'stat_card',
                      'label': 'This Year',
                      'expression': 'sum(amount, period(year))',
                      'format': 'currency',
                      'filter': [
                        {'field': 'schemaKey', 'op': '==', 'value': 'income'},
                      ],
                    },
                  ],
                },
                {
                  'type': 'button',
                  'label': 'Add Income',
                  'style': 'outlined',
                  'action': {
                    'type': 'navigate',
                    'screen': 'add_income',
                    'params': {'_schemaKey': 'income'},
                  },
                },
                {
                  'type': 'section',
                  'title': 'Income Log',
                  'children': [
                    {
                      'type': 'entry_list',
                      'filter': [
                        {'field': 'schemaKey', 'op': '==', 'value': 'income'},
                      ],
                      'query': {
                        'orderBy': 'date',
                        'direction': 'desc',
                        'limit': 20,
                      },
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{source}}',
                        'subtitle': '{{date}}',
                        'trailing': '{{amount}}',
                        'trailingFormat': 'currency',
                        'onTap': {
                          'type': 'navigate',
                          'screen': 'edit_income',
                          'forwardFields': incomeFields,
                          'params': {'_schemaKey': 'income'},
                        },
                        'swipeActions': {
                          'right': {
                            'type': 'delete_entry',
                            'confirm': true,
                            'confirmMessage': 'Delete this income entry?',
                          },
                        },
                      },
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
          'action': {
            'type': 'navigate',
            'screen': 'add_expense',
            'params': {'_schemaKey': 'expense'},
          },
        },
      },

      // ─── Add expense ───
      'add_expense': {
        'id': 'add_expense',
        'type': 'form_screen',
        'title': 'Add Expense',
        'submitLabel': 'Save',
        'defaults': {},
        'children': [
          {'type': 'number_input', 'fieldKey': 'amount'},
          {'type': 'enum_selector', 'fieldKey': 'bucket'},
          {'type': 'text_input', 'fieldKey': 'note'},
          {'type': 'date_picker', 'fieldKey': 'date'},
        ],
      },

      // ─── Edit expense ───
      'edit_expense': {
        'id': 'edit_expense',
        'type': 'form_screen',
        'title': 'Edit Expense',
        'editLabel': 'Update',
        'children': [
          {'type': 'number_input', 'fieldKey': 'amount'},
          {'type': 'enum_selector', 'fieldKey': 'bucket'},
          {'type': 'text_input', 'fieldKey': 'note'},
          {'type': 'date_picker', 'fieldKey': 'date'},
        ],
      },

      // ─── Add account ───
      'add_account': {
        'id': 'add_account',
        'type': 'form_screen',
        'title': 'New Account',
        'submitLabel': 'Create',
        'defaults': {'balance': 0},
        'children': [
          {'type': 'text_input', 'fieldKey': 'name'},
          {'type': 'number_input', 'fieldKey': 'balance'},
          {'type': 'number_input', 'fieldKey': 'cap', 'label': 'Limit (optional)'},
          {'type': 'enum_selector', 'fieldKey': 'icon'},
        ],
      },

      // ─── Edit account ───
      'edit_account': {
        'id': 'edit_account',
        'type': 'form_screen',
        'title': 'Edit Account',
        'editLabel': 'Update',
        'children': [
          {'type': 'text_input', 'fieldKey': 'name'},
          {'type': 'number_input', 'fieldKey': 'balance'},
          {'type': 'number_input', 'fieldKey': 'cap', 'label': 'Limit (optional)'},
          {'type': 'enum_selector', 'fieldKey': 'icon'},
        ],
      },

      // ─── Add income ───
      'add_income': {
        'id': 'add_income',
        'type': 'form_screen',
        'title': 'Add Income',
        'submitLabel': 'Save',
        'defaults': {},
        'children': [
          {'type': 'number_input', 'fieldKey': 'amount'},
          {'type': 'text_input', 'fieldKey': 'source'},
          {'type': 'date_picker', 'fieldKey': 'date'},
        ],
      },

      // ─── Edit income ───
      'edit_income': {
        'id': 'edit_income',
        'type': 'form_screen',
        'title': 'Edit Income',
        'editLabel': 'Update',
        'children': [
          {'type': 'number_input', 'fieldKey': 'amount'},
          {'type': 'text_input', 'fieldKey': 'source'},
          {'type': 'date_picker', 'fieldKey': 'date'},
        ],
      },
    },
  );
}
