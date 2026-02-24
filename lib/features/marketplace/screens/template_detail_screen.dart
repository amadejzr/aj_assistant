import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/module_template.dart';
import '../../../core/repositories/marketplace_repository.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/module_display_utils.dart';
import '../../../core/widgets/app_toast.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/widgets/paper_background.dart';
import '../bloc/marketplace_bloc.dart';
import '../bloc/marketplace_event.dart';
import '../bloc/marketplace_state.dart';

class TemplateDetailScreen extends StatelessWidget {
  final String templateId;

  const TemplateDetailScreen({super.key, required this.templateId});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';

    return BlocProvider(
      create: (context) => MarketplaceBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
        moduleRepository: context.read<ModuleRepository>(),
        db: context.read<AppDatabase>(),
        userId: userId,
      )..add(const MarketplaceStarted()),
      child: _DetailBody(templateId: templateId),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final String templateId;

  const _DetailBody({required this.templateId});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocBuilder<MarketplaceBloc, MarketplaceState>(
      builder: (context, state) {
        if (state is! MarketplaceLoaded) {
          return Scaffold(
            backgroundColor: colors.background,
            appBar: AppBar(
              backgroundColor: colors.background,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: colors.onBackground),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final template = state.allTemplates
            .where((t) => t.id == templateId)
            .firstOrNull;

        if (template == null) {
          return Scaffold(
            backgroundColor: colors.background,
            appBar: AppBar(
              backgroundColor: colors.background,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: colors.onBackground),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(child: Text('Template not found')),
          );
        }

        final isInstalling = state.installingId == templateId;
        final isInstalled = state.isInstalled(templateId);

        return _TemplateDetailScaffold(
          template: template,
          isInstalling: isInstalling,
          isInstalled: isInstalled,
        );
      },
    );
  }
}

class _TemplateDetailScaffold extends StatefulWidget {
  final ModuleTemplate template;
  final bool isInstalling;
  final bool isInstalled;

  const _TemplateDetailScaffold({
    required this.template,
    required this.isInstalling,
    required this.isInstalled,
  });

  @override
  State<_TemplateDetailScaffold> createState() =>
      _TemplateDetailScaffoldState();
}

class _TemplateDetailScaffoldState extends State<_TemplateDetailScaffold>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _wasInstalling = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didUpdateWidget(covariant _TemplateDetailScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Detect install completion: was installing, now is not
    if (_wasInstalling && !widget.isInstalling) {
      _onInstallComplete();
    }
    _wasInstalling = widget.isInstalling;
  }

  void _onInstallComplete() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: '"${widget.template.name}" installed!',
        type: AppToastType.success,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final moduleColor = parseModuleColor(widget.template.color);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onBackground),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.template.name,
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: colors.onBackground,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.accent,
          indicatorWeight: 2.5,
          labelColor: colors.accent,
          unselectedLabelColor: colors.onBackgroundMuted,
          labelStyle: const TextStyle(
            fontFamily: 'Karla',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Karla',
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Database'),
          ],
        ),
      ),
      body: Stack(
        children: [
          PaperBackground(colors: colors),
          TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(
                template: widget.template,
                moduleColor: moduleColor,
              ),
              _DatabaseTab(template: widget.template),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _InstallBar(
        template: widget.template,
        isInstalling: widget.isInstalling,
        isInstalled: widget.isInstalled,
        colors: colors,
      ),
    );
  }
}

// ─── Overview Tab ───

class _OverviewTab extends StatelessWidget {
  final ModuleTemplate template;
  final Color moduleColor;

  const _OverviewTab({required this.template, required this.moduleColor});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          const SizedBox(height: AppSpacing.lg),
          _buildStatsRow(colors),
          if (template.longDescription.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            _buildDescription(colors),
          ],
          if (template.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildTags(colors),
          ],
          const SizedBox(height: AppSpacing.xl),
          _buildGuideSection(colors),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: moduleColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            resolveModuleIcon(template.icon),
            color: moduleColor,
            size: 28,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.name,
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: colors.onBackground,
                ),
              ),
              if (template.description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  template.description,
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 14,
                    color: colors.onBackgroundMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(AppColors colors) {
    final tableCount = template.database?.tableNames.length ?? 0;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _StatChip(
          icon: PhosphorIcons.gitBranch(PhosphorIconsStyle.bold),
          label: 'v${template.version}',
          colors: colors,
        ),
        _StatChip(
          icon: PhosphorIcons.table(PhosphorIconsStyle.bold),
          label: '$tableCount tables',
          colors: colors,
        ),
        _StatChip(
          icon: PhosphorIcons.browsers(PhosphorIconsStyle.bold),
          label: '${template.screens.length} screens',
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildDescription(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.onBackground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          template.longDescription,
          style: TextStyle(
            fontFamily: 'Karla',
            fontSize: 14,
            color: colors.onBackgroundMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTags(AppColors colors) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: template.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 12,
              color: colors.onBackgroundMuted,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGuideSection(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guide',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.onBackground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (template.guide.isEmpty)
          Text(
            'No guide yet',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 14,
              color: colors.onBackgroundMuted,
            ),
          )
        else
          ...template.guide.map((section) {
            final title = section['title'] ?? '';
            final body = section['body'] ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty) ...[
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      body,
                      style: TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 14,
                        color: colors.onBackgroundMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ─── Database Tab ───

class _DatabaseTab extends StatelessWidget {
  final ModuleTemplate template;

  const _DatabaseTab({required this.template});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTablesSection(colors),
          const SizedBox(height: AppSpacing.xl),
          _buildScreensSection(colors),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildTablesSection(AppColors colors) {
    final tableNames = template.database?.tableNames ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tables',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.onBackground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (tableNames.isEmpty)
          Text(
            'No tables defined',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 14,
              color: colors.onBackgroundMuted,
            ),
          )
        else
          ...tableNames.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 15,
                          color: colors.onBackground,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 13,
                          color: colors.onBackgroundMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildScreensSection(AppColors colors) {
    final screenIds = template.screens.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Screens',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.onBackground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (screenIds.isEmpty)
          Text(
            'No screens defined',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 14,
              color: colors.onBackgroundMuted,
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: screenIds.map((id) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  id,
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.onBackground,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ─── Install Bar ───

class _InstallBar extends StatelessWidget {
  final ModuleTemplate template;
  final bool isInstalling;
  final bool isInstalled;
  final AppColors colors;

  const _InstallBar({
    required this.template,
    required this.isInstalling,
    required this.isInstalled,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: isInstalled
            ? OutlinedButton.icon(
                onPressed: null,
                icon: Icon(
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.bold),
                  size: 20,
                  color: colors.accent,
                ),
                label: Text(
                  'Already Installed',
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.accent,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.accent.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            : ElevatedButton(
                onPressed: isInstalling
                    ? null
                    : () => context
                        .read<MarketplaceBloc>()
                        .add(MarketplaceTemplateInstalled(template.id)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      colors.accent.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isInstalling
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Install Module',
                        style: TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
      ),
    );
  }
}

// ─── Shared Widgets ───

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppColors colors;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.onBackgroundMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.onBackground,
            ),
          ),
        ],
      ),
    );
  }
}

