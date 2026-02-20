# Local Module Storage with Drift/SQLite

## Goal

Replace `FirestoreModuleRepository` with a local Drift (SQLite) implementation. Modules are stored on-device. Marketplace stays on Firebase. This is step 1 of the full offline migration.

## What Changes

### New Dependencies

```yaml
# pubspec.yaml
dependencies:
  drift: ^2.22.1
  sqlite3_flutter_libs: ^0.5.28
  path_provider: ^2.1.5

dev_dependencies:
  drift_dev: ^2.22.3
  build_runner: ^2.4.14
```

### Database Schema

Single `modules` table:

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | UUID |
| name | TEXT NOT NULL | |
| description | TEXT | Default '' |
| icon | TEXT | Default 'cube' |
| color | TEXT | Default '#D94E33' |
| sort_order | INTEGER | Default 0 |
| schemas | TEXT | JSON-encoded Map<String, ModuleSchema> |
| screens | TEXT | JSON-encoded Map<String, Map<String, dynamic>> |
| settings | TEXT | JSON-encoded Map<String, dynamic> |
| guide | TEXT | JSON-encoded List<Map<String, String>> |
| navigation | TEXT | JSON-encoded ModuleNavigation, nullable |
| version | INTEGER | Default 1 |
| created_at | INTEGER | Unix ms timestamp |
| updated_at | INTEGER | Unix ms timestamp |

### New Files

- `lib/core/database/app_database.dart` - Drift database class with modules table
- `lib/core/database/app_database.g.dart` - Generated code (build_runner)
- `lib/core/repositories/drift_module_repository.dart` - Local implementation of ModuleRepository

### Modified Files

- `pubspec.yaml` - Add drift, sqlite3_flutter_libs, path_provider, drift_dev, build_runner
- `lib/core/models/module.dart` - Add `fromJson(Map)` and rename `toFirestore()` to `toJson()`. Keep `fromFirestore()` since marketplace still uses it indirectly (via ModuleTemplate)
- `lib/main.dart` - Initialize Drift DB, swap `FirestoreModuleRepository` -> `DriftModuleRepository`

### Unchanged

- `ModuleRepository` abstract interface (already clean, no Firestore types in API)
- All BLoCs (ModulesListBloc, MarketplaceBloc, ModuleViewerBloc) - use interface only
- Blueprint rendering, expression engine, UI
- Firebase Auth, MarketplaceRepository

## Module Model Changes

Current `Module` has:
- `fromFirestore(DocumentSnapshot)` - takes Firestore doc, extracts data map
- `toFirestore()` - returns `Map<String, dynamic>`

Add:
- `fromJson(Map<String, dynamic>)` - same parsing logic as fromFirestore but takes a raw map + id
- `toJson()` - alias for current toFirestore() logic

The `fromFirestore` factory can delegate to `fromJson` internally to avoid duplication.

## DriftModuleRepository

Implements `ModuleRepository` with:
- `watchModules(userId)` - Drift's `.watch()` query on modules table, ordered by sort_order. The `userId` param is kept for interface compatibility but is not used (single-user local DB).
- `getModule(userId, moduleId)` - Single row lookup by id
- `createModule(userId, module)` - Insert with current timestamp
- `updateModule(userId, module)` - Update with new timestamp
- `deleteModule(userId, moduleId)` - Delete by id

JSON columns (schemas, screens, settings, guide, navigation) are serialized/deserialized with `dart:convert` in the repository layer.

## Data Flow

```
Marketplace (Firestore) -> getTemplates() -> user taps "Install"
-> template.toModule() -> moduleRepository.createModule()
-> DriftModuleRepository inserts into SQLite
-> watchModules() stream emits updated list
-> ModulesListBloc receives update -> UI re-renders
```

## Key Design Decisions

1. **Single-user DB**: No user_id column needed in tables. One DB per device installation. The `userId` param in repository methods is ignored but kept for interface stability.
2. **JSON columns for dynamic data**: schemas, screens, settings are stored as JSON text. Parsed on read, serialized on write. This matches the document-model nature of this data.
3. **Timestamps as Unix ms integers**: Simpler than DateTime columns in SQLite, easy to compare and sort.
4. **Drift `.watch()` for reactivity**: Provides the same Stream-based API as Firestore's `snapshots()`, so BLoCs work identically.
