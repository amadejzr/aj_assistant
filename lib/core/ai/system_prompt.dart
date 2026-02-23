import '../models/module.dart';

String buildSystemPrompt(List<Module> modules) {
  final sections = <String>[];
  final now = DateTime.now();
  final dateStr = '${now.year}-${_pad(now.month)}-${_pad(now.day)}';

  sections.add(
    'You are AJ, a personal assistant that helps users manage their data. '
    'You operate within an app where users have created modules (like '
    'expense trackers, fitness logs, habit trackers, etc.). Each module '
    'has its own data schema.\n\n'
    'Your job is to help users create, read, and update entries in their '
    'modules through natural conversation. Always be concise and helpful.\n\n'
    'Today\'s date is $dateStr.',
  );

  sections.add(
    'RULES:\n'
    '- ONLY operate on modules the user already has. If the user asks to '
    'add data that doesn\'t fit any existing module, tell them they need '
    'to create that module first. Never invent module IDs or schema keys.\n'
    '- Use the tools provided to perform data operations. Never make up data.\n'
    '- Always match field keys exactly as defined in the schema.\n'
    '- For enum fields, only use values from the options list.\n'
    '- For reference fields, use getModuleSummary or queryEntries first '
    'to find the correct entry ID.\n'
    '- For write operations (creating or updating entries), always call '
    'the tool directly. The app shows the user an approval card before '
    'anything is saved — do NOT ask for confirmation in text first.\n'
    '- For deletions, confirm with the user in text before proceeding.\n'
    '- When the user mentions an amount without specifying a module, '
    'use context to infer which module they mean.\n'
    '- When creating multiple entries at once, ALWAYS use createEntries '
    'instead of calling createEntry multiple times. Same for updates: '
    'use updateEntries to update several entries in one call.\n'
    '- Keep responses short. After creating/updating data, briefly '
    'confirm what was done.',
  );

  if (modules.isEmpty) {
    sections.add(
      'USER\'S MODULES:\nThe user has no modules yet. They need to create '
      'modules through the module builder before you can help with data.',
    );
  } else {
    final moduleLines = modules.map(_formatModule).join('\n\n');
    sections.add('USER\'S MODULES:\n$moduleLines');
  }

  return sections.join('\n\n');
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
