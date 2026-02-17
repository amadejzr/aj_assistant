import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/schema_bloc.dart';
import '../bloc/schema_state.dart';
import 'field_editor_screen.dart';
import 'schema_editor_screen.dart';
import 'schema_list_screen.dart';

class SchemaNavigator extends StatelessWidget {
  final VoidCallback? onExit;

  const SchemaNavigator({super.key, this.onExit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SchemaBloc, SchemaState>(
      buildWhen: (prev, curr) {
        if (prev is SchemaLoaded && curr is SchemaLoaded) {
          return prev.currentScreen != curr.currentScreen ||
              prev.screenParams != curr.screenParams;
        }
        return prev != curr;
      },
      builder: (context, state) {
        if (state is! SchemaLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return switch (state.currentScreen) {
          'list' => SchemaListScreen(onExit: onExit),
          'editor' => const SchemaEditorScreen(),
          'field_editor' => const FieldEditorScreen(),
          _ => const Scaffold(
              body: Center(child: Text('Unknown schema screen')),
            ),
        };
      },
    );
  }
}
