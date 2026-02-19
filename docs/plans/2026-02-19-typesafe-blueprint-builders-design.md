# Type-Safe Blueprint Builders Design

## Goal

Replace raw `Map<String, dynamic>` screen construction with a sealed class hierarchy that provides compile-time safety, IDE autocomplete, and testable `toJson()` output. Add a typed `ModuleNavigation` model for bottom navigation and drawer. Optimize the module viewer to keep tab screens alive instead of rebuilding on every navigation.

## Scope

**In scope (this pass):**
- `Blueprint` sealed class hierarchy for layout nodes (screen, form_screen, tab_screen, scroll_column, section, row, column, expandable)
- `BlueprintAction` sealed class for actions (navigate, submit, delete, etc.)
- `ModuleNavigation` model (BottomNav, DrawerNav, NavItem) on Module
- Navigation-aware module viewer with IndexedStack for bottom nav
- `RawBlueprint` escape hatch for uncovered node types
- Fab and Button builders (needed by layout)
- Unit tests for all `toJson()` methods
- Migration of existing templates to use typed builders

**Out of scope (later passes):**
- Input node builders (text_input, number_input, etc.)
- Display node builders (stat_card, entry_list, chart, etc.)
- Cloud Functions / TypeScript builders

## Architecture

### 1. Blueprint Sealed Class Hierarchy

```
Blueprint (sealed)
  ├── Screen          → { type: 'screen', title, children, fab }
  ├── FormScreen      → { type: 'form_screen', title, submitLabel, defaults, children }
  ├── TabScreen       → { type: 'tab_screen', title, tabs, fab }
  ├── ScrollColumn    → { type: 'scroll_column', children }
  ├── Section         → { type: 'section', title, children }
  ├── BpRow           → { type: 'row', children }
  ├── BpColumn        → { type: 'column', children }
  ├── Expandable      → { type: 'expandable', title, children }
  ├── Fab             → { type: 'fab', icon, action }
  ├── Button          → { type: 'button', label, action, style, icon }
  └── RawBlueprint    → passthrough for uncovered node types
```

Class names avoid Dart conflicts: `BpRow` and `BpColumn` instead of `Row`/`Column` (Flutter widgets). `RawBlueprint` wraps raw `Map<String, dynamic>` for incremental migration.

All classes are `const`-constructible and extend `Equatable` for testability.

### 2. BlueprintAction Sealed Class

```
BlueprintAction (sealed)
  ├── NavigateAction      → { type: 'navigate', screen, params }
  ├── NavigateBackAction  → { type: 'navigate_back' }
  ├── SubmitAction        → { type: 'submit' }
  ├── DeleteEntryAction   → { type: 'delete_entry', confirm }
  ├── ShowFormSheetAction → { type: 'show_form_sheet', screen, title }
  └── RawAction           → passthrough for uncovered action types
```

### 3. Supporting Types

```dart
class TabDef extends Equatable {
  final String label;
  final String icon;
  final Blueprint content;
  // toJson()
}
```

### 4. ModuleNavigation Model

```dart
class ModuleNavigation extends Equatable {
  final BottomNav? bottomNav;
  final DrawerNav? drawer;
  // toJson() / fromJson()
}

class BottomNav extends Equatable {
  final List<NavItem> items;  // 2-5 items
}

class DrawerNav extends Equatable {
  final List<NavItem> items;
  final String? header;
}

class NavItem extends Equatable {
  final String label;
  final String icon;
  final String screenId;  // references module.screens key
}
```

Added to `Module` as:
```dart
final ModuleNavigation? navigation;  // null = legacy flat screens
```

**Backward compatibility:** When `navigation` is null, behavior is identical to today. Templates and Firestore data without a `navigation` field continue to work unchanged.

### 5. File Layout

```
lib/features/blueprint/
  models/
    blueprint.dart              ← Blueprint sealed class + all subtypes
    blueprint_action.dart       ← BlueprintAction sealed class
  navigation/
    module_navigation.dart      ← ModuleNavigation, BottomNav, DrawerNav, NavItem
```

### 6. Performance: Navigation-Aware Module Viewer

**Current behavior (problem):** Every `ModuleViewerScreenChanged` event re-parses the screen JSON, rebuilds the entire widget tree, and re-resolves expressions. Navigating between tabs destroys and recreates everything.

**New behavior with bottom nav:**

When a module has `navigation.bottomNav`:

1. **IndexedStack** holds all bottom nav screens simultaneously. Only the active tab is visible, but all tabs stay alive in the widget tree. Switching tabs = changing the active index. Zero rebuilds.

2. **Parsed node cache** in the BLoC state: `Map<String, BlueprintNode>` keyed by screenId. Parse once, reuse forever (invalidated only if the module definition changes).

3. **Per-screen expression cache**: `Map<String, Map<String, dynamic>>` — each screen's resolved expressions are cached independently. Only recomputed when entries change, not on tab switch.

4. **Stack-based navigation within a tab**: Each bottom nav tab has its own screen stack. Navigating to a detail screen within a tab pushes onto that tab's stack. Pressing back pops within the tab. This prevents tab switches from losing navigation state.

**When no bottom nav (backward compat):** Behavior is identical to today — single screen stack with push/pop.

**Drawer:** Opens as a standard Material drawer. Tapping a drawer item navigates to that screen (same as bottom nav item switch or stack push depending on whether the screen is a top-level nav item).

### 7. Module.screens Remains Map<String, dynamic>

Screens are still stored as JSON in Firestore. The type-safe builders produce JSON via `toJson()`. The parser still reads JSON into `BlueprintNode` for rendering. This maintains the clean boundary:

```
Builder (Blueprint) → toJson() → Firestore → fromFirestore → BlueprintParser → BlueprintNode → Widget
```

The builder and parser hierarchies are deliberately separate — builders are for constructing, parsers are for rendering. They don't need to share types.

### 8. Testing Strategy

Every `Blueprint` subclass gets a unit test verifying:
1. `toJson()` produces the correct JSON structure
2. Required fields are present
3. Children are recursively serialized
4. `RawBlueprint` passthrough works

`ModuleNavigation` gets:
1. `toJson()` / `fromJson()` roundtrip tests
2. Backward compat: missing `navigation` field → null
3. Validation: bottom nav needs 2-5 items

Navigation-aware module viewer gets:
1. Bottom nav tab switching doesn't trigger re-parse
2. Per-tab screen stacks work independently
3. Drawer navigation works
4. Backward compat: no navigation field = legacy behavior

### 9. Template Migration

Existing templates (`tasks_template.dart`, `drinks_template.dart`) will be migrated to use the typed builders. Layout nodes become typed, input/display nodes use `RawBlueprint` until those builders are added in a later pass.

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Builder pattern | Sealed classes with toJson() | Same pattern as FieldConstraints/SchemaEffect. Compile-time safety, const-constructible, testable. |
| Navigation config location | Field on Module | Co-located with screens. Single Firestore read. Backward compatible when null. |
| Bottom nav implementation | IndexedStack | All tabs alive = zero rebuild on switch. Standard Flutter pattern. |
| Per-tab stacks | Yes | Each tab maintains its own navigation history. Essential for UX. |
| RawBlueprint escape hatch | Yes | Enables incremental migration. No big-bang rewrite. |
| Class naming | BpRow/BpColumn | Avoids collision with Flutter's Row/Column. |
