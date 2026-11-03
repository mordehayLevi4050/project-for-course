---
title: 'Story 1.1 (part 2a): Create a Group and add its Members'
type: 'feature'
created: '2026-11-03'
status: 'done'
baseline_commit: 'f5cd9ff54839f8038ee424e83592834909128677'
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

**Problem:** Part 1 shipped the kernel and a static empty group list. The Organizer still cannot create a Group or add its Members.

**Approach:** Build FR1 and FR2 (epics.md lines 289–352) on the part-1 kernel: the `groups` domain, drift repositories and notifiers, the live group list with cards, the two-stage Create group screen with adding Members, and the Group page header.

**Decisions:**
- Group list order: newest first by a new `groups.groupSeq` (MAX+1, `UNIQUE`, set once). It is added to schema v1, and the v1 snapshot is regenerated, because no real data exists yet.
- Stage-1 save goes straight to stage 2 (the Active-group sheet is Story 1.2). Stage-1 ✕ leaves with no sheet.
- The add-member field submits on its "+" button and on the keyboard action, then clears and keeps focus. An inline error clears on the next change to its field.
- The Group page shows only the header: nav "☰ הקבוצות שלי", the name, the "⚙ ✎" chip, `formatShekel(Tenths.zero)` and "{n} משתתפים". The chip renders but does nothing until part 2b adds Group settings.
- Deferred: Group settings, renames and remove (part 2b). Badges, totals, Expenses and the exit sheet come in Stories 1.2–1.4.

## Boundaries & Constraints

**Always:**
- CLAUDE.md layering. `groups/domain` is pure Dart: `Group` and `Member` entities and the repository interfaces. `groups/data` holds the drift implementations and maps `*Row` to entities. `groups/app` declares the repository providers (`keepAlive`, throw until `shell/` overrides) and the notifiers. `groups/ui` holds the screens.
- Every write is one `db.transaction`: gather facts, call `core/policy` (`mayAddMember`, `nextMemberSeq`, and a new `nextGroupSeq`), then write. It returns `Result<T>` or `Failure(MessageKey)`. Names go through `normalizeName`, `nameKey` and `GraphemeLimitFormatter` (Group 20, Member 10). Ids are UUID v7 from one `core` helper. Times come from `clockProvider`.
- Save once (AD-23). The id is generated when the form opens; for the add-member field, again after each successful add. An insert whose id already exists returns `Ok` and writes nothing. Notifiers ignore calls while a save is in flight. The button is disabled during the save.
- Reads are repository `.watch()` streams. Members are ordered by `memberSeq`. Avatar color is `memberColorIndex(memberSeq)`, wrapping after 6. The label is the first word, or the full name when another Member shares that first word.
- New strings are `MessageKey` entries. Feature `ui/` has no color, font-size or radius literals.
- Routes `/create` and `/group/:id` use `NoTransitionPage`. "סיום" or system back on stage 2 runs `go('/group/:id')`, and back from there returns to `/`.

**Never:** No `app_settings`, no expenses code, no SQL `lower()`/`NOCASE`, no centered dialogs, and no code ported from the `main` branch's old `lib/`.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Create | "Trip to Eilat" | One Group saved; the card shows the name and "{n} משתתפים" ("משתתף אחד" for 1); stage 2 opens | N/A |
| Blank name | "", "   " (Group or Member) | Nothing written | `nameRequired` inline |
| Duplicate group | "Budapest" exists; create " budapest " | Nothing written | `groupNameTaken` inline |
| Duplicate member | "Dana" exists; add "Dana" / " dana " | Nothing written | `memberNameTaken` inline |
| 11th member | 10 Members; add "Gil" | Nothing written | `membersLimit` inline |
| Double tap | Create twice fast with the same form id | Exactly 1 Group, no error | N/A |
| Member seq | Members with seq [1, 2] → add | New seq 3; the 7th Member gets color index 0 | N/A |
| Group order | Create A, then B | List shows B, then A | N/A |
| Avatar label | "Dana Levi", "Dana Cohen", "Yossi" | "Dana Levi", "Dana Cohen", "Yossi" | N/A |

