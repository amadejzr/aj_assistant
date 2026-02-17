import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory Message.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final actionsRaw = data['pendingActions'] as List?;
    final actions = actionsRaw
            ?.map((a) => PendingAction.fromMap(
                  Map<String, dynamic>.from(a as Map),
                ))
            .toList() ??
        const [];

    final statusStr = data['approvalStatus'] as String?;
    final approvalStatus = switch (statusStr) {
      'approved' => ApprovalStatus.approved,
      'rejected' => ApprovalStatus.rejected,
      'pending' => ApprovalStatus.pending,
      _ => actions.isNotEmpty ? ApprovalStatus.pending : null,
    };

    return Message(
      id: doc.id,
      role: data['role'] == 'assistant'
          ? MessageRole.assistant
          : MessageRole.user,
      content: data['content'] as String? ?? '',
      timestamp: _toDateTime(data['timestamp']),
      pendingActions: actions,
      approvalStatus: approvalStatus,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  @override
  List<Object?> get props =>
      [id, role, content, timestamp, pendingActions, approvalStatus];
}
