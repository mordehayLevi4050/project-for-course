---
title: 'Story 1.1 (part 2b): Group settings — rename and remove Members, rename the Group'
type: 'feature'
created: '2026-11-03'
status: 'done'
route: 'dispatch'
baseline_commit: 'cdf0dd53fdb9d7cf00c5fd4b07dbe87c3fcbd9f9'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-1-context.md'
  - '{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-groupay-2026-10-26/EXPERIENCE.md'
  - '{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-groupay-2026-10-26/DESIGN.md'
  - '{project-root}/CLAUDE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** After part 2a, a Group's name and Members cannot be changed. The "⚙ ✎" chip on the Group page does nothing.

**Approach:** Build FR3, FR4 and FR5 (epics.md lines 354–393). The chip opens Group settings at `/group/:id/settings`. Renames use a Rename sheet built on a new `showAppSheet<T>()`. ✕ removes a Member through `mayRemoveMember`, with facts from `PayerUsagePort`. The same ✎/✕ Member rows also appear on Create group stage 2.

**Decisions:**
- Group settings has a compact top bar with "→" back (mockup 5) and the title "הגדרות קבוצה". Back or "→" returns to the Group page.
- Rows: a settings card "שם הקבוצה" with the value "{name} ›", which opens the Rename sheet. Then the section label "משתתפים ({n})", the Member rows, and a last row "+ הוספת משתתף". Tapping that row replaces it with the part-2a add-member field (focused), which stays open after each add.
- Member rows keep the FR2 avatar (circle with the `avatarLabel` under it, confirmed by Motty), with ✎ and ✕ on the end side.
- The Rename sheet opens pre-filled with the current name. "שמירה" saves while the sheet is open: an error shows inside the sheet and the sheet stays open; success closes it. "ביטול", the scrim or back closes it and writes nothing.
- ✕ always opens a Remove-member confirm sheet first (Motty's decision; this overrides EXPERIENCE.md/UX-DR27 "no Expenses → removed immediately"), in Group settings and on Create group stage 2. The sheet has the title "להסיר את {name}?" (`removeMemberTitle`, name through `isolateName()`), no body, and the buttons "הסרה" (`removeMemberConfirm`, button-danger, start side) and "ביטול". "הסרה" closes the sheet and runs the removal. "ביטול", the scrim or back writes nothing.
- A refusal ("לא ניתן להסיר משתתף שיש הוצאה על שמו") shows inline under that row after "הסרה" and replaces any earlier refusal.
- Deferred: the Active toggle and "🗂 העברה לארכיון" (Story 1.2). Story 1.3 adds the body line "ההוצאות יתחלקו מחדש בין {n} המשתתפים הנותרים." to the same sheet when the Group has Expenses.

## Boundaries & Constraints

**Always:**
- The part-2a rules still hold: layering, one `db.transaction` per action returning `Result<T>`/`Failure(MessageKey)`, `normalizeNameWithin` and `nameKey` (Group 20, Member 10), `clockProvider` times, notifiers that ignore calls while a save is in flight, and no Hebrew, color, size or radius literals in feature `ui/`.
- A rename checks uniqueness against everyone except the item being renamed (by `nameKey`), so a case-only or unchanged rename succeeds. It updates `name`, `nameKey` and `modifiedAt`, never `createdAt` or the seq.
- Remove: gather `isPayer` from `PayerUsagePort` inside the transaction, call `mayRemoveMember`, then SQL `DELETE`. Removing a Member that no longer exists returns `Ok` and writes nothing.
- `showAppSheet<T>()` lives in `core/ui/widgets`. It uses the DESIGN bottom-sheet tokens and `AppAnimation.sheetSlide`, and resolves `null` when dismissed. It is never a centered dialog.
- The route is `NoTransitionPage`, a child of `group/:id`.

**Never:** No `app_settings`, archive or `isGroupMutable` code. No new `core/policy` rule. No expenses code. No change to the `PayerUsagePort` stand-in. No schema change.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Rename Member | "Dana" → "Danna" | The row shows "Danna"; `modifiedAt` changes, `createdAt` and `memberSeq` do not | N/A |
| Case-only rename | "dana" → "Dana" | Saved, no error | N/A |
| Rename Member invalid | "Dana" → "" / "Yossi" (exists) | Name stays "Dana" | `nameRequired` / `memberNameTaken` in the sheet |
| Rename Group | "Budapest" → "Budapest 2026" | Shown in the list, on the Group page and in settings | N/A |
| Rename Group invalid | "Budapest" → "  " / "Eilat" → "Budapest" | Name unchanged | `nameRequired` / `groupNameTaken` in the sheet |
| Unchanged rename | "Budapest" → "Budapest" | Ok, no error | N/A |
| Dismiss sheet | Edit text, then "ביטול" / scrim / back | Nothing written | N/A |
| Remove | No Expenses; ✕ on "Dana", then "הסרה" | The sheet shows "להסיר את Dana?"; then the row disappears and is deleted | N/A |
| Cancel remove | ✕ on "Dana", then "ביטול" / scrim / back | Dana stays; nothing written | N/A |
| Remove a Payer | The port reports `isPayer`; ✕, then "הסרה" | Nothing removed | `memberIsPayer` inline under the row |
| Field limits | 11th char in a Member rename, 21st in a Group rename | Blocked | N/A |

</frozen-after-approval>

## Code Map

- `lib/features/groups/domain/{group,member}_repository.dart` -- add `renameGroup({id, name})`, `renameMember({id, name})` and `removeMember({id})`.
- `lib/features/groups/data/drift_{group,member}_repository.dart` -- implement them following the existing `createGroup`/`addMember` pattern. `DriftMemberRepository` gains a `PayerUsagePort` constructor argument.
- `lib/core/ports/payer_usage_port.dart`, `port_providers.dart` -- consume. `lib/shell/payer_usage_stand_in.dart` -- leave unchanged.
- `lib/features/groups/app/group_providers.dart` -- add `RenameGroup`, `RenameMember` and `RemoveMember` notifiers with the same in-flight guard.
- `lib/core/policy/member_rules.dart` -- reuse `mayRemoveMember` (it denies with `memberIsPayer`).
- `lib/core/ui/widgets/` -- new `app_sheet.dart` (`showAppSheet<T>()`), `rename_sheet.dart` and `confirm_sheet.dart` (`showConfirmSheet(context, title:, confirmLabel:, body: null)` → `true` on confirm, `null` on dismiss; danger confirm button with `AppColors.danger`/`onDanger`, secondary "ביטול"). The sheet takes the current name, the max length and `Future<MessageKey?> Function(String) onSave`. Reuse `name_field.dart`, `motion.dart` (`appAnimationDuration`) and tokens (`AppColors.scrim`, `AppRadii`, `divider`, `secondaryInk`, `inkSecondary`). Extend `compact_top_bar.dart` with an optional back control on the start side.
- `lib/core/i18n/message_key.dart` -- reuse `groupSettingsTitle`, `groupNameLabel`, `addMember`, `renameTitle`, `save`, `cancel`, `removeMemberTitle`, `removeMemberConfirm` and `memberIsPayer` (`removeMemberBody` stays unused until Story 1.3). Add `back('→')`, `membersCount('משתתפים ({n})')`, `rowValue('{value} ›')`, and ✎/✕ row glyph keys.
- `lib/features/groups/ui/` -- new `group_settings_screen.dart`. Extract the stage-2 `_MemberRow` and the add field into a shared `member_list.dart`, used by both `create_group_screen.dart` and settings. Wire the chip in `group_page.dart` to `context.go('/group/$id/settings')`.
- `lib/shell/router.dart`, `overrides.dart` -- add the `settings` child route and pass `payerUsagePortProvider` into `DriftMemberRepository`.
- `test/support/app_harness.dart` -- reuse `pumpGrouPay`/`unmountGrouPay`. Every widget test ends with `unmountGrouPay`. Run with `--timeout 60s`.

## Tasks & Acceptance

**Execution:**
- [x] `lib/features/groups/{domain,data,app}/` -- the rename and remove methods and notifiers.
- [x] `lib/core/i18n/message_key.dart`, `lib/core/ui/widgets/{app_sheet,rename_sheet,confirm_sheet,compact_top_bar}.dart` -- the keys, the sheet helper, the Rename sheet, the confirm sheet and the back variant.
- [x] `lib/features/groups/ui/{member_list,group_settings_screen,create_group_screen,group_page}.dart` -- the shared rows with ✎/✕ (✕ → confirm sheet) and inline refusal, the settings screen and the chip wiring.
- [x] `lib/shell/{router,overrides}.dart` -- the route and the port binding.
- [x] `test/**` -- repository tests on `NativeDatabase.memory()` for every matrix row, with a fake `PayerUsagePort` for the Payer row. A unit test for `showAppSheet` returning `null` on dismiss. Widget tests: chip → settings → rename Group (the list and Group page update) → rename a Member → ✕, "ביטול" keeps the Member → ✕, "הסרה" removes it → back to the Group page; the sheet errors; a ✎/✕ row with the confirm sheet on Create group stage 2.

**Acceptance Criteria:**
- Given the finished part, when `flutter analyze` and `flutter test --timeout 60s` run, then both pass with zero issues.
- Given the emulator with "Trip to Eilat" (Dana, Yossi), when the Organizer opens "⚙ ✎", renames the Group to "Eilat 2026", renames Dana to "Danna" and removes Yossi (✕, the sheet "להסיר את Yossi?", "הסרה"), then the Group page shows "Eilat 2026" and "משתתף אחד", and the group list card matches.

## Design Notes

The Rename sheet owns the save so that errors stay inside it. For example:
`showRenameSheet(context, current: m.name, maxLength: maxMemberNameLength, onSave: (n) async => switch (await notifier.submit(id: m.id, name: n)) { Ok() => null, Failure(:final message) => message, null => null })`.
The sheet pops with `true` when `onSave` returns `null`, so `showAppSheet` resolves `null` only on dismissal.
Removal: `if (await showConfirmSheet(...) == true) { final r = await removeNotifier.submit(id: m.id); /* Failure → inline refusal under the row */ }`. The confirm sheet does not own the save; the policy check still runs in the repository transaction.

## Verification

**Commands:**
- `flutter analyze` -- "No issues found!"
- `flutter test --timeout 60s` -- all pass

**Manual checks:**
- On emulator-5554, run the acceptance flow. Every screen is RTL Heebo, and the sheet slides up from the bottom.

## Review Triage Log

| # | Source | Finding | Verdict | Evidence | Route |
|---|--------|---------|---------|----------|-------|
| 1 | verification-gap | The Rename sheet's `_saving` guard is not pinned by any test; removing it lets the keyboard action re-submit, the notifier returns `null`, and the sheet closes as success while the first save may still fail | medium | Confirmed: `app_sheet_test.dart` never overlaps two saves, and the keyboard action is not gated by the disabled button | patch |
| 2 | blind, edge, verification-gap (other) | The rename call sites map an ignored notifier call (`null`) to success, so the sheet would close | low | Only reachable if a save is already in flight from another sheet (the sheet is modal and has its own `_saving` guard) or after a dismiss mid-save; a fix needs a new "busy" contract or key | rejected (low, rare, fix adds a branch and surface) |
| 3 | edge | Dismissing the sheet during an in-flight save still writes the rename | low | True, but a local SQLite write takes milliseconds; blocking the dismiss would add a guard on top | rejected (low, rare) |
| 4 | blind, edge | `_save` has no try/finally, so a `StateError` from `onSave` leaves the sheet stuck in "saving" | false | The `StateError` fires only for a missing Group/Member id. Groups are never deleted, and a Member can be removed only from the same screen, which the modal sheet blocks. Per the architecture, exceptions are bugs | rejected |
| 5 | blind | Rename (throws `StateError`) and remove (`Ok`) handle a missing id differently, and the rename behavior is undocumented | low | Confirmed: the interface docs do not mention the throw; the fix is one doc sentence | patch |
| 6 | blind, edge | Group settings has no loading/not-found state: briefly shows "משתתפים (0)", and a missing id shows a working add field | low | The stream emits within a frame (GroupPage uses the same pattern). A missing id is unreachable in v1: settings opens only from the chip of an existing Group, and there are no deep links | rejected (low, fix adds a branch) |
| 7 | edge | The settings route has no redirect for an unknown Group id | false | Unreachable: offline app, no deep links; the archived-group redirect is Story 1.2 | rejected |
| 8 | edge | `MemberAddField._add` has no catch for a thrown FK/I/O error | false | The FK failure needs a missing Group (unreachable, see 6); an I/O fault is an exception by design | rejected |
| 9 | blind | A refusal under a row is never cleared by a rename, another removal, or an add | false | The message stays true (that Member is still a Payer); the spec only requires replacement by a later refusal, which is implemented and tested | rejected |
| 10 | blind | The 10-Member cap is not handled or tested in Group settings | false | `MemberAddField` is the same widget as stage 2 and goes through the same `addMember` policy; the inline cap message is tested in part 2a; EXPERIENCE does not require hiding the row | rejected |
| 11 | blind | No RTL-placement test for the danger button, "→" or ✎/✕ | low | `Row` and `EdgeInsetsDirectional` follow `Directionality`; the LTR test proves start-side placement; no bad outcome shown | rejected |
| 12 | blind | The sheets may overflow at 150% text scale with the keyboard open | false | Probe: the Rename sheet with an error at 1.5 scale, 360×640 dp, 300 dp keyboard, RTL — no overflow or exception | rejected |
| 13 | blind | Tests use Latin names only | low | The Hebrew/Latin/mixed requirement in CLAUDE.md is for Summary goldens; `isolateName` and grapheme cuts are unit-tested in `core` | rejected |
| 14 | blind | The card decoration and four GestureDetector tap targets are duplicated; there is no pressed feedback | low | No named failure; GestureDetector was already the pattern in part 2a | rejected |
