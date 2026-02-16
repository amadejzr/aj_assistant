# Schema Feature — AI Tool Reference

This document describes the schema system that defines the data structure of every module in AJ Assistant. When the AI creates or modifies a module, it works with schemas and fields as described below.

---

## Data Model

A **Module** contains a `schemas` map: `Map<String, ModuleSchema>`. Each key is a schema identifier (e.g. `"expense"`, `"category"`, `"habit"`). Every module starts with at least a `"default"` schema.

### ModuleSchema

```
ModuleSchema:
  version: int (default 1)
  label: String (display name, e.g. "Expense")
  icon: String? (optional icon identifier)
  fields: Map<String, FieldDefinition>
```

### FieldDefinition

```
FieldDefinition:
  key: String (unique within schema, e.g. "amount")
  type: FieldType
  label: String (display name, e.g. "Amount")
  required: bool (default false)
  options: List<String> (only for enumType/multiEnum, e.g. ["Food", "Transport"])
  constraints: Map<String, dynamic> (type-specific constraints)
```

### FieldType (all supported types)

| Type | Description | Constraints |
|------|------------|-------------|
| `text` | Free text input | `maxLength`, `minLength` |
| `number` | Numeric value | `min`, `max` |
| `boolean` | True/false toggle | — |
| `datetime` | Date and/or time | — |
| `enumType` | Single select from options | Requires `options` list |
| `multiEnum` | Multi select from options | Requires `options` list |
| `list` | List of text values | — |
| `reference` | Link to entry in another schema | Requires `constraints.schemaKey` |
| `image` | Image attachment | — |
| `location` | Geographic coordinates | — |
| `duration` | Time duration | — |
| `currency` | Monetary value | `min`, `max`, `currency` |
| `rating` | Star/numeric rating | `min`, `max` |
| `url` | Web URL | — |
| `phone` | Phone number | — |
| `email` | Email address | — |

---

## Firestore Structure

```
/users/{userId}/modules/{moduleId}
  schemas:
    "expense":
      version: 1
      label: "Expense"
      fields:
        "amount": { type: "currency", label: "Amount", required: true }
        "category": { type: "enumType", label: "Category", options: ["Food", "Transport", "Other"] }
        "note": { type: "text", label: "Note" }
        "date": { type: "datetime", label: "Date", required: true }
    "category":
      version: 1
      label: "Category"
      fields:
        "name": { type: "text", label: "Name", required: true }
        "color": { type: "text", label: "Color" }
```

Entries live in a subcollection and reference their schema:

```
/users/{userId}/modules/{moduleId}/entries/{entryId}
  data: { "amount": 42.50, "category": "Food", "note": "Lunch", "date": "2026-02-16T12:00:00Z" }
  schemaVersion: 1
  schemaKey: "expense"
```

---

## AI Tool Operations

When creating or modifying modules, the AI uses these operations through Cloud Function tools:

### createModule

Creates a new module with initial schemas and screen blueprints.

```json
{
  "name": "Expense Tracker",
  "icon": "wallet",
  "color": "#D94E33",
  "schemas": {
    "expense": {
      "label": "Expense",
      "fields": {
        "amount": { "type": "currency", "label": "Amount", "required": true },
        "category": { "type": "enumType", "label": "Category", "required": true, "options": ["Food", "Transport", "Entertainment", "Other"] },
        "note": { "type": "text", "label": "Note" },
        "date": { "type": "datetime", "label": "Date", "required": true }
      }
    }
  },
  "screens": { ... }
}
```

### updateSchema

Modifies an existing schema — add/remove/update fields, change label.

- **addFields**: `{ "fieldKey": { type, label, required, options, constraints } }`
- **removeFields**: `["fieldKey1", "fieldKey2"]`
- **updateFields**: `{ "fieldKey": { ...partial updates } }`

### Key Rules

1. **Schema keys** are lowercase, snake_case identifiers (e.g. `"expense"`, `"workout_log"`).
2. **Field keys** are lowercase, snake_case (e.g. `"amount"`, `"due_date"`).
3. **Labels** are human-readable display names (e.g. `"Amount"`, `"Due Date"`).
4. **enumType/multiEnum** fields must include an `options` list.
5. **reference** fields must include `constraints.schemaKey` pointing to another schema in the same module.
6. Field removal is soft — existing entries keep their data, the field just disappears from the UI.
7. Entries are migrated lazily on read when `schemaVersion` is behind the current schema version.

---

## Multi-Schema Modules

A module can have multiple schemas for related data types. Example — an expense tracker with categories:

```
schemas:
  "expense": { fields: { amount, category_ref, note, date } }
  "category": { fields: { name, color, icon } }
```

The `category_ref` field in `expense` uses `type: "reference"` with `constraints: { "schemaKey": "category" }` to link to category entries.

---

## Example: Creating a Habit Tracker

```json
{
  "name": "Habit Tracker",
  "icon": "check_circle",
  "color": "#4CAF50",
  "schemas": {
    "habit": {
      "label": "Habit",
      "fields": {
        "name": { "type": "text", "label": "Habit Name", "required": true },
        "frequency": { "type": "enumType", "label": "Frequency", "required": true, "options": ["Daily", "Weekly", "Monthly"] },
        "target": { "type": "number", "label": "Target Count", "constraints": { "min": 1 } },
        "active": { "type": "boolean", "label": "Active" }
      }
    },
    "log": {
      "label": "Log Entry",
      "fields": {
        "habit_ref": { "type": "reference", "label": "Habit", "required": true, "constraints": { "schemaKey": "habit" } },
        "date": { "type": "datetime", "label": "Date", "required": true },
        "count": { "type": "number", "label": "Count", "constraints": { "min": 0 } },
        "notes": { "type": "text", "label": "Notes" }
      }
    }
  }
}
```
