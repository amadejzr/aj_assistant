# Capabilities Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Redesign capabilities from module-owned entities to app-level services, starting with Reminders — with a dedicated Reminders page, home screen section, and module bell icon.

**Architecture:** Capabilities become app-level with nullable `moduleId`. The `CapabilitiesBloc` supports both global and filtered modes. Home screen shows upcoming reminders. A new `/reminders` route replaces the old `/module/:moduleId/capabilities`.

**Tech Stack:** Flutter, Drift (SQLite), flutter_bloc, go_router, phosphor_flutter, flutter_local_notifications

---

### Task 1: Remove template capability integration

Remove capabilities from templates — users add reminders manually.

**Files:**
- Modify: `lib/features/blueprint/models/blueprint_template.dart` — remove `BpCapability` sealed class and all subclasses, remove `capabilities` field from `BpTemplate`
- Modify: `lib/core/models/module_template.dart` — remove `capabilities` field
- Modify: `lib/features/marketplace/bloc/marketplace_bloc.dart` — remove capability installation loop
- Modify: `scripts/templates/finance_template.dart` — remove `capabilities` key

**Step 1: Remove BpCapability from blueprint_template.dart**

Delete lines 335-480 (the entire `// ─── Capabilities ───` section including `BpCapability`, `BpScheduledReminder`, `BpDeadlineReminder`, `BpStreakNudge`).

Remove `capabilities` field from `BpTemplate` class:
- Remove `final List<BpCapability> capabilities;` (line 36)
- Remove `this.capabilities = const [],` from constructor (line 54)
- Remove `'capabilities': [for (final c in capabilities) c.toJson()],` from `toJson()` (line 74)
- Remove `capabilities,` from `props` (line 98)

**Step 2: Remove capabilities from ModuleTemplate**

In `lib/core/models/module_template.dart`:
- Remove `final List<Map<String, dynamic>> capabilities;` field (line 26)
- Remove `this.capabilities = const [],` from constructor (line 46)
- Remove capabilities parsing from `fromFirestore` (lines 78-81)
- Remove `'capabilities': capabilities,` from `toFirestore()` (line 105)
- Remove `capabilities,` from `props` (line 168)
- Remove `capabilities: t.capabilities,` from `MarketplaceBloc._onInstalled` rebuild (line 163)

**Step 3: Remove capability installation from MarketplaceBloc**

In `lib/features/marketplace/bloc/marketplace_bloc.dart`:
- Remove imports: `../../capabilities/models/capability.dart`, `../../capabilities/repositories/capability_repository.dart`, `../../capabilities/services/notification_scheduler.dart`
- Remove fields: `capabilityRepository`, `notificationScheduler` from constructor and class
- Remove the capability creation loop in `_onInstalled` (lines 119-133)

**Step 4: Remove capabilities from finance template**

In `scripts/templates/finance_template.dart`:
- Delete lines 55-78 (the `'capabilities': [...]` section)

**Step 5: Remove bell icon navigation to _capabilities in finance template**

In `scripts/templates/finance_template.dart`, in the `main` screen `appBar.actions`, remove the bell icon action (lines 348-353):
```dart
{
  'type': 'icon_button',
  'icon': 'bell',
  'tooltip': 'Reminders',
  'action': {'type': 'navigate', 'screen': '_capabilities'},
},
```

**Step 6: Commit**

```bash
git add -A && git commit -m "refactor: remove capability auto-install from templates"
```

---

### Task 2: Make moduleId nullable in Capability model and DB

**Files:**
- Modify: `lib/features/capabilities/models/capability.dart`
- Modify: `lib/core/database/tables.dart`
- Modify: `lib/core/database/app_database.dart`
- Modify: `lib/features/capabilities/repositories/drift_capability_repository.dart`
- Modify: `test/features/capabilities/models/capability_test.dart`

**Step 1: Update Capability sealed class**

In `lib/features/capabilities/models/capability.dart`:
- Change `final String moduleId;` → `final String? moduleId;` (line 7)
- Update `toJson()`: change `'moduleId': moduleId,` → `if (moduleId != null) 'moduleId': moduleId,`
- In `fromJson`: change `final moduleId = json['moduleId'] as String;` → `final moduleId = json['moduleId'] as String?;`
- In all three subclass constructors (`ScheduledReminder`, `DeadlineReminder`, `StreakNudge`), `super.moduleId` is already required — keep it but the type now accepts null

**Step 2: Update Drift table**

In `lib/core/database/tables.dart`, line 46:
- Change `TextColumn get moduleId => text().references(Modules, #id)();`
- To `TextColumn get moduleId => text().nullable()();`

(Remove the foreign key reference since moduleId is now optional)

**Step 3: Bump schema version and add migration**

