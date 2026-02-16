import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/field_definition.dart';
import '../../../../core/models/module_schema.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../bloc/module_viewer_bloc.dart';
import '../../bloc/module_viewer_event.dart';
import '../../bloc/module_viewer_state.dart' show ModuleViewerLoaded, ModuleViewerState;
import '../blueprint_node.dart';
import '../render_context.dart';
import '../widgets/reference_entry_sheet.dart';

Widget buildReferencePicker(BlueprintNode node, RenderContext ctx) {
  final input = node as ReferencePickerNode;
  return _ReferencePickerWidget(input: input, ctx: ctx);
}

class _ReferencePickerWidget extends StatefulWidget {
  final ReferencePickerNode input;
  final RenderContext ctx;

  const _ReferencePickerWidget({required this.input, required this.ctx});

  @override
  State<_ReferencePickerWidget> createState() => _ReferencePickerWidgetState();
}

class _ReferencePickerWidgetState extends State<_ReferencePickerWidget> {
  ReferencePickerNode get input => widget.input;
  RenderContext get ctx => widget.ctx;

  FieldDefinition? _resolveFieldDefinition() {
    final fromDefault = ctx.getFieldDefinition(input.fieldKey);
    if (fromDefault != null) return fromDefault;

    for (final schema in ctx.module.schemas.values) {
      final field = schema.fields[input.fieldKey];
      if (field != null) return field;
    }
    return null;
  }

  String _resolveSchemaKey(FieldDefinition? field) {
    if (input.schemaKey.isNotEmpty) return input.schemaKey;
    return field?.constraints['schemaKey'] as String? ?? '';
  }

  ModuleSchema? _getTargetSchema(String schemaKey) {
    return ctx.module.schemas[schemaKey];
  }

  Future<void> _openCreateSheet(
    BuildContext context,
    String schemaKey,
    ModuleSchema targetSchema,
  ) async {
    final result = await ReferenceEntrySheet.show(
      context: context,
      schema: targetSchema,
      schemaLabel: targetSchema.label.isNotEmpty
          ? targetSchema.label
          : schemaKey,
    );
    if (result != null && context.mounted) {
      context.read<ModuleViewerBloc>().add(ModuleViewerQuickEntryCreated(
            schemaKey: schemaKey,
            data: result,
            autoSelectFieldKey: input.fieldKey,
          ));
    }
  }

  Future<void> _openEditSheet(
    BuildContext context,
    String schemaKey,
    ModuleSchema targetSchema,
    String entryId,
    Map<String, dynamic> entryData,
  ) async {
    final result = await ReferenceEntrySheet.show(
      context: context,
      schema: targetSchema,
      schemaLabel: targetSchema.label.isNotEmpty
          ? targetSchema.label
          : schemaKey,
      initialData: entryData,
    );
    if (result != null && context.mounted) {
      context.read<ModuleViewerBloc>().add(ModuleViewerQuickEntryUpdated(
            entryId: entryId,
            schemaKey: schemaKey,
            data: result,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final field = _resolveFieldDefinition();
    final label = field?.label ?? input.fieldKey;
    final schemaKey = _resolveSchemaKey(field);
    final targetSchema = _getTargetSchema(schemaKey);

    final matchingEntries = ctx.entries
        .where((e) => e.schemaKey == schemaKey)
        .toList();

    final currentValue = ctx.getFormValue(input.fieldKey) as String?;

    // Capture non-nullable reference for use inside collection-if
    final ModuleSchema? schema = targetSchema;

    return BlocListener<ModuleViewerBloc, ModuleViewerState>(
      listenWhen: (prev, curr) {
        if (curr is! ModuleViewerLoaded) return false;
        final pending = curr.pendingAutoSelect;
        return pending != null && pending.fieldKey == input.fieldKey;
      },
      listener: (context, state) {
        if (state is! ModuleViewerLoaded) return;
        final pending = state.pendingAutoSelect;
        if (pending == null || pending.fieldKey != input.fieldKey) return;

        // Auto-select the newly created entry — this dispatches
        // ModuleViewerFormValueChanged which also clears pendingAutoSelect
        ctx.onFormValueChanged(input.fieldKey, pending.entryId);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.karla(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.onBackgroundMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ...matchingEntries.map((entry) {
                  final displayText =
                      entry.data[input.displayField]?.toString() ?? entry.id;
                  final isSelected = currentValue == entry.id;

                  return GestureDetector(
                    onTap: () {
                      ctx.onFormValueChanged(input.fieldKey, entry.id);
                    },
                    onLongPress: schema != null
                        ? () => _openEditSheet(
                              context,
                              schemaKey,
                              schema,
                              entry.id,
                              Map<String, dynamic>.from(entry.data),
                            )
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.accent : colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? colors.accent : colors.border,
                        ),
                      ),
                      child: Text(
                        displayText,
                        style: GoogleFonts.karla(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : colors.onBackground,
                        ),
                      ),
                    ),
                  );
                }),
                if (schema != null)
                  GestureDetector(
                    onTap: () =>
                        _openCreateSheet(context, schemaKey, schema),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.accent),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: colors.accent),
                          const SizedBox(width: 4),
                          Text(
                            'New',
                            style: GoogleFonts.karla(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
