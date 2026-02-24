/// Validates that typed Blueprint builders can reproduce the Finance template
/// structure. All screen nodes use typed builders — no RawBlueprint.
///
/// Uses BpAppBar, BpConditional, ConfirmAction, and bottom-nav navigation —
/// the new features added alongside the type-safe builders.
library;

import 'package:bowerlab/features/blueprint/models/blueprint.dart';
import 'package:bowerlab/features/blueprint/models/blueprint_action.dart';
import 'package:bowerlab/features/blueprint/navigation/module_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Shared field lists ───

const _expenseFields = ['amount', 'category', 'account', 'note', 'date'];
const _accountFields = ['name', 'accountType', 'balance', 'institution'];
const _debtFields = ['name', 'balance', 'interestRate', 'minimumPayment'];
const _goalFields = ['name', 'target', 'saved', 'note'];
const _transferFields = ['amount', 'fromAccount', 'toAccount', 'note', 'date'];

// ─── Shared form inputs ───

const _expenseInputs = <Blueprint>[
  BpNumberInput(fieldKey: 'amount'),
  BpReferencePicker(fieldKey: 'account', schemaKey: 'account'),
  BpEnumSelector(fieldKey: 'category'),
  BpTextInput(fieldKey: 'note'),
  BpDatePicker(fieldKey: 'date'),
];

const _incomeInputs = <Blueprint>[
  BpNumberInput(fieldKey: 'amount'),
  BpTextInput(fieldKey: 'source'),
  BpReferencePicker(fieldKey: 'account', schemaKey: 'account'),
  BpDatePicker(fieldKey: 'date'),
];

const _accountInputs = <Blueprint>[
  BpTextInput(fieldKey: 'name'),
  BpEnumSelector(fieldKey: 'accountType'),
  BpNumberInput(fieldKey: 'balance'),
  BpTextInput(fieldKey: 'institution'),
];

const _debtInputs = <Blueprint>[
  BpTextInput(fieldKey: 'name'),
  BpNumberInput(fieldKey: 'balance'),
  BpNumberInput(fieldKey: 'interestRate'),
  BpNumberInput(fieldKey: 'minimumPayment'),
];

const _goalInputs = <Blueprint>[
  BpTextInput(fieldKey: 'name'),
  BpNumberInput(fieldKey: 'target'),
  BpNumberInput(fieldKey: 'saved'),
  BpTextInput(fieldKey: 'note'),
];

const _transferInputs = <Blueprint>[
  BpNumberInput(fieldKey: 'amount'),
  BpReferencePicker(fieldKey: 'fromAccount', schemaKey: 'account'),
  BpReferencePicker(fieldKey: 'toAccount', schemaKey: 'account'),
  BpTextInput(fieldKey: 'note'),
  BpDatePicker(fieldKey: 'date'),
];

// ─── Helpers ───

ConfirmAction _confirmDelete(String title, String message) {
  return ConfirmAction(
    title: title,
    message: message,
    onConfirm: const DeleteEntryAction(),
  );
}

