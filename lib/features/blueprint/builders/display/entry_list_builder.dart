import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../engine/entry_filter.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';
import '../../renderer/widget_registry.dart';

/// Renders a list of entries in three modes:
///
/// **Summary mode** — fixed item count with optional title header and "view all" link.
/// **Paginated mode** — infinite scroll, loads pages on demand.
/// **Default mode** — simple list of all items.
///
/// Supports an optional `filters` array for interactive filter chips:
/// ```json
/// {
///   "type": "entry_list",
///   "filters": [
///     {"field": "category", "type": "enum"},
///     {"field": "date", "type": "period"}
///   ],
///   "query": {"orderBy": "date", "direction": "desc"},
///   "pageSize": 20
/// }
/// ```
Widget buildEntryList(BlueprintNode node, RenderContext ctx) {
  final listNode = node as EntryListNode;
  return _EntryListWidget(listNode: listNode, ctx: ctx);
}

class _EntryListWidget extends StatefulWidget {
  final EntryListNode listNode;
  final RenderContext ctx;

  const _EntryListWidget({required this.listNode, required this.ctx});

  @override
  State<_EntryListWidget> createState() => _EntryListWidgetState();
}

class _EntryListWidgetState extends State<_EntryListWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasAnimated = false;
  late int _loadedCount;

  /// Active user-selected filter values. Key = field name, value = selected option.
  /// null value means "All" (no filter on that field).
  final Map<String, String?> _activeFilters = {};

  @override
  void initState() {
    super.initState();
    _loadedCount = widget.listNode.pageSize ?? 0;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasAnimated && mounted) {
        _hasAnimated = true;
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<dynamic> _filteredAndSorted() {
    // SQL source path: read from queryResults, skip client-side filtering
    final source = widget.listNode.properties['source'] as String?;
    if (source != null) {
      return widget.ctx.queryResults[source] ?? [];
    }

    // Existing path: filter from ctx.entries
    final result = EntryFilter.filter(
      widget.ctx.entries,
      widget.listNode.filter,
      widget.ctx.screenParams,
    );
    List<dynamic> entries = List.of(result.entries);

    // Apply interactive filter bar selections
    for (final filterDef in widget.listNode.filters) {
      final field = filterDef['field'] as String?;
      if (field == null) continue;
      final activeValue = _activeFilters[field];
      if (activeValue == null) continue; // "All" selected

      final type = filterDef['type'] as String?;
      if (type == 'period') {
        entries = _applyPeriodFilter(entries, field, activeValue);
      } else {
        // Enum or other equality filter
        entries = entries
            .where((e) => (e as dynamic).data[field]?.toString() == activeValue)
            .toList();
      }
    }

    final orderBy = widget.listNode.query['orderBy'] as String?;
    final direction =
        widget.listNode.query['direction'] as String? ?? 'desc';
    if (orderBy != null) {
      entries.sort((a, b) {
        final aVal = a.data[orderBy];
        final bVal = b.data[orderBy];
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return 1;
        if (bVal == null) return -1;
        final cmp =
            Comparable.compare(aVal as Comparable, bVal as Comparable);
        return direction == 'desc' ? -cmp : cmp;
      });
    }

    return entries;
  }

  List<dynamic> _applyPeriodFilter(
      List<dynamic> entries, String field, String period) {
    final now = DateTime.now();
    late DateTime start;
    DateTime? end;

    switch (period) {
      case 'This Week':
        start = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
      case 'Last Month':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 1);
      default:
        return entries;
    }

    return entries.where((e) {
      final dateVal = (e as dynamic).data[field];
      if (dateVal == null) return false;
      DateTime date;
      if (dateVal is String) {
        date = DateTime.tryParse(dateVal) ?? DateTime(0);
      } else if (dateVal is int) {
        date = DateTime.fromMillisecondsSinceEpoch(dateVal);
      } else {
        return false;
      }
      if (date.isBefore(start)) return false;
      if (end != null && !date.isBefore(end)) return false;
      return true;
    }).toList();
  }

  RenderContext _entryContext(dynamic entry) {
    // SQL row (Map) vs Entry object
    final Map<String, dynamic> data;
    if (entry is Map<String, dynamic>) {
      data = entry;
    } else {
      data = (entry as dynamic).data as Map<String, dynamic>;
    }

    return RenderContext(
      module: widget.ctx.module,
      entries: entry is Map ? const [] : [entry],
      allEntries: widget.ctx.allEntries,
      formValues: data,
      screenParams: widget.ctx.screenParams,
      canGoBack: widget.ctx.canGoBack,
      onFormValueChanged: widget.ctx.onFormValueChanged,
      onFormSubmit: widget.ctx.onFormSubmit,
      onNavigateToScreen: widget.ctx.onNavigateToScreen,
      onNavigateBack: widget.ctx.onNavigateBack,
      onDeleteEntry: widget.ctx.onDeleteEntry,
      resolvedExpressions: widget.ctx.resolvedExpressions,
      onCreateEntry: widget.ctx.onCreateEntry,
      onUpdateEntry: widget.ctx.onUpdateEntry,
      queryResults: widget.ctx.queryResults,
    );
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    if (index >= 10 || _hasAnimated) return child;

    final staggerStart = (index * 0.08).clamp(0.0, 0.7);
    final staggerEnd = (staggerStart + 0.3).clamp(0.0, 1.0);
    final curve = Interval(staggerStart, staggerEnd, curve: Curves.easeOut);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _controller, curve: curve)),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: _controller, curve: curve)),
        child: child,
      ),
    );
  }

  // ─── Filter Bar ───

  List<_FilterChipData> _resolveFilterChips() {
    final chips = <_FilterChipData>[];

    for (final filterDef in widget.listNode.filters) {
      final field = filterDef['field'] as String? ?? '';
      final type = filterDef['type'] as String?;
      final label = filterDef['label'] as String?;

      List<String> options;
      if (type == 'period') {
        options = const ['This Week', 'This Month', 'Last Month'];
      } else {
        // Enum options come from the filter definition itself
        final inlineOptions = filterDef['options'];
        if (inlineOptions is List) {
          options = inlineOptions.cast<String>();
        } else {
          continue;
        }
      }
      if (options.isEmpty) continue;

      chips.add(_FilterChipData(
        field: field,
        allLabel: label ?? 'All',
        options: options,
      ));
    }
    return chips;
  }

  Widget _buildFilterBar() {
    final chipGroups = _resolveFilterChips();
    if (chipGroups.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;

    // Build all chips into a single flat list with group separators
    final allChips = <Widget>[];
    for (var gi = 0; gi < chipGroups.length; gi++) {
      final group = chipGroups[gi];
      final activeValue = _activeFilters[group.field];

      // "All" chip for this group
      allChips.add(_buildChip(
        label: group.allLabel,
        isActive: activeValue == null,
        colors: colors,
        onTap: () => _setFilter(group.field, null),
      ));

      // Option chips
      for (final option in group.options) {
        allChips.add(_buildChip(
          label: option,
          isActive: activeValue == option,
          colors: colors,
          onTap: () => _setFilter(group.field, option),
        ));
      }

      // Separator dot between groups
      if (gi < chipGroups.length - 1) {
        allChips.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: colors.onBackgroundMuted.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
          ),
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          children: [
            for (var i = 0; i < allChips.length; i++) ...[
              allChips[i],
              if (i < allChips.length - 1 &&
                  allChips[i] is! Padding &&
                  allChips[i + 1] is! Padding)
                const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }

  void _setFilter(String field, String? value) {
    setState(() {
      _activeFilters[field] = value;
      _loadedCount = widget.listNode.pageSize ?? 0;
    });
  }

  Widget _buildChip({
    required String label,
    required bool isActive,
    required AppColors colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? colors.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? colors.accent.withValues(alpha: 0.5)
                : colors.onBackgroundMuted.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Karla',
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? colors.accent : colors.onBackgroundMuted,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final entries = _filteredAndSorted();
    final hasFilters = widget.listNode.filters.isNotEmpty;

    if (entries.isEmpty && !hasFilters) {
      final emptyNode = EmptyStateNode(
        icon: 'list',
        title: 'No entries yet',
        subtitle: 'Add your first entry to get started',
      );
      return WidgetRegistry.instance.build(emptyNode, widget.ctx);
    }

    final itemLayout = widget.listNode.itemLayout;
    if (itemLayout == null) return const SizedBox.shrink();

    if (widget.listNode.isSummary) {
      return _buildSummary(entries, itemLayout);
    }

    if (widget.listNode.isPaginated) {
      return _buildPaginated(entries, itemLayout);
    }

    // Default: show all (no limit, no pagination)
    return _buildSimpleList(entries, itemLayout);
  }

  /// Summary mode: title header + limited items + "view all" link.
  Widget _buildSummary(List<dynamic> entries, BlueprintNode itemLayout) {
    final colors = context.colors;
    final limit = (widget.listNode.query['limit'] as int?) ?? 5;
    final totalCount = entries.length;
    final visible = entries.take(limit).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title header with "view all" tap
        if (widget.listNode.title != null)
          GestureDetector(
            onTap: widget.listNode.viewAllScreen != null
                ? () => widget.ctx
                    .onNavigateToScreen(widget.listNode.viewAllScreen!)
                : null,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.listNode.title!,
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.onBackground,
                    ),
                  ),
                  if (widget.listNode.viewAllScreen != null &&
                      totalCount > limit)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View all',
                          style: TextStyle(
                            fontFamily: 'Karla',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.accent,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          PhosphorIcons.caretRight(
                              PhosphorIconsStyle.regular),
                          size: 14,
                          color: colors.accent,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

        // Items
        ...List.generate(visible.length, (index) {
          final child = WidgetRegistry.instance
              .build(itemLayout, _entryContext(visible[index]));
          return _buildAnimatedItem(child, index);
        }),
      ],
    );
  }

  /// Paginated mode: filter bar + infinite scroll with "load more" on scroll end.
  Widget _buildPaginated(List<dynamic> entries, BlueprintNode itemLayout) {
    final colors = context.colors;
    final pageSize = widget.listNode.pageSize!;
    final visible = entries.take(_loadedCount).toList();
    final hasMore = entries.length > _loadedCount;
    final hasFilters = widget.listNode.filters.isNotEmpty;

    // Show empty state when filters produce no results
    if (entries.isEmpty && hasFilters) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterBar(),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Column(
              children: [
                Icon(
                  PhosphorIcons.funnel(PhosphorIconsStyle.regular),
                  size: 32,
                  color: colors.onBackgroundMuted.withValues(alpha: 0.4),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No matching entries',
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 14,
                    color: colors.onBackgroundMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            hasMore &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          setState(() {
            _loadedCount += pageSize;
          });
        }
        return false;
      },
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: visible.length + (hasFilters ? 1 : 0) + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Filter bar as first item
          if (hasFilters && index == 0) {
            return _buildFilterBar();
          }
          final dataIndex = hasFilters ? index - 1 : index;

          if (dataIndex >= visible.length) {
            // Loading indicator at the bottom
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.accent,
                  ),
                ),
              ),
            );
          }

          final child = WidgetRegistry.instance
              .build(itemLayout, _entryContext(visible[dataIndex]));
          return _buildAnimatedItem(child, dataIndex);
        },
      ),
    );
  }

  /// Default mode: optional filter bar + simple list of all items.
  Widget _buildSimpleList(
      List<dynamic> entries, BlueprintNode itemLayout) {
    final hasFilters = widget.listNode.filters.isNotEmpty;
    final colors = context.colors;

    // Show empty state when filters produce no results
    if (entries.isEmpty && hasFilters) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterBar(),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Column(
              children: [
                Icon(
                  PhosphorIcons.funnel(PhosphorIconsStyle.regular),
                  size: 32,
                  color: colors.onBackgroundMuted.withValues(alpha: 0.4),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No matching entries',
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 14,
                    color: colors.onBackgroundMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasFilters) _buildFilterBar(),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final child = WidgetRegistry.instance
                .build(itemLayout, _entryContext(entries[index]));
            return _buildAnimatedItem(child, index);
          },
        ),
      ],
    );
  }
}

/// Resolved chip data for a single filter group.
class _FilterChipData {
  final String field;
  final String allLabel;
  final List<String> options;

  const _FilterChipData({
    required this.field,
    required this.allLabel,
    required this.options,
  });
}
