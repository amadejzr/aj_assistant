import 'package:aj_assistant/core/models/module.dart';
import 'package:aj_assistant/features/blueprint/navigation/module_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Module', () {
    test('construction — defaults are sensible', () {
      const module = Module(id: 'test', name: 'Test');
      expect(module.id, 'test');
      expect(module.name, 'Test');
      expect(module.version, 1);
    });

    test('equality — modules with same fields are equal', () {
      const a = Module(id: 'x', name: 'X');
      const b = Module(id: 'x', name: 'X');
      expect(a, equals(b));
    });

    test('copyWith — change name, keep id', () {
      const original = Module(id: 'x', name: 'Old');
      final copied = original.copyWith(name: 'New');
      expect(copied.name, 'New');
      expect(copied.id, 'x');
    });

    test('copyWith — no args returns equal copy', () {
      const original = Module(id: 'x', name: 'X');
      final copied = original.copyWith();
      expect(copied, equals(original));
    });

    test('toFirestore / fromFirestore roundtrip', () {
      const original = Module(
        id: 'exp',
        name: 'Expenses',
        description: 'Track money',
        icon: 'wallet',
        color: '#D94E33',
        sortOrder: 1,
      );
      final json = original.toFirestore();
      expect(json['name'], 'Expenses');
      expect(json['description'], 'Track money');
      expect(json['icon'], 'wallet');
    });

    test('toFirestore does not write schemas key', () {
      const module = Module(id: 'x', name: 'X');
      final json = module.toFirestore();
      expect(json.containsKey('schemas'), false);
    });

    test('Module with navigation roundtrips through toFirestore', () {
      const module = Module(
        id: 'test',
        name: 'Test',
        navigation: ModuleNavigation(
          bottomNav: BottomNav(items: [
            NavItem(label: 'Home', icon: 'home', screenId: 'main'),
            NavItem(label: 'Stats', icon: 'chart', screenId: 'stats'),
          ]),
        ),
      );
      final json = module.toFirestore();
      expect(json['navigation'], isNotNull);
      expect(
          (json['navigation']['bottomNav']['items'] as List).length, 2);
    });

    test('Module without navigation — backward compat', () {
      const module = Module(id: 'test', name: 'Test');
      final json = module.toFirestore();
      expect(json.containsKey('navigation'), false);
    });

    test('copyWith navigation', () {
      const module = Module(id: 'test', name: 'Test');
      final updated = module.copyWith(
        navigation: const ModuleNavigation(
          bottomNav: BottomNav(items: [
            NavItem(label: 'Home', icon: 'home', screenId: 'main'),
          ]),
        ),
      );
      expect(updated.navigation, isNotNull);
      expect(updated.navigation!.bottomNav!.items.length, 1);
    });
  });
}
