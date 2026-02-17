import 'package:flutter/material.dart';

import '../../renderer/blueprint_node.dart';
import '../../engine/condition_evaluator.dart';
import '../../renderer/render_context.dart';
import '../../renderer/widget_registry.dart';

Widget buildConditional(BlueprintNode node, RenderContext ctx) {
  final cond = node as ConditionalNode;
  final context = {...ctx.screenParams, ...ctx.formValues};
  final isTrue = ConditionEvaluator.evaluate(cond.condition, context);
  final children = isTrue ? cond.thenChildren : cond.elseChildren;

  if (children.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: children
        .map((child) => WidgetRegistry.instance.build(child, ctx))
        .toList(),
  );
}
