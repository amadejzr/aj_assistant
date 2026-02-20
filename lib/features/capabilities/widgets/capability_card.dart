import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../models/capability.dart';

class CapabilityCard extends StatelessWidget {
  final Capability capability;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CapabilityCard({
    super.key,
    required this.capability,
    required this.onToggle,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            _buildIcon(colors),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capability.title,
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _scheduleDescription,
                    style: TextStyle(
                      fontFamily: 'Karla',
                      fontSize: 12,
                      color: colors.onBackgroundMuted,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: capability.enabled,
              onChanged: onToggle,
              activeTrackColor: colors.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(AppColors colors) {
    final (icon, color) = switch (capability) {
      ScheduledReminder() => (
        PhosphorIcons.bell(PhosphorIconsStyle.duotone),
        colors.accent,
      ),
      DeadlineReminder() => (
        PhosphorIcons.calendarCheck(PhosphorIconsStyle.duotone),
        colors.success,
      ),
      StreakNudge() => (
        PhosphorIcons.flame(PhosphorIconsStyle.duotone),
        const Color(0xFFE8913A),
      ),
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String get _scheduleDescription {
    return switch (capability) {
      ScheduledReminder(:final frequency, :final hour, :final minute,
          :final dayOfWeek, :final dayOfMonth) => switch (frequency) {
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
