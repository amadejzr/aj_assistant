import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/widgets/paper_background.dart';
import '../../module_viewer/bloc/module_viewer_bloc.dart';
import '../../module_viewer/bloc/module_viewer_event.dart';
import '../../module_viewer/bloc/module_viewer_state.dart';
import '../widgets/add_schema_sheet.dart';
import '../widgets/schema_card.dart';

class SchemaListScreen extends StatelessWidget {
  const SchemaListScreen({super.key});

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
                            return SchemaCard(
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
        onPressed: () {
          final bloc = context.read<ModuleViewerBloc>();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddSchemaSheet(bloc: bloc),
          );
        },
      ),
    );
  }
}
