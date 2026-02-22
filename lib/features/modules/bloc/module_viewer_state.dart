import 'package:equatable/equatable.dart';

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
  final Map<String, dynamic> formValues;
  final Map<String, dynamic> screenParams;
  final List<ScreenEntry> screenStack;
  final bool isSubmitting;
  final String? submitError;
  final String? submitSuccess;
  final ({String fieldKey, String entryId})? pendingAutoSelect;
  final Map<String, dynamic> resolvedExpressions;
  final Map<String, List<Map<String, dynamic>>> queryResults;
  final Map<String, String> queryErrors;
  final Map<String, int> paginationOffsets;

  const ModuleViewerLoaded({
    required this.module,
    this.currentScreenId = 'main',
    this.formValues = const {},
    this.screenParams = const {},
    this.screenStack = const [],
    this.isSubmitting = false,
    this.submitError,
    this.submitSuccess,
    this.pendingAutoSelect,
    this.resolvedExpressions = const {},
    this.queryResults = const {},
    this.queryErrors = const {},
    this.paginationOffsets = const {},
  });

  bool get canGoBack => screenStack.isNotEmpty;

  ModuleViewerLoaded copyWith({
    Module? module,
    String? currentScreenId,
    Map<String, dynamic>? formValues,
    Map<String, dynamic>? screenParams,
    List<ScreenEntry>? screenStack,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
    String? submitSuccess,
    bool clearSubmitSuccess = false,
    ({String fieldKey, String entryId})? pendingAutoSelect,
    bool clearPendingAutoSelect = false,
    Map<String, dynamic>? resolvedExpressions,
    Map<String, List<Map<String, dynamic>>>? queryResults,
    Map<String, String>? queryErrors,
    Map<String, int>? paginationOffsets,
  }) {
    return ModuleViewerLoaded(
      module: module ?? this.module,
      currentScreenId: currentScreenId ?? this.currentScreenId,
      formValues: formValues ?? this.formValues,
      screenParams: screenParams ?? this.screenParams,
      screenStack: screenStack ?? this.screenStack,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError
          ? null
          : (submitError ?? this.submitError),
      submitSuccess: clearSubmitSuccess
          ? null
          : (submitSuccess ?? this.submitSuccess),
      pendingAutoSelect: clearPendingAutoSelect
          ? null
          : (pendingAutoSelect ?? this.pendingAutoSelect),
      resolvedExpressions: resolvedExpressions ?? this.resolvedExpressions,
      queryResults: queryResults ?? this.queryResults,
      queryErrors: queryErrors ?? this.queryErrors,
      paginationOffsets: paginationOffsets ?? this.paginationOffsets,
    );
  }

  @override
  List<Object?> get props => [
        module,
        currentScreenId,
        formValues,
        screenParams,
        screenStack,
        isSubmitting,
        submitError,
        submitSuccess,
        pendingAutoSelect,
        resolvedExpressions,
        queryResults,
        queryErrors,
        paginationOffsets,
      ];
}

class ModuleViewerError extends ModuleViewerState {
  final String message;

  const ModuleViewerError(this.message);

  @override
  List<Object?> get props => [message];
}
