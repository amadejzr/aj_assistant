# Type-Safe Schema Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace untyped `Map<String, dynamic>` constraints and effects with a sealed class hierarchy that gives compile-time type safety to the entire schema system.

**Architecture:** Each `FieldType` gets its own `FieldConstraints` subclass (sealed). Effects get a `SchemaEffect` sealed hierarchy matching the existing `adjust_reference`/`set_reference` JSON format. JSON serialization is backward compatible — existing Firestore documents deserialize cleanly. The `options` field moves from `FieldDefinition` into `EnumConstraints` but stays at the field level in JSON for backward compat.

**Tech Stack:** Dart sealed classes, Equatable, existing Firestore JSON format.

**Design doc:** `docs/plans/2026-02-19-typesafe-schema-design.md`

---

### Task 1: Create FieldConstraints sealed hierarchy

**Files:**
- Create: `lib/features/schema/models/field_constraints.dart`

**Step 1: Create the file with the sealed class and all subclasses**

```dart
import 'package:equatable/equatable.dart';

import 'field_type.dart';

/// Type-safe constraints for each [FieldType].
///
/// Instead of `Map<String, dynamic>`, every field type maps to a specific
/// subclass with typed fields. Use [FieldConstraints.fromJson] to
/// deserialize — it uses [FieldType] as the discriminator.
sealed class FieldConstraints extends Equatable {
  const FieldConstraints();

  Map<String, dynamic> toJson();

  /// Deserializes constraints using [type] as discriminator.
  ///
  /// The [json] map is the `constraints` value from the FieldDefinition JSON.
  /// For enum types, pass `options` merged in under the `'options'` key.
  static FieldConstraints fromJson(FieldType type, Map<String, dynamic> json) {
    return switch (type) {
      FieldType.text => TextConstraints.fromJson(json),
      FieldType.number => NumberConstraints.fromJson(json),
      FieldType.currency => CurrencyConstraints.fromJson(json),
      FieldType.datetime => DateTimeConstraints.fromJson(json),
      FieldType.enumType || FieldType.multiEnum => EnumConstraints.fromJson(json),
      FieldType.rating => RatingConstraints.fromJson(json),
      FieldType.duration => DurationConstraints.fromJson(json),
      FieldType.reference => ReferenceConstraints.fromJson(json),
      _ => const EmptyConstraints(),
    };
  }
}

// ── Text ──

class TextConstraints extends FieldConstraints {
  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final bool multiline;

  const TextConstraints({
    this.minLength,
    this.maxLength,
    this.pattern,
    this.multiline = false,
  });

  factory TextConstraints.fromJson(Map<String, dynamic> json) {
    return TextConstraints(
      minLength: json['minLength'] as int?,
      maxLength: json['maxLength'] as int?,
      pattern: json['pattern'] as String?,
      multiline: json['multiline'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (minLength != null) 'minLength': minLength,
        if (maxLength != null) 'maxLength': maxLength,
        if (pattern != null) 'pattern': pattern,
        if (multiline) 'multiline': multiline,
      };

  @override
  List<Object?> get props => [minLength, maxLength, pattern, multiline];
}

// ── Number ──

class NumberConstraints extends FieldConstraints {
  final num? min;
  final num? max;
  final num? step;
  final int? divisions;

  const NumberConstraints({this.min, this.max, this.step, this.divisions});

  factory NumberConstraints.fromJson(Map<String, dynamic> json) {
    return NumberConstraints(
      min: json['min'] as num?,
      max: json['max'] as num?,
      step: json['step'] as num?,
      divisions: json['divisions'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (min != null) 'min': min,
        if (max != null) 'max': max,
        if (step != null) 'step': step,
        if (divisions != null) 'divisions': divisions,
      };

  @override
  List<Object?> get props => [min, max, step, divisions];
}

// ── Currency ──

class CurrencyConstraints extends FieldConstraints {
  final String? defaultCurrency;
  final num? min;
  final num? max;

  const CurrencyConstraints({this.defaultCurrency, this.min, this.max});

  factory CurrencyConstraints.fromJson(Map<String, dynamic> json) {
    return CurrencyConstraints(
      defaultCurrency: json['defaultCurrency'] as String?,
      min: json['min'] as num?,
      max: json['max'] as num?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (defaultCurrency != null) 'defaultCurrency': defaultCurrency,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
      };

  @override
  List<Object?> get props => [defaultCurrency, min, max];
}

// ── DateTime ──

class DateTimeConstraints extends FieldConstraints {
  final bool dateOnly;
  final bool allowPast;
  final bool allowFuture;

  const DateTimeConstraints({
    this.dateOnly = false,
    this.allowPast = true,
    this.allowFuture = true,
  });

  factory DateTimeConstraints.fromJson(Map<String, dynamic> json) {
    return DateTimeConstraints(
      dateOnly: json['dateOnly'] as bool? ?? false,
      allowPast: json['allowPast'] as bool? ?? true,
      allowFuture: json['allowFuture'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (dateOnly) 'dateOnly': dateOnly,
        if (!allowPast) 'allowPast': allowPast,
        if (!allowFuture) 'allowFuture': allowFuture,
      };

  @override
  List<Object?> get props => [dateOnly, allowPast, allowFuture];
}

// ── Enum / MultiEnum ──

class EnumConstraints extends FieldConstraints {
  final List<String> options;

  const EnumConstraints({this.options = const []});

  factory EnumConstraints.fromJson(Map<String, dynamic> json) {
    return EnumConstraints(
      options: List<String>.from(json['options'] as List? ?? []),
    );
  }

  @override
  Map<String, dynamic> toJson() => {};

  @override
  List<Object?> get props => [options];
}

// ── Rating ──

class RatingConstraints extends FieldConstraints {
  final int maxRating;
  final bool allowHalf;

  const RatingConstraints({this.maxRating = 5, this.allowHalf = false});

  factory RatingConstraints.fromJson(Map<String, dynamic> json) {
    return RatingConstraints(
      maxRating: (json['max'] as num?)?.toInt() ?? 5,
      allowHalf: json['allowHalf'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        if (maxRating != 5) 'max': maxRating,
        if (allowHalf) 'allowHalf': allowHalf,
      };

  @override
  List<Object?> get props => [maxRating, allowHalf];
}

// ── Duration ──

enum DurationUnit { seconds, minutes, hours }

class DurationConstraints extends FieldConstraints {
  final DurationUnit unit;

  const DurationConstraints({this.unit = DurationUnit.minutes});

  factory DurationConstraints.fromJson(Map<String, dynamic> json) {
    final unitStr = json['unit'] as String?;
    final unit = DurationUnit.values.firstWhere(
      (e) => e.name == unitStr,
      orElse: () => DurationUnit.minutes,
    );
    return DurationConstraints(unit: unit);
  }

  @override
  Map<String, dynamic> toJson() => {
        if (unit != DurationUnit.minutes) 'unit': unit.name,
      };

  @override
  List<Object?> get props => [unit];
}

// ── Reference ──

enum OnDeleteAction { cascade, setNull, restrict }

class ReferenceConstraints extends FieldConstraints {
  final String targetSchema;
  final String? displayField;
  final OnDeleteAction onDelete;
  final String? inverseLabel;

  const ReferenceConstraints({
    required this.targetSchema,
    this.displayField,
    this.onDelete = OnDeleteAction.restrict,
    this.inverseLabel,
  });

  factory ReferenceConstraints.fromJson(Map<String, dynamic> json) {
    // Backward compat: old key was 'schemaKey', new key is 'targetSchema'
    final target =
        json['targetSchema'] as String? ?? json['schemaKey'] as String? ?? '';

    final onDeleteStr = json['onDelete'] as String?;
    final onDelete = OnDeleteAction.values.firstWhere(
      (e) => e.name == onDeleteStr,
      orElse: () => OnDeleteAction.restrict,
    );

    return ReferenceConstraints(
      targetSchema: target,
      displayField: json['displayField'] as String?,
      onDelete: onDelete,
      inverseLabel: json['inverseLabel'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'targetSchema': targetSchema,
        // Also write 'schemaKey' for backward compat with blueprint readers
        'schemaKey': targetSchema,
        if (displayField != null) 'displayField': displayField,
        if (onDelete != OnDeleteAction.restrict) 'onDelete': onDelete.name,
        if (inverseLabel != null) 'inverseLabel': inverseLabel,
      };

  @override
  List<Object?> get props => [targetSchema, displayField, onDelete, inverseLabel];
}

// ── Empty (boolean, image, location, url, phone, email, list) ──

class EmptyConstraints extends FieldConstraints {
  const EmptyConstraints();

  @override
  Map<String, dynamic> toJson() => {};

  @override
  List<Object?> get props => [];
}
```

