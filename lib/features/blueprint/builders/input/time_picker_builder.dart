import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

/// Renders a tappable time picker field that opens the platform time dialog and stores a `"HH:mm"` string.
///
/// Blueprint JSON:
/// ```json
/// {"type": "time_picker", "fieldKey": "startTime"}
/// ```
///
/// - `fieldKey` (`String`, required): Schema field key this picker is bound to. The selected time is stored as a `"HH:mm"` formatted string.
Widget buildTimePicker(BlueprintNode node, RenderContext ctx) {
  final input = node as TimePickerNode;
  return _TimePickerWidget(input: input, ctx: ctx);
}

class _TimePickerWidget extends StatelessWidget {
  final TimePickerNode input;
  final RenderContext ctx;

  const _TimePickerWidget({required this.input, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final meta = ctx.resolveFieldMeta(input.fieldKey, input.properties);
    final label = meta.label;
    final currentValue = ctx.getFormValue(input.fieldKey) as String?;

    TimeOfDay? parsed;
    if (currentValue != null && currentValue.contains(':')) {
      final parts = currentValue.split(':');
      parsed = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }

    final displayText = parsed != null
        ? parsed.format(context)
        : 'Select time';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.onBackgroundMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: parsed ?? TimeOfDay.now(),
                builder: (ctx, child) {
                  return Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: Theme.of(ctx).colorScheme.copyWith(
                            primary: colors.accent,
                          ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                final formatted =
                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                ctx.onFormValueChanged(input.fieldKey, formatted);
              }
            },
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
                      displayText,
                      style: TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 15,
                        color: parsed != null
                            ? colors.onBackground
                            : colors.onBackgroundMuted.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.access_time_outlined,
                    size: 18,
                    color: colors.onBackgroundMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
