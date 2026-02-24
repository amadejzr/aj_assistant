import 'package:flutter_test/flutter_test.dart';
import 'package:bowerlab/core/ai/tool_definitions.dart';

void main() {
  group('toolDefinitions', () {
    test('core tools contains 7 tools (no createModule)', () {
      expect(coreToolDefinitions, hasLength(7));
      final names = coreToolDefinitions.map((t) => t['name']).toSet();
      expect(names, isNot(contains('createModule')));
    });

    test('getToolDefinitions with module creation includes all 8', () {
      final all = getToolDefinitions(includeModuleCreation: true);
      expect(all, hasLength(8));
    });

    test('getToolDefinitions without module creation has 7', () {
      final core = getToolDefinitions(includeModuleCreation: false);
      expect(core, hasLength(7));
      final names = core.map((t) => t['name']).toSet();
      expect(names, isNot(contains('createModule')));
    });

    test('all tools have required fields', () {
      final all = getToolDefinitions();
      for (final tool in all) {
        expect(tool['name'], isA<String>());
        expect(tool['description'], isA<String>());
        expect(tool['input_schema'], isA<Map>());
        expect(tool['input_schema']['type'], 'object');
      }
    });

    test('tool names match expected set', () {
      final names = getToolDefinitions().map((t) => t['name']).toSet();
      expect(names, {
        'createEntry',
        'createEntries',
        'queryEntries',
        'updateEntry',
        'updateEntries',
        'getModuleSummary',
        'runQuery',
        'createModule',
      });
    });

    test('write tools are identified correctly', () {
      expect(toolsRequiringApproval, {
        'createEntry',
        'createEntries',
        'updateEntry',
        'updateEntries',
        'createModule',
      });
    });

    test('describeAction formats createEntry', () {
      final desc = describeAction('createEntry', {
        'schemaKey': 'default',
        'data': {'name': 'Groceries', 'amount': 50},
      });
      expect(desc, contains('Create entry'));
      expect(desc, contains('default'));
    });

    test('describeAction formats createEntries', () {
      final desc = describeAction('createEntries', {
        'schemaKey': 'meals',
        'entries': [
          {'data': {}},
          {'data': {}},
        ],
      });
      expect(desc, contains('2 entries'));
    });
  });
}