**Step 2: Verify the file has no analysis errors**

Run: `dart analyze lib/features/schema/models/field_constraints.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/schema/models/field_constraints.dart
git commit -m "feat(schema): add FieldConstraints sealed hierarchy"
```

---

### Task 2: Create SchemaEffect sealed hierarchy

**Files:**
- Create: `lib/features/schema/models/schema_effect.dart`

**Context:** The existing effects in `PostSubmitEffectExecutor` (`lib/features/blueprint/engine/post_submit_effect.dart`) use two JSON types: `adjust_reference` and `set_reference`. The typed model must match this exact shape.

**Step 1: Create the file**

```dart
import 'package:equatable/equatable.dart';

/// Type-safe effect declarations for [ModuleSchema].
///
/// Effects are side-effects that run when entries are created or deleted.
/// They are executed by `PostSubmitEffectExecutor`.
sealed class SchemaEffect extends Equatable {
  const SchemaEffect();

  String get type;

  Map<String, dynamic> toJson();

  /// Deserializes an effect from its JSON representation.
  ///
  /// Falls back to [UnknownEffect] for unrecognized types so old data
  /// never causes a crash.
  static SchemaEffect fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'adjust_reference' => AdjustReferenceEffect.fromJson(json),
      'set_reference' => SetReferenceEffect.fromJson(json),
      _ => UnknownEffect(json),
    };
  }
}

/// Adjusts a numeric field on a referenced entry (add/subtract).
///
/// Example JSON:
/// ```json
/// {
///   "type": "adjust_reference",
///   "referenceField": "account",
///   "targetField": "balance",
///   "amountField": "amount",
///   "operation": "add",
///   "min": 0
/// }
/// ```
class AdjustReferenceEffect extends SchemaEffect {
  @override
  String get type => 'adjust_reference';

