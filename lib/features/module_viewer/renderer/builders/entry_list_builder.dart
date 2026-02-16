import 'package:flutter/material.dart';

import '../blueprint_node.dart';
import '../entry_filter.dart';
import '../render_context.dart';
import '../widget_registry.dart';

Widget buildEntryList(BlueprintNode node, RenderContext ctx) {
  final listNode = node as EntryListNode;
  return _EntryListWidget(listNode: listNode, ctx: ctx);
}

class _EntryListWidget extends StatelessWidget {
  final EntryListNode listNode;
  final RenderContext ctx;

  const _EntryListWidget({required this.listNode, required this.ctx});

  @override
  Widget build(BuildContext context) {
    // Use EntryFilter for unified filtering
    final result = EntryFilter.filter(
      ctx.entries,
      listNode.filter,
      ctx.screenParams,
    );
    var entries = result.entries;

    // Sort
    final orderBy = listNode.query['orderBy'] as String?;
    final direction = listNode.query['direction'] as String? ?? 'desc';
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
    final limit = listNode.query['limit'] as int?;
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
      return WidgetRegistry.instance.build(emptyNode, ctx);
    }

    // Render items
    final itemLayout = listNode.itemLayout;
    if (itemLayout == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: entries.map((entry) {
        final entryCtx = RenderContext(
          module: ctx.module,
          entries: [entry],
          formValues: entry.data,
          screenParams: ctx.screenParams,
          canGoBack: ctx.canGoBack,
          onFormValueChanged: ctx.onFormValueChanged,
          onFormSubmit: ctx.onFormSubmit,
          onNavigateToScreen: ctx.onNavigateToScreen,
          onNavigateBack: ctx.onNavigateBack,
          onDeleteEntry: ctx.onDeleteEntry,
          resolvedExpressions: ctx.resolvedExpressions,
        );
        return WidgetRegistry.instance.build(itemLayout, entryCtx);
      }).toList(),
    );
  }
}
