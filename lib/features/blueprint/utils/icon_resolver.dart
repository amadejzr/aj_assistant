import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Resolves a string icon name to an [IconData] using Phosphor Icons.
///
/// Used by tab_screen_builder, module_viewer bottom nav, and drawer rendering.
IconData? resolveIcon(String? iconName) {
  return switch (iconName) {
    // Layout / navigation
    'list' => PhosphorIcons.listBullets(PhosphorIconsStyle.regular),
    'home' => PhosphorIcons.house(PhosphorIconsStyle.regular),
    'search' => PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.regular),
    'add' => PhosphorIcons.plus(PhosphorIconsStyle.regular),
    'settings' => PhosphorIcons.gear(PhosphorIconsStyle.regular),

    // Time & calendar
    'calendar' => PhosphorIcons.calendar(PhosphorIconsStyle.regular),
    'clock' => PhosphorIcons.clock(PhosphorIconsStyle.regular),
    'pending_actions' => PhosphorIcons.clockCountdown(PhosphorIconsStyle.regular),

    // Charts & stats
    'chart' => PhosphorIcons.chartBar(PhosphorIconsStyle.regular),
    'stats' => PhosphorIcons.trendUp(PhosphorIconsStyle.regular),
    'activity' => PhosphorIcons.lightning(PhosphorIconsStyle.regular),

    // Status
    'check_circle' => PhosphorIcons.checkCircle(PhosphorIconsStyle.regular),
    'check-circle' => PhosphorIcons.checkCircle(PhosphorIconsStyle.regular),
    'check' => PhosphorIcons.check(PhosphorIconsStyle.regular),
    'compass' => PhosphorIcons.compass(PhosphorIconsStyle.regular),

    // Actions
    'add' || 'plus' => PhosphorIcons.plus(PhosphorIconsStyle.regular),
    'edit' || 'pencil' => PhosphorIcons.pencilSimple(PhosphorIconsStyle.regular),
    'delete' || 'trash' => PhosphorIcons.trash(PhosphorIconsStyle.regular),
    'close' || 'x' => PhosphorIcons.x(PhosphorIconsStyle.regular),
    'share' => PhosphorIcons.shareFat(PhosphorIconsStyle.regular),

    // Finance
    'piggy_bank' => PhosphorIcons.piggyBank(PhosphorIconsStyle.regular),
    'cash' => PhosphorIcons.money(PhosphorIconsStyle.regular),
    'wallet' => PhosphorIcons.wallet(PhosphorIconsStyle.regular),
    'receipt' => PhosphorIcons.receipt(PhosphorIconsStyle.regular),

    // Content
    'book' => PhosphorIcons.bookOpen(PhosphorIconsStyle.regular),
    'note' => PhosphorIcons.notepad(PhosphorIconsStyle.regular),
    'tag' => PhosphorIcons.tag(PhosphorIconsStyle.regular),
    'star' => PhosphorIcons.star(PhosphorIconsStyle.regular),
    'heart' => PhosphorIcons.heart(PhosphorIconsStyle.regular),
    'bookmark' => PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.regular),
    'folder' => PhosphorIcons.folder(PhosphorIconsStyle.regular),
    'user' => PhosphorIcons.user(PhosphorIconsStyle.regular),

    _ => null,
  };
}
