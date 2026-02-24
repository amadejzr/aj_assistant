import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/claude_client.dart';
import '../../../core/database/app_database.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/conversation_history_cubit.dart';
import '../cubit/model_cubit.dart';
import '../repositories/chat_repository.dart';
import '../widgets/active_chat_view.dart';
import '../widgets/conversation_history_drawer.dart';

class ChatScreen extends StatelessWidget {
  final ClaudeClient claude;

  const ChatScreen({super.key, required this.claude});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }

    final model = context.read<ModelCubit>().state;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ConversationHistoryCubit(
            repository: context.read<ChatRepository>(),
          )..start(),
        ),
        BlocProvider(
          create: (_) => ChatCubit(
            claude: claude,
            db: context.read<AppDatabase>(),
            chatRepository: context.read<ChatRepository>(),
            moduleRepository: context.read<ModuleRepository>(),
            userId: authState.user.uid,
            model: model.apiId,
          ),
        ),
      ],
      child: const _ChatBody(),
    );
  }
}

class _ChatBody extends StatelessWidget {
  const _ChatBody();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      drawerEdgeDragWidth: 40,
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.78,
        child: Drawer(
          backgroundColor: colors.background,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
          ),
          child: ConversationHistoryDrawer(
            onNewConversation: () {
              Navigator.of(context).pop(); // close drawer
              context.read<ChatCubit>().newConversation();
            },
            onResume: (conversationId) {
              Navigator.of(context).pop(); // close drawer
              context.read<ChatCubit>().resumeConversation(conversationId);
            },
          ),
        ),
      ),
      body: Builder(
        builder: (scaffoldContext) => SafeArea(
          child: ActiveChatView(
            onOpenDrawer: () => Scaffold.of(scaffoldContext).openDrawer(),
            onClose: () => context.pop(),
          ),
        ),
      ),
    );
  }
}
