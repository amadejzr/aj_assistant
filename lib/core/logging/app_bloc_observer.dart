import 'package:flutter_bloc/flutter_bloc.dart';

import 'log.dart';

const _tag = 'Bloc';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    Log.d('${bloc.runtimeType} created', tag: _tag);
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    Log.d('${bloc.runtimeType} ← ${event.runtimeType}', tag: _tag);
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    Log.d(
      '${bloc.runtimeType}: '
      '${transition.currentState.runtimeType} → ${transition.nextState.runtimeType}',
      tag: _tag,
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    Log.e(
      '${bloc.runtimeType} error',
      tag: _tag,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
