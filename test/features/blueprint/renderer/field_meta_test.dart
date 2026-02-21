import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/features/blueprint/renderer/field_meta.dart';
import 'package:aj_assistant/features/blueprint/renderer/render_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FieldMeta', () {
    test('defaults are sensible', () {
      const meta = FieldMeta(label: 'Name');
      expect(meta.label, 'Name');
      expect(meta.required, false);
      expect(meta.options, isEmpty);
      expect(meta.min, isNull);
      expect(meta.max, isNull);
      expect(meta.step, isNull);
      expect(meta.divisions, isNull);
      expect(meta.maxLength, isNull);
      expect(meta.minLength, isNull);
      expect(meta.maxRating, isNull);
      expect(meta.multiline, false);
      expect(meta.targetSchema, isNull);
    });

    test('equatable works', () {
      const a = FieldMeta(label: 'X', required: true);
      const b = FieldMeta(label: 'X', required: true);
      const c = FieldMeta(label: 'Y');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('resolveFieldMeta', () {
    late RenderContext ctx;

    setUp(() {
      ctx = RenderContext(
        module: const Module(id: 'mod1', name: 'Test', schemas: {}),
        onFormValueChanged: (_, _) {},
        onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
      );
    });

    test('uses fieldKey as label fallback', () {
      final meta = ctx.resolveFieldMeta('amount', {});
      expect(meta.label, 'amount');
      expect(meta.required, false);
    });

    test('reads label from properties', () {
      final meta = ctx.resolveFieldMeta('amount', {'label': 'Total'});
      expect(meta.label, 'Total');
    });

    test('reads required flag', () {
      final meta = ctx.resolveFieldMeta('f', {'required': true});
      expect(meta.required, true);
    });

    test('reads options list', () {
      final meta = ctx.resolveFieldMeta('cat', {
        'options': ['A', 'B', 'C'],
      });
      expect(meta.options, ['A', 'B', 'C']);
    });

    test('reads numeric constraints', () {
      final meta = ctx.resolveFieldMeta('intensity', {
        'min': 0,
        'max': 100,
        'step': 5,
        'divisions': 20,
      });
      expect(meta.min, 0);
      expect(meta.max, 100);
      expect(meta.step, 5);
      expect(meta.divisions, 20);
    });

    test('reads text constraints', () {
      final meta = ctx.resolveFieldMeta('bio', {
        'maxLength': 200,
        'minLength': 10,
        'multiline': true,
      });
      expect(meta.maxLength, 200);
      expect(meta.minLength, 10);
      expect(meta.multiline, true);
    });

    test('reads rating constraint', () {
      final meta = ctx.resolveFieldMeta('stars', {'maxRating': 10});
      expect(meta.maxRating, 10);
    });

    test('reads targetSchema for references', () {
      final meta = ctx.resolveFieldMeta('account_id', {
        'targetSchema': 'account',
      });
      expect(meta.targetSchema, 'account');
    });

    test('reads all properties together', () {
      final meta = ctx.resolveFieldMeta('amount', {
        'label': 'Amount',
        'required': true,
        'min': 0,
        'max': 1000,
      });
      expect(meta.label, 'Amount');
      expect(meta.required, true);
      expect(meta.min, 0);
      expect(meta.max, 1000);
    });
  });
}
