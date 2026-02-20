import 'package:equatable/equatable.dart';

/// Navigation configuration for a module.
///
/// When set on [Module], the module viewer renders bottom nav / drawer
/// instead of a flat screen stack.
class ModuleNavigation extends Equatable {
  final BottomNav? bottomNav;
  final DrawerNav? drawer;

  const ModuleNavigation({this.bottomNav, this.drawer});

  factory ModuleNavigation.fromJson(Map<String, dynamic> json) {
    return ModuleNavigation(
      bottomNav: json['bottomNav'] != null
          ? BottomNav.fromJson(
              Map<String, dynamic>.from(json['bottomNav'] as Map))
          : null,
      drawer: json['drawer'] != null
          ? DrawerNav.fromJson(
              Map<String, dynamic>.from(json['drawer'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (bottomNav != null) 'bottomNav': bottomNav!.toJson(),
        if (drawer != null) 'drawer': drawer!.toJson(),
      };

  @override
  List<Object?> get props => [bottomNav, drawer];
}

class BottomNav extends Equatable {
  final List<NavItem> items;

  const BottomNav({required this.items});

  factory BottomNav.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?)
            ?.map(
                (e) => NavItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];
    return BottomNav(items: items);
  }

  Map<String, dynamic> toJson() => {
        'items': [for (final item in items) item.toJson()],
      };

  @override
  List<Object?> get props => [items];
}

class DrawerNav extends Equatable {
  final List<NavItem> items;
  final String? header;

  const DrawerNav({required this.items, this.header});

  factory DrawerNav.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?)
            ?.map(
                (e) => NavItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];
    return DrawerNav(
      items: items,
      header: json['header'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': [for (final item in items) item.toJson()],
        if (header != null) 'header': header,
      };

  @override
  List<Object?> get props => [items, header];
}

class NavItem extends Equatable {
  final String label;
  final String icon;
  final String screenId;

  const NavItem({
    required this.label,
    required this.icon,
    required this.screenId,
  });

  factory NavItem.fromJson(Map<String, dynamic> json) {
    return NavItem(
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      screenId: json['screenId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'icon': icon,
        'screenId': screenId,
      };

  @override
  List<Object?> get props => [label, icon, screenId];
}
