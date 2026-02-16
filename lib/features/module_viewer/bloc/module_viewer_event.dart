import 'package:equatable/equatable.dart';

import '../../../core/models/entry.dart';

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

  const ModuleViewerScreenChanged(this.screenId, {this.params = const {}});

  @override
  List<Object?> get props => [screenId, params];
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

class ModuleViewerEntriesUpdated extends ModuleViewerEvent {
  final List<Entry> entries;

  const ModuleViewerEntriesUpdated(this.entries);

  @override
  List<Object?> get props => [entries];
}
