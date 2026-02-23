import '../../blueprint/dsl/action_builders.dart';

/// DSL for declaring reminder side-effects on mutations.
class Reminders {
  Reminders._();

  /// Creates a one-shot reminder from form field values.
  ///
  /// - [titleField]: template string like `'Hike: {{name}}'` or a bare field key
  /// - [messageField]: template string or bare field key
  /// - [dateField]: form field key containing the reminder date (epoch int)
  /// - [timeField]: optional form field key for time (overrides hour/minute defaults)
  /// - [conditionField]: optional form field key — reminder only created when truthy
  /// - [hour]/[minute]: default time if no timeField provided (defaults 9:00)
  static Json onFormSubmit({
    required String titleField,
    required String messageField,
    required String dateField,
    String? timeField,
    String? conditionField,
    int hour = 9,
    int minute = 0,
  }) => {
    'type': 'scheduled',
    'frequency': 'once',
    'titleField': titleField,
    'messageField': messageField,
    'dateField': dateField,
    'timeField': ?timeField,
    'conditionField': ?conditionField,
    'hour': hour,
    'minute': minute,
  };

}

/// Standalone notification widgets that carry their own config.
///
/// Drop into any form's children — the BLoC auto-detects them on submit.
/// No mutation wiring needed.
class Notifications {
  Notifications._();

  /// Compound toggle + date + time picker that schedules a notification.
  ///
  /// Self-contained: carries its own title/message templates.
  /// On form submit, the BLoC scans the screen blueprint for these nodes,
  /// reads the compound form value `{enabled, date, hour, minute}`,
  /// and schedules the notification automatically.
  static Json scheduleField({
    required String fieldKey,
    String? label,
    required String titleTemplate,
    required String messageTemplate,
    dynamic visibleWhen,
  }) => {
    'type': 'schedule_notification',
    'fieldKey': fieldKey,
    'label': ?label,
    'titleTemplate': titleTemplate,
    'messageTemplate': messageTemplate,
    'visibleWhen': ?visibleWhen,
  };
}

/// DSL for declaring module-level capabilities in `settings.capabilities`.
class Cap {
  Cap._();

  /// Auto-schedules a notification whenever an entry with a date field
  /// is created or updated. No form widget needed.
  static Json autoNotify({
    required String dateField,
    String? timeField,
    int offsetMinutes = 0,
    required String titleTemplate,
    required String messageTemplate,
  }) => {
    'type': 'auto_notify',
    'dateField': dateField,
    'timeField': ?timeField,
    'offsetMinutes': offsetMinutes,
    'titleTemplate': titleTemplate,
    'messageTemplate': messageTemplate,
  };
}
