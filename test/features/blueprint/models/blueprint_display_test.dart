import 'package:aj_assistant/features/blueprint/models/blueprint.dart';
import 'package:aj_assistant/features/blueprint/models/blueprint_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BpFilter', () {
    test('toJson with defaults', () {
      const f = BpFilter(field: 'status', value: 'done');
      expect(f.toJson(), {'field': 'status', 'op': '==', 'value': 'done'});
    });

    test('toJson with custom op', () {
      const f = BpFilter(field: 'amount', op: '>', value: 100);
      expect(f.toJson(), {'field': 'amount', 'op': '>', 'value': 100});
    });
  });

  group('BpQuery', () {
    test('toJson with all fields', () {
      const q = BpQuery(orderBy: 'date', direction: 'asc', limit: 10);
      expect(q.toJson(), {'orderBy': 'date', 'direction': 'asc', 'limit': 10});
    });

    test('toJson omits null orderBy and limit', () {
      const q = BpQuery();
      expect(q.toJson(), {'direction': 'desc'});
    });
  });

  group('BpSwipeActions', () {
    test('toJson with both actions', () {
      const sa = BpSwipeActions(
        left: UpdateEntryAction(data: {'status': 'done'}, label: 'Done'),
        right: DeleteEntryAction(confirm: true),
      );
      final json = sa.toJson();
      expect(json['left']['type'], 'update_entry');
      expect(json['right']['type'], 'delete_entry');
    });

    test('toJson omits null actions', () {
      const sa = BpSwipeActions();
      expect(sa.toJson(), <String, dynamic>{});
    });
  });

  group('BpStatCard', () {
    test('minimal', () {
      const card = BpStatCard(label: 'Total', expression: 'sum(amount)');
      expect(card.toJson(), {
        'type': 'stat_card',
        'label': 'Total',
        'expression': 'sum(amount)',
      });
    });

    test('with format and filter', () {
      const card = BpStatCard(
        label: 'Overdue',
        expression: 'count(where(status, !=, done))',
        format: 'integer',
        filter: [BpFilter(field: 'due_date', op: '<', value: r'$today')],
      );
      final json = card.toJson();
      expect(json['format'], 'integer');
      expect((json['filter'] as List).length, 1);
      expect((json['filter'] as List)[0]['field'], 'due_date');
    });
  });

  group('BpEntryList', () {
    test('minimal', () {
      const list = BpEntryList();
      expect(list.toJson(), {'type': 'entry_list'});
    });

    test('with query, filter, and itemLayout', () {
      const list = BpEntryList(
        query: BpQuery(orderBy: 'date', direction: 'desc', limit: 10),
        filter: [BpFilter(field: 'status', value: 'active')],
        itemLayout: BpEntryCard(
          title: '{{name}}',
          subtitle: '{{category}}',
          trailing: '{{amount}}',
          trailingFormat: 'currency',
        ),
      );
      final json = list.toJson();
      expect(json['query']['orderBy'], 'date');
      expect((json['filter'] as List)[0]['value'], 'active');
      expect(json['itemLayout']['type'], 'entry_card');
      expect(json['itemLayout']['title'], '{{name}}');
    });
  });

  group('BpEntryCard', () {
    test('minimal', () {
      const card = BpEntryCard(title: '{{title}}');
      expect(card.toJson(), {
        'type': 'entry_card',
        'title': '{{title}}',
      });
    });

    test('full card with actions', () {
      const card = BpEntryCard(
        title: '{{title}}',
        subtitle: '{{project}}',
        trailing: '{{due_date}}',
        trailingFormat: 'relative_date',
        onTap: NavigateAction(screen: 'edit_entry', forwardFields: ['title']),
        swipeActions: BpSwipeActions(
          left: UpdateEntryAction(data: {'status': 'done'}, label: 'Done'),
          right: DeleteEntryAction(confirm: true),
        ),
      );
      final json = card.toJson();
      expect(json['trailingFormat'], 'relative_date');
      expect(json['onTap']['type'], 'navigate');
      expect(json['swipeActions']['left']['type'], 'update_entry');
      expect(json['swipeActions']['right']['type'], 'delete_entry');
    });

    test('dot notation template for references', () {
      const card = BpEntryCard(
        title: '{{title}}',
        subtitle: '{{category.name}}',
        trailing: '{{account.balance}}',
      );
      final json = card.toJson();
      expect(json['subtitle'], '{{category.name}}');
      expect(json['trailing'], '{{account.balance}}');
    });
  });

  group('BpChart', () {
    test('defaults', () {
      const chart = BpChart();
      expect(chart.toJson(), {
        'type': 'chart',
        'chartType': 'donut',
      });
    });

    test('bar chart with groupBy', () {
      const chart = BpChart(
        chartType: 'bar',
        groupBy: 'category',
        aggregate: 'sum',
        expression: 'amount',
      );
      expect(chart.toJson(), {
        'type': 'chart',
        'chartType': 'bar',
        'groupBy': 'category',
        'aggregate': 'sum',
        'expression': 'amount',
      });
    });
  });

  group('BpProgressBar', () {
    test('minimal', () {
      const bar = BpProgressBar(
        label: 'Budget',
        expression: 'percentage(sum(amount), settings.budget)',
      );
      expect(bar.toJson(), {
        'type': 'progress_bar',
        'label': 'Budget',
        'expression': 'percentage(sum(amount), settings.budget)',
      });
    });

    test('with format', () {
      const bar = BpProgressBar(
        expression: 'ratio',
        format: 'percentage',
      );
      final json = bar.toJson();
      expect(json['format'], 'percentage');
    });
  });

  group('BpDateCalendar', () {
    test('defaults', () {
      const cal = BpDateCalendar();
      expect(cal.toJson(), {
        'type': 'date_calendar',
        'dateField': 'date',
      });
    });

    test('with all fields', () {
      const cal = BpDateCalendar(
        dateField: 'due_date',
        onEntryTap: NavigateAction(screen: 'edit_entry'),
        forwardFields: ['title', 'due_date'],
      );
      final json = cal.toJson();
      expect(json['dateField'], 'due_date');
      expect(json['onEntryTap']['type'], 'navigate');
      expect(json['forwardFields'], ['title', 'due_date']);
    });
  });

  group('BpTextDisplay', () {
    test('minimal', () {
      const td = BpTextDisplay(text: 'Hello World');
      expect(td.toJson(), {'type': 'text_display', 'text': 'Hello World'});
    });

    test('with style', () {
      const td = BpTextDisplay(text: 'Title', style: 'headline');
      expect(td.toJson(), {
        'type': 'text_display',
        'text': 'Title',
        'style': 'headline',
      });
    });
  });

  group('BpEmptyState', () {
    test('minimal', () {
      const es = BpEmptyState();
      expect(es.toJson(), {'type': 'empty_state'});
    });

    test('with all fields', () {
      const es = BpEmptyState(
        icon: 'inbox',
        title: 'No entries yet',
        subtitle: 'Tap + to add one',
      );
      expect(es.toJson(), {
        'type': 'empty_state',
        'icon': 'inbox',
        'title': 'No entries yet',
        'subtitle': 'Tap + to add one',
      });
    });
  });

  group('BpBadge', () {
    test('minimal', () {
      const b = BpBadge(text: 'New');
      expect(b.toJson(), {'type': 'badge', 'text': 'New'});
    });

    test('with expression and variant', () {
      const b = BpBadge(
        text: 'Overdue',
        expression: 'count(where(due_date, <, \$today))',
        variant: 'danger',
      );
      expect(b.toJson(), {
        'type': 'badge',
        'text': 'Overdue',
        'expression': 'count(where(due_date, <, \$today))',
        'variant': 'danger',
      });
    });

    test('default variant omitted', () {
      const b = BpBadge(text: 'OK');
      expect(b.toJson().containsKey('variant'), false);
    });
  });

  group('BpCardGrid', () {
    test('minimal', () {
      const grid = BpCardGrid(fieldKey: 'category');
      expect(grid.toJson(), {'type': 'card_grid', 'fieldKey': 'category'});
    });

    test('with action', () {
      const grid = BpCardGrid(
        fieldKey: 'project',
        action: NavigateAction(screen: 'project_detail'),
      );
      final json = grid.toJson();
      expect(json['action']['type'], 'navigate');
    });
  });

  group('BpDivider', () {
    test('toJson', () {
      const d = BpDivider();
      expect(d.toJson(), {'type': 'divider'});
    });
  });

  group('BpIconButton', () {
    test('minimal', () {
      const btn = BpIconButton(
        icon: 'settings',
        action: NavigateAction(screen: 'settings'),
      );
      expect(btn.toJson(), {
        'type': 'icon_button',
        'icon': 'settings',
        'action': {'type': 'navigate', 'screen': 'settings'},
      });
    });

    test('with tooltip', () {
      const btn = BpIconButton(
        icon: 'delete',
        action: DeleteEntryAction(confirm: true),
        tooltip: 'Delete this entry',
      );
      final json = btn.toJson();
      expect(json['tooltip'], 'Delete this entry');
      expect(json['action']['type'], 'delete_entry');
    });
  });

  group('BpActionMenu', () {
    test('defaults', () {
      const menu = BpActionMenu();
      expect(menu.toJson(), {
        'type': 'action_menu',
        'icon': 'more_vert',
        'items': <dynamic>[],
      });
    });

    test('with items', () {
      const menu = BpActionMenu(
        items: [
          BpActionMenuItem(
            label: 'Edit',
            icon: 'edit',
            action: NavigateAction(screen: 'edit'),
          ),
          BpActionMenuItem(
            label: 'Delete',
            action: DeleteEntryAction(confirm: true),
          ),
        ],
      );
      final json = menu.toJson();
      final items = json['items'] as List;
      expect(items.length, 2);
      expect(items[0]['label'], 'Edit');
      expect(items[0]['icon'], 'edit');
      expect(items[0]['action']['type'], 'navigate');
      expect(items[1]['label'], 'Delete');
      expect(items[1].containsKey('icon'), false);
    });
  });

  group('display nodes in layout', () {
    test('stat cards in a row', () {
      const row = BpRow(children: [
        BpStatCard(label: 'Total', expression: 'sum(amount)', format: 'currency'),
        BpStatCard(label: 'Count', expression: 'count()'),
      ]);
      final json = row.toJson();
      final children = json['children'] as List;
      expect(children[0]['type'], 'stat_card');
      expect(children[1]['type'], 'stat_card');
    });

    test('entry list in section', () {
      const section = BpSection(
        title: 'Recent',
        children: [
          BpEntryList(
            query: BpQuery(orderBy: 'date', limit: 5),
            itemLayout: BpEntryCard(
              title: '{{note}}',
              subtitle: '{{category.name}}',
              trailing: '{{amount}}',
              trailingFormat: 'currency',
            ),
          ),
        ],
      );
      final json = section.toJson();
      expect(json['title'], 'Recent');
      final entryList = (json['children'] as List)[0] as Map;
      expect(entryList['type'], 'entry_list');
      expect(entryList['itemLayout']['subtitle'], '{{category.name}}');
    });
  });

  group('equality', () {
    test('same stat cards are equal', () {
      const a = BpStatCard(label: 'X', expression: 'sum(y)');
      const b = BpStatCard(label: 'X', expression: 'sum(y)');
      expect(a, equals(b));
    });

    test('different labels are not equal', () {
      const a = BpStatCard(label: 'X', expression: 'sum(y)');
      const b = BpStatCard(label: 'Z', expression: 'sum(y)');
      expect(a, isNot(equals(b)));
    });

    test('same filters are equal', () {
      const a = BpFilter(field: 'x', value: 1);
      const b = BpFilter(field: 'x', value: 1);
      expect(a, equals(b));
    });
  });
}
