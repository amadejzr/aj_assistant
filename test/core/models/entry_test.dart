import 'package:aj_assistant/core/models/entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Entry', () {
    test('construction — schemaKey defaults to "default"', () {
      const entry = Entry(id: 'e1', data: {'x': 1});
      expect(entry.schemaKey, 'default');
    });

    test('construction with schemaKey', () {
      const entry = Entry(id: 'e1', data: {}, schemaKey: 'expense');
      expect(entry.schemaKey, 'expense');
    });

    test('equality — same data + schemaKey are equal', () {
      const a = Entry(id: 'e1', data: {'x': 1}, schemaKey: 'expense');
      const b = Entry(id: 'e1', data: {'x': 1}, schemaKey: 'expense');
      expect(a, equals(b));
    });

    test('inequality — same data, different schemaKey', () {
      const a = Entry(id: 'e1', data: {'x': 1}, schemaKey: 'expense');
      const b = Entry(id: 'e1', data: {'x': 1}, schemaKey: 'income');
      expect(a, isNot(equals(b)));
    });

    test('toFirestore includes schemaKey', () {
      const entry = Entry(id: 'e1', data: {'x': 1}, schemaKey: 'expense');
      final json = entry.toFirestore();
      expect(json['schemaKey'], 'expense');
    });

    test('toFirestore default schemaKey', () {
      const entry = Entry(id: 'e1', data: {});
      final json = entry.toFirestore();
      expect(json['schemaKey'], 'default');
    });
  });
}
