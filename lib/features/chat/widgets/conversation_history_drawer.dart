import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../cubit/conversation_history_cubit.dart';
import '../models/conversation.dart';

class ConversationHistoryDrawer extends StatelessWidget {
  final VoidCallback onNewConversation;
  final void Function(String conversationId) onResume;

  const ConversationHistoryDrawer({
    super.key,
    required this.onNewConversation,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          _buildNewChatButton(colors),
          const SizedBox(height: 8),
          Divider(color: colors.border, height: 1),
          Expanded(child: _buildConversationList(context, colors)),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(
        'BowerLab',
        style: TextStyle(
          fontFamily: 'CormorantGaramond',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: colors.onBackground,
        ),
      ),
    );
  }

  Widget _buildNewChatButton(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: colors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onNewConversation,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(Icons.add_rounded, color: colors.accent, size: 20),
                const SizedBox(width: 10),
                Text(
                  'New conversation',
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList(BuildContext context, AppColors colors) {
    return BlocBuilder<ConversationHistoryCubit, ConversationHistoryState>(
      builder: (context, state) {
        if (state.conversations.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'Your conversations will appear here.',
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 13,
                color: colors.onBackgroundMuted.withValues(alpha: 0.6),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: state.conversations.length,
          itemBuilder: (context, index) {
            final conversation = state.conversations[index];
            return _ConversationTile(
              conversation: conversation,
              onTap: () => onResume(conversation.id),
            );
          },
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context, colors),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conversation.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.onBackground,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatRelativeTime(conversation.lastMessageAt),
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 12,
                  color: colors.onBackgroundMuted.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, AppColors colors) {
    final cubit = context.read<ConversationHistoryCubit>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: colors.onBackgroundMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    conversation.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.onBackground,
                    ),
                  ),
                ),
              ),
              Divider(color: colors.border, height: 1),
              ListTile(
                leading: Icon(
                  Icons.edit_outlined,
                  color: colors.onBackground,
                  size: 20,
                ),
                title: Text(
                  'Rename',
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 15,
                    color: colors.onBackground,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showRenameDialog(context, colors, cubit);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: colors.accent,
                  size: 20,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 15,
                    color: colors.accent,
                  ),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final error = await cubit.delete(conversation.id);
                  if (error != null && context.mounted) {
                    AppToast.show(
                      context,
                      message: error,
                      type: AppToastType.error,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    AppColors colors,
    ConversationHistoryCubit cubit,
  ) {
    final controller = TextEditingController(text: conversation.title ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Rename conversation',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.onBackground,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(
            fontFamily: 'Karla',
            fontSize: 14,
            color: colors.onBackground,
          ),
          decoration: InputDecoration(
            hintText: 'Conversation name',
            fillColor: colors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.accent, width: 1.5),
            ),
          ),
          onSubmitted: (value) async {
            Navigator.of(dialogContext).pop();
            await _submitRename(context, cubit, value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Karla',
                color: colors.onBackgroundMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _submitRename(context, cubit, controller.text);
            },
            child: Text(
              'Save',
              style: TextStyle(
                fontFamily: 'Karla',
                fontWeight: FontWeight.w600,
                color: colors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRename(
    BuildContext context,
    ConversationHistoryCubit cubit,
    String value,
  ) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final error = await cubit.rename(conversation.id, trimmed);
    if (error != null && context.mounted) {
      AppToast.show(
        context,
        message: error,
        type: AppToastType.error,
      );
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }
}
