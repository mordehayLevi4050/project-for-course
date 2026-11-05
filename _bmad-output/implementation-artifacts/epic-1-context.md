# Epic 1 Context: Shared Expense Splitting

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

The Organizer sets up a Group for a trip, records every shared Expense at the checkout one-handed and offline in at most 4 taps, and at the end of the trip gets one screenshot that shows who transfers how much to whom. This one epic is all of GrouPay v1, a Hebrew-first, RTL, offline Android app for a single phone. It starts from the throwaway Flutter scaffold and ends with a correct, minimal Transfer list on a Summary that friends can read from a screenshot alone.

## Stories

- Story 1.1: Create a Group and manage its Members (plus scaffold replacement and the shared kernel)
- Story 1.2: Open straight into the trip, and archive old Groups
- Story 1.3: Record, fix and delete Expenses at the checkout
- Story 1.4: Settle up with one screenshot

## Requirements & Constraints

- **Names:**
  - Length is counted in grapheme clusters: a Group name is at most 20 and a Member name at most 10.
  - The field blocks extra input, a paste is cut to the limit, and outer spaces are trimmed on save.
  - Uniqueness ignores case and outer spaces. Group names are unique across all Groups, Archived ones included. Member names are unique within their Group.
  - A rename is checked against everyone except the item being renamed, so a case-only rename is allowed.
  - If a name is rejected, nothing changes.
- **Members:**
  - A Group has at most 10 Members.
  - A Member who is the Payer of any Expense cannot be removed.
  - Every Expense is split equally among all current Members, including Members added later.
  - A rename never changes a Balance, but it may change which pairs appear in the Transfers.
- **Active group:**
  - At most one Group is active.
  - At launch, the app opens the Active group's page directly, or the Group list when no Group is active.
  - Right after a Group is saved, and before any Members are added, the app offers to make it active. It warns when another Group is already active.
  - An Archived group cannot be active. Archiving the Active group unsets it. A restored Group does not become active by itself.
- **Archive:**
  - Groups are never deleted.
  - An Archived group is read-only (its Expenses and Summary can still be viewed) until it is restored.
- **Expenses:**
  - *Add expense* and *Summary* are disabled while the Group has fewer than 2 Members.
  - The Amount must be greater than 0 and at most ₪1,000,000, with at most one decimal.
  - A Category is required. *Other* also requires a Description, and a Description is stored only with *Other*.
  - Invalid input stays on screen.
  - The default Payer is the current Payer of the Expense with the highest `saveSeq`. With no Expenses, it is the earliest-added Member.
  - The list shows the newest first by save order, never by the clock.
  - The recorded time is the time of the first save. Editing never changes it or the save order.
  - Every delete needs confirmation.
- **Tap budget:** recording an Expense from launch takes at most 4 taps with the default Payer and at most 5 with a changed Payer. A swipe counts as a tap. Typing the Amount does not count.
- **Transfer calculation:**
  - Everything is exact, in units of ₪0.10.
  - Share = total ÷ number of Members, rounded down.
  - The Leftover is taken off receivers only, starting with the smallest total paid. Between equal totals, the receiver whose first Expense was saved later goes first.
  - The list uses the fewest possible Transfers, and each Transfer goes from a negative Balance to a positive one.
  - Ties between minimal lists go to the lexicographically first (debtor, receiver) sequence under the Hebrew-first collation.
  - There is no minimum Transfer, so ₪0.1 is shown.
- **Summary:**
  - Each line reads "תשלום נדרש מ{debtor} ל{receiver} ₪N", with no arrows.
  - With 6 or fewer Members, the whole Summary fits one screen on a Galaxy S25 at the default font, with no scrolling.
  - With 7–10 Members, only the Transfer list scrolls.
  - The Summary must make sense from a screenshot alone.
  - Open check: 5 Transfers with wrapped long names must fit without scrolling, verified by a golden test or on the device.
- **Non-functional:**
  - Full Hebrew RTL. The 17 fixed messages must match the spec table exactly. "Member" is always "משתתף".
  - Amounts are shown in ₪ only, with no decimals when whole and exactly one otherwise.
  - Fully offline, with zero network calls. Data stays on the device.
  - Every save is all-or-nothing and survives a kill or a reboot.
  - Touch targets are at least 48dp. Primary actions sit in the lower half of the screen, on the right. Contrast meets WCAG AA. Font scale up to 150% must not clip text.
  - Performance: cold launch in 2 s or less, Save to Group page in under 300 ms, and the Summary of a 10-Member Group in 1 s or less.
  - Android 15 (API 35) and above.
- **Tests:**
  - Unit tests for every policy, text and money function.
  - Every required Transfer-calculation case, including a 10-Member case that runs in 1 s or less.
  - Repository tests on `NativeDatabase.memory()`.
  - The generated migration tests.
  - Summary golden tests with the bundled Heebo font, at text scale 1.0 and 1.5, with Hebrew, Latin and mixed names.

