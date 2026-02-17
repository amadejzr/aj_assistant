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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final field = ctx.getFieldDefinition(input.fieldKey);
    final label = field?.label ?? input.fieldKey;
    final currentValue = ctx.getFormValue(input.fieldKey) as String?;

    DateTime? parsed;
    if (currentValue != null) {
      parsed = DateTime.tryParse(currentValue);
    }

    final displayText = parsed != null
        ? DateFormat.yMMMd().format(parsed)
        : 'Select date';

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
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: parsed ?? DateTime.now(),
                firstDate: DateTime(2000),
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
              padding: const EdgeInsets.only(
                top: 12,
                bottom: 10,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.border),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayText,
                      style: TextStyle(
                        fontFamily: 'Karla',
                        fontSize: 16,
                        color: parsed != null
                            ? colors.onBackground
                            : colors.onBackgroundMuted,
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
        ],
      ),
    );
  }
}
