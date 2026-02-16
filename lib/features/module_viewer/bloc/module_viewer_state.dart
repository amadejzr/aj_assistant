import 'package:equatable/equatable.dart';

import '../../../core/models/entry.dart';
import '../../../core/models/module.dart';

sealed class ModuleViewerState extends Equatable {
  const ModuleViewerState();

  @override
  List<Object?> get props => [];
}

class ModuleViewerInitial extends ModuleViewerState {
  const ModuleViewerInitial();
}

class ModuleViewerLoading extends ModuleViewerState {
  const ModuleViewerLoading();
}

class ScreenEntry extends Equatable {
  final String screenId;
  final Map<String, dynamic> params;

  const ScreenEntry(this.screenId, {this.params = const {}});

  @override
  List<Object?> get props => [screenId, params];
}

class ModuleViewerLoaded extends ModuleViewerState {
  final Module module;
  final String currentScreenId;
  final List<Entry> entries;
  final Map<String, dynamic> formValues;
  final Map<String, dynamic> screenParams;
  final List<ScreenEntry> screenStack;
  final bool isSubmitting;
  final ({String fieldKey, String entryId})? pendingAutoSelect;

  const ModuleViewerLoaded({
    required this.module,
    this.currentScreenId = 'main',
    this.entries = const [],
    this.formValues = const {},
    this.screenParams = const {},
    this.screenStack = const [],
    this.isSubmitting = false,
    this.pendingAutoSelect,
  });

  bool get canGoBack => screenStack.isNotEmpty;

  ModuleViewerLoaded copyWith({
    Module? module,
    String? currentScreenId,
    List<Entry>? entries,
    Map<String, dynamic>? formValues,
    Map<String, dynamic>? screenParams,
    List<ScreenEntry>? screenStack,
    bool? isSubmitting,
    ({String fieldKey, String entryId})? pendingAutoSelect,
    bool clearPendingAutoSelect = false,
  }) {
    return ModuleViewerLoaded(
      module: module ?? this.module,
      currentScreenId: currentScreenId ?? this.currentScreenId,
      entries: entries ?? this.entries,
      formValues: formValues ?? this.formValues,
      screenParams: screenParams ?? this.screenParams,
      screenStack: screenStack ?? this.screenStack,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      pendingAutoSelect: clearPendingAutoSelect
          ? null
          : (pendingAutoSelect ?? this.pendingAutoSelect),
    );
  }

  @override
  List<Object?> get props => [
        module,
        currentScreenId,
        entries,
        formValues,
        screenParams,
        screenStack,
        isSubmitting,
        pendingAutoSelect,
      ];
}

class ModuleViewerError extends ModuleViewerState {
  final String message;

  const ModuleViewerError(this.message);

  @override
  List<Object?> get props => [message];
}
