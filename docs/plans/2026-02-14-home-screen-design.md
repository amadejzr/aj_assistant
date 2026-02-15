# Home Screen & Theme Design — "Night Studio"

## Overview

AJ Assistant is a chat-first personal assistant that starts completely empty. The user talks to an AI which dynamically creates modules through natural language. The home screen must communicate "intelligent emptiness" — alive and ready, not barren.

## Color System

### Dark Theme (Primary)

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#1A1A1E` | Main background — warm charcoal |
| `surface` | `#242428` | Cards, chat bubbles, elevated elements |
| `surfaceVariant` | `#2E2E33` | Input fields, secondary surfaces |
| `onBackground` | `#F2EDE8` | Primary text — warm off-white |
| `onBackgroundMuted` | `#8A857E` | Secondary text, timestamps, hints |
| `accent` | `#E8A84C` | Amber — primary accent, AI identity |
| `accentMuted` | `#E8A84C` @ 15% opacity | Accent backgrounds, subtle highlights |
| `border` | `#FFFFFF` @ 8% opacity | Dividers, card borders |
| `error` | `#E85C5C` | Error states |
| `success` | `#5CE88A` | Confirmations |

### Light Theme

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#FAF7F2` | Warm ivory |
| `surface` | `#FFFFFF` | Cards, elevated elements |
| `surfaceVariant` | `#F0EBE3` | Input fields, secondary surfaces |
| `onBackground` | `#2C2520` | Espresso — primary text |
| `onBackgroundMuted` | `#9C958C` | Secondary text |
| `accent` | `#D4922E` | Deeper amber for light backgrounds |
| `accentMuted` | `#D4922E` @ 10% opacity | Subtle highlights |
| `border` | `#000000` @ 8% opacity | Dividers |

## Typography

- **Headlines / Greeting:** `Bricolage Grotesque` — Semi-bold (600). Variable geometric grotesque with optical quirks.
- **Body / UI:** `DM Sans` — Regular (400) and Medium (500). Clean, geometric, highly legible.
- **Monospace accent:** `DM Mono` — For code snippets or data values.

### Type Scale

| Role | Size | Weight | Font |
|------|------|--------|------|
| Display (greeting) | 32sp | 600 | Bricolage Grotesque |
| Headline | 24sp | 600 | Bricolage Grotesque |
| Title | 18sp | 500 | DM Sans |
| Body | 15sp | 400 | DM Sans |
| Caption | 12sp | 400 | DM Sans |
| Mono | 13sp | 400 | DM Mono |

## Home Screen Layout

Three zones stacked vertically:

### Greeting Zone (top ~30%)
- Time-of-day greeting: "Good morning" / "Good afternoon" / "Good evening"
- Current date below in muted text
- Bricolage Grotesque at display size
- Fade-in + slight upward slide on load (400ms, ease-out-cubic)

### Module Zone (middle, scrollable)
- **Empty state:** Centered geometric accent shape (three overlapping translucent circles in accentMuted, drawn with CustomPaint), slow rotation animation (8s cycle)
- Below it: "Ask me anything. I'll build what you need." in muted text
- **Future state:** Grid of AI-created module cards

### Input Zone (pinned bottom)
- Rounded rectangle input with surfaceVariant background
- Placeholder: "What's on your mind?"
- Send button: Amber circle with arrow icon
- Subtle breathing glow animation on input (opacity 0.3-0.6, 3s cycle)

## Background Treatment

- **Dark:** Radial gradient from center `#1E1E22` → `#1A1A1E`. Barely visible noise texture at 2% opacity.
- **Light:** Linear gradient from top `#FAF7F2` → `#F5F0E8`. Same subtle noise overlay.

## Animations

All use `Curves.easeOutCubic`.

| Element | Animation | Duration | Trigger |
|---------|-----------|----------|---------|
| Greeting text | Fade in + translateY (20→0) | 400ms | Page load |
| Date text | Fade in + translateY (20→0) | 400ms, 100ms delay | Page load |
| Empty state shape | Fade in + scale (0.8→1.0) | 600ms, 200ms delay | Page load |
| Empty state text | Fade in | 500ms, 400ms delay | Page load |
| Input field | Fade in + translateY (30→0) | 400ms, 300ms delay | Page load |
| Input glow | Opacity oscillation (0.3↔0.6) | 3000ms, infinite | Always |
| Geometric accent | Slow rotation | 8000ms, infinite | Always |

## File Architecture

```
lib/
├── main.dart
├── core/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_spacing.dart
│   └── widgets/
│       └── animated_glow.dart
├── features/
│   └── home/
│       ├── home_screen.dart
│       ├── widgets/
│       │   ├── greeting_section.dart
│       │   ├── empty_state.dart
│       │   ├── chat_input_bar.dart
│       │   └── geometric_accent.dart
│       └── home_controller.dart
```

## Spacing System (4px grid)

- `xs`: 4px
- `sm`: 8px
- `md`: 16px
- `lg`: 24px
- `xl`: 32px
- `xxl`: 48px

Screen padding: 24px horizontal.
