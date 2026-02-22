# Dynamic Module Tables — Design

## Problem

All module entry data lives in a single `entries` table as a JSON blob (`data` column). SQLite has zero visibility into field values. Every aggregation (SUM, AVG, GROUP BY), filter, and sort happens in Dart over up to 500 entries fetched into memory. This causes:

1. **Performance**: Screens with multiple stat cards/charts iterate all 500 entries per widget per rebuild
2. **Scalability**: Hard 500-entry cap silently drops older data from all calculations
3. **Flexibility**: Widgets can't declare what data they need — they all get the same 500-entry dump

## Solution

Each module gets its own typed SQLite table with real columns. Blueprint widgets declare SQL query specs. SQLite handles all aggregation, filtering, sorting, and pagination natively. Per-screen query batching minimizes database reads.

## Architecture

### Per-Module Typed Tables

When a module is created (via AI chat or marketplace install), a `SchemaManager` generates a real SQLite table:

```sql
CREATE TABLE "m_expenses_a1b2" (
  id TEXT PRIMARY KEY,
  schema_key TEXT NOT NULL,
  amount REAL,
  category TEXT,
  date INTEGER,
  notes TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX "idx_m_expenses_a1b2_category" ON "m_expenses_a1b2" (category);
CREATE INDEX "idx_m_expenses_a1b2_date" ON "m_expenses_a1b2" (date);
```

Table name format: `m_{sanitized_name}_{short_hash}`. Stored on the module record.

**Type mapping from FieldType:**

