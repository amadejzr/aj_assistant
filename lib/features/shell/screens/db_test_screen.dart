import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/module.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/module_display_utils.dart';
import '../../auth/widgets/paper_background.dart';

class DbTestScreen extends StatefulWidget {
  const DbTestScreen({super.key});

  @override
  State<DbTestScreen> createState() => _DbTestScreenState();
}

class _DbTestScreenState extends State<DbTestScreen> {
  _DbGroup? _appDb;
  List<_ModuleDbGroup>? _moduleGroups;
  List<_DbObject>? _orphanTables;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final db = context.read<AppDatabase>();

    // Query all installed modules directly from Drift
    final moduleRows = await db.select(db.modules).get();
    final allModules = moduleRows
        .map((row) => Module(
              id: row.id,
              name: row.name,
              description: row.description,
              icon: row.icon,
              color: row.color,
              database: row.database,
            ))
        .toList();

    // Get all DB objects from sqlite_master
    final allTables = await db.customSelect(
      "SELECT name, sql FROM sqlite_master WHERE type='table' "
      "AND name NOT LIKE 'sqlite_%' ORDER BY name",
    ).get();
    final allTriggers = await db.customSelect(
      "SELECT name, tbl_name, sql FROM sqlite_master WHERE type='trigger' "
      "ORDER BY name",
    ).get();
    final allIndices = await db.customSelect(
      "SELECT name, tbl_name, sql FROM sqlite_master WHERE type='index' "
      "AND name NOT LIKE 'sqlite_%' ORDER BY name",
    ).get();

    // ── App Database: built-in Drift tables ──
    const driftTableNames = {'modules', 'capabilities'};

    final appTables = allTables
        .where((r) => driftTableNames.contains(r.data['name'] as String))
        .map((r) => _DbObject(
              name: r.data['name'] as String,
              sql: r.data['sql'] as String? ?? '',
            ))
        .toList();
    final appTriggers = allTriggers
        .where((r) => driftTableNames.contains(r.data['tbl_name'] as String))
        .map((r) => _DbObject(
              name: r.data['name'] as String,
              parentTable: r.data['tbl_name'] as String?,
              sql: r.data['sql'] as String? ?? '',
            ))
        .toList();
    final appIndices = allIndices
        .where((r) => driftTableNames.contains(r.data['tbl_name'] as String))
        .map((r) => _DbObject(
              name: r.data['name'] as String,
              parentTable: r.data['tbl_name'] as String?,
              sql: r.data['sql'] as String? ?? '',
            ))
        .toList();

    final appDb = _DbGroup(
      tables: appTables,
      triggers: appTriggers,
      indices: appIndices,
    );

    // ── Module databases: grouped by module ──
    final moduleGroups = <_ModuleDbGroup>[];
    final claimedTables = <String>{...driftTableNames};

    for (final module in allModules) {
      final tableNames = module.database?.tableNames.values.toSet() ?? {};
      claimedTables.addAll(tableNames);

      final tables = allTables
          .where((r) => tableNames.contains(r.data['name'] as String))
          .map((r) => _DbObject(
                name: r.data['name'] as String,
                sql: r.data['sql'] as String? ?? '',
              ))
          .toList();

      final triggers = allTriggers
          .where((r) => tableNames.contains(r.data['tbl_name'] as String))
          .map((r) => _DbObject(
                name: r.data['name'] as String,
                parentTable: r.data['tbl_name'] as String?,
                sql: r.data['sql'] as String? ?? '',
              ))
          .toList();

      final indices = allIndices
          .where((r) => tableNames.contains(r.data['tbl_name'] as String))
          .map((r) => _DbObject(
                name: r.data['name'] as String,
                parentTable: r.data['tbl_name'] as String?,
                sql: r.data['sql'] as String? ?? '',
              ))
          .toList();

      if (tables.isNotEmpty || triggers.isNotEmpty || indices.isNotEmpty) {
        moduleGroups.add(_ModuleDbGroup(
          module: module,
          group: _DbGroup(
            tables: tables,
            triggers: triggers,
            indices: indices,
          ),
        ));
      }
    }

