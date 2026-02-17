import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/field_definition.dart';
import '../models/field_type.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/widgets/paper_background.dart';
import '../bloc/schema_bloc.dart';
import '../bloc/schema_event.dart';
import '../bloc/schema_state.dart';
import '../widgets/constraints_editor.dart';
import '../widgets/options_editor.dart';

class FieldEditorScreen extends StatelessWidget {
  const FieldEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SchemaBloc, SchemaState>(
      builder: (context, state) {
        if (state is! SchemaLoaded) {
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

        final schema = state.schemas[schemaKey];
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
                    .read<SchemaBloc>()
                    .add(const SchemaNavigateBack());
              },
            ),
            title: Text(
              field.label,
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
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
    context.read<SchemaBloc>().add(
          FieldUpdated(widget.schemaKey, widget.fieldKey, updated),
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
              labelStyle: TextStyle(
                fontFamily: 'Karla',
                color: colors.onBackgroundMuted,
              ),
            ),
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 15,
              color: colors.onBackground,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Key (read-only)
          TextFormField(
            key: const Key('field_key_input'),
            initialValue: widget.fieldKey,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Key',
              labelStyle: TextStyle(
                fontFamily: 'Karla',
                color: colors.onBackgroundMuted,
              ),
            ),
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 15,
              color: colors.onBackgroundMuted,
            ),
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
            OptionsEditor(
              key: const Key('options_editor'),
              options: _options,
              colors: colors,
              onChanged: (updated) {
                setState(() => _options = updated);
              },
            ),

          // Constraints editor
          if (_constraints.isNotEmpty || true)
            ConstraintsEditor(
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
