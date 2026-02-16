import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/features/schema/models/field_definition.dart';
import 'package:aj_assistant/features/schema/models/field_type.dart';
import 'package:aj_assistant/features/schema/models/module_schema.dart';
import 'package:aj_assistant/features/module_viewer/renderer/render_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testModule = Module(
    id: 'mod1',
    name: 'Test',
    schemas: {
      'default': ModuleSchema(
        label: 'Default',
        fields: {
          'name': FieldDefinition(
            key: 'name',
            type: FieldType.text,
            label: 'Name',
          ),
        },
      ),
      'category': ModuleSchema(
        label: 'Category',
        fields: {
          'title': FieldDefinition(
            key: 'title',
            type: FieldType.text,
            label: 'Title',
          ),
          'color': FieldDefinition(
            key: 'color',
            type: FieldType.text,
            label: 'Color',
          ),
        },
      ),
    },
  );

  late RenderContext ctx;

  setUp(() {
    ctx = RenderContext(
      module: testModule,
      onFormValueChanged: (_, _) {},
      onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
    );
  });

  group('getFieldDefinition', () {
    test('returns field from default schema when no schemaKey param', () {
      final field = ctx.getFieldDefinition('name');
      expect(field, isNotNull);
      expect(field!.label, 'Name');
    });

    test('returns field from named schema with schemaKey param', () {
      final field = ctx.getFieldDefinition('title', schemaKey: 'category');
      expect(field, isNotNull);
      expect(field!.label, 'Title');
    });

    test('returns null for nonexistent field', () {
      expect(ctx.getFieldDefinition('nonexistent'), isNull);
      expect(
        ctx.getFieldDefinition('nonexistent', schemaKey: 'category'),
        isNull,
      );
    });

    test('returns null for nonexistent schema', () {
      expect(ctx.getFieldDefinition('name', schemaKey: 'ghost'), isNull);
    });
  });

  group('getSchemaFields', () {
    test('returns fields map for valid schema', () {
      final fields = ctx.getSchemaFields('category');
      expect(fields, hasLength(2));
      expect(fields.containsKey('title'), true);
      expect(fields.containsKey('color'), true);
    });

    test('returns empty map for nonexistent schema', () {
      final fields = ctx.getSchemaFields('nonexistent');
      expect(fields, isEmpty);
    });
  });
}
