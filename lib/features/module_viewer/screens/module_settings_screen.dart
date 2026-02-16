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

class ModuleSettingsScreen extends StatelessWidget {
  const ModuleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ModuleViewerBloc, ModuleViewerState>(
      builder: (context, state) {
        if (state is! ModuleViewerLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final colors = context.colors;
        final schemas = state.module.schemas;

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
              'Settings',
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
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      _AddSchemaButton(colors: colors),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: ListView.builder(
                          itemCount: schemas.length,
                          itemBuilder: (context, index) {
                            final key = schemas.keys.elementAt(index);
                            final schema = schemas[key]!;
                            return _SchemaCard(
                              schemaKey: key,
                              schema: schema,
                              colors: colors,
                            );
                          },
                        ),
                      ),
                    ],
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

class _AddSchemaButton extends StatelessWidget {
  final dynamic colors;

  const _AddSchemaButton({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const Key('add_schema_button'),
        icon: Icon(Icons.add, color: colors.accent),
        label: Text(
          'Add Schema',
          style: TextStyle(color: colors.accent),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.border),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
        onPressed: () => _showAddSchemaSheet(context),
      ),
    );
  }

  void _showAddSchemaSheet(BuildContext context) {
    final bloc = context.read<ModuleViewerBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSchemaSheet(bloc: bloc),
    );
  }
}

class _SchemaCard extends StatelessWidget {
  final String schemaKey;
  final ModuleSchema schema;
  final dynamic colors;

