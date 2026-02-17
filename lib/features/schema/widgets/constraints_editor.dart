import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

class ConstraintsEditor extends StatelessWidget {
  final Map<String, dynamic> constraints;
  final dynamic colors;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const ConstraintsEditor({
    super.key,
    required this.constraints,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Constraints',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.onBackground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...constraints.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: TextStyle(color: colors.onBackground),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: colors.error),
                  onPressed: () {
                    final updated = Map.of(constraints)..remove(entry.key);
                    onChanged(updated);
                  },
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          icon: Icon(Icons.add, color: colors.accent, size: 18),
          label:
              Text('Add constraint', style: TextStyle(color: colors.accent)),
          onPressed: () => _showAddConstraintSheet(context),
        ),
      ],
    );
  }

  void _showAddConstraintSheet(BuildContext context) {
    final keyController = TextEditingController();
    final valueController = TextEditingController();
    final sheetColors = context.colors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: sheetColors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sheetColors.onBackgroundMuted
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Add Constraint',
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: sheetColors.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'KEY',
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                  color: sheetColors.onBackgroundMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: keyController,
                autofocus: true,
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 15,
                  color: sheetColors.onBackground,
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g. min',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'VALUE',
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                  color: sheetColors.onBackgroundMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: valueController,
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 15,
                  color: sheetColors.onBackground,
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g. 0',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: sheetColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  final key = keyController.text.trim();
                  final value = valueController.text.trim();
                  if (key.isNotEmpty) {
                    final updated = Map.of(constraints);
                    final numValue = num.tryParse(value);
                    updated[key] = numValue ?? value;
                    onChanged(updated);
                  }
                  Navigator.of(sheetContext).pop();
                },
                child: Text(
                  'Add',
                  style: TextStyle(
                    fontFamily: 'Karla',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
