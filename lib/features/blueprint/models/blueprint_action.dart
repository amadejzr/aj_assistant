import 'package:equatable/equatable.dart';

/// Type-safe actions used by buttons, FABs, and other interactive nodes.
sealed class BlueprintAction extends Equatable {
  const BlueprintAction();
  Map<String, dynamic> toJson();

  static BlueprintAction fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'navigate' => NavigateAction.fromJson(json),
      'navigate_back' => const NavigateBackAction(),
      'submit' => const SubmitAction(),
      'delete_entry' => DeleteEntryAction.fromJson(json),
      'update_entry' => UpdateEntryAction.fromJson(json),
      'show_form_sheet' => ShowFormSheetAction.fromJson(json),
      'confirm' => ConfirmAction.fromJson(json),
      'toast' => ToastAction.fromJson(json),
      _ => RawAction(json),
    };
  }
}

class NavigateAction extends BlueprintAction {
  final String screen;
  final Map<String, dynamic> params;
  final List<String> forwardFields;

  const NavigateAction({
    required this.screen,
    this.params = const {},
    this.forwardFields = const [],
  });

  factory NavigateAction.fromJson(Map<String, dynamic> json) {
    return NavigateAction(
      screen: json['screen'] as String? ?? '',
      params: Map<String, dynamic>.from(json['params'] as Map? ?? {}),
      forwardFields: List<String>.from(json['forwardFields'] as List? ?? []),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'navigate',
        'screen': screen,
        if (params.isNotEmpty) 'params': params,
        if (forwardFields.isNotEmpty) 'forwardFields': forwardFields,
      };

  @override
  List<Object?> get props => [screen, params, forwardFields];
}

class NavigateBackAction extends BlueprintAction {
  const NavigateBackAction();

  @override
  Map<String, dynamic> toJson() => {'type': 'navigate_back'};

  @override
  List<Object?> get props => [];
}

class SubmitAction extends BlueprintAction {
  const SubmitAction();

  @override
  Map<String, dynamic> toJson() => {'type': 'submit'};

  @override
  List<Object?> get props => [];
}

class DeleteEntryAction extends BlueprintAction {
  final bool confirm;
  final String? confirmMessage;

  const DeleteEntryAction({this.confirm = false, this.confirmMessage});

  factory DeleteEntryAction.fromJson(Map<String, dynamic> json) {
    return DeleteEntryAction(
      confirm: json['confirm'] as bool? ?? false,
      confirmMessage: json['confirmMessage'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'delete_entry',
        if (confirm) 'confirm': confirm,
        if (confirmMessage != null) 'confirmMessage': confirmMessage,
      };

  @override
  List<Object?> get props => [confirm, confirmMessage];
}

class UpdateEntryAction extends BlueprintAction {
  final Map<String, dynamic> data;
  final String? label;

  const UpdateEntryAction({required this.data, this.label});

  factory UpdateEntryAction.fromJson(Map<String, dynamic> json) {
    return UpdateEntryAction(
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      label: json['label'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'update_entry',
        'data': data,
        if (label != null) 'label': label,
      };

  @override
  List<Object?> get props => [data, label];
}

class ShowFormSheetAction extends BlueprintAction {
  final String screen;
  final String? title;

  const ShowFormSheetAction({required this.screen, this.title});

  factory ShowFormSheetAction.fromJson(Map<String, dynamic> json) {
    return ShowFormSheetAction(
      screen: json['screen'] as String? ?? '',
      title: json['title'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'show_form_sheet',
        'screen': screen,
        if (title != null) 'title': title,
      };

  @override
  List<Object?> get props => [screen, title];
}

class ConfirmAction extends BlueprintAction {
  final String? title;
  final String? message;
  final BlueprintAction onConfirm;

  const ConfirmAction({this.title, this.message, required this.onConfirm});

  factory ConfirmAction.fromJson(Map<String, dynamic> json) {
    return ConfirmAction(
      title: json['title'] as String?,
      message: json['message'] as String?,
      onConfirm: BlueprintAction.fromJson(
        Map<String, dynamic>.from(json['onConfirm'] as Map? ?? {}),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'confirm',
        if (title != null) 'title': title,
        if (message != null) 'message': message,
        'onConfirm': onConfirm.toJson(),
      };

  @override
  List<Object?> get props => [title, message, onConfirm];
}

class ToastAction extends BlueprintAction {
  final String message;

  const ToastAction({required this.message});

  factory ToastAction.fromJson(Map<String, dynamic> json) {
    return ToastAction(
      message: json['message'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'toast',
        'message': message,
      };

  @override
  List<Object?> get props => [message];
}

/// Passthrough for unrecognized action types.
class RawAction extends BlueprintAction {
  final Map<String, dynamic> json;
  const RawAction(this.json);

  @override
  Map<String, dynamic> toJson() => json;

  @override
  List<Object?> get props => [json];
}