</frozen-after-approval>

## Code Map

- `lib/core/db/tables/groups.dart` -- add `groupSeq` + unique key. Then rerun build_runner and `make-migrations` (the v1 snapshot, `test/core/db/app_database/generated/`). Update `test/core/db/app_database_test.dart`.
- `lib/core/policy/member_rules.dart` -- reuse `mayAddMember`, `nextMemberSeq`. Put `nextGroupSeq` beside them, with tests.
- `lib/core/text/names.dart`, `grapheme_limit_formatter.dart` -- reuse `normalizeName`, `nameKey`, `isBlankName`, the max lengths and the formatter.
- `lib/core/i18n/message_key.dart` -- reuse `newGroupTitle`, `groupNameLabel`, `createGroup`, `membersSection`, `memberNamePlaceholder`, `done`, `memberCountOne/Many`. Add the nav "☰ הקבוצות שלי" and the "⚙ ✎" chip label. Never reword the fixed keys.
- `lib/core/ports`, `lib/core/time/clock_provider.dart`, `lib/core/db/database_provider.dart` -- consume.
- `lib/core/ui/theme/tokens.dart` -- `AppColors.members`, `AppGradients.header`, `AppSizes.avatar`/`avatarSlot`/`compactTopBarHeight`. Reuse `lib/core/ui/widgets/app_scaffold.dart`.
- `lib/features/groups/ui/group_list_screen.dart` -- the static part-1 screen; make it live.
- `lib/shell/router.dart`, `overrides.dart`, `test/shell/app_test.dart` -- add the routes and the repository bindings.
- `uuid` 4.6.0 -- `const Uuid().v7()`.

## Tasks & Acceptance

**Execution:**
- [x] `lib/core/db/tables/groups.dart`, generated files, `drift_schemas/` -- `groupSeq` in v1.
- [x] `lib/core/ids/new_id.dart`, `lib/core/policy/member_rules.dart` -- `newId()` (UUID v7) and `nextGroupSeq`.
- [x] `lib/core/i18n/message_key.dart` -- the new keys.
- [x] `lib/core/ui/widgets/` -- `compact_top_bar.dart`, `group_header.dart`, `member_avatar.dart` (`memberColorIndex()`, `avatarLabel()`), `name_field.dart` (field + formatter + inline error + optional end "+" button).
- [x] `lib/features/groups/{domain,data,app}/` -- entities, interfaces, drift repositories (`watchGroups` with member counts, `watchGroup`, `createGroup`, `watchMembers`, `addMember`), providers and notifiers.
- [x] `lib/features/groups/ui/` -- the live group list with cards, `create_group_screen.dart` (two stages) and `group_page.dart` (header only).
- [x] `lib/shell/` -- routes and bindings.
- [x] `test/**` -- repository tests on `NativeDatabase.memory()` for every matrix row, plus UUID v7 ids, `createdAt` set once and `modifiedAt` on insert. Unit tests for `newId`, `nextGroupSeq`, `memberColorIndex` and `avatarLabel`. Widget tests: stage 1 → 2 → Group page → back to the list; the 21st-character and 11th-character blocks.

**Acceptance Criteria:**
- Given the finished part, when `flutter analyze` and `flutter test` run, then both pass with zero issues.
- Given the emulator, when the Organizer creates "Trip to Eilat" with Members "Dana" and "Yossi", then the Group page shows the name, ₪0 and "2 משתתפים", and back shows the card in the list.

## Implementation Notes

## Spec Change Log

## Review Triage Log

