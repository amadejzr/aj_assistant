import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/models/module.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/module_display_utils.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/widgets/paper_background.dart';
import '../models/field_definition.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
            Tab(text: 'Schema'),
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
              _SchemaTab(module: widget.module),
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
    final totalFields =
        module.schemas.values.fold<int>(0, (sum, s) => sum + s.fields.length);

    return Row(
      children: [
        _StatChip(
          icon: PhosphorIcons.gitBranch(PhosphorIconsStyle.bold),
          label: 'v${module.version}',
          colors: colors,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(
          icon: PhosphorIcons.stack(PhosphorIconsStyle.bold),
          label: '$totalFields fields',
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

// ─── Schema Tab ───

class _SchemaTab extends StatelessWidget {
  final Module module;

  const _SchemaTab({required this.module});

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
          _buildFieldsSection(colors),
          const SizedBox(height: AppSpacing.xl),
          _buildScreensSection(colors),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildFieldsSection(AppColors colors) {
    final schemas = module.schemas;
    final hasMultipleSchemas = schemas.length > 1;
    final hasAnyFields = schemas.values.any((s) => s.fields.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fields',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.onBackground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!hasAnyFields)
          Text(
            'No fields defined',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 14,
              color: colors.onBackgroundMuted,
            ),
          )
        else
          ...schemas.entries.expand((schemaEntry) {
            final schema = schemaEntry.value;
            if (schema.fields.isEmpty) return <Widget>[];
            return [
              if (hasMultipleSchemas) ...[
                _SchemaGroupHeader(
                  label: schema.label.isNotEmpty
                      ? schema.label
                      : schemaEntry.key,
                  colors: colors,
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              ...schema.fields.values.map((field) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _FieldRow(field: field, colors: colors),
                );
              }),
              if (hasMultipleSchemas) const SizedBox(height: AppSpacing.sm),
            ];
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

class _SchemaGroupHeader extends StatelessWidget {
  final String label;
  final AppColors colors;

  const _SchemaGroupHeader({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Karla',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: colors.onBackgroundMuted,
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final FieldDefinition field;
  final AppColors colors;

  const _FieldRow({required this.field, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              field.label,
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
              field.type.name,
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 13,
                color: colors.onBackgroundMuted,
              ),
            ),
          ),
          if (field.required) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'required',
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 11,
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
}