    // ── Orphan tables: not claimed by any module or Drift ──
    final orphans = allTables
        .where((r) => !claimedTables.contains(r.data['name'] as String))
        .map((r) => _DbObject(
              name: r.data['name'] as String,
              sql: r.data['sql'] as String? ?? '',
            ))
        .toList();

    if (!mounted) return;
    setState(() {
      _appDb = appDb;
      _moduleGroups = moduleGroups;
      _orphanTables = orphans;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Stack(
      children: [
        PaperBackground(colors: colors),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colors.onBackground),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Database Inspector',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: colors.onBackground,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  PhosphorIcons.arrowClockwise(PhosphorIconsStyle.regular),
                  color: colors.onBackgroundMuted,
                ),
                onPressed: _load,
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(colors),
        ),
      ],
    );
  }

  Widget _buildBody(AppColors colors) {
    final appDb = _appDb;
    final modules = _moduleGroups ?? [];
    final orphans = _orphanTables ?? [];

    // Total counts across everything
    final totalTables = (appDb?.tables.length ?? 0) +
        modules.fold<int>(0, (s, m) => s + m.group.tables.length) +
        orphans.length;
    final totalTriggers = (appDb?.triggers.length ?? 0) +
        modules.fold<int>(0, (s, m) => s + m.group.triggers.length);
    final totalIndices = (appDb?.indices.length ?? 0) +
        modules.fold<int>(0, (s, m) => s + m.group.indices.length);

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
      children: [
        // Summary chips
        _SummaryRow(
          totalTables: totalTables,
          totalTriggers: totalTriggers,
          totalIndices: totalIndices,
          colors: colors,
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── App Database ──
        if (appDb != null && appDb.tables.isNotEmpty)
          _SectionCard(
            icon: PhosphorIcons.hardDrives(PhosphorIconsStyle.regular),
            iconColor: colors.onBackgroundMuted,
            title: 'App Database',
            subtitle: 'Built-in runtime tables (Drift)',
            group: appDb,
            colors: colors,
          ),

        // ── Module Databases ──
        ...modules.map((mg) {
          final moduleColor = parseModuleColor(mg.module.color);
          return _SectionCard(
            icon: resolveModuleIcon(mg.module.icon),
            iconColor: moduleColor,
            title: mg.module.name,
            subtitle:
                '${mg.group.tables.length} tables, '
                '${mg.group.triggers.length} triggers, '
                '${mg.group.indices.length} indices',
            group: mg.group,
            colors: colors,
          );
        }),

        // ── Orphan tables ──
        if (orphans.isNotEmpty)
          _SectionCard(
            icon: PhosphorIcons.question(PhosphorIconsStyle.regular),
            iconColor: colors.onBackgroundMuted,
            title: 'Unclaimed',
            subtitle: 'Tables not owned by any module',
            group: _DbGroup(tables: orphans, triggers: [], indices: []),
            colors: colors,
          ),

        // ── Empty state ──
        if (totalTables == 0) _buildEmptyState(colors),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              PhosphorIcons.database(PhosphorIconsStyle.light),
              size: 48,
              color: colors.onBackgroundMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No databases found',
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onBackgroundMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Install a module and open it to create tables',
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 13,
                color: colors.onBackgroundMuted.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary Row ───

class _SummaryRow extends StatelessWidget {
  final int totalTables;
  final int totalTriggers;
  final int totalIndices;
  final AppColors colors;

  const _SummaryRow({
    required this.totalTables,
    required this.totalTriggers,
    required this.totalIndices,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryChip(
          icon: PhosphorIcons.table(PhosphorIconsStyle.bold),
          label: '$totalTables tables',
          colors: colors,
        ),
        const SizedBox(width: AppSpacing.sm),
        _SummaryChip(
          icon: PhosphorIcons.lightning(PhosphorIconsStyle.bold),
          label: '$totalTriggers triggers',
          colors: colors,
        ),
        const SizedBox(width: AppSpacing.sm),
        _SummaryChip(
          icon: PhosphorIcons.listMagnifyingGlass(PhosphorIconsStyle.bold),
          label: '$totalIndices indices',
          colors: colors,
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppColors colors;

  const _SummaryChip({
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
          Icon(icon, size: 14, color: colors.onBackgroundMuted),
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

// ─── Section Card (reusable for App DB, Module, Orphans) ───

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final _DbGroup group;
  final AppColors colors;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.group,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'CormorantGaramond',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colors.onBackground,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 12,
                        color: colors.onBackgroundMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Tables
          if (group.tables.isNotEmpty) ...[
            _CategoryLabel(label: 'Tables', colors: colors),
            ...group.tables.map((t) => _ObjectCard(
                  icon: PhosphorIcons.table(PhosphorIconsStyle.regular),
                  label: t.name,
                  tag: 'TABLE',
                  tagColor: colors.accent,
                  sql: t.sql,
                  colors: colors,
                )),
          ],

          // Triggers
          if (group.triggers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _CategoryLabel(label: 'Triggers', colors: colors),
            ...group.triggers.map((t) => _ObjectCard(
                  icon: PhosphorIcons.lightning(PhosphorIconsStyle.regular),
                  label: t.name,
                  subtitle:
                      t.parentTable != null ? 'on ${t.parentTable}' : null,
                  tag: 'TRIGGER',
                  tagColor: colors.success,
                  sql: t.sql,
                  colors: colors,
                )),
          ],

          // Indices
          if (group.indices.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _CategoryLabel(label: 'Indices', colors: colors),
            ...group.indices.map((t) => _ObjectCard(
                  icon: PhosphorIcons.listMagnifyingGlass(
                      PhosphorIconsStyle.regular),
                  label: t.name,
                  subtitle:
                      t.parentTable != null ? 'on ${t.parentTable}' : null,
                  tag: 'INDEX',
                  tagColor: colors.onBackgroundMuted,
                  sql: t.sql,
                  colors: colors,
                )),
          ],
        ],
      ),
    );
  }
}

// ─── Category Label ───

class _CategoryLabel extends StatelessWidget {
  final String label;
  final AppColors colors;

  const _CategoryLabel({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6, top: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Karla',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: colors.onBackgroundMuted.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// ─── Object Card ───

class _ObjectCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String tag;
  final Color tagColor;
  final String sql;
  final AppColors colors;

  const _ObjectCard({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.tag,
    required this.tagColor,
    required this.sql,
    required this.colors,
  });

  @override
  State<_ObjectCard> createState() => _ObjectCardState();
}

class _ObjectCardState extends State<_ObjectCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: GestureDetector(
        onTap: widget.sql.isNotEmpty
            ? () => setState(() => _expanded = !_expanded)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _expanded
                  ? widget.tagColor.withValues(alpha: 0.3)
                  : widget.colors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.icon, size: 16, color: widget.tagColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.colors.onBackground,
                          ),
                        ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              fontFamily: 'Karla',
                              fontSize: 11,
                              color: widget.colors.onBackgroundMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: widget.tagColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.tag,
                      style: TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: widget.tagColor,
                      ),
                    ),
                  ),
                  if (widget.sql.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                        size: 12,
                        color: widget.colors.onBackgroundMuted,
                      ),
                    ),
                  ],
                ],
              ),
              // SQL expandable
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.colors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatSql(widget.sql),
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        height: 1.5,
                        color: widget.colors.onBackgroundMuted,
                      ),
                    ),
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSql(String sql) {
    return sql
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('CREATE TABLE', 'CREATE TABLE\n ')
        .replaceAll('CREATE TRIGGER', 'CREATE TRIGGER\n ')
        .replaceAll('CREATE INDEX', 'CREATE INDEX\n ')
        .replaceAll(' BEGIN ', '\nBEGIN\n  ')
        .replaceAll(' END', '\nEND')
        .replaceAll(', ', ',\n  ')
        .replaceAll(' AFTER ', '\n  AFTER ')
        .replaceAll(' WHERE ', '\n  WHERE ')
        .replaceAll(' SET ', '\n  SET ')
        .trim();
  }
}

// ─── Models ───

class _DbGroup {
  final List<_DbObject> tables;
  final List<_DbObject> triggers;
  final List<_DbObject> indices;

  const _DbGroup({
    required this.tables,
    required this.triggers,
    required this.indices,
  });
}

class _ModuleDbGroup {
  final Module module;
  final _DbGroup group;

  const _ModuleDbGroup({required this.module, required this.group});
}

class _DbObject {
  final String name;
  final String? parentTable;
  final String sql;

  const _DbObject({required this.name, this.parentTable, required this.sql});
}
