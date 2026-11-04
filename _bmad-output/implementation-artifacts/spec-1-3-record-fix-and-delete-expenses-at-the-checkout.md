---
title: 'Story 1.3 (part A): Record Expenses at the checkout'
type: 'feature'
created: '2026-11-04'
status: 'in-review'
baseline_commit: 'f1826f7395437c3832435ba17cec5ddb6f66e04c'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-1-context.md'
  - '{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-groupay-2026-10-26/EXPERIENCE.md'
  - '{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-groupay-2026-10-26/DESIGN.md'
  - '{project-root}/CLAUDE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** No Expense can be recorded: the Group page is a bare header with a ₪0 placeholder, and `PayerUsagePort` is a stand-in that never blocks a remove.

**Approach:** Build FR10–FR12 and the FR4 payer refusal (epics.md lines 527–637, 642–676, 714–717): schema v3 `expenses`, the record policies, real `PayerUsagePort`/`GroupTotalsPort`, the Group page list/total/stripe/Add bar, and the Add expense screen.

**Decisions:**
- Scope split (Motty): this is part A. Edit, delete, view-only archived rows and the Remove-member body are part B (`deferred-work.md`). Rows render but tap/long-press do nothing yet.
- Copy and states verbatim from EXPERIENCE.md lines 59, 78, 88, 96–97, 119–131, 156–166, 185–192 and DESIGN.md lines 153–166, 201–239, 284, 292–300, 323–326, 333–335, 342, 344.
- Expense time (EXPERIENCE.md:59): local time of `createdAt`; today `HH:mm`, earlier `dd.mm`.
- Header line "{n} משתתפים · {m} הוצאות" with singulars "משתתף אחד"/"הוצאה אחת"; 0 → "0 הוצאות".
- No "סיכום" button (Story 1.4). Archived page keeps its restore bar and shows the list.

## Boundaries & Constraints

**Always:**
- Part 1.1/1.2 rules hold (layering, one `db.transaction` per action → `Result<T>`, in-flight guards, no literals in feature `ui/`, `NoTransitionPage`). Add checks `isGroupMutable` then `mayRecordExpense` inside the transaction.
- Only `expenses/data` writes `expenses`. `groups` never imports `expenses`; it gets payer facts and card totals only through the two ports, whose impls take only `AppDatabase`.
- Id made when the form opens; insert with an existing id is a no-op returning `Ok`. `saveSeq` = MAX+1 in the insert transaction. Payer must be a current Member of the Group.
- Description stored only for *Other* (trimmed). Keypad/bounds only via `core/money` (`pressKeypadKey`, `parseAmount`).
- `schemaVersion` 3 via `make-migrations`; commit `drift_schema_v3.json`, `schema_v3.dart`, a v2→v3 data-integrity test.

**Never:** No edit/delete code, no Summary, no swipe gestures, no clock-based ordering, no change to v1/v2 snapshots or `from1To2`.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Record | Dana, 300, 🏨, Save | Back on Group page; row slides in on top; total and card total +₪300 | N/A |
| Double save | Save ×2 fast | Exactly one Expense | Second call ignored |
| Bad amount | empty / 0 / 1,000,001 (Dana, 🏨 picked) | Not saved; Dana and 🏨 stay | "סכום לא תקין" in slot |
| Max amount | 1,000,000, 🏨 | Saved | N/A |
| 87.45 typed | keypad | Shows 87.4 | Ignored silently |
| No category | 87.4 | Not saved | "נא לבחור קטגוריה" |
| Other | 50, 📝, "  " / "Umbrella" | Refused / row titled "Umbrella" | "נדרש תיאור או בחירת קטגוריה" |
| Default payer | last `saveSeq` by Motty / no Expenses (Motty added first) | Motty selected | N/A |
| Clock back | A,B,C, clock −1 day, D | List D,C,B,A | N/A |
| Exit | 87 typed, ✕/back | Exit sheet; "יציאה" → nothing saved | "המשך עריכה"/scrim/back → 87 kept; no input → closes, no sheet |
| < 2 Members | Group page | Add disabled (40%), note above bar | Repo `Failure(needTwoMembers)` |
| Archived | page / `add` route / repo add | List, total, stripe shown; `add` → `/archive/group/:id` | `Failure(groupArchived)` |
| Remove payer | ✕ Yossi who paid | Not removed | Inline "לא ניתן להסיר משתתף שיש הוצאה על שמו"; FK RESTRICT backs it |

</frozen-after-approval>

## Code Map

