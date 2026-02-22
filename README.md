<p align="center">
  <img src="assets/app_icon.png" width="120" alt="Bower logo" />
</p>

<h1 align="center">Bower</h1>

<p align="center">
  <em>your personal notebook</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-0.0.1-blue?style=flat-square" alt="Version" />
  <img src="https://img.shields.io/badge/flutter-3.38-02569B?style=flat-square&logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/dart-3.10-0175C2?style=flat-square&logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey?style=flat-square" alt="Platform" />
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License" />
</p>

<p align="center">
  <a href="#what-is-bower">What is Bower</a> &middot;
  <a href="#how-it-works">How it works</a> &middot;
  <a href="#features">Features</a> &middot;
  <a href="#roadmap">Roadmap</a> &middot;
  <a href="#tech-stack">Tech stack</a> &middot;
  <a href="#license">License</a>
</p>

---

## What is Bower

Bower is a modular personal notebook app. It uses a blueprint system and a local SQLite database to build modules — expense trackers, fitness logs, budgets, or anything you can think of. You define the schema, Bower renders the screens. You can also add entries to your modules through the AI chat. Full AI-powered module creation — where the chat designs schemas and screens for you — is planned for a future release.

## How it works

1. **Define a module** — pick one from the marketplace or build it yourself. Each module has a schema with field definitions, constraints, and triggers
2. **Tables are created locally** — Bower generates SQLite tables on your device based on the module's database fields
3. **Blueprints describe the UI** — each screen is a JSON document that defines layout, inputs, displays, and actions
4. **Blueprint renderer builds native screens** — the blueprint is parsed into a widget tree and rendered as real Flutter widgets
5. **Data stays local** — all entries are stored in SQLite via Drift, on your device
6. **Chat with the AI** — add entries, query your data, and interact with your modules through conversation

## Features

- **Blueprint-driven UI** — screens are JSON blueprints rendered into native Flutter widgets — stat cards, charts, forms, lists, tabs, and more
- **Local-first data** — all your data lives in SQLite via Drift, on your device
- **Dynamic module tables** — each module generates its own SQLite tables from its schema definition
- **Composable builders** — layout, display, input, and action builders that snap together into full screens
- **Module capabilities** — modules can opt into built-in capabilities like reminders
- **AI chat** — add entries to your modules through conversation with Claude
- **Module marketplace** — browse, search, and install pre-made module templates


## Screenshots

> Coming soon — screenshots of the login screen, chat interface, module viewer, and splash animation.

<!--
<p align="center">
  <img src="docs/screenshots/login.png" width="200" />
  <img src="docs/screenshots/chat.png" width="200" />
  <img src="docs/screenshots/module.png" width="200" />
  <img src="docs/screenshots/splash.png" width="200" />
</p>
-->

## Roadmap

Bower is in active development. The architecture and approach are still evolving — contributions and ideas are welcome.

- [ ] AI-powered module creation — design schemas and screens through conversation
- [ ] More capabilities — user-configured integrations like calendar sync, webhooks, cloud backup, and external APIs
- [ ] Data export — CSV, JSON
- [ ] More blueprint widgets — richer ways to display and visualize your data
- [ ] Remove Firebase dependency — no login required, modules and marketplace work offline
- [ ] Local AI chat — runs on-device with your own API key, no cloud functions
- [ ] Multiple AI providers — support for different LLM backends beyond Claude

## Tech stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (iOS + Android) |
| State management | flutter_bloc |
| Local database | Drift (SQLite) |
| Routing | GoRouter |
| AI | Anthropic Claude API |
| Icons | Phosphor Flutter |
| Charts | fl_chart |

## License

MIT — see [LICENSE](LICENSE) for details.
