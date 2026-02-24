import '../database/field_type.dart';

/// Validates createModule tool input before the builder runs.
///
/// Catches structural errors (missing fields, invalid types, broken
/// references) early so the user gets clear feedback instead of a
/// cryptic runtime failure.
class ModuleValidator {
  ModuleValidator._();

  // ---------------------------------------------------------------------------
  // Known constants
  // ---------------------------------------------------------------------------

  static final _validColumnTypes = FieldType.values.map((e) => e.name).toSet();

  static const _validScreenTypes = {'screen', 'form_screen', 'tab_screen'};

  static const _inputWidgetTypes = {
    'text_input',
    'number_input',
    'currency_input',
    'date_picker',
    'time_picker',
    'enum_selector',
    'multi_enum_selector',
    'toggle',
    'slider',
    'rating_input',
    'reference_picker',
    'schedule_notification',
  };

  static const _sourceWidgetTypes = {
    'entry_list',
    'stat_card',
    'chart',
    'card_grid',
    'date_calendar',
  };

  static const _knownWidgetTypes = {
    // root
    'screen', 'form_screen', 'tab_screen',
    // layout
    'scroll_column', 'section', 'column', 'row', 'expandable', 'conditional',
    'divider',
    // input
    'text_input', 'number_input', 'currency_input', 'date_picker',
    'time_picker', 'enum_selector', 'multi_enum_selector', 'toggle', 'slider',
    'rating_input', 'reference_picker', 'schedule_notification',
    // display
    'stat_card', 'entry_list', 'entry_card', 'text_display', 'empty_state',
    'chart', 'progress_bar', 'date_calendar', 'card_grid', 'badge',
    // action
    'button', 'fab', 'icon_button', 'action_menu',
  };

  static const _navigateActionTypes = {'navigate', 'show_form_sheet'};

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Validates createModule input. Returns null if valid,
  /// or a list of error messages if invalid.
  static List<String>? validate(Map<String, dynamic> input) {
    final errors = <String>[];

    final tables = _validateStructure(input, errors);
    if (tables != null) {
      _validateColumns(tables, errors);
      _validateScreens(input, tables, errors);
    }

    return errors.isEmpty ? null : errors;
  }

  // ---------------------------------------------------------------------------
  // Structure checks (1-2)
  // ---------------------------------------------------------------------------

  /// Returns the tables map if structurally valid, null otherwise.
  static Map<String, dynamic>? _validateStructure(
    Map<String, dynamic> input,
    List<String> errors,
  ) {
    // 1. name
    final name = input['name'];
    if (name is! String || name.trim().isEmpty) {
      errors.add('Module name is required.');
    }

    // 2. tables
    final tables = input['tables'];
    if (tables is! Map || tables.isEmpty) {
      errors.add('At least one table is required.');
      return null;
    }

    return Map<String, dynamic>.from(tables);
  }

  // ---------------------------------------------------------------------------
  // Column checks (3)
  // ---------------------------------------------------------------------------

