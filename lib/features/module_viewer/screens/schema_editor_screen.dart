import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/field_definition.dart';
import '../../../core/models/field_type.dart';
import '../../../core/models/module_schema.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/widgets/paper_background.dart';
import '../bloc/module_viewer_bloc.dart';
import '../bloc/module_viewer_event.dart';
import '../bloc/module_viewer_state.dart';

class SchemaEditorScreen extends StatelessWidget {
  const SchemaEditorScreen({super.key});

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
        if (schemaKey == null) {
          return const Scaffold(
            body: Center(child: Text('No schema selected')),
          );
        }

        final schema = state.module.schemas[schemaKey];
        if (schema == null) {
          return const Scaffold(
            body: Center(child: Text('Schema not found')),
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
              schema.label.isNotEmpty ? schema.label : schemaKey,
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: _SchemaEditorBody(
                    schemaKey: schemaKey,
                    schema: schema,
                    colors: colors,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SchemaEditorBody extends StatelessWidget {
  final String schemaKey;
  final ModuleSchema schema;
  final dynamic colors;

  const _SchemaEditorBody({
    required this.schemaKey,
    required this.schema,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final fields = schema.fields;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        _LabelField(
          schemaKey: schemaKey,
          schema: schema,
          colors: colors,
        ),
        const SizedBox(height: AppSpacing.md),
        _AddFieldButton(
          schemaKey: schemaKey,
          colors: colors,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView.builder(
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final fieldKey = fields.keys.elementAt(index);
              final field = fields[fieldKey]!;
              return _FieldCard(
                schemaKey: schemaKey,
                fieldKey: fieldKey,
                field: field,
                colors: colors,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LabelField extends StatefulWidget {
  final String schemaKey;
  final ModuleSchema schema;
  final dynamic colors;

  const _LabelField({
    required this.schemaKey,
    required this.schema,
    required this.colors,
  });

  @override
  State<_LabelField> createState() => _LabelFieldState();
}

class _LabelFieldState extends State<_LabelField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.schema.label);
  }

  @override
  void didUpdateWidget(_LabelField old) {
    super.didUpdateWidget(old);
    if (old.schema.label != widget.schema.label) {
      _controller.text = widget.schema.label;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('schema_label_input'),
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'Schema Label',
        labelStyle: TextStyle(color: widget.colors.onBackgroundMuted),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: widget.colors.border),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: widget.colors.accent),
        ),
      ),
      style: TextStyle(color: widget.colors.onBackground),
      onSubmitted: (value) {
        context.read<ModuleViewerBloc>().add(
              ModuleViewerSchemaUpdated(
                widget.schemaKey,
                widget.schema.copyWith(label: value),
              ),
            );
      },
    );
  }
}

class _AddFieldButton extends StatelessWidget {
  final String schemaKey;
  final dynamic colors;

  const _AddFieldButton({
    required this.schemaKey,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const Key('add_field_button'),
        icon: Icon(Icons.add, color: colors.accent),
        label: Text(
          'Add Field',
          style: TextStyle(color: colors.accent),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.border),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
        onPressed: () => _showAddFieldSheet(context),
      ),
    );
  }

  void _showAddFieldSheet(BuildContext context) {
    final bloc = context.read<ModuleViewerBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFieldSheet(schemaKey: schemaKey, bloc: bloc),
    );
  }
}

class _AddFieldSheet extends StatefulWidget {
  final String schemaKey;
  final ModuleViewerBloc bloc;

  const _AddFieldSheet({required this.schemaKey, required this.bloc});

  @override
  State<_AddFieldSheet> createState() => _AddFieldSheetState();
}

class _AddFieldSheetState extends State<_AddFieldSheet> {
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
      ModuleViewerFieldAdded(
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
              style: GoogleFonts.cormorantGaramond(
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
              style: GoogleFonts.karla(
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
              style: GoogleFonts.karla(
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
              style: GoogleFonts.karla(
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
                    color: selected
                        ? colors.accent
                        : colors.border,
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
                style: GoogleFonts.karla(
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
                  // Inline add chip
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
                style: GoogleFonts.karla(
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
                style: GoogleFonts.karla(
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

class _FieldCard extends StatelessWidget {
  final String schemaKey;
  final String fieldKey;
  final FieldDefinition field;
  final dynamic colors;

  const _FieldCard({
    required this.schemaKey,
    required this.fieldKey,
    required this.field,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () {
          context.read<ModuleViewerBloc>().add(
                ModuleViewerScreenChanged(
                  '_field_editor',
                  params: {
                    'schemaKey': schemaKey,
                    'fieldKey': fieldKey,
                  },
                ),
              );
        },
        onLongPress: () => _showDeleteDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          field.label,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colors.onBackground,
                          ),
                        ),
                        if (field.required) ...[
                          const SizedBox(width: 4),
                          Text(
                            '*',
                            style: TextStyle(
                              color: colors.accent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        field.type.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onBackgroundMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.onBackgroundMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Field'),
        content: Text('Delete field "$fieldKey"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ModuleViewerBloc>().add(
                    ModuleViewerFieldDeleted(schemaKey, fieldKey),
                  );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
