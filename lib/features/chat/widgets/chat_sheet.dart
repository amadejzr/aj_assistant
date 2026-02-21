import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../models/message.dart';
import '../repositories/chat_repository.dart';
import 'approval_card.dart';
import 'message_bubble.dart';
import 'typing_indicator.dart';

/// Opens the chat as a draggable bottom sheet.
void showChatSheet(
  BuildContext context, {
  required String userId,
  required ChatRepository chatRepository,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) => ChatBloc(
        chatRepository: chatRepository,
        userId: userId,
      )..add(const ChatStarted()),
      child: const _ChatSheetBody(),
    ),
  );
}

class _ChatSheetBody extends StatelessWidget {
  const _ChatSheetBody();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: colors.border, width: 1)),
      ),
      child: Column(
        children: [
          _buildHandle(colors),
          _buildHeader(context, colors),
          const Expanded(child: _MessageList()),
          const _ChatInput(),
        ],
      ),
    );
  }

  Widget _buildHandle(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: colors.onBackgroundMuted.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Text(
            'AJ',
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colors.onBackground,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: colors.onBackgroundMuted, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state is ChatLoading) {
          return Center(child: CircularProgressIndicator(color: colors.accent));
        }

        if (state is! ChatReady) {
          return const SizedBox.shrink();
        }

        if (state.messages.isEmpty && !state.isAiTyping) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ask me anything about your data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 15,
                      color: colors.onBackgroundMuted,
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 13,
                        color: colors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            if (state.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: colors.error.withValues(alpha: 0.1),
                child: Text(
                  state.error!,
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 13,
                    color: colors.error,
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                reverse: true,
                itemCount: state.messages.length + (state.isAiTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  // Typing indicator at position 0 (bottom) when reversed
                  if (state.isAiTyping && index == 0) {
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

                  // Render approval card for pending actions
                  if (msg.hasPendingActions) {
                    return ApprovalCard(
                      actions: msg.pendingActions,
                      status: msg.approvalStatus ?? ApprovalStatus.pending,
                    );
                  }

                  // Skip empty assistant messages (they carry only pendingActions)
                  if (msg.role == MessageRole.assistant &&
                      msg.content.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return MessageBubble(message: msg);
                },
              ),
            ),
          ],
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

    context.read<ChatBloc>().add(ChatMessageSent(text));
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
        bottom:
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom +
            12,
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
                hintText: 'Message AJ...',
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
                  borderSide: BorderSide(color: colors.accent, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          BlocBuilder<ChatBloc, ChatState>(
            buildWhen: (prev, curr) {
              final prevTyping = prev is ChatReady && prev.isAiTyping;
              final currTyping = curr is ChatReady && curr.isAiTyping;
              return prevTyping != currTyping;
            },
            builder: (context, state) {
              final isTyping = state is ChatReady && state.isAiTyping;
              return IconButton(
                onPressed: isTyping ? null : _send,
                icon: Icon(
                  Icons.arrow_upward_rounded,
                  color: isTyping ? colors.onBackgroundMuted : colors.accent,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: isTyping
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
