import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
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

  String? _queryError() {
    final source = widget.listNode.properties['source'] as String?;
    if (source == null) return null;
    return widget.ctx.queryErrors[source];
  }

  List<dynamic> _filteredAndSorted() {
    // SQL source path: read from queryResults
    final source = widget.listNode.properties['source'] as String?;
    if (source != null) {
      return widget.ctx.queryResults[source] ?? [];
    }

    return [];
  }

  RenderContext _entryContext(dynamic entry) {
    final Map<String, dynamic> data;
    if (entry is Map<String, dynamic>) {
      data = entry;
    } else {
      data = (entry as dynamic) as Map<String, dynamic>;
    }

    return RenderContext(
      module: widget.ctx.module,
      formValues: data,
      screenParams: widget.ctx.screenParams,
      canGoBack: widget.ctx.canGoBack,
      onFormValueChanged: widget.ctx.onFormValueChanged,
      onFormSubmit: widget.ctx.onFormSubmit,
      onNavigateToScreen: widget.ctx.onNavigateToScreen,
      onNavigateBack: widget.ctx.onNavigateBack,
      onDeleteEntry: widget.ctx.onDeleteEntry,
      resolvedExpressions: widget.ctx.resolvedExpressions,
      queryResults: widget.ctx.queryResults,
      queryErrors: widget.ctx.queryErrors,
      onLoadNextPage: widget.ctx.onLoadNextPage,
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

  // ─── Loading State ───

  bool _isLoading() {
    final source = widget.listNode.properties['source'] as String?;
    if (source == null) return false;
    // Loading when some queries have returned but this source hasn't yet.
    // If queryResults is completely empty, we haven't received any data yet —
    // but we show empty state rather than skeleton to avoid infinite animations.
    if (widget.ctx.queryResults.isEmpty) return false;
    return !widget.ctx.queryResults.containsKey(source) &&
        !widget.ctx.queryErrors.containsKey(source);
  }

  Widget _buildSkeletonLoading(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _SkeletonCard(colors: colors, delay: index * 150),
        );
      }),
    );
  }

  // ─── Custom Empty State ───

  Widget _buildCustomEmptyState(BuildContext context) {
    final emptyState =
        widget.listNode.properties['emptyState'] as Map<String, dynamic>?;
    if (emptyState == null) return const SizedBox.shrink();

    final colors = context.colors;
    final message = emptyState['message'] as String? ?? 'No entries yet';
    final iconName = emptyState['icon'] as String?;
    final action = emptyState['action'] as Map<String, dynamic>?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconName != null)
              Icon(
                PhosphorIcons.target(PhosphorIconsStyle.regular),
                size: 40,
                color: colors.onBackgroundMuted.withValues(alpha: 0.3),
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 15,
                color: colors.onBackgroundMuted,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () {
                  final screen = action['screen'] as String?;
                  if (screen != null) {
                    widget.ctx.onNavigateToScreen(screen);
                  }
                },
                child: Text(
                  action['label'] as String? ?? 'Get started',
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
      ),
    );
  }

  // ─── Error State ───

  Widget _buildErrorState(BuildContext context, String error) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.warningCircle(PhosphorIconsStyle.regular),
              size: 32,
              color: colors.accent.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Failed to load data',
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.onBackgroundMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final queryError = _queryError();
    if (queryError != null) {
      return _buildErrorState(context, queryError);
    }

    if (_isLoading()) {
      return _buildSkeletonLoading(context);
    }

    final entries = _filteredAndSorted();
    final hasFilters = widget.listNode.filters.isNotEmpty;

    if (entries.isEmpty && !hasFilters) {
      // Use custom emptyState from blueprint if available
      final customEmptyState =
          widget.listNode.properties['emptyState'] as Map<String, dynamic>?;
      if (customEmptyState != null) {
        return _buildCustomEmptyState(context);
      }

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
          // SQL-driven pagination: dispatch load next page event
          final source = widget.listNode.properties['source'] as String?;
          if (source != null && widget.ctx.onLoadNextPage != null) {
            widget.ctx.onLoadNextPage!(source);
          } else {
            setState(() {
              _loadedCount += pageSize;
            });
          }
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
        for (var i = 0; i < entries.length; i++)
          _buildAnimatedItem(
            WidgetRegistry.instance
                .build(itemLayout, _entryContext(entries[i])),
            i,
          ),
      ],
    );
  }
}

/// Skeleton loading card with a warm shimmer matching the Sumi ink aesthetic.
class _SkeletonCard extends StatefulWidget {
  final AppColors colors;
  final int delay;

  const _SkeletonCard({required this.colors, this.delay = 0});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _shimmer.repeat();
    });
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        final shimmerValue = _shimmer.value;
        final opacity = 0.06 + (0.04 * (0.5 + 0.5 * math.sin(shimmerValue * math.pi * 2)));

        return Container(
          height: 64,
          decoration: BoxDecoration(
            color: colors.onBackground.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors.onBackground.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors.onBackground.withValues(alpha: opacity * 0.7),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 12,
                decoration: BoxDecoration(
                  color: colors.onBackground.withValues(alpha: opacity * 0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
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
