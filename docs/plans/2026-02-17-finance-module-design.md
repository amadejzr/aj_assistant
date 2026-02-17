# Finance Module Design

Multi-schema single module for personal finance tracking: accounts, expenses, and income with 50/30/20 budgeting.

## Schemas

### `account` (4 fields)
- `name` (text, required) — account name
- `balance` (number, required) — current balance
- `cap` (number, optional) — max limit, null = unlimited
- `icon` (enumType, optional) — shield, airplane, golf, piggy_bank, trending_up, wallet

### `expense` (4 fields)
- `amount` (number, required)
- `bucket` (enumType, required) — Needs, Wants, Savings
- `note` (text, optional)
- `date` (datetime, required)

### `income` (3 fields)
- `amount` (number, required)
- `source` (text, optional)
- `date` (datetime, required)

## Settings
- `monthlyIncome` — expected monthly income for 50/30/20 budget calculations

## Screens

### Main (tab_screen, 3 tabs)

**Overview tab:**
- Total Balance + Spent This Month stat cards
- 50/30/20 progress bars (Needs 50%, Wants 30%, Savings 20%)
- Set Monthly Income button (settings mode)
- Recent 5 expenses list
- FAB: Add Expense

**Accounts tab:**
- Add Account button
- Account list (name, icon, balance, swipe to delete)
- Tap to edit

**Income tab:**
- This Month + This Year stat cards
- Add Income button
- Income log list

### Forms
- add_expense / edit_expense — amount, bucket, note, date
- add_account / edit_account — name, balance, cap, icon
- add_income / edit_income — amount, source, date
- edit_income_target — monthly income setting

## Engine Extensions

1. **EntryFilter** — added `schemaKey` as a special field that reads from `entry.schemaKey` instead of `entry.data`
2. **ExpressionEvaluator** — added `multiply(a, b)` and `divide(a, b)` functions
3. **ProgressBarNode** — added `filter` property (matching StatCardNode pattern)
4. **Tab screen icons** — added compass, check_circle, piggy_bank, cash, wallet

## Key Decisions
- AI handles income allocation through chat, module is just the ledger
- Three buckets only (Needs/Wants/Savings), no sub-categories
- Account caps are hard limits, AI knows not to over-allocate
- Single FAB for most frequent action (Add Expense), buttons for Account/Income creation
