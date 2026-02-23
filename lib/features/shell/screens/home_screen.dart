import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/models/module.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/module_display_utils.dart';
import '../../../core/widgets/app_toast.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/widgets/paper_background.dart';
import '../../modules/bloc/modules_list_bloc.dart';
import '../../modules/bloc/modules_list_event.dart';
import '../../modules/bloc/modules_list_state.dart';
import '../widgets/upcoming_reminders_section.dart';

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
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
          ),
        );
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
                    ModulesListLoading() => const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    ModulesListLoaded(:final modules) =>
                      modules.isEmpty
                          ? SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyState(context, colors),
                            )
                          : SliverMainAxisGroup(
                              slivers: [
                                _buildModulesSection(context, colors, modules),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.screenPadding,
                                    ),
                                    child: const UpcomingRemindersSection(),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: _buildMarketplaceCard(context, colors),
                                ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 100),
                                ),
                              ],
                            ),
                    ModulesListError() => SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(context, colors),
                    ),
                  };
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (kDebugMode)
          IconButton(
            onPressed: () => context.push('/db-test'),
            icon: Icon(
              PhosphorIcons.database(PhosphorIconsStyle.light),
              color: colors.onBackgroundMuted,
            ),
          ),
        IconButton(
          onPressed: () {
            context.read<AuthBloc>().add(const AuthLogoutRequested());
          },
          icon: Icon(
            PhosphorIcons.signOut(PhosphorIconsStyle.light),
            color: colors.onBackgroundMuted,
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
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
              delegate: SliverChildBuilderDelegate((context, index) {
                final module = modules[index];
                return _ModuleCard(
                  module: module,
                  onTap: () => context.push('/module/${module.id}'),
                  onLongPress: () => _confirmDeleteModule(module),
                );
              }, childCount: modules.length),
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
              GestureDetector(child: Text('NOTIFICATIONS')),
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
                'Browse the marketplace to get started',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: () => context.push('/marketplace'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.storefront(PhosphorIconsStyle.bold),
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Explore Marketplace',
                        style: TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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

  Future<void> _confirmDeleteModule(Module module) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteModuleDialog(module: module),
    );

    if (confirmed != true || !mounted) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    try {
      final repo = context.read<ModuleRepository>();
      await repo.deleteModule(authState.user.uid, module.id);
      if (mounted) {
        AppToast.show(
          context,
          message: '"${module.name}" deleted',
          type: AppToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Failed to delete module',
          type: AppToastType.error,
        );
      }
    }
  }
}

class _ModuleCard extends StatelessWidget {
  final Module module;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ModuleCard({
    required this.module,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final moduleColor = parseModuleColor(module.color);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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

class _DeleteModuleDialog extends StatefulWidget {
  final Module module;

  const _DeleteModuleDialog({required this.module});

  @override
  State<_DeleteModuleDialog> createState() => _DeleteModuleDialogState();
}

class _DeleteModuleDialogState extends State<_DeleteModuleDialog>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  bool _matches = false;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final matches =
          _controller.text.trim().toLowerCase() ==
          widget.module.name.trim().toLowerCase();
      if (matches != _matches) setState(() => _matches = matches);
    });
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ScaleTransition(
      scale: _scaleAnim,
      child: Dialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Module icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  resolveModuleIcon(widget.module.icon),
                  color: colors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Delete Module',
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colors.onBackground,
                ),
              ),
              const SizedBox(height: 16),

              // Warning box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      PhosphorIcons.warning(PhosphorIconsStyle.fill),
                      color: colors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This will permanently delete "${widget.module.name}" '
                        'and all its entries. This action cannot be undone.',
                        style: TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 13,
                          height: 1.4,
                          color: colors.onBackground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Instruction
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Type "${widget.module.name}" to confirm',
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onBackgroundMuted,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Text field
              TextField(
                controller: _controller,
                autofocus: true,
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 15,
                  color: colors.onBackground,
                ),
                decoration: InputDecoration(
                  hintText: widget.module.name,
                  hintStyle: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 15,
                    color: colors.onBackgroundMuted.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: colors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _matches ? colors.error : colors.accent,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.border),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.onBackgroundMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _matches ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 200),
                      child: GestureDetector(
                        onTap: _matches
                            ? () => Navigator.of(context).pop(true)
                            : null,
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: colors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                PhosphorIcons.trash(PhosphorIconsStyle.bold),
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Delete',
                                style: TextStyle(
                                  fontFamily: 'Karla',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
