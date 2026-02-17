import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/dev/mock_finance_2_module.dart';
import '../../core/dev/mock_finance_module.dart';
import '../../core/dev/mock_hiking_module.dart';
import '../../core/dev/mock_pushup_module.dart';
import '../../core/dev/seed_marketplace.dart';
import '../../core/models/module.dart';
import '../../core/repositories/module_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/module_display_utils.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../auth/bloc/auth_state.dart';
import '../auth/widgets/paper_background.dart';
import '../modules/bloc/modules_list_bloc.dart';
import '../modules/bloc/modules_list_event.dart';
import '../modules/bloc/modules_list_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';

    return BlocProvider(
      create: (context) => ModulesListBloc(
        moduleRepository: context.read<ModuleRepository>(),
        userId: userId,
      )..add(const ModulesListStarted()),
      child: const _HomeScreenBody(),
    );
  }
}

class _HomeScreenBody extends StatefulWidget {
  const _HomeScreenBody();

  @override
  State<_HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<_HomeScreenBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _greetingFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentFade;

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
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
    ));
    _contentFade = CurvedAnimation(
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
                    _buildGreeting(context),
                  ],
                ),
              ),
              BlocBuilder<ModulesListBloc, ModulesListState>(
                builder: (context, state) {
                  return switch (state) {
                    ModulesListInitial() ||
                    ModulesListLoading() =>
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ModulesListLoaded(:final modules) => modules.isEmpty
                        ? SliverFillRemaining(
                            child: _buildEmptyState(context, colors),
                          )
                        : _buildModulesSection(context, colors, modules),
                    ModulesListError() => SliverFillRemaining(
                        child: _buildEmptyState(context, colors),
                      ),
                  };
                },
              ),
              SliverToBoxAdapter(
                child: _buildMarketplaceCard(context, colors),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
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

  Widget _buildGreeting(BuildContext context) {
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

  Widget _buildModulesSection(
    BuildContext context,
    AppColors colors,
    List<Module> modules,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _contentSlide,
              child: FadeTransition(
                opacity: _contentFade,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xl,
                    bottom: AppSpacing.md,
                  ),
                  child: Text(
                    'Your modules',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
          ),
          SliverFadeTransition(
            opacity: _contentFade,
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final module = modules[index];
                  return _ModuleCard(
                    module: module,
                    onTap: () => context.push('/module/${module.id}'),
                  );
                },
                childCount: modules.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColors colors) {
    final textTheme = Theme.of(context).textTheme;

    return SlideTransition(
      position: _contentSlide,
      child: FadeTransition(
        opacity: _contentFade,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.notebook(PhosphorIconsStyle.light),
                size: 56,
                color: colors.onBackgroundMuted,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No modules yet',
                style: textTheme.titleMedium?.copyWith(
                  color: colors.onBackgroundMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Start a conversation to create\nyour first module',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: AppSpacing.lg),
                _DebugSeedButton(
                  icon: PhosphorIcons.bug(PhosphorIconsStyle.bold),
                  label: 'Seed Hiking Module',
                  colors: colors,
                  onPressed: () => _seedModule(createMockHikingModule()),
                ),
                _DebugSeedButton(
                  icon: PhosphorIcons.barbell(PhosphorIconsStyle.bold),
                  label: 'Seed Pushup Module',
                  colors: colors,
                  onPressed: () => _seedModule(createMockPushupModule()),
                ),
                _DebugSeedButton(
                  icon: PhosphorIcons.wallet(PhosphorIconsStyle.bold),
                  label: 'Seed Finance Module',
                  colors: colors,
                  onPressed: () => _seedModule(createMockFinanceModule()),
                ),
                _DebugSeedButton(
                  icon: PhosphorIcons.trendUp(PhosphorIconsStyle.bold),
                  label: 'Seed Finance 2.0',
                  colors: colors,
                  onPressed: () => _seedModule(createMockFinance2Module()),
                ),
                _DebugSeedButton(
                  icon: PhosphorIcons.storefront(PhosphorIconsStyle.bold),
                  label: 'Seed Marketplace',
                  colors: colors,
                  onPressed: () => seedMarketplaceTemplates(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketplaceCard(BuildContext context, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xl,
        AppSpacing.screenPadding,
        0,
      ),
      child: GestureDetector(
        onTap: () => context.push('/marketplace'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
                color: colors.accent,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marketplace',
                      style: TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.onBackground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Discover templates & community modules',
                      style: TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 12,
                        color: colors.onBackgroundMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                color: colors.onBackgroundMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seedModule(Module module) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final repo = context.read<ModuleRepository>();
    await repo.createModule(authState.user.uid, module);
  }
}

class _DebugSeedButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppColors colors;
  final VoidCallback onPressed;

  const _DebugSeedButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: colors.accent),
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Karla',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colors.accent,
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final Module module;
  final VoidCallback onTap;

  const _ModuleCard({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final moduleColor = parseModuleColor(module.color);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: moduleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                resolveModuleIcon(module.icon),
                color: moduleColor,
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              module.name,
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onBackground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (module.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                module.description,
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 12,
                  color: colors.onBackgroundMuted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
