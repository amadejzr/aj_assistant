import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/breathing_fab.dart';

class ShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            bottom: 28,
            right: 24,
            child: BreathingFab(
              colors: colors,
              onPressed: () {
                // TODO: open chat sheet
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _SumiBottomNav(
        currentIndex: navigationShell.currentIndex,
        colors: colors,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _SumiBottomNav extends StatelessWidget {
  final int currentIndex;
  final AppColors colors;
  final ValueChanged<int> onTap;

  const _SumiBottomNav({
    required this.currentIndex,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: PhosphorIcons.house(PhosphorIconsStyle.light),
                  activeIcon: PhosphorIcons.house(PhosphorIconsStyle.bold),
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  colors: colors,
                  onTap: () => onTap(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: PhosphorIcons.squaresFour(PhosphorIconsStyle.light),
                  activeIcon:
                      PhosphorIcons.squaresFour(PhosphorIconsStyle.bold),
                  label: 'Modules',
                  isSelected: currentIndex == 1,
                  colors: colors,
                  onTap: () => onTap(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final AppColors colors;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? colors.accent : colors.onBackgroundMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.karla(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
