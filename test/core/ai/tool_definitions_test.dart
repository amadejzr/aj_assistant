import 'package:flutter_test/flutter_test.dart';
import 'package:aj_assistant/core/ai/tool_definitions.dart';

void main() {
  group('toolDefinitions', () {
    test('contains exactly 6 tools', () {
      expect(toolDefinitions, hasLength(6));
    });

    test('all tools have required fields', () {
      for (final tool in toolDefinitions) {
        expect(tool['name'], isA<String>());
        expect(tool['description'], isA<String>());
        expect(tool['input_schema'], isA<Map>());
        expect(tool['input_schema']['type'], 'object');
      }
    });

    test('tool names match expected set', () {
      final names = toolDefinitions.map((t) => t['name']).toSet();
      expect(names, {
        'createEntry',
        'createEntries',
        'queryEntries',
        'updateEntry',
        'updateEntries',
        'getModuleSummary',
      });
    });

    test('write tools are identified correctly', () {
      expect(toolsRequiringApproval, {
        'createEntry',
        'createEntries',
        'updateEntry',
        'updateEntries',
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
