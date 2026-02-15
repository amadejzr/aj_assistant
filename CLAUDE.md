Design Language: Sumi Ink & Washi Paper

This app's aesthetic draws from Japanese stationery and calligraphy culture — sumi ink on washi paper, hanko vermillion seals, hand-drawn sketchbook textures. Every screen should feel like opening a well-loved creative notebook. Avoid generic "AI slop" aesthetics at all costs.

Typography: Use distinctive fonts that fit the stationery mood. Cormorant Garamond for display/seal text, Karla for login UI (uppercase labels, tight letter-spacing), DM Sans for signup/secondary UI. Never fall back to Inter, Roboto, Arial, or system defaults. Vary fonts across screens — don't converge on a single choice.

Color & Theme: Warm charcoal backgrounds (sumi ink stone), aged cream paper surfaces (washi), vermillion accent (hanko stamp red). The palette is built around AppColors — dark theme is ink-on-dark, light theme is ink-on-cream. Dominant warm tones with a single sharp vermillion accent. No purple gradients, no cool-toned generics.

Motion: Staggered reveals on page load are the signature — the login seal stamps in with a scale bounce, fields slide up sequentially. One well-orchestrated entrance beats scattered micro-interactions. Use animation-delay staggering, ease-out-back for physical weight.

Backgrounds: Never flat solid colors. Use CustomPaint sketchbook textures — wobbly hand-drawn borders, cross-hatching, pencil shading patches, spiral doodles, ink dots, geometric sketch marks (wobbly squares, circles, lines). These create depth and atmosphere like a real notebook page. Both auth screens share the PaperBackground painter.

Avoid:
- Overused font families (Inter, Roboto, Arial, Space Grotesk, system fonts)
- Cool-toned or purple color schemes
- Flat, textureless backgrounds
- Rounded-rectangle logo containers (use the hanko SealLogo instead)
- Cookie-cutter layouts that ignore the stationery context

All new screens should feel like they belong in the same sketchbook. When in doubt, ask: "Would this look at home next to a hand-drawn ink spiral and a vermillion seal stamp?"

