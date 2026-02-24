import '../models/module_template.dart';

abstract class MarketplaceRepository {
  Future<List<ModuleTemplate>> getTemplates();
  Future<ModuleTemplate?> getTemplate(String id);
  Future<void> incrementInstallCount(String id);
}

/// Stub marketplace — returns empty results until a backend is wired up.
class StubMarketplaceRepository implements MarketplaceRepository {
  @override
  Future<List<ModuleTemplate>> getTemplates() async => const [];

  @override
  Future<ModuleTemplate?> getTemplate(String id) async => null;

  @override
  Future<void> incrementInstallCount(String id) async {}
}
