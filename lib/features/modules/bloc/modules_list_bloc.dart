import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/log.dart';
import '../../../core/models/module.dart';
import '../../../core/repositories/module_repository.dart';
import 'modules_list_event.dart';
import 'modules_list_state.dart';

class ModulesListBloc extends Bloc<ModulesListEvent, ModulesListState> {
  final ModuleRepository moduleRepository;
  final String userId;

  StreamSubscription<List<Module>>? _modulesSub;

  ModulesListBloc({
    required this.moduleRepository,
    required this.userId,
  }) : super(const ModulesListInitial()) {
    on<ModulesListStarted>(_onStarted);
    on<ModulesListUpdated>(_onUpdated);
  }

  void _onStarted(
    ModulesListStarted event,
    Emitter<ModulesListState> emit,
  ) {
    emit(const ModulesListLoading());

    _modulesSub?.cancel();
    _modulesSub = moduleRepository.watchModules(userId).listen(
          (modules) => add(ModulesListUpdated(modules)),
          onError: (e) {
            Log.e('Modules stream error', tag: 'ModulesList', error: e);
            add(const ModulesListUpdated([]));
          },
        );
  }

  void _onUpdated(
    ModulesListUpdated event,
    Emitter<ModulesListState> emit,
  ) {
    emit(ModulesListLoaded(event.modules));
  }

  @override
  Future<void> close() {
    _modulesSub?.cancel();
    return super.close();
  }
}
