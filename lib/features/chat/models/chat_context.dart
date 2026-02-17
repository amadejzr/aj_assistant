import 'package:equatable/equatable.dart';

sealed class ChatContext extends Equatable {
  const ChatContext();

  Map<String, dynamic> toMap();
}

class DashboardChatContext extends ChatContext {
  const DashboardChatContext();

  @override
  Map<String, dynamic> toMap() => {'type': 'dashboard'};

  @override
  List<Object?> get props => [];
}

class ModulesListChatContext extends ChatContext {
  const ModulesListChatContext();

  @override
  Map<String, dynamic> toMap() => {'type': 'modules_list'};

  @override
  List<Object?> get props => [];
}

class ModuleChatContext extends ChatContext {
  final String moduleId;
  final String? screenId;

  const ModuleChatContext({required this.moduleId, this.screenId});

  @override
  Map<String, dynamic> toMap() => {
        'type': 'module',
        'moduleId': moduleId,
        if (screenId != null) 'screenId': screenId,
      };

  @override
  List<Object?> get props => [moduleId, screenId];
}
