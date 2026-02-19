# Type-Safe Schema Redesign

**Date:** 2026-02-19
**Status:** Approved
**Scope:** Schema models only (field_definition, module_schema, new constraints/effects classes)

## Problem

The schema system uses `Map<String, dynamic>` for constraints and `List<Map<String, dynamic>>` for effects. This means:
- No compile-time safety — invalid constraint combos are possible
- Reference fields store `{'schemaKey': 'conference'}` in a generic map
- ConstraintsEditor UI is a raw key/value form
- ReferenceResolver guesses display fields instead of reading them from schema
- Effects have no model class at all
- `options` lives on every FieldDefinition even though only enum types use it

## Design Decisions

1. **Sealed class hierarchy for constraints** — each FieldType gets its own constraints subclass
2. **Bidirectional relations** — reference fields declare both forward and inverse sides; reverse is derived, not stored
3. **Typed effects** — SchemaEffect sealed class replaces untyped maps
4. **displayField on ModuleSchema** — explicit, no more guessing in ReferenceResolver
5. **Backward compatible JSON** — existing Firestore data deserializes cleanly

## FieldConstraints Sealed Hierarchy

```dart
sealed class FieldConstraints extends Equatable {
  const FieldConstraints();
  Map<String, dynamic> toJson();
  static FieldConstraints fromJson(FieldType type, Map<String, dynamic> json);
}
```

### Per-type constraints

| FieldType | Constraints class | Fields |
|-----------|------------------|--------|
| text | TextConstraints | minLength?, maxLength?, pattern?, multiline |
| number | NumberConstraints | min?, max?, step? |
| currency | CurrencyConstraints | defaultCurrency?, min?, max? |
| datetime | DateTimeConstraints | dateOnly, allowPast, allowFuture |
| enumType | EnumConstraints | options (List\<String>) |
| multiEnum | EnumConstraints | options (List\<String>) |
| rating | RatingConstraints | maxRating (default 5), allowHalf |
| duration | DurationConstraints | unit (seconds/minutes/hours) |
| reference | ReferenceConstraints | targetSchema, displayField?, onDelete, inverseLabel? |
| boolean | EmptyConstraints | (none) |
| image | EmptyConstraints | (none) |
| location | EmptyConstraints | (none) |
| url | EmptyConstraints | (none) |
| phone | EmptyConstraints | (none) |
| email | EmptyConstraints | (none) |
| list | EmptyConstraints | (none) |

### ReferenceConstraints detail

```dart
class ReferenceConstraints extends FieldConstraints {
  final String targetSchema;        // e.g. 'conference'
  final String? displayField;       // e.g. 'name' (null = auto-detect)
  final OnDeleteAction onDelete;    // cascade, setNull, restrict
  final String? inverseLabel;       // e.g. 'Drinks' — label for reverse lookup
}

enum OnDeleteAction { cascade, setNull, restrict }
```

### Reverse relations (derived)

A helper on Module computes reverse relations by scanning all schemas:

```dart
List<ReverseRelation> reverseRelationsFor(String schemaKey) → [
  ReverseRelation(fromSchema: 'drink', fromField: 'conference', label: 'Drinks')
]
```

No data stored for the reverse side — always computed from forward references.

## SchemaEffect Sealed Hierarchy

```dart
sealed class SchemaEffect extends Equatable {
  const SchemaEffect();
  Map<String, dynamic> toJson();
  static SchemaEffect fromJson(Map<String, dynamic> json);
}

class AggregateEffect extends SchemaEffect {
  final String targetSchema;
  final String targetField;
  final AggregateOperation operation; // add, subtract, set
  final String sourceField;
}

enum AggregateOperation { add, subtract, set }
```

Backward-compat: existing `onDelete` migration in ModuleSchema.fromJson converts to typed AggregateEffect objects.

## Updated FieldDefinition

```dart
class FieldDefinition extends Equatable {
  final String key;
  final FieldType type;
  final String label;
  final bool required;
  final FieldConstraints constraints;   // was Map<String, dynamic>
  // options removed — now inside EnumConstraints
}
```

## Updated ModuleSchema

```dart
class ModuleSchema extends Equatable {
  final int version;
  final Map<String, FieldDefinition> fields;
  final String label;
  final String? icon;
  final String? displayField;           // NEW
  final List<SchemaEffect> effects;     // was List<Map<String, dynamic>>
}
```

## JSON Serialization

FieldType is the discriminator for deserializing constraints:

```dart
static FieldConstraints fromJson(FieldType type, Map<String, dynamic> json) {
  return switch (type) {
    FieldType.text => TextConstraints.fromJson(json),
    FieldType.number => NumberConstraints.fromJson(json),
    FieldType.reference => ReferenceConstraints.fromJson(json),
    FieldType.enumType || FieldType.multiEnum => EnumConstraints.fromJson(json),
    FieldType.currency => CurrencyConstraints.fromJson(json),
    FieldType.datetime => DateTimeConstraints.fromJson(json),
    FieldType.rating => RatingConstraints.fromJson(json),
    FieldType.duration => DurationConstraints.fromJson(json),
    _ => const EmptyConstraints(),
  };
}
```

Backward compatibility: `{'schemaKey': 'conference'}` on a reference field → `ReferenceConstraints(targetSchema: 'conference')`. The key rename (`schemaKey` → `targetSchema`) is handled in `ReferenceConstraints.fromJson` by checking both keys.

## Files

| Action | File |
|--------|------|
| Create | `lib/features/schema/models/field_constraints.dart` |
| Create | `lib/features/schema/models/schema_effect.dart` |
| Modify | `lib/features/schema/models/field_definition.dart` |
| Modify | `lib/features/schema/models/module_schema.dart` |

Consumers (bloc, widgets, blueprint builders, reference resolver, templates) will need updates in a follow-up pass.
