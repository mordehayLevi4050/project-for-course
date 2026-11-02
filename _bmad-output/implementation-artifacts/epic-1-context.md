# Epic 1 Context: Shared Expense Splitting

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

The Organizer sets up a Group for a trip, records every shared Expense at the checkout one-handed and offline in at most 4 taps, and at the end of the trip gets one screenshot showing who transfers how much to whom. This single epic is the whole of GrouPay v1: a Hebrew-first, RTL, offline, single-phone Android app. It starts from the throwaway Flutter scaffold and ends with a correct, minimal settle-up Transfer list.

## Stories

- Story 1.1: Create a Group and manage its Members (plus scaffold replacement and the shared kernel)
- Story 1.2: Open straight into the trip, and archive old Groups
- Story 1.3: Record, fix and delete Expenses at the checkout
- Story 1.4: Settle up with one screenshot

## Requirements & Constraints

- **Names:** Group name ≤20 grapheme clusters, Member name ≤10. The field blocks extra input, a paste is cut to the limit, and outer spaces are trimmed on save. Uniqueness ignores case and outer spaces. Group names are unique across all Groups, including Archived ones. Member names are unique within their Group. A rename is checked against everyone except the item being renamed, so a case-only rename is allowed. On rejection nothing changes.
- **Members:** at most 10 per Group. A Member who is the Payer of any Expense cannot be removed. Every Expense is split equally among all current Members, including Members added after the Expense. Renaming changes no Balance, but it may change the Transfer pairs.
- **Active group:** at most one at a time. Launch opens the Active group's page directly, or the group list when none is set. After a Group is created, the app offers to make it active, and warns if another Group is already active. An Archived group cannot be active, and archiving the Active group unsets it.
- **Archive:** Groups are never deleted. An Archived group is read-only (Expenses and Summary can be viewed) until it is restored.
- **Expenses:** Add expense is disabled when the Group has fewer than 2 Members. Amount must be > 0 and ≤ ₪1,000,000 with at most one decimal. A Category is required. *Other* requires a Description. Invalid input keeps the data on screen. The default Payer is the Payer of the most recently saved Expense (highest save order), or the earliest-added Member when there are no Expenses. The list is ordered newest first by save order, never by clock. The recorded time is the first-save time, and editing never changes it or the save order. Every delete requires confirmation.
- **Tap budget:** recording an Expense takes ≤4 taps from launch with the default Payer and ≤5 with a changed Payer. A swipe counts as a tap; typing the Amount does not.
- **Transfer calculation:** exact, in ₪0.10 units. Share = total ÷ Members, rounded down. The Leftover is taken off receivers only, starting with the smallest total paid. On equal totals, the receiver whose first Expense was saved later goes first. The result uses the minimum number of Transfers, always from a negative Balance to a positive one. Ties between minimal lists go to the lexicographically first (debtor, receiver) sequence under the Hebrew-first collation. No minimum Transfer amount (₪0.1 is shown).
- **Summary:** entry is disabled below 2 Members. Each line reads "תשלום נדרש מ{debtor} ל{receiver} ₪N", with no arrows. With ≤6 Members it fits one screen without scrolling on a Galaxy S25. With 7–10 Members only the Transfer list scrolls. It must be understandable from a screenshot alone.
- **Non-functional:**
  - Full Hebrew RTL UI. Every fixed message must match the spec's Hebrew table exactly. "Member" is always "משתתף".
  - Amounts show in ₪ only: no decimals when whole, otherwise exactly one.
  - Fully offline, with zero network calls and data on the device only.
  - Every save is all-or-nothing and survives a kill or reboot.
  - Touch targets ≥48dp. Primary actions sit in the lower half of the screen. Contrast meets WCAG AA.
  - Performance: cold launch ≤2 s, save → Group page <300 ms, a 10-Member Summary ≤1 s.
  - Android 15 (API 35) and above only.
- **Tests:** a unit test for every core policy, text and money function. Every required Transfer-calculation case is covered, including a 10-Member case that runs in ≤1 s. Repositories are tested on `NativeDatabase.memory()`. Generated migration tests are included. Summary golden tests use bundled Heebo at text scale 1.0 and 1.5, with Hebrew, Latin and mixed names.

## Technical Decisions

