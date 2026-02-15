import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum AppToastType { error, success, info }

abstract final class AppToast {
  static OverlayEntry? _currentEntry;
  static _AppToastWidgetState? _currentState;

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.error,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Remove any existing toast immediately.
    _dismiss();

    final overlay = Overlay.of(context);
    final colors = context.colors;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _AppToastWidget(
        message: message,
        type: type,
        colors: colors,
        duration: duration,
        onDismissed: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
            _currentState = null;
          }
        },
        onStateCreated: (state) {
          _currentState = state;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void _dismiss() {
    final state = _currentState;
    if (state != null && state.mounted) {
      state.dismissImmediately();
    } else {
      _currentEntry?.remove();
    }
    _currentEntry = null;
    _currentState = null;
  }
}

class _AppToastWidget extends StatefulWidget {
  final String message;
  final AppToastType type;
  final AppColors colors;
  final Duration duration;
  final VoidCallback onDismissed;
  final ValueChanged<_AppToastWidgetState> onStateCreated;

  const _AppToastWidget({
    required this.message,
    required this.type,
    required this.colors,
    required this.duration,
    required this.onDismissed,
    required this.onStateCreated,
  });

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    widget.onStateCreated(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const _EaseOutBack(),
      reverseCurve: Curves.easeIn,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) _animateOut();
    });
  }

  void _animateOut() {
    _controller.reverse().then((_) {
      if (mounted) widget.onDismissed();
    });
  }

  void dismissImmediately() {
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final barColor = switch (widget.type) {
      AppToastType.error => colors.error,
      AppToastType.success => colors.success,
      AppToastType.info => colors.accent,
    };
    final icon = switch (widget.type) {
      AppToastType.error => PhosphorIcons.warningCircle(PhosphorIconsStyle.regular),
      AppToastType.success => PhosphorIcons.checkCircle(PhosphorIconsStyle.regular),
      AppToastType.info => PhosphorIcons.info(PhosphorIconsStyle.regular),
    };

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          bottom: false,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy < -100) {
                _animateOut();
              }
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: colors.onBackground.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: [
                      CustomPaint(
                        size: const Size(4, 48),
                        painter: _BrushBarPainter(color: barColor),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        icon,
                        size: 20,
                        color: colors.onBackgroundMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            widget.message,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: colors.onBackground),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom easeOutBack curve matching the seal stamp animation feel.
class _EaseOutBack extends Curve {
  const _EaseOutBack();

  @override
  double transformInternal(double t) {
    const s = 1.70158;
    final t1 = t - 1;
    return t1 * t1 * ((s + 1) * t1 + s) + 1;
  }
}

/// Paints a wobbly vertical brush-stroke bar on the left edge.
class _BrushBarPainter extends CustomPainter {
  final Color color;

  const _BrushBarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    final path = Path();

    // Left edge with slight wobble.
    path.moveTo(0, 0);
    const segments = 8;
    for (var i = 1; i <= segments; i++) {
      final y = size.height * i / segments;
      final wobble = (random.nextDouble() - 0.5) * 1.2;
      path.lineTo(wobble, y);
    }

    // Right edge with wobble going back up.
    for (var i = segments; i >= 0; i--) {
      final y = size.height * i / segments;
      final wobble = size.width + (random.nextDouble() - 0.5) * 1.2;
      path.lineTo(wobble, y);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BrushBarPainter oldDelegate) =>
      color != oldDelegate.color;
}
