import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../blueprint_node.dart';
import '../render_context.dart';
import '../widget_registry.dart';

Widget buildSection(BlueprintNode node, RenderContext ctx) {
  final section = node as SectionNode;
  final registry = WidgetRegistry.instance;

  return _SectionWidget(section: section, ctx: ctx, registry: registry);
}

class _SectionWidget extends StatelessWidget {
  final SectionNode section;
  final RenderContext ctx;
  final WidgetRegistry registry;

  const _SectionWidget({
    required this.section,
    required this.ctx,
    required this.registry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null) ...[
          Text(
            section.title!,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colors.onBackground,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final child in section.children) ...[
          registry.build(child, ctx),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
