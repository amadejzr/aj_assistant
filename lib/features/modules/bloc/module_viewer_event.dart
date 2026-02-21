import 'package:equatable/equatable.dart';

sealed class ModuleViewerEvent extends Equatable {
  const ModuleViewerEvent();

  @override
  List<Object?> get props => [];
}

class ModuleViewerStarted extends ModuleViewerEvent {
  final String moduleId;

  const ModuleViewerStarted(this.moduleId);

  @override
  List<Object?> get props => [moduleId];
}

class ModuleViewerScreenChanged extends ModuleViewerEvent {
  final String screenId;
  final Map<String, dynamic> params;

  /// When true, clears the navigation stack instead of pushing onto it.
  /// Use for top-level destinations (bottom nav tabs, drawer items).
  final bool clearStack;

  const ModuleViewerScreenChanged(
    this.screenId, {
    this.params = const {},
    this.clearStack = false,
  });

  @override
  List<Object?> get props => [screenId, params, clearStack];
}

class ModuleViewerNavigateBack extends ModuleViewerEvent {
  const ModuleViewerNavigateBack();
}

class ModuleViewerFormValueChanged extends ModuleViewerEvent {
  final String fieldKey;
  final dynamic value;

  const ModuleViewerFormValueChanged(this.fieldKey, this.value);

  @override
  List<Object?> get props => [fieldKey, value];
}

class ModuleViewerFormSubmitted extends ModuleViewerEvent {
  const ModuleViewerFormSubmitted();
}

class ModuleViewerFormReset extends ModuleViewerEvent {
  const ModuleViewerFormReset();
}

class ModuleViewerEntryDeleted extends ModuleViewerEvent {
  final String entryId;

  const ModuleViewerEntryDeleted(this.entryId);

  @override
  List<Object?> get props => [entryId];
}

class ModuleViewerModuleRefreshed extends ModuleViewerEvent {
  const ModuleViewerModuleRefreshed();
}

class ModuleViewerScreenParamChanged extends ModuleViewerEvent {
  final String key;
  final dynamic value;

  const ModuleViewerScreenParamChanged(this.key, this.value);

  @override
  List<Object?> get props => [key, value];
}

class ModuleViewerQueryResultsUpdated extends ModuleViewerEvent {
  final Map<String, List<Map<String, dynamic>>> results;

  const ModuleViewerQueryResultsUpdated(this.results);

  @override
  List<Object?> get props => [results];
}

class ModuleViewerFormPrePopulated extends ModuleViewerEvent {
  final Map<String, dynamic> values;

  const ModuleViewerFormPrePopulated(this.values);

  @override
  List<Object?> get props => [values];
}

