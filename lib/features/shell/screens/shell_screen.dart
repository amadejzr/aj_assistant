import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/api_key_service.dart';
import '../../../core/ai/claude_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../widgets/breathing_fab.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: child,
      floatingActionButton: BreathingFab(
        colors: colors,
        onPressed: () async {
          final apiKeyService = context.read<ApiKeyService>();
          final apiKey = await apiKeyService.getKey();
          if (apiKey == null || apiKey.isEmpty) {
            if (context.mounted) {
              AppToast.show(
                context,
                message: 'Set your Anthropic API key in settings first.',
                type: AppToastType.error,
              );
            }
            return;
          }

          if (context.mounted) {
            context.push('/chat', extra: ClaudeClient(apiKey: apiKey));
          }
        },
      ),
    );
  }
}
