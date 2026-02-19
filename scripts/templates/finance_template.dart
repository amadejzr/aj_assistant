const financeTemplate = {
  'name': 'Finance',
  'description': 'Know your numbers. Build your future.',
  'longDescription':
      'A comprehensive personal finance suite with multi-account tracking, '
      'the 50/30/20 budget rule, debt management, savings goals, and '
      'inter-account transfers.',
  'icon': 'wallet',
  'color': '#2E7D32',
  'category': 'Finance',
  'tags': ['budget', 'expenses', 'income', 'debt', 'goals', 'accounts'],
  'featured': true,
  'sortOrder': 0,
  'installCount': 0,
  'version': 3,
  'settings': {
    'needsTarget': 50,
    'wantsTarget': 30,
    'savingsTarget': 20,
  },
  'guide': [
    {
      'title': 'Getting Started',
      'body':
          'Add your bank accounts under the Accounts tab, then start logging '
          'expenses and income. Your net worth updates automatically.',
    },
    {
      'title': 'Budget Targets',
      'body':
          'The 50/30/20 rule splits income into Needs, Wants, and Savings. '
          'Tap "Adjust Budget Targets" on the Home tab to customize the percentages.',
    },
    {
      'title': 'Debt Tracking',
      'body':
          'Add credit cards and loans under Accounts. Track balances '
          'and interest rates to see your total liability alongside your assets.',
    },
    {
      'title': 'Savings Goals',
      'body':
          'Create goals in the Goals tab with a target amount. Update the '
          '"Saved So Far" field as you make progress — the progress bar fills automatically.',
    },
    {
      'title': 'Transfers',
      'body':
          'Move money between accounts from the Accounts tab. Pick a source '
          'and destination account, enter the amount, and both balances update '
          'automatically. Deleting a transfer reverses the balances.',
    },
  ],

  // ─── Navigation ───
  //
  // Bottom nav replaces the old 4-tab layout — each section is its own screen
  // with a proper appBar and contextual actions.
  'navigation': {
    'bottomNav': {
      'items': [
        {'label': 'Home', 'icon': 'chart', 'screenId': 'main'},
        {'label': 'Spending', 'icon': 'receipt', 'screenId': 'spending'},
        {'label': 'Accounts', 'icon': 'wallet', 'screenId': 'accounts'},
        {'label': 'Goals', 'icon': 'star', 'screenId': 'goals'},
      ],
    },
    'drawer': {
      'header': 'Finance',
      'items': [
        {'label': 'Add Expense', 'icon': 'receipt', 'screenId': 'add_expense'},
        {'label': 'Add Income', 'icon': 'cash', 'screenId': 'add_income'},
        {'label': 'New Account', 'icon': 'wallet', 'screenId': 'add_account'},
        {'label': 'New Goal', 'icon': 'star', 'screenId': 'add_goal'},
        {'label': 'Transfer Funds', 'icon': 'wallet', 'screenId': 'add_transfer'},
      ],
    },
  },

  // ─── Schemas ───
  'schemas': {
    'account': {
      'label': 'Account',
      'icon': 'wallet',
      'fields': {
        'name': {
          'key': 'name',
          'type': 'text',
          'label': 'Account Name',
          'required': true,
        },
        'accountType': {
          'key': 'accountType',
          'type': 'enumType',
          'label': 'Type',
          'required': true,
          'options': ['Checking', 'Savings', 'Investment', 'Retirement', 'Cash'],
        },
        'balance': {
          'key': 'balance',
          'type': 'number',
          'label': 'Balance',
          'required': true,
        },
        'institution': {
          'key': 'institution',
          'type': 'text',
          'label': 'Bank / Institution',
        },
      },
    },
    'expense': {
      'label': 'Expense',
      'icon': 'receipt',
      'effects': [
        {
          'type': 'adjust_reference',
          'referenceField': 'account',
          'targetField': 'balance',
          'amountField': 'amount',
          'operation': 'subtract',
          'min': 0,
        },
      ],
      'fields': {
        'amount': {
          'key': 'amount',
          'type': 'number',
          'label': 'Amount',
          'required': true,
        },
        'category': {
          'key': 'category',
          'type': 'enumType',
          'label': 'Category',
          'required': true,
          'options': ['Needs', 'Wants', 'Savings'],
        },
        'account': {
          'key': 'account',
          'type': 'reference',
          'label': 'From Account',
          'constraints': {'schemaKey': 'account'},
        },
        'note': {
          'key': 'note',
          'type': 'text',
          'label': 'What was it for?',
        },
        'date': {
          'key': 'date',
          'type': 'datetime',
          'label': 'Date',
          'required': true,
        },
      },
    },
    'income': {
      'label': 'Income',
      'icon': 'cash',
      'effects': [
        {
          'type': 'adjust_reference',
          'referenceField': 'account',
          'targetField': 'balance',
          'amountField': 'amount',
          'operation': 'add',
        },
      ],
      'fields': {
        'amount': {
          'key': 'amount',
          'type': 'number',
          'label': 'Amount',
          'required': true,
        },
        'source': {
          'key': 'source',
          'type': 'text',
          'label': 'Source',
        },
        'account': {
          'key': 'account',
          'type': 'reference',
          'label': 'Deposit To',
          'constraints': {'schemaKey': 'account'},
        },
        'date': {
          'key': 'date',
          'type': 'datetime',
          'label': 'Date',
          'required': true,
        },
      },
    },
    'debt': {
      'label': 'Debt',
      'icon': 'warning',
      'fields': {
        'name': {
          'key': 'name',
          'type': 'text',
          'label': 'Debt Name',
          'required': true,
        },
        'balance': {
          'key': 'balance',
          'type': 'number',
          'label': 'Balance Owed',
          'required': true,
        },
        'interestRate': {
          'key': 'interestRate',
          'type': 'number',
          'label': 'Interest Rate (%)',
        },
        'minimumPayment': {
          'key': 'minimumPayment',
          'type': 'number',
          'label': 'Minimum Payment',
        },
      },
    },
    'goal': {
      'label': 'Goal',
      'icon': 'target',
      'fields': {
        'name': {
          'key': 'name',
          'type': 'text',
          'label': 'Goal Name',
          'required': true,
        },
        'target': {
          'key': 'target',
          'type': 'number',
          'label': 'Target Amount',
          'required': true,
        },
        'saved': {
          'key': 'saved',
          'type': 'number',
          'label': 'Saved So Far',
          'required': true,
        },
        'note': {
          'key': 'note',
          'type': 'text',
          'label': 'Note',
        },
      },
    },
    'transfer': {
      'label': 'Transfer',
      'icon': 'swap',
      'effects': [
        {
          'type': 'adjust_reference',
          'referenceField': 'fromAccount',
          'targetField': 'balance',
          'amountField': 'amount',
          'operation': 'subtract',
          'min': 0,
        },
        {
          'type': 'adjust_reference',
          'referenceField': 'toAccount',
          'targetField': 'balance',
          'amountField': 'amount',
          'operation': 'add',
        },
      ],
      'fields': {
        'amount': {
          'key': 'amount',
          'type': 'number',
          'label': 'Amount',
          'required': true,
        },
        'fromAccount': {
          'key': 'fromAccount',
          'type': 'reference',
          'label': 'From Account',
          'required': true,
          'constraints': {'schemaKey': 'account'},
        },
        'toAccount': {
          'key': 'toAccount',
          'type': 'reference',
          'label': 'To Account',
          'required': true,
          'constraints': {'schemaKey': 'account'},
        },
        'note': {
          'key': 'note',
          'type': 'text',
          'label': 'Note',
        },
        'date': {
          'key': 'date',
          'type': 'datetime',
          'label': 'Date',
          'required': true,
        },
      },
    },
  },

  // ─── Screens ───
  'screens': {
    // ═══════════════════════════════════════════
    //  HOME — Dashboard overview
    // ═══════════════════════════════════════════
    'main': {
      'id': 'main',
      'type': 'screen',
      'title': 'Finance',
      'appBar': {
        'type': 'app_bar',
        'title': 'Finance',
        'showBack': false,
        'actions': [
          {
            'type': 'icon_button',
            'icon': 'settings',
            'action': {'type': 'navigate', 'screen': '_settings'},
          },
        ],
      },
      'children': [
        {
          'type': 'scroll_column',
          'children': [
            {
              'type': 'stat_card',
              'label': 'Net Worth',
              'expression':
                  'subtract(sum(balance, where(schemaKey, ==, account)), sum(balance, where(schemaKey, ==, debt)))',
              'format': 'currency',
              'properties': {'accent': true},
            },
            {
              'type': 'row',
              'children': [
                {
                  'type': 'stat_card',
                  'label': 'Income This Month',
                  'expression':
                      'sum(amount, period(month), where(schemaKey, ==, income))',
                  'format': 'currency',
                },
                {
                  'type': 'stat_card',
                  'label': 'Spent This Month',
                  'expression':
                      'sum(amount, period(month), where(schemaKey, ==, expense))',
                  'format': 'currency',
                },
              ],
            },
            {
              'type': 'row',
              'children': [
                {
                  'type': 'stat_card',
                  'label': 'Total Debt',
                  'expression': 'sum(balance, where(schemaKey, ==, debt))',
                  'format': 'currency',
                },
                {
                  'type': 'stat_card',
                  'label': 'Total Saved',
                  'expression': 'sum(saved, where(schemaKey, ==, goal))',
                  'format': 'currency',
                },
              ],
            },
            {
              'type': 'section',
              'title': 'Budget Pulse',
              'children': [
                {
                  'type': 'progress_bar',
                  'label': 'Needs',
                  'expression':
                      'percentage(sum(amount, period(month), where(category, ==, Needs), where(schemaKey, ==, expense)), multiply(sum(amount, period(month), where(schemaKey, ==, income)), divide(value(needsTarget), 100)))',
                  'format': 'percentage',
                },
                {
                  'type': 'progress_bar',
                  'label': 'Wants',
                  'expression':
                      'percentage(sum(amount, period(month), where(category, ==, Wants), where(schemaKey, ==, expense)), multiply(sum(amount, period(month), where(schemaKey, ==, income)), divide(value(wantsTarget), 100)))',
                  'format': 'percentage',
                },
                {
                  'type': 'progress_bar',
                  'label': 'Savings',
                  'expression':
                      'percentage(sum(amount, period(month), where(category, ==, Savings), where(schemaKey, ==, expense)), multiply(sum(amount, period(month), where(schemaKey, ==, income)), divide(value(savingsTarget), 100)))',
                  'format': 'percentage',
                },
              ],
            },
            {
              'type': 'button',
              'label': 'Adjust Budget Targets',
              'style': 'outlined',
              'action': {
                'type': 'navigate',
                'screen': 'edit_budget',
                'params': {'_settingsMode': true},
              },
            },
            {
              'type': 'section',
              'title': 'Recent Spending',
              'children': [
                {
                  'type': 'conditional',
                  'condition': {
                    'expression': 'count(where(schemaKey, ==, expense))',
                    'op': '>',
                    'value': 0,
                  },
                  'then': [
                    {
                      'type': 'entry_list',
                      'filter': [
                        {'field': 'schemaKey', 'op': '==', 'value': 'expense'},
                      ],
                      'query': {
                        'orderBy': 'date',
                        'direction': 'desc',
                        'limit': 3,
                      },
                      'itemLayout': {
                        'type': 'entry_card',
                        'title': '{{note}}',
                        'subtitle': '{{category}} · {{account}}',
                        'trailing': '{{amount}}',
                        'trailingFormat': 'currency',
                        'onTap': {
                          'type': 'navigate',
                          'screen': 'edit_expense',
                          'forwardFields': [
                            'amount',
                            'category',
                            'account',
                            'note',
                            'date',
                          ],
                          'params': {'_schemaKey': 'expense'},
                        },
                      },
                    },
                  ],
                  'else': [
                    {
                      'type': 'empty_state',
                      'icon': 'receipt',
                      'title': 'No expenses yet',
                      'subtitle': 'Tap + to log your first expense',
                    },
                  ],
                },
              ],
            },
          ],
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

    // ═══════════════════════════════════════════
    //  SPENDING — Expenses & income
    // ═══════════════════════════════════════════
    'spending': {
      'id': 'spending',
      'type': 'screen',
      'appBar': {
        'type': 'app_bar',
        'title': 'Spending',
        'showBack': false,
        'actions': [
          {
            'type': 'icon_button',
            'icon': 'add',
            'tooltip': 'Add Income',
            'action': {
              'type': 'navigate',
              'screen': 'add_income',
              'params': {'_schemaKey': 'income'},
            },
          },
        ],
      },
      'children': [
        {
          'type': 'scroll_column',
          'children': [
            {
              'type': 'row',
              'children': [
                {
                  'type': 'stat_card',
                  'label': 'Needs',
                  'expression':
                      'sum(amount, period(month), where(category, ==, Needs))',
                  'format': 'currency',
                  'filter': [
                    {'field': 'schemaKey', 'op': '==', 'value': 'expense'},
                  ],
                },
                {
                  'type': 'stat_card',
                  'label': 'Wants',
                  'expression':
                      'sum(amount, period(month), where(category, ==, Wants))',
                  'format': 'currency',
                  'filter': [
                    {'field': 'schemaKey', 'op': '==', 'value': 'expense'},
                  ],
                },
              ],
            },
            {
              'type': 'chart',
              'chartType': 'donut',
              'groupBy': 'category',
              'aggregate': 'sum',
              'expression': 'group(category, sum(amount), period(month))',
              'filter': [
                {'field': 'schemaKey', 'op': '==', 'value': 'expense'},
              ],
            },
            {
              'type': 'section',
              'title': 'All Expenses',
              'children': [
                {
                  'type': 'entry_list',
                  'filter': [
                    {'field': 'schemaKey', 'op': '==', 'value': 'expense'},
                  ],
                  'query': {
                    'orderBy': 'date',
                    'direction': 'desc',
                    'limit': 30,
                  },
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{note}}',
                    'subtitle': '{{category}} · {{account}}',
                    'trailing': '{{amount}}',
                    'trailingFormat': 'currency',
                    'onTap': {
                      'type': 'navigate',
                      'screen': 'edit_expense',
                      'forwardFields': [
                        'amount',
                        'category',
                        'account',
                        'note',
                        'date',
                      ],
                      'params': {'_schemaKey': 'expense'},
                    },
                    'swipeActions': {
                      'right': {
                        'type': 'confirm',
                        'title': 'Delete Expense',
                        'message': 'Delete this expense? The account balance will be adjusted.',
                        'onConfirm': {'type': 'delete_entry'},
                      },
                    },
                  },
                },
              ],
            },
            {
              'type': 'section',
              'title': 'Income',
              'children': [
                {
                  'type': 'entry_list',
                  'filter': [
                    {'field': 'schemaKey', 'op': '==', 'value': 'income'},
                  ],
                  'query': {
                    'orderBy': 'date',
                    'direction': 'desc',
                    'limit': 10,
                  },
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{source}}',
                    'subtitle': '{{date}} · {{account}}',
                    'trailing': '{{amount}}',
                    'trailingFormat': 'currency',
                    'onTap': {
                      'type': 'navigate',
                      'screen': 'edit_income',
                      'forwardFields': [
                        'amount',
                        'source',
                        'account',
                        'date',
                      ],
                      'params': {'_schemaKey': 'income'},
                    },
                    'swipeActions': {
                      'right': {
                        'type': 'confirm',
                        'title': 'Delete Income',
                        'message': 'Delete this income entry?',
                        'onConfirm': {'type': 'delete_entry'},
                      },
                    },
                  },
                },
              ],
            },
          ],
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

    // ═══════════════════════════════════════════
    //  ACCOUNTS — Assets, debts, transfers
    // ═══════════════════════════════════════════
    'accounts': {
      'id': 'accounts',
      'type': 'screen',
      'appBar': {
        'type': 'app_bar',
        'title': 'Accounts',
        'showBack': false,
        'actions': [
          {
            'type': 'icon_button',
            'icon': 'add',
            'tooltip': 'Transfer Funds',
            'action': {
              'type': 'navigate',
              'screen': 'add_transfer',
              'params': {'_schemaKey': 'transfer'},
            },
          },
        ],
      },
      'children': [
        {
          'type': 'scroll_column',
          'children': [
            {
              'type': 'section',
              'title': 'Assets',
              'children': [
                {
                  'type': 'stat_card',
                  'label': 'Total Assets',
                  'expression': 'sum(balance)',
                  'format': 'currency',
                  'filter': [
                    {'field': 'schemaKey', 'op': '==', 'value': 'account'},
                  ],
                },
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
                  'query': {'orderBy': 'name', 'direction': 'asc'},
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{name}}',
                    'subtitle': '{{accountType}} · {{institution}}',
                    'trailing': '{{balance}}',
                    'trailingFormat': 'currency',
                    'onTap': {
                      'type': 'navigate',
                      'screen': 'edit_account',
                      'forwardFields': [
                        'name',
                        'accountType',
                        'balance',
                        'institution',
                      ],
                      'params': {'_schemaKey': 'account'},
                    },
                    'swipeActions': {
                      'right': {
                        'type': 'confirm',
                        'title': 'Delete Account',
                        'message': 'Delete this account? This cannot be undone.',
                        'onConfirm': {'type': 'delete_entry'},
                      },
                    },
                  },
                },
              ],
            },
            {
              'type': 'section',
              'title': 'Debts',
              'children': [
                {
                  'type': 'stat_card',
                  'label': 'Total Debt',
                  'expression': 'sum(balance)',
                  'format': 'currency',
                  'filter': [
                    {'field': 'schemaKey', 'op': '==', 'value': 'debt'},
                  ],
                },
                {
                  'type': 'button',
                  'label': 'Add Debt',
                  'style': 'outlined',
                  'action': {
                    'type': 'navigate',
                    'screen': 'add_debt',
                    'params': {'_schemaKey': 'debt'},
                  },
                },
                {
                  'type': 'entry_list',
                  'filter': [
                    {'field': 'schemaKey', 'op': '==', 'value': 'debt'},
                  ],
                  'query': {'orderBy': 'balance', 'direction': 'desc'},
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{name}}',
                    'subtitle':
                        '{{interestRate}}% · min {{minimumPayment}}',
                    'trailing': '{{balance}}',
                    'trailingFormat': 'currency',
                    'onTap': {
                      'type': 'navigate',
                      'screen': 'edit_debt',
                      'forwardFields': [
                        'name',
                        'balance',
                        'interestRate',
                        'minimumPayment',
                      ],
                      'params': {'_schemaKey': 'debt'},
                    },
                    'swipeActions': {
                      'right': {
                        'type': 'confirm',
                        'title': 'Delete Debt',
                        'message': 'Delete this debt entry?',
                        'onConfirm': {'type': 'delete_entry'},
                      },
                    },
                  },
                },
              ],
            },
            {
              'type': 'section',
              'title': 'Recent Transfers',
              'children': [
                {
                  'type': 'entry_list',
                  'filter': [
                    {'field': 'schemaKey', 'op': '==', 'value': 'transfer'},
                  ],
                  'query': {
                    'orderBy': 'date',
                    'direction': 'desc',
                    'limit': 10,
                  },
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{fromAccount}} → {{toAccount}}',
                    'subtitle': '{{note}}',
                    'trailing': '{{amount}}',
                    'trailingFormat': 'currency',
                    'onTap': {
                      'type': 'navigate',
                      'screen': 'edit_transfer',
                      'forwardFields': [
                        'amount',
                        'fromAccount',
                        'toAccount',
                        'note',
                        'date',
                      ],
                      'params': {'_schemaKey': 'transfer'},
                    },
                    'swipeActions': {
                      'right': {
                        'type': 'confirm',
                        'title': 'Delete Transfer',
                        'message':
                            'Delete this transfer? Balances will be reversed.',
                        'onConfirm': {'type': 'delete_entry'},
                      },
                    },
                  },
                },
              ],
            },
          ],
        },
      ],
    },

    // ═══════════════════════════════════════════
    //  GOALS — Savings targets
    // ═══════════════════════════════════════════
    'goals': {
      'id': 'goals',
      'type': 'screen',
      'appBar': {
        'type': 'app_bar',
        'title': 'Goals',
        'showBack': false,
        'actions': [
          {
            'type': 'icon_button',
            'icon': 'add',
            'tooltip': 'New Goal',
            'action': {
              'type': 'navigate',
              'screen': 'add_goal',
              'params': {'_schemaKey': 'goal'},
            },
          },
        ],
      },
      'children': [
        {
          'type': 'scroll_column',
          'children': [
            {
              'type': 'row',
              'children': [
                {
                  'type': 'stat_card',
                  'label': 'Total Saved',
                  'expression': 'sum(saved)',
                  'format': 'currency',
                  'filter': [
                    {'field': 'schemaKey', 'op': '==', 'value': 'goal'},
                  ],
                },
                {
                  'type': 'stat_card',
                  'label': 'Total Target',
                  'expression': 'sum(target)',
                  'format': 'currency',
                  'filter': [
                    {'field': 'schemaKey', 'op': '==', 'value': 'goal'},
                  ],
                },
              ],
            },
            {
              'type': 'progress_bar',
              'label': 'Overall Goal Progress',
              'expression': 'percentage(sum(saved), sum(target))',
              'format': 'percentage',
              'filter': [
                {'field': 'schemaKey', 'op': '==', 'value': 'goal'},
              ],
            },
            {
              'type': 'conditional',
              'condition': {
                'expression': 'count(where(schemaKey, ==, goal))',
                'op': '>',
                'value': 0,
              },
              'then': [
                {
                  'type': 'entry_list',
                  'filter': [
                    {'field': 'schemaKey', 'op': '==', 'value': 'goal'},
                  ],
                  'query': {'orderBy': 'name', 'direction': 'asc'},
                  'itemLayout': {
                    'type': 'entry_card',
                    'title': '{{name}}',
                    'subtitle': '{{note}}',
                    'trailing': '{{saved}} / {{target}}',
                    'onTap': {
                      'type': 'navigate',
                      'screen': 'edit_goal',
                      'forwardFields': ['name', 'target', 'saved', 'note'],
                      'params': {'_schemaKey': 'goal'},
                    },
                    'swipeActions': {
                      'right': {
                        'type': 'confirm',
                        'title': 'Delete Goal',
                        'message': 'Delete this savings goal?',
                        'onConfirm': {'type': 'delete_entry'},
                      },
                    },
                  },
                },
              ],
              'else': [
                {
                  'type': 'empty_state',
                  'icon': 'star',
                  'title': 'No goals yet',
                  'subtitle': 'Tap + to set your first savings goal',
                },
              ],
            },
          ],
        },
      ],
    },

    // ═══════════════════════════════════════════
    //  FORMS
    // ═══════════════════════════════════════════
    'edit_budget': {
      'id': 'edit_budget',
      'type': 'form_screen',
      'title': 'Budget Targets',
      'submitLabel': 'Save',
      'children': [
        {'type': 'number_input', 'fieldKey': 'needsTarget', 'label': 'Needs (%)'},
        {'type': 'number_input', 'fieldKey': 'wantsTarget', 'label': 'Wants (%)'},
        {
          'type': 'number_input',
          'fieldKey': 'savingsTarget',
          'label': 'Savings (%)',
        },
      ],
    },
    'add_expense': {
      'id': 'add_expense',
      'type': 'form_screen',
      'title': 'Add Expense',
      'submitLabel': 'Save',
      'defaults': {},
      'children': [
        {'type': 'number_input', 'fieldKey': 'amount'},
        {
          'type': 'reference_picker',
          'fieldKey': 'account',
          'schemaKey': 'account',
          'displayField': 'name',
        },
        {'type': 'enum_selector', 'fieldKey': 'category'},
        {'type': 'text_input', 'fieldKey': 'note'},
        {'type': 'date_picker', 'fieldKey': 'date'},
      ],
    },
    'edit_expense': {
      'id': 'edit_expense',
      'type': 'form_screen',
      'title': 'Edit Expense',
      'editLabel': 'Update',
      'children': [
        {'type': 'number_input', 'fieldKey': 'amount'},
        {
          'type': 'reference_picker',
          'fieldKey': 'account',
          'schemaKey': 'account',
          'displayField': 'name',
        },
        {'type': 'enum_selector', 'fieldKey': 'category'},
        {'type': 'text_input', 'fieldKey': 'note'},
        {'type': 'date_picker', 'fieldKey': 'date'},
      ],
    },
    'add_income': {
      'id': 'add_income',
      'type': 'form_screen',
      'title': 'Add Income',
      'submitLabel': 'Save',
      'defaults': {},
      'children': [
        {'type': 'number_input', 'fieldKey': 'amount'},
        {'type': 'text_input', 'fieldKey': 'source'},
        {
          'type': 'reference_picker',
          'fieldKey': 'account',
          'schemaKey': 'account',
          'displayField': 'name',
        },
        {'type': 'date_picker', 'fieldKey': 'date'},
      ],
    },
    'edit_income': {
      'id': 'edit_income',
      'type': 'form_screen',
      'title': 'Edit Income',
      'editLabel': 'Update',
      'children': [
        {'type': 'number_input', 'fieldKey': 'amount'},
        {'type': 'text_input', 'fieldKey': 'source'},
        {
          'type': 'reference_picker',
          'fieldKey': 'account',
          'schemaKey': 'account',
          'displayField': 'name',
        },
        {'type': 'date_picker', 'fieldKey': 'date'},
      ],
    },
    'add_account': {
      'id': 'add_account',
      'type': 'form_screen',
      'title': 'New Account',
      'submitLabel': 'Create',
      'defaults': {'balance': 0},
      'children': [
        {'type': 'text_input', 'fieldKey': 'name'},
        {'type': 'enum_selector', 'fieldKey': 'accountType'},
        {'type': 'number_input', 'fieldKey': 'balance'},
        {'type': 'text_input', 'fieldKey': 'institution'},
      ],
    },
    'edit_account': {
      'id': 'edit_account',
      'type': 'form_screen',
      'title': 'Edit Account',
      'editLabel': 'Update',
      'children': [
        {'type': 'text_input', 'fieldKey': 'name'},
        {'type': 'enum_selector', 'fieldKey': 'accountType'},
        {'type': 'number_input', 'fieldKey': 'balance'},
        {'type': 'text_input', 'fieldKey': 'institution'},
      ],
    },
    'add_debt': {
      'id': 'add_debt',
      'type': 'form_screen',
      'title': 'Add Debt',
      'submitLabel': 'Save',
      'defaults': {},
      'children': [
        {'type': 'text_input', 'fieldKey': 'name'},
        {'type': 'number_input', 'fieldKey': 'balance'},
        {'type': 'number_input', 'fieldKey': 'interestRate'},
        {'type': 'number_input', 'fieldKey': 'minimumPayment'},
      ],
    },
    'edit_debt': {
      'id': 'edit_debt',
      'type': 'form_screen',
      'title': 'Edit Debt',
      'editLabel': 'Update',
      'children': [
        {'type': 'text_input', 'fieldKey': 'name'},
        {'type': 'number_input', 'fieldKey': 'balance'},
        {'type': 'number_input', 'fieldKey': 'interestRate'},
        {'type': 'number_input', 'fieldKey': 'minimumPayment'},
      ],
    },
    'add_goal': {
      'id': 'add_goal',
      'type': 'form_screen',
      'title': 'New Goal',
      'submitLabel': 'Create',
      'defaults': {'saved': 0},
      'children': [
        {'type': 'text_input', 'fieldKey': 'name'},
        {'type': 'number_input', 'fieldKey': 'target'},
        {'type': 'number_input', 'fieldKey': 'saved'},
        {'type': 'text_input', 'fieldKey': 'note'},
      ],
    },
    'edit_goal': {
      'id': 'edit_goal',
      'type': 'form_screen',
      'title': 'Edit Goal',
      'editLabel': 'Update',
      'children': [
        {'type': 'text_input', 'fieldKey': 'name'},
        {'type': 'number_input', 'fieldKey': 'target'},
        {'type': 'number_input', 'fieldKey': 'saved'},
        {'type': 'text_input', 'fieldKey': 'note'},
      ],
    },
    'add_transfer': {
      'id': 'add_transfer',
      'type': 'form_screen',
      'title': 'Transfer Funds',
      'submitLabel': 'Transfer',
      'defaults': {},
      'children': [
        {'type': 'number_input', 'fieldKey': 'amount'},
        {
          'type': 'reference_picker',
          'fieldKey': 'fromAccount',
          'schemaKey': 'account',
          'displayField': 'name',
        },
        {
          'type': 'reference_picker',
          'fieldKey': 'toAccount',
          'schemaKey': 'account',
          'displayField': 'name',
        },
        {'type': 'text_input', 'fieldKey': 'note'},
        {'type': 'date_picker', 'fieldKey': 'date'},
      ],
    },
    'edit_transfer': {
      'id': 'edit_transfer',
      'type': 'form_screen',
      'title': 'Edit Transfer',
      'editLabel': 'Update',
      'children': [
        {'type': 'number_input', 'fieldKey': 'amount'},
        {
          'type': 'reference_picker',
          'fieldKey': 'fromAccount',
          'schemaKey': 'account',
          'displayField': 'name',
        },
        {
          'type': 'reference_picker',
          'fieldKey': 'toAccount',
          'schemaKey': 'account',
          'displayField': 'name',
        },
        {'type': 'text_input', 'fieldKey': 'note'},
        {'type': 'date_picker', 'fieldKey': 'date'},
      ],
    },
  },
};
