# AJ Assistant

Chat-first personal assistant. The user talks to Claude, Claude creates modules (expense trackers, fitness logs, habit trackers, budgets) through natural language. Each module is a mini-app with its own schema, screens, and data. The app starts empty — the AI and user build everything together.

## Design Language: Sumi Ink & Washi Paper

Aesthetic: Japanese stationery and calligraphy — sumi ink on washi paper, hanko vermillion seals, hand-drawn sketchbook textures. Every screen should feel like opening a well-loved creative notebook.

Typography: Cormorant Garamond for display/seal text, Karla for login UI (uppercase labels, tight letter-spacing), DM Sans for signup/secondary UI. Never fall back to Inter, Roboto, Arial, or system defaults.

Color: Warm charcoal backgrounds (sumi ink stone), aged cream paper surfaces (washi), vermillion accent (hanko stamp red). Built around `AppColors` — dark theme is ink-on-dark, light theme is ink-on-cream. No purple gradients, no cool-toned generics.

Motion: Staggered reveals on page load. Login seal stamps in with a scale bounce, fields slide up sequentially. Use ease-out-back for physical weight.

Backgrounds: Never flat. Use `CustomPaint` sketchbook textures — wobbly borders, cross-hatching, ink dots, pencil shading. Both auth screens share `PaperBackground`.

Avoid: overused fonts (Inter, Roboto, system defaults), cool/purple palettes, flat textureless backgrounds, rounded-rectangle logos (use `SealLogo`), cookie-cutter layouts.

## Tech Stack

Flutter (iOS + Android) | Drift (local SQLite) | Firebase (Auth, Firestore, Cloud Functions) | Anthropic Claude API

State management: flutter_bloc. Routing: go_router. Icons: phosphor_flutter. Charts: fl_chart. Local notifications: flutter_local_notifications.

## Project Structure

```
lib/
  main.dart                        # Entry point, Firebase init, BLoC providers
  app.dart                         # MaterialApp.router setup
  app_router.dart                  # GoRouter config, auth redirects
  firebase_options.dart            # Generated Firebase config

  core/
    database/                      # Drift database, tables, converters
    logging/                       # Log utility, BLoC observer
    models/                        # Module, Entry, ModuleTemplate
    repositories/                  # Abstract + Drift repos (module, entry, marketplace)
    theme/                         # AppColors, AppTypography, AppSpacing, AppTheme
    utils/                         # module_display_utils
    widgets/                       # Shared widgets (AppToast, SumiTextField)

  features/
    auth/                          # Login, signup, social sign-in
      bloc/                        # AuthBloc (listens to FirebaseAuth)
      models/                      # AppUser
      screens/                     # LoginScreen, SignupScreen
      services/                    # AuthService, UserService
      widgets/                     # SealLogo, PaperBackground, AuthTextField

    blueprint/                     # Server-driven UI rendering engine
      builders/
        action/                    # button, fab, icon_button, action_menu
        display/                   # stat_card, entry_list, chart, progress_bar, etc.
        input/                     # text, number, currency, date, enum, toggle, etc.
        layout/                    # screen, form_screen, scroll_column, row, section, tabs
      engine/                      # Expression evaluator, form validator, action dispatcher
      models/                      # Blueprint, BlueprintAction, BlueprintTemplate
      navigation/                  # ModuleNavigation (bottom nav / drawer config)
      renderer/                    # BlueprintRenderer, BlueprintParser, RenderContext, WidgetRegistry
      utils/                       # IconResolver
      widgets/                     # ReferenceEntrySheet

    capabilities/                  # Built-in capabilities (reminders, notifications)
      bloc/                        # CapabilitiesBloc
      models/                      # Capability
      repositories/                # CapabilityRepository (abstract + Drift)
      screens/                     # RemindersScreen
      services/                    # NotificationScheduler
      widgets/                     # AddReminderSheet, CapabilityCard

    chat/                          # Chat with Claude
      bloc/                        # ChatBloc
      models/                      # Conversation, Message
      repositories/                # ChatRepository
      widgets/                     # ChatSheet, MessageBubble, ApprovalCard, TypingIndicator

    marketplace/                   # Module template marketplace
      bloc/                        # MarketplaceBloc
      screens/                     # MarketplaceScreen, TemplateDetailScreen

    modules/                       # Module system (list, viewer, info, schema)
      bloc/                        # ModulesListBloc, ModuleViewerBloc
      models/                      # ModuleSchema, FieldDefinition, FieldType, FieldConstraints
      screens/                     # ModuleViewerScreen, ModuleInfoScreen

    shell/                         # App frame (scaffold, navigation, splash)
      screens/                     # ShellScreen, HomeScreen, SplashScreen
      widgets/                     # BreathingFab, UpcomingRemindersSection
```

