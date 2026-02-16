import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../schema/models/field_definition.dart';
import '../../../schema/models/field_type.dart';
import '../../../schema/models/module_schema.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

class ReferenceEntrySheet extends StatefulWidget {
  final ModuleSchema schema;
  final String schemaLabel;
  final Map<String, dynamic>? initialData;
  final void Function(Map<String, dynamic> data) onSubmit;

  const ReferenceEntrySheet({
    super.key,
    required this.schema,
    required this.schemaLabel,
    this.initialData,
    required this.onSubmit,
  });

  bool get isEdit => initialData != null;

  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required ModuleSchema schema,
    required String schemaLabel,
    Map<String, dynamic>? initialData,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, scrollController) {
          return _SheetContainer(
            scrollController: scrollController,
            schema: schema,
            schemaLabel: schemaLabel,
            initialData: initialData,
          );
        },
      ),
    );
  }

  @override
  State<ReferenceEntrySheet> createState() => _ReferenceEntrySheetState();
}

class _SheetContainer extends StatefulWidget {
  final ScrollController scrollController;
  final ModuleSchema schema;
  final String schemaLabel;
  final Map<String, dynamic>? initialData;

  const _SheetContainer({
    required this.scrollController,
    required this.schema,
    required this.schemaLabel,
    this.initialData,
  });

  @override
  State<_SheetContainer> createState() => _SheetContainerState();
}

class _SheetContainerState extends State<_SheetContainer> {
  late final Map<String, dynamic> _formData;

  @override
  void initState() {
    super.initState();
    _formData = Map<String, dynamic>.from(widget.initialData ?? {});
  }

  bool get _isEdit => widget.initialData != null;

  List<MapEntry<String, FieldDefinition>> get _editableFields {
    return widget.schema.fields.entries
        .where((e) => e.value.type != FieldType.reference)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fields = _editableFields;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onBackgroundMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              _isEdit
                  ? 'Edit ${widget.schemaLabel}'
                  : 'Create ${widget.schemaLabel}',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colors.onBackground,
              ),
            ),
          ),
          // Fields
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: fields.length,
              itemBuilder: (context, index) {
                final entry = fields[index];
                return _buildField(context, entry.key, entry.value);
              },
            ),
          ),
          // Submit button
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_formData),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _isEdit ? 'Save' : 'Create',
                  style: GoogleFonts.karla(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    BuildContext context,
    String fieldKey,
    FieldDefinition field,
  ) {
    final colors = context.colors;
    final labelStyle = GoogleFonts.karla(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: colors.onBackgroundMuted,
      letterSpacing: 0.8,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label, style: labelStyle),
          const SizedBox(height: AppSpacing.xs),
          _buildInput(context, fieldKey, field),
        ],
      ),
    );
  }

  Widget _buildInput(
    BuildContext context,
    String fieldKey,
    FieldDefinition field,
  ) {
    switch (field.type) {
      case FieldType.boolean:
        return _buildSwitch(fieldKey);
      case FieldType.enumType:
        return _buildChipSelector(context, fieldKey, field);
      case FieldType.datetime:
        return _buildDatePicker(context, fieldKey);
      case FieldType.number:
      case FieldType.currency:
        return _buildTextInput(
          fieldKey,
          keyboardType: TextInputType.number,
        );
      default:
        return _buildTextInput(fieldKey);
    }
  }

  Widget _buildTextInput(
    String fieldKey, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    final colors = context.colors;
    return TextFormField(
      initialValue: _formData[fieldKey]?.toString() ?? '',
      keyboardType: keyboardType,
      style: GoogleFonts.karla(
        fontSize: 15,
        color: colors.onBackground,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      onChanged: (value) {
        if (keyboardType == TextInputType.number) {
          _formData[fieldKey] = num.tryParse(value) ?? value;
        } else {
          _formData[fieldKey] = value;
        }
      },
    );
  }

  Widget _buildSwitch(String fieldKey) {
    final colors = context.colors;
    return Switch(
      value: _formData[fieldKey] as bool? ?? false,
      activeThumbColor: colors.accent,
      onChanged: (value) => setState(() => _formData[fieldKey] = value),
    );
  }

  Widget _buildChipSelector(
    BuildContext context,
    String fieldKey,
    FieldDefinition field,
  ) {
    final colors = context.colors;
    final currentValue = _formData[fieldKey] as String?;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: field.options.map((option) {
        final isSelected = currentValue == option;
        return GestureDetector(
          onTap: () => setState(() => _formData[fieldKey] = option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? colors.accent : colors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? colors.accent : colors.border,
              ),
            ),
            child: Text(
              option,
              style: GoogleFonts.karla(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : colors.onBackground,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker(BuildContext context, String fieldKey) {
    final colors = context.colors;
    final currentDate = _formData[fieldKey] as String?;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() {
            _formData[fieldKey] = picked.toIso8601String();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: colors.onBackgroundMuted),
            const SizedBox(width: 8),
            Text(
              currentDate ?? 'Select date',
              style: GoogleFonts.karla(
                fontSize: 15,
                color: currentDate != null
                    ? colors.onBackground
                    : colors.onBackgroundMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceEntrySheetState extends State<ReferenceEntrySheet> {
  @override
  Widget build(BuildContext context) {
    // This state class exists for direct embedding (non-modal usage).
    // For modal usage, prefer ReferenceEntrySheet.show().
    return _SheetContainer(
      scrollController: ScrollController(),
      schema: widget.schema,
      schemaLabel: widget.schemaLabel,
      initialData: widget.initialData,
    );
  }
}
