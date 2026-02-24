import 'package:bowerlab/core/models/module.dart';
import 'package:bowerlab/features/blueprint/renderer/reference_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testModule = Module(
    id: 'expenses',
    name: 'Finances',
  );

  const allEntries = [
    {'id': 'cat1', 'name': 'Food', 'schemaKey': 'category'},
    {'id': 'cat2', 'name': 'Transport', 'schemaKey': 'category'},
    {
      'id': 'acc1',
      'title': 'Checking',
      'balance': 1000,
      'schemaKey': 'account'
    },
    {
      'id': 'exp1',
      'note': 'Lunch',
      'category': 'cat1',
      'amount': 15,
      'schemaKey': 'expense'
    },
  ];

  late ReferenceResolver resolver;

  setUp(() {
    resolver = const ReferenceResolver(
      module: testModule,
      allEntries: allEntries,
    );
  });

  group('ReferenceResolver', () {
    test('resolves entry ID to display name', () {
      final result = resolver.resolve('category', 'cat1');
      expect(result, 'Food');
    });

    test('resolves different entry ID to display name', () {
      final result = resolver.resolve('category', 'cat2');
      expect(result, 'Transport');
    });

    test('returns raw value when referenced entry has no name field', () {
      // acc1 has 'title' not 'name', so falls back to raw ID
      final result = resolver.resolve('account', 'acc1');
      expect(result, 'acc1');
    });

    test('returns raw value as string for non-null values', () {
      final result = resolver.resolve('amount', 42);
      expect(result, '42');
    });

    test('returns empty string for null value', () {
      final result = resolver.resolve('category', null);
      expect(result, '');
    });

    test('returns raw ID when referenced entry not found', () {
      final result = resolver.resolve('category', 'cat_nonexistent');
      expect(result, 'cat_nonexistent');
    });

    group('resolveField (dot notation)', () {
      test('resolves specific subfield from referenced entry', () {
        final result = resolver.resolveField(
          'account',
          'balance',
          'acc1',
        );
        expect(result, '1000');
      });

      test('resolves text subfield from referenced entry', () {
        final result = resolver.resolveField(
          'account',
          'title',
          'acc1',
        );
        expect(result, 'Checking');
      });

      test('resolves name from category reference', () {
        final result = resolver.resolveField(
          'category',
          'name',
          'cat1',
        );
        expect(result, 'Food');
      });

      test('returns empty string for null value', () {
        final result = resolver.resolveField(
          'category',
          'name',
          null,
        );
        expect(result, '');
      });

      test('returns empty string when referenced entry not found', () {
        final result = resolver.resolveField(
          'category',
          'name',
          'nonexistent',
        );
        expect(result, '');
      });

      test('returns empty string when subfield not in referenced entry', () {
        final result = resolver.resolveField(
          'category',
          'nonexistent_field',
          'cat1',
        );
        expect(result, '');
      });
    });
  });
}
