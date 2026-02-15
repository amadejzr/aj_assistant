# Night Studio Home Screen — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the themed home screen for AJ Assistant with dark/light mode, animated greeting, geometric empty state, and glowing chat input bar.

**Architecture:** Feature-first folder structure. Theme system using custom color/typography classes consumed via extensions. Home screen composed of three widget zones (greeting, module area, input bar) with staggered entrance animations.

**Tech Stack:** Flutter 3.38, Dart 3.10, google_fonts package, CustomPaint for geometric accents.

---

### Task 1: Spacing Constants

**Files:**
- Create: `lib/core/theme/app_spacing.dart`

**Step 1: Create the spacing file**

```dart
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double screenPadding = 24;
}
```

**Step 2: Verify no syntax errors**

Run: `dart analyze lib/core/theme/app_spacing.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/theme/app_spacing.dart
git commit -m "feat: add spacing constants (4px grid system)"
```

---

### Task 2: Color Tokens

**Files:**
- Create: `lib/core/theme/app_colors.dart`

**Step 1: Create the color tokens file**

Define two classes — `AppColorsDark` and `AppColorsLight` — both implementing a shared abstract interface `AppColors`. This lets widgets reference colors abstractly.

```dart
import 'package:flutter/material.dart';

abstract class AppColors {
  Color get background;
  Color get surface;
  Color get surfaceVariant;
  Color get onBackground;
  Color get onBackgroundMuted;
  Color get accent;
  Color get accentMuted;
  Color get border;
  Color get error;
  Color get success;

  // Background gradient colors
  Color get gradientStart;
  Color get gradientEnd;
}

class AppColorsDark implements AppColors {
  const AppColorsDark();

  @override
  Color get background => const Color(0xFF1A1A1E);
  @override
  Color get surface => const Color(0xFF242428);
  @override
  Color get surfaceVariant => const Color(0xFF2E2E33);
  @override
  Color get onBackground => const Color(0xFFF2EDE8);
  @override
  Color get onBackgroundMuted => const Color(0xFF8A857E);
  @override
  Color get accent => const Color(0xFFE8A84C);
  @override
  Color get accentMuted => const Color(0xFFE8A84C).withValues(alpha: 0.15);
  @override
  Color get border => Colors.white.withValues(alpha: 0.08);
  @override
  Color get error => const Color(0xFFE85C5C);
  @override
  Color get success => const Color(0xFF5CE88A);
  @override
  Color get gradientStart => const Color(0xFF1E1E22);
  @override
  Color get gradientEnd => const Color(0xFF1A1A1E);
}

class AppColorsLight implements AppColors {
  const AppColorsLight();

  @override
  Color get background => const Color(0xFFFAF7F2);
  @override
  Color get surface => const Color(0xFFFFFFFF);
  @override
  Color get surfaceVariant => const Color(0xFFF0EBE3);
  @override
  Color get onBackground => const Color(0xFF2C2520);
  @override
  Color get onBackgroundMuted => const Color(0xFF9C958C);
  @override
  Color get accent => const Color(0xFFD4922E);
  @override
  Color get accentMuted => const Color(0xFFD4922E).withValues(alpha: 0.10);
  @override
  Color get border => Colors.black.withValues(alpha: 0.08);
  @override
  Color get error => const Color(0xFFE85C5C);
  @override
  Color get success => const Color(0xFF5CE88A);
  @override
  Color get gradientStart => const Color(0xFFFAF7F2);
  @override
  Color get gradientEnd => const Color(0xFFF5F0E8);
}
```

**Step 2: Verify no syntax errors**

Run: `dart analyze lib/core/theme/app_colors.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/theme/app_colors.dart
git commit -m "feat: add dark and light color token definitions"
```

---

### Task 3: Typography System

**Files:**
- Create: `lib/core/theme/app_typography.dart`

**Step 1: Create the typography file**

Uses `google_fonts` package to load Bricolage Grotesque, DM Sans, and DM Mono. Returns a `TextTheme` configured to our type scale, parameterized by `AppColors` so text colors match the active theme.

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextTheme textTheme(AppColors colors) {
    final onBg = colors.onBackground;
    final muted = colors.onBackgroundMuted;

    return TextTheme(
      displayLarge: GoogleFonts.bricolageGrotesque(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: onBg,
        height: 1.2,
      ),
      headlineMedium: GoogleFonts.bricolageGrotesque(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: onBg,
        height: 1.3,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: onBg,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: onBg,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.5,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.dmMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: onBg,
        height: 1.5,
      ),
    );
  }
}
```

**Step 2: Verify no syntax errors**

Run: `dart analyze lib/core/theme/app_typography.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/theme/app_typography.dart
git commit -m "feat: add typography system with Bricolage Grotesque and DM Sans"
```

---

### Task 4: Theme Assembly

**Files:**
- Create: `lib/core/theme/app_theme.dart`

**Step 1: Create the theme file**

Assembles `ThemeData` for light and dark modes. Uses an `InheritedWidget` extension to expose `AppColors` down the tree so widgets can access our custom tokens.

```dart
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final AppColors colors;

  const AppColorsExtension({required this.colors});

  @override
  AppColorsExtension copyWith({AppColors? colors}) {
    return AppColorsExtension(colors: colors ?? this.colors);
  }

  @override
  AppColorsExtension lerp(covariant ThemeExtension<AppColorsExtension>? other, double t) {
    return this; // No lerp needed for discrete color sets
  }
}

