import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ai/claude_client.dart';
import '../../../core/ai/claude_model.dart';
import '../../../core/database/app_database.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/conversation_history_cubit.dart';
import '../repositories/chat_repository.dart';
import '../widgets/active_chat_view.dart';
import '../widgets/conversation_history_drawer.dart';

void showChatDialog(
  BuildContext context, {
  required String userId,
  required ClaudeClient claude,
  required AppDatabase appDatabase,
  required ModuleRepository moduleRepository,
  required ChatRepository chatRepository,
  required ClaudeModel model,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 400),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                ConversationHistoryCubit(repository: chatRepository)..start(),
          ),
          BlocProvider(
            create: (_) => ChatCubit(
              claude: claude,
              db: appDatabase,
              chatRepository: chatRepository,
              moduleRepository: moduleRepository,
              userId: userId,
              model: model.apiId,
            ),
          ),
        ],
        child: const _ChatPage(),
      );
    },
  );
}

class _ChatPage extends StatelessWidget {
  const _ChatPage();

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
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