void main() {
  group('Finance template built with typed builders', () {
    test('home screen with appBar, conditional, and fab', () {
      const homeScreen = BpScreen(
        appBar: BpAppBar(
          title: 'Finance',
          showBack: false,
          actions: [
            BpIconButton(
              icon: 'settings',
              action: NavigateAction(screen: '_settings'),
            ),
          ],
        ),
        children: [
          BpScrollColumn(children: [
            BpStatCard(
              label: 'Net Worth',
              expression:
                  'subtract(sum(balance, where(schemaKey, ==, account)), sum(balance, where(schemaKey, ==, debt)))',
              format: 'currency',
            ),
            BpRow(children: [
              BpStatCard(
                label: 'Income This Month',
                expression:
                    'sum(amount, period(month), where(schemaKey, ==, income))',
                format: 'currency',
              ),
              BpStatCard(
                label: 'Spent This Month',
                expression:
                    'sum(amount, period(month), where(schemaKey, ==, expense))',
                format: 'currency',
              ),
            ]),
            BpSection(title: 'Budget Pulse', children: [
              BpProgressBar(
                label: 'Needs',
                expression:
                    'percentage(sum(amount, period(month), where(category, ==, Needs), where(schemaKey, ==, expense)), multiply(sum(amount, period(month), where(schemaKey, ==, income)), divide(value(needsTarget), 100)))',
                format: 'percentage',
              ),
            ]),
            BpSection(title: 'Recent Spending', children: [
              BpConditional(
                condition: {
                  'expression': 'count(where(schemaKey, ==, expense))',
                  'op': '>',
                  'value': 0,
                },
                thenChildren: [
                  BpEntryList(
                    filter: [BpFilter(field: 'schemaKey', value: 'expense')],
                    query: BpQuery(
                        orderBy: 'date', direction: 'desc', limit: 3),
                    itemLayout: BpEntryCard(
                      title: '{{note}}',
                      subtitle: '{{category}} · {{account}}',
                      trailing: '{{amount}}',
                      trailingFormat: 'currency',
                    ),
                  ),
                ],
                elseChildren: [
                  BpEmptyState(
                    icon: 'receipt',
                    title: 'No expenses yet',
                    subtitle: 'Tap + to log your first expense',
                  ),
                ],
              ),
            ]),
          ]),
        ],
        fab: BpFab(
          icon: 'add',
          action: NavigateAction(
            screen: 'add_expense',
            params: {'_schemaKey': 'expense'},
          ),
        ),
      );

      final json = homeScreen.toJson();
      expect(json['type'], 'screen');

      // AppBar
      expect(json['appBar'], isNotNull);
      expect(json['appBar']['title'], 'Finance');
      expect(json['appBar']['showBack'], false);
      expect(json['appBar']['actions'], hasLength(1));
      expect(json['appBar']['actions'][0]['icon'], 'settings');

      // Children → scroll_column
      final scrollCol = (json['children'] as List)[0] as Map;
      expect(scrollCol['type'], 'scroll_column');
      final children = scrollCol['children'] as List;
      expect(children.length, 4);

      // Net Worth stat card
      expect(children[0]['type'], 'stat_card');
      expect(children[0]['label'], 'Net Worth');

      // Conditional in Recent Spending section
      final recentSection = children[3] as Map;
      expect(recentSection['type'], 'section');
      expect(recentSection['title'], 'Recent Spending');
      final conditional = (recentSection['children'] as List)[0] as Map;
      expect(conditional['type'], 'conditional');
      expect(conditional['then'], hasLength(1));
      expect(conditional['else'], hasLength(1));
      expect((conditional['else'] as List)[0]['type'], 'empty_state');

      // FAB
      expect(json['fab']['type'], 'fab');
      expect(json['fab']['action']['screen'], 'add_expense');
    });

    test('spending screen with confirm delete actions', () {
      final spendingScreen = BpScreen(
        appBar: const BpAppBar(
          title: 'Spending',
          showBack: false,
          actions: [
            BpIconButton(
              icon: 'add',
              tooltip: 'Add Income',
              action: NavigateAction(
                screen: 'add_income',
                params: {'_schemaKey': 'income'},
              ),
            ),
          ],
        ),
        children: [
          BpScrollColumn(children: [
            BpSection(title: 'All Expenses', children: [
              BpEntryList(
                filter: const [BpFilter(field: 'schemaKey', value: 'expense')],
                query: const BpQuery(
                    orderBy: 'date', direction: 'desc', limit: 30),
                itemLayout: BpEntryCard(
                  title: '{{note}}',
                  subtitle: '{{category}} · {{account}}',
                  trailing: '{{amount}}',
                  trailingFormat: 'currency',
                  onTap: const NavigateAction(
                    screen: 'edit_expense',
                    forwardFields: _expenseFields,
                    params: {'_schemaKey': 'expense'},
                  ),
                  swipeActions: BpSwipeActions(
                    right: _confirmDelete(
                      'Delete Expense',
                      'Delete this expense? The account balance will be adjusted.',
                    ),
                  ),
                ),
              ),
            ]),
          ]),
        ],
        fab: const BpFab(
          icon: 'add',
          action: NavigateAction(
            screen: 'add_expense',
            params: {'_schemaKey': 'expense'},
          ),
        ),
      );

      final json = spendingScreen.toJson();

      // AppBar with income shortcut
      expect(json['appBar']['title'], 'Spending');
      expect(json['appBar']['actions'][0]['tooltip'], 'Add Income');

      // Swipe action uses confirm → delete_entry
      final scrollCol = (json['children'] as List)[0] as Map;
      final section = (scrollCol['children'] as List)[0] as Map;
      final entryList = (section['children'] as List)[0] as Map;
      final swipeRight =
          entryList['itemLayout']['swipeActions']['right'] as Map;
      expect(swipeRight['type'], 'confirm');
      expect(swipeRight['title'], 'Delete Expense');
      expect(swipeRight['onConfirm']['type'], 'delete_entry');
    });

    test('goals screen with conditional empty state', () {
      final goalsScreen = BpScreen(
        appBar: const BpAppBar(
          title: 'Goals',
          showBack: false,
          actions: [
            BpIconButton(
              icon: 'add',
              tooltip: 'New Goal',
              action: NavigateAction(
                screen: 'add_goal',
                params: {'_schemaKey': 'goal'},
              ),
            ),
          ],
        ),
        children: [
          BpScrollColumn(children: [
            const BpRow(children: [
              BpStatCard(
                label: 'Total Saved',
                expression: 'sum(saved)',
                format: 'currency',
                filter: [BpFilter(field: 'schemaKey', value: 'goal')],
              ),
              BpStatCard(
                label: 'Total Target',
                expression: 'sum(target)',
                format: 'currency',
                filter: [BpFilter(field: 'schemaKey', value: 'goal')],
              ),
            ]),
            BpConditional(
              condition: const {
                'expression': 'count(where(schemaKey, ==, goal))',
                'op': '>',
                'value': 0,
              },
              thenChildren: [
                BpEntryList(
                  filter: const [BpFilter(field: 'schemaKey', value: 'goal')],
                  query: const BpQuery(orderBy: 'name', direction: 'asc'),
                  itemLayout: BpEntryCard(
                    title: '{{name}}',
                    subtitle: '{{note}}',
                    trailing: '{{saved}} / {{target}}',
                    onTap: const NavigateAction(
                      screen: 'edit_goal',
                      forwardFields: _goalFields,
                      params: {'_schemaKey': 'goal'},
                    ),
                    swipeActions: BpSwipeActions(
                      right: _confirmDelete(
                        'Delete Goal',
                        'Delete this savings goal?',
                      ),
                    ),
                  ),
                ),
              ],
              elseChildren: const [
                BpEmptyState(
                  icon: 'star',
                  title: 'No goals yet',
                  subtitle: 'Tap + to set your first savings goal',
                ),
              ],
            ),
          ]),
        ],
      );

      final json = goalsScreen.toJson();
      final scrollCol = (json['children'] as List)[0] as Map;
      final children = scrollCol['children'] as List;

      // Row with stat cards
      expect(children[0]['type'], 'row');

      // Conditional
      final cond = children[1] as Map;
      expect(cond['type'], 'conditional');

      // Then: entry_list with swipe confirm
      final entryList = (cond['then'] as List)[0] as Map;
      expect(entryList['type'], 'entry_list');
      final swipe = entryList['itemLayout']['swipeActions']['right'] as Map;
      expect(swipe['type'], 'confirm');
      expect(swipe['title'], 'Delete Goal');

      // Else: empty state
      final emptyState = (cond['else'] as List)[0] as Map;
      expect(emptyState['type'], 'empty_state');
      expect(emptyState['title'], 'No goals yet');
    });

    test('form screens share typed input lists', () {
      const addExpense = BpFormScreen(
        title: 'Add Expense',
        submitLabel: 'Save',
        children: _expenseInputs,
      );
      const editExpense = BpFormScreen(
        title: 'Edit Expense',
        editLabel: 'Update',
        children: _expenseInputs,
      );

      final addJson = addExpense.toJson();
      final editJson = editExpense.toJson();

      // Same children structure
      expect(
          (addJson['children'] as List).length, (editJson['children'] as List).length);
      expect(addJson['submitLabel'], 'Save');
      expect(editJson['editLabel'], 'Update');

      // Verify specific input types
      final inputs = addJson['children'] as List;
      expect(inputs[0]['type'], 'number_input');
      expect(inputs[1]['type'], 'reference_picker');
      expect(inputs[1]['schemaKey'], 'account');
      expect(inputs[2]['type'], 'enum_selector');
      expect(inputs[3]['type'], 'text_input');
      expect(inputs[4]['type'], 'date_picker');
    });

    test('all form screens produce valid JSON', () {
      final forms = {
        'add_expense': const BpFormScreen(
          title: 'Add Expense',
          submitLabel: 'Save',
          children: _expenseInputs,
        ),
        'add_income': const BpFormScreen(
          title: 'Add Income',
          submitLabel: 'Save',
          children: _incomeInputs,
        ),
        'add_account': const BpFormScreen(
          title: 'New Account',
          submitLabel: 'Create',
          defaults: {'balance': 0},
          children: _accountInputs,
        ),
        'add_debt': const BpFormScreen(
          title: 'Add Debt',
          submitLabel: 'Save',
          children: _debtInputs,
        ),
        'add_goal': const BpFormScreen(
          title: 'New Goal',
          submitLabel: 'Create',
          defaults: {'saved': 0},
          children: _goalInputs,
        ),
        'add_transfer': const BpFormScreen(
          title: 'Transfer Funds',
          submitLabel: 'Transfer',
          children: _transferInputs,
        ),
      };

      for (final entry in forms.entries) {
        final json = entry.value.toJson();
        expect(json['type'], 'form_screen', reason: '${entry.key} type');
        expect(json['children'], isList, reason: '${entry.key} children');
        expect((json['children'] as List), isNotEmpty,
            reason: '${entry.key} has inputs');
      }

      // Transfer has two reference pickers
      final transferJson = forms['add_transfer']!.toJson();
      final transferInputs = transferJson['children'] as List;
      final refPickers =
          transferInputs.where((c) => c['type'] == 'reference_picker').toList();
      expect(refPickers, hasLength(2));
      expect(refPickers[0]['fieldKey'], 'fromAccount');
      expect(refPickers[1]['fieldKey'], 'toAccount');
    });

    test('accounts screen with assets, debts, and transfers sections', () {
      final accountsScreen = BpScreen(
        appBar: const BpAppBar(
          title: 'Accounts',
          showBack: false,
          actions: [
            BpIconButton(
              icon: 'add',
              tooltip: 'Transfer Funds',
              action: NavigateAction(
                screen: 'add_transfer',
                params: {'_schemaKey': 'transfer'},
              ),
            ),
          ],
        ),
        children: [
          BpScrollColumn(children: [
            BpSection(title: 'Assets', children: [
              const BpStatCard(
                label: 'Total Assets',
                expression: 'sum(balance)',
                format: 'currency',
                filter: [BpFilter(field: 'schemaKey', value: 'account')],
              ),
              BpEntryList(
                filter: const [BpFilter(field: 'schemaKey', value: 'account')],
                query: const BpQuery(orderBy: 'name', direction: 'asc'),
                itemLayout: BpEntryCard(
                  title: '{{name}}',
                  subtitle: '{{accountType}} · {{institution}}',
                  trailing: '{{balance}}',
                  trailingFormat: 'currency',
                  onTap: const NavigateAction(
                    screen: 'edit_account',
                    forwardFields: _accountFields,
                    params: {'_schemaKey': 'account'},
                  ),
                  swipeActions: BpSwipeActions(
                    right: _confirmDelete(
                      'Delete Account',
                      'Delete this account? This cannot be undone.',
                    ),
                  ),
                ),
              ),
            ]),
            BpSection(title: 'Debts', children: [
              BpEntryList(
                filter: const [BpFilter(field: 'schemaKey', value: 'debt')],
                query: const BpQuery(orderBy: 'balance', direction: 'desc'),
                itemLayout: BpEntryCard(
                  title: '{{name}}',
                  subtitle: '{{interestRate}}% · min {{minimumPayment}}',
                  trailing: '{{balance}}',
                  trailingFormat: 'currency',
                  onTap: const NavigateAction(
                    screen: 'edit_debt',
                    forwardFields: _debtFields,
                    params: {'_schemaKey': 'debt'},
                  ),
                  swipeActions: BpSwipeActions(
                    right: _confirmDelete('Delete Debt', 'Delete this debt entry?'),
                  ),
                ),
              ),
            ]),
            BpSection(title: 'Recent Transfers', children: [
              BpEntryList(
                filter: const [BpFilter(field: 'schemaKey', value: 'transfer')],
                query: const BpQuery(
                    orderBy: 'date', direction: 'desc', limit: 10),
                itemLayout: BpEntryCard(
                  title: '{{fromAccount}} → {{toAccount}}',
                  subtitle: '{{note}}',
                  trailing: '{{amount}}',
                  trailingFormat: 'currency',
                  onTap: const NavigateAction(
                    screen: 'edit_transfer',
                    forwardFields: _transferFields,
                    params: {'_schemaKey': 'transfer'},
                  ),
                  swipeActions: BpSwipeActions(
                    right: _confirmDelete(
                      'Delete Transfer',
                      'Delete this transfer? Balances will be reversed.',
                    ),
                  ),
                ),
              ),
            ]),
          ]),
        ],
      );

      final json = accountsScreen.toJson();

      // AppBar
      expect(json['appBar']['title'], 'Accounts');
      expect(json['appBar']['actions'][0]['tooltip'], 'Transfer Funds');

      // Three sections
      final scrollCol = (json['children'] as List)[0] as Map;
      final sections = scrollCol['children'] as List;
      expect(sections, hasLength(3));
      expect(sections[0]['title'], 'Assets');
      expect(sections[1]['title'], 'Debts');
      expect(sections[2]['title'], 'Recent Transfers');

      // Transfer entry card has → in title template
      final transferList = (sections[2]['children'] as List)[0] as Map;
      expect(
          transferList['itemLayout']['title'], '{{fromAccount}} → {{toAccount}}');
    });

    test('navigation with bottom nav and drawer', () {
      const navigation = ModuleNavigation(
        bottomNav: BottomNav(items: [
          NavItem(label: 'Home', icon: 'chart', screenId: 'main'),
          NavItem(label: 'Spending', icon: 'receipt', screenId: 'spending'),
          NavItem(label: 'Accounts', icon: 'wallet', screenId: 'accounts'),
          NavItem(label: 'Goals', icon: 'star', screenId: 'goals'),
        ]),
        drawer: DrawerNav(
          header: 'Finance',
          items: [
            NavItem(
                label: 'Add Expense', icon: 'receipt', screenId: 'add_expense'),
            NavItem(
                label: 'Add Income', icon: 'cash', screenId: 'add_income'),
            NavItem(
                label: 'New Account', icon: 'wallet', screenId: 'add_account'),
            NavItem(label: 'New Goal', icon: 'star', screenId: 'add_goal'),
            NavItem(
                label: 'Transfer Funds',
                icon: 'wallet',
                screenId: 'add_transfer'),
          ],
        ),
      );

      final json = navigation.toJson();

      // Bottom nav — 4 tabs matching our 4 main screens
      expect(json['bottomNav'], isNotNull);
      final bottomItems = json['bottomNav']['items'] as List;
      expect(bottomItems, hasLength(4));
      expect(bottomItems[0]['label'], 'Home');
      expect(bottomItems[0]['screenId'], 'main');
      expect(bottomItems[1]['label'], 'Spending');
      expect(bottomItems[2]['label'], 'Accounts');
      expect(bottomItems[3]['label'], 'Goals');

      // Drawer — header + 5 quick-add items
      expect(json['drawer'], isNotNull);
      expect(json['drawer']['header'], 'Finance');
      final drawerItems = json['drawer']['items'] as List;
      expect(drawerItems, hasLength(5));
      expect(drawerItems[0]['label'], 'Add Expense');
      expect(drawerItems[0]['screenId'], 'add_expense');
      expect(drawerItems[4]['label'], 'Transfer Funds');

      // Roundtrip: fromJson → toJson produces same structure
      final roundtripped = ModuleNavigation.fromJson(json).toJson();
      expect(roundtripped['bottomNav']['items'], hasLength(4));
      expect(roundtripped['drawer']['items'], hasLength(5));
      expect(roundtripped['drawer']['header'], 'Finance');
    });

    test('navigation JSON matches raw finance template structure', () {
      // Build navigation with typed classes
      const navigation = ModuleNavigation(
        bottomNav: BottomNav(items: [
          NavItem(label: 'Home', icon: 'chart', screenId: 'main'),
          NavItem(label: 'Spending', icon: 'receipt', screenId: 'spending'),
          NavItem(label: 'Accounts', icon: 'wallet', screenId: 'accounts'),
          NavItem(label: 'Goals', icon: 'star', screenId: 'goals'),
        ]),
        drawer: DrawerNav(
          header: 'Finance',
          items: [
            NavItem(
                label: 'Add Expense', icon: 'receipt', screenId: 'add_expense'),
            NavItem(
                label: 'Add Income', icon: 'cash', screenId: 'add_income'),
            NavItem(
                label: 'New Account', icon: 'wallet', screenId: 'add_account'),
            NavItem(label: 'New Goal', icon: 'star', screenId: 'add_goal'),
            NavItem(
                label: 'Transfer Funds',
                icon: 'wallet',
                screenId: 'add_transfer'),
          ],
        ),
      );

      // This is the raw JSON from the finance template
      final rawNavigation = {
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
            {
              'label': 'Add Expense',
              'icon': 'receipt',
              'screenId': 'add_expense',
            },
            {
              'label': 'Add Income',
              'icon': 'cash',
              'screenId': 'add_income',
            },
            {
              'label': 'New Account',
              'icon': 'wallet',
              'screenId': 'add_account',
            },
            {'label': 'New Goal', 'icon': 'star', 'screenId': 'add_goal'},
            {
              'label': 'Transfer Funds',
              'icon': 'wallet',
              'screenId': 'add_transfer',
            },
          ],
        },
      };

      // Typed builder output matches raw JSON exactly
      expect(navigation.toJson(), equals(rawNavigation));
    });
  });
}
