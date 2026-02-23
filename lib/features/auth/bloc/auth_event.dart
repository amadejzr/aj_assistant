import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginWithEmail extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginWithEmail({required this.email, required this.password});

  @override
  List<Object?> get props => [email];
}

class AuthSignUpWithEmail extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;

  const AuthSignUpWithEmail({
    required this.email,
    required this.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, displayName];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthUserChanged extends AuthEvent {
  final User? user;

  const AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}