- `lib/core/db/tables/expenses.dart` (new) -- `ExpenseRow`: `id` PK, `groupId` FK→groups, `payerId`, `amount` int, `category` text, `description` nullable, `saveSeq`, `createdAt`, `modifiedAt`; `uniqueKeys {groupId, saveSeq}`; composite FK `(group_id, payer_id) → members(group_id, id) ON DELETE RESTRICT` via `customConstraints` (target exists, `members.dart:79-84`). `app_database.dart:15,28,31-39`: register, v3, `from2To3: createTable(schema.expenses)`.
- `lib/core/policy/expense_rules.dart` (new) -- `mayRecordExpense(({int memberCount}))`, `defaultPayer({String? lastPayerId, List<String> memberIdsBySeq})`, `nextSaveSeq` (reuse `_maxPlusOne` from `member_rules.dart`, make it shared).
- `lib/core/ports/group_totals_port.dart` (new) -- `Stream<Map<String, Tenths>> watchTotals()`; keepAlive throwing provider in `port_providers.dart`.
- `lib/core/i18n/` -- keys `noExpenses`, `addExpense`, `needTwoMembers`, `chooseCategory`, `descriptionRequired`, `descriptionHint`, `expenseCountOne/Many`, 8 category labels; `expenseCountText(int)` beside `memberCountText` (`message_key.dart:186`); pure `formatExpenseTime(int createdAtUtc, int nowUtc)`.
- `lib/core/ui/widgets/` -- new `exit_sheet.dart` on `showConfirmSheet`; new `category_stripe.dart` (8dp, 2dp gaps); `group_header.dart` gets optional `stripe`.
- `lib/features/expenses/domain/` -- `Category` enum (fixed order, stable `key`, emoji), `Expense`, `ExpenseRepository` (`watchExpenses(groupId)` by `saveSeq` desc, `readLastPayerId(groupId)`, `add(...)`).
- `lib/features/expenses/data/` -- `DriftExpenseRepository(db, clock)` (copy `_checkMutable`, `drift_member_repository.dart:125-142`), `DriftPayerUsage(db)`, `DriftGroupTotals(db)`.
- `lib/features/expenses/app/` -- `expenseRepositoryProvider`, `expensesProvider(groupId)`, `AddExpense` notifier (pattern `group_providers.dart:143`).
- `lib/features/expenses/ui/` -- `group_page.dart` **moved from `groups/ui`** (spine line 62; keep its read-only/restore code): total, stripe, `expense_list.dart`, Add bar; `add_expense_screen.dart`, `payer_picker.dart`, `category_picker.dart` (4×2 grid, `LayoutBuilder` fallback to two-page `PageView` with peek and dots), `keypad.dart`. Slide-in via `appAnimationDuration(context, AppAnimation.expenseRowSlideIn)`.
- `lib/features/groups/ui/group_card.dart:9` -- show total from `GroupTotalsPort`.
- `lib/shell/` -- `router.dart` `group/:id/add` with `archivedRedirect`, import Group page from `expenses`; `overrides.dart`/`bootstrap.dart` bind `DriftPayerUsage`, `DriftGroupTotals`, `DriftExpenseRepository`; delete `payer_usage_stand_in.dart`; keep an optional `payerUsage` override so `FakePayerUsage` tests still work.

## Tasks & Acceptance

**Execution:**
- [x] `lib/core/db/**`, `drift_schemas/`, `test/core/db/**` -- schema v3, make-migrations, v2→v3 test.
- [x] `lib/core/{policy,ports,i18n}/**` + unit tests -- policies, port, keys, `formatExpenseTime`.
- [x] `lib/features/expenses/{domain,data,app}/**` + repository tests on `NativeDatabase.memory()` for each matrix row (incl. FK RESTRICT, port totals).
- [x] `lib/core/ui/widgets/**`, `lib/features/expenses/ui/**`, `lib/features/groups/ui/**` -- widgets, screens, card total.
- [x] `lib/shell/**` -- routes, overrides, stand-in removal.
- [x] `test/**` widget flows -- record, double save, validation, Other, exit sheet, disabled Add, archived redirect, payer refusal, two-page row at text scale 1.5, tap budget (launch → 87.4 🛒 saved in ≤4 taps).

**Acceptance Criteria:**
- Given the finished story, when `flutter analyze` and `flutter test --timeout 60s` run, then both pass with zero issues.
- Given the emulator with an Active group of 3 Members, when the Organizer launches, records 87.4 🛒 in ≤4 taps, force-stops and relaunches, then the row, Trip total, stripe and card total are unchanged.

## Implementation Notes

## Spec Change Log

## Review Triage Log