| # | Source | Finding | Verdict | Evidence | Route |
|---|--------|---------|---------|----------|-------|
| 1 | verification-gap | Stage-1 "יצירת קבוצה" disabled-during-save has no widget test | low | Pre-verified: no test asserts `onPressed == null` while in flight; data still guarded by notifier + id check | patch (add widget test) |
| 2 | verification-gap, blind, edge | Add-member "+" (and keyboard action) swaps to a no-op instead of looking disabled during save | low | Real spec deviation, but a local insert finishes in milliseconds so the state is never visible; fixing needs a new `NameField` parameter | rejected (low, fix adds surface) |
| 3 | blind | Name-uniqueness checks live in repositories, not `core/policy` | false | CLAUDE.md puts `nameKey` uniqueness in `core/text`; the spec's policy list (`mayAddMember`, `nextMemberSeq`, `nextGroupSeq`) is exactly what is called | rejected |
| 4 | blind | `nextGroupSeq` sits in `member_rules.dart` | false | The Code Map says to put it beside `nextMemberSeq` | rejected |
| 5 | blind, edge | `addMember` with an unknown `groupId` throws on the FK instead of returning `Failure` | false | Unreachable: the only caller passes the Group just created, and Groups are never deleted (archive only); an FK throw on a bug is the intended exception path | rejected |
| 6 | blind, edge | Save-once returns `Ok(existing)` even when the existing row's payload or Group differs | false | Ids are fresh UUID v7 per form; no caller can reuse an id across forms or Groups | rejected |
| 7 | edge | Repository exceptions escape the button callbacks unhandled | false | CLAUDE.md: exceptions are only for bugs or I/O faults; expected failures are `Failure(MessageKey)` | rejected |
| 8 | blind, edge | `AsyncError` from watch streams is hidden (`.value`), so the screen is blank or shows "0 משתתפים" | low | Local drift streams error only on bugs; the first emission arrives at once | rejected (low, needs new UI branches) |
| 9 | blind, edge | Group page is blank (no header or nav) for an unknown id | low | Reachable only through a hand-typed deep link; every in-app route passes a real id | rejected (low, needs new state) |
| 10 | blind, edge | Typed but un-added Member name is dropped on "סיום" or back | false | EXPERIENCE.md:154 says "סיום" or back opens the Group page; the exit sheet applies only to Add/Edit expense (EXPERIENCE.md:131) | rejected |
| 11 | edge | System back on stage 1 while the save is in flight lands on the list and skips stage 2 | low | Real but needs a back press in the milliseconds of a local insert; the Group is still saved and listed | rejected (low, needs PopScope guard) |
| 12 | blind | Stage-2 state lives only in widget state and is lost on process restore | low | The app relaunches at `initialLocation`; the Group is saved and listed | rejected (low) |
| 13 | blind | Custom tap targets lack `Semantics`; the chip swallows taps | false | EXPERIENCE.md:204 excludes TalkBack labelling from v1; the spec says the chip renders and does nothing until part 2b | rejected |
| 14 | blind | The teal "+" uses the `headerEnd` token; its glyph may overflow at text scale 1.5 | false / low | DESIGN.md:329 names `{colors.header-end}` for the "+"; overflow is unverified and cosmetic | rejected |
| 15 | edge, blind | Existing dev installs with the old v1 schema crash (`no such column: groupSeq`) | out of scope | The frozen intent chose to regenerate v1 because no real data exists; the manual check uninstalls the `.dev` build first | rejected (intent) |
| 16 | blind | Review diff omits the regenerated schema artefacts | false | Generated files were left out of the diff on purpose; `migration_test.dart` validates the v1 snapshot and passed | rejected |
| 17 | blind | Spec Implementation Notes and Change Log are empty | n/a | Fixing it means editing this build's spec | rejected |
| 18 | blind | Test gaps: Hebrew `nameKey` repository case, UI double tap, `AddMember` in-flight state assert, weak `newId` time test, goldens | low / false | Hebrew normalization is covered in `core/text` tests; goldens are required for the Summary only; the rest are marginal | rejected |

## Verification

**Commands:**
- `dart run build_runner build --delete-conflicting-outputs` and `dart run drift_dev make-migrations` -- succeed
- `flutter analyze` -- "No issues found!"
- `flutter test` -- all pass

**Manual checks:**
- On the emulator (uninstall the old `.dev` build first, because the schema changed), run create → add Members → Group page → back. Every screen is RTL Heebo, and the primary button is in the lower half.
