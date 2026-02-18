import 'package:flutter/material.dart';

import 'blueprint_parser.dart';
import 'blueprint_node.dart';
import 'render_context.dart';
import 'widget_registry.dart';

class BlueprintRenderer extends StatefulWidget {
  final Map<String, dynamic> blueprintJson;
  final RenderContext context_;

  const BlueprintRenderer({
    super.key,
    required this.blueprintJson,
    required this.context_,
  });

  @override
  State<BlueprintRenderer> createState() => _BlueprintRendererState();
}

class _BlueprintRendererState extends State<BlueprintRenderer> {
  static const _parser = BlueprintParser();
  late BlueprintNode _node;

  @override
  void initState() {
    super.initState();
    _node = _parser.parse(widget.blueprintJson);
  }

  @override
  void didUpdateWidget(BlueprintRenderer old) {
    super.didUpdateWidget(old);
    if (!identical(widget.blueprintJson, old.blueprintJson)) {
      _node = _parser.parse(widget.blueprintJson);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WidgetRegistry.instance.build(_node, widget.context_);
  }
}