abstract final class AppTheme {
  static ThemeData dark() {
    const colors = AppColorsDark();
    return _buildTheme(colors, Brightness.dark);
  }

  static ThemeData light() {
    const colors = AppColorsLight();
    return _buildTheme(colors, Brightness.light);
  }

  static ThemeData _buildTheme(AppColors colors, Brightness brightness) {
    final textTheme = AppTypography.textTheme(colors);

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accent,
        onPrimary: colors.onBackground,
        secondary: colors.accentMuted,
        onSecondary: colors.onBackground,
        error: colors.error,
        onError: colors.onBackground,
        surface: colors.surface,
        onSurface: colors.onBackground,
      ),
      textTheme: textTheme,
      extensions: [AppColorsExtension(colors: colors)],
    );
  }
}

/// Convenience extension to access AppColors from BuildContext.
extension AppColorsX on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColorsExtension>()!.colors;
}
```

**Step 2: Verify no syntax errors**

Run: `dart analyze lib/core/theme/app_theme.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/theme/app_theme.dart
git commit -m "feat: assemble ThemeData with dark/light modes and color extension"
```

---

### Task 5: Animated Glow Widget

**Files:**
- Create: `lib/core/widgets/animated_glow.dart`

**Step 1: Create the reusable glow widget**

A widget that wraps a child and adds a breathing box-shadow glow effect. Used by the chat input bar.

```dart
import 'package:flutter/material.dart';

class AnimatedGlow extends StatefulWidget {
  final Widget child;
  final Color color;
  final double minOpacity;
  final double maxOpacity;
  final double blurRadius;
  final Duration duration;

  const AnimatedGlow({
    super.key,
    required this.child,
    required this.color,
    this.minOpacity = 0.3,
    this.maxOpacity = 0.6,
    this.blurRadius = 20,
    this.duration = const Duration(milliseconds: 3000),
  });

  @override
  State<AnimatedGlow> createState() => _AnimatedGlowState();
}

class _AnimatedGlowState extends State<AnimatedGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _opacity = Tween(begin: widget.minOpacity, end: widget.maxOpacity)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _opacity.value),
                blurRadius: widget.blurRadius,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
```

**Step 2: Verify no syntax errors**

Run: `dart analyze lib/core/widgets/animated_glow.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/widgets/animated_glow.dart
git commit -m "feat: add AnimatedGlow widget for breathing box-shadow effect"
```

---

### Task 6: Geometric Accent (CustomPaint)

**Files:**
- Create: `lib/features/home/widgets/geometric_accent.dart`

**Step 1: Create the geometric accent widget**

Three overlapping translucent circles with slow rotation. Drawn with CustomPaint for performance.

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

class GeometricAccent extends StatefulWidget {
  final Color color;
  final double size;

  const GeometricAccent({
    super.key,
    required this.color,
    this.size = 160,
  });

  @override
  State<GeometricAccent> createState() => _GeometricAccentState();
}

class _GeometricAccentState extends State<GeometricAccent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _GeometricPainter(
            color: widget.color,
            rotation: _controller.value * 2 * math.pi,
          ),
        );
      },
    );
  }
}

class _GeometricPainter extends CustomPainter {
  final Color color;
  final double rotation;

  _GeometricPainter({required this.color, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28;
    final orbitRadius = size.width * 0.15;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Three circles offset by 120 degrees, orbiting around center
    for (var i = 0; i < 3; i++) {
      final angle = rotation + (i * 2 * math.pi / 3);
      final offset = Offset(
        center.dx + orbitRadius * math.cos(angle),
        center.dy + orbitRadius * math.sin(angle),
      );
      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_GeometricPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}
```

**Step 2: Verify no syntax errors**

Run: `dart analyze lib/features/home/widgets/geometric_accent.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/home/widgets/geometric_accent.dart
git commit -m "feat: add GeometricAccent widget with rotating overlapping circles"
```

---

### Task 7: Greeting Section Widget

**Files:**
- Create: `lib/features/home/widgets/greeting_section.dart`

**Step 1: Create the greeting widget**

Time-of-day aware greeting with staggered entrance animation.

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

class GreetingSection extends StatefulWidget {
  const GreetingSection({super.key});

  @override
  State<GreetingSection> createState() => _GreetingSectionState();
}

