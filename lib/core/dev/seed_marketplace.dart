import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/module_template.dart';
import 'mock_finance_2_module.dart';
import 'mock_hiking_module.dart';

/// Seeds the global `marketplace_templates` collection with starter
/// templates. Debug-only — call from a kDebugMode button.
Future<void> seedMarketplaceTemplates() async {
  final ref = FirebaseFirestore.instance.collection('marketplace_templates');
  final templates = _buildTemplates();

  for (final template in templates) {
    await ref.doc(template.id).set(template.toFirestore());
  }
}

List<ModuleTemplate> _buildTemplates() {
  final finance = createMockFinance2Module();
  final hiking = createMockHikingModule();

  return [
    ModuleTemplate(
      id: 'tpl_finance',
      name: 'Finance',
      description: finance.description,
      longDescription:
          'A comprehensive personal finance suite with multi-account tracking, '
          'the 50/30/20 budget rule, debt management, savings goals, and '
          'inter-account transfers.',
      icon: finance.icon,
      color: finance.color,
      category: 'Finance',
      tags: ['budget', 'expenses', 'income', 'debt', 'goals', 'accounts'],
      featured: true,
      sortOrder: 0,
      installCount: 0,
      version: finance.version,
      schemas: finance.schemas,
      screens: finance.screens,
      settings: finance.settings,
      guide: finance.guide,
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
      sortOrder: 1,
      installCount: 0,
      version: hiking.version,
      schemas: hiking.schemas,
      screens: hiking.screens,
      settings: hiking.settings,
      guide: hiking.guide,
    ),
  ];
}