| FieldType | SQL Type |
|---|---|
| text | TEXT |
| number, currency, slider, rating | REAL |
| date | INTEGER (epoch ms) |
| enum_ | TEXT |
| toggle | INTEGER (0/1) |
| reference | TEXT (FK to another module's table) |

### Dual-Write Strategy

The `entries` table with its JSON blob stays as the **source of truth for recovery**. Every entry create/update writes to both:

1. `entries` table — JSON blob (via Drift, unchanged)
2. Module typed table — typed columns (via raw SQL)

If the typed table needs rebuilding after a complex schema change, reconstruct from JSON blobs.

### SchemaManager

Handles all DDL for module tables:

```dart
class SchemaManager {
  Future<String> createModuleTable(Module module);
  Future<void> addColumn(String tableName, FieldDefinition field);
  Future<void> renameColumn(String tableName, String oldKey, String newKey);
  Future<void> rebuildTable(Module module);
  Future<void> dropModuleTable(String tableName);
}
```

**Schema evolution when AI updates a module:**

| Change | Strategy |
|---|---|
| Add field | `ALTER TABLE ADD COLUMN` |
| Remove field | Column stays with NULLs, or rebuild |
| Rename field | `ALTER TABLE RENAME COLUMN` (SQLite 3.25+) |
| Type change | Rebuild table from JSON blobs |

### SchemaRegistry

Knows all module table names and their columns. Used by `QueryBuilder` for validation and by `SchemaManager` for diff-based migrations:

```dart
class SchemaRegistry {
  Map<String, TableSchema> getRegisteredTables();
  TableSchema? getTableForModule(String moduleId);
  bool isValidColumn(String tableName, String columnName);
}
```

### Blueprint Query Specs

Widgets declare what data they need via a `query` property:

**Aggregate (stat_card, progress_bar):**
```json
{
  "type": "stat_card",
  "label": "Total Food Expenses",
  "query": {
    "type": "aggregate",
    "aggregate": "SUM",
    "field": "amount",
    "where": [
      {"field": "category", "op": "=", "value": "Food"},
      {"field": "date", "op": ">=", "value": "$startOfMonth"}
    ]
  }
}
```
Generates: `SELECT SUM(amount) FROM m_expenses_a1b2 WHERE category = ? AND date >= ?`

**Group-by (chart):**
```json
{
  "type": "chart",
  "query": {
    "type": "group",
    "groupBy": "category",
    "aggregate": "SUM",
    "field": "amount"
  }
}
```
Generates: `SELECT category, SUM(amount) AS value FROM m_expenses_a1b2 GROUP BY category`

**Entries with real pagination (entry_list):**
```json
{
  "type": "entry_list",
  "query": {
    "type": "entries",
    "where": [{"field": "category", "op": "=", "value": "{{selectedCategory}}"}],
    "orderBy": "date",
    "descending": true,
    "limit": 20
  }
}
```
Generates: `SELECT * FROM m_expenses_a1b2 WHERE category = ? ORDER BY date DESC LIMIT 20 OFFSET ?`

### Cross-Module References

A "reference" field type enables JOINs between module tables:

```json
{
  "type": "entry_list",
  "query": {
    "type": "entries",
    "join": {
      "module": "categories",
      "on": {"field": "category_id", "foreignField": "id"},
      "select": ["name AS category_name", "color"]
    },
    "orderBy": "date"
  }
}
```
Generates: `SELECT e.*, c.name AS category_name, c.color FROM m_expenses_a1b2 e JOIN m_categories_d4e5 c ON e.category_id = c.id ORDER BY e.date DESC`

### QueryBuilder + Safety

Translates query specs into parameterized SQL:

```dart
class QueryBuilder {
  QueryResult build(QuerySpec spec, SchemaRegistry registry);
}

class QueryResult {
  final String sql;
  final List<Variable> parameters;
}
```

**Safety**: All table/column names validated against `SchemaRegistry`. All values use SQL parameters (`?`), never string interpolation.

### QueryRepository

Executes queries against module typed tables:

```dart
abstract class QueryRepository {
  Future<double?> aggregate({
    required String moduleId,
    required String aggregate,
    required String field,
    List<QueryFilter>? where,
  });

  Future<Map<String, double>> groupBy({
    required String moduleId,
    required String groupField,
    required String aggregate,
    required String aggregateField,
    List<QueryFilter>? where,
  });

  Future<List<Entry>> queryEntries({
    required String moduleId,
    List<QueryFilter>? where,
    String? orderBy,
    bool descending,
    int? limit,
    int? offset,
  });

  Stream<List<Entry>> watchEntries({
    required String moduleId,
    List<QueryFilter>? where,
    String? orderBy,
    bool descending,
    int? limit,
  });

  Future<int> count({
    required String moduleId,
    List<QueryFilter>? where,
  });
}
```

### Per-Screen Transaction Batching

All queries for a screen execute in a single Drift `transaction()` block — one database round trip per screen:

```dart
await db.transaction(() async {
  final totalSpent = await queryRepo.aggregate(SUM, 'amount', ...);
  final byCategory = await queryRepo.groupBy('category', SUM, 'amount', ...);
  final recentEntries = await queryRepo.queryEntries(orderBy: 'date', limit: 5);
  return ScreenQueryResults(totalSpent, byCategory, recentEntries);
});
```

The `QueryCollector` walks the current screen's blueprint, collects all `query` specs, and the BLoC batch-executes them in one transaction.

### Reactive Live Updates (Single-Stream Pattern)

Instead of one `.watch()` per widget query (N streams → N rebuilds), use a **single table watcher** per module. When the table changes, batch-execute all screen queries in one transaction and emit once:

```dart
// ONE watcher for the whole screen
db.customSelect(
  'SELECT 1 FROM "m_expenses_a1b2" LIMIT 1',
  readsFrom: {db.rawTableByName('m_expenses_a1b2')},
).watch()
  .debounceTime(Duration(milliseconds: 50))  // collapse rapid writes
  .listen((_) async {
    // Table changed — run ALL screen queries in one transaction
    final results = await db.transaction(() async {
      return {
        'total_month': await queryRepo.aggregate(SUM, 'amount', ...),
        'by_category': await queryRepo.groupBy('category', SUM, ...),
        'recent': await queryRepo.queryEntries(limit: 5, ...),
      };
    });
    // ONE state emission → ONE rebuild
    emit(state.copyWith(queryResults: results));
  });

// Write: after INSERT/UPDATE/DELETE, notify Drift
await db.customStatement('INSERT INTO "m_expenses_a1b2" ...');
db.markTablesUpdated({'m_expenses_a1b2'});
```

**Rebuild optimization**: ONE table change → debounce 50ms → ONE transaction → ONE emit → Flutter widget diffing only repaints widgets whose values actually changed. A stat card receiving the same value as before skips re-render automatically.

### BLoC Integration

`ModuleViewerBloc` changes:

1. `QueryCollector` walks current screen's blueprint, collects all `query` specs
2. BLoC subscribes to a single table watcher (not per-query)
3. On table change: batch-executes all queries in one transaction via `QueryRepository`
4. Results stored in state as `queryResults: Map<String, dynamic>`
5. Widgets read from `queryResults` (same pattern as current `resolvedExpressions`)

**Per-screen optimization**: When user navigates between screens, the BLoC drops the old watcher and query set, starts new ones. Each screen gets exactly the data it needs.

**Minimal rebuilds**: State uses `Equatable`. If query results haven't changed, no emit. If they have, Flutter's element tree reconciliation only repaints widgets with new values.

### Triggers and Advanced SQLite

`SchemaManager` can also auto-generate per module:

- **Triggers**: auto-update `updated_at` timestamps, cascading deletes for references
- **Views**: pre-defined aggregation views
- **Generated columns**: computed fields (SQLite 3.31+)

All via `customStatement()` — anything SQLite supports.

### Module Deletion

Atomic cleanup in a single transaction:

```sql
DROP TABLE IF EXISTS "m_expenses_a1b2";
DELETE FROM entries WHERE module_id = ?;
DELETE FROM capabilities WHERE module_id = ?;
DELETE FROM modules WHERE id = ?;
```

### Module Install (Marketplace or AI Chat)

Both paths are identical:

1. Module definition received (schema + screens + blueprint with query specs)
2. `ModuleRepository.createModule()` saves the module record
3. `SchemaManager.createModuleTable()` generates CREATE TABLE + indices
4. Module is fully functional — no app update needed

## Data Flow: Before vs After

**Before:**
```
SQLite → SELECT * FROM entries LIMIT 500 → 500 entries in memory
→ ExpressionEvaluator iterates all per expression → Widget
```

**After:**
```
stat_card:  SQLite → SELECT SUM(amount) WHERE ... → scalar → Widget
chart:      SQLite → SELECT category, SUM(amount) GROUP BY ... → map → Widget
entry_list: SQLite → SELECT * WHERE ... ORDER BY ... LIMIT 20 → page → Widget
All in one transaction per screen. Reactive via .watch().
```

## Backwards Compatibility

- `entries` table with JSON blob stays (source of truth + recovery)
- `ExpressionEvaluator` stays as fallback for widgets without `query` specs
- New widgets prefer `query` → SQL path
- AI gradually migrates blueprints from expressions to query specs

## Migration Strategy

One-time Drift database migration (v3 → v4):

1. Add `table_name` column to `modules` table
2. For each existing module: generate typed table from schema, backfill from JSON blobs
3. Set up `SchemaManager` infrastructure

After that, all DDL is automatic — driven by module creation/update/deletion.

## Future Extensions (Not In Scope)

- **External data sources (RPi, IoT, APIs)**: External devices push data to Firebase → Cloud Function or app sync writes into the module's typed table via the same INSERT path. The single-stream watcher picks it up automatically. No architectural changes needed — just another write path.
- **Firebase sync**: Bidirectional sync between local typed tables and Firestore collections. The typed table structure maps naturally to Firestore documents.
- **Cross-module computed views**: SQL VIEWs that aggregate across multiple module tables.
