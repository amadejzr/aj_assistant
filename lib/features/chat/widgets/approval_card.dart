import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../models/message.dart';

class ApprovalCard extends StatelessWidget {
  final List<PendingAction> actions;
  final ApprovalStatus status;

  const ApprovalCard({
    super.key,
    required this.actions,
    this.status = ApprovalStatus.pending,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final isApproved = status == ApprovalStatus.approved;
    final isRejected = status == ApprovalStatus.rejected;
    final isResolved = isApproved || isRejected;

    final borderColor = isApproved
        ? colors.success.withValues(alpha: 0.4)
        : isRejected
            ? colors.onBackgroundMuted.withValues(alpha: 0.2)
            : colors.accent.withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isApproved
            ? colors.success.withValues(alpha: 0.06)
            : colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors, isApproved, isRejected),
          const SizedBox(height: 10),
          ...actions.map((a) => _ActionItem(
                action: a,
                isResolved: isResolved,
                isApproved: isApproved,
              )),
          if (!isResolved) ...[
            const SizedBox(height: 10),
            _buildButtons(context, colors),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    dynamic colors,
    bool isApproved,
    bool isRejected,
  ) {
    final icon = isApproved
        ? Icons.check_circle_rounded
        : isRejected
            ? Icons.cancel_rounded
            : Icons.pending_rounded;

    final label = isApproved
        ? 'Approved'
        : isRejected
            ? 'Rejected'
            : 'Confirm';

    final color = isApproved
        ? colors.success
        : isRejected
            ? colors.onBackgroundMuted
            : colors.onBackground;

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Karla',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, dynamic colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            context.read<ChatBloc>().add(const ChatActionRejected());
          },
          child: Text(
            'Reject',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.onBackgroundMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () {
            context.read<ChatBloc>().add(const ChatActionApproved());
          },
          style: FilledButton.styleFrom(
            backgroundColor: colors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Approve',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.onBackground,
            ),
          ),
        ),
      ],
    );
  }
}

/// Displays a single pending action with its data fields clearly laid out.
class _ActionItem extends StatelessWidget {
  final PendingAction action;
  final bool isResolved;
  final bool isApproved;

  const _ActionItem({
    required this.action,
    required this.isResolved,
    required this.isApproved,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCreate = action.name == 'createEntry';
    final data = action.input['data'] as Map? ?? {};
    final schemaKey = action.input['schemaKey'] as String?;

    final accentColor =
        isResolved ? colors.onBackgroundMuted : colors.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action type header
          Row(
            children: [
              Icon(
                isCreate ? Icons.add_circle_outline : Icons.edit_outlined,
                size: 15,
                color: accentColor,
              ),
              const SizedBox(width: 6),
              Text(
                isCreate
                    ? 'Create${schemaKey != null ? ' in $schemaKey' : ''}'
                    : 'Update entry',
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          if (data.isNotEmpty) ...[
            const SizedBox(height: 6),
            // Data fields
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            e.key,
                            style: TextStyle(
                              fontFamily: 'Karla',
                              fontSize: 12,
                              color: colors.onBackgroundMuted,
                              height: 1.4,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${e.value}',
                            style: TextStyle(
                              fontFamily: 'Karla',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.onBackground,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
