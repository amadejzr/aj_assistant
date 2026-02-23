import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

Widget buildScheduleNotification(BlueprintNode node, RenderContext ctx) {
  final input = node as ScheduleNotificationNode;
  return _ScheduleNotificationWidget(input: input, ctx: ctx);
}

class _ScheduleNotificationWidget extends StatelessWidget {
  final ScheduleNotificationNode input;
  final RenderContext ctx;

  const _ScheduleNotificationWidget({
    required this.input,
    required this.ctx,
  });

  Map<String, dynamic> _currentValue() {
    final raw = ctx.getFormValue(input.fieldKey);
    if (raw is Map<String, dynamic>) return raw;
    return {'enabled': false};
  }

  void _update(Map<String, dynamic> value) {
    ctx.onFormValueChanged(input.fieldKey, value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final meta = ctx.resolveFieldMeta(input.fieldKey, input.properties);
    final label = meta.label;
    final compound = _currentValue();
    final enabled = compound['enabled'] as bool? ?? false;

    final dateMs = compound['date'] as int?;
    final hour = compound['hour'] as int?;
    final minute = compound['minute'] as int?;

    DateTime? parsedDate;
    if (dateMs != null) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(dateMs);
    }

    TimeOfDay? parsedTime;
    if (hour != null && minute != null) {
      parsedTime = TimeOfDay(hour: hour, minute: minute);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 15,
                  color: colors.onBackground,
                ),
              ),
              Switch.adaptive(
                value: enabled,
                activeTrackColor: colors.accent,
                activeThumbColor: Colors.white,
                onChanged: (value) {
                  _update({...compound, 'enabled': value});
                },
              ),
            ],
          ),

          // Expandable date + time pickers
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Column(
                children: [
                  // Date picker
                  _PickerTile(
                    icon: Icons.calendar_today_outlined,
                    label: parsedDate != null
                        ? DateFormat.yMMMd().format(parsedDate)
                        : 'Select date',
                    hasValue: parsedDate != null,
                    colors: colors,
                    onTap: () async {
                      final initial = parsedDate ?? DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                                  primary: colors.accent,
                                ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        _update({
                          ...compound,
                          'enabled': true,
                          'date': picked.millisecondsSinceEpoch,
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Time picker
                  _PickerTile(
                    icon: Icons.access_time_outlined,
                    label: parsedTime != null
                        ? parsedTime.format(context)
                        : 'Select time',
                    hasValue: parsedTime != null,
                    colors: colors,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: parsedTime ?? TimeOfDay.now(),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                                  primary: colors.accent,
                                ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        _update({
                          ...compound,
                          'enabled': true,
                          'hour': picked.hour,
                          'minute': picked.minute,
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            crossFadeState:
                enabled ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasValue;
  final AppColors colors;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.hasValue,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 15,
                  color: hasValue
                      ? colors.onBackground
                      : colors.onBackgroundMuted.withValues(alpha: 0.5),
                ),
              ),
            ),
            Icon(icon, size: 18, color: colors.onBackgroundMuted),
          ],
        ),
      ),
    );
  }
}
