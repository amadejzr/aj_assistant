import 'package:flutter/material.dart';

import '../../renderer/blueprint_node.dart';
import '../../engine/entry_filter.dart';
import '../../renderer/render_context.dart';
import '../../renderer/widget_registry.dart';

/// Renders a filtered, sorted, and animated list of entries using a configurable item layout.
///
/// Blueprint JSON:
/// ```json
/// {"type": "entry_list", "query": {"orderBy": "date", "direction": "desc", "limit": 10}, "itemLayout": {"type": "entry_card", "title": "{{name}}"}}
/// ```
///
/// - `query` (`Map<String, dynamic>`, optional): Query parameters including `orderBy` (field name), `direction` (`"asc"` or `"desc"`), and `limit` (max entries).
/// - `filter` (`dynamic`, optional): Entry filter to scope which entries appear in the list.
/// - `itemLayout` (`BlueprintNode?`, optional): Blueprint node used to render each individual entry (typically an `entry_card`).
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
  late final AnimationController _controller;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // Animate on first build
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

  @override
  Widget build(BuildContext context) {
    // Use EntryFilter for unified filtering
    final result = EntryFilter.filter(
      widget.ctx.entries,
      widget.listNode.filter,
      widget.ctx.screenParams,
    );
    var entries = List.of(result.entries);

    // Sort
    final orderBy = widget.listNode.query['orderBy'] as String?;
    final direction = widget.listNode.query['direction'] as String? ?? 'desc';
    if (orderBy != null) {
      entries.sort((a, b) {
        final aVal = a.data[orderBy];
        final bVal = b.data[orderBy];
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return 1;
        if (bVal == null) return -1;
        final cmp = Comparable.compare(aVal as Comparable, bVal as Comparable);
        return direction == 'desc' ? -cmp : cmp;
      });
    }

    // Limit
    final limit = widget.listNode.query['limit'] as int?;
    if (limit != null && entries.length > limit) {
      entries = entries.sublist(0, limit);
    }

    // Empty state
    if (entries.isEmpty) {
      final emptyNode = EmptyStateNode(
        icon: 'list',
        title: 'No entries yet',
        subtitle: 'Add your first entry to get started',
      );
      return WidgetRegistry.instance.build(emptyNode, widget.ctx);
    }

    // Render items
    final itemLayout = widget.listNode.itemLayout;
    if (itemLayout == null) {
      return const SizedBox.shrink();
    }

    final itemCount = entries.length;

    return Column(
      children: List.generate(itemCount, (index) {
        final entry = entries[index];
        final entryCtx = RenderContext(
          module: widget.ctx.module,
          entries: [entry],
          allEntries: widget.ctx.allEntries,
          formValues: entry.data,
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
        );

        final child = WidgetRegistry.instance.build(itemLayout, entryCtx);

        // Stagger delay: each item starts 80ms after the previous
        final staggerStart = (index * 0.08).clamp(0.0, 0.7);
        final staggerEnd = (staggerStart + 0.3).clamp(0.0, 1.0);

        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Interval(staggerStart, staggerEnd, curve: Curves.easeOut),
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Interval(staggerStart, staggerEnd, curve: Curves.easeOut),
        ));

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      }),
    );
  }
}
