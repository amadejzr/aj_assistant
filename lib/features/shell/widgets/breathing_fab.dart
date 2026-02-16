import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_colors.dart';

class BreathingFab extends StatefulWidget {
  final VoidCallback? onPressed;
  final AppColors colors;

  const BreathingFab({
    super.key,
    this.onPressed,
    required this.colors,
  });

  @override
  State<BreathingFab> createState() => _BreathingFabState();
}

class _BreathingFabState extends State<BreathingFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowOpacity = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return AnimatedBuilder(
      animation: _glowOpacity,
      builder: (context, child) {
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.accent,
            boxShadow: [
              BoxShadow(
                color: colors.accent.withValues(alpha: _glowOpacity.value),
                blurRadius: 16,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed,
          child: Center(
            child: Icon(
              PhosphorIcons.chatCircle(PhosphorIconsStyle.bold),
              color: colors.onBackground,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
