import 'package:flutter/material.dart';

import '../models/field_definition.dart';
import '../models/field_type.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/schema_bloc.dart';
import '../bloc/schema_event.dart';

class AddFieldSheet extends StatefulWidget {
  final String schemaKey;
  final SchemaBloc bloc;

  const AddFieldSheet({
    super.key,
    required this.schemaKey,
    required this.bloc,
  });

  @override
  State<AddFieldSheet> createState() => _AddFieldSheetState();
}

class _AddFieldSheetState extends State<AddFieldSheet> {
  final _keyController = TextEditingController();
  final _labelController = TextEditingController();
  final _refSchemaKeyController = TextEditingController();
  FieldType _selectedType = FieldType.text;
  bool _isRequired = false;
  final List<String> _options = [];
  final _optionController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    _labelController.dispose();
    _refSchemaKeyController.dispose();
    _optionController.dispose();
    super.dispose();
  }

  bool get _isEnumType =>
      _selectedType == FieldType.enumType ||
      _selectedType == FieldType.multiEnum;

  bool get _isReference => _selectedType == FieldType.reference;

  void _submit() {
    final fieldKey = _keyController.text.trim();
    final label = _labelController.text.trim();
    if (fieldKey.isEmpty) return;

    Map<String, dynamic> constraints = {};
    if (_isReference) {
      final refKey = _refSchemaKeyController.text.trim();
      if (refKey.isNotEmpty) {
        constraints = {'schemaKey': refKey};
      }
    }

    widget.bloc.add(
      FieldAdded(
        widget.schemaKey,
        fieldKey,
        FieldDefinition(
          key: fieldKey,
          type: _selectedType,
          label: label.isNotEmpty ? label : fieldKey,
          required: _isRequired,
          options: List.of(_options),
          constraints: constraints,
        ),
      ),
    );

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
              'Add Field',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colors.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Field key
            Text(
              'KEY',
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
              key: const Key('field_key_input'),
              controller: _keyController,
              style: TextStyle(color: colors.onBackground),
              decoration: InputDecoration(
                hintText: 'e.g. amount',
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
            // Field label
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
              key: const Key('field_label_input'),
              controller: _labelController,
              style: TextStyle(color: colors.onBackground),
              decoration: InputDecoration(
                hintText: 'e.g. Amount',
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
            // Type selector (chip grid)
            Text(
              'TYPE',
              style: TextStyle(
                fontFamily: 'Karla',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
                color: colors.onBackgroundMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FieldType.values.map((type) {
                final selected = type == _selectedType;
                return ChoiceChip(
                  key: Key('type_chip_${type.name}'),
                  label: Text(type.name),
                  selected: selected,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : colors.onBackground,
                    fontSize: 13,
                  ),
                  selectedColor: colors.accent,
                  backgroundColor: colors.surfaceVariant,
                  side: BorderSide(
                    color: selected ? colors.accent : colors.border,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedType = type);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            // Required toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Required',
                  style: TextStyle(
                    color: colors.onBackground,
                    fontSize: 15,
                  ),
                ),
                Switch(
                  key: const Key('field_required_toggle'),
                  value: _isRequired,
                  activeTrackColor: colors.accentMuted,
                  activeThumbColor: colors.accent,
                  onChanged: (value) {
                    setState(() => _isRequired = value);
                  },
                ),
              ],
            ),
            // Enum options section
            if (_isEnumType) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'OPTIONS',
                style: TextStyle(
                  fontFamily: 'Karla',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                  color: colors.onBackgroundMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ..._options.asMap().entries.map((entry) {
                    return Chip(
                      key: Key('option_chip_${entry.key}'),
                      label: Text(
                        entry.value,
                        style: TextStyle(
                          color: colors.onBackground,
                          fontSize: 13,
                        ),
                      ),
                      backgroundColor: colors.surfaceVariant,
                      deleteIcon: Icon(
                        Icons.close,
                        size: 14,
                        color: colors.error,
                      ),
                      onDeleted: () {
                        setState(() => _options.removeAt(entry.key));
                      },
                    );
                  }),
                  // Inline add option input
                  SizedBox(
                    width: 120,
                    height: 32,
                    child: TextField(
                      key: const Key('add_option_input'),
                      controller: _optionController,
                      style: TextStyle(
                        color: colors.onBackground,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: '+ Add option',
                        hintStyle: TextStyle(
                          color: colors.accent,
                          fontSize: 13,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        filled: true,
                        fillColor: colors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: colors.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: colors.accent.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      onSubmitted: (value) {
                        final trimmed = value.trim();
                        if (trimmed.isNotEmpty) {
                          setState(() => _options.add(trimmed));
                          _optionController.clear();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
            // Reference schema key section
            if (_isReference) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'REFERENCE SCHEMA KEY',
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
                key: const Key('ref_schema_key_input'),
                controller: _refSchemaKeyController,
                style: TextStyle(color: colors.onBackground),
                decoration: InputDecoration(
                  hintText: 'e.g. category',
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
            ],
            const SizedBox(height: AppSpacing.lg),
            // Add button
            ElevatedButton(
              key: const Key('submit_field_button'),
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
    );
  }
}
