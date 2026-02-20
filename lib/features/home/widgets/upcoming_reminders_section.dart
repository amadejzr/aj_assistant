import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../capabilities/models/capability.dart';
import '../../capabilities/repositories/capability_repository.dart';

class UpcomingRemindersSection extends StatelessWidget {
  const UpcomingRemindersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<CapabilityRepository>();

    return StreamBuilder<List<Capability>>(
      stream: repository.watchEnabledCapabilities(limit: 3),
      builder: (context, snapshot) {
        final reminders = snapshot.data ?? [];
        final colors = context.colors;

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reminders',
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.onBackground,
                    ),
                  ),
                  if (reminders.isNotEmpty)
                    GestureDetector(
                      onTap: () => context.push('/reminders'),
                      child: Text(
                        'See all',
                        style: TextStyle(
                          fontFamily: 'Karla',
                          fontSize: 13,
                          color: colors.accent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (reminders.isEmpty)
                // Empty state — prompt to create first reminder
                GestureDetector(
                  onTap: () => context.push('/reminders'),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          PhosphorIcons.bellRinging(PhosphorIconsStyle.duotone),
                          color: colors.onBackgroundMuted,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No reminders yet',
                                style: TextStyle(
                                  fontFamily: 'Karla',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onBackground,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Set up reminders to stay on track',
                                style: TextStyle(
                                  fontFamily: 'Karla',
                                  fontSize: 12,
                                  color: colors.onBackgroundMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                          color: colors.onBackgroundMuted,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Reminder cards
                ...List.generate(reminders.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 0 : 8,
                    ),
                    child: _ReminderRow(capability: reminders[index]),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final Capability capability;

  const _ReminderRow({required this.capability});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, iconColor) = _iconForType(capability);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              capability.title,
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.onBackground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            flex: 0,
            child: Text(
              _scheduleDescription(capability),
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 12,
                color: colors.onBackgroundMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _iconForType(Capability cap) {
    final colors = switch (cap) {
      ScheduledReminder() => (
        PhosphorIcons.bell(PhosphorIconsStyle.duotone),
        const Color(0xFFD94E33), // vermillion accent
      ),
      DeadlineReminder() => (
        PhosphorIcons.calendarCheck(PhosphorIconsStyle.duotone),
        const Color(0xFF6B9E6B), // success green
      ),
      StreakNudge() => (
        PhosphorIcons.flame(PhosphorIconsStyle.duotone),
        const Color(0xFFE8913A), // warm amber
      ),
    };
    return colors;
  }

  String _scheduleDescription(Capability cap) {
    return switch (cap) {
      ScheduledReminder(
        :final frequency,
        :final hour,
        :final minute,
        :final dayOfWeek,
        :final dayOfMonth,
      ) =>
        switch (frequency) {
          ReminderFrequency.daily =>
            'Every day at ${_formatTime(hour, minute)}',
          ReminderFrequency.weekly =>
            'Every ${_dayName(dayOfWeek ?? 1)} at ${_formatTime(hour, minute)}',
          ReminderFrequency.monthly =>
            '${_ordinal(dayOfMonth ?? 1)} of each month at ${_formatTime(hour, minute)}',
        },
      DeadlineReminder(:final dateField, :final offsetMinutes) =>
        offsetMinutes < 0
            ? '${(-offsetMinutes / 1440).round()} day(s) before $dateField'
            : 'On $dateField',
      StreakNudge(:final inactivityDays) =>
        'Nudge after $inactivityDays days inactive',
    };
  }

  static String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$h:${minute.toString().padLeft(2, '0')} $period';
  }

  static String _dayName(int day) {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[day.clamp(1, 7)];
  }

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }
}
