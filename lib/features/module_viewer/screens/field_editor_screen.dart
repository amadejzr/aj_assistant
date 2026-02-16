import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/field_definition.dart';
import '../../../core/models/field_type.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/widgets/paper_background.dart';
import '../bloc/module_viewer_bloc.dart';
import '../bloc/module_viewer_event.dart';
import '../bloc/module_viewer_state.dart';

class FieldEditorScreen extends StatelessWidget {
  const FieldEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModuleViewerBloc, ModuleViewerState>(
      builder: (context, state) {
        if (state is! ModuleViewerLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final schemaKey = state.screenParams['schemaKey'] as String?;
        final fieldKey = state.screenParams['fieldKey'] as String?;
        if (schemaKey == null || fieldKey == null) {
          return const Scaffold(
            body: Center(child: Text('No field selected')),
          );
        }

        final schema = state.module.schemas[schemaKey];
        final field = schema?.fields[fieldKey];
        if (field == null) {
          return const Scaffold(
            body: Center(child: Text('Field not found')),
          );
        }

        final colors = context.colors;

        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: colors.background,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colors.onBackground),
              onPressed: () {
                context
                    .read<ModuleViewerBloc>()
                    .add(const ModuleViewerNavigateBack());
              },
            ),
            title: Text(
              field.label,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: colors.onBackground,
              ),
            ),
          ),
          body: Stack(
            children: [
              PaperBackground(colors: colors),
              SafeArea(
                child: _FieldEditorForm(
                  schemaKey: schemaKey,
                  fieldKey: fieldKey,
                  field: field,
                  colors: colors,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FieldEditorForm extends StatefulWidget {
  final String schemaKey;
  final String fieldKey;
  final FieldDefinition field;
  final dynamic colors;

  const _FieldEditorForm({
    required this.schemaKey,
    required this.fieldKey,
    required this.field,
    required this.colors,
  });

  @override
  State<_FieldEditorForm> createState() => _FieldEditorFormState();
}

class _FieldEditorFormState extends State<_FieldEditorForm> {
  late TextEditingController _labelController;
  late FieldType _selectedType;
  late bool _isRequired;
  late List<String> _options;
  late Map<String, dynamic> _constraints;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.field.label);
    _selectedType = widget.field.type;
    _isRequired = widget.field.required;
    _options = List.of(widget.field.options);
    _constraints = Map.of(widget.field.constraints);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  bool get _isEnumType =>
      _selectedType == FieldType.enumType ||
      _selectedType == FieldType.multiEnum;

  void _save() {
    final updated = widget.field.copyWith(
      label: _labelController.text.trim(),
      type: _selectedType,
      required: _isRequired,
      options: _options,
      constraints: _constraints,
    );
    context.read<ModuleViewerBloc>().add(
          ModuleViewerFieldUpdated(widget.schemaKey, widget.fieldKey, updated),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label
          TextFormField(
            key: const Key('field_label_input'),
            controller: _labelController,
            decoration: InputDecoration(
              labelText: 'Label',
              labelStyle: TextStyle(color: colors.onBackgroundMuted),
            ),
            style: TextStyle(color: colors.onBackground),
          ),
          const SizedBox(height: AppSpacing.md),

          // Key (read-only)
          TextFormField(
            key: const Key('field_key_input'),
            initialValue: widget.fieldKey,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Key',
              labelStyle: TextStyle(color: colors.onBackgroundMuted),
            ),
            style: TextStyle(color: colors.onBackgroundMuted),
          ),
          const SizedBox(height: AppSpacing.md),

          // Type dropdown
          DropdownButton<FieldType>(
            value: _selectedType,
            isExpanded: true,
            dropdownColor: colors.surface,
            style: TextStyle(color: colors.onBackground),
            items: FieldType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.name),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedType = value);
              }
            },
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
                  fontSize: 16,
                ),
              ),
              Switch(
                value: _isRequired,
                activeTrackColor: colors.accentMuted,
                activeThumbColor: colors.accent,
                onChanged: (value) {
                  setState(() => _isRequired = value);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Options editor (only for enum types)
          if (_isEnumType)
            _OptionsEditor(
              key: const Key('options_editor'),
              options: _options,
              colors: colors,
              onChanged: (updated) {
                setState(() => _options = updated);
              },
            ),

          // Constraints editor
          if (_constraints.isNotEmpty || true)
            _ConstraintsEditor(
              key: const Key('constraints_editor'),
              constraints: _constraints,
              colors: colors,
              onChanged: (updated) {
                setState(() => _constraints = updated);
              },
            ),

          const SizedBox(height: AppSpacing.lg),

          // Save button
          ElevatedButton(
            key: const Key('save_field_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: colors.onBackground,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _OptionsEditor extends StatelessWidget {
  final List<String> options;
  final dynamic colors;
  final ValueChanged<List<String>> onChanged;

  const _OptionsEditor({
    super.key,
    required this.options,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.onBackground,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...options.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.value,
                    style: TextStyle(color: colors.onBackground),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: colors.error),
                  onPressed: () {
                    final updated = List.of(options)..removeAt(entry.key);
                    onChanged(updated);
                  },
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          icon: Icon(Icons.add, color: colors.accent, size: 18),
          label: Text('Add option', style: TextStyle(color: colors.accent)),
          onPressed: () => _showAddOptionSheet(context),
        ),
      ],
    );
  }

  void _showAddOptionSheet(BuildContext context) {
    final controller = TextEditingController();
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
                'Add Option',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: sheetColors.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'OPTION VALUE',
                style: GoogleFonts.karla(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                  color: sheetColors.onBackgroundMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: sheetColors.onBackground),
                decoration: InputDecoration(
                  hintText: 'e.g. Food',
                  hintStyle: TextStyle(
                    color: sheetColors.onBackgroundMuted
                        .withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: sheetColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
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
                  final value = controller.text.trim();
                  if (value.isNotEmpty) {
                    onChanged([...options, value]);
                  }
                  Navigator.of(sheetContext).pop();
                },
                child: Text(
                  'Add',
                  style: GoogleFonts.karla(
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

class _ConstraintsEditor extends StatelessWidget {
  final Map<String, dynamic> constraints;
  final dynamic colors;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const _ConstraintsEditor({
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
          style: GoogleFonts.cormorantGaramond(
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
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: sheetColors.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'KEY',
                style: GoogleFonts.karla(
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
                style: TextStyle(color: sheetColors.onBackground),
                decoration: InputDecoration(
                  hintText: 'e.g. min',
                  hintStyle: TextStyle(
                    color: sheetColors.onBackgroundMuted
                        .withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: sheetColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'VALUE',
                style: GoogleFonts.karla(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                  color: sheetColors.onBackgroundMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: valueController,
                style: TextStyle(color: sheetColors.onBackground),
                decoration: InputDecoration(
                  hintText: 'e.g. 0',
                  hintStyle: TextStyle(
                    color: sheetColors.onBackgroundMuted
                        .withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: sheetColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
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
                  style: GoogleFonts.karla(
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
