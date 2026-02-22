import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/database/app_database.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../chat/repositories/chat_repository.dart';
import '../../chat/widgets/chat_sheet.dart';
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
        onPressed: () {
          final authState = context.read<AuthBloc>().state;
          if (authState is! AuthAuthenticated) return;

          showChatSheet(
            context,
            userId: authState.user.uid,
            chatRepository: context.read<ChatRepository>(),
            appDatabase: context.read<AppDatabase>(),
            moduleRepository: context.read<ModuleRepository>(),
          );
        },
      ),
    );
  }
}
