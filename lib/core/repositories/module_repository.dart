import '../models/module.dart';

abstract class ModuleRepository {
  Stream<List<Module>> watchModules(String userId);
  Future<Module?> getModule(String userId, String moduleId);
  Future<void> createModule(String userId, Module module);
  Future<void> updateModule(String userId, Module module);
  Future<void> deleteModule(String userId, String moduleId);
}
