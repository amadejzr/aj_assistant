// lib/features/chat/models/message.dart
import 'dart:convert';

import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant }

enum ApprovalStatus { pending, approved, rejected }

class PendingAction extends Equatable {
  final String toolUseId;
  final String name;
  final Map<String, dynamic> input;
  final String description;

  const PendingAction({
    required this.toolUseId,
    required this.name,
    required this.input,
    required this.description,
  });

  factory PendingAction.fromMap(Map<String, dynamic> map) {
    return PendingAction(
      toolUseId: map['toolUseId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      input: Map<String, dynamic>.from(map['input'] as Map? ?? {}),
      description: map['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'toolUseId': toolUseId,
        'name': name,
        'input': input,
        'description': description,
      };

  @override
  List<Object?> get props => [toolUseId, name, input, description];
}

class Message extends Equatable {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime? timestamp;
  final List<PendingAction> pendingActions;
  final ApprovalStatus? approvalStatus;

  const Message({
    required this.id,
    required this.role,
    required this.content,
    this.timestamp,
    this.pendingActions = const [],
    this.approvalStatus,
  });

  bool get hasPendingActions => pendingActions.isNotEmpty;

  /// Converts to Claude API message format.
  Map<String, dynamic> toApiMessage() => {
        'role': role == MessageRole.user ? 'user' : 'assistant',
        'content': content,
      };

  /// Creates from a Drift ChatMessage row data map.
  factory Message.fromRow(Map<String, dynamic> row) {
    final toolCallsJson = row['tool_calls'] as String?;
    List<PendingAction> actions = const [];
    ApprovalStatus? status;

    if (toolCallsJson != null) {
      final decoded = jsonDecode(toolCallsJson) as Map<String, dynamic>;
      actions = (decoded['actions'] as List?)
              ?.map((a) => PendingAction.fromMap(
                    Map<String, dynamic>.from(a as Map),
                  ))
              .toList() ??
          const [];
      final statusStr = decoded['approvalStatus'] as String?;
      status = switch (statusStr) {
        'approved' => ApprovalStatus.approved,
        'rejected' => ApprovalStatus.rejected,
        'pending' => ApprovalStatus.pending,
        _ => actions.isNotEmpty ? ApprovalStatus.pending : null,
      };
    }

    return Message(
      id: row['id'] as String,
      role: row['role'] == 'assistant'
          ? MessageRole.assistant
          : MessageRole.user,
      content: row['content'] as String? ?? '',
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      pendingActions: actions,
      approvalStatus: status,
    );
  }

  Message copyWith({
    ApprovalStatus? approvalStatus,
  }) {
    return Message(
      id: id,
      role: role,
      content: content,
      timestamp: timestamp,
      pendingActions: pendingActions,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }

  @override
  List<Object?> get props =>
      [id, role, content, timestamp, pendingActions, approvalStatus];
}
