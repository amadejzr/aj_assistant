import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ai/claude_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/model_cubit.dart';
import '../models/message.dart';
import 'approval_card.dart';
import 'message_bubble.dart';
import 'typing_indicator.dart';

class ActiveChatView extends StatelessWidget {
  final VoidCallback onOpenDrawer;
  final VoidCallback onClose;

  const ActiveChatView({
    super.key,
    required this.onOpenDrawer,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final model = context.watch<ModelCubit>().state;

    return BlocListener<ChatCubit, ChatState>(
      listenWhen: (prev, curr) => prev.error != curr.error && curr.error != null,
      listener: (context, state) {
        AppToast.show(
          context,
          message: state.error!,
          type: AppToastType.error,
        );
      },
      child: Column(
        children: [
          _buildHeader(context, colors, model),
          const Expanded(child: _MessageList()),
          const _ChatInput(),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppColors colors,
    ClaudeModel model,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onOpenDrawer,
            icon: Icon(
              Icons.menu_rounded,
              color: colors.onBackgroundMuted,
              size: 22,
            ),
          ),
          Text(
            'Bower',
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colors.onBackground,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showModelPicker(context, colors, model),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                model.label,
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.onBackgroundMuted,
                ),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon:
                Icon(Icons.close, color: colors.onBackgroundMuted, size: 20),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  void _showModelPicker(
    BuildContext context,
    AppColors colors,
    ClaudeModel currentModel,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: colors.border, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onBackgroundMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Model',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onBackground,
              ),
            ),
            const SizedBox(height: 12),
            for (final option in ClaudeModel.values)
              _ModelOption(
                model: option,
                isSelected: option == currentModel,
                colors: colors,
                onTap: () {
                  context.read<ModelCubit>().setModel(option);
                  Navigator.of(context).pop();
                },
              ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: colors.accent),
          );
        }

        if (state.messages.isEmpty && !state.isAiTyping) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Ask me anything about your data.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 15,
                  color: colors.onBackgroundMuted,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          reverse: true,
          itemCount: state.messages.length + (state.isAiTyping ? 1 : 0),
          itemBuilder: (context, index) {
            if (state.isAiTyping && index == 0) {
              if (state.streamingText.isNotEmpty) {
                return MessageBubble(
                  message: Message(
                    id: '_streaming',
                    role: MessageRole.assistant,
                    content: state.streamingText,
                  ),
                );
              }
              return const Align(
                alignment: Alignment.centerLeft,
                child: TypingIndicator(),
              );
            }

            final msgIndex = state.isAiTyping
                ? state.messages.length - index
                : state.messages.length - 1 - index;

            if (msgIndex < 0 || msgIndex >= state.messages.length) {
              return const SizedBox.shrink();
            }

            final msg = state.messages[msgIndex];

            if (msg.hasPendingActions) {
              return ApprovalCard(
                actions: msg.pendingActions,
                status: msg.approvalStatus ?? ApprovalStatus.pending,
              );
            }

            if (msg.role == MessageRole.assistant && msg.content.isEmpty) {
              return const SizedBox.shrink();
            }

            return MessageBubble(message: msg);
          },
        );
      },
    );
  }
}

class _ChatInput extends StatefulWidget {
  const _ChatInput();

  @override
  State<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<_ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    context.read<ChatCubit>().sendMessage(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              maxLines: 4,
              minLines: 1,
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 14,
                color: colors.onBackground,
              ),
              decoration: InputDecoration(
                hintText: 'Message Bower...',
                fillColor: colors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide:
                      BorderSide(color: colors.accent, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          BlocBuilder<ChatCubit, ChatState>(
            buildWhen: (prev, curr) =>
                prev.isAiTyping != curr.isAiTyping,
            builder: (context, state) {
              return IconButton(
                onPressed: state.isAiTyping ? null : _send,
                icon: Icon(
                  Icons.arrow_upward_rounded,
                  color: state.isAiTyping
                      ? colors.onBackgroundMuted
                      : colors.accent,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: state.isAiTyping
                      ? colors.accentMuted
                      : colors.accent.withValues(alpha: 0.15),
                  shape: const CircleBorder(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModelOption extends StatelessWidget {
  final ClaudeModel model;
  final bool isSelected;
  final AppColors colors;
  final VoidCallback onTap;

  const _ModelOption({
    required this.model,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? colors.accent.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: colors.accent.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.label,
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    model.description,
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 13,
                      color: colors.onBackgroundMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, color: colors.accent, size: 20),
          ],
        ),
      ),
    );
  }
}
