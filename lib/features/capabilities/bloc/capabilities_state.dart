import 'package:equatable/equatable.dart';

import '../models/capability.dart';

sealed class CapabilitiesState extends Equatable {
  const CapabilitiesState();

  @override
  List<Object?> get props => [];
}

class CapabilitiesInitial extends CapabilitiesState {
  const CapabilitiesInitial();
}

class CapabilitiesLoading extends CapabilitiesState {
  const CapabilitiesLoading();
}

class CapabilitiesLoaded extends CapabilitiesState {
  final List<Capability> capabilities;
  final String? moduleId;

  const CapabilitiesLoaded({
    required this.capabilities,
    this.moduleId,
  });

  @override
  List<Object?> get props => [capabilities, moduleId];
}

class CapabilitiesError extends CapabilitiesState {
  final String message;

  const CapabilitiesError(this.message);

  @override
  List<Object?> get props => [message];
}
