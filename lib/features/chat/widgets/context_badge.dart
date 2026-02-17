import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_context.dart';

/// Small chip showing current module context above the input.
class ContextBadge extends StatelessWidget {
  final ChatContext context_;

  const ContextBadge({super.key, required this.context_});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = switch (context_) {
      DashboardChatContext() => 'Dashboard',
      ModulesListChatContext() => 'Modules',
      ModuleChatContext(:final moduleId) => moduleId,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.accentMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Karla',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: colors.accent,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
