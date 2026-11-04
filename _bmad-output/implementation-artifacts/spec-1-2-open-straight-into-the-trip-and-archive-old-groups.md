---
title: 'Story 1.2: Open straight into the trip, and archive old Groups'
type: 'feature'
created: '2026-11-04'
status: 'done'
route: 'dispatch'
baseline_commit: '0e3ce4b17b8a34842d8e7c101101ff3a37a842c2'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-1-context.md'
  - '{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-groupay-2026-10-26/EXPERIENCE.md'
  - '{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-groupay-2026-10-26/DESIGN.md'
  - '{project-root}/CLAUDE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Every launch opens the group list, there is no Active group, and old Groups can never be put away, so the checkout flow does not start at zero taps and the list grows forever.

**Approach:** Build FR6–FR9 (epics.md lines 403–515): schema v2 (`groups.archivedAt`, single-row `app_settings.activeGroupId`), the policies `isGroupMutable`/`mayArchive`/`mayRestore`/`maySetActive`, the Active-group sheet (Create group and the settings toggle), launch into the Active group, and archive/restore with a read-only archived Group page and an Archive view.

**Decisions:**
- Copy and states come verbatim from EXPERIENCE.md lines 71–72, 87–107, 136–177 and DESIGN.md lines 259–260, 331–341.
- Group list: Active group first (6dp orange start edge, badge "⭐ פעילה"), then the others newest first by `groupSeq`; archived Groups are hidden. "🗂 ארכיון (n)" under the last card, hidden when n = 0.
- Archive view at `/archive` (Motty's decision): the group-list gradient header with the nav line "→ הקבוצות שלי" (→ `/`) over the title "ארכיון", and no bottom bar. Gray cards newest first, each with "↩ שחזור". A card opens `/archive/group/:id` (read-only page, nav "→ ארכיון", badge "🗂 בארכיון", no chip, archive note above a bottom bar whose primary is "↩ שחזור מהארכיון").
- Restore (card or page) has no confirmation, does not make the Group active, then `go('/group/:id')`. Archive confirm → `go('/')`.
- Group settings gains a "קבוצה פעילה" toggle row (in the name card) and a single-row card "🗂 העברה לארכיון" after the Members.

## Boundaries & Constraints

**Always:**
- Part 1.1 rules hold (layering, one `db.transaction` per action → `Result<T>`, in-flight guards, no literals in feature `ui/`, `NoTransitionPage`).
- `app_settings` is written only by `groups/data`; no shared_preferences. Archive clears `activeGroupId` in the same transaction. At most one Active group; an Archived group is never active.
- `mayArchive`, `mayRestore`, `maySetActive` never call `isGroupMutable`. renameGroup, addMember, renameMember, removeMember check `isGroupMutable` inside their transactions and return `Failure(MessageKey.groupArchived)`.
- `shell/main.dart` reads `activeGroupId` before `runApp` → `initialLocation` `/group/:id`, else `/`. A router redirect sends `settings` (and later `add`/`edit`) of an Archived group to its read-only page.
- `schemaVersion` 2 via `make-migrations`; commit `drift_schema_v2.json` and the generated step test.

**Never:** No expenses or summary code, no Trip total change, no `PayerUsagePort` change, no Group deletion.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Create, none active | Save "Budapest" on stage 1 | Sheet (no warning) at once; "כן" → Budapest active; any answer → stage 2 | N/A |
| Create, Eilat active | Save "Budapest" | Sheet with "הקבוצה 'Eilat' תפסיק להיות הקבוצה הפעילה"; "כן" → only Budapest active; "לא עכשיו"/scrim/back → Eilat stays | N/A |
| Toggle on, none active | Settings of Budapest | Active at once, no sheet | N/A |
| Toggle on, Eilat active | Settings of Budapest | Sheet; toggle stays off until "כן"; cancel → off, Eilat stays | N/A |
| Toggle off | Budapest active | Unset at once; list has no "⭐ פעילה" | N/A |
| Launch | Active set / unset | Opens `/group/:id` / `/` with no flash | N/A |
| Archive active Group | Confirm Archive sheet | Archived + `activeGroupId` cleared in one tx; lands on list; "🗂 ארכיון (1)" | "ביטול"/scrim/back → nothing |
| Writes on archived | rename, add/rename/remove Member, set active | Nothing written | `Failure(groupArchived)` |
| Restore | "↩ שחזור" on card or page | Members unchanged, not active, Group page editable; back → list | N/A |
| Name taken by archived | Create "Budapest" while archived | No Group created | `groupNameTaken` |
| Archive twice / restore unarchived | Repository call | Nothing written | `Failure` from `mayArchive`/`mayRestore` |

</frozen-after-approval>

## Code Map

- `lib/core/db/tables/groups.dart` -- add nullable `archivedAt` int. New `lib/core/db/tables/app_settings.dart`: `id` int PK with `CHECK (id = 1)`, nullable `activeGroupId` text FK → `groups.id`. Register in `app_database.dart`, `schemaVersion` 2, `onUpgrade` from 1: `addColumn` + `createTable` (use make-migrations' generated `stepByStep`).
- `lib/core/policy/group_rules.dart` (new) -- `isGroupMutable`, `mayArchive`, `maySetActive` take `({bool isArchived})` and deny an archived Group with `groupArchived`; `mayRestore` denies a non-archived Group with `groupNotArchived` (internal key, text 'הקבוצה לא בארכיון'). Pattern: `member_rules.dart` + `verdict.dart`.
- `lib/core/i18n/message_key.dart` -- add from EXPERIENCE: Active sheet title/body/confirm/decline/warning `{name}`, `activeToggle('קבוצה פעילה')`, `activeBadge`, `archivedBadge`, `archiveLink('🗂 ארכיון ({n})')`, `archiveAction`, archive sheet title `{group}`/body/confirm, `restore('↩ שחזור')`, `restoreFromArchive`, `archiveNote`, `archiveNav('→ ארכיון')`, `archiveTitle('ארכיון')`, `archiveBackNav('→ הקבוצות שלי')`, `groupArchived` (internal failure, text = the short archive note).
- `lib/features/groups/domain/group.dart` -- `Group.archivedAt` (nullable) + `isArchived`; `GroupListItem.isActive`. `group_repository.dart` -- `watchGroups()` (non-archived, Active first), `watchArchivedGroups()`, `watchActiveGroupId()`, `readActiveGroupId()`, `setActive({id})`, `unsetActive({id})`, `archive({id})`, `restore({id})`.
- `lib/features/groups/data/drift_group_repository.dart` -- implement them; add the `isGroupMutable` check to `renameGroup`. `drift_member_repository.dart` -- read the Group's `archivedAt` in add/rename/remove and call `isGroupMutable` first.
- `lib/features/groups/app/group_providers.dart` -- `archivedGroupList`, `activeGroupId` stream providers; `SetActive`, `UnsetActive`, `ArchiveGroup`, `RestoreGroup` notifiers with the in-flight guard. Run `dart run build_runner build`.
- `lib/core/ui/widgets/app_sheet.dart` -- `AppSheetLayout` gains optional `warning` (strip on `badgeActiveSurface`). New `active_group_sheet.dart` → `Future<bool?> showActiveGroupSheet(context, {String? currentActiveName})`. Reuse `confirm_sheet.dart` for Archive (non-danger primary: pass a style param).
- `lib/core/ui/widgets/group_header.dart` -- optional `badgeLabel` on the nav line.
- `lib/features/groups/ui/` -- `group_list_screen.dart` (active card edge + badge, archive link); new `archive_screen.dart`; `group_page.dart` (`readOnly` from `isGroupMutable`: badge, no chip, nav "→ ארכיון" → `/archive`, note + restore bar); `group_settings_screen.dart` (toggle row, archive row); `create_group_screen.dart` (show the sheet after stage-1 Ok, then stage 2).
- `lib/shell/router.dart` -- `/archive` with child `group/:id`; async redirect on `group/:id/settings` using a `Future<bool> Function(String id) isArchived` argument. `lib/shell/main.dart` -- open DB, `await readActiveGroupId()`, pass `initialLocation`. Expose a pure `initialLocationFor(String? activeId)` for the launch test.
- `test/support/app_harness.dart` -- reuse; widget tests end with `unmountGrouPay`, run with `--timeout 60s`.

## Tasks & Acceptance

**Execution:**
- [x] `lib/core/db/**`, `drift_schemas/`, `test/core/db/**` -- schema v2, make-migrations, committed snapshot and generated migration test.
- [x] `lib/core/policy/group_rules.dart`, `test/core/policy/group_rules_test.dart` -- the four policies, unit-tested.
- [x] `lib/features/groups/{domain,data,app}/**` -- entities, repository methods, the mutable guard on 1.1 writes, notifiers.
- [x] `lib/core/i18n/message_key.dart`, `lib/core/ui/widgets/{app_sheet,active_group_sheet,confirm_sheet,group_header}.dart` -- keys, warning strip, sheets, badge.
- [x] `lib/features/groups/ui/**` -- list, Archive view, read-only page, settings toggle/archive, create-group sheet.
- [x] `lib/shell/{router,main}.dart` -- routes, redirect, launch location.
- [x] `test/**` -- repository tests (`NativeDatabase.memory()`) for every matrix row; launch-location test for both cases; widget flows: create with/without active, toggle with sheet cancel/confirm, archive → list → Archive → read-only page → restore.

**Acceptance Criteria:**
- Given the finished story, when `flutter analyze` and `flutter test --timeout 60s` run, then both pass with zero issues.
- Given the emulator with "Eilat" active, when the Organizer creates "Budapest" and confirms the sheet, kills and relaunches the app, then Budapest's page opens directly; after archiving Budapest the next launch opens the group list.

## Implementation Notes

- Added `GroupRepository.readGroup(id)` (not in the Code Map): the router's archived check needs a one-shot read; `watchGroup(id).first` never resolved inside widget tests.
- Archive and restore change only `archivedAt` (not `modifiedAt`), so a restored Group comes back exactly as it was.
- `app_settings` uses `customConstraints: ['CHECK (id = 1)']` instead of `.check()` to keep analyze clean.
- New tokens: `AppSizes.startEdge` (6dp) and `AppTextStyles.link` (14sp semibold). Cards moved to `group_card.dart`. `showConfirmSheet` gained `destructive` (Archive uses the orange primary).
- The "סיכום" button beside "↩ שחזור מהארכיון" arrives with Story 1.4.
- Verified in the project folder: `flutter analyze` no issues; `flutter test --timeout 60s` 230 passed. Emulator check still pending.

## Spec Change Log

## Review Triage Log

| # | Source | Finding | Verdict | Evidence | Route |
|---|--------|---------|---------|----------|-------|
| 1 | blind, edge | While a restore is in flight `onRestore` is `null`, so the inner GestureDetector has no recognizer and the tap falls through to the card's `onTap` | low | Confirmed in `group_card.dart`: a null `onTap` registers no tap recognizer; the tap opens `/archive/group/:id` mid-restore. Fix is a one-token direct correction | patch |
| 2 | verification-gap | `SetActive`, `UnsetActive`, `ArchiveGroup`, `RestoreGroup` in-flight guards are not pinned by any test | medium | Pre-verified: `_SlowRepos` stubs throw `UnimplementedError`; deleting `if (state) return null;` keeps every test green | patch |
| 3 | verification-gap, blind | `main()`'s launch wiring (Active group read before `runApp`, `isArchived` redirect closure) is never executed by a test; `launch_test.dart` re-implements it, and the helpers live in the entry-point file | medium | Pre-verified: dropping `initialLocation` in `main()` keeps all tests green. Fix extracts a shell-only bootstrap function used by `main()` and the harness (shell is the composition root; no feature imports it) | patch |
| 4 | blind, edge | UI ignores `Failure` from setActive/unsetActive/archive/restore | false | Every failure path is unreachable from the UI: settings is redirected for an Archived group, archive ends with `go('/')`, the Archive list is a live stream so a restored card disappears, and buttons are disabled while in flight. The spec allows a snackbar only for "ההוצאה נמחקה" | rejected |
| 5 | blind | No semantics labels on the Switch row, archive link, restore button or archive row | low | True for TalkBack, but the single-Organizer app is not used with a screen reader day to day; GestureDetector rows are the part-1.1 pattern (1.1 triage #14) | rejected |
| 6 | blind | Double tap on the toggle can stack two Active-group sheets before the in-flight guard turns on | low | Needs two taps inside the microtask gap before the modal sheet mounts; the fix adds a local busy flag | rejected |
| 7 | blind, edge | `/group/:id` of an Archived group is not redirected, so back goes to the list while the nav says "→ ארכיון" | false | Unreachable: launch never targets an Archived group (archive clears the Active group), archive ends with `go('/')`, archived cards open `/archive/group/:id`, and the settings redirect targets `/archive/group/:id` | rejected |
| 8 | blind, edge | The Archive view has no empty or loading state | false | Unreachable empty: the link is hidden at 0, and every restore leaves the view with `go('/group/:id')`; no deep links in v1. The local stream emits within a frame | rejected |
| 9 | blind | Archive and restore do not update `modifiedAt` | low | A recorded decision (Implementation Notes): restore returns the Group exactly as it was; no reader depends on `modifiedAt` | rejected |
| 10 | blind, edge | The header Row (nav + Spacer + badge) may overflow at text scale 1.5 | false | The only labels are the fixed "→ ארכיון" and "🗂 בארכיון" (together about 220dp at 1.5 on a 360dp screen); the unbadged nav is a single short Text | rejected |
| 11 | blind | No golden tests for the new UI | false | CLAUDE.md requires goldens for the Summary only (Story 1.4) | rejected |
| 12 | blind | The archived-check `(isArchived: row.archivedAt != null)` is built in three places | low | No caller diverges today; consolidating adds an indirection | rejected |
| 13 | blind | Migration test argument order, implicit `archivedAt IS NULL`, long doc line, replaced header comment | low | The migration test body is make-migrations boilerplate; analyze is clean; cosmetic | rejected |
| 14 | blind | `unsetActive` does no existence or policy check, unlike the other writes | low | An unknown id writes nothing and harms nothing; unsetting needs no `Verdict` (FR-8 has no deny rule) | rejected |
| 15 | edge | Repeated `addMember` with an existing id after archiving returns `Failure(groupArchived)`, not `Ok` | low | Add-member is unreachable on an Archived group (settings redirected, stage 2 only for a new Group) | rejected |
| 16 | edge | The toggle renders off while `activeGroupIdProvider` loads; a tap then runs the set path | low | The local stream emits within a frame, and `_toggleActive` re-reads the Active group, so a tap still does the right thing | rejected |
| 17 | edge | A thrown `setActive` in `_offerActive` leaves Create group on stage 1 | false | Throws only on a bug or I/O fault, which are exceptions by design (CLAUDE.md) | rejected |
| 18 | edge | A throw from `readActiveGroupId` before `runApp` hangs launch | false | An I/O fault on DB open is an exception by design; no reachable failure shown | rejected |

## Verification

**Commands:**
- `dart run drift_dev make-migrations` -- writes v2 snapshot and step test
- `flutter analyze` -- "No issues found!"
- `flutter test --timeout 60s` -- all pass

**Manual checks:**
- On emulator-5554 run the acceptance flow; archived page shows the badge, note and restore bar in RTL.
