import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/features/blueprint/renderer/render_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testModule = Module(
    id: 'mod1',
    name: 'Test',
  );

  late RenderContext ctx;

  setUp(() {
    ctx = RenderContext(
      module: testModule,
      onFormValueChanged: (_, _) {},
      onNavigateToScreen: (_, {Map<String, dynamic> params = const {}}) {},
    );
  });

  group('RenderContext basics', () {
    test('exposes module', () {
      expect(ctx.module.id, 'mod1');
      expect(ctx.module.name, 'Test');
    });

    test('formValues defaults to empty', () {
      expect(ctx.formValues, isEmpty);
    });

    test('entries defaults to empty', () {
      expect(ctx.entries, isEmpty);
    });
  });
}
