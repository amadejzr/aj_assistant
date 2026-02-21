# Savings Goals Marketplace Template

## Overview

Full-featured savings goals module for the marketplace. Two schemas (goals + deposits) with reference effects for automatic progress tracking. Bottom nav with Dashboard, Goals, and History tabs.

## Data Model

### Goals Schema (`goals`)

| Field | Type | Label | Required | Constraints |
|-------|------|-------|----------|-------------|
| `name` | text | Goal Name | yes | — |
| `target_amount` | currency | Target | yes | min: 0, defaultCurrency: USD |
| `saved_amount` | currency | Saved | no | Auto-updated by deposit effect. Starts at 0 |
| `deadline` | datetime | Target Date | no | dateOnly: true, allowPast: false |
| `category` | enumType | Category | no | Emergency, Travel, Purchase, Education, Retirement, Other |
| `status` | enumType | Status | no | Active, Completed, Paused |
| `notes` | text | Notes | no | multiline: true |

- `displayField`: `name`
- `icon`: `target`

### Deposits Schema (`deposits`)

| Field | Type | Label | Required | Constraints |
|-------|------|-------|----------|-------------|
| `amount` | currency | Amount | yes | min: 0.01, defaultCurrency: USD |
| `goal` | reference | Goal | yes | targetSchema: goals, displayField: name, onDelete: cascade |
| `date` | datetime | Date | yes | dateOnly: true |
| `note` | text | Note | no | — |

- `displayField`: `note`
- `icon`: `coins`
- **Effect:** `AdjustReferenceEffect` on `goal` reference — adds `amount` to goal's `saved_amount` on create, subtracts on delete.

## Screens

### Navigation

Bottom nav with 3 items:
1. **Dashboard** (icon: `chart-line-up`, screenId: `main`)
2. **Goals** (icon: `target`, screenId: `goals_list`)
3. **History** (icon: `clock-counter-clockwise`, screenId: `history`)

### Dashboard (`main`)

- Stat cards row: Total Saved, Active Goals count, Monthly Deposits count
- Section "Active Goals": entry list filtered to status == Active
  - Entry card: title = `{{name}}`, subtitle = `${{saved_amount}} / ${{target_amount}}`, trailing = `{{category}}`
- FAB: navigate to `add_goal`

### Goals List (`goals_list`)

- Entry list of all goals, ordered by deadline asc
  - Entry card: title = `{{name}}`, subtitle = `{{deadline}}`, trailing = `{{status}}`
- FAB: navigate to `add_goal`

### History (`history`)

- Entry list of deposits (schema: deposits), ordered by date desc
  - Entry card: title = `${{amount}}`, subtitle = `{{note}}`, trailing = `{{date}}`
- FAB: navigate to `add_deposit`

### Add Goal (`add_goal`)

Form screen: name, target_amount, deadline, category, status (default: Active), notes.

### Add Deposit (`add_deposit`)

Form screen: goal (reference picker), amount, date (default: today), note.

### View Goal (`view_goal`)

Detail screen: goal info + progress bar + filtered deposit list for that goal.

## Template Metadata

- **Name:** Savings Goals
- **Description:** Set targets, log deposits, watch your savings grow
- **Icon:** `piggy-bank`
- **Color:** `#2E7D32`
- **Category:** Finance
- **Tags:** savings, goals, money, finance, budget, deposits
- **Featured:** true
- **Sort order:** 1

## Guide

1. **Create a Goal** — Tap + to add a savings goal. Give it a name, set your target amount, and optionally pick a deadline.
2. **Log Deposits** — Switch to the History tab and tap + to log a deposit. Pick which goal it's for, enter the amount, and it's automatically tracked.
3. **Track Progress** — The Dashboard shows your total savings and progress bars for each active goal. Watch them fill up as you save!
