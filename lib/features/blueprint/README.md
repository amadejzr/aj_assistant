# Blueprint Feature — Server-Driven UI Renderer

The Blueprint feature converts JSON screen definitions into live Flutter widget trees. The AI generates these JSON blueprints, and the renderer turns them into fully interactive screens.

## Architecture

```
renderer/
  blueprint_renderer.dart  — Top-level widget: parse → build widget tree
  blueprint_parser.dart    — JSON → BlueprintNode sealed class hierarchy
  blueprint_node.dart      — All node type definitions
  widget_registry.dart     — Maps type strings to builder functions
  render_context.dart      — Carries module, entries, callbacks through tree
  reference_resolver.dart  — Resolves reference field IDs to display text
engine/
  expression_evaluator.dart — Evaluates expressions (sum, count, avg, etc.)
  entry_filter.dart         — Filters entries by conditions + time periods
  condition_evaluator.dart  — Evaluates visibility conditions
  action_dispatcher.dart    — Dispatches blueprint actions (navigate, submit, delete)
builders/
  layout/    — Screen containers and structural widgets
  display/   — Data visualization and read-only display
  input/     — Form fields and data entry
  action/    — Buttons and interactive triggers
widgets/
  reference_entry_sheet.dart — Bottom sheet for inline reference entry creation
```

## Widget Types

### Layout

| Type | Description | Key Properties |
|------|-------------|----------------|
| `screen` | Top-level screen with app bar and optional FAB | `title`, `children`, `fab` |
| `tab_screen` | Tabbed screen with multiple tab content areas | `title`, `tabs[{label, icon, content}]`, `fab` |
| `form_screen` | Form wrapper with submit button | `title`, `children`, `submitLabel`, `editLabel`, `defaults` |
| `scroll_column` | Scrollable vertical layout | `children` |
| `section` | Titled group with ink-brush underline | `title`, `children` |
| `row` | Horizontal layout (expands children equally) | `children` |
| `column` | Vertical layout | `children` |
| `conditional` | Shows/hides children based on conditions | `condition`, `then`, `else` |
| `expandable` | Collapsible section with animated chevron | `title`, `children`, `initiallyExpanded` |

### Display

| Type | Description | Key Properties |
|------|-------------|----------------|
| `stat_card` | Shows a computed value (sum, count, streak, etc.) | `label`, `expression`, `stat`, `format`, `filter` |
| `entry_list` | Filtered, sorted list of entries | `query{orderBy, direction, limit}`, `filter`, `itemLayout` |
| `entry_card` | Single entry display with title/subtitle/trailing | `title`, `subtitle`, `trailing`, `onTap`, `swipeActions` |
| `text_display` | Static text with optional style | `text`, `style` |
| `empty_state` | Placeholder when no data exists | `icon`, `title`, `subtitle` |
| `chart` | Pie/donut/bar chart from grouped data | `chartType`, `groupBy`, `aggregate`, `filter` |
| `progress_bar` | Horizontal progress indicator | `label`, `expression`, `format` |
| `date_calendar` | Calendar view highlighting entry dates | `dateField`, `filter` |
| `card_grid` | Grid of cards from enum field options | `fieldKey`, `action` |
| `divider` | Horizontal line separator | _(none)_ |
| `badge` | Hanko-style pill label with rotation | `text`, `expression`, `variant` |

### Input

| Type | Description | Key Properties |
|------|-------------|----------------|
| `text_input` | Text field (single or multiline) | `fieldKey`, `multiline` |
| `number_input` | Numeric field with min/max validation | `fieldKey` |
| `currency_input` | Formatted currency field with symbol prefix | `fieldKey`, `currencySymbol`, `decimalPlaces` |
| `date_picker` | Date selection via calendar dialog | `fieldKey` |
| `time_picker` | Time selection via clock dialog | `fieldKey` |
| `enum_selector` | Single/multi-select chip selector | `fieldKey`, `multiSelect` |
| `toggle` | Boolean switch | `fieldKey` |
| `slider` | Numeric range slider | `fieldKey` |
| `rating_input` | Star rating (1-5) | `fieldKey` |
| `reference_picker` | Cross-schema reference selector with inline create/edit | `fieldKey`, `schemaKey`, `displayField` |

