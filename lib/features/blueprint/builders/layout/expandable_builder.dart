import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';
import '../../renderer/widget_registry.dart';

Widget buildExpandable(BlueprintNode node, RenderContext ctx) {
  final expandable = node as ExpandableNode;
  return _ExpandableWidget(expandable: expandable, ctx: ctx);
}

class _ExpandableWidget extends StatefulWidget {
  final ExpandableNode expandable;
  final RenderContext ctx;

  const _ExpandableWidget({required this.expandable, required this.ctx});

  @override
  State<_ExpandableWidget> createState() => _ExpandableWidgetState();
}

class _ExpandableWidgetState extends State<_ExpandableWidget>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _controller;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _expanded = widget.expandable.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    if (_expanded) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final registry = WidgetRegistry.instance;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.expandable.title != null)
                        Text(
                          widget.expandable.title!,
                          style: TextStyle(
                            fontFamily: 'CormorantGaramond',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colors.onBackground,
                          ),
                        ),
                      // Ink underline
                      Container(
                        height: 1,
                        margin: const EdgeInsets.only(top: 4),
                        color: colors.border,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                RotationTransition(
                  turns: _rotationAnimation,
                  child: Icon(
                    Icons.expand_more,
                    color: colors.onBackgroundMuted,
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final child in widget.expandable.children)
                    registry.build(child, widget.ctx),
                ],
              ),
            ),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
