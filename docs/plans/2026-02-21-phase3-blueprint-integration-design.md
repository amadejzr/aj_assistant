# SQL-Driven Screens — Phase 3: Blueprint Builder Integration

## Context

Phase 1 built `SchemaManager` + `ModuleDatabase` (table creation/teardown). Phase 2 built `QueryExecutor` + `MutationExecutor` (parameterized SQL, Drift streaming, CRUD). Phase 3 connects these executors to the blueprint rendering system so SQL-driven screens actually render.

## Design Decisions

1. **Explicit `source` field** — builders declare which named query feeds them: `{"type": "entry_list", "source": "recent_expenses"}`. No convention magic.
2. **Single BLoC, dual path** — `ModuleViewerBloc` checks `module.database != null` to pick the data path. No new abstractions.
3. **SQL-side filtering** — filter chip changes push into query params via `onScreenParamChanged`. BLoC re-subscribes `watchAll()` with new resolved params. Database handles filtering.

## Screen JSON Format (recap)

```json
{
  "type": "screen",
  "queries": {
    "recent_expenses": {
      "sql": "SELECT e.*, a.name as account_name FROM m_budget_expenses e JOIN m_budget_accounts a ON e.account_id = a.id WHERE (:category = 'all' OR e.category = :category) ORDER BY e.created_at DESC LIMIT 20",
      "params": { "category": "{{filters.category}}" },
      "defaults": { "category": "all" }
    },
    "total_balance": {
      "sql": "SELECT SUM(balance) as total FROM m_budget_accounts"
    }
  },
  "mutations": {
    "create": "INSERT INTO m_budget_expenses (...) VALUES (:id, :amount, ...)",
    "update": "UPDATE m_budget_expenses SET amount = COALESCE(:amount, amount), ... WHERE id = :id",
    "delete": "DELETE FROM m_budget_expenses WHERE id = :id"
  },
  "children": [
    { "type": "stat_card", "source": "total_balance", "valueKey": "total", "label": "Total Balance" },
    { "type": "entry_list", "source": "recent_expenses", "itemLayout": { ... } }
  ]
}
```

## Data Flow

```
Screen navigated to
  → BLoC parses screen's queries + mutations
  → BLoC resolves {{filters.X}} from screenParams
  → QueryExecutor.watchAll(queries, resolvedParams)
  → Stream<Map<String, List<Map>>>
  → BLoC stores in state.queryResults
  → RenderContext carries queryResults
  → Builders read ctx.queryResults[source]
```

Filter change:
```
Filter chip tap → onScreenParamChanged('category', 'Food')
  → BLoC re-resolves params → re-subscribes watchAll
  → Drift re-emits with filtered data
  → Builders update
```

Mutation:
```
Form submit → BLoC calls MutationExecutor.create(mutation, formValues)
  → SQL INSERT with auto-generated id/timestamps
  → Drift notifies table change
  → watchAll streams auto-emit updated results
  → Builders update
```

## State Changes

### ModuleViewerLoaded

Add:
```dart
final Map<String, List<Map<String, dynamic>>> queryResults;  // default: {}
```

### ModuleViewerState events

Add:
```dart
class ModuleViewerQueryResultsUpdated extends ModuleViewerEvent {
  final Map<String, List<Map<String, dynamic>>> results;
}
```

## BLoC Changes

### _onStarted

```
if module.database != null:
  create QueryExecutor(db, module.database.tableNames.values)
  create MutationExecutor(db, module.database.tableNames.values)
  parse initial screen's queries
  subscribe to watchAll(queries, resolvedParams)
else:
  existing EntryRepository.watchEntries() path (unchanged)
```

### _onScreenChanged

```
if SQL module:
  cancel previous query subscription
  parse new screen's queries + mutations
  resolve params from new screenParams
  subscribe to watchAll(queries, resolvedParams)
```

### _onScreenParamChanged

```
if SQL module:
  re-resolve params from updated screenParams
  re-subscribe watchAll with new params
```

### _onFormSubmitted

```
if SQL module:
  if editing (has _entryId): MutationExecutor.update(mutation, id, formValues)
  else: MutationExecutor.create(mutation, formValues)
  navigate back (watchAll auto-updates)
else:
  existing EntryRepository path (unchanged)
```

### _onEntryDeleted

```
if SQL module:
  MutationExecutor.delete(mutation, id)
  (watchAll auto-updates, no manual state changes needed)
else:
  existing path
```

## RenderContext Changes

Add:
```dart
final Map<String, List<Map<String, dynamic>>> queryResults;  // default: {}
```

No other changes — all existing callbacks stay the same.

## Builder Changes

### entry_list_builder

If `source` property exists on the node:
- Read rows from `ctx.queryResults[source]` instead of `ctx.entries`
- Each row is already a `Map<String, dynamic>` — set as `formValues` in child RenderContext
- Skip client-side filtering/sorting (SQL already handled it)
- Keep pagination logic (LIMIT in SQL, "load more" adjusts LIMIT param)

If no `source` — existing `ctx.entries` path (backward compatible).

### stat_card_builder

If `source` + `valueKey` properties exist:
- Read `ctx.queryResults[source]?[0]?[valueKey]` directly
- No ExpressionEvaluator needed

If no `source` — existing expression evaluation path (backward compatible).

### chart_builder

If `source` property exists:
- Read grouped data from `ctx.queryResults[source]`
- Each row has group key + value columns
- Map to chart data series

If no `source` — existing path.

### form_screen_builder

No changes needed. Form submit still calls `ctx.onFormSubmit()` → BLoC handles routing to MutationExecutor.

### All other builders

Unchanged.

## Param Resolution

Utility function to resolve `{{filters.X}}` expressions from screenParams:

```dart
Map<String, Object> resolveQueryParams(
  List<ScreenQuery> queries,
  Map<String, dynamic> screenParams,
) {
  // For each query's params map:
  //   "category": "{{filters.category}}" → screenParams['category'] ?? query.defaults['category']
}
```

Pattern: `{{filters.<key>}}` → look up `screenParams[key]`.

## Backward Compatibility

- Modules without `database` field → entirely unchanged
- Builders without `source` field → read from `ctx.entries` as before
- ExpressionEvaluator → still used for non-SQL screens
- PostSubmitEffectExecutor → only used for non-SQL modules (SQL modules use triggers)

## What This Phase Does NOT Change

- Blueprint parsing (BlueprintParser, BlueprintNode types)
- Widget registry dispatch
- Navigation stack, screen transitions
- Form value management
- SchemaManager / ModuleDatabase (Phase 1)
- QueryExecutor / MutationExecutor (Phase 2)
- Non-database modules
