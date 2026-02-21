import 'package:equatable/equatable.dart';

/// Raw SQL definition for a module's local database.
///
/// Stored on the module in Firebase. When the module is installed,
/// [SchemaManager] executes [setup] statements in order.
/// When uninstalled, it executes [teardown] in order.
class ModuleDatabase extends Equatable {
  /// Maps schema key → table name so the app knows where to query.
  final Map<String, String> tableNames;

  /// SQL statements to run on install (CREATE TABLE, INDEX, TRIGGER, etc.)
  /// Executed in order.
  final List<String> setup;

  /// SQL statements to run on uninstall (DROP TABLE, etc.)
  /// Executed in order.
  final List<String> teardown;

  const ModuleDatabase({
    this.tableNames = const {},
    this.setup = const [],
    this.teardown = const [],
  });

  factory ModuleDatabase.fromJson(Map<String, dynamic> json) {
    return ModuleDatabase(
      tableNames: Map<String, String>.from(json['tableNames'] as Map? ?? {}),
      setup: List<String>.from(json['setup'] as List? ?? []),
      teardown: List<String>.from(json['teardown'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'tableNames': tableNames,
        'setup': setup,
        'teardown': teardown,
      };

  @override
  List<Object?> get props => [tableNames, setup, teardown];
}
