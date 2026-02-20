import 'package:equatable/equatable.dart';

enum ReminderFrequency { once, daily, weekly, monthly }

sealed class Capability extends Equatable {
  final String id;
  final String? moduleId;
  final String title;
  final String message;
  final bool enabled;
  final DateTime? lastFiredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Capability({
    required this.id,
    this.moduleId,
    required this.title,
    required this.message,
    required this.enabled,
    this.lastFiredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get type;
  Map<String, dynamic> configToJson();

  Map<String, dynamic> toJson() => {
    if (moduleId != null) 'moduleId': moduleId,
    'type': type,
    'title': title,
    'message': message,
    'enabled': enabled,
    'config': configToJson(),
    if (lastFiredAt != null)
      'lastFiredAt': lastFiredAt!.millisecondsSinceEpoch,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  factory Capability.fromJson(String id, Map<String, dynamic> json) {
    final type = json['type'] as String;
    final config = Map<String, dynamic>.from(json['config'] as Map? ?? {});
    final moduleId = json['moduleId'] as String?;
    final title = json['title'] as String;
    final message = json['message'] as String;
    final enabled = json['enabled'] as bool? ?? true;
    final lastFiredAt = json['lastFiredAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['lastFiredAt'] as int)
        : null;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int);

    return switch (type) {
      'scheduled' => ScheduledReminder(
        id: id, moduleId: moduleId, title: title, message: message,
        enabled: enabled, lastFiredAt: lastFiredAt,
        createdAt: createdAt, updatedAt: updatedAt,
        frequency: ReminderFrequency.values.firstWhere(
          (f) => f.name == (config['frequency'] as String? ?? 'daily'),
        ),
        hour: config['hour'] as int? ?? 9,
        minute: config['minute'] as int? ?? 0,
        dayOfWeek: config['dayOfWeek'] as int?,
        dayOfMonth: config['dayOfMonth'] as int?,
        scheduledDate: config['scheduledDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(config['scheduledDate'] as int)
            : null,
      ),
      'deadline' => DeadlineReminder(
        id: id, moduleId: moduleId, title: title, message: message,
        enabled: enabled, lastFiredAt: lastFiredAt,
        createdAt: createdAt, updatedAt: updatedAt,
        schemaKey: config['schemaKey'] as String? ?? 'default',
        dateField: config['dateField'] as String? ?? 'date',
        offsetMinutes: config['offsetMinutes'] as int? ?? -1440,
      ),
      'streak' => StreakNudge(
        id: id, moduleId: moduleId, title: title, message: message,
        enabled: enabled, lastFiredAt: lastFiredAt,
        createdAt: createdAt, updatedAt: updatedAt,
        inactivityDays: config['inactivityDays'] as int? ?? 3,
        checkHour: config['checkHour'] as int? ?? 20,
        checkMinute: config['checkMinute'] as int? ?? 0,
        schemaKey: config['schemaKey'] as String?,
      ),
      _ => throw ArgumentError('Unknown capability type: $type'),
    };
  }
}

class ScheduledReminder extends Capability {
  final ReminderFrequency frequency;
  final int hour;
  final int minute;
  final int? dayOfWeek;
  final int? dayOfMonth;
  final DateTime? scheduledDate; // For one-shot reminders

  const ScheduledReminder({
    required super.id, super.moduleId,
    required super.title, required super.message,
    required super.enabled, super.lastFiredAt,
    required super.createdAt, required super.updatedAt,
    required this.frequency, required this.hour, required this.minute,
    this.dayOfWeek, this.dayOfMonth, this.scheduledDate,
  });

  @override
  String get type => 'scheduled';

  @override
  Map<String, dynamic> configToJson() => {
    'frequency': frequency.name,
    'hour': hour,
    'minute': minute,
    if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
    if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
    if (scheduledDate != null)
      'scheduledDate': scheduledDate!.millisecondsSinceEpoch,
  };

  @override
  List<Object?> get props => [
    id, moduleId, title, message, enabled, lastFiredAt,
    createdAt, updatedAt, frequency, hour, minute, dayOfWeek, dayOfMonth,
    scheduledDate,
  ];
}

class DeadlineReminder extends Capability {
  final String schemaKey;
  final String dateField;
  final int offsetMinutes;

  const DeadlineReminder({
    required super.id, super.moduleId,
    required super.title, required super.message,
    required super.enabled, super.lastFiredAt,
    required super.createdAt, required super.updatedAt,
    required this.schemaKey, required this.dateField,
    required this.offsetMinutes,
  });

  @override
  String get type => 'deadline';

  @override
  Map<String, dynamic> configToJson() => {
    'schemaKey': schemaKey,
    'dateField': dateField,
    'offsetMinutes': offsetMinutes,
  };

  @override
  List<Object?> get props => [
    id, moduleId, title, message, enabled, lastFiredAt,
    createdAt, updatedAt, schemaKey, dateField, offsetMinutes,
  ];
}

class StreakNudge extends Capability {
  final int inactivityDays;
  final int checkHour;
  final int checkMinute;
  final String? schemaKey;

  const StreakNudge({
    required super.id, super.moduleId,
    required super.title, required super.message,
    required super.enabled, super.lastFiredAt,
    required super.createdAt, required super.updatedAt,
    required this.inactivityDays, required this.checkHour,
    required this.checkMinute, this.schemaKey,
  });

  @override
  String get type => 'streak';

  @override
  Map<String, dynamic> configToJson() => {
    'inactivityDays': inactivityDays,
    'checkHour': checkHour,
    'checkMinute': checkMinute,
    if (schemaKey != null) 'schemaKey': schemaKey,
  };

  @override
  List<Object?> get props => [
    id, moduleId, title, message, enabled, lastFiredAt,
    createdAt, updatedAt, inactivityDays, checkHour, checkMinute, schemaKey,
  ];
}
