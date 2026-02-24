# Contributing to BowerLab

Thanks for your interest in contributing! BowerLab is in active development and we welcome contributions and ideas.

## Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) 3.38+
- Xcode (for iOS development)
- An [Anthropic API key](https://console.anthropic.com/) (for AI chat features)

### Setup

```bash
git clone https://github.com/amadejzr/bowerlab.git
cd bowerlab
flutter pub get
flutter run
```

### Useful Commands

```bash
flutter run                                                   # Run the app
flutter test                                                  # Run tests
dart analyze                                                  # Static analysis
dart run build_runner build --delete-conflicting-outputs       # Regenerate Drift code
```

## Project Conventions

BowerLab follows strict conventions documented in [CLAUDE.md](CLAUDE.md). Key points:

- **Feature structure:** Each feature lives in `lib/features/{name}/` with subdirectories for `bloc/`, `models/`, `screens/`, `widgets/`, `services/`, `repositories/` as needed.
- **State management:** BLoC pattern everywhere. Events and states are sealed classes with `Equatable`.
- **Theme:** Use `context.colors`, `AppSpacing`, and `AppTypography` — never hardcode colors or spacing.
- **Naming:** Files use `snake_case`. One class per file. Methods under 20 lines.
- **Imports:** Relative imports within the same feature, package imports in tests.

## Pull Requests

1. Fork the repo and create a branch from `main`
2. Make your changes, following the conventions above
3. Ensure `dart analyze` reports no issues and `flutter test` passes
4. Open a PR with a clear description of what changed and why

## Architecture

The most interesting part of the codebase is the **blueprint rendering engine** in `lib/features/blueprint/`. Claude generates JSON screen definitions, and the engine renders them into native Flutter widgets at runtime. If you're exploring the codebase, start there.
