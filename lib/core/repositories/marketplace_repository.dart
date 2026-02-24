import '../models/module_template.dart';
import 'templates/expense_tracker_template.dart';
import 'templates/finance_template.dart';
import 'templates/hiking_template.dart';
import 'templates/savings_goals_template.dart';
import 'templates/todo_template.dart';

abstract class MarketplaceRepository {
  Future<List<ModuleTemplate>> getTemplates();
  Future<ModuleTemplate?> getTemplate(String id);
  Future<void> incrementInstallCount(String id);
}

/// Bundled marketplace — returns templates compiled into the app binary.
class BundledMarketplaceRepository implements MarketplaceRepository {
  late final List<ModuleTemplate> _templates = _buildTemplates();

  static List<ModuleTemplate> _buildTemplates() {
    final defs = {
      'finance_2': financeTemplate(),
      'savings_goals': savingsGoalsTemplate(),
      'hiking_journal': hikingTemplate(),
      'expense_tracker': expenseTrackerTemplate(),
      'todo_list': todoTemplate(),
    };

    final templates = defs.entries
        .map((e) => ModuleTemplate.fromJson(e.key, e.value))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return templates;
  }

  @override
  Future<List<ModuleTemplate>> getTemplates() async => _templates;

  @override
  Future<ModuleTemplate?> getTemplate(String id) async {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<void> incrementInstallCount(String id) async {}
}