### Action

| Type | Description | Key Properties |
|------|-------------|----------------|
| `button` | Text button (primary, outlined, destructive) | `label`, `action`, `style` |
| `fab` | Floating action button | `icon`, `action` |
| `icon_button` | Icon-only button with optional tooltip | `icon`, `action`, `tooltip` |
| `action_menu` | Popup menu with labeled items | `icon`, `items[{label, icon, action}]` |

## Expression Syntax

Expressions compute values from entry data:

```
sum(amount)                          — Total of all amounts
sum(amount, period(month))           — This month's total
count(period(week))                  — Entries this week
group(category, sum(amount))         — {Food: 450, Transport: 120}
avg(duration)                        — Average duration
min(amount)                          — Minimum amount
max(amount)                          — Maximum amount
subtract(settings.budget, sum(amount, period(month))) — Budget remaining
```

**Operators:** sum, count, avg, min, max, group, subtract, multiply, divide, percentage
**Filters:** period(today|week|month|year), where(field, op, value)

## Template Interpolation

Entry cards use `{{fieldKey}}` templates that resolve against entry data:

```json
{"type": "entry_card", "title": "{{note}}", "subtitle": "{{category}}", "trailing": "{{amount}}"}
```

Reference fields (type `reference`) automatically resolve IDs to display values using `ReferenceResolver`.

## Action System

Actions are JSON objects with a `type` key:

```json
{"type": "navigate", "screen": "add_entry", "params": {"mode": "quick"}}
{"type": "navigate_back"}
{"type": "submit"}
{"type": "delete_entry", "confirm": true, "confirmMessage": "Delete this?"}
```

## Visibility Conditions

Any widget can have a `visible` property in its `properties`:

```json
{"type": "button", "label": "Delete", "visible": {"field": "_entryId", "op": "!=", "value": null}}
```

## Screen Navigation

Screens are keyed in `module.screens`. The `navigate` action pushes a new screen onto the BLoC's stack:

```json
{"type": "fab", "icon": "add", "action": {"type": "navigate", "screen": "add_entry"}}
```

Form screens can receive `defaults` and `screenParams` to pre-fill fields.

## Reference Fields

Schemas connect via `FieldType.reference`:

```json
{
  "expense": {
    "fields": {
      "category": {"type": "reference", "constraints": {"schemaKey": "category"}}
    }
  },
  "category": {
    "fields": {
      "name": {"type": "text", "label": "Category Name"}
    }
  }
}
```

The `reference_picker` widget shows entries from the target schema as selectable chips. Long-press to edit, "+" to create inline.

## Full Blueprint Example

```json
{
  "id": "main",
  "type": "screen",
  "title": "Expenses",
  "layout": {
    "type": "scroll_column",
    "children": [
      {
        "type": "section",
        "title": "This Month",
        "children": [
          {
            "type": "row",
            "children": [
              {"type": "stat_card", "label": "Total Spent", "expression": "sum(amount, period(month))"},
              {"type": "stat_card", "label": "Transactions", "expression": "count(period(month))"}
            ]
          }
        ]
      },
      {
        "type": "section",
        "title": "By Category",
        "children": [
          {"type": "chart", "chartType": "donut", "groupBy": "category", "aggregate": "sum(amount)"}
        ]
      },
      {
        "type": "section",
        "title": "Recent",
        "children": [
          {
            "type": "entry_list",
            "query": {"orderBy": "date", "direction": "desc", "limit": 10},
            "itemLayout": {
              "type": "entry_card",
              "title": "{{note}}",
              "subtitle": "{{category}}",
              "trailing": "{{amount}}"
            }
          }
        ]
      }
    ]
  },
  "fab": {"type": "fab", "icon": "add", "action": {"type": "navigate", "screen": "add_entry"}}
}
```
