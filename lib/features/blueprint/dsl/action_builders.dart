typedef Json = Map<String, dynamic>;

/// Static builders for action widgets (button, fab, icon_button, action_menu).
class Actions {
  Actions._();

  static Json button({
    required String label,
    Json? action,
    String? style,
  }) => {
    'type': 'button',
    'label': label,
    'action': ?action,
    'style': ?style,
  };

  static Json fab({String? icon, Json? action}) => {
    'type': 'fab',
    'icon': ?icon,
    'action': ?action,
  };

  static Json iconButton({
    required String icon,
    Json? action,
    String? tooltip,
  }) => {
    'type': 'icon_button',
    'icon': icon,
    'action': ?action,
    'tooltip': ?tooltip,
  };

  static Json actionMenu({String? icon, List<Json>? items}) => {
    'type': 'action_menu',
    'icon': ?icon,
    'items': ?items,
  };

  static Json menuItem({
    required String label,
    String? icon,
    Json? action,
  }) => {
    'label': label,
    'icon': ?icon,
    'action': ?action,
  };
}

/// Static builders for action payloads (navigate, submit, delete, confirm).
class Act {
  Act._();

  static Json navigate(
    String screen, {
    Map<String, dynamic>? params,
    List<String>? forwardFields,
    String? label,
  }) => {
    'type': 'navigate',
    'screen': screen,
    'params': ?params,
    'forwardFields': ?forwardFields,
    'label': ?label,
  };

  static Json navigateBack() => {'type': 'navigate_back'};

  static Json submit() => {'type': 'submit'};

  static Json deleteEntry() => {'type': 'delete_entry'};

  static Json confirm({
    String? title,
    String? message,
    required Json onConfirm,
  }) => {
    'type': 'confirm',
    'title': ?title,
    'message': ?message,
    'onConfirm': onConfirm,
  };
}
