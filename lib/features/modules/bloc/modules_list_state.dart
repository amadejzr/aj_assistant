import 'package:equatable/equatable.dart';

import '../../../core/models/module.dart';

sealed class ModulesListState extends Equatable {
  const ModulesListState();

  @override
  List<Object?> get props => [];
}

class ModulesListInitial extends ModulesListState {
  const ModulesListInitial();
}

class ModulesListLoading extends ModulesListState {
  const ModulesListLoading();
}

class ModulesListLoaded extends ModulesListState {
  final List<Module> modules;

  const ModulesListLoaded(this.modules);

  @override
  List<Object?> get props => [modules];
}

class ModulesListError extends ModulesListState {
  final String message;

  const ModulesListError(this.message);

  @override
  List<Object?> get props => [message];
}
