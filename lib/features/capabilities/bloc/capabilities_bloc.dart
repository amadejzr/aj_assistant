import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/capability_repository.dart';
import '../services/notification_scheduler.dart';
import 'capabilities_event.dart';
import 'capabilities_state.dart';

class CapabilitiesBloc extends Bloc<CapabilitiesEvent, CapabilitiesState> {
  final CapabilityRepository capabilityRepository;
  final NotificationScheduler notificationScheduler;

  StreamSubscription<dynamic>? _sub;
  String? _moduleId;

  CapabilitiesBloc({
    required this.capabilityRepository,
    required this.notificationScheduler,
  }) : super(const CapabilitiesInitial()) {
    on<CapabilitiesStarted>(_onStarted);
    on<CapabilitiesUpdated>(_onUpdated);
    on<CapabilityToggled>(_onToggled);
    on<CapabilityCreated>(_onCreated);
    on<CapabilityDeleted>(_onDeleted);
  }

  Future<void> _onStarted(
    CapabilitiesStarted event,
    Emitter<CapabilitiesState> emit,
  ) async {
    _moduleId = event.moduleId;
    emit(const CapabilitiesLoading());
    _sub?.cancel();
    final stream = event.moduleId != null
        ? capabilityRepository.watchCapabilities(event.moduleId!)
        : capabilityRepository.watchAllCapabilities();
    _sub = stream.listen((caps) => add(CapabilitiesUpdated(caps)));
  }

  void _onUpdated(
    CapabilitiesUpdated event,
    Emitter<CapabilitiesState> emit,
  ) {
    emit(CapabilitiesLoaded(
      capabilities: event.capabilities,
      moduleId: _moduleId,
    ));
  }

  Future<void> _onToggled(
    CapabilityToggled event,
    Emitter<CapabilitiesState> emit,
  ) async {
    await capabilityRepository.toggleCapability(
      event.capabilityId,
      event.enabled,
    );
    if (event.enabled) {
      final cap = await capabilityRepository.getCapability(event.capabilityId);
      if (cap != null) await notificationScheduler.scheduleCapability(cap);
    } else {
      await notificationScheduler.cancelCapability(event.capabilityId);
    }
  }

  Future<void> _onCreated(
    CapabilityCreated event,
    Emitter<CapabilitiesState> emit,
  ) async {
    await capabilityRepository.createCapability(event.capability);
    await notificationScheduler.scheduleCapability(event.capability);
  }

  Future<void> _onDeleted(
    CapabilityDeleted event,
    Emitter<CapabilitiesState> emit,
  ) async {
    await notificationScheduler.cancelCapability(event.capabilityId);
    await capabilityRepository.deleteCapability(event.capabilityId);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
