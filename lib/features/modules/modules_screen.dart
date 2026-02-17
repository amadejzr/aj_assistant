import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/dev/mock_hiking_module.dart';
import '../../core/dev/mock_pushup_module.dart';
import '../../core/models/module.dart';
import '../../core/repositories/module_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_state.dart';
import '../auth/widgets/paper_background.dart';
import 'bloc/modules_list_bloc.dart';
import 'bloc/modules_list_event.dart';
import 'bloc/modules_list_state.dart';

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';

    return BlocProvider(
      create: (context) => ModulesListBloc(
        moduleRepository: context.read<ModuleRepository>(),
        userId: userId,
      )..add(const ModulesListStarted()),
      child: const _ModulesScreenBody(),
    );
  }
}

class _ModulesScreenBody extends StatefulWidget {
  const _ModulesScreenBody();

  @override
  State<_ModulesScreenBody> createState() => _ModulesScreenBodyState();
}

class _ModulesScreenBodyState extends State<_ModulesScreenBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _titleFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
          ),
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
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        PaperBackground(colors: colors),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                _buildHeader(textTheme),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: BlocBuilder<ModulesListBloc, ModulesListState>(
                    builder: (context, state) {
                      return switch (state) {
                        ModulesListInitial() || ModulesListLoading() =>
                          const Center(child: CircularProgressIndicator()),
                        ModulesListLoaded(:final modules) =>
                          modules.isEmpty
                              ? _buildEmptyState(colors, textTheme)
                              : _buildModuleGrid(context, colors, modules),
                        ModulesListError() => _buildEmptyState(
                          colors,
                          textTheme,
                        ),
                      };
                    },
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return SlideTransition(
      position: _titleSlide,
      child: FadeTransition(
        opacity: _titleFade,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modules', style: textTheme.displayLarge),
            const SizedBox(height: AppSpacing.xs),
            Text('Your collection of tools', style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.squaresFour(PhosphorIconsStyle.light),
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
            TextButton.icon(
              onPressed: () async {
                final authState = context.read<AuthBloc>().state;
                if (authState is! AuthAuthenticated) return;
                final repo = context.read<ModuleRepository>();
                await repo.createModule(
                  authState.user.uid,
                  createMockHikingModule(),
                );
              },
              icon: Icon(
                PhosphorIcons.bug(PhosphorIconsStyle.bold),
                size: 16,
                color: colors.accent,
              ),
              label: Text(
                'Seed Hiking Module',
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final authState = context.read<AuthBloc>().state;
                if (authState is! AuthAuthenticated) return;
                final repo = context.read<ModuleRepository>();
                await repo.createModule(
                  authState.user.uid,
                  createMockPushupModule(),
                );
              },
              icon: Icon(
                PhosphorIcons.barbell(PhosphorIconsStyle.bold),
                size: 16,
                color: colors.accent,
              ),
              label: Text(
                'Seed Pushup Module',
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModuleGrid(
    BuildContext context,
    AppColors colors,
    List<Module> modules,
  ) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.1,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return _ModuleCard(
          module: module,
          onTap: () {
            context.push('/module/${module.id}');
          },
        );
      },
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final Module module;
  final VoidCallback onTap;

  const _ModuleCard({required this.module, required this.onTap});

  IconData _resolveIcon(String iconName) {
    return switch (iconName) {
      'barbell' => PhosphorIcons.barbell(PhosphorIconsStyle.duotone),
      'wallet' => PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
      'heart' => PhosphorIcons.heartbeat(PhosphorIconsStyle.duotone),
      'book' => PhosphorIcons.book(PhosphorIconsStyle.duotone),
      'chart' => PhosphorIcons.chartBar(PhosphorIconsStyle.duotone),
      'calendar' => PhosphorIcons.calendar(PhosphorIconsStyle.duotone),
      'list' => PhosphorIcons.listChecks(PhosphorIconsStyle.duotone),
      'mountains' => PhosphorIcons.mountains(PhosphorIconsStyle.duotone),
      _ => PhosphorIcons.cube(PhosphorIconsStyle.duotone),
    };
  }

  Color _parseColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final moduleColor = _parseColor(module.color);

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
                _resolveIcon(module.icon),
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