- **Stack (pinned):**
  - Flutter 3.47.7 and Dart 3.13.5
  - drift 2.35.3, drift_flutter 0.3.1 and drift_dev 2.35.2
  - build_runner 2.16.2 (not 2.17.x)
  - flutter_riverpod 3.4.3, riverpod_generator 4.0.9 and riverpod_annotation 4.0.7
  - go_router 18.1.2 and uuid 4.6.0
  - flutter_localizations, characters, and the bundled Heebo font
  - flutter_lints with zero warnings. Generated `*.g.dart` files are committed.
- **Structure:**
  - `lib/shell` is the composition root. It holds the router and the `ProviderScope` overrides, and clamps text scale to 1.5.
  - `lib/core/{db,ports,policy,result,money,text,i18n,ui/theme,ui/widgets}`
  - `lib/features/{groups,expenses,settle_up}/{ui,app,domain,data}`. `settle_up` has no `data`.
  - `test/` mirrors `lib/`.
- **Dependencies:** imports go only downward: `settle_up → expenses → groups`. `groups` gets facts owned by `expenses` through `core/ports`: `PayerUsagePort` and `GroupTotalsPort`. Both are implemented in `expenses/data` and depend only on `AppDatabase`. Features navigate to each other by route path only.
- **Layers:**
  - `domain/` is pure Dart.
  - Only `data/` and `core/db/` import drift. All tables live in `core/db/tables/`. Generated `*Row` classes stay in `data/` and are mapped to domain entities.
  - Repository providers are declared in `app/` and throw until `shell` overrides them. The DB, repository and port providers are `keepAlive`.
- **Ownership:** `groups` writes the `groups`, `members` and `app_settings` tables. `expenses` writes `expenses`. `settle_up` only reads.
- **Writes:** each user action is one `db.transaction`: gather facts, call the pure `core/policy` function (it returns a `Verdict`), then write. Writes return `Result<T>` or `Failure(MessageKey)`. Guards are never only in the UI.
  - The policy set: `isGroupMutable`, `mayArchive`, `mayRestore`, `maySetActive`, `mayAddMember`, `mayRemoveMember`, `mayModifyExpense`, `mayRecordExpense`, `maySummarize`, `defaultPayer`, `nextSaveSeq`, `nextMemberSeq`.
- **Save once:** the UUID v7 is generated when the form opens. An insert with an existing id does nothing. Notifiers ignore calls while a save is in flight. Save is disabled during the save, and the screen closes only after success.
- **Data model:**
  - String UUID v7 ids.
  - `createdAt` and `modifiedAt` are UTC epoch-ms ints, set only by repositories from one clock provider.
  - `members.memberSeq` and `expenses.saveSeq` are MAX+1 per Group, assigned once and unique per Group.
    - `saveSeq` drives list order, the default Payer and the Leftover tie-break.
    - `memberSeq` drives the earliest Member, payer-picker order and avatar color.
  - Members and Expenses are hard-deleted.
  - `groups.nameKey` is unique, including archived Groups. `(members.groupId, nameKey)` is unique.
  - `expenses(groupId, payerId)` references `members(groupId, id)` with `ON DELETE RESTRICT`. This needs `UNIQUE(groupId, id)` on `members`.
  - Category is a Dart enum stored as a stable string key that is never renamed.
  - No participants are stored.
  - Active group = `app_settings.activeGroupId`, a single-row table with a nullable FK.
- **Schema:** `beforeOpen` sets `PRAGMA foreign_keys = ON` and `synchronous = FULL`.
  - `schemaVersion` is 1 in Story 1.1, 2 in Story 1.2 (`app_settings` and the archive column) and 3 in Story 1.3 (`expenses`).
  - Every change runs `make-migrations` (the DB is listed in `build.yaml`) and commits the snapshot and the generated test.
