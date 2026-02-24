import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginWithName extends AuthEvent {
  final String name;

  const AuthLoginWithName(this.name);

  @override
  List<Object?> get props => [name];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
