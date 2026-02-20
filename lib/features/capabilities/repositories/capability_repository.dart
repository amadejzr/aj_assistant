import '../models/capability.dart';

abstract class CapabilityRepository {
  Stream<List<Capability>> watchCapabilities(String moduleId);
  Stream<List<Capability>> watchAllCapabilities();
  Stream<List<Capability>> watchEnabledCapabilities({int? limit});
  Future<List<Capability>> getCapabilities(String moduleId);
  Future<List<Capability>> getAllEnabledCapabilities();
  Future<Capability?> getCapability(String id);
  Future<void> createCapability(Capability capability);
  Future<void> updateCapability(Capability capability);
  Future<void> toggleCapability(String id, bool enabled);
  Future<void> deleteCapability(String id);
  Future<void> deleteAllForModule(String moduleId);
  Future<void> updateLastFiredAt(String id, DateTime firedAt);
}
