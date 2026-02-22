import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../renderer/blueprint_node.dart';
import '../../renderer/render_context.dart';

/// Renders a tappable date picker field that opens the platform date dialog and stores an ISO 8601 string.
///
/// Blueprint JSON:
/// ```json
/// {"type": "date_picker", "fieldKey": "date"}
/// ```
///
/// - `fieldKey` (`String`, required): Schema field key this picker is bound to. The selected date is stored as an ISO 8601 string.
Widget buildDatePicker(BlueprintNode node, RenderContext ctx) {
  final input = node as DatePickerNode;
  return _DatePickerWidget(input: input, ctx: ctx);
}

class _DatePickerWidget extends StatelessWidget {
  final DatePickerNode input;
  final RenderContext ctx;

  const _DatePickerWidget({required this.input, required this.ctx});

  DateTime _resolveMinDate() {
    final validation = input.properties['validation'] as Map<String, dynamic>?;
    final minDate = validation?['minDate'] as String?;
    if (minDate == 'today') return DateUtils.dateOnly(DateTime.now());
    return DateTime(2000);
  }

  String? _validateDate(DateTime? date) {
    final validation = input.properties['validation'] as Map<String, dynamic>?;
    if (validation == null) return null;

    final customMessage = validation['message'] as String?;
    final isRequired = validation['required'] as bool? ?? false;
    final meta = ctx.resolveFieldMeta(input.fieldKey, input.properties);

    if (isRequired && date == null) {
      return customMessage ?? '${meta.label} is required';
    }

    if (date == null) return null;

    final minDate = validation['minDate'] as String?;
    if (minDate == 'today' && date.isBefore(DateUtils.dateOnly(DateTime.now()))) {
      return customMessage ?? '${meta.label} cannot be in the past';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final meta = ctx.resolveFieldMeta(input.fieldKey, input.properties);
    final label = meta.label;
    final currentValue = ctx.getFormValue(input.fieldKey) as String?;

    DateTime? parsed;
    if (currentValue != null) {
      parsed = DateTime.tryParse(currentValue);
    }

    final displayText = parsed != null
        ? DateFormat.yMMMd().format(parsed)
        : 'Select date';

    final errorText = _validateDate(parsed);
    final minDate = _resolveMinDate();

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
              final initialDate = parsed ?? DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: initialDate.isBefore(minDate) ? minDate : initialDate,
                firstDate: minDate,
                lastDate: DateTime(2100),
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
                ctx.onFormValueChanged(
                  input.fieldKey,
                  picked.toIso8601String(),
                );
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: errorText != null ? colors.accent : colors.border,
                ),
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
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: colors.onBackgroundMuted,
                  ),
                ],
              ),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                errorText,
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 12,
                  color: colors.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