| # | Source | Finding | Verdict | Evidence | Route |
|---|--------|---------|---------|----------|-------|
| 1 | edge | `submit()` throwing leaves `_saving` true | low | Throws only on bugs/I/O faults (AD: exceptions are for bugs); loud failure on an unreachable state. Fix adds a guard. | reject |
| 2 | edge+blind | Save is silent while `_payerId` is null | low | Default payer comes from a local stream that resolves on the first frame; no-Member groups can't reach `add` from the UI. Fix adds a branch. | reject |
| 3 | edge | `defaultPayerIdProvider` error never selects a Payer | low | Errors only on a DB fault (a bug path). Fix adds a branch. | reject |
| 4 | edge | *Other* before an Amount hides the keypad | false | EXPERIENCE.md:128 and UX-DR22 require the keypad to be replaced in the *Other* state; switching Category brings it back. | reject |
| 5 | edge | Input changed during an in-flight save is dropped | low | The save takes milliseconds and then the screen closes; fix adds guards. | reject |
| 6 | edge+blind | `/group/:id/add` for an unknown id or <2 Members | low | No UI path reaches it (Add disabled; ids come from the router's own links). Fix adds a redirect branch. | reject |
| 7 | edge+blind | `nowUtc` goes stale across midnight | low | Real, but only until the next rebuild (any write or navigation); fix needs a timer or lifecycle hook. | reject |
| 8 | edge | Members still loading flashes the hint and "0 משתתפים" | low | At most one frame on a local DB; the same `?? 0` existed before this story. Fix adds loading branches. | reject |
| 9 | edge | `ExpenseList` State reused across groupId | false | Each `group/:id` route builds `NoTransitionPage(key: state.pageKey)`, so a different id gets a new element and new State. | reject |
| 10 | edge | `_SlideIn` disposed mid-animation re-animates | low | The new row is at the top and on screen right after the save; the user can't scroll it away within 250ms in practice. | reject |
| 11 | edge+blind | Save-once returns another Group's row for a reused id | false | The id is a UUID v7 made once per form (`_formId = newId()`); it can't collide with another form's id. | reject |
| 12 | blind | Save-once is checked after mutability | false | A retry with the same id only happens inside one in-flight submit; archiving needs leaving the form, which drops its id. | reject |
| 13 | blind | All avatars at 55% before a default Payer exists | low | `payer_picker.dart` passes `member.id == selectedId`, so `null` dims everyone; fix is a direct correction (pass `null` when nothing is selected). | patch |
| 14 | blind | The Exit sheet can open during an in-flight save | low | Window is milliseconds; fix adds a guard. | reject |
| 15 | blind | No Description length limit | low | The spec sets no bound (glossary: "short free text"); adding one is new behaviour with no spec value. The row title wraps rather than breaking. | reject |
| 16 | blind | The message slot clips at text scale 1.5 | false | EXPERIENCE.md:129 mandates a single reserved line so errors never shift the layout; `maxLines: 1` is the spec. | reject |
| 17 | blind | Stripe draws a gap beside a zero-width tiny segment | low | Needs a ₪0.10 Category next to a ≥₪10,000 one; cosmetic; fix adds min-width logic. | reject |
| 18 | blind | Slide-in restarts when Expenses arrive close together | false | Expenses are added one per Add screen visit; two inserts can't land within one 250ms animation. | reject |
| 19 | verify+blind | No test for the Trip total on the Archive card | medium | Searched `test/`: the only `ArchivedGroupCard` test has no Expenses; a wrong lookup would pass. | patch |
| 20 | verify | No widget test for the category share stripe | medium | Only `categoryTotals` is unit-tested; no test pumps `CategoryStripe` on the Group page. | patch |
| 21 | verify | Slide-in tested only for a new row | medium | No test asserts no slide-in on first show, or an instant show with `disableAnimations`. | patch |
| 22 | blind | Stale doc comment in `group_card.dart` | low | Class doc still says "the name and the Member count"; direct edit. | patch |
| 23 | blind | `StateError` docs vs. uncaught in notifier | false | By design: a non-Member Payer is a bug, which CLAUDE.md says should throw. | reject |
| 24 | blind | No `dd.mm` row-display or RTL anatomy test | low | `formatExpenseTime` is unit-tested for both formats; RTL anatomy is a manual check in Verification. | reject |

## Verification

**Commands:**
- `dart run drift_dev make-migrations` -- writes v3 snapshot and step test
- `flutter analyze` -- "No issues found!"
- `flutter test --timeout 60s` -- all pass

**Manual checks:**
- On emulator-5554: Add expense layout (no scrolling above keypad, ₪ tinted), slide-in, RTL row anatomy.