Context

 AJ Assistant is a chat-first personal assistant mobile app that starts completely empty. The user talks to an AI (Claude), and the AI dynamically creates modules (expense trackers,
 fitness logs, habit trackers, budgets, etc.) through natural language. Each module is a rich, domain-specific mini-app with its own data schema, custom screen layouts, automations,
 and data entries. The user can also manually tweak anything the AI creates through visual settings panels or through further chat conversation.

 Core principle: The app has no pre-built features. The AI and the user together build the app's functionality.

 ---
 Architecture Overview

 User message → Cloud Function → Claude API (with tools) → Structured module definition
 → Firestore write → Real-time listener fires → BlueprintRenderer → Live Flutter widgets

 Stack: Flutter (iOS + Android) | Firebase (Auth + Firestore + Cloud Functions) | Anthropic Claude API

 ---
 1. Navigation & App Shell

 - Bottom navigation (2 tabs): Dashboard (landing) | Modules (grid/list of all modules)
 - Floating chat button: Always visible above bottom nav, amber accent with breathing glow animation. Tapping opens a bottom sheet chat overlay. Context-aware — knows which screen the
 user is on.
 - App bar: App name (left), settings gear icon (right) → settings page
 - Onboarding: 2-3 quick intro screens → empty dashboard with prominent "Start a conversation" card

 ---
 2. Firestore Data Model

 /users/{userId}
   - profile, settings, dashboardConfig (embedded blueprint)
   - onboardingCompleted

 /users/{userId}/modules/{moduleId}
   - name, description, icon, color, sortOrder
   - schema: { version, fields: { fieldKey: { type, label, required, constraints, options } }, migrations }
   - screens: { screenId: blueprintJSON }
   - settings: { moduleSpecific config like monthlyBudget, currency }

 /users/{userId}/modules/{moduleId}/entries/{entryId}
   - data: { fieldKey: value, ... }
   - schemaVersion, createdAt, updatedAt

 /users/{userId}/modules/{moduleId}/automations/{autoId}
   - name, enabled, trigger, actions, lastTriggeredAt

 /users/{userId}/conversations/{conversationId}
   - context, startedAt, lastMessageAt, messageCount

 /users/{userId}/conversations/{conversationId}/messages/{messageId}
   - role, content, timestamp, toolCalls, toolResults

 Key decisions:
 - Schema + screens are embedded in the module doc (always fetched together, single read, well under 1MB limit)
 - Entries are a subcollection (thousands per module, need independent querying/pagination)
 - Dashboard config is embedded in user doc (single read on app launch)
 - Messages are immutable (create only, no edits)

 ---
 3. Module System

 Schema Field Types

 text | number | boolean | datetime | enumType | multiEnum | list | reference | image | location | duration | currency | rating | url | phone | email

 Schema Migration Strategy

 - Lazy migration: Entries are migrated on read, not on write
 - Each entry stores schemaVersion — when behind current, migration runs before rendering
 - Field removal is soft delete: field disappears from UI, old data stays
 - Migrations are idempotent and recorded in schema.migrations[]

 ---
 4. Screen Blueprint System (Server-Driven UI)

 The AI generates JSON screen definitions. The app has a BlueprintRenderer that turns any blueprint into a real Flutter widget tree.

 Widget Type Taxonomy (~35 types)

 Layout: screen, form_screen, scroll_column, column, row, card, section, tabs, expandable, conditional

 Data display: stat_card, entry_list, entry_card, chart (pie/bar/line/donut), progress_bar, calendar_view, timeline, data_table, text_display, badge, empty_state, image_gallery

 Input: text_input, number_input, currency_input, date_picker, time_picker, enum_selector, multi_enum_selector, toggle, slider, rating_input, image_picker, location_picker

 Actions: button, fab, icon_button, action_menu

 Dashboard-specific: module_summary_card, quick_add_button, recent_activity, greeting_header

 Blueprint Example (Expense Tracker Main Screen)

 {
   "id": "main",
   "title": "Expenses",
   "type": "screen",
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
               { "type": "stat_card", "label": "Total Spent", "expression": "sum(amount, period(month))", "format": "currency" },
               { "type": "stat_card", "label": "Transactions", "expression": "count(period(month))", "format": "integer" }
             ]
           }
         ]
       },
       {
         "type": "section",
         "title": "By Category",
         "children": [
           { "type": "chart", "chartType": "donut", "expression": "group(category, sum(amount), period(month))" }
         ]
       },
       {
         "type": "section",
         "title": "Recent",
         "children": [
           {
             "type": "entry_list",
             "query": { "orderBy": "date", "direction": "desc", "limit": 10 },
             "itemLayout": {
               "type": "entry_card",
               "title": "{{note}}",
               "subtitle": "{{category}}",
               "trailing": "{{amount}}",
               "trailingFormat": "currency"
             }
           }
         ]
       }
     ]
   },
   "fab": { "type": "fab", "icon": "add", "action": { "type": "navigate", "screen": "add_entry" } }
 }

 Renderer Architecture

 1. BlueprintParser — JSON → BlueprintNode sealed class hierarchy
 2. WidgetRegistry — Maps type strings to Flutter widget builder functions. Singleton, initialized once at startup.
 3. RenderContext — Carries module, resolved data, theme, navigation callbacks through the widget tree
 4. ExpressionCollector — Walks blueprint tree, extracts all expression strings before rendering
 5. BlueprintRenderer — Top-level widget: parse → resolve expressions → build widget tree

 Blueprint Validation (defense against bad AI output)

 - Server-side (Cloud Functions): Validate before saving to Firestore. Fatal errors → tool call returns error to Claude for retry.
 - Client-side (Flutter): Unknown widget types → SizedBox.shrink() (silently skip). Invalid expressions → display "--". Unparseable JSON → error screen with "Report issue" button.

 ---
 5. Expression Engine

 Blueprints reference data through a mini expression language:

 sum(amount)                                    → total of all amounts
 sum(amount, period(month))                     → this month's total
 count(period(week))                            → entries this week
 group(category, sum(amount))                   → { "Food": 450, "Transport": 120 }
 subtract(settings.monthlyBudget, sum(amount, period(month)))  → budget remaining
 percentage(sum(amount, where(category, ==, Food)), sum(amount))  → food % of total

 Operators: sum, count, avg, min, max, group, subtract, multiply, divide, percentage
 Filters: period(today|week|month|year), where(field, op, value)

 Implementation: Recursive descent parser → Expression sealed class → ExpressionEngine.resolveAll() batch-resolves all expressions for a screen against the entries list. Results are
 cached in BLoC state and recomputed only when entries change.

 ---
 6. AI Integration Pipeline

 Chat Flow

 1. User sends message from chat sheet
 2. Flutter sends HTTP call to Cloud Function /chat with message + conversationId + context (moduleId, screenId)
 3. Cloud Function loads conversation history (last 20 messages) + current module state
 4. Builds system prompt with: available widget types, field types, expression syntax, current module/dashboard state
 5. Calls Claude API with tool definitions
 6. Claude returns text + tool calls → Cloud Function executes tools (writes to Firestore)
 7. If Claude chains more tool calls, loops until stop_reason != tool_use
 8. Returns final text response + list of mutations to Flutter
 9. Firestore real-time listeners automatically pick up all changes → UI re-renders

 Claude Tool Definitions

 - createModule — name, icon, color, schema, screens, dashboardCard
 - updateSchema — addFields, removeFields, updateFields
 - updateScreenBlueprint — moduleId, screenId, blueprint
 - createEntry — moduleId, data
 - createAutomation — moduleId, trigger, actions
 - updateDashboard — blueprint
 - updateModuleSettings — moduleId, settings
 - deleteModule — moduleId + confirmation

 Context-Awareness

 The floating chat button infers context from the current route:
 - On dashboard → DashboardChatContext → AI knows to work with dashboard
 - In a module screen → ModuleChatContext(moduleId, screenId) → AI knows to work with that module
 - Claude's system prompt includes current module state when context is provided

 ---
 7. Automation System

 Trigger Types

 - Time-based: daily_20:00, weekly_monday_9am, monthly_1st_9am — evaluated by Cloud Scheduler (every 15 min)
 - Event-based: entry_created, entry_updated, entry_deleted — evaluated by Firestore onWrite triggers
 - Threshold-based: expression reaches a value (e.g., sum(amount, period(month)) >= 2000) — evaluated on entry writes + periodic checks

 Action Types

 - notification — push notification with template interpolation
 - createEntry — auto-create an entry
 - updateField — modify an entry field
 - sendSummary — generate periodic summary notification

 ---
 8. Flutter App Structure

 lib/
   main.dart                           → Firebase init, providers, GoRouter
   app.dart                            → MaterialApp.router setup
   core/
     theme/                            → EXISTING: app_colors, app_typography, app_spacing, app_theme
     models/                           → Module, Entry, Automation, Conversation, BlueprintNode, AppUser
     services/                         → ModuleService, EntryService, ChatService, AuthService, UserService, SchemaMigrationService
     routing/                          → GoRouter config + route names
     utils/                            → format_utils, icon_utils
     widgets/                          → Shared widgets (aj_card, aj_button, loading_indicator)
   features/
     auth/                             → BLoC + screens (login, signup) + social sign-in widgets
     onboarding/                       → 2-3 screen intro flow
     shell/                            → Scaffold with bottom nav + chat FAB
     dashboard/                        → BLoC + screen (renders dashboard blueprint)
     modules/                          → BLoC + modules list screen
     module_viewer/
       bloc/                           → ModuleViewerBloc (active module state + data)
       screens/                        → ModuleScreen (hosts BlueprintRenderer)
       renderer/
         blueprint_renderer.dart       → Top-level renderer widget
         render_context.dart           → Context passed through widget tree
         widget_registry.dart          → Type string → builder map
         blueprint_parser.dart         → JSON → BlueprintNode
         builders/                     → One file per widget type (~35 builders)
       expression/
         expression_engine.dart        → Resolves expressions against entries
         expression_parser.dart        → String → Expression AST
         expression_collector.dart     → Extracts expressions from blueprints
     chat/                             → ChatBloc + ChatSheet (bottom sheet overlay) + message bubbles
     settings/                         → SettingsBloc + screen (theme, account, preferences)
     module_settings/                  → Visual settings panel for module customization

 Key Dependencies to Add

 go_router: ^15.1.0
 firebase_core: ^3.12.0
 firebase_auth: ^5.5.0
 cloud_firestore: ^5.6.0
 cloud_functions: ^5.3.0
 firebase_messaging: ^15.2.0
 google_sign_in: ^6.2.2
 sign_in_with_apple: ^6.1.4
 equatable: ^2.0.7
 json_annotation: ^4.9.0
 uuid: ^4.5.1
 fl_chart: ^0.70.2
 intl: ^0.19.0
 shimmer: ^3.0.0

 Cloud Functions Structure (TypeScript)

 functions/src/
   index.ts                → exports
   chat/handler.ts         → main chat endpoint
   chat/systemPrompt.ts    → builds system prompt
   chat/toolDefinitions.ts → Claude tool schemas
   chat/toolExecutor.ts    → dispatches tool calls
   tools/                  → one file per tool (createModule, updateSchema, etc.)
   automations/            → runner, evaluator, executor
   validation/             → blueprint, schema, entry validators

 ---
 9. Authentication

 - Email/Password — Firebase Auth with email verification
 - Google Sign-In — google_sign_in package
 - Apple Sign-In — sign_in_with_apple package (required for iOS App Store)
 - Auth state managed by AuthBloc listening to FirebaseAuth.authStateChanges
 - GoRouter redirect guards: unauthenticated → /auth/login, first time → /onboarding

 ---
 10. Implementation Phases

 Phase 1: Foundation

 1. Firebase project setup (Core, Auth, Firestore, Functions)
 2. Add all dependencies to pubspec.yaml
 3. Auth feature: AuthBloc, AuthService, Login/Signup screens, social sign-in
 4. App shell: ShellScreen with BottomNavBar
 5. GoRouter setup with auth redirects
 6. Settings screen (theme toggle, sign out)
 7. Onboarding screens (2-3 pages)

 Phase 2: Module System Core

 8. Data models: Module, ModuleSchema, FieldDefinition, Entry
 9. Services: ModuleService, EntryService (Firestore CRUD with real-time streams)
 10. WidgetRegistry + BlueprintParser
 11. Core widget builders: screen, scroll_column, section, row, column, card, stat_card, text_display, empty_state
 12. RenderContext + BlueprintRenderer
 13. ModuleViewerBloc + ModuleScreen
 14. ModulesListBloc + ModulesListScreen
 15. Hardcode a test module in Firestore → verify rendering works

 Phase 3: Data & Expressions

 16. Expression parser (string → AST)
 17. Expression engine (AST → resolved values against entries)
 18. Expression collector (extracts all expressions from a blueprint)
 19. entry_list + entry_card widget builders
 20. Form system: form_screen, text_input, number_input, currency_input, date_picker, enum_selector, toggle builders
 21. Entry creation flow (form → validate → write to Firestore)
 22. Entry detail screen rendering

 Phase 4: AI Integration

 23. Cloud Functions project init + deploy pipeline
 24. Chat Cloud Function: message handling, Claude API call, tool loop
 25. System prompt builder with context awareness
 26. Tool implementations: createModule, updateSchema, updateScreenBlueprint, createEntry
 27. updateDashboard, updateModuleSettings, deleteModule tools
 28. ChatBloc + ChatSheet UI (bottom sheet with message bubbles, typing indicator)
 29. Chat FAB with context inference and breathing glow animation
 30. Dashboard blueprint rendering (DashboardBloc, DashboardScreen)
 31. End-to-end test: create an expense tracker module through chat

 Phase 5: Polish & Advanced Features

 32. Chart widget builders (fl_chart integration: pie, bar, line, donut)
 33. progress_bar, calendar_view, timeline builders
 34. Module settings screen (visual field editing, section reordering)
 35. Automation model + Cloud Function runner (scheduled + event-based)
 36. Push notifications via Firebase Messaging
 37. Blueprint validation (client + server)
 38. Remaining widget builders (image_picker, location_picker, etc.)
 39. Offline behavior polish
 40. Performance optimization (entry pagination, expression caching)

 ---
 Critical Files to Modify/Create

 Existing (modify):
 - lib/main.dart — Add Firebase init, BLoC providers, GoRouter
 - pubspec.yaml — Add all new dependencies

 Existing (reuse as-is):
 - lib/core/theme/app_colors.dart — Color tokens referenced by blueprint style properties
 - lib/core/theme/app_typography.dart — Text styles used by all widget builders
 - lib/core/theme/app_spacing.dart — Spacing constants mapped from blueprint padding/margin values
 - lib/core/theme/app_theme.dart — ThemeData + AppColorsExtension accessed via context.colors

 ---
 Verification

 Per-phase verification:

 1. Phase 1: App launches → shows onboarding → sign in with email → lands on empty dashboard with bottom nav and chat FAB
 2. Phase 2: Manually insert a module doc in Firestore → app renders its blueprint as a real screen with stat cards and sections
 3. Phase 3: Navigate to a module → see entry list → tap FAB → fill form → entry appears in list → stat cards update with correct expression values
 4. Phase 4: Tap chat FAB → type "Create an expense tracker with categories and a monthly budget" → Claude creates the module → module appears in modules list → dashboard updates with
 summary card → navigate to module → see full working expense tracker
 5. Phase 5: Charts render correctly → automations fire notifications → module settings panel allows visual editing → blueprint validation catches invalid AI output gracefully