In `lib/core/database/app_database.dart`:
- Change `int get schemaVersion => 2;` → `int get schemaVersion => 3;`
- Add migration for `from < 3`: alter the `moduleId` column to be nullable. Since Drift/SQLite doesn't support ALTER COLUMN easily, the migration should recreate the table:

```dart
if (from < 3) {
  // SQLite doesn't support ALTER COLUMN to nullable,
  // so we recreate the capabilities table.
  await m.deleteTable('capabilities');
  await m.createTable(capabilities);
}
```

**Step 4: Update DriftCapabilityRepository**

In `lib/features/capabilities/repositories/drift_capability_repository.dart`:
- In `createCapability` (line 50): change `moduleId: capability.moduleId,` → `moduleId: Value(capability.moduleId),` since it's now nullable
- In `_rowToCapability` (line 111): the `moduleId` in the JSON map is already handled since it can be null

**Step 5: Update tests**

In `test/features/capabilities/models/capability_test.dart`:
- Add a test for null moduleId:

```dart
test('supports null moduleId', () {
  final json = {
    'type': 'scheduled',
    'title': 'Drink water', 'message': 'Stay hydrated',
    'enabled': true,
    'config': {'frequency': 'daily', 'hour': 10, 'minute': 0},
    'createdAt': 1704067200000, 'updatedAt': 1704067200000,
  };
  final cap = Capability.fromJson('cap_null', json);
  expect(cap.moduleId, isNull);
  expect(cap.toJson().containsKey('moduleId'), isFalse);
});
```

**Step 6: Run tests**

```bash
cd /Users/jerlah/Developer/projects/aj_assistant && flutter test test/features/capabilities/
```

**Step 7: Regenerate Drift code**

```bash
cd /Users/jerlah/Developer/projects/aj_assistant && dart run build_runner build --delete-conflicting-outputs
```

**Step 8: Commit**

```bash
git add -A && git commit -m "refactor: make capability moduleId nullable for app-level reminders"
```

---

### Task 3: Add global query methods to repository

**Files:**
- Modify: `lib/features/capabilities/repositories/capability_repository.dart`
- Modify: `lib/features/capabilities/repositories/drift_capability_repository.dart`

**Step 1: Add interface methods**

In `lib/features/capabilities/repositories/capability_repository.dart`, add:

```dart
Stream<List<Capability>> watchAllCapabilities();
Stream<List<Capability>> watchEnabledCapabilities({int? limit});
```

**Step 2: Implement in DriftCapabilityRepository**

In `lib/features/capabilities/repositories/drift_capability_repository.dart`, add:

```dart
@override
Stream<List<Capability>> watchAllCapabilities() {
  final query = _db.select(_db.capabilities)
    ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
  return query.watch().map((rows) => rows.map(_rowToCapability).toList());
}

@override
Stream<List<Capability>> watchEnabledCapabilities({int? limit}) {
  final query = _db.select(_db.capabilities)
    ..where((t) => t.enabled.equals(true))
    ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
  if (limit != null) query.limit(limit);
  return query.watch().map((rows) => rows.map(_rowToCapability).toList());
}
```

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add global capability query methods to repository"
```

---

### Task 4: Update CapabilitiesBloc for global and filtered modes

**Files:**
- Modify: `lib/features/capabilities/bloc/capabilities_event.dart`
- Modify: `lib/features/capabilities/bloc/capabilities_state.dart`
- Modify: `lib/features/capabilities/bloc/capabilities_bloc.dart`

**Step 1: Update events**

In `lib/features/capabilities/bloc/capabilities_event.dart`:
- Make `moduleId` optional in `CapabilitiesStarted`:

```dart
class CapabilitiesStarted extends CapabilitiesEvent {
  final String? moduleId;

  const CapabilitiesStarted({this.moduleId});

  @override
  List<Object?> get props => [moduleId];
}
```

**Step 2: Update state**

In `lib/features/capabilities/bloc/capabilities_state.dart`:
- Make `moduleId` optional in `CapabilitiesLoaded`:

```dart
class CapabilitiesLoaded extends CapabilitiesState {
  final List<Capability> capabilities;
  final String? moduleId;

  const CapabilitiesLoaded({
    required this.capabilities,
    this.moduleId,
  });

