import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/database/screen_query.dart';
import '../../../core/models/module.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/module_display_utils.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/widgets/paper_background.dart';

class ModuleInfoScreen extends StatelessWidget {
  final String moduleId;

  const ModuleInfoScreen({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';
    final moduleRepo = context.read<ModuleRepository>();
    final colors = context.colors;

    return FutureBuilder<Module?>(
      future: moduleRepo.getModule(userId, moduleId),
      builder: (context, moduleSnapshot) {
        if (!moduleSnapshot.hasData) {
          return Scaffold(
            backgroundColor: colors.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final module = moduleSnapshot.data;
        if (module == null) {
          return Scaffold(
            backgroundColor: colors.background,
            appBar: AppBar(backgroundColor: colors.background, elevation: 0),
            body: const Center(child: Text('Module not found')),
          );
        }

        return _InfoScaffold(module: module);
      },
    );
  }
}

class _InfoScaffold extends StatefulWidget {
  final Module module;

  const _InfoScaffold({required this.module});

  @override
  State<_InfoScaffold> createState() => _InfoScaffoldState();
}

class _InfoScaffoldState extends State<_InfoScaffold>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final moduleColor = parseModuleColor(widget.module.color);

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
          'Module Info',
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
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: Stack(
        children: [
          PaperBackground(colors: colors),
          TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(module: widget.module, moduleColor: moduleColor),
              _DatabaseTab(module: widget.module),
              _SettingsTab(module: widget.module),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Overview Tab ───

class _OverviewTab extends StatelessWidget {
  final Module module;
  final Color moduleColor;

  const _OverviewTab({required this.module, required this.moduleColor});

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
            resolveModuleIcon(module.icon),
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
                module.name,
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: colors.onBackground,
                ),
              ),
              if (module.description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  module.description,
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
    final tableCount = module.database?.tableNames.length ?? 0;

    return Row(
      children: [
        _StatChip(
          icon: PhosphorIcons.gitBranch(PhosphorIconsStyle.bold),
          label: 'v${module.version}',
          colors: colors,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(
          icon: PhosphorIcons.table(PhosphorIconsStyle.bold),
          label: '$tableCount tables',
          colors: colors,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(
          icon: PhosphorIcons.browsers(PhosphorIconsStyle.bold),
          label: '${module.screens.length} screens',
          colors: colors,
        ),
      ],
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
        if (module.guide.isEmpty)
          Text(
            'No guide yet',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 14,
              color: colors.onBackgroundMuted,
            ),
          )
        else
          ...module.guide.map((section) {
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
  final Module module;

  const _DatabaseTab({required this.module});

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
    final tableNames = module.database?.tableNames ?? {};

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
    final screenIds = module.screens.keys.toList();

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

// ─── Settings Tab ───

class _SettingsTab extends StatefulWidget {
  final Module module;

  const _SettingsTab({required this.module});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late Map<String, bool> _states;

  @override
  void initState() {
    super.initState();
    _states = Map<String, bool>.from(widget.module.capabilityStates);
  }

  bool _hasNotificationCapability() {
    // Check settings.capabilities for auto_notify
    for (final cap in widget.module.capabilities) {
      if (cap['type'] == 'auto_notify') return true;
    }

    // Check screen JSON for schedule_notification nodes
    for (final screen in widget.module.screens.values) {
      if (_containsNodeType(screen, 'schedule_notification')) return true;
    }

    // Check mutations for reminders
    for (final screen in widget.module.screens.values) {
      final mutationsJson = screen['mutations'] as Map<String, dynamic>?;
      if (mutationsJson == null) continue;
      final mutations = ScreenMutations.fromJson(mutationsJson);
      for (final m in [mutations.create, mutations.update]) {
        if (m != null && m.reminders.isNotEmpty) return true;
      }
    }

    return false;
  }

  bool _containsNodeType(Map<String, dynamic> json, String type) {
    if (json['type'] == type) return true;
    for (final value in json.values) {
      if (value is Map<String, dynamic>) {
        if (_containsNodeType(value, type)) return true;
      } else if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            if (_containsNodeType(item, type)) return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> _onToggle(String capabilityType, bool enabled) async {
    setState(() => _states[capabilityType] = enabled);

    final updatedSettings = Map<String, dynamic>.from(widget.module.settings);
    updatedSettings['capabilityStates'] = {..._states};

    final updatedModule = widget.module.copyWith(settings: updatedSettings);

    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';
    await context.read<ModuleRepository>().updateModule(userId, updatedModule);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasNotifications = _hasNotificationCapability();

    if (!hasNotifications) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'No configurable capabilities',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 15,
              color: colors.onBackgroundMuted,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Capabilities',
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.onBackground,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (hasNotifications)
            _CapabilityToggle(
              label: 'Notifications',
              description: 'Reminders and scheduled notifications',
              icon: PhosphorIcons.bell(PhosphorIconsStyle.bold),
              enabled: _states['notifications'] ?? true,
              onChanged: (v) => _onToggle('notifications', v),
              colors: colors,
            ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _CapabilityToggle extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final AppColors colors;

  const _CapabilityToggle({
    required this.label,
    required this.description,
    required this.icon,
    required this.enabled,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: colors.onBackgroundMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onBackground,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 13,
                    color: colors.onBackgroundMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: onChanged,
            activeTrackColor: colors.accent,
          ),
        ],
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
