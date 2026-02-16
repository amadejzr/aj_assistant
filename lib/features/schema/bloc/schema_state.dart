import 'package:equatable/equatable.dart';

import '../models/module_schema.dart';

class SchemaScreenEntry extends Equatable {
  final String screen;
  final Map<String, dynamic> params;

  const SchemaScreenEntry(this.screen, {this.params = const {}});

  @override
  List<Object?> get props => [screen, params];
}

sealed class SchemaState extends Equatable {
  const SchemaState();

  @override
  List<Object?> get props => [];
}

class SchemaInitial extends SchemaState {
  const SchemaInitial();
}

class SchemaLoading extends SchemaState {
  const SchemaLoading();
}

class SchemaLoaded extends SchemaState {
  final String moduleId;
  final Map<String, ModuleSchema> schemas;
  final String currentScreen;
  final Map<String, dynamic> screenParams;
  final List<SchemaScreenEntry> screenStack;

  const SchemaLoaded({
    required this.moduleId,
    required this.schemas,
    this.currentScreen = 'list',
    this.screenParams = const {},
    this.screenStack = const [],
  });

  bool get canGoBack => screenStack.isNotEmpty;

  SchemaLoaded copyWith({
    String? moduleId,
    Map<String, ModuleSchema>? schemas,
    String? currentScreen,
    Map<String, dynamic>? screenParams,
    List<SchemaScreenEntry>? screenStack,
  }) {
    return SchemaLoaded(
      moduleId: moduleId ?? this.moduleId,
      schemas: schemas ?? this.schemas,
      currentScreen: currentScreen ?? this.currentScreen,
      screenParams: screenParams ?? this.screenParams,
      screenStack: screenStack ?? this.screenStack,
    );
  }

  @override
  List<Object?> get props => [
        moduleId,
        schemas,
        currentScreen,
        screenParams,
        screenStack,
      ];
}

class SchemaError extends SchemaState {
  final String message;

  const SchemaError(this.message);

  @override
  List<Object?> get props => [message];
}
