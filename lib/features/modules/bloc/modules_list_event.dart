import 'package:equatable/equatable.dart';

import '../../../core/models/module.dart';

sealed class ModulesListEvent extends Equatable {
  const ModulesListEvent();

  @override
  List<Object?> get props => [];
}

class ModulesListStarted extends ModulesListEvent {
  const ModulesListStarted();
}

class ModulesListUpdated extends ModulesListEvent {
  final List<Module> modules;

  const ModulesListUpdated(this.modules);

  @override
  List<Object?> get props => [modules];
}
