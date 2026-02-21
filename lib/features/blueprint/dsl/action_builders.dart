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
    if (action != null) 'action': action,
    if (style != null) 'style': style,
  };

  static Json fab({String? icon, Json? action}) => {
    'type': 'fab',
    if (icon != null) 'icon': icon,
    if (action != null) 'action': action,
  };

  static Json iconButton({
    required String icon,
    Json? action,
    String? tooltip,
  }) => {
    'type': 'icon_button',
    'icon': icon,
    if (action != null) 'action': action,
    if (tooltip != null) 'tooltip': tooltip,
  };

  static Json actionMenu({String? icon, List<Json>? items}) => {
    'type': 'action_menu',
    if (icon != null) 'icon': icon,
    if (items != null) 'items': items,
  };

  static Json menuItem({
    required String label,
    String? icon,
    Json? action,
  }) => {
    'label': label,
    if (icon != null) 'icon': icon,
    if (action != null) 'action': action,
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
    if (params != null) 'params': params,
    if (forwardFields != null) 'forwardFields': forwardFields,
    if (label != null) 'label': label,
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
    if (title != null) 'title': title,
    if (message != null) 'message': message,
    'onConfirm': onConfirm,
  };
}
