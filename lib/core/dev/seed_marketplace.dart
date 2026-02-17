import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/module_template.dart';
import 'mock_finance_2_module.dart';
import 'mock_finance_module.dart';
import 'mock_hiking_module.dart';
import 'mock_pushup_module.dart';

/// Seeds the global `marketplace_templates` collection with the four
/// existing mock modules. Debug-only — call from a kDebugMode button.
Future<void> seedMarketplaceTemplates() async {
  final ref = FirebaseFirestore.instance.collection('marketplace_templates');
  final templates = _buildTemplates();

  for (final template in templates) {
    await ref.doc(template.id).set(template.toFirestore());
  }
}

List<ModuleTemplate> _buildTemplates() {
  final finance2 = createMockFinance2Module();
  final finance = createMockFinanceModule();
  final pushups = createMockPushupModule();
  final hiking = createMockHikingModule();

  return [
    ModuleTemplate(
      id: 'tpl_finance_2',
      name: finance2.name,
      description: finance2.description,
      longDescription:
          'A comprehensive personal finance suite with multi-account tracking, '
          'the 50/30/20 budget rule, debt management, savings goals, and '
          'inter-account transfers. Perfect for users who want full control '
          'over their financial life in one place.',
      icon: finance2.icon,
      color: finance2.color,
      category: 'Finance',
      tags: ['budget', 'expenses', 'income', 'debt', 'goals', 'accounts'],
      featured: true,
      sortOrder: 0,
      installCount: 0,
      version: finance2.version,
      schemas: finance2.schemas,
      screens: finance2.screens,
      settings: finance2.settings,
      guide: finance2.guide,
    ),
    ModuleTemplate(
      id: 'tpl_finance',
      name: finance.name,
      description: finance.description,
      longDescription:
          'A streamlined finance tracker with accounts, expenses, and income. '
          'Uses the 50/30/20 budget framework to categorize spending into '
          'Needs, Wants, and Savings. Great for getting started with budgeting.',
      icon: finance.icon,
      color: finance.color,
      category: 'Finance',
      tags: ['budget', 'expenses', 'simple'],
      featured: false,
      sortOrder: 1,
      installCount: 0,
      version: finance.version,
      schemas: finance.schemas,
      screens: finance.screens,
      settings: finance.settings,
      guide: finance.guide,
    ),
    ModuleTemplate(
      id: 'tpl_pushups',
      name: pushups.name,
      description: pushups.description,
      longDescription:
          'Track your daily pushup sets with a simple counter and goal system. '
          'See your progress towards a daily target, track your total count, '
          'and maintain a streak of consecutive active days.',
      icon: pushups.icon,
      color: pushups.color,
      category: 'Fitness',
      tags: ['workout', 'pushups', 'tracker', 'streak'],
      featured: false,
      sortOrder: 2,
      installCount: 0,
      version: pushups.version,
      schemas: pushups.schemas,
      screens: pushups.screens,
      settings: pushups.settings,
      guide: pushups.guide,
    ),
    ModuleTemplate(
      id: 'tpl_hiking',
      name: hiking.name,
      description: hiking.description,
      longDescription:
          'Plan future hikes and log completed trails. Schedule hikes with '
          'dates, save trail ideas for later, and after each hike rate the '
          'difficulty, give it a star rating, and record your best moment. '
          'Includes a calendar view for planning.',
      icon: hiking.icon,
      color: hiking.color,
      category: 'Lifestyle',
      tags: ['outdoor', 'hiking', 'trails', 'nature'],
      featured: false,
      sortOrder: 3,
      installCount: 0,
      version: hiking.version,
      schemas: hiking.schemas,
      screens: hiking.screens,
      settings: hiking.settings,
      guide: hiking.guide,
    ),
  ];
}
