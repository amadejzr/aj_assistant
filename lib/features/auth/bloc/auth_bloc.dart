import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/log.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

const _tag = 'Auth';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final UserService _userService;

  AuthBloc({
    required AuthService authService,
    required UserService userService,
  })  : _authService = authService,
        _userService = userService,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginWithName>(_onLoginWithName);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final stored = await _userService.getUser();
    if (stored == null) {
      emit(const AuthUnauthenticated());
    } else {
      _authService.login(stored.displayName ?? 'User');
      Log.i('auto-login: ${stored.uid}', tag: _tag);
      emit(AuthAuthenticated(stored));
    }
  }

  Future<void> _onLoginWithName(
    AuthLoginWithName event,
    Emitter<AuthState> emit,
  ) async {
    Log.i('login with name: ${event.name}', tag: _tag);
    emit(const AuthLoading());
    try {
      final user = _authService.login(event.name);
      await _userService.createUser(user);
      Log.i('authenticated: ${user.uid}', tag: _tag);
      emit(AuthAuthenticated(user));
    } catch (e, st) {
      Log.e('login failed', tag: _tag, error: e, stackTrace: st);
      emit(const AuthError('Something went wrong. Please try again.'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    Log.i('logout requested', tag: _tag);
    _authService.signOut();
    await _userService.deleteUser();
    emit(const AuthUnauthenticated());
  }
}
