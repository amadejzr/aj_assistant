import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Three ink dots with staggered fade animation.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Stagger each dot by 0.2
              final delay = i * 0.2;
              final t = (_controller.value - delay).clamp(0.0, 1.0);
              // Fade in then out
              final opacity = t < 0.5 ? t * 2 : 2 - t * 2;

              return Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.onBackgroundMuted.withValues(
                    alpha: 0.3 + opacity * 0.7,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