class _GreetingSectionState extends State<GreetingSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _greetingFade;
  late final Animation<Offset> _greetingSlide;
  late final Animation<double> _dateFade;
  late final Animation<Offset> _dateSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _greetingFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.67, curve: Curves.easeOutCubic),
      ),
    );
    _greetingSlide = Tween(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.67, curve: Curves.easeOutCubic),
      ),
    );

    _dateFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.17, 0.83, curve: Curves.easeOutCubic),
      ),
    );
    _dateSlide = Tween(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.17, 0.83, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _dateString {
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: _greetingSlide.value,
                child: Opacity(opacity: _greetingFade.value, child: child),
              );
            },
            child: Text(
              _greeting,
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: _dateSlide.value,
                child: Opacity(opacity: _dateFade.value, child: child),
              );
            },
            child: Text(
              _dateString,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onBackgroundMuted,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Verify no syntax errors**

Run: `dart analyze lib/features/home/widgets/greeting_section.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/home/widgets/greeting_section.dart
git commit -m "feat: add GreetingSection with time-aware greeting and staggered animation"
```

---

### Task 8: Empty State Widget

**Files:**
- Create: `lib/features/home/widgets/empty_state.dart`

**Step 1: Create the empty state widget**

Geometric accent + prompt text with entrance animation.

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import 'geometric_accent.dart';

class EmptyState extends StatefulWidget {
  const EmptyState({super.key});

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shapeFade;
  late final Animation<double> _shapeScale;
  late final Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _shapeFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _shapeScale = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _textFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Delay to stagger after greeting
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: _shapeFade.value,
              child: Transform.scale(
                scale: _shapeScale.value,
                child: GeometricAccent(color: colors.accentMuted),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Opacity(
              opacity: _textFade.value,
              child: Text(
                'Ask me anything.\nI\'ll build what you need.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onBackgroundMuted,
                      height: 1.6,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}
```

**Step 2: Verify no syntax errors**

Run: `dart analyze lib/features/home/widgets/empty_state.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/home/widgets/empty_state.dart
git commit -m "feat: add EmptyState widget with geometric accent and staggered entrance"
```

---

### Task 9: Chat Input Bar

**Files:**
- Create: `lib/features/home/widgets/chat_input_bar.dart`

**Step 1: Create the chat input bar widget**

Bottom-pinned input with send button and breathing glow.

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_glow.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({super.key});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _slide = Tween(
      begin: const Offset(0, 30),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottom = MediaQuery.of(context).padding.bottom;

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Transform.translate(
          offset: _slide.value,
          child: Opacity(opacity: _fade.value, child: child),
        );
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.md,
          AppSpacing.screenPadding,
          AppSpacing.md + bottom,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: AnimatedGlow(
          color: colors.accent,
          minOpacity: 0.08,
          maxOpacity: 0.2,
          blurRadius: 24,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    "What's on your mind?",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onBackgroundMuted,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: colors.background,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Verify no syntax errors**

Run: `dart analyze lib/features/home/widgets/chat_input_bar.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/home/widgets/chat_input_bar.dart
git commit -m "feat: add ChatInputBar with breathing glow and entrance animation"
```

---

### Task 10: Home Screen Assembly

**Files:**
- Create: `lib/features/home/home_screen.dart`

**Step 1: Create the home screen**

Assembles all three zones with gradient background.

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/empty_state.dart';
import 'widgets/greeting_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [colors.gradientStart, colors.gradientEnd],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: topPadding + AppSpacing.xxl),
            const GreetingSection(),
            const Expanded(
              child: Center(child: EmptyState()),
            ),
            const ChatInputBar(),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Verify no syntax errors**

Run: `dart analyze lib/features/home/home_screen.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/home/home_screen.dart
git commit -m "feat: assemble HomeScreen with gradient background and three zones"
```

---

### Task 11: Wire Up main.dart

**Files:**
- Modify: `lib/main.dart` (replace entire file)

**Step 1: Update main.dart**

Replace the default counter app with our themed app.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
  );
  runApp(const AJAssistantApp());
}

class AJAssistantApp extends StatelessWidget {
  const AJAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AJ Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
```

**Step 2: Verify the full project analyzes cleanly**

Run: `flutter analyze`
Expected: No issues found

**Step 3: Run on simulator to verify visually**

Run: `flutter run` (on connected device or simulator)
Expected: Home screen appears with greeting, geometric accent, glowing input bar. Dark/light responds to system setting.

**Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat: wire up AJ Assistant with Night Studio theme and home screen"
```

---

### Task 12: Final Verification

**Step 1: Run full analysis**

Run: `flutter analyze`
Expected: No issues found

**Step 2: Run existing tests (should still pass)**

Run: `flutter test`
Expected: May need to update widget_test.dart since we removed MyApp/MyHomePage. Update the test to reference AJAssistantApp and HomeScreen, or remove the default test.

**Step 3: Fix test if needed**

If the default widget_test.dart fails, replace it with a minimal smoke test:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:aj_assistant/main.dart';

void main() {
  testWidgets('App renders home screen', (tester) async {
    await tester.pumpWidget(const AJAssistantApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text("What's on your mind?"), findsOneWidget);
  });
}
```

**Step 4: Final commit**

```bash
git add -A
git commit -m "chore: update widget test for new home screen"
```
