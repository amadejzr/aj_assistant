import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/logging/log.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

const _tag = 'Auth';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final UserService _userService;
  StreamSubscription<User?>? _authSub;

  AuthBloc({
    required AuthService authService,
    required UserService userService,
  })  : _authService = authService,
        _userService = userService,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthLoginWithEmail>(_onLoginWithEmail);
    on<AuthSignUpWithEmail>(_onSignUpWithEmail);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  void startListening() {
    Log.d('listening to auth state changes', tag: _tag);
    _authSub = _authService.authStateChanges.listen((user) {
      add(AuthUserChanged(user));
    });
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authService.currentUser;
    if (user == null) {
      emit(const AuthUnauthenticated());
    } else {
      await _resolveUser(user, emit);
    }
  }

  Future<void> _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    if (user == null) {
      emit(const AuthUnauthenticated());
    } else {
      await _resolveUser(user, emit);
    }
  }

  Future<void> _onLoginWithEmail(
    AuthLoginWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    Log.i('login attempt for ${event.email}', tag: _tag);
    emit(const AuthLoading());
    try {
      await _authService.signInWithEmail(event.email, event.password);
      Log.i('login successful', tag: _tag);
    } on FirebaseAuthException catch (e) {
      Log.w('login failed: ${e.code}', tag: _tag, error: e);
      emit(AuthError(_mapFirebaseError(e.code)));
    }
  }

  Future<void> _onSignUpWithEmail(
    AuthSignUpWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    Log.i('signup attempt for ${event.email}', tag: _tag);
    emit(const AuthLoading());
    try {
      final credential = await _authService.signUpWithEmail(
        event.email,
        event.password,
      );
      final user = credential.user!;

      if (event.displayName != null) {
        await user.updateDisplayName(event.displayName);
      }

      final appUser = AppUser(
        uid: user.uid,
        email: user.email!,
        displayName: event.displayName,
      );
      await _userService.createUser(appUser);
      Log.i('signup successful for ${user.uid}', tag: _tag);
    } on FirebaseAuthException catch (e) {
      Log.w('signup failed: ${e.code}', tag: _tag, error: e);
      emit(AuthError(_mapFirebaseError(e.code)));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    Log.i('logout requested', tag: _tag);
    await _authService.signOut();
  }

  Future<void> _resolveUser(User user, Emitter<AuthState> emit) async {
    try {
      var appUser = await _userService.getUser(user.uid);
      if (appUser == null) {
        Log.d('no Firestore profile for ${user.uid}, creating', tag: _tag);
        appUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );
        await _userService.createUser(appUser);
      }
      Log.i('authenticated: ${appUser.uid}', tag: _tag);
      emit(AuthAuthenticated(appUser));
    } catch (e, st) {
      Log.e('failed to resolve user profile', tag: _tag, error: e, stackTrace: st);
      emit(const AuthError('Unable to connect. Please try again.'));
    }
  }

  String _mapFirebaseError(String code) {
    return switch (code) {
      'user-not-found' => 'No account found with this email.',
      'wrong-password' => 'Incorrect password.',
      'email-already-in-use' => 'An account already exists with this email.',
      'weak-password' => 'Password must be at least 6 characters.',
      'invalid-email' => 'Please enter a valid email address.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      _ => 'Something went wrong. Please try again.',
    };
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