  final String referenceField;
  final String targetField;
  final String operation; // 'add' or 'subtract'
  final String? amountField;
  final num? amount;
  final num? min;

  const AdjustReferenceEffect({
    required this.referenceField,
    required this.targetField,
    required this.operation,
    this.amountField,
    this.amount,
    this.min,
  });

  /// Returns a copy with the operation inverted (add↔subtract).
  AdjustReferenceEffect inverted() => AdjustReferenceEffect(
        referenceField: referenceField,
        targetField: targetField,
        operation: operation == 'add' ? 'subtract' : 'add',
        amountField: amountField,
        amount: amount,
        min: min,
      );

  factory AdjustReferenceEffect.fromJson(Map<String, dynamic> json) {
    return AdjustReferenceEffect(
      referenceField: json['referenceField'] as String? ?? '',
      targetField: json['targetField'] as String? ?? '',
      operation: json['operation'] as String? ?? 'add',
      amountField: json['amountField'] as String?,
      amount: json['amount'] as num?,
      min: json['min'] as num?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'referenceField': referenceField,
        'targetField': targetField,
        'operation': operation,
        if (amountField != null) 'amountField': amountField,
        if (amount != null) 'amount': amount,
        if (min != null) 'min': min,
      };

  @override
  List<Object?> get props =>
      [referenceField, targetField, operation, amountField, amount, min];
}

/// Sets a field on a referenced entry to a literal value or form value.
///
/// Example JSON:
/// ```json
/// {
///   "type": "set_reference",
///   "referenceField": "goal",
///   "targetField": "status",
///   "value": "completed"
/// }
/// ```
class SetReferenceEffect extends SchemaEffect {
  @override
  String get type => 'set_reference';

  final String referenceField;
  final String targetField;
  final String? sourceField;
  final dynamic value;

  const SetReferenceEffect({
    required this.referenceField,
    required this.targetField,
    this.sourceField,
    this.value,
  });

