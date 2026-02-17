import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/widgets/seal_logo.dart';

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
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.accent.withValues(alpha: _glowOpacity.value),
                blurRadius: 18,
                spreadRadius: 3,
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
            child: SealLogo(
              color: colors.accent,
              textColor: colors.onBackground,
              size: 58,
            ),
          ),
        ),
      ),
    );
  }
}
