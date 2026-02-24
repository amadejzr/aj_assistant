import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ai/api_key_service.dart';
import '../../../core/ai/claude_client.dart';
import '../../chat/cubit/model_cubit.dart';
import '../../../core/database/app_database.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../chat/repositories/chat_repository.dart';
import '../../chat/screens/chat_dialog.dart';
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
          final authState = context.read<AuthBloc>().state;
          if (authState is! AuthAuthenticated) return;

          final apiKeyService = context.read<ApiKeyService>();
          final model = context.read<ModelCubit>().state;
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

          final claude = ClaudeClient(apiKey: apiKey);
          if (context.mounted) {
            showChatDialog(
              context,
              userId: authState.user.uid,
              claude: claude,
              appDatabase: context.read<AppDatabase>(),
              moduleRepository: context.read<ModuleRepository>(),
              chatRepository: context.read<ChatRepository>(),
              model: model,
            );
          }
        },
      ),
    );
  }
}
