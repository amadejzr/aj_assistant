import '../models/module.dart';
import 'prompts/core_rules.dart';
import 'prompts/data_handling.dart';

/// Builds the system prompt sent with every Claude API call.
///
/// Intentionally lean — only includes identity, rules, data handling,
/// and the user's module context. The blueprint reference lives in the
/// createModule tool description (see [tool_definitions.dart]).
String buildSystemPrompt(List<Module> modules) {
  final now = DateTime.now();
  final dateStr = '${now.year}-${_pad(now.month)}-${_pad(now.day)}';
  final timeStr = '${_pad(now.hour)}:${_pad(now.minute)}';

  final sections = <String>[
    coreRules,
    'Current date and time: $dateStr $timeStr.',
    dataHandling,
    _buildModuleContext(modules),
  ];

  return sections.join('\n\n');
}

String _buildModuleContext(List<Module> modules) {
  if (modules.isEmpty) {
    return 'USER\'S MODULES:\nThe user has no modules yet. If they want to track '
        'something, use createModule to build one for them.';
  }

  final moduleLines = modules.map(_formatModule).join('\n\n');
  return 'USER\'S MODULES:\n$moduleLines';
}

String _formatModule(Module module) {
  final lines = <String>[];
  lines.add('Module "${module.name}" (id: ${module.id})');

  if (module.description.isNotEmpty) {
    lines.add('  Description: ${module.description}');
  }

  final db = module.database;
  if (db != null) {
    for (final entry in db.tableNames.entries) {
      lines.add('  Schema key "${entry.key}" → table "${entry.value}"');
    }
    for (final sql in db.setup) {
      if (sql.toUpperCase().startsWith('CREATE TABLE')) {
        lines.add('  $sql');
      }
    }
  }

  if (module.settings.isNotEmpty) {
    lines.add('  Settings: ${module.settings}');
  }

  return lines.join('\n');
}

String _pad(int n) => n.toString().padLeft(2, '0');
