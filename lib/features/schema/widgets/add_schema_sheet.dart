import 'package:flutter/material.dart';

import '../models/field_definition.dart';
import '../models/field_type.dart';
import '../models/module_schema.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/schema_bloc.dart';
import '../bloc/schema_event.dart';
import 'field_draft_row.dart';

class AddSchemaSheet extends StatefulWidget {
  final SchemaBloc bloc;

  const AddSchemaSheet({super.key, required this.bloc});

  @override
  State<AddSchemaSheet> createState() => _AddSchemaSheetState();
}

class _AddSchemaSheetState extends State<AddSchemaSheet> {
  final _keyController = TextEditingController();
  final _labelController = TextEditingController();
  final List<FieldDraft> _fields = [];

  @override
  void dispose() {
    _keyController.dispose();
    _labelController.dispose();
    for (final f in _fields) {
      f.dispose();
    }
    super.dispose();
  }

  void _addField() {
    setState(() => _fields.add(FieldDraft()));
  }

  void _removeField(int index) {
    setState(() {
      _fields[index].dispose();
      _fields.removeAt(index);
    });
  }

  void _submit() {
    final schemaKey = _keyController.text.trim();
    final label = _labelController.text.trim();
    if (schemaKey.isEmpty) return;

    final fields = <String, FieldDefinition>{};
    for (final draft in _fields) {
      final fKey = draft.keyController.text.trim();
      if (fKey.isEmpty) continue;
      final fLabel = draft.labelController.text.trim();

      Map<String, dynamic> constraints = {};
      if (draft.type == FieldType.reference &&
          draft.referenceSchemaKey.isNotEmpty) {
        constraints = {'schemaKey': draft.referenceSchemaKey};
      }

      fields[fKey] = FieldDefinition(
        key: fKey,
        type: draft.type,
        label: fLabel.isNotEmpty ? fLabel : fKey,
        required: draft.isRequired,
        options: List.of(draft.options),
        constraints: constraints,
      );
    }

    widget.bloc.add(SchemaAdded(
      schemaKey,
      ModuleSchema(label: label, fields: fields),
    ));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onBackgroundMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Title
            Text(
              'Create Schema',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colors.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Schema key
            Text(
              'SCHEMA KEY',
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
                color: colors.onBackgroundMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              key: const Key('schema_key_field'),
              controller: _keyController,
              style: TextStyle(color: colors.onBackground),
              decoration: InputDecoration(
                hintText: 'e.g. expense',
                hintStyle: TextStyle(
                  color: colors.onBackgroundMuted.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: colors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Schema label
            Text(
              'LABEL',
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
                color: colors.onBackgroundMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              key: const Key('schema_label_field'),
              controller: _labelController,
              style: TextStyle(color: colors.onBackground),
              decoration: InputDecoration(
                hintText: 'e.g. Expense',
                hintStyle: TextStyle(
                  color: colors.onBackgroundMuted.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: colors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Fields section
            Text(
              'Fields',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onBackground,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._fields.asMap().entries.map((entry) {
              return FieldDraftRow(
                key: ValueKey('field_draft_${entry.key}'),
                draft: entry.value,
                index: entry.key,
                colors: colors,
                onRemove: () => _removeField(entry.key),
                onChanged: () => setState(() {}),
              );
            }),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              key: const Key('add_field_to_schema_button'),
              icon: Icon(Icons.add, color: colors.accent, size: 18),
              label: Text(
                'Add Field',
                style: TextStyle(color: colors.accent),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.border),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
              onPressed: _addField,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Create button
            ElevatedButton(
              key: const Key('create_schema_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _submit,
              child: Text(
                'Create',
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
    );
  }
}
