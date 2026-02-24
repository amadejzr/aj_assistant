import 'package:bowerlab/features/blueprint/engine/default_value_resolver.dart';
import 'package:bowerlab/features/blueprint/renderer/render_context.dart';
import 'package:bowerlab/core/models/module.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  final ctx = RenderContext(
    module: const Module(
      id: 'test',
      name: 'Test',
      settings: {'currency': 'USD'},
    ),
    onFormValueChanged: (_, _) {},
    onNavigateToScreen: (_, {params = const {}}) {},
    screenParams: {'_entryId': '123', 'accountId': 'acc-1'},
  );

  group('DefaultValueResolver.resolve', () {
    test('{{today}} returns today\'s date in yyyy-MM-dd format', () {
      final result = DefaultValueResolver.resolve('{{today}}', ctx);

      final expected = DateFormat('yyyy-MM-dd').format(DateTime.now());
      expect(result, expected);
    });

    test('{{now}} returns ISO 8601 datetime string', () {
      final before = DateTime.now();
      final result = DefaultValueResolver.resolve('{{now}}', ctx) as String;
      final after = DateTime.now();

      final parsed = DateTime.parse(result);
      // The resolved time should be between before and after
      expect(
        parsed.isAfter(before.subtract(const Duration(seconds: 1))) &&
            parsed.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('{{param.accountId}} returns value from screen params', () {
      final result = DefaultValueResolver.resolve('{{param.accountId}}', ctx);

      expect(result, 'acc-1');
    });

    test('{{settings.currency}} returns value from module settings', () {
      final result = DefaultValueResolver.resolve('{{settings.currency}}', ctx);

      expect(result, 'USD');
    });

    test('{{entry.accountId}} returns value from screen params', () {
      // Entry data is forwarded as screen params
      final result = DefaultValueResolver.resolve('{{entry.accountId}}', ctx);

      expect(result, 'acc-1');
    });

    test('{{entry._entryId}} returns _entryId from screen params', () {
      final result = DefaultValueResolver.resolve('{{entry._entryId}}', ctx);

      expect(result, '123');
    });

    test('null defaultValue returns null', () {
      final result = DefaultValueResolver.resolve(null, ctx);

      expect(result, isNull);
    });

    test('non-token string returns as-is (literal default)', () {
      final result = DefaultValueResolver.resolve('Hello World', ctx);

      expect(result, 'Hello World');
    });

    test('number literal returns as-is', () {
      final result = DefaultValueResolver.resolve(42, ctx);

      expect(result, 42);
    });

    test('double literal returns as-is', () {
      final result = DefaultValueResolver.resolve(3.14, ctx);

      expect(result, 3.14);
    });

    test('boolean literal returns as-is', () {
      expect(DefaultValueResolver.resolve(true, ctx), true);
      expect(DefaultValueResolver.resolve(false, ctx), false);
    });

    test('unknown token returns null', () {
      final result = DefaultValueResolver.resolve('{{unknown}}', ctx);

      expect(result, isNull);
    });

    test('unknown param key returns null', () {
      final result =
          DefaultValueResolver.resolve('{{param.nonexistent}}', ctx);

      expect(result, isNull);
    });

    test('unknown settings key returns null', () {
      final result =
          DefaultValueResolver.resolve('{{settings.nonexistent}}', ctx);

      expect(result, isNull);
    });

    test('unknown entry field returns null', () {
      final result =
          DefaultValueResolver.resolve('{{entry.nonexistent}}', ctx);

      expect(result, isNull);
    });

    test('string that looks like token but is not properly wrapped returns as-is', () {
      // Single braces — not a token
      expect(DefaultValueResolver.resolve('{today}', ctx), '{today}');
      // Only opening braces
      expect(DefaultValueResolver.resolve('{{today', ctx), '{{today');
    });

    test('whitespace inside token is trimmed', () {
      final result = DefaultValueResolver.resolve('{{ today }}', ctx);

      final expected = DateFormat('yyyy-MM-dd').format(DateTime.now());
      expect(result, expected);
    });
  });
}
