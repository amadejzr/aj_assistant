import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../cubit/chat_cubit.dart';
import '../models/message.dart';

class ApprovalCard extends StatelessWidget {
  final List<PendingAction> actions;
  final ApprovalStatus status;

  const ApprovalCard({
    super.key,
    required this.actions,
    this.status = ApprovalStatus.pending,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final isApproved = status == ApprovalStatus.approved;
    final isRejected = status == ApprovalStatus.rejected;
    final isResolved = isApproved || isRejected;

    final borderColor = isApproved
        ? colors.success.withValues(alpha: 0.4)
        : isRejected
            ? colors.onBackgroundMuted.withValues(alpha: 0.2)
            : colors.accent.withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isApproved
            ? colors.success.withValues(alpha: 0.06)
            : colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors, isApproved, isRejected),
          const SizedBox(height: 10),
          ...actions.map((a) => _ActionItem(
                action: a,
                isResolved: isResolved,
                isApproved: isApproved,
              )),
          if (!isResolved) ...[
            const SizedBox(height: 10),
            _buildButtons(context, colors),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    dynamic colors,
    bool isApproved,
    bool isRejected,
  ) {
    final icon = isApproved
        ? Icons.check_circle_rounded
        : isRejected
            ? Icons.cancel_rounded
            : Icons.pending_rounded;

    final label = isApproved
        ? 'Approved'
        : isRejected
            ? 'Rejected'
            : 'Confirm';

    final color = isApproved
        ? colors.success
        : isRejected
            ? colors.onBackgroundMuted
            : colors.onBackground;

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Karla',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, dynamic colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            context.read<ChatCubit>().rejectActions();
          },
          child: Text(
            'Reject',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.onBackgroundMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () {
            context.read<ChatCubit>().approveActions();
          },
          style: FilledButton.styleFrom(
            backgroundColor: colors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Approve',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.onBackground,
            ),
          ),
        ),
      ],
    );
  }
}

/// Displays a single pending action with its data fields clearly laid out.
/// Handles both single-entry actions and batch actions.
class _ActionItem extends StatelessWidget {
  final PendingAction action;
  final bool isResolved;
  final bool isApproved;

  const _ActionItem({
    required this.action,
    required this.isResolved,
    required this.isApproved,
  });

  bool get _isBatch =>
      action.name == 'createEntries' || action.name == 'updateEntries';

  bool get _isModuleCreate => action.name == 'createModule';

  @override
  Widget build(BuildContext context) {
    if (_isModuleCreate) return _buildModulePreview(context);
    if (_isBatch) return _buildBatch(context);
    return _buildSingle(context);
  }

