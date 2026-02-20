import 'package:equatable/equatable.dart';

import '../models/capability.dart';

sealed class CapabilitiesEvent extends Equatable {
  const CapabilitiesEvent();

  @override
  List<Object?> get props => [];
}

class CapabilitiesStarted extends CapabilitiesEvent {
  final String? moduleId;

  const CapabilitiesStarted({this.moduleId});

  @override
  List<Object?> get props => [moduleId];
}

class CapabilitiesUpdated extends CapabilitiesEvent {
  final List<Capability> capabilities;

  const CapabilitiesUpdated(this.capabilities);

  @override
  List<Object?> get props => [capabilities];
}

class CapabilityToggled extends CapabilitiesEvent {
  final String capabilityId;
  final bool enabled;

  const CapabilityToggled(this.capabilityId, {required this.enabled});

  @override
  List<Object?> get props => [capabilityId, enabled];
}

class CapabilityCreated extends CapabilitiesEvent {
  final Capability capability;

  const CapabilityCreated(this.capability);

  @override
  List<Object?> get props => [capability];
}

class CapabilityEdited extends CapabilitiesEvent {
  final Capability capability;

  const CapabilityEdited(this.capability);

  @override
  List<Object?> get props => [capability];
}

class CapabilityDeleted extends CapabilitiesEvent {
  final String capabilityId;

  const CapabilityDeleted(this.capabilityId);

  @override
  List<Object?> get props => [capabilityId];
}