## Technical Decisions

- **Pinned stack:**
  - Flutter 3.47.7 and Dart 3.13.5.
  - drift 2.35.3, drift_flutter 0.3.1 and drift_dev 2.35.2.
  - build_runner 2.16.2 (2.17.x breaks riverpod_generator).
  - flutter_riverpod 3.4.3, riverpod_generator 4.0.9 and riverpod_annotation 4.0.7.
  - go_router 18.1.2, uuid 4.6.0, characters and the bundled Heebo font.
  - flutter_lints with zero warnings. The generated `*.g.dart` files are committed.
- **Slices and imports:**
  - Imports go downward only: `settle_up → expenses → groups`.
  - `groups` learns Expense facts through `PayerUsagePort` and `GroupTotalsPort` in `core/ports`. Both are implemented in `expenses/data` and depend only on `AppDatabase`.
  - Features navigate to each other by route path only.
- **Layer rules:**
  - `domain/` is pure Dart.
  - Only `data/` and `core/db/` import drift. All tables live in `core/db/tables/`. The generated `*Row` classes stay in `data/` and are mapped to domain entities.
  - Repository providers are declared in `app/` and throw until `shell/` overrides them. The database, repository and port providers are `keepAlive`.
- **Ownership:** `groups` writes the `groups`, `members` and `app_settings` tables. `expenses` writes `expenses`. `settle_up` only reads.
- **Writes:**
  - Each user action runs as one `db.transaction`: gather the facts, call the pure `core/policy` function (which returns a `Verdict`), then write.
  - Writes return `Result<T>` or `Failure(MessageKey)`. Guards never live only in the UI.
  - The policy set is closed: `isGroupMutable`, `mayArchive`, `mayRestore`, `maySetActive`, `mayAddMember`, `mayRemoveMember`, `mayModifyExpense`, `mayRecordExpense`, `maySummarize`, `defaultPayer`, `nextSaveSeq`, `nextMemberSeq`.
- **Save once:**
  - The UUID v7 is generated when the form opens. Inserting an id that already exists does nothing.
  - Notifiers ignore calls while a save is in flight. Save is disabled while saving, and the screen closes only after success.
- **Data model:**
  - `createdAt` and `modifiedAt` are UTC epoch-ms values set only by repositories, from one clock provider. An Expense's recorded time is its `createdAt`.
  - `memberSeq` and `saveSeq` are MAX+1 per Group, assigned once and unique per Group.
  - Members and Expenses are hard-deleted.
  - `groups.nameKey` is unique, Archived Groups included. `(members.groupId, nameKey)` is unique.
  - `expenses(groupId, payerId)` references `members(groupId, id)` with `ON DELETE RESTRICT`.
  - Category is a stable string key for a Dart enum.
  - No participants are stored.
  - The Active group is `app_settings.activeGroupId`.
  - Gap: the UX orders Group cards by a creation sequence, never the clock, but the architecture defines no Group sequence column.
- **Schema:**
  - `beforeOpen` turns on `foreign_keys` and sets `synchronous = FULL`.
  - `schemaVersion` goes to 1 in Story 1.1, 2 in Story 1.2 and 3 in Story 1.3.
  - After every schema change, run `make-migrations` and commit the snapshot and the generated test.
- **Money:**
  - `Tenths` is an extension type over `int`. `double` never holds money.
  - Keypad parsing and bounds live only in `core/money`.
  - Amounts are displayed only through `formatShekel()`, which adds ₪, groups thousands, shows 0 or 1 decimals and isolates the amount as LTR.
- **Text and i18n:**
  - `core/text` alone owns trimming, `nameKey` case-folding, grapheme length and the collation (Hebrew, then Latin A–Z ignoring case, then digits, then geresh, then Unicode).
  - Never use SQL `lower()` or `NOCASE` on names.
  - The locale is fixed to `he`, and every string comes from the `MessageKey` table.
  - Names enter sentences only through `isolateName()`, which wraps them in FSI/PDI and adds a hyphen after the prefix when the name does not start with a Hebrew letter.
- **Transfer list:**
  - One pure function in `settle_up/domain` computes it from a single read snapshot.
  - It runs an exact search over zero-sum partitions and is never greedy.
- **Routing:**
  - Routes: `/` with `create`, `group/:id` (`add`, `edit/:eid`, `settings`, `summary`), and `archive` (`group/:id` and its `summary`).
  - `activeGroupId` is read before `runApp` and becomes `initialLocation`.
  - After a create or a restore, call `go('/group/:id')`.
  - A redirect blocks `add`, `edit` and `settings` for an Archived group. Read-only mode comes from `isGroupMutable`.
  - Every route uses `NoTransitionPage`.
- **Android:**
  - `applicationId` is `com.mordehay.groupay`, and debug builds add `.dev`.
  - minSdk is 35.
  - Backup is disabled.
  - The release keystore is kept outside git. The trip build is release mode with `isDebuggable = true`.

