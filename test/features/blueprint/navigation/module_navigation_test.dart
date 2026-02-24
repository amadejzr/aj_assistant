import 'package:bowerlab/features/blueprint/navigation/module_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NavItem', () {
    test('toJson / fromJson roundtrip', () {
      const item = NavItem(label: 'Home', icon: 'home', screenId: 'main');
      final restored = NavItem.fromJson(item.toJson());
      expect(restored, equals(item));
    });
  });

  group('BottomNav', () {
    test('toJson / fromJson roundtrip', () {
      const nav = BottomNav(items: [
        NavItem(label: 'Tasks', icon: 'check', screenId: 'main'),
        NavItem(label: 'Calendar', icon: 'calendar', screenId: 'calendar'),
      ]);
      final restored = BottomNav.fromJson(nav.toJson());
      expect(restored, equals(nav));
      expect(restored.items.length, 2);
    });
  });

  group('DrawerNav', () {
    test('toJson / fromJson roundtrip with header', () {
      const drawer = DrawerNav(
        header: 'Finance',
        items: [
          NavItem(label: 'Settings', icon: 'settings', screenId: 'settings'),
        ],
      );
      final restored = DrawerNav.fromJson(drawer.toJson());
      expect(restored, equals(drawer));
      expect(restored.header, 'Finance');
    });

    test('header is optional', () {
      const drawer = DrawerNav(items: [
        NavItem(label: 'Info', icon: 'info', screenId: 'info'),
      ]);
      final json = drawer.toJson();
      expect(json.containsKey('header'), false);
    });
  });

  group('ModuleNavigation', () {
    test('toJson / fromJson roundtrip with both', () {
      const nav = ModuleNavigation(
        bottomNav: BottomNav(items: [
          NavItem(label: 'Home', icon: 'home', screenId: 'main'),
          NavItem(label: 'Stats', icon: 'chart', screenId: 'stats'),
        ]),
        drawer: DrawerNav(
          header: 'My Module',
          items: [
            NavItem(label: 'Settings', icon: 'gear', screenId: 'settings'),
          ],
        ),
      );
      final restored = ModuleNavigation.fromJson(nav.toJson());
      expect(restored, equals(nav));
    });

    test('toJson / fromJson with bottomNav only', () {
      const nav = ModuleNavigation(
        bottomNav: BottomNav(items: [
          NavItem(label: 'Home', icon: 'home', screenId: 'main'),
        ]),
      );
      final json = nav.toJson();
      expect(json.containsKey('drawer'), false);
      final restored = ModuleNavigation.fromJson(json);
      expect(restored.drawer, isNull);
      expect(restored.bottomNav, isNotNull);
    });

    test('fromJson with empty map returns null fields', () {
      final nav = ModuleNavigation.fromJson({});
      expect(nav.bottomNav, isNull);
      expect(nav.drawer, isNull);
    });
  });
}
