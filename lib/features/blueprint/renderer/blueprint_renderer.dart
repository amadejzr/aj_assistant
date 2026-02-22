import 'package:flutter/material.dart';

import '../../../core/logging/log.dart';
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
  late BlueprintNode _node;

  BlueprintParser _createParser() {
    return BlueprintParser(
      fieldSets: widget.context_.module.fieldSets,
    );
  }

  @override
  void initState() {
    super.initState();
    _node = _createParser().parse(widget.blueprintJson);
    Log.d('Parsed blueprint for initial build', tag: 'Perf');
  }

  @override
  void didUpdateWidget(BlueprintRenderer old) {
    super.didUpdateWidget(old);
    if (!identical(widget.blueprintJson, old.blueprintJson)) {
      _node = _createParser().parse(widget.blueprintJson);
      Log.d('Blueprint changed — re-parsing', tag: 'Perf');
    } else {
      Log.d('Blueprint identical — skipped parse', tag: 'Perf');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WidgetRegistry.instance.build(_node, widget.context_);
  }
}
