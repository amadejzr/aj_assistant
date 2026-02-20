# Capabilities Redesign: App-Level Services

## Summary

Capabilities are app-level features (like Reminders, Calendar, Stats) that exist independently. Modules opt into them — a module doesn't own capabilities, it links to them. Each capability has its own dedicated page showing aggregated data from all connected modules.

V1 scope: Reminders capability only.

## Data Architecture

Capabilities are app-level entities, not module-owned:

```
Capability (app-level, e.g. "Reminders")
  └── Reminder entries, each optionally linked to a moduleId

Module
  └── knows nothing about capabilities directly
```

The existing `Capabilities` Drift table stays. Key change: `moduleId` becomes **nullable** — a reminder can exist without a module (e.g., "Drink water").

The table is queried globally (all reminders) or filtered by moduleId (one module's reminders).

Templates no longer define or install capabilities. Users add reminders manually.

## Navigation & Screens

### Home Screen

New "Upcoming reminders" section between modules grid and marketplace card:
- Shows max 3 enabled reminders as compact cards
- Each card: title, module name, schedule description
- "See all" link navigates to full Reminders page
- Section hidden entirely when no reminders exist

### Reminders Page (`/reminders`)

Full-screen page outside the shell:
- Lists all reminders grouped by module (+ "General" group for module-free reminders)
- Each card: title, message, schedule description, module name, toggle switch
- FAB to add a new reminder
- Swipe or long-press to delete, tap to edit
- Supports `?module={moduleId}` query param for pre-filtered view

### Module Viewer

Bell icon in the app bar → navigates to `/reminders?module={moduleId}` (pre-filtered Reminders page). Can add reminders scoped to that module from there.

### Routes

- `/reminders` — full reminders page
- `/reminders/add` — add/edit reminder (optional `moduleId` query param)
- Remove: `/module/:moduleId/capabilities`

## Code Changes

### Keep as-is
- `Capability` sealed class model (ScheduledReminder, DeadlineReminder, StreakNudge)
- `Capabilities` Drift table definition
- `DriftCapabilityRepository` core CRUD
- `NotificationScheduler` service
- Unit tests for capability model serialization

### Modify
- `CapabilityRepository` — add `watchAllCapabilities()`, `watchUpcoming(int limit)` methods
- `DriftCapabilityRepository` — implement new global query methods
- `CapabilitiesBloc` — support global mode (no moduleId) and filtered mode (with moduleId)
- `HomeScreen` — add "Upcoming reminders" section between modules grid and marketplace card
- `ModuleViewerScreen` — add bell icon in app bar navigating to `/reminders?module={moduleId}`
- `app_router.dart` — add `/reminders` and `/reminders/add` routes, remove `/module/:moduleId/capabilities`
- `Capability` model — make `moduleId` nullable
- `Capabilities` Drift table — make `moduleId` column nullable

### Delete / Remove
- `BpCapability` sealed class from `blueprint_template.dart`
- `capabilities` field from `ModuleTemplate`
- Capability installation logic from `MarketplaceBloc`
- Finance template's capabilities definitions
- Old `CapabilitiesScreen` (replaced by `RemindersScreen`)

### Create new
- `RemindersScreen` — full reminders page with grouped list, toggles, FAB
- `AddReminderSheet` — bottom sheet to create/edit a reminder (pick type, time, module, message)
- `UpcomingRemindersSection` — home screen widget showing next 3 reminders with "See all"

## Design Constraints

- Follow the sumi ink / washi paper aesthetic (PaperBackground, CormorantGaramond headers, Karla body text)
- Staggered entrance animations on the reminders page
- Bell icon uses Phosphor icons (consistent with rest of app)
- No template auto-install of reminders — user always decides