  @override
  List<Object?> get props => [capabilities, moduleId];
}
```

**Step 3: Update BLoC to support global mode**

In `lib/features/capabilities/bloc/capabilities_bloc.dart`:
- In `_onStarted`, choose stream based on moduleId:

```dart
Future<void> _onStarted(
  CapabilitiesStarted event,
  Emitter<CapabilitiesState> emit,
) async {
  _moduleId = event.moduleId;
  emit(const CapabilitiesLoading());
  _sub?.cancel();
  final stream = event.moduleId != null
      ? capabilityRepository.watchCapabilities(event.moduleId!)
      : capabilityRepository.watchAllCapabilities();
  _sub = stream.listen((caps) => add(CapabilitiesUpdated(caps)));
}
```

**Step 4: Commit**

```bash
git add -A && git commit -m "feat: support global and filtered modes in CapabilitiesBloc"
```

---

### Task 5: Create RemindersScreen

**Files:**
- Create: `lib/features/capabilities/screens/reminders_screen.dart`
- Delete content of: `lib/features/capabilities/screens/capabilities_screen.dart` (replace with redirect or remove)

**Step 1: Create RemindersScreen**

Create `lib/features/capabilities/screens/reminders_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/module_repository.dart';
import '../../../core/models/module.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/widgets/paper_background.dart';
import '../bloc/capabilities_bloc.dart';
import '../bloc/capabilities_event.dart';
import '../bloc/capabilities_state.dart';
import '../models/capability.dart';
import '../repositories/capability_repository.dart';
import '../services/notification_scheduler.dart';
import '../widgets/capability_card.dart';

class RemindersScreen extends StatelessWidget {
  final String? moduleId;

  const RemindersScreen({super.key, this.moduleId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CapabilitiesBloc(
        capabilityRepository: context.read<CapabilityRepository>(),
        notificationScheduler: context.read<NotificationScheduler>(),
      )..add(CapabilitiesStarted(moduleId: moduleId)),
      child: _RemindersBody(moduleId: moduleId),
    );
  }
}

class _RemindersBody extends StatelessWidget {
  final String? moduleId;

  const _RemindersBody({this.moduleId});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Stack(
      children: [
        PaperBackground(colors: colors),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              moduleId != null ? 'Module Reminders' : 'Reminders',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colors.onBackground,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                color: colors.onBackground,
              ),
              onPressed: () => context.pop(),
            ),
          ),
          body: BlocBuilder<CapabilitiesBloc, CapabilitiesState>(
            builder: (context, state) {
              return switch (state) {
                CapabilitiesInitial() ||
                CapabilitiesLoading() =>
                  const Center(child: CircularProgressIndicator()),
                CapabilitiesError(:final message) =>
                  Center(child: Text(message)),
                CapabilitiesLoaded(:final capabilities) =>
                  capabilities.isEmpty
                      ? _buildEmptyState(context, colors)
                      : _buildGroupedList(context, colors, capabilities),
              };
            },
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: colors.accent,
            onPressed: () {
              // TODO: Task 6 — open AddReminderSheet
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.bellSlash(PhosphorIconsStyle.light),
            size: 56,
            color: colors.onBackgroundMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No reminders yet',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onBackgroundMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap + to create your first reminder',
            style: TextStyle(
              fontFamily: 'Karla',
              fontSize: 13,
              color: colors.onBackgroundMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    AppColors colors,
    List<Capability> capabilities,
  ) {
    // Group by moduleId (null = "General")
    final grouped = <String?, List<Capability>>{};
    for (final cap in capabilities) {
      grouped.putIfAbsent(cap.moduleId, () => []).add(cap);
    }

    final entries = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final group = entries[index];
        return _ReminderGroup(
          moduleId: group.key,
          capabilities: group.value,
        );
      },
    );
  }
}

class _ReminderGroup extends StatelessWidget {
  final String? moduleId;
  final List<Capability> capabilities;

  const _ReminderGroup({
    required this.moduleId,
    required this.capabilities,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GroupHeader(moduleId: moduleId),
        const SizedBox(height: AppSpacing.sm),
        ...capabilities.map((cap) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Dismissible(
                key: ValueKey(cap.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: colors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  context
                      .read<CapabilitiesBloc>()
                      .add(CapabilityDeleted(cap.id));
                },
                child: CapabilityCard(
                  capability: cap,
                  onToggle: (enabled) {
                    context.read<CapabilitiesBloc>().add(
                          CapabilityToggled(cap.id, enabled: enabled),
                        );
                  },
                ),
              ),
            )),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String? moduleId;

  const _GroupHeader({this.moduleId});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (moduleId == null) {
      return Text(
        'General',
        style: TextStyle(
          fontFamily: 'Karla',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: colors.onBackgroundMuted,
        ),
      );
    }

    // Look up module name from repository
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Module?>(
      future: context
          .read<ModuleRepository>()
          .getModule(authState.user.uid, moduleId!),
      builder: (context, snapshot) {
        final name = snapshot.data?.name ?? moduleId!;
        return Text(
          name,
          style: TextStyle(
            fontFamily: 'Karla',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: colors.onBackgroundMuted,
          ),
        );
      },
    );
  }
}
```

**Step 2: Delete old capabilities_screen.dart**

Delete `lib/features/capabilities/screens/capabilities_screen.dart`.

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: create RemindersScreen with grouped list and swipe-to-delete"
```