- **Money:** `Tenths` is an extension type over `int` in `core/money`. `double` never holds money. Keypad parsing and bounds live only in `core/money`. Display goes only through `formatShekel()`, which shows ₪, groups thousands, shows 0 or 1 decimals and isolates the amount LTR.
- **Text:** `core/text` alone owns trimming, `nameKey` case-folding, grapheme length and the collation. The collation order is: Hebrew alphabet, then Latin A–Z case-insensitive, then digits, then geresh, then everything else by Unicode. Final letters fold, a prefix sorts first, and Unicode breaks ties. Never use SQL `lower()`/`NOCASE`.
- **i18n:** the locale is fixed to `he`. All strings come from the `MessageKey` table in `core/i18n`. Names enter sentences only through `isolateName()`, which wraps them in FSI/PDI and adds a hyphen after the prefix when the name does not start with a Hebrew letter.
- **Transfer list:** one pure function in `settle_up/domain` over a single read snapshot. It does an exact search over zero-sum partitions and is never greedy. It runs only when `maySummarize` allows.
- **Routing:**
  - Routes: `/` → `create`, `group/:id` (`add`, `edit/:eid`, `settings`, `summary`), and `archive` (`group/:id`, `summary`).
  - `activeGroupId` is read before `runApp` and becomes `initialLocation`. After a create or restore, call `go('/group/:id')`.
  - A redirect blocks `add`, `edit` and `settings` for Archived groups. Read-only mode comes from `isGroupMutable`.
  - Every route uses `NoTransitionPage`.
- **Android:**
  - `applicationId` is `com.mordehay.groupay` and never changes. Debug builds add the `.dev` suffix.
  - minSdk 35.
  - `allowBackup="false"`, and `dataExtractionRules` exclude every domain.
  - The release keystore is kept outside git. The trip build is release mode with `isDebuggable = true`.
  - Android-only plugins sit behind `core/` interfaces.

## UX & Interaction Patterns

- **Theme and type:** a light-only token theme in `core/ui/theme`.
  - Lagoon gradient `#0F766E`→`#0D9488`, primary orange `#EA580C`, 8 category colors and 6 member colors.
  - All text in Heebo, in sp, and must scale to 150%.
  - Radii: 10, 14, 18, 24 and full. Spacing: 4 to 24.
  - Feature UI has no color, font-size or radius literals.
  - Text on the gradient is ≥18sp bold. Category colors are never used as text color.
- **Shared widgets:**
  - `AppScaffold` handles edge-to-edge insets and the keyboard.
  - The gradient header block shows the name, the Trip total, a count line and a category share stripe.
  - A 56dp compact top bar for the add, edit and create screens.
  - Pill buttons: one orange primary per screen, about 2/3 width on the start side; the secondary is white with a teal border.
  - `showAppSheet<T>()` bottom sheets, where `null` means dismissed. Never centered dialogs.
  - The exit sheet for unsaved input.
  - Member avatars: 44dp in a 48dp slot, colored by `memberSeq` (wrapping after 6), with the first word of the name under the circle.
  - A snackbar used only for "ההוצאה נמחקה".
- **Motion:** only two animations exist: the new Expense row slides in, and sheets slide. Both go through one helper that respects Remove animations. No haptics.
- **Add/Edit expense layout (top to bottom):** top bar, Amount (46sp), payer picker (6 per row, never scrolls), 4×2 Category grid, custom 3×4 keypad, then Save.
  - The Category grid falls back to a two-page swipe row only when the grid does not fit.
  - Choosing *Other* swaps the keypad for a Description field.
  - Keypad and Save are pinned, and nothing above them scrolls.
- **Group page:** Expense cards overlap the header. The bottom bar holds "+ הוספת הוצאה" and "סיכום". Tap an Expense to edit; long-press to delete. No swipe gestures.
- **Archived group page:** a read-only page with a badge, a note strip and "↩ שחזור מהארכיון".
- **Group settings** (from the "⚙ ✎" chip): rename, the Member list, the Active toggle and archive.
- **Summary:** no button bar. Transfer cards are flat, with an orange start edge and a decorative avatar pair. Fixed messages appear exactly as written, with no added emoji. Free text uses second-person masculine.

## Cross-Story Dependencies

- **Story 1.1** replaces the scaffold (`main.dart`, `widget_test.dart`, the `com.example` Gradle config) and delivers the whole shared kernel that later stories reuse: theme, widgets, money, text, i18n, result, policy, db and shell.
  - Until 1.3 lands, `shell` binds a `PayerUsagePort` stand-in that reports no Payer usage.
- **Story 1.2** adds `isGroupMutable`. The Story 1.1 write paths must then check it inside their transactions. Stories 1.3 and 1.4 enforce read-only mode through the same policy.
- **Story 1.3** adds the `expenses` table. It replaces the port stand-in with real `PayerUsagePort` and `GroupTotalsPort` implementations in `expenses/data`. It turns on the FR4 Payer check and the Remove-member sheet.
- **Story 1.4** adds `settle_up` with no tables (it only reads), along with the Summary button and screen. It also covers the Summary checks for the earlier rename, remove and archive work.
