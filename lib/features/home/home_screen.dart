import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../auth/bloc/auth_state.dart';
import '../auth/widgets/paper_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _greetingFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _greetingFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
    ));
    _cardFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Stack(
      children: [
        PaperBackground(colors: colors),
        SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                sliver: SliverList.list(
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    _buildTopBar(colors),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildGreeting(context, colors),
                    const SizedBox(height: AppSpacing.xl),
                    _buildEmptyStateCard(colors),
                    const SizedBox(height: 120), // FAB clearance
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(AppColors colors) {
    return Align(
      alignment: Alignment.centerRight,
      child: IconButton(
        onPressed: () {
          context.read<AuthBloc>().add(const AuthLogoutRequested());
        },
        icon: Icon(
          PhosphorIcons.signOut(PhosphorIconsStyle.light),
          color: colors.onBackgroundMuted,
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, AppColors colors) {
    return FadeTransition(
      opacity: _greetingFade,
      child: BlocSelector<AuthBloc, AuthState, String?>(
        selector: (state) =>
            state is AuthAuthenticated ? state.user.displayName : null,
        builder: (context, displayName) {
          final name = displayName ?? 'there';
          return Text(
            'Hello, $name',
            style: Theme.of(context).textTheme.displayLarge,
          );
        },
      ),
    );
  }

  Widget _buildEmptyStateCard(AppColors colors) {
    return SlideTransition(
      position: _cardSlide,
      child: FadeTransition(
        opacity: _cardFade,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Icon(
                PhosphorIcons.notebook(PhosphorIconsStyle.light),
                size: 48,
                color: colors.onBackgroundMuted,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Start a conversation to build\nyour first module',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onBackgroundMuted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
