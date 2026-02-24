import 'package:bowerlab/features/blueprint/engine/expression_collector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const collector = ExpressionCollector();

  group('ExpressionCollector', () {
    test('collects expressions from stat_card nodes', () {
      final blueprint = {
        'type': 'screen',
        'children': [
          {
            'type': 'stat_card',
            'label': 'Total',
            'expression': 'sum(amount)',
          },
        ],
      };

      final result = collector.collect(blueprint);
      expect(result, {'sum(amount)'});
    });

    test('collects expressions from chart nodes', () {
      final blueprint = {
        'type': 'screen',
        'children': [
          {
            'type': 'chart',
            'chartType': 'donut',
            'expression': 'group(category, sum(amount))',
          },
        ],
      };

      final result = collector.collect(blueprint);
      expect(result, {'group(category, sum(amount))'});
    });

    test('collects expressions from progress_bar nodes', () {
      final blueprint = {
        'type': 'screen',
        'children': [
          {
            'type': 'progress_bar',
            'label': 'Budget',
            'expression': 'percentage(sum(amount), value(budget))',
          },
        ],
      };

      final result = collector.collect(blueprint);
      expect(result, {'percentage(sum(amount), value(budget))'});
    });

    test('collects expressions from badge nodes', () {
      final blueprint = {
        'type': 'screen',
        'children': [
          {
            'type': 'badge',
            'text': 'Count',
            'expression': 'count()',
          },
        ],
      };

      final result = collector.collect(blueprint);
      expect(result, {'count()'});
    });

    test('skips nodes with a non-empty filter property', () {
      final blueprint = {
        'type': 'screen',
        'children': [
          {
            'type': 'stat_card',
            'label': 'Filtered',
            'expression': 'sum(amount)',
            'filter': {'category': 'Food'},
          },
          {
            'type': 'stat_card',
            'label': 'Unfiltered',
            'expression': 'count()',
          },
        ],
      };

      final result = collector.collect(blueprint);
      expect(result, {'count()'});
      expect(result.contains('sum(amount)'), isFalse);
    });

    test('skips nodes with array filter', () {
      final blueprint = {
        'type': 'screen',
        'children': [
          {
            'type': 'stat_card',
            'label': 'Filtered',
            'expression': 'sum(amount)',
            'filter': [
              {'field': 'category', 'op': '==', 'value': 'Food'},
            ],
          },
        ],
      };

      final result = collector.collect(blueprint);
      expect(result, isEmpty);
    });

    test('does not skip nodes with empty filter map', () {
      final blueprint = {
        'type': 'screen',
        'children': [
          {
            'type': 'stat_card',
            'label': 'Total',
            'expression': 'sum(amount)',
            'filter': <String, dynamic>{},
          },
        ],
      };

      final result = collector.collect(blueprint);
      expect(result, {'sum(amount)'});
    });

    test('returns empty set for blueprint with no expressions', () {
      final blueprint = {
        'type': 'screen',
        'children': [
          {
            'type': 'text_display',
            'text': 'Hello',
          },
          {
            'type': 'button',
            'label': 'Click me',
          },
        ],
      };

      final result = collector.collect(blueprint);
      expect(result, isEmpty);
    });

    test('handles nested layouts (scroll_column > section > row > stat_card)',
        () {
      final blueprint = {
        'type': 'screen',
        'layout': {
          'type': 'scroll_column',
          'children': [
            {
              'type': 'section',
              'title': 'Stats',
              'children': [
                {
                  'type': 'row',
                  'children': [
                    {
                      'type': 'stat_card',
                      'label': 'Total',
                      'expression': 'sum(amount)',
                    },
                    {
                      'type': 'stat_card',
                      'label': 'Count',
                      'expression': 'count()',
                    },
                  ],
                },
              ],
            },
            {
              'type': 'section',
              'title': 'Chart',
              'children': [
                {
                  'type': 'chart',
                  'expression': 'group(category, sum(amount))',
                },
              ],
            },
          ],
        },
      };

      final result = collector.collect(blueprint);
      expect(result, {
        'sum(amount)',
        'count()',
        'group(category, sum(amount))',
      });
    });

    test('deduplicates identical expressions', () {
      final blueprint = {
        'type': 'screen',
        'children': [
          {
            'type': 'stat_card',
            'label': 'Total 1',
            'expression': 'sum(amount)',
          },
          {
            'type': 'stat_card',
            'label': 'Total 2',
            'expression': 'sum(amount)',
          },
        ],
      };

      final result = collector.collect(blueprint);
      expect(result.length, 1);
      expect(result, {'sum(amount)'});
    });

    test('handles tab screen tabs', () {
      final blueprint = {
        'type': 'tab_screen',
        'tabs': [
          {
            'label': 'Overview',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'stat_card',
                  'label': 'Total',
                  'expression': 'sum(amount)',
                },
              ],
            },
          },
          {
            'label': 'Details',
            'content': {
              'type': 'scroll_column',
              'children': [
                {
                  'type': 'progress_bar',
                  'expression': 'percentage(sum(amount), value(budget))',
                },
              ],
            },
          },
        ],
      };

      final result = collector.collect(blueprint);
      expect(result, {
        'sum(amount)',
        'percentage(sum(amount), value(budget))',
      });
    });

    test('skips stat_card with no expression', () {
      final blueprint = {
        'type': 'screen',
        'children': [
          {
            'type': 'stat_card',
            'label': 'Count',
            'stat': 'count',
          },
        ],
      };

      final result = collector.collect(blueprint);
      expect(result, isEmpty);
    });
  });
}
