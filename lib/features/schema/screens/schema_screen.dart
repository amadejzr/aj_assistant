import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/module_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/schema_bloc.dart';
import '../bloc/schema_event.dart';
import '../bloc/schema_state.dart';
import 'schema_navigator.dart';

/// Standalone page for the schema/settings editor.
/// Pushed as a GoRouter route — back button pops the route.
class SchemaScreen extends StatelessWidget {
  final String moduleId;

  const SchemaScreen({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.uid : '';

    return BlocProvider(
      create: (context) => SchemaBloc(
        moduleRepository: context.read<ModuleRepository>(),
        userId: userId,
        moduleId: moduleId,
      )..add(SchemaStarted(moduleId)),
      child: _SchemaScreenBody(moduleId: moduleId),
    );
  }
}

class _SchemaScreenBody extends StatelessWidget {
  final String moduleId;

  const _SchemaScreenBody({required this.moduleId});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final bloc = context.read<SchemaBloc>();
        final state = bloc.state;
        if (state is SchemaLoaded && state.screenStack.isNotEmpty) {
          bloc.add(const SchemaNavigateBack());
        } else {
          Navigator.of(context).pop();
        }
      },
      child: SchemaNavigator(
        onExit: () => Navigator.of(context).pop(),
      ),
    );
  }
}