## Conventions

**Feature structure.** Each feature follows: `bloc/`, `models/`, `screens/`, `widgets/`, `services/`, `repositories/`. Only create subdirectories that are needed.

**Naming.** Files use `snake_case`. BLoCs: `{feature}_bloc.dart`, `{feature}_event.dart`, `{feature}_state.dart`. Screens: `{name}_screen.dart`. Widgets: descriptive name, no `_widget` suffix.

**State management.** BLoC pattern everywhere. Events are sealed classes with `Equatable`. States are sealed classes with `Equatable`. BLoCs go in `features/{feature}/bloc/`.

**Repositories.** Abstract interface in `core/repositories/`. Drift implementation alongside it prefixed with `drift_`. Feature-specific repos live in `features/{feature}/repositories/`.

**Theme.** Access colors via `context.colors` (AppColorsExtension). Use `AppSpacing` constants for padding/margin. Use `AppTypography` for text styles. Never hardcode colors or spacing.

**Routing.** All routes defined in `app_router.dart`. Auth redirects handled by GoRouter's `redirect` callback. Use `context.go()` / `context.push()` for navigation.

**Imports.** Use relative imports within the same feature. Use package imports (`package:bowerlab/...`) only in test files.

## Code Quality

**Readability first.** Write code that reads like prose. Short methods, clear names, obvious flow. If a function needs a comment to explain what it does, rename it or break it up. Prefer explicit over clever.

**Testability.** Every class should be testable in isolation. Inject dependencies through constructors — never reach for globals or singletons in business logic. BLoCs take repositories/services as constructor params. Keep widgets dumb: UI reads state from BLoC, delegates actions to BLoC. Pure functions over stateful helpers.

**Keep it small.** One class per file. Methods under 20 lines. If a widget's `build` method is getting long, extract sub-widgets as private methods or separate widgets. If a BLoC is growing, split by domain concern.

**No dead code.** Delete unused imports, methods, and variables. Don't comment out code "for later" — git has history.

## Blueprint System

The AI generates JSON screen definitions. `BlueprintRenderer` turns them into Flutter widgets.

Flow: JSON blueprint -> `BlueprintParser` -> `BlueprintNode` tree -> `WidgetRegistry` looks up builder per type -> Flutter widget tree

Builder categories: layout (screen, form_screen, scroll_column, row, section, tabs), display (stat_card, entry_list, chart, progress_bar, empty_state), input (text, number, currency, date, enum, toggle, slider, rating), action (button, fab, icon_button, action_menu).

`RenderContext` carries module data, resolved expressions, theme, and navigation callbacks through the tree.

## Local Database (Drift)

SQLite via Drift. Tables defined in `core/database/tables.dart`. Database class in `app_database.dart`. Generated code in `app_database.g.dart`.

Regenerate after schema changes:
```
dart run build_runner build --delete-conflicting-outputs
```

## Commands

```bash
flutter run                                    # Run app
flutter test                                   # Run tests
dart analyze                                   # Static analysis
dart run build_runner build --delete-conflicting-outputs  # Regenerate Drift code
```
