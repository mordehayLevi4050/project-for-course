---
title: 'Story 1.3 (part B): Fix and delete Expenses'
type: 'feature'
created: '2026-11-05'
status: 'done'
baseline_commit: '3556b7bbf98f3268fce5cf8d5e57863c1327d19f'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-1-context.md'
  - '{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-groupay-2026-10-26/EXPERIENCE.md'
  - '{project-root}/CLAUDE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** A recorded Expense cannot be corrected or removed: rows ignore tap and long-press, and the Remove-member sheet never warns that shares will be recalculated.

**Approach:** Build FR13, FR14 and the Expense parts of FR3/FR4/FR6 (epics.md lines 638–640, 678–730): Edit expense at `group/:id/edit/:eid`, `mayModifyExpense`, Delete by long-press or the "🗑 מחיקה" chip, view-only rows in an Archived group, and the Remove-member sheet body.

**Decisions:**
- Scope = the part B entry in `deferred-work.md` (Motty, 2026-11-04). Story 1.3 is done after this part.
- Edit meta line (EXPERIENCE.md:94, Motty): "נרשם {time}", plus " · נערך {time}" only when `modifiedAt != createdAt`; both via `formatExpenseTime`. It sits on its own line under the Amount, above the message slot (mockup secondary-screens #3).
- Remove-member body (Motty): shown only when the Group has Expenses; "ההוצאות יתחלקו מחדש בין {n} המשתתפים הנותרים." with n = Members − 1, or "כל ההוצאות יחולו על המשתתף הנותר." when n = 1. Added to EXPERIENCE.md:99 and the `MessageKey` table.
- Saving an Edit with no field changed closes the screen and writes nothing (`modifiedAt` stays, so no "נערך").
- Copy verbatim from EXPERIENCE.md lines 79, 94, 99–102, 116, 122, 131, 158, 167–168; DESIGN.md lines 324, 343.

## Boundaries & Constraints

**Always:**
- Part A rules hold (layering, one `db.transaction` → `Result<T>`, in-flight guards, no literals in feature `ui/`, `NoTransitionPage`, `isolateName()` for names).
- Edit and delete each check `mayModifyExpense` inside their transaction; an Archived group → `Failure(groupArchived)`, nothing written.
- Edit keeps `id`, `groupId`, `saveSeq`, `createdAt`; sets `modifiedAt` from the clock. Same validation as add (Amount bounds, Category, *Other* Description, Payer is a current Member). Description stored only for *Other*.
- Delete is SQL `DELETE`; deleting a missing id returns `Ok` and writes nothing. Every delete goes through the Delete sheet.
- Exit sheet on Edit = any field differs from the saved Expense.

**Never:** No schema change, no swipe gestures, no undo, no Summary, no change to the add path's behaviour.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Edit amount | tap ₪870 row, 87, Save | Fields prefilled; list ₪87 in same place; total −₪783; `createdAt` kept | N/A |
| Edit to 0 | ₪87 → 0, Save | Not saved | "סכום לא תקין" |
| Edit payer | Dana → Yossi, Save | `saveSeq` and time unchanged; next Add defaults to Yossi if it is the last row | N/A |
| Page 2 category | edit a 🍝 row with the two-page row | Row opens on page 2 | N/A |
| Meta | never edited / edited | "נרשם 10:00" / "נרשם 10:00 · נערך 12:00" | N/A |
| Edit, no change | ✕ / back / Save | Closes, no sheet, nothing written | N/A |
| Edit, changed | ✕ / back | Exit sheet | "המשך עריכה" keeps input |
| Delete | long-press or "🗑 מחיקה", "מחיקה" | Row gone, total −₪87, snackbar "ההוצאה נמחקה", no undo; from Edit → back on Group page | N/A |
| Cancel delete | "ביטול" / scrim / back | Unchanged | N/A |
| Delete sheet | 🛒, Motty, 87.4 | "🛒 אוכל ושתייה · מוטי · ₪87.4" + "אי אפשר לבטל את הפעולה." | N/A |
| Archived | tap / long-press row; `edit` route; repo update/delete | Nothing; route → `/archive/group/:id` | `Failure(groupArchived)` |
| Remove sheet | Expenses exist, 4 Members, ✕ Noa | Body "…בין 3 המשתתפים הנותרים." | "ביטול" changes nothing |
| Remove sheet, 2 Members | Expenses exist, ✕ one | Body "כל ההוצאות יחולו על המשתתף הנותר." | N/A |
| Remove sheet, no Expenses | ✕ | Title only, no body | N/A |
| Rename payer | Dana → "Danna" | All her rows show "Danna" | N/A |

</frozen-after-approval>

## Code Map

- `lib/core/policy/expense_rules.dart` -- add `mayModifyExpense(GroupStateFacts)` = `isGroupMutable` (spine line 100); unit-test.
- `lib/core/i18n/message_key.dart` -- add `deleteChip('🗑 מחיקה')`, `deleteTitle`, `deleteBody('אי אפשר לבטל את הפעולה.')`, `deleteConfirm('מחיקה')`, `expenseLine('{emoji} {title} · {payer} · {amount}')` (amount = `formatShekel`, already has ₪), `expenseDeleted`, `recordedMeta('נרשם {time}')`, `editedMeta(' · נערך {time}')`, `removeMemberBodyOne`. Reuse `removeMemberBody` (line 139), `cancel`.
- `lib/features/expenses/domain/expense_repository.dart` -- add `watchExpense(id)` (nullable), `update({id, payerId, amount, category, description})`, `delete({id})`.
- `lib/features/expenses/data/drift_expense_repository.dart` -- implement; reuse `_checkMutable`'s group read for the facts and the add validation (extract a shared private validator). Unknown id on update → `StateError`.
- `lib/features/expenses/app/expense_providers.dart` -- `expenseProvider(id)`, `EditExpense` and `DeleteExpense` notifiers (copy `AddExpense` guard).
- `lib/features/expenses/ui/add_expense_screen.dart` -- turn into one form for add and edit (`expenseId` optional): prefill once from `expenseProvider`, Category picker already opens on the selected page (`category_picker.dart` `_controllerFor`), meta line row (add it to `_TopMetrics` when editing), `CompactTopBar` gets an optional end-side `action` (the danger chip, 48dp hit area). Unsaved = differs from saved values.
- `lib/core/ui/widgets/compact_top_bar.dart` -- optional end-side action replacing the empty `slot`.
- `lib/core/ui/widgets/delete_sheet.dart` (new) -- `showDeleteSheet(context, line:)` on `showConfirmSheet`.
- `lib/core/ui/widgets/snackbar.dart` (new) -- `appMessengerKey` + `showAppSnackbar(MessageKey)`; `lib/shell/app.dart` sets `scaffoldMessengerKey`. Floating, above the Group page bottom bar (`app_theme.dart:112`).
- `lib/features/expenses/ui/expense_list.dart` -- `onTap`/`onLongPress` per row (`InkWell` inside the card's clip); `null` in read-only mode. Group page passes them when `isGroupMutable`.
- `lib/features/groups/ui/member_list.dart:54` -- body from `groupTotalsProvider` (`group_providers.dart:237`; a total present ⇔ the Group has Expenses) and the Member count; used on both Create group stage 2 and settings.
- `lib/shell/router.dart` -- `edit/:eid` under `group/:id` with `archivedRedirect`.
- `_bmad-output/planning-artifacts/ux-designs/ux-groupay-2026-10-26/EXPERIENCE.md:99` -- add the singular body.

## Tasks & Acceptance

**Execution:**
- [x] `EXPERIENCE.md`, `lib/core/{policy,i18n}/**` + unit tests -- policy, keys.
- [x] `lib/features/expenses/{domain,data,app}/**` + repository tests on `NativeDatabase.memory()` -- update/delete matrix rows, archived refusal, `saveSeq`/`createdAt` kept, `defaultPayer` after a Payer edit and a delete.
- [x] `lib/core/ui/widgets/**`, `lib/shell/**` -- chip, delete sheet, snackbar, route.
- [x] `lib/features/expenses/ui/**`, `lib/features/groups/ui/member_list.dart` -- edit form, row gestures, remove body.
- [x] `test/**` widget flows -- every matrix row, incl. page-2 at text scale 1.5, no swipe-delete, archived rows inert.

**Acceptance Criteria:**
- Given the finished part, when `flutter analyze` and `flutter test --timeout 60s` run, then both pass with zero issues.
- Given the emulator with an Active group, when the Organizer edits a row's Amount, deletes another by long-press, force-stops and relaunches, then the edit, the deletion and the total persist and the edited row shows "נערך".

## Implementation Notes

## Spec Change Log

## Review Triage Log

| # | Source | Finding | Verdict | Evidence | Route |
|---|--------|---------|---------|----------|-------|
| 1 | verify | No UI test for editing only an *Other* Description (save + Exit sheet) | medium | Pre-verified: no test edits only the Description; inverting the clause in `_hasUnsavedInput` passes all tests. | patch |
| 2 | verify+blind | Delete-sheet line for an *Other* Expense (isolated Description) untested | medium | Pre-verified: sheet-line tests use foodDrink/hotel only. | patch |
| 3 | verify+blind | Missing-Expense redirect from `edit/:eid` untested | low | Pre-verified; new branch from this change; one cheap widget test. | patch |
| 4 | edge+blind | Save tap during an in-flight chip delete → `update` throws `StateError` | low | `_delete` reads `_saving` but never sets it; Save stays enabled after the sheet closes. Setting the flag is a direct correction. | patch |
| 5 | edge+blind | `edit/:eid` with an Expense from another Group | low | Ids come only from the router's own row links (same as part A #6); reaching it needs a crafted link; fix adds a branch. | reject |
| 6 | edge | `expenseProvider` error leaves a blank Edit screen | low | Errors only on a DB fault (bug path, part A #3). | reject |
| 7 | edge+blind | Long-press delete `Failure` is silent | false | The only Failure is `groupArchived`, and long-press is `null` in an Archived group (`group_page.dart` `readOnly`). | reject |
| 8 | edge+blind | Remove-member body missing while `groupTotalsProvider` loads | low | `MemberList` watches it in `build`; a local stream emits before a ✕ tap is possible. | reject |
| 9 | edge | Title off-centre when the chip is wider than the start slot | low | Cosmetic; equal-width slots need measuring logic. | reject |
| 10 | edge | AC "edited row shows נערך" vs row meta | false | Fix would edit this spec; "נערך" lives on the Edit meta line by design (EXPERIENCE.md:94). | reject |
| 11 | blind | Remove sheet opens with no Expenses, contra UX-DR27 | false | Motty's part 2b decision: ✕ always opens the sheet (spec-1-1-part-2b line 29). | reject |
| 12 | blind | `epics.md` 198/682/721 still has the old meta/body wording | medium | Pre-existing drift since Motty's decisions; EXPERIENCE.md is updated; planning-doc reconciliation. | defer |
| 13 | blind | Snackbar inset duplicates the bottom-bar sum in the theme | low | Only one snackbar exists; the flow test asserts it sits above the bar, so a padding change fails loudly. | reject |
| 14 | blind | `modifiedAt == createdAt` same-ms edit; stale clock in build | low | An edit is a later user action; stale clock is part A #7. | reject |
| 15 | blind | `_category!` force-unwrap in Edit | false | After `_prefill` `_category` is set and the picker cannot deselect. | reject |
| 16 | blind | Other missing tests (cross-group id, archived Failure in Edit, loading totals) | low | Paths rejected above (5, 7, 8); archived Edit is redirected by the router. | reject |
| 17 | blind | No golden for the Edit layout | false | CLAUDE.md requires goldens for the Summary only. | reject |
| 18 | blind | Row lacks semantics for tap/long-press | low | `InkWell` exposes tap and long-press semantics actions itself. | reject |
| 19 | blind | Emoji and ₪ amount not isolated in the Delete line | false | `formatShekel` wraps the amount in LRI…PDI (`format_shekel.dart:17`). | reject |

## Verification

**Commands:**
- `flutter analyze` -- "No issues found!"
- `flutter test --timeout 60s` -- all pass

**Manual checks:**
- On emulator-5554: Edit layout still fits without scrolling above the keypad; chip on the end side; snackbar above the bottom bar; Delete sheet text.
