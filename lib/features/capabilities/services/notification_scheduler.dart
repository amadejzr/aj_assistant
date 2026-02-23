import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../core/logging/log.dart';
import '../models/capability.dart';
import '../repositories/capability_repository.dart';

class NotificationScheduler {
  final CapabilityRepository _repository;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationScheduler(this._repository);

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Cancel all and re-schedule from the database.
  Future<void> rescheduleAll() async {
    await _plugin.cancelAll();
    final capabilities = await _repository.getAllEnabledCapabilities();
    for (final cap in capabilities) {
      await _scheduleCapability(cap);
    }
  }

  /// Schedule notifications for a single capability.
  Future<void> scheduleCapability(Capability capability) async {
    if (!capability.enabled) return;
    await _scheduleCapability(capability);
  }

  Future<void> _scheduleCapability(Capability capability) async {
    switch (capability) {
      case ScheduledReminder():
        await _scheduleReminder(capability);
      case DeadlineReminder():
        break;
      case StreakNudge():
        break;
    }
  }

  Future<void> _scheduleReminder(ScheduledReminder cap) async {
    final notifId = cap.id.hashCode & 0x7FFFFFFF;
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      cap.hour,
      cap.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'capabilities',
        'Module Reminders',
        channelDescription: 'Reminders from your modules',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    switch (cap.frequency) {
      case ReminderFrequency.once:
        if (cap.scheduledDate == null) return;
        final oneShot = tz.TZDateTime(
          tz.local,
          cap.scheduledDate!.year,
          cap.scheduledDate!.month,
          cap.scheduledDate!.day,
          cap.hour,
          cap.minute,
        );
        // Don't schedule if the date is in the past
        if (oneShot.isBefore(now)) {
          Log.w(
            'Skipped notification "${cap.title}" — scheduled for $oneShot which is in the past',
            tag: 'Notifications',
          );
          return;
        }
        await _plugin.zonedSchedule(
          id: notifId,
          title: cap.title,
          body: cap.message,
          scheduledDate: oneShot,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      case ReminderFrequency.daily:
        await _plugin.zonedSchedule(
          id: notifId,
          title: cap.title,
          body: cap.message,
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      case ReminderFrequency.weekly:
        // Find next occurrence of the target day
        while (scheduled.weekday != (cap.dayOfWeek ?? 1)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        await _plugin.zonedSchedule(
          id: notifId,
          title: cap.title,
          body: cap.message,
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      case ReminderFrequency.monthly:
        scheduled = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          cap.dayOfMonth ?? 1,
          cap.hour,
          cap.minute,
        );
        if (scheduled.isBefore(now)) {
          scheduled = tz.TZDateTime(
            tz.local,
            now.year,
            now.month + 1,
            cap.dayOfMonth ?? 1,
            cap.hour,
            cap.minute,
          );
        }
        await _plugin.zonedSchedule(
          id: notifId,
          title: cap.title,
          body: cap.message,
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        );
    }
  }

  /// Returns all pending (scheduled) OS notifications.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _plugin.pendingNotificationRequests();
  }

  /// Cancel all notifications for a capability.
  Future<void> cancelCapability(String capabilityId) async {
    final notifId = capabilityId.hashCode & 0x7FFFFFFF;
    await _plugin.cancel(id: notifId);
  }
}
