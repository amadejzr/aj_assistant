import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/blueprint/navigation/module_navigation.dart';
import '../../features/schema/models/module_schema.dart';

class SchemasConverter
    extends TypeConverter<Map<String, ModuleSchema>, String> {
  const SchemasConverter();

  @override
  Map<String, ModuleSchema> fromSql(String fromDb) {
    final map = jsonDecode(fromDb) as Map<String, dynamic>;
    return map.map(
      (key, value) => MapEntry(
        key,
        ModuleSchema.fromJson(Map<String, dynamic>.from(value as Map)),
      ),
    );
  }

  @override
  String toSql(Map<String, ModuleSchema> value) {
    return jsonEncode(
      value.map((key, schema) => MapEntry(key, schema.toJson())),
    );
  }
}

class ScreensConverter
    extends TypeConverter<Map<String, Map<String, dynamic>>, String> {
  const ScreensConverter();

  @override
  Map<String, Map<String, dynamic>> fromSql(String fromDb) {
    final map = jsonDecode(fromDb) as Map<String, dynamic>;
    return map.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)),
    );
  }

  @override
  String toSql(Map<String, Map<String, dynamic>> value) {
    return jsonEncode(value);
  }
}

class JsonMapConverter extends TypeConverter<Map<String, dynamic>, String> {
  const JsonMapConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    return Map<String, dynamic>.from(jsonDecode(fromDb) as Map);
  }

  @override
  String toSql(Map<String, dynamic> value) => jsonEncode(value);
}

class GuideConverter extends TypeConverter<List<Map<String, String>>, String> {
  const GuideConverter();

  @override
  List<Map<String, String>> fromSql(String fromDb) {
    final list = jsonDecode(fromDb) as List;
    return list.cast<Map>().map((m) => Map<String, String>.from(m)).toList();
  }

  @override
  String toSql(List<Map<String, String>> value) => jsonEncode(value);
}

class NavigationConverter extends TypeConverter<ModuleNavigation, String> {
  const NavigationConverter();

  @override
  ModuleNavigation fromSql(String fromDb) {
    return ModuleNavigation.fromJson(
      Map<String, dynamic>.from(jsonDecode(fromDb) as Map),
    );
  }

  @override
  String toSql(ModuleNavigation value) => jsonEncode(value.toJson());
}