  const _SchemaCard({
    required this.schemaKey,
    required this.schema,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final label = schema.label.isNotEmpty ? schema.label : schemaKey;
    final fieldCount = schema.fields.length;
    final fieldText = fieldCount == 1 ? '1 field' : '$fieldCount fields';

    return Card(
      color: colors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () {
          context.read<ModuleViewerBloc>().add(
                ModuleViewerScreenChanged(
                  '_schema_editor',
                  params: {'schemaKey': schemaKey},
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
                    Text(
                      label,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colors.onBackground,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      fieldText,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onBackgroundMuted,
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
        title: const Text('Delete Schema'),
        content: Text('Delete "$schemaKey" and all its fields?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ModuleViewerBloc>().add(
                    ModuleViewerSchemaDeleted(schemaKey),
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

// -- Add Schema bottom sheet --------------------------------------------------

class _FieldDraft {
  final TextEditingController keyController;
  final TextEditingController labelController;
  FieldType type;
  bool isRequired;
  List<String> options;
  String referenceSchemaKey;

  _FieldDraft()
      : keyController = TextEditingController(),
        labelController = TextEditingController(),
        type = FieldType.text,
        isRequired = false,
        options = [],
        referenceSchemaKey = '';

  void dispose() {
    keyController.dispose();
    labelController.dispose();
  }
}

class _AddSchemaSheet extends StatefulWidget {
  final ModuleViewerBloc bloc;

  const _AddSchemaSheet({required this.bloc});

  @override
  State<_AddSchemaSheet> createState() => _AddSchemaSheetState();
}

class _AddSchemaSheetState extends State<_AddSchemaSheet> {
  final _keyController = TextEditingController();
  final _labelController = TextEditingController();
  final List<_FieldDraft> _fields = [];

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
    setState(() => _fields.add(_FieldDraft()));
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

    widget.bloc.add(ModuleViewerSchemaAdded(
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
              style: GoogleFonts.cormorantGaramond(
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
              style: GoogleFonts.karla(
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
              style: GoogleFonts.karla(
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
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onBackground,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._fields.asMap().entries.map((entry) {
              return _FieldDraftRow(
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

class _FieldDraftRow extends StatelessWidget {
  final _FieldDraft draft;
  final int index;
  final dynamic colors;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _FieldDraftRow({
    super.key,
    required this.draft,
    required this.index,
    required this.colors,
    required this.onRemove,
    required this.onChanged,
  });

  bool get _isEnumType =>
      draft.type == FieldType.enumType || draft.type == FieldType.multiEnum;

  bool get _isReference => draft.type == FieldType.reference;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with remove button
          Row(
            children: [
              Text(
                'Field ${index + 1}',
                style: GoogleFonts.karla(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                  color: colors.onBackgroundMuted,
                ),
              ),
              const Spacer(),
              IconButton(
                key: Key('remove_field_$index'),
                icon: Icon(Icons.close, size: 18, color: colors.error),
                onPressed: onRemove,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Key + Label row
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: Key('field_draft_key_$index'),
                  controller: draft.keyController,
                  style: TextStyle(color: colors.onBackground, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Key',
                    labelStyle: GoogleFonts.karla(
                      fontSize: 12,
                      color: colors.onBackgroundMuted,
                    ),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  key: Key('field_draft_label_$index'),
                  controller: draft.labelController,
                  style: TextStyle(color: colors.onBackground, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Label',
                    labelStyle: GoogleFonts.karla(
                      fontSize: 12,
                      color: colors.onBackgroundMuted,
                    ),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Type dropdown + Required toggle
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Type',
                    labelStyle: GoogleFonts.karla(
                      fontSize: 12,
                      color: colors.onBackgroundMuted,
                    ),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<FieldType>(
                      key: Key('field_draft_type_$index'),
                      value: draft.type,
                      isExpanded: true,
                      dropdownColor: colors.surface,
                      style: TextStyle(
                          color: colors.onBackground, fontSize: 14),
                      items: FieldType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          draft.type = value;
                          onChanged();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                children: [
                  Text(
                    'Req',
                    style: GoogleFonts.karla(
                      fontSize: 11,
                      color: colors.onBackgroundMuted,
                    ),
                  ),
                  Switch(
                    key: Key('field_draft_required_$index'),
                    value: draft.isRequired,
                    activeTrackColor: colors.accentMuted,
                    activeThumbColor: colors.accent,
                    onChanged: (value) {
                      draft.isRequired = value;
                      onChanged();
                    },
                  ),
                ],
              ),
            ],
          ),
          // Enum options (inline chips)
          if (_isEnumType) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'OPTIONS',
              style: GoogleFonts.karla(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
                color: colors.onBackgroundMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...draft.options.asMap().entries.map((entry) {
                  return Chip(
                    label: Text(
                      entry.value,
                      style: TextStyle(
                        color: colors.onBackground,
                        fontSize: 13,
                      ),
                    ),
                    backgroundColor: colors.surface,
                    deleteIcon:
                        Icon(Icons.close, size: 14, color: colors.error),
                    onDeleted: () {
                      draft.options.removeAt(entry.key);
                      onChanged();
                    },
                  );
                }),
                _AddOptionChip(
                  colors: colors,
                  onAdd: (value) {
                    draft.options.add(value);
                    onChanged();
                  },
                ),
              ],
            ),
          ],
          // Reference schema key
          if (_isReference) ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: Key('field_draft_ref_$index'),
              style: TextStyle(color: colors.onBackground, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Reference Schema Key',
                labelStyle: GoogleFonts.karla(
                  fontSize: 12,
                  color: colors.onBackgroundMuted,
                ),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
              onChanged: (value) {
                draft.referenceSchemaKey = value;
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _AddOptionChip extends StatefulWidget {
  final dynamic colors;
  final ValueChanged<String> onAdd;

  const _AddOptionChip({required this.colors, required this.onAdd});

  @override
  State<_AddOptionChip> createState() => _AddOptionChipState();
}

class _AddOptionChipState extends State<_AddOptionChip> {
  bool _editing = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return SizedBox(
        width: 100,
        height: 32,
        child: TextField(
          controller: _controller,
          autofocus: true,
          style: TextStyle(color: widget.colors.onBackground, fontSize: 13),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            filled: true,
            fillColor: widget.colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (value) {
            final trimmed = value.trim();
            if (trimmed.isNotEmpty) {
              widget.onAdd(trimmed);
            }
            _controller.clear();
            setState(() => _editing = false);
          },
        ),
      );
    }

    return ActionChip(
      label: Text(
        '+ Add',
        style: TextStyle(color: widget.colors.accent, fontSize: 13),
      ),
      backgroundColor: widget.colors.surface,
      side: BorderSide(color: widget.colors.accent.withValues(alpha: 0.3)),
      onPressed: () => setState(() => _editing = true),
    );
  }
}
