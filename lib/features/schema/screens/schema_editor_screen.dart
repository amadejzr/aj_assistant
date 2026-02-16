import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/module_schema.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/widgets/paper_background.dart';
import '../../module_viewer/bloc/module_viewer_bloc.dart';
import '../../module_viewer/bloc/module_viewer_event.dart';
import '../../module_viewer/bloc/module_viewer_state.dart';
import '../widgets/add_field_sheet.dart';
import '../widgets/field_card.dart';

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
              return FieldCard(
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
        onPressed: () {
          final bloc = context.read<ModuleViewerBloc>();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddFieldSheet(schemaKey: schemaKey, bloc: bloc),
          );
        },
      ),
    );
  }
}
