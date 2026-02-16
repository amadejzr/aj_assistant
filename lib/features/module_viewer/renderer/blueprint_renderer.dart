import 'package:flutter/material.dart';

import 'blueprint_parser.dart';
import 'render_context.dart';
import 'widget_registry.dart';

class BlueprintRenderer extends StatelessWidget {
  final Map<String, dynamic> blueprintJson;
  final RenderContext context_;

  const BlueprintRenderer({
    super.key,
    required this.blueprintJson,
    required this.context_,
  });

  @override
  Widget build(BuildContext context) {
    const parser = BlueprintParser();
    final node = parser.parse(blueprintJson);
    return WidgetRegistry.instance.build(node, context_);
  }
}