  Widget _buildSingle(BuildContext context) {
    final colors = context.colors;
    final isCreate = action.name == 'createEntry';
    final data = action.input['data'] as Map? ?? {};
    final schemaKey = action.input['schemaKey'] as String?;

    final accentColor =
        isResolved ? colors.onBackgroundMuted : colors.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _actionHeader(
            icon: isCreate ? Icons.add_circle_outline : Icons.edit_outlined,
            label: isCreate
                ? 'Create${schemaKey != null ? ' in $schemaKey' : ''}'
                : 'Update entry',
            color: accentColor,
          ),
          if (data.isNotEmpty) ...[
            const SizedBox(height: 6),
            _dataBox(colors, data),
          ],
        ],
      ),
    );
  }

  Widget _buildBatch(BuildContext context) {
    final colors = context.colors;
    final isCreate = action.name == 'createEntries';
    final entries = (action.input['entries'] as List?) ?? [];
    final schemaKey = action.input['schemaKey'] as String?;
    final count = entries.length;

    final accentColor =
        isResolved ? colors.onBackgroundMuted : colors.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _actionHeader(
            icon: isCreate
                ? Icons.playlist_add_rounded
                : Icons.edit_note_rounded,
            label: isCreate
                ? 'Create $count entries${schemaKey != null ? ' in $schemaKey' : ''}'
                : 'Update $count entries',
            color: accentColor,
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < entries.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 12,
                      thickness: 0.5,
                      color: colors.onBackgroundMuted.withValues(alpha: 0.15),
                    ),
                  _batchEntryRow(colors, entries[i] as Map, i + 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact row for a single entry within a batch.
  /// Shows the entry number and up to 2 key data fields.
  Widget _batchEntryRow(dynamic colors, Map entry, int index) {
    final data = entry['data'] as Map? ?? {};
    // Pick the most descriptive fields to show (first 2 non-empty string values)
    final preview = data.entries
        .where((e) => e.value != null && '${e.value}'.isNotEmpty)
        .take(2)
        .map((e) => '${e.value}')
        .join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$index.',
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 11,
                color: colors.onBackgroundMuted,
                height: 1.4,
              ),
            ),
          ),
          Expanded(
            child: Text(
              preview.isNotEmpty ? preview : '(empty)',
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.onBackground,
                height: 1.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulePreview(BuildContext context) {
    final colors = context.colors;
    final input = action.input;
    final name = input['name'] as String? ?? 'Module';
    final description = input['description'] as String? ?? '';
    final db = input['database'] as Map? ?? {};
    final setupSql = (db['setup'] as List?)?.cast<String>() ?? [];
    final screens = input['screens'] as Map? ?? {};
    final iconName = input['icon'] as String?;
    final colorHex = input['color'] as String?;

    final accentColor =
        isResolved ? colors.onBackgroundMuted : colors.accent;

    // Parse table info from CREATE TABLE statements
    final tables = <_TableInfo>[];
    for (final sql in setupSql) {
      if (!sql.toUpperCase().startsWith('CREATE TABLE')) continue;
      final tableMatch = RegExp(
        r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\S+)\s*\((.+)\)',
        caseSensitive: false,
      ).firstMatch(sql);
      if (tableMatch == null) continue;
      final tableName = tableMatch.group(1)!.replaceAll('"', '');
      final columnsDef = tableMatch.group(2)!;
      final columns = columnsDef
          .split(',')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty && !c.toUpperCase().startsWith('PRIMARY KEY'))
          .map((c) {
            final parts = c.split(RegExp(r'\s+'));
            return parts.first.replaceAll('"', '');
          })
          .where((c) => c != 'id' && c != 'created_at' && c != 'updated_at')
          .toList();
      // Use short name: strip m_modulename_ prefix
      final shortName = tableName.replaceFirst(RegExp(r'^m_\w+?_'), '');
      tables.add(_TableInfo(shortName.isNotEmpty ? shortName : tableName, columns));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _actionHeader(
            icon: Icons.dashboard_customize_rounded,
            label: 'Create module "$name"',
            color: accentColor,
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Module metadata row
                if (iconName != null || colorHex != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        if (colorHex != null)
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: _parseHexColor(colorHex),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        if (iconName != null)
                          Text(
                            iconName,
                            style: TextStyle(
                              fontFamily: 'Karla',
                              fontSize: 11,
                              color: colors.onBackgroundMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                // Description
                if (description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      description,
                      style: TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 12,
                        color: colors.onBackground,
                        height: 1.4,
                      ),
                    ),
                  ),
                // Tables
                if (tables.isNotEmpty) ...[
                  Text(
                    'Tables',
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.onBackgroundMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final table in tables)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 90,
                            child: Text(
                              table.name,
                              style: TextStyle(
                                fontFamily: 'Karla',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colors.onBackground,
                                height: 1.4,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              table.columns.join(', '),
                              style: TextStyle(
                                fontFamily: 'Karla',
                                fontSize: 12,
                                color: colors.onBackgroundMuted,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                ],
                // Screens
                if (screens.isNotEmpty) ...[
                  Text(
                    'Screens',
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.onBackgroundMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final screenId in screens.keys)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(
                        screenId,
                        style: TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 12,
                          color: colors.onBackground,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _parseHexColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    return Color(int.parse(clean, radix: 16));
  }

  Widget _actionHeader({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Karla',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _dataBox(dynamic colors, Map data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    e.key,
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 12,
                      color: colors.onBackgroundMuted,
                      height: 1.4,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${e.value}',
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.onBackground,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TableInfo {
  final String name;
  final List<String> columns;

  const _TableInfo(this.name, this.columns);
}