  factory SetReferenceEffect.fromJson(Map<String, dynamic> json) {
    return SetReferenceEffect(
      referenceField: json['referenceField'] as String? ?? '',
      targetField: json['targetField'] as String? ?? '',
      sourceField: json['sourceField'] as String?,
      value: json['value'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'referenceField': referenceField,
        'targetField': targetField,
        if (sourceField != null) 'sourceField': sourceField,
        if (value != null) 'value': value,
      };

  @override
  List<Object?> get props => [referenceField, targetField, sourceField, value];
}

/// Preserves unrecognized effect types so data is never lost.
class UnknownEffect extends SchemaEffect {
  @override
  String get type => _json['type'] as String? ?? 'unknown';

  final Map<String, dynamic> _json;

  const UnknownEffect(this._json);

  @override
  Map<String, dynamic> toJson() => _json;

  @override
  List<Object?> get props => [_json];
}
```

**Step 2: Verify no analysis errors**

Run: `dart analyze lib/features/schema/models/schema_effect.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/schema/models/schema_effect.dart
git commit -m "feat(schema): add SchemaEffect sealed hierarchy"
```

---

### Task 3: Update FieldDefinition

**Files:**
- Modify: `lib/features/schema/models/field_definition.dart`

**What changes:**
- `constraints` type: `Map<String, dynamic>` → `FieldConstraints`
- `options` field: removed (now in `EnumConstraints`)
- `fromJson`: reads `options` from JSON, merges into constraints map for enum types, then calls `FieldConstraints.fromJson`
- `toJson`: extracts `options` from `EnumConstraints` for backward compat at field level
- `copyWith`: updated to match new fields
- Convenience getter: `options` getter that returns enum options if constraints is `EnumConstraints`, else empty list

**Step 1: Rewrite the file**

```dart
import 'package:equatable/equatable.dart';

import 'field_constraints.dart';
import 'field_type.dart';

class FieldDefinition extends Equatable {
  final String key;
  final FieldType type;
  final String label;
  final bool required;
  final FieldConstraints constraints;

  const FieldDefinition({
    required this.key,
    required this.type,
    required this.label,
    this.required = false,
    this.constraints = const EmptyConstraints(),
  });

  /// Convenience accessor — returns enum options if this is an enum field.
  List<String> get options => switch (constraints) {
        EnumConstraints(:final options) => options,
        _ => const [],
      };

  factory FieldDefinition.fromJson(String key, Map<String, dynamic> json) {
    final type = FieldType.fromString(json['type'] as String? ?? 'text');

    // Read the raw constraints map
    final constraintsJson = Map<String, dynamic>.from(
      json['constraints'] as Map? ?? {},
    );

    // Backward compat: merge top-level 'options' into constraints for enum types
    final options = json['options'] as List?;
    if (options != null &&
        (type == FieldType.enumType || type == FieldType.multiEnum)) {
      constraintsJson['options'] = options;
    }

    return FieldDefinition(
      key: key,
      type: type,
      label: json['label'] as String? ?? key,
      required: json['required'] as bool? ?? false,
      constraints: FieldConstraints.fromJson(type, constraintsJson),
    );
  }

  FieldDefinition copyWith({
    String? key,
    FieldType? type,
    String? label,
    bool? required,
    FieldConstraints? constraints,
  }) {
    return FieldDefinition(
      key: key ?? this.key,
      type: type ?? this.type,
      label: label ?? this.label,
      required: required ?? this.required,
      constraints: constraints ?? this.constraints,
    );
  }

  Map<String, dynamic> toJson() {
    final constraintsJson = constraints.toJson();

    return {
      'type': type.toJson(),
      'label': label,
      'required': required,
      if (constraintsJson.isNotEmpty) 'constraints': constraintsJson,
      // Write options at field level for backward compat
      if (options.isNotEmpty) 'options': options,
    };
  }

  @override
  List<Object?> get props => [key, type, label, required, constraints];
}
```

**Step 2: Verify no analysis errors in the file itself**

Run: `dart analyze lib/features/schema/models/field_definition.dart`
Expected: No issues found (consumers will have errors until updated)

**Step 3: Commit**

```bash
git add lib/features/schema/models/field_definition.dart
git commit -m "feat(schema): type-safe FieldDefinition with FieldConstraints"
```

---

### Task 4: Update ModuleSchema

**Files:**
- Modify: `lib/features/schema/models/module_schema.dart`

**What changes:**
- `effects` type: `List<Map<String, dynamic>>` → `List<SchemaEffect>`
- New field: `displayField` (`String?`)
- `fromJson`: backward compat for `onDelete` migration now produces typed `AdjustReferenceEffect` objects
- `toJson`: serializes typed effects
- `copyWith`: updated

**Step 1: Rewrite the file**

```dart
import 'package:equatable/equatable.dart';

import 'field_definition.dart';
import 'schema_effect.dart';

class ModuleSchema extends Equatable {
  final int version;
  final Map<String, FieldDefinition> fields;
  final String label;
  final String? icon;
  final String? displayField;
  final List<SchemaEffect> effects;

  const ModuleSchema({
    this.version = 1,
    this.fields = const {},
    this.label = '',
    this.icon,
    this.displayField,
    this.effects = const [],
  });

  ModuleSchema copyWith({
    int? version,
    Map<String, FieldDefinition>? fields,
    String? label,
    String? icon,
    String? displayField,
    List<SchemaEffect>? effects,
  }) {
    return ModuleSchema(
      version: version ?? this.version,
      fields: fields ?? this.fields,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      displayField: displayField ?? this.displayField,
      effects: effects ?? this.effects,
    );
  }

  factory ModuleSchema.fromJson(Map<String, dynamic> json) {
    final fieldsJson = json['fields'] as Map<String, dynamic>? ?? {};
    final fields = fieldsJson.map(
      (key, value) => MapEntry(
        key,
        FieldDefinition.fromJson(key, Map<String, dynamic>.from(value as Map)),
      ),
    );

    // Parse typed effects
    final effectsRaw = json['effects'] as List?;
    var effects = effectsRaw
            ?.whereType<Map>()
            .map((e) => SchemaEffect.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        <SchemaEffect>[];

    // Backward compat: migrate legacy onDelete → effects with inverted ops
    if (effects.isEmpty) {
      final onDeleteRaw = json['onDelete'] as List?;
      if (onDeleteRaw != null && onDeleteRaw.isNotEmpty) {
        effects = onDeleteRaw.whereType<Map>().map((e) {
          final map = Map<String, dynamic>.from(e);
          // Invert the operation since onDelete stored the delete-time op
          final op = map['operation'] as String?;
          if (op == 'add') {
            map['operation'] = 'subtract';
          } else if (op == 'subtract') {
            map['operation'] = 'add';
          }
          return SchemaEffect.fromJson(map);
        }).toList();
      }
    }

    return ModuleSchema(
      version: json['version'] as int? ?? 1,
      fields: fields,
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String?,
      displayField: json['displayField'] as String?,
      effects: effects,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'fields': fields.map((key, field) => MapEntry(key, field.toJson())),
      'label': label,
      if (icon != null) 'icon': icon,
      if (displayField != null) 'displayField': displayField,
      if (effects.isNotEmpty)
        'effects': effects.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [version, fields, label, icon, displayField, effects];
}
```

**Step 2: Verify no analysis errors**

Run: `dart analyze lib/features/schema/models/module_schema.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/schema/models/module_schema.dart
git commit -m "feat(schema): typed SchemaEffect and displayField on ModuleSchema"
```

---

### Task 5: Update blueprint builders that read constraints

**Files:**
- Modify: `lib/features/blueprint/builders/input/slider_builder.dart` (lines 31-33)
- Modify: `lib/features/blueprint/builders/input/number_input_builder.dart` (lines 37-38)
- Modify: `lib/features/blueprint/builders/input/text_input_builder.dart` (line 37)
- Modify: `lib/features/blueprint/builders/input/rating_input_builder.dart` (line 33)
- Modify: `lib/features/blueprint/builders/input/reference_picker_builder.dart` (line 52)

**What changes:** Replace `field?.constraints['key']` map accesses with typed pattern matching.

**Step 1: Update slider_builder.dart**

Replace lines 31-33:
```dart
// OLD:
final min = (field?.constraints['min'] as num?)?.toDouble() ?? 0.0;
final max = (field?.constraints['max'] as num?)?.toDouble() ?? 100.0;
final divisions = (field?.constraints['divisions'] as num?)?.toInt();

// NEW:
final nc = field?.constraints;
final min = (nc is NumberConstraints ? nc.min : null)?.toDouble() ?? 0.0;
final max = (nc is NumberConstraints ? nc.max : null)?.toDouble() ?? 100.0;
final divisions = nc is NumberConstraints ? nc.divisions : null;
```

Add import at top: `import '../../../schema/models/field_constraints.dart';`

**Step 2: Update number_input_builder.dart**

Replace lines 37-38:
```dart
// OLD:
final min = field?.constraints['min'] as num?;
final max = field?.constraints['max'] as num?;

// NEW:
final nc = field?.constraints;
final min = nc is NumberConstraints ? nc.min : null;
final max = nc is NumberConstraints ? nc.max : null;
```

Add import: `import '../../../schema/models/field_constraints.dart';`

**Step 3: Update text_input_builder.dart**

Replace line 37:
```dart
// OLD:
final maxLength = field?.constraints['maxLength'] as int?;

// NEW:
final maxLength = field?.constraints is TextConstraints
    ? (field!.constraints as TextConstraints).maxLength
    : null;
```

Add import: `import '../../../schema/models/field_constraints.dart';`

**Step 4: Update rating_input_builder.dart**

Replace line 33:
```dart
// OLD:
final maxStars = (field?.constraints['max'] as num?)?.toInt() ?? 5;

// NEW:
final maxStars = field?.constraints is RatingConstraints
    ? (field!.constraints as RatingConstraints).maxRating
    : 5;
```

Add import: `import '../../../schema/models/field_constraints.dart';`

**Step 5: Update reference_picker_builder.dart**

Replace line 52:
```dart
// OLD:
return field?.constraints['schemaKey'] as String? ?? '';

// NEW:
final c = field?.constraints;
return c is ReferenceConstraints ? c.targetSchema : '';
```

Add import: `import '../../../schema/models/field_constraints.dart';`

**Step 6: Verify all five files have no analysis errors**

Run: `dart analyze lib/features/blueprint/builders/input/`
Expected: No issues found

**Step 7: Commit**

```bash
git add lib/features/blueprint/builders/input/slider_builder.dart \
        lib/features/blueprint/builders/input/number_input_builder.dart \
        lib/features/blueprint/builders/input/text_input_builder.dart \
        lib/features/blueprint/builders/input/rating_input_builder.dart \
        lib/features/blueprint/builders/input/reference_picker_builder.dart
git commit -m "refactor(builders): use typed FieldConstraints in input builders"
```

---

### Task 6: Update ReferenceResolver

**Files:**
- Modify: `lib/features/blueprint/renderer/reference_resolver.dart`

**What changes:**
- Use `ReferenceConstraints.targetSchema` instead of `field.constraints['schemaKey']`
- Use `ReferenceConstraints.displayField` when available, fall back to auto-detect
- Use `ModuleSchema.displayField` as another fallback

**Step 1: Update the file**

In `resolve()`, replace line 21:
```dart
// OLD:
final targetSchemaKey = field.constraints['schemaKey'] as String?;

// NEW:
final ref = field.constraints;
if (ref is! ReferenceConstraints) return rawValue.toString();
final targetSchemaKey = ref.targetSchema;
```

Remove the now-redundant null check on `targetSchemaKey` (line 22) — `ReferenceConstraints` always has `targetSchema`.

In `_findDisplayField()`, use `ReferenceConstraints.displayField` and `ModuleSchema.displayField`:

Replace `_findDisplayField` method:
```dart
String _findDisplayField(ModuleSchema schema, {String? refDisplayField}) {
  // 1. Explicit displayField from reference constraint
  if (refDisplayField != null && schema.fields.containsKey(refDisplayField)) {
    return refDisplayField;
  }
  // 2. Explicit displayField on the schema itself
  if (schema.displayField != null && schema.fields.containsKey(schema.displayField)) {
    return schema.displayField!;
  }
  // 3. Convention: field named 'name'
  if (schema.fields.containsKey('name')) return 'name';
  // 4. First text field
  for (final e in schema.fields.entries) {
    if (e.value.type == FieldType.text) return e.key;
  }
  return schema.fields.keys.first;
}
```

Update the call site in `resolve()` to pass `ref.displayField`.

Add import: `import '../../schema/models/field_constraints.dart';`

**Step 2: Verify**

Run: `dart analyze lib/features/blueprint/renderer/reference_resolver.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/blueprint/renderer/reference_resolver.dart
git commit -m "refactor(reference): use typed ReferenceConstraints in resolver"
```

---

### Task 7: Update schema UI widgets

**Files:**
- Modify: `lib/features/schema/screens/field_editor_screen.dart`
- Modify: `lib/features/schema/widgets/add_field_sheet.dart`
- Modify: `lib/features/schema/widgets/add_schema_sheet.dart`
- Modify: `lib/features/schema/widgets/field_draft_row.dart`
- Modify: `lib/features/schema/widgets/constraints_editor.dart`

**What changes:**

**field_editor_screen.dart:**
- `_options` and `_constraints` local state → derive from typed `FieldConstraints`
- Remove `_options = List.of(widget.field.options)` → use `widget.field.options` directly
- Remove `_constraints = Map.of(widget.field.constraints)` → not needed for raw map editing
- `_save()`: construct the appropriate `FieldConstraints` subclass based on `_selectedType`
- The ConstraintsEditor will need to work with the specific constraint type

In `_FieldEditorFormState.initState()` (line 112-119):
```dart
// OLD:
_options = List.of(widget.field.options);
_constraints = Map.of(widget.field.constraints);

// NEW:
_options = List.of(widget.field.options);
_constraints = Map.of(widget.field.constraints.toJson());
```

In `_save()` (line 132-143):
```dart
// OLD:
final updated = widget.field.copyWith(
  label: _labelController.text.trim(),
  type: _selectedType,
  required: _isRequired,
  options: _options,
  constraints: _constraints,
);

// NEW:
// Build typed constraints from the local state
final constraintsMap = Map<String, dynamic>.from(_constraints);
if (_isEnumType) {
  constraintsMap['options'] = _options;
}
final typedConstraints = FieldConstraints.fromJson(_selectedType, constraintsMap);

final updated = widget.field.copyWith(
  label: _labelController.text.trim(),
  type: _selectedType,
  required: _isRequired,
  constraints: typedConstraints,
);
```

Add import: `import '../models/field_constraints.dart';`

**add_field_sheet.dart:**
In `_submit()` (lines 48-76), replace constraints construction:
```dart
// OLD:
Map<String, dynamic> constraints = {};
if (_isReference) {
  final refKey = _refSchemaKeyController.text.trim();
  if (refKey.isNotEmpty) {
    constraints = {'schemaKey': refKey};
  }
}
// ... FieldDefinition(... options: List.of(_options), constraints: constraints)

// NEW:
FieldConstraints constraints;
if (_isReference) {
  final refKey = _refSchemaKeyController.text.trim();
  constraints = ReferenceConstraints(targetSchema: refKey);
} else if (_isEnumType) {
  constraints = EnumConstraints(options: List.of(_options));
} else {
  constraints = const EmptyConstraints();
}
// ... FieldDefinition(... constraints: constraints)
```

Remove `options` from the `FieldDefinition` constructor call.

Add import: `import '../models/field_constraints.dart';`

**add_schema_sheet.dart:**
In `_submit()` (lines 58-71), same pattern:
```dart
// OLD:
Map<String, dynamic> constraints = {};
if (draft.type == FieldType.reference && draft.referenceSchemaKey.isNotEmpty) {
  constraints = {'schemaKey': draft.referenceSchemaKey};
}
fields[fKey] = FieldDefinition(... options: List.of(draft.options), constraints: constraints);

// NEW:
FieldConstraints constraints;
if (draft.type == FieldType.reference && draft.referenceSchemaKey.isNotEmpty) {
  constraints = ReferenceConstraints(targetSchema: draft.referenceSchemaKey);
} else if (draft.type == FieldType.enumType || draft.type == FieldType.multiEnum) {
  constraints = EnumConstraints(options: List.of(draft.options));
} else {
  constraints = const EmptyConstraints();
}
fields[fKey] = FieldDefinition(... constraints: constraints);
```

Add import: `import '../models/field_constraints.dart';`

**field_draft_row.dart:** No changes needed — `FieldDraft` is a UI-only draft class with its own `options` and `referenceSchemaKey` strings. It doesn't use `FieldDefinition` or `FieldConstraints`.

**constraints_editor.dart:** This widget currently takes `Map<String, dynamic>` constraints and renders raw key/value pairs. For now, keep it working with `Map<String, dynamic>` obtained from `constraints.toJson()`. The field editor screen already passes `widget.field.constraints.toJson()` to it. A smarter per-type constraints editor is a follow-up task.

**Step 2: Verify all schema widget files**

Run: `dart analyze lib/features/schema/`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/schema/screens/field_editor_screen.dart \
        lib/features/schema/widgets/add_field_sheet.dart \
        lib/features/schema/widgets/add_schema_sheet.dart
git commit -m "refactor(schema-ui): use typed FieldConstraints in schema editors"
```

---

### Task 8: Update effect consumers

**Files:**
- Modify: `lib/features/blueprint/engine/post_submit_effect.dart`
- Modify: `lib/features/module_viewer/bloc/module_viewer_bloc.dart`
- Modify: `lib/features/blueprint/engine/action_dispatcher.dart`

**What changes:**

**post_submit_effect.dart:**
- `computeUpdates` parameter: `List<dynamic> effects` → `List<SchemaEffect> effects`
- `validateEffects` parameter: `List<dynamic> effects` → `List<SchemaEffect> effects`
- `computeDeleteUpdates` parameter: `List<Map<String, dynamic>> effects` → `List<SchemaEffect> effects`
- Internal logic: replace `effect is! Map<String, dynamic>` checks with `switch` on sealed type
- `computeDeleteUpdates`: use `AdjustReferenceEffect.inverted()` instead of manual map copy
- Import: `import '../../schema/models/schema_effect.dart';`

Key changes in `computeUpdates`:
```dart
// OLD:
for (final effect in effects) {
  if (effect is! Map<String, dynamic>) continue;
  final type = effect['type'] as String?;
  switch (type) {
    case 'adjust_reference': _applyAdjust(effect, ...);
    case 'set_reference': _applySet(effect, ...);
  }
}

// NEW:
for (final effect in effects) {
  switch (effect) {
    case AdjustReferenceEffect():
      _applyAdjust(effect, formData, entryById, updates);
    case SetReferenceEffect():
      _applySet(effect, formData, entryById, updates);
    case UnknownEffect():
      break; // skip unrecognized effects
  }
}
```

Update `_applyAdjust` to take `AdjustReferenceEffect` instead of `Map<String, dynamic>`:
```dart
void _applyAdjust(
  AdjustReferenceEffect effect,
  Map<String, dynamic> formData,
  Map<String, Entry> entryById,
  Map<String, Map<String, dynamic>> updates,
) {
  if (effect.operation != 'add' && effect.operation != 'subtract') return;

  final entryId = formData[effect.referenceField]?.toString();
  if (entryId == null || entryId.isEmpty) return;

  final entry = entryById[entryId];
  if (entry == null) return;

  final num? amount;
  if (effect.amount != null) {
    amount = effect.amount;
  } else if (effect.amountField != null) {
    amount = _toNum(formData[effect.amountField]);
  } else {
    return;
  }
  if (amount == null) return;

  final accumulated = updates[entryId] ?? {};
  final currentRaw = accumulated.containsKey(effect.targetField)
      ? accumulated[effect.targetField]
      : entry.data[effect.targetField];
  final current = _toNum(currentRaw) ?? 0;

  final newValue = effect.operation == 'add' ? current + amount : current - amount;

  updates.putIfAbsent(entryId, () => {});
  updates[entryId]![effect.targetField] = newValue;
}
```

Update `_applySet` similarly with `SetReferenceEffect`.

Update `validateEffects` to use typed fields instead of map access.

Update `computeDeleteUpdates`:
```dart
// OLD:
final invertedEffects = effects.map((effect) {
  final type = effect['type'] as String?;
  if (type == 'adjust_reference') {
    final op = effect['operation'] as String?;
    final invertedOp = op == 'add' ? 'subtract' : 'add';
    return {...effect, 'operation': invertedOp};
  }
  return effect;
}).toList();

// NEW:
final invertedEffects = effects.map((effect) {
  if (effect is AdjustReferenceEffect) return effect.inverted();
  return effect;
}).toList();
```

**module_viewer_bloc.dart:**
- Line 158: `final schemaEffects = current.module.schemas[schemaKey]?.effects ?? const [];` — type is now `List<SchemaEffect>`, no change needed.
- Line 283: `await _applyDeleteEffects(current, schema.effects, deletedEntry);` — no change needed.
- Line 309: `_applyDeleteEffects` parameter type: `List<Map<String, dynamic>> effects` → `List<SchemaEffect> effects`
- Import: `import '../../schema/models/schema_effect.dart';`

**action_dispatcher.dart:**
- Line 288: same pattern, type changes from `List<Map<String, dynamic>>` to `List<SchemaEffect>` automatically since `schema.effects` is now typed.
- May need import.

**Step 2: Verify**

Run: `dart analyze lib/features/blueprint/engine/post_submit_effect.dart lib/features/module_viewer/bloc/module_viewer_bloc.dart lib/features/blueprint/engine/action_dispatcher.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/blueprint/engine/post_submit_effect.dart \
        lib/features/module_viewer/bloc/module_viewer_bloc.dart \
        lib/features/blueprint/engine/action_dispatcher.dart
git commit -m "refactor(effects): use typed SchemaEffect in executor and bloc"
```

---

### Task 9: Add reverse relations helper to Module

**Files:**
- Modify: `lib/core/models/module.dart`

**What changes:** Add a method that scans all schemas for reference fields pointing at a given schema key, returning computed reverse relations.

**Step 1: Add the helper class and method**

Add to the bottom of the file (or a new import):

```dart
// In module.dart, add import:
import '../../features/schema/models/field_constraints.dart';

// Add class:
class ReverseRelation extends Equatable {
  final String fromSchema;
  final String fromField;
  final String label;

  const ReverseRelation({
    required this.fromSchema,
    required this.fromField,
    required this.label,
  });

  @override
  List<Object?> get props => [fromSchema, fromField, label];
}

// Add method to Module class:
/// Computes reverse relations for [schemaKey] by scanning all schemas
/// for reference fields that point at it.
List<ReverseRelation> reverseRelationsFor(String schemaKey) {
  final results = <ReverseRelation>[];
  for (final entry in schemas.entries) {
    for (final field in entry.value.fields.values) {
      final c = field.constraints;
      if (c is ReferenceConstraints && c.targetSchema == schemaKey) {
        results.add(ReverseRelation(
          fromSchema: entry.key,
          fromField: field.key,
          label: c.inverseLabel ?? entry.value.label,
        ));
      }
    }
  }
  return results;
}
```

**Step 2: Verify**

Run: `dart analyze lib/core/models/module.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/models/module.dart
git commit -m "feat(schema): add reverse relations helper to Module"
```

---

### Task 10: Full project analysis

**Step 1: Run full analysis**

Run: `dart analyze lib/`
Expected: No issues (or only pre-existing issues unrelated to this change)

If there are errors, fix them — likely missed consumers reading `.constraints[...]` or `.options` that need updating.

**Step 2: Verify templates still work**

The seed templates (`scripts/templates/*.dart`) are raw `Map<String, dynamic>` that get written to Firestore and read back through `ModuleSchema.fromJson`. Verify the drinks template (which uses references) deserializes correctly:

Run: `dart analyze scripts/`
Expected: No issues — templates are just raw maps, they don't reference the typed classes.

**Step 3: Final commit**

```bash
git add -A
git commit -m "chore: fix any remaining analysis issues from schema redesign"
```
