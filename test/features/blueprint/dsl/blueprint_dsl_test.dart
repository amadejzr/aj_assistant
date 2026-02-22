import 'package:aj_assistant/features/blueprint/dsl/blueprint_dsl.dart';
import 'package:aj_assistant/features/blueprint/renderer/blueprint_node.dart';
import 'package:aj_assistant/features/blueprint/renderer/blueprint_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─── 1. Each builder produces correct `type` key ───

  group('type key', () {
    test('Actions.button has type "button"', () {
      final json = Actions.button(label: 'Go');
      expect(json['type'], 'button');
    });

    test('Actions.fab has type "fab"', () {
      final json = Actions.fab();
      expect(json['type'], 'fab');
    });

    test('Actions.iconButton has type "icon_button"', () {
      final json = Actions.iconButton(icon: 'pencil');
      expect(json['type'], 'icon_button');
    });

    test('Actions.actionMenu has type "action_menu"', () {
      final json = Actions.actionMenu();
      expect(json['type'], 'action_menu');
    });

    test('Display.statCard has type "stat_card"', () {
      final json = Display.statCard(label: 'Total');
      expect(json['type'], 'stat_card');
    });

    test('Display.entryList has type "entry_list"', () {
      final json = Display.entryList();
      expect(json['type'], 'entry_list');
    });

    test('Display.entryCard has type "entry_card"', () {
      final json = Display.entryCard();
      expect(json['type'], 'entry_card');
    });

    test('Display.textDisplay has type "text_display"', () {
      final json = Display.textDisplay();
      expect(json['type'], 'text_display');
    });

    test('Display.progressBar has type "progress_bar"', () {
      final json = Display.progressBar();
      expect(json['type'], 'progress_bar');
    });

    test('Display.chart has type "chart"', () {
      final json = Display.chart();
      expect(json['type'], 'chart');
    });

    test('Display.emptyState has type "empty_state"', () {
      final json = Display.emptyState();
      expect(json['type'], 'empty_state');
    });

    test('Display.badge has type "badge"', () {
      final json = Display.badge(text: 'New');
      expect(json['type'], 'badge');
    });

    test('Display.cardGrid has type "card_grid"', () {
      final json = Display.cardGrid(fieldKey: 'category');
      expect(json['type'], 'card_grid');
    });

    test('Display.dateCalendar has type "date_calendar"', () {
      final json = Display.dateCalendar();
      expect(json['type'], 'date_calendar');
    });

    test('Display.divider has type "divider"', () {
      final json = Display.divider();
      expect(json['type'], 'divider');
    });

    test('Display.spacer has type "spacer"', () {
      final json = Display.spacer();
      expect(json['type'], 'spacer');
    });

    test('Inputs.textInput has type "text_input"', () {
      final json = Inputs.textInput(fieldKey: 'name');
      expect(json['type'], 'text_input');
    });

    test('Inputs.numberInput has type "number_input"', () {
      final json = Inputs.numberInput(fieldKey: 'amount');
      expect(json['type'], 'number_input');
    });

    test('Inputs.currencyInput has type "currency_input"', () {
      final json = Inputs.currencyInput(fieldKey: 'price');
      expect(json['type'], 'currency_input');
    });

    test('Inputs.datePicker has type "date_picker"', () {
      final json = Inputs.datePicker(fieldKey: 'date');
      expect(json['type'], 'date_picker');
    });

    test('Inputs.timePicker has type "time_picker"', () {
      final json = Inputs.timePicker(fieldKey: 'time');
      expect(json['type'], 'time_picker');
    });

    test('Inputs.enumSelector has type "enum_selector"', () {
      final json = Inputs.enumSelector(fieldKey: 'category');
      expect(json['type'], 'enum_selector');
    });

    test('Inputs.multiEnumSelector has type "multi_enum_selector"', () {
      final json = Inputs.multiEnumSelector(fieldKey: 'tags');
      expect(json['type'], 'multi_enum_selector');
    });

    test('Inputs.toggle has type "toggle"', () {
      final json = Inputs.toggle(fieldKey: 'active');
      expect(json['type'], 'toggle');
    });

    test('Inputs.slider has type "slider"', () {
      final json = Inputs.slider(fieldKey: 'rating');
      expect(json['type'], 'slider');
    });

    test('Inputs.ratingInput has type "rating_input"', () {
      final json = Inputs.ratingInput(fieldKey: 'stars');
      expect(json['type'], 'rating_input');
    });

    test('Inputs.referencePicker has type "reference_picker"', () {
      final json = Inputs.referencePicker(
        fieldKey: 'categoryId',
        schemaKey: 'categories',
      );
      expect(json['type'], 'reference_picker');
    });

    test('Inputs.colorPicker has type "color_picker"', () {
      final json = Inputs.colorPicker(fieldKey: 'color');
      expect(json['type'], 'color_picker');
    });

    test('Layout.screen has type "screen"', () {
      final json = Layout.screen();
      expect(json['type'], 'screen');
    });

    test('Layout.formScreen has type "form_screen"', () {
      final json = Layout.formScreen();
      expect(json['type'], 'form_screen');
    });

    test('Layout.tabScreen has type "tab_screen"', () {
      final json = Layout.tabScreen();
      expect(json['type'], 'tab_screen');
    });

    test('Layout.scrollColumn has type "scroll_column"', () {
      final json = Layout.scrollColumn();
      expect(json['type'], 'scroll_column');
    });

    test('Layout.row has type "row"', () {
      final json = Layout.row();
      expect(json['type'], 'row');
    });

    test('Layout.column has type "column"', () {
      final json = Layout.column();
      expect(json['type'], 'column');
    });

    test('Layout.section has type "section"', () {
      final json = Layout.section();
      expect(json['type'], 'section');
    });

    test('Layout.expandable has type "expandable"', () {
      final json = Layout.expandable();
      expect(json['type'], 'expandable');
    });

    test('Layout.conditional has type "conditional"', () {
      final json = Layout.conditional(condition: 'true');
      expect(json['type'], 'conditional');
    });

    test('Layout.appBar has type "app_bar"', () {
      final json = Layout.appBar();
      expect(json['type'], 'app_bar');
    });
  });

  // ─── 2. Optional params are omitted when null ───

  group('optional params omitted when null', () {
    test('Actions.button with only label omits action and style', () {
      final json = Actions.button(label: 'Go');
      expect(json.containsKey('action'), isFalse);
      expect(json.containsKey('style'), isFalse);
      expect(json['label'], 'Go');
    });

    test('Actions.button with all params includes them', () {
      final action = Act.submit();
      final json = Actions.button(
        label: 'Save',
        action: action,
        style: 'primary',
      );
      expect(json['action'], action);
      expect(json['style'], 'primary');
    });

    test('Actions.fab with no params omits icon and action', () {
      final json = Actions.fab();
      expect(json.containsKey('icon'), isFalse);
      expect(json.containsKey('action'), isFalse);
    });

    test('Actions.iconButton omits optional params', () {
      final json = Actions.iconButton(icon: 'trash');
      expect(json.containsKey('action'), isFalse);
      expect(json.containsKey('tooltip'), isFalse);
    });

    test('Display.statCard omits null optional fields', () {
      final json = Display.statCard(label: 'Total');
      expect(json.containsKey('format'), isFalse);
      expect(json.containsKey('source'), isFalse);
      expect(json.containsKey('valueKey'), isFalse);
      expect(json.containsKey('value'), isFalse);
      expect(json.containsKey('accent'), isFalse);
      expect(json.containsKey('expression'), isFalse);
      expect(json.containsKey('filter'), isFalse);
      // Always present:
      expect(json['label'], 'Total');
      expect(json['stat'], 'custom');
    });

    test('Display.entryList omits all optional fields', () {
      final json = Display.entryList();
      expect(json.containsKey('title'), isFalse);
      expect(json.containsKey('source'), isFalse);
      expect(json.containsKey('emptyState'), isFalse);
      expect(json.containsKey('itemLayout'), isFalse);
      expect(json.containsKey('pageSize'), isFalse);
      expect(json.containsKey('viewAllScreen'), isFalse);
      expect(json.containsKey('filters'), isFalse);
    });

    test('Inputs.textInput omits optional fields', () {
      final json = Inputs.textInput(fieldKey: 'name');
      expect(json.containsKey('label'), isFalse);
      expect(json.containsKey('required'), isFalse);
      expect(json.containsKey('multiline'), isFalse);
      expect(json.containsKey('maxLength'), isFalse);
      expect(json.containsKey('minLength'), isFalse);
      expect(json.containsKey('defaultValue'), isFalse);
      expect(json.containsKey('validation'), isFalse);
      expect(json.containsKey('visibleWhen'), isFalse);
    });

    test('Inputs.textInput includes all provided fields', () {
      final json = Inputs.textInput(
        fieldKey: 'notes',
        label: 'Notes',
        required: true,
        multiline: true,
        maxLength: 500,
        minLength: 10,
        defaultValue: 'Hello',
      );
      expect(json['fieldKey'], 'notes');
      expect(json['label'], 'Notes');
      expect(json['required'], true);
      expect(json['multiline'], true);
      expect(json['maxLength'], 500);
      expect(json['minLength'], 10);
      expect(json['defaultValue'], 'Hello');
    });

    test('Inputs.numberInput omits optional fields', () {
      final json = Inputs.numberInput(fieldKey: 'qty');
      expect(json.containsKey('label'), isFalse);
      expect(json.containsKey('min'), isFalse);
      expect(json.containsKey('max'), isFalse);
      expect(json.containsKey('step'), isFalse);
    });

    test('Inputs.currencyInput omits optional fields', () {
      final json = Inputs.currencyInput(fieldKey: 'price');
      expect(json.containsKey('label'), isFalse);
      expect(json.containsKey('currencySymbol'), isFalse);
      expect(json.containsKey('decimalPlaces'), isFalse);
    });

    test('Layout.screen omits all optional fields', () {
      final json = Layout.screen();
      expect(json.containsKey('title'), isFalse);
      expect(json.containsKey('appBar'), isFalse);
      expect(json.containsKey('queries'), isFalse);
      expect(json.containsKey('mutations'), isFalse);
      expect(json.containsKey('children'), isFalse);
      expect(json.containsKey('fab'), isFalse);
      expect(json.containsKey('appBarActions'), isFalse);
    });

    test('Layout.formScreen omits all optional fields', () {
      final json = Layout.formScreen();
      expect(json.containsKey('title'), isFalse);
      expect(json.containsKey('submitLabel'), isFalse);
      expect(json.containsKey('editLabel'), isFalse);
      expect(json.containsKey('defaults'), isFalse);
      expect(json.containsKey('queries'), isFalse);
      expect(json.containsKey('mutations'), isFalse);
      expect(json.containsKey('children'), isFalse);
    });

    test('Display.spacer omits height when null', () {
      final json = Display.spacer();
      expect(json.containsKey('height'), isFalse);
    });

    test('Display.spacer includes height when provided', () {
      final json = Display.spacer(height: 16.0);
      expect(json['height'], 16.0);
    });
  });

  // ─── 3. stat_card produces flat structure (no nested `properties`) ───

  group('stat_card flat structure', () {
    test('stat_card has source, valueKey, accent at top level', () {
      final card = Display.statCard(
        label: 'Total',
        source: 'q1',
        valueKey: 'val',
        accent: true,
      );
      expect(card['source'], 'q1');
      expect(card['valueKey'], 'val');
      expect(card['accent'], true);
    });

    test('stat_card does NOT have a nested properties key', () {
      final card = Display.statCard(
        label: 'Total',
        source: 'q1',
        valueKey: 'val',
        accent: true,
      );
      expect(card.containsKey('properties'), isFalse);
    });

    test('stat_card with all fields sets them at top level', () {
      final card = Display.statCard(
        label: 'Revenue',
        stat: 'sum',
        format: 'currency',
        source: 'revenue_query',
        valueKey: 'total',
        value: '1000',
        accent: true,
        expression: 'q.total * 1.1',
        filter: {'period': 'month'},
      );
      expect(card['label'], 'Revenue');
      expect(card['stat'], 'sum');
      expect(card['format'], 'currency');
      expect(card['source'], 'revenue_query');
      expect(card['valueKey'], 'total');
      expect(card['value'], '1000');
      expect(card['accent'], true);
      expect(card['expression'], 'q.total * 1.1');
      expect(card['filter'], {'period': 'month'});
      expect(card.containsKey('properties'), isFalse);
    });

    test('stat_card with accent=false omits accent key', () {
      final card = Display.statCard(label: 'Count', accent: false);
      // accent is only set when true (accent == true check in builder)
      expect(card.containsKey('accent'), isFalse);
    });
  });

  // ─── 4. Full screen round-trip (DSL -> parse -> node tree) ───

  group('full screen round-trip', () {
    test('screen with row and stat_card parses into correct node tree', () {
      final screen = Layout.screen(
        title: 'Test',
        children: [
          Layout.row(
            children: [
              Display.statCard(label: 'Count', source: 'q', valueKey: 'n'),
            ],
          ),
        ],
      );
      final parser = BlueprintParser();
      final node = parser.parse(screen);

      expect(node, isA<ScreenNode>());
      final screenNode = node as ScreenNode;
      expect(screenNode.title, 'Test');
      expect(screenNode.children, hasLength(1));

      final rowNode = screenNode.children.first;
      expect(rowNode, isA<RowNode>());
      expect((rowNode as RowNode).children, hasLength(1));

      final statNode = rowNode.children.first;
      expect(statNode, isA<StatCardNode>());
      expect((statNode as StatCardNode).label, 'Count');
      expect(statNode.stat, 'custom');
    });

    test('form_screen round-trip preserves structure', () {
      final form = Layout.formScreen(
        title: 'Add Entry',
        submitLabel: 'Save',
        children: [
          Inputs.textInput(fieldKey: 'name', label: 'Name', required: true),
          Inputs.numberInput(fieldKey: 'amount', label: 'Amount'),
          Inputs.datePicker(fieldKey: 'date', label: 'Date'),
        ],
      );
      final parser = BlueprintParser();
      final node = parser.parse(form);

      expect(node, isA<FormScreenNode>());
      final formNode = node as FormScreenNode;
      expect(formNode.title, 'Add Entry');
      expect(formNode.submitLabel, 'Save');
      expect(formNode.children, hasLength(3));

      expect(formNode.children[0], isA<TextInputNode>());
      expect((formNode.children[0] as TextInputNode).fieldKey, 'name');

      expect(formNode.children[1], isA<NumberInputNode>());
      expect((formNode.children[1] as NumberInputNode).fieldKey, 'amount');

      expect(formNode.children[2], isA<DatePickerNode>());
      expect((formNode.children[2] as DatePickerNode).fieldKey, 'date');
    });

    test('screen with section, entry_list, and fab round-trip', () {
      final screen = Layout.screen(
        title: 'Dashboard',
        children: [
          Layout.section(
            title: 'Recent',
            children: [
              Display.entryList(
                source: 'recent_entries',
                pageSize: 10,
                itemLayout: Display.entryCard(
                  title: r'${name}',
                  subtitle: r'${date}',
                  trailing: r'${amount}',
                ),
              ),
            ],
          ),
        ],
        fab: Actions.fab(
          icon: 'plus',
          action: Act.navigate('add_entry'),
        ),
      );
      final parser = BlueprintParser();
      final node = parser.parse(screen);

      expect(node, isA<ScreenNode>());
      final screenNode = node as ScreenNode;
      expect(screenNode.title, 'Dashboard');
      expect(screenNode.fab, isA<FabNode>());
      expect((screenNode.fab as FabNode).icon, 'plus');

      expect(screenNode.children, hasLength(1));
      final sectionNode = screenNode.children.first as SectionNode;
      expect(sectionNode.title, 'Recent');
      expect(sectionNode.children, hasLength(1));

      final entryListNode = sectionNode.children.first as EntryListNode;
      expect(entryListNode.itemLayout, isA<EntryCardNode>());
    });

    test('screen with nested layout parses deeply', () {
      final screen = Layout.screen(
        title: 'Complex',
        children: [
          Layout.scrollColumn(
            children: [
              Layout.row(
                children: [
                  Display.statCard(label: 'A', source: 'q1', valueKey: 'a'),
                  Display.statCard(label: 'B', source: 'q1', valueKey: 'b'),
                ],
              ),
              Layout.section(
                title: 'Info',
                children: [
                  Display.textDisplay(text: 'Hello'),
                  Display.progressBar(label: 'Progress', expression: '0.5'),
                ],
              ),
            ],
          ),
        ],
      );
      final parser = BlueprintParser();
      final node = parser.parse(screen) as ScreenNode;

      expect(node.children, hasLength(1));
      final scrollCol = node.children.first as ScrollColumnNode;
      expect(scrollCol.children, hasLength(2));

      final row = scrollCol.children[0] as RowNode;
      expect(row.children, hasLength(2));
      expect(row.children[0], isA<StatCardNode>());
      expect(row.children[1], isA<StatCardNode>());

      final section = scrollCol.children[1] as SectionNode;
      expect(section.title, 'Info');
      expect(section.children, hasLength(2));
      expect(section.children[0], isA<TextDisplayNode>());
      expect(section.children[1], isA<ProgressBarNode>());
    });

    test('conditional node round-trip', () {
      final screen = Layout.screen(
        title: 'Cond',
        children: [
          Layout.conditional(
            condition: 'hasEntries',
            thenChildren: [
              Display.textDisplay(text: 'Has data'),
            ],
            elseChildren: [
              Display.emptyState(message: 'No data yet'),
            ],
          ),
        ],
      );
      final parser = BlueprintParser();
      final node = parser.parse(screen) as ScreenNode;

      final condNode = node.children.first as ConditionalNode;
      expect(condNode.condition, 'hasEntries');
      expect(condNode.thenChildren, hasLength(1));
      expect(condNode.thenChildren.first, isA<TextDisplayNode>());
      expect(condNode.elseChildren, hasLength(1));
      expect(condNode.elseChildren.first, isA<EmptyStateNode>());
    });

    test('expandable node round-trip', () {
      final screen = Layout.screen(
        title: 'Expand',
        children: [
          Layout.expandable(
            title: 'Details',
            initiallyExpanded: true,
            children: [
              Display.textDisplay(text: 'Hidden content'),
            ],
          ),
        ],
      );
      final parser = BlueprintParser();
      final node = parser.parse(screen) as ScreenNode;

      final expandable = node.children.first as ExpandableNode;
      expect(expandable.title, 'Details');
      expect(expandable.initiallyExpanded, true);
      expect(expandable.children, hasLength(1));
      expect(expandable.children.first, isA<TextDisplayNode>());
    });
  });

  // ─── 5. Act helpers produce correct action shapes ───

  group('Act helpers', () {
    test('Act.navigate produces navigate action', () {
      final action = Act.navigate('add_entry');
      expect(action['type'], 'navigate');
      expect(action['screen'], 'add_entry');
      expect(action.containsKey('params'), isFalse);
      expect(action.containsKey('forwardFields'), isFalse);
      expect(action.containsKey('label'), isFalse);
    });

    test('Act.navigate with params and forwardFields', () {
      final action = Act.navigate(
        'edit_entry',
        params: {'id': r'${entry_id}'},
        forwardFields: ['name', 'amount'],
        label: 'Edit',
      );
      expect(action['type'], 'navigate');
      expect(action['screen'], 'edit_entry');
      expect(action['params'], {'id': r'${entry_id}'});
      expect(action['forwardFields'], ['name', 'amount']);
      expect(action['label'], 'Edit');
    });

    test('Act.navigateBack produces navigate_back action', () {
      final action = Act.navigateBack();
      expect(action['type'], 'navigate_back');
      expect(action.length, 1);
    });

    test('Act.submit produces submit action', () {
      final action = Act.submit();
      expect(action['type'], 'submit');
      expect(action.length, 1);
    });

    test('Act.deleteEntry produces delete_entry action', () {
      final action = Act.deleteEntry();
      expect(action['type'], 'delete_entry');
      expect(action.length, 1);
    });

    test('Act.confirm wraps onConfirm action', () {
      final action = Act.confirm(
        title: 'Delete?',
        message: 'This cannot be undone.',
        onConfirm: Act.deleteEntry(),
      );
      expect(action['type'], 'confirm');
      expect(action['title'], 'Delete?');
      expect(action['message'], 'This cannot be undone.');
      expect(action['onConfirm'], {'type': 'delete_entry'});
    });

    test('Act.confirm omits optional title and message', () {
      final action = Act.confirm(onConfirm: Act.deleteEntry());
      expect(action['type'], 'confirm');
      expect(action.containsKey('title'), isFalse);
      expect(action.containsKey('message'), isFalse);
      expect(action['onConfirm'], isA<Map<String, dynamic>>());
    });
  });

  // ─── 6. Helper classes ───

  group('Query helpers', () {
    test('Query.def produces sql map', () {
      final query = Query.def('SELECT * FROM expenses');
      expect(query['sql'], 'SELECT * FROM expenses');
      expect(query.containsKey('params'), isFalse);
      expect(query.containsKey('defaults'), isFalse);
      expect(query.containsKey('dependsOn'), isFalse);
    });

    test('Query.def with params and defaults', () {
      final query = Query.def(
        'SELECT * FROM expenses WHERE category = :cat',
        params: {'cat': 'food'},
        defaults: {'cat': 'all'},
        dependsOn: ['categories_query'],
      );
      expect(query['sql'], 'SELECT * FROM expenses WHERE category = :cat');
      expect(query['params'], {'cat': 'food'});
      expect(query['defaults'], {'cat': 'all'});
      expect(query['dependsOn'], ['categories_query']);
    });
  });

  group('Mut helpers', () {
    test('Mut.sql returns a plain string', () {
      final sql = Mut.sql('INSERT INTO expenses VALUES (...)');
      expect(sql, isA<String>());
      expect(sql, 'INSERT INTO expenses VALUES (...)');
    });

    test('Mut.object produces map with sql and refresh', () {
      final mut = Mut.object(
        sql: 'INSERT INTO expenses VALUES (...)',
        refresh: ['expenses_query'],
        onSuccess: Act.navigateBack(),
      );
      expect(mut['sql'], 'INSERT INTO expenses VALUES (...)');
      expect(mut['refresh'], ['expenses_query']);
      expect(mut['onSuccess'], {'type': 'navigate_back'});
      expect(mut.containsKey('onError'), isFalse);
    });

    test('Mut.steps produces multi-step transaction', () {
      final mut = Mut.steps(
        steps: [
          'INSERT INTO a VALUES (...)',
          'UPDATE b SET x = 1',
        ],
        refresh: ['q1'],
      );
      expect(mut['steps'], hasLength(2));
      expect(mut['refresh'], ['q1']);
    });
  });

  group('Nav helpers', () {
    test('Nav.bottomNav wraps items in bottomNav key', () {
      final nav = Nav.bottomNav(
        items: [
          Nav.item(label: 'Home', icon: 'house', screenId: 'home'),
          Nav.item(label: 'Add', icon: 'plus', screenId: 'add'),
        ],
      );
      expect(nav.containsKey('bottomNav'), isTrue);
      final bottomNav = nav['bottomNav'] as Map<String, dynamic>;
      expect(bottomNav['items'], hasLength(2));
    });

    test('Nav.drawer wraps items in drawer key', () {
      final nav = Nav.drawer(
        items: [
          Nav.item(label: 'Settings', icon: 'gear', screenId: 'settings'),
        ],
        header: 'My App',
      );
      expect(nav.containsKey('drawer'), isTrue);
      final drawer = nav['drawer'] as Map<String, dynamic>;
      expect(drawer['items'], hasLength(1));
      expect(drawer['header'], 'My App');
    });

    test('Nav.drawer omits header when null', () {
      final nav = Nav.drawer(
        items: [
          Nav.item(label: 'Home', icon: 'house', screenId: 'home'),
        ],
      );
      final drawer = nav['drawer'] as Map<String, dynamic>;
      expect(drawer.containsKey('header'), isFalse);
    });

    test('Nav.item has label, icon, and screenId', () {
      final item = Nav.item(
        label: 'Dashboard',
        icon: 'chart-bar',
        screenId: 'dashboard',
      );
      expect(item['label'], 'Dashboard');
      expect(item['icon'], 'chart-bar');
      expect(item['screenId'], 'dashboard');
    });
  });

  group('Db helper', () {
    test('Db.build produces database config', () {
      final db = Db.build(
        tableNames: {'entries': 'mod_abc_entries'},
        setup: ['CREATE TABLE mod_abc_entries (id TEXT PRIMARY KEY)'],
        teardown: ['DROP TABLE IF EXISTS mod_abc_entries'],
      );
      expect(db['tableNames'], {'entries': 'mod_abc_entries'});
      expect(db['setup'], hasLength(1));
      expect(db['teardown'], hasLength(1));
    });
  });

  group('Guide helper', () {
    test('Guide.step produces title and body', () {
      final step = Guide.step(
        title: 'Welcome',
        body: 'This is how you get started.',
      );
      expect(step['title'], 'Welcome');
      expect(step['body'], 'This is how you get started.');
    });
  });

  group('TemplateDef helper', () {
    test('TemplateDef.build produces full template with required fields', () {
      final template = TemplateDef.build(
        name: 'Expense Tracker',
        description: 'Track your expenses',
        icon: 'wallet',
        color: 'vermillion',
        category: 'finance',
        screens: {
          'home': Layout.screen(title: 'Home'),
        },
      );
      expect(template['name'], 'Expense Tracker');
      expect(template['description'], 'Track your expenses');
      expect(template['icon'], 'wallet');
      expect(template['color'], 'vermillion');
      expect(template['category'], 'finance');
      expect(template['screens'], isA<Map<String, dynamic>>());
      expect(template['installCount'], 0);
      expect(template['version'], 1);
      expect(template['settings'], <String, dynamic>{});
    });

    test('TemplateDef.build omits null optional fields', () {
      final template = TemplateDef.build(
        name: 'Test',
        description: 'Desc',
        icon: 'star',
        color: 'blue',
        category: 'other',
        screens: {'home': Layout.screen()},
      );
      expect(template.containsKey('longDescription'), isFalse);
      expect(template.containsKey('tags'), isFalse);
      expect(template.containsKey('featured'), isFalse);
      expect(template.containsKey('sortOrder'), isFalse);
      expect(template.containsKey('guide'), isFalse);
      expect(template.containsKey('navigation'), isFalse);
      expect(template.containsKey('database'), isFalse);
      expect(template.containsKey('fieldSets'), isFalse);
    });

    test('TemplateDef.build includes all optional fields when provided', () {
      final template = TemplateDef.build(
        name: 'Full Template',
        description: 'All options',
        longDescription: 'A very long description',
        icon: 'star',
        color: 'red',
        category: 'health',
        tags: ['fitness', 'tracking'],
        featured: true,
        sortOrder: 5,
        installCount: 100,
        version: 3,
        settings: {'theme': 'dark'},
        guide: [
          Guide.step(title: 'Start', body: 'Begin here'),
        ],
        navigation: Nav.bottomNav(
          items: [
            Nav.item(label: 'Home', icon: 'house', screenId: 'home'),
          ],
        ),
        database: Db.build(
          tableNames: {'entries': 'mod_x_entries'},
          setup: ['CREATE TABLE mod_x_entries (id TEXT)'],
          teardown: ['DROP TABLE IF EXISTS mod_x_entries'],
        ),
        screens: {'home': Layout.screen(title: 'Home')},
        fieldSets: {
          'core': [
            Inputs.textInput(fieldKey: 'name', label: 'Name'),
          ],
        },
      );
      expect(template['longDescription'], 'A very long description');
      expect(template['tags'], ['fitness', 'tracking']);
      expect(template['featured'], true);
      expect(template['sortOrder'], 5);
      expect(template['installCount'], 100);
      expect(template['version'], 3);
      expect(template['settings'], {'theme': 'dark'});
      expect(template['guide'], hasLength(1));
      expect(template['navigation'], isA<Map<String, dynamic>>());
      expect(template['database'], isA<Map<String, dynamic>>());
      expect(template['fieldSets'], isA<Map<String, dynamic>>());
      expect(
        (template['fieldSets'] as Map)['core'],
        hasLength(1),
      );
    });
  });

  // ─── 7. Actions.menuItem helper ───

  group('Actions.menuItem', () {
    test('menuItem has label, omits optional fields', () {
      final item = Actions.menuItem(label: 'Delete');
      expect(item['label'], 'Delete');
      expect(item.containsKey('icon'), isFalse);
      expect(item.containsKey('action'), isFalse);
      // menuItem has no 'type' key
      expect(item.containsKey('type'), isFalse);
    });

    test('menuItem includes icon and action when provided', () {
      final item = Actions.menuItem(
        label: 'Edit',
        icon: 'pencil',
        action: Act.navigate('edit_screen'),
      );
      expect(item['label'], 'Edit');
      expect(item['icon'], 'pencil');
      expect(item['action'], isA<Map<String, dynamic>>());
      expect((item['action'] as Map)['type'], 'navigate');
    });
  });
}