---

### Task 6: Create AddReminderSheet

**Files:**
- Create: `lib/features/capabilities/widgets/add_reminder_sheet.dart`
- Modify: `lib/features/capabilities/screens/reminders_screen.dart` — wire up FAB

**Step 1: Create AddReminderSheet**

Create `lib/features/capabilities/widgets/add_reminder_sheet.dart` — a bottom sheet with:
- Title text field
- Message text field
- Frequency picker (daily/weekly/monthly)
- Time picker
- Optional module selector (dropdown of user's modules)
- Save button that creates a `ScheduledReminder` and dispatches `CapabilityCreated`

Use `showModalBottomSheet` with the sumi ink aesthetic (surface color, CormorantGaramond header, Karla inputs).

**Step 2: Wire up FAB in RemindersScreen**

Replace the TODO in `reminders_screen.dart` FAB `onPressed` with:

```dart
onPressed: () => showAddReminderSheet(
  context,
  moduleId: moduleId,
),
```

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add AddReminderSheet bottom sheet for creating reminders"
```

---

### Task 7: Update routing

**Files:**
- Modify: `lib/app_router.dart`
- Modify: `lib/features/module_viewer/screens/module_viewer_screen.dart`

**Step 1: Update routes**

In `lib/app_router.dart`:
- Replace import of `capabilities_screen.dart` with `reminders_screen.dart`
- Remove the `/module/:moduleId/capabilities` sub-route (lines 132-140)
- Add new top-level `/reminders` route:

```dart
GoRoute(
  path: '/reminders',
  pageBuilder: (context, state) {
    final moduleId = state.uri.queryParameters['module'];
    return _pageFadeSlide(
      key: state.pageKey,
      child: RemindersScreen(moduleId: moduleId),
    );
  },
),
```

**Step 2: Update ModuleViewerScreen navigation**

In `lib/features/module_viewer/screens/module_viewer_screen.dart`:
- Change the `_capabilities` navigation handler (line 127-129):

```dart
if (screenId == '_capabilities') {
  context.push('/reminders?module=${state.module.id}');
  return;
}
```

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add /reminders route, remove /module/:moduleId/capabilities"
```

---

### Task 8: Add upcoming reminders section to HomeScreen

**Files:**
- Create: `lib/features/home/widgets/upcoming_reminders_section.dart`
- Modify: `lib/features/home/home_screen.dart`

**Step 1: Create UpcomingRemindersSection widget**

Create `lib/features/home/widgets/upcoming_reminders_section.dart`:

A widget that uses `StreamBuilder` with `capabilityRepository.watchEnabledCapabilities(limit: 3)` to show up to 3 enabled reminders as compact cards. Includes a "See all" link that navigates to `/reminders`. Hidden when no reminders exist (returns `SizedBox.shrink()`).

Each compact card shows: type icon, title, and schedule description (reuse the description logic from `CapabilityCard`).

**Step 2: Add section to HomeScreen**

In `lib/features/home/home_screen.dart`, inside the `ModulesListLoaded` branch (around line 124-128), add the `UpcomingRemindersSection` between the modules grid and the marketplace card:

```dart
SliverToBoxAdapter(
  child: UpcomingRemindersSection(),
),
```

**Step 3: Commit**

```bash
git add -A && git commit -m "feat: add upcoming reminders section to home screen"
```

---

### Task 9: Update MarketplaceBloc constructor references

**Files:**
- Modify: `lib/features/marketplace/screens/marketplace_screen.dart` (or wherever MarketplaceBloc is created)
- Modify: `lib/features/marketplace/screens/template_detail_screen.dart`

**Step 1: Update BlocProvider creation sites**

Find where `MarketplaceBloc` is instantiated and remove the `capabilityRepository` and `notificationScheduler` parameters that were removed in Task 1.

**Step 2: Verify build**

```bash
cd /Users/jerlah/Developer/projects/aj_assistant && flutter build ios --no-codesign 2>&1 | tail -20
```

**Step 3: Commit**

```bash
git add -A && git commit -m "fix: update MarketplaceBloc instantiation after capability removal"
```

---

### Task 10: Run tests and verify

**Step 1: Run all capability tests**

```bash
cd /Users/jerlah/Developer/projects/aj_assistant && flutter test test/features/capabilities/
```

**Step 2: Run full test suite**

```bash
cd /Users/jerlah/Developer/projects/aj_assistant && flutter test
```

**Step 3: Verify app builds**

```bash
cd /Users/jerlah/Developer/projects/aj_assistant && flutter build ios --no-codesign
```

**Step 4: Final commit if any fixes needed**

```bash
git add -A && git commit -m "fix: resolve test/build issues from capabilities redesign"
```
