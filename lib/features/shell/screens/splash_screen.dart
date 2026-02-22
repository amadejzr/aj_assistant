import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/widgets/seal_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _navigated = false;

  // Ink bloom
  late final Animation<double> _inkBloomProgress;
  late final Animation<double> _inkBloomOpacity;

  // Seal stamp
  late final Animation<double> _sealScale;
  late final Animation<double> _sealOpacity;
  late final Animation<double> _sealRotation;

  // Stamp impact ring
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;

  // Brush stroke
  late final Animation<double> _brushProgress;

  // Title
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleSlide;

  // Subtitle
  late final Animation<double> _subtitleOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(_tryNavigate);

    _inkBloomProgress = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    ));
    _inkBloomOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.5), weight: 75),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5),
    ));

    _sealScale = Tween(begin: 1.6, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.48, curve: Curves.easeOutBack),
    ));
    _sealOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.25, curve: Curves.easeOut),
    );
    _sealRotation = Tween(begin: 0.06, end: 0.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.48, curve: Curves.easeOutCubic),
    ));

    _ringScale = Tween(begin: 1.0, end: 2.5).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.36, 0.62, curve: Curves.easeOut),
    ));
    _ringOpacity = Tween(begin: 0.25, end: 0.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.36, 0.62, curve: Curves.easeIn),
    ));

    _brushProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 0.68, curve: Curves.easeInOutCubic),
    );

    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.75, curve: Curves.easeOut),
    );
    _titleSlide = Tween(begin: 12.0, end: 0.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.75, curve: Curves.easeOutCubic),
    ));

    _subtitleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.85, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  void _tryNavigate() {
    if (_navigated || _controller.value < 0.8) return;
    final state = context.read<AuthBloc>().state;
    if (state is AuthInitial) return;

    _navigated = true;
    context.go(state is AuthAuthenticated ? '/home' : '/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final screenSize = MediaQuery.sizeOf(context);
    final center = Offset(screenSize.width / 2, screenSize.height / 2);

    return BlocListener<AuthBloc, AuthState>(
      listener: (_, _) => _tryNavigate(),
      child: Scaffold(
        backgroundColor: colors.background,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Ink bloom
                Positioned.fill(
                  child: CustomPaint(
                    painter: _InkBloomPainter(
                      progress: _inkBloomProgress.value,
                      opacity: _inkBloomOpacity.value,
                      color: colors.surfaceVariant,
                      center: center,
                      maxRadius: screenSize.longestSide * 0.8,
                    ),
                  ),
                ),

                Center(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Seal + impact ring
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: _ringScale.value,
                          child: Opacity(
                            opacity: _ringOpacity.value,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.accent,
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Transform.rotate(
                          angle: _sealRotation.value,
                          child: Transform.scale(
                            scale: _sealScale.value,
                            child: Opacity(
                              opacity: _sealOpacity.value,
                              child: SealLogo(
                                color: colors.accent,
                                textColor: colors.background,
                                size: 80,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Brush stroke
                    SizedBox(
                      width: 100,
                      height: 6,
                      child: CustomPaint(
                        painter: _BrushStrokePainter(
                          progress: _brushProgress.value,
                          color: colors.accent.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Title
                    Transform.translate(
                      offset: Offset(0, _titleSlide.value),
                      child: Opacity(
                        opacity: _titleOpacity.value,
                        child: Text(
                          'bower',
                          style: TextStyle(
                            fontFamily: 'CormorantGaramond',
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: colors.onBackground,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subtitle
                    Opacity(
                      opacity: _subtitleOpacity.value,
                      child: Text(
                        'your personal notebook',
                        style: TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: colors.onBackgroundMuted,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),
                  ],
                ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Expanding circle of diluted ink — like a drop on wet washi paper.
class _InkBloomPainter extends CustomPainter {
  final double progress;
  final double opacity;
  final Color color;
  final Offset center;
  final double maxRadius;

  _InkBloomPainter({
    required this.progress,
    required this.opacity,
    required this.color,
    required this.center,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final currentRadius = maxRadius * progress;
    final gradient = RadialGradient(
      colors: [
        color.withValues(alpha: opacity * 0.15),
        color.withValues(alpha: opacity * 0.08),
        color.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final rect = Rect.fromCircle(center: center, radius: currentRadius);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _InkBloomPainter oldDelegate) =>
      progress != oldDelegate.progress || opacity != oldDelegate.opacity;
}

/// Calligraphic brush stroke that draws itself left to right.
class _BrushStrokePainter extends CustomPainter {
  final double progress;
  final Color color;

  _BrushStrokePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final h = size.height;
    final midY = h / 2;
    const segments = 24;
    final visibleSegments = (segments * progress).ceil();

    final path = Path();

    for (var i = 0; i <= visibleSegments; i++) {
      final t = i / segments;
      final x = t * size.width;
      final thickness = math.sin(t * math.pi) * (h * 0.42);
      final wobble = math.sin(i * 3.7) * 0.5;
      final y = midY - thickness + wobble;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    for (var i = visibleSegments; i >= 0; i--) {
      final t = i / segments;
      final x = t * size.width;
      final thickness = math.sin(t * math.pi) * (h * 0.42);
      final wobble = math.sin(i * 5.3 + 2.0) * 0.5;
      final y = midY + thickness + wobble;
      path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BrushStrokePainter oldDelegate) =>
      progress != oldDelegate.progress;
}