  static void _validateColumns(
    Map<String, dynamic> tables,
    List<String> errors,
  ) {
    for (final tableEntry in tables.entries) {
      final tableDef = tableEntry.value;
      if (tableDef is! Map) continue;
      final columns = tableDef['columns'];
      if (columns is! List) continue;

      for (final col in columns) {
        if (col is! Map) continue;
        final colName = col['name'] as String? ?? '';
        final colType = col['type'] as String? ?? '';
        if (!_validColumnTypes.contains(colType)) {
          errors.add(
            "Column '$colName' has invalid type '$colType'. "
            'Must be one of: ${_validColumnTypes.join(', ')}.',
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Screen checks (4-14)
  // ---------------------------------------------------------------------------

  static void _validateScreens(
    Map<String, dynamic> input,
    Map<String, dynamic> tables,
    List<String> errors,
  ) {
    final screens = input['screens'];
    if (screens is! Map || screens.isEmpty) {
      errors.add("Missing required 'main' screen.");
      return;
    }

    final screenMap = Map<String, dynamic>.from(screens);

    // 4. main screen
    if (!screenMap.containsKey('main')) {
      errors.add("Missing required 'main' screen.");
    }

    // Collect all column names across all tables.
    final allColumnNames = _collectAllColumnNames(tables);

    // Collect table keys for reference.
    final tableKeys = tables.keys.toSet();

    for (final entry in screenMap.entries) {
      final screenKey = entry.key;
      final screenDef = entry.value;
      if (screenDef is! Map) continue;

      final screenData = Map<String, dynamic>.from(screenDef);
      final screenType = screenData['type'] as String? ?? '';

      // 5. valid screen type
      if (!_validScreenTypes.contains(screenType)) {
        errors.add("Screen '$screenKey' has invalid type '$screenType'.");
      }

      // 6. form_screen table reference
      if (screenType == 'form_screen') {
        final table = screenData['table'] as String?;
        if (table != null && !tableKeys.contains(table)) {
          errors.add(
            "form_screen '$screenKey' references table '$table' "
            'which does not exist.',
          );
        }
      }

      // Collect widgets from this screen.
      final widgets = _collectWidgets(screenData);

      // Collect query names for this screen.
      final queryNames = _collectQueryNames(screenData);

      for (final widget in widgets) {
        final widgetType = widget['type'] as String? ?? '';

        // 13. unknown widget type
        if (widgetType.isNotEmpty && !_knownWidgetTypes.contains(widgetType)) {
          errors.add(
            "Unknown widget type '$widgetType' on screen '$screenKey'.",
          );
        }

        // 7. fieldKey for input widgets
        if (_inputWidgetTypes.contains(widgetType)) {
          final fieldKey = widget['fieldKey'] as String?;
          if (fieldKey != null && !allColumnNames.contains(fieldKey)) {
            final sortedColumns = allColumnNames.toList()..sort();
            errors.add(
              "fieldKey '$fieldKey' on screen '$screenKey' not found "
              'in table columns: $sortedColumns.',
            );
          }
        }

        // 8 & 9. source widgets
        if (_sourceWidgetTypes.contains(widgetType)) {
          final source = widget['source'] as String?;

          // 8. missing source
          if (source == null) {
            // 12. stat_card special case: needs source+valueKey OR value
            if (widgetType == 'stat_card') {
              _validateStatCard(widget, screenKey, errors);
            } else {
              errors.add(
                "$widgetType on screen '$screenKey' missing 'source'.",
              );
            }
          } else {
            // 9. source matches query
            if (!queryNames.contains(source)) {
              final sortedQueries = queryNames.toList()..sort();
              errors.add(
                "$widgetType source '$source' on screen '$screenKey' "
                'has no matching query. Available: $sortedQueries.',
              );
            }

            // 12. stat_card with source still needs valueKey
            if (widgetType == 'stat_card') {
              _validateStatCard(widget, screenKey, errors);
            }
          }
        }

        // 11. enum_selector / multi_enum_selector options
        if (widgetType == 'enum_selector' ||
            widgetType == 'multi_enum_selector') {
          final options = widget['options'];
          if (options is! List || options.isEmpty) {
            final fieldKey = widget['fieldKey'] as String? ?? widgetType;
            errors.add("$widgetType '$fieldKey' missing options array.");
          }
        }
      }

      // 10. navigate/show_form_sheet action targets
      _validateActions(screenData, screenKey, screenMap.keys.toSet(), errors);

      // 14. unresolved placeholders in queries
      _validateQueryPlaceholders(screenData, screenKey, tableKeys, errors);
    }
  }

  // ---------------------------------------------------------------------------
  // stat_card validation (12)
  // ---------------------------------------------------------------------------

  static void _validateStatCard(
    Map<String, dynamic> widget,
    String screenKey,
    List<String> errors,
  ) {
    final source = widget['source'] as String?;
    final valueKey = widget['valueKey'] as String?;
    final value = widget['value'];

    final hasSourceAndValueKey = source != null && valueKey != null;
    final hasValue = value != null;

    if (!hasSourceAndValueKey && !hasValue) {
      final label = widget['label'] as String? ?? 'unlabeled';
      errors.add("stat_card '$label' needs source+valueKey or value.");
    }
  }

  // ---------------------------------------------------------------------------
  // Widget tree walking
  // ---------------------------------------------------------------------------

  static List<Map<String, dynamic>> _collectWidgets(
    Map<String, dynamic> node,
  ) {
    final result = <Map<String, dynamic>>[];
    _walkWidgetTree(node, result);
    return result;
  }

  static void _walkWidgetTree(
    Map<String, dynamic> node,
    List<Map<String, dynamic>> result,
  ) {
    result.add(node);

    // children
    final children = node['children'];
    if (children is List) {
      for (final child in children) {
        if (child is Map) {
          _walkWidgetTree(Map<String, dynamic>.from(child), result);
        }
      }
    }

    // itemLayout (entry_list)
    final itemLayout = node['itemLayout'];
    if (itemLayout is Map) {
      _walkWidgetTree(Map<String, dynamic>.from(itemLayout), result);
    }

    // fab (screen-level)
    final fab = node['fab'];
    if (fab is Map) {
      _walkWidgetTree(Map<String, dynamic>.from(fab), result);
    }

    // tabs[].content (tab_screen)
    final tabs = node['tabs'];
    if (tabs is List) {
      for (final tab in tabs) {
        if (tab is Map) {
          final content = tab['content'];
          if (content is Map) {
            _walkWidgetTree(Map<String, dynamic>.from(content), result);
          }
        }
      }
    }

    // conditional then/else
    final thenBranch = node['then'];
    if (thenBranch is List) {
      for (final child in thenBranch) {
        if (child is Map) {
          _walkWidgetTree(Map<String, dynamic>.from(child), result);
        }
      }
    }
    final elseBranch = node['else'];
    if (elseBranch is List) {
      for (final child in elseBranch) {
        if (child is Map) {
          _walkWidgetTree(Map<String, dynamic>.from(child), result);
        }
      }
    }

    // appBarActions
    final appBarActions = node['appBarActions'];
    if (appBarActions is List) {
      for (final child in appBarActions) {
        if (child is Map) {
          _walkWidgetTree(Map<String, dynamic>.from(child), result);
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Action validation (10)
  // ---------------------------------------------------------------------------

  static void _validateActions(
    Map<String, dynamic> screenDef,
    String screenKey,
    Set<String> screenNames,
    List<String> errors,
  ) {
    final widgets = _collectWidgets(screenDef);

    for (final widget in widgets) {
      // action property
      _checkActionTarget(widget['action'], screenKey, screenNames, errors);

      // onTap (entry_card)
      _checkActionTarget(widget['onTap'], screenKey, screenNames, errors);

      // swipeActions.right / swipeActions.left
      final swipeActions = widget['swipeActions'];
      if (swipeActions is Map) {
        _checkActionTarget(swipeActions['right'], screenKey, screenNames, errors);
        _checkActionTarget(swipeActions['left'], screenKey, screenNames, errors);
      }

      // action_menu items[].action
      final items = widget['items'];
      if (items is List) {
        for (final item in items) {
          if (item is Map) {
            _checkActionTarget(item['action'], screenKey, screenNames, errors);
          }
        }
      }
    }
  }

  static void _checkActionTarget(
    dynamic action,
    String screenKey,
    Set<String> screenNames,
    List<String> errors,
  ) {
    if (action is! Map) return;

    final actionType = action['type'] as String?;
    if (_navigateActionTypes.contains(actionType)) {
      final target = action['screen'] as String?;
      if (target != null && !screenNames.contains(target)) {
        errors.add(
          "Action on screen '$screenKey' navigates to '$target' "
          'but no such screen exists.',
        );
      }
    }

    // Recurse into confirm.onConfirm
    final confirm = action['confirm'];
    if (confirm is Map) {
      _checkActionTarget(confirm['onConfirm'], screenKey, screenNames, errors);
    }
  }

  // ---------------------------------------------------------------------------
  // Query placeholder validation (14)
  // ---------------------------------------------------------------------------

  static void _validateQueryPlaceholders(
    Map<String, dynamic> screenDef,
    String screenKey,
    Set<String> tableKeys,
    List<String> errors,
  ) {
    final queries = screenDef['queries'];
    if (queries is! Map) return;

    final placeholderPattern = RegExp(r'\{\{(\w+)\}\}');

    for (final queryEntry in queries.entries) {
      final queryName = queryEntry.key as String;
      final queryDef = queryEntry.value;
      if (queryDef is! Map) continue;

      final sql = queryDef['sql'] as String?;
      if (sql == null) continue;

      final matches = placeholderPattern.allMatches(sql);
      for (final match in matches) {
        final placeholder = match.group(1)!;
        if (!tableKeys.contains(placeholder)) {
          errors.add(
            "Query '$queryName' on screen '$screenKey' has unresolved "
            "placeholder '{{$placeholder}}'.",
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static Set<String> _collectAllColumnNames(Map<String, dynamic> tables) {
    final names = <String>{};
    for (final tableDef in tables.values) {
      if (tableDef is! Map) continue;
      final columns = tableDef['columns'];
      if (columns is! List) continue;
      for (final col in columns) {
        if (col is! Map) continue;
        final name = col['name'] as String?;
        if (name != null) names.add(name);
      }
    }
    return names;
  }

  static Set<String> _collectQueryNames(Map<String, dynamic> screenDef) {
    final queries = screenDef['queries'];
    if (queries is! Map) return {};
    return queries.keys.cast<String>().toSet();
  }
}