## UX & Interaction Patterns

- **Theme:**
  - Tokens live in `core/ui/theme`, light theme only.
  - Colors: the Lagoon gradient `#0F766E`→`#0D9488`, the primary orange `#EA580C`, 8 Category colors and 6 Member colors.
  - All text uses Heebo in sp. Radii are 10, 14, 18, 24 and full.
  - Text on the gradient is at least 18sp bold. Category colors are never used for text.
  - Feature UI contains no color, font-size or radius literals.
- **Shared widgets:**
  - `AppScaffold`.
  - A gradient header with the name, Trip total, a count line and a Category share stripe. The "⚙ ✎" chip appears only on an unarchived Group page, never on the Summary.
  - A 56dp compact top bar.
  - Pill buttons: one orange primary at most per screen, on the start side at about ⅔ width, and a white secondary with a teal border.
  - `showAppSheet<T>()` for every confirmation, never a centered dialog. Dismissing a sheet changes nothing.
  - Avatars are colored by `memberSeq` (wrapping after 6) and show the first word of the name, or the full name when first words collide. Names wrap and are never truncated.
  - A snackbar is used only for "ההוצאה נמחקה".
- **Motion:** only two animations exist: a new Expense row slides in, and sheets slide. Both respect "Remove animations". There are no haptics.
- **Navigation:**
  - The stack is shallow. Back from a Group page goes to the Group list (or to Archive for an Archived group), even after launching into the Active group.
  - Create group is replaced by the new Group page.
  - Confirming an archive lands on the Group list.
  - A restore opens the restored Group page, and back from it goes to the Group list.
- **Group list:**
  - The Active group comes first, with "⭐ פעילה" and an orange start edge. The rest follow, newest created first.
  - The "🗂 ארכיון (n)" link is hidden when n = 0.
  - Archive cards are gray and each has a "↩ שחזור" button.
- **Create group:** a two-stage screen.
  - Stage 1 names and saves the Group, and then the Active-group sheet appears.
  - Either answer opens stage 2, where Members are saved as they are added. "סיום" opens the Group page.
- **Group page:**
  - Expense cards overlap the header.
  - The bottom bar holds "+ הוספת הוצאה" and "סיכום".
  - Tap a row to edit it, or long-press it to delete. There are no swipe gestures.
  - Expense time shows `HH:mm` for today and `dd.mm` for earlier days.
  - When archived, the page shows a badge and a note strip, puts "↩ שחזור מהארכיון" in the primary slot, and rows are view-only.
- **Add/Edit expense:**
  - Layout from top to bottom: top bar, Amount (46sp) with a reserved one-line message slot, payer picker (6 per row, never scrolls), 4×2 Category grid, custom 3×4 keypad, then Save. The keypad and Save are pinned, and nothing above them scrolls.
  - When the grid does not fit, it becomes a two-page swipe row with a peek of the next tile and dots.
  - On the keypad, `.` on an empty Amount gives "0.", and a second `.` or a second decimal digit is ignored.
  - *Other* swaps the keypad for a Description field. Leaving *Other* hides the field but keeps its text.
  - Errors replace each other in the message slot and clear on the next relevant change.
  - The exit sheet appears only when there is unsaved input.
  - The Edit meta line reads "נרשם {time}", with " · נערך {time}" added only after a changed save.
- **Group settings:**
  - Rename sheet, Member rows (✎ and ✕) and the Active toggle. When another Group is active, turning the toggle on opens the sheet, and the toggle stays off until the user confirms.
  - Archive.
  - Removing a Payer is refused inline. With Expenses in the Group, removal shows the Remove-member sheet. Without Expenses, the Member is removed at once.
- **Summary:**
  - There is no button bar.
  - The page shows the header with the share line "{n} משתתפים · ₪{share} לאחד", then "מי מעביר למי", then flat Transfer cards with an orange start edge and a decorative avatar pair, or the fixed settled message instead.
  - Fixed messages never get added emoji. Free text addresses the user in second-person masculine.

## Cross-Story Dependencies

- **Story 1.1** replaces the scaffold (`main.dart`, `widget_test.dart` and the `com.example` Gradle config). It delivers the whole shared kernel: theme, widgets, money, text, i18n, result, policy, db and shell. Until Story 1.3, `shell/` binds a `PayerUsagePort` stand-in that reports no Payer usage.
- **Story 1.2** adds `app_settings`, the archive column and `isGroupMutable`. The Story 1.1 write paths must check `isGroupMutable` inside their transactions.
- **Story 1.3** adds the `expenses` table and the real port implementations. These activate the Payer-removal refusal and the Remove-member sheet.
- **Story 1.4** adds `settle_up` with no tables and turns on the Summary button. It also verifies the Summary effects of the earlier rename, remove and archive work.
