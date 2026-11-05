---
status: final
stepsCompleted: [step-01-validate-prerequisites, step-02-design-epics, step-03-create-stories, step-04-final-validation]
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-groupay-2026-10-26/prd.md
  - _bmad-output/planning-artifacts/prds/prd-groupay-2026-10-26/addendum.md
  - _bmad-output/planning-artifacts/architecture/architecture-groupay-2026-10-29/ARCHITECTURE-SPINE.md
  - _bmad-output/planning-artifacts/ux-designs/ux-groupay-2026-10-26/DESIGN.md
  - _bmad-output/planning-artifacts/ux-designs/ux-groupay-2026-10-26/EXPERIENCE.md
  - _bmad-output/specs/spec-groupay/SPEC.md
  - _bmad-output/specs/spec-groupay/functional-rules.md
  - _bmad-output/specs/spec-groupay/transfer-calculation.md
  - _bmad-output/specs/spec-groupay/ui-messages.md
  - _bmad-output/specs/spec-groupay/user-journeys.md
  - _bmad-output/specs/spec-groupay/glossary.md
  - _bmad-output/specs/spec-groupay/future-phases.md
  - ears-requirements.md
excludedDocuments:
  - _bmad-output/specs/spec-groupay/stories.yaml (excluded by the founder, 2026-11-01)
constraints:
  - 'One epic, at most 4 stories (founder, 2026-11-01; PRD §8.1 had 3).'
---

# GrouPay - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for GrouPay, decomposing the requirements from the PRD, UX Design if it exists, and Architecture requirements into implementable stories.

Precedence on conflict: PRD > `ears-requirements.md` (PRD §8.2). DESIGN.md / EXPERIENCE.md win over the mockups. Fixed Hebrew texts come only from the PRD NFR-6 table (`ui-messages.md`). EARS test IDs (T1.x, T2.x, T3.x, TX.x) are the acceptance test references.

## Requirements Inventory

### Functional Requirements

**Groups and Members**

FR1: The Organizer can create a Group by name; it appears in the group list immediately. Name ≤20 user-perceived characters (grapheme clusters); the field blocks extra input, a paste is cut to the limit, outer spaces are trimmed on save. Empty/whitespace-only → "Name required". A name matching any other Group, including Archived ones (case- and outer-space-insensitive) → "Group already exists". Nothing is created on rejection. With no Groups the list shows "The list of groups will appear here". (T1.1, T1.3, T1.4, T1.21, T1.22, T1.31, T1.36)

FR2: The Organizer can add Members to a Group by typing a name; the Member appears immediately. Name ≤10 grapheme clusters with the same field behavior as FR1. Empty → "Name required"; duplicate in the Group (case/outer-space-insensitive) → "Member already exists"; an 11th Member → "A group can have at most 10 members". A Member added after Expenses exist shares all Expenses, including earlier ones. (T1.2, T1.5–T1.7, T1.20, T1.33–T1.35)

FR3: The Organizer can rename a Member. The new name appears everywhere (member list, past Expenses, Summary). No Balance or any Member's total paid/received changes; the Transfer pairs may change. FR2 rules apply; the uniqueness check excludes the Member being renamed (case-only rename allowed); on rejection the old name stays. (T1.12, T1.37–T1.39)

FR4: The Organizer can remove a Member only if they are not the Payer of any Expense; otherwise refused with "A member with expenses in their name cannot be removed". After a removal every Expense splits equally among the remaining Members. (T1.13, T1.14)

FR5: The Organizer can rename a Group. FR1 rules apply against all other Groups; saving under its own current name is not a duplicate; empty → "Name required" and the old name stays. The new name shows on the home page, Group page and Summary. (T1.17, T1.18, T1.23–T1.25)

FR6: The Organizer can archive a Group (no deletion in v1). It disappears from the group list, keeps all Members and Expenses, appears in a separate Archive view and can be restored. Archiving the Active group unsets it. An Archived group is read-only: Expenses and Summary viewable; no change to Members, Expenses or name; cannot be set active. Restoring brings back every action. (T1.15, T1.16, T1.26)

**Active Group and Launch**

FR7: As soon as a new Group is saved, before any Members are added, the app asks "Make this the active group?". Confirming while another Group is active first shows "'{name}' will no longer be the active group". Declining leaves the current Active group unchanged. (T1.8, T1.9, T1.19, T1.40)

FR8: The Organizer can set any non-archived Group as the Active group, or unset it, at any time. At most one Group is active at any moment. An Archived group cannot be set active. (T1.10, T1.32)

FR9: With an Active group set, launch shows that Group's page with no intermediate screen; without one, launch shows the group list. From the Active group's page the group list is always reachable. (T1.8, T1.10, T1.11)

**Expenses**

FR10: The Organizer can add an Expense from a single prominent *Add expense* control on the Group page.
- With fewer than 2 Members, *Add expense* is disabled and "Add at least two members to record expenses" shows next to it.
- The screen opens with the Amount focused and a numeric keypad (with decimal separator) open; Amount, Payer, Category and Save never require dismissing the keypad.
- Default Payer = current Payer of the Expense with the highest save-order number in the Group; with no Expenses, the earliest-added Member still in the Group.
- All Members (≤10) are visible at once as directly tappable Payer options; the selected one is clearly marked; one tap selects another.
- Categories are directly tappable, normally all at once in a grid; if they don't fit at the required target size they sit in a sideways row of at most two pages (one swipe = one tap, keypad stays open).
- Tap budget: ≤4 taps from launch with the default Payer, ≤5 with a changed Payer (each swipe counts, typing the Amount does not).
- Recorded time = first-save time; editing never changes it; no back-dating.
- Leaving with unsaved input asks "Exit without saving?"; confirm discards, cancel keeps the input (outside the tap budget).
- Save on a valid Expense saves exactly once and returns immediately to the Group page with the new Expense at the top; a second tap creates nothing. Same for saving an edit.
(T2.1, T2.8–T2.10, T2.17–T2.22, T2.26–T2.29)

FR11: The app refuses to save an invalid Expense and keeps the entered data on screen. Empty, zero, negative or > ₪1,000,000 Amount → "Please enter a valid amount" (₪1,000,000 is valid). The keypad rejects a second digit after the decimal separator. No Category → "Please choose a category". *Other* with empty/whitespace-only Description → "Description required, or choose a category". (T2.3a–e, T2.4–T2.7, T2.15, T2.23, T2.24)

FR12: The Group page lists all Expenses newest first by save order (never by clock), each showing Payer, Amount, Category (or Description for *Other*) and recorded time. It shows the Trip total. With no Expenses it shows "No expenses yet". (T2.2, T2.14, T2.25)

FR13: Tapping an Expense opens an edit screen with all fields filled; any field can be changed and saved. FR11 validation applies. The list, Trip total and Summary update immediately. Editing never changes the save-order number (including a Payer change) or the recorded time. (T2.11, T2.16, T2.24, T2.29)

FR14: The Organizer can delete an Expense from the edit screen or by long-pressing it in the list. Every deletion requires confirmation ("Delete this expense?"); cancelling leaves it unchanged. (T2.12, T2.13)

**Summary and Settling Up**

FR15: The app computes the Transfer list exactly in ₪0.10 units from all Expenses and Members of the Group:
- Share = Trip total ÷ number of Members, rounded down to ₪0.10. Starting Balance = paid − Share.
- The Leftover is taken off receivers only, starting with the receiver who paid the smallest total; a Balance stops at zero and the rest moves to the next-smallest. Equal totals: the receiver whose first Expense (lowest save-order number among Expenses they currently pay) was saved later absorbs first. Never uses the clock.
- Minimum number of Transfers; every Transfer goes from a negative to a positive Balance (no Member both sends and receives); only such lists are candidates.
- Tie-break between minimal lists: order each candidate's Transfers by debtor then receiver name; choose the lexicographically first (debtor, receiver) sequence, under the FR15 collation (Hebrew alphabet, then Latin A–Z case-insensitive, then digits, then geresh, then other by Unicode; final letters fold; prefix first; Unicode breaks ties).
- Renaming may change pairs, never Balances. Empty list exactly when every Balance is zero. No minimum Transfer (₪0.1 is shown).
- Every amount in the app shows no decimals when whole, otherwise exactly one.
(T3.1, T3.3–T3.6, T3.15–T3.20, T3.31–T3.35, T3.37–T3.40, T3.45, T1.13, T1.20, T2.16)

FR16: The Organizer can open the Summary of any Group with ≥2 Members (entry disabled below 2). It shows the Group name, Trip total and Transfer list in FR15 order. Each Transfer is one line "תשלום נדרש מ{debtor} ל{receiver} ₪N" with no arrow or direction symbol; names are bidi-isolated and a name not starting with a Hebrew letter takes a hyphen after the prefix ("מ-Dan לדנה"). ≤6 Members: everything fits one screen without scrolling on the Galaxy S25 at default font; 7–10: only the Transfer list scrolls. With no Transfers it shows "Everyone is settled up". Understandable from a screenshot alone. (T3.2, T3.7, T3.8, T3.43, T3.44, T3.46)

### NonFunctional Requirements

NFR1: Tap budget — recording an Expense takes ≤4 taps from launch (Active group set, default Payer correct), ≤5 with a changed Payer; each swipe counts as a tap, typing the Amount does not. Any new UI on this path must stay in budget.

NFR2: Right-thumb zone — primary actions (*Add expense*, *Save*) sit in the lower half of the screen, reachable by a right thumb on a 6–6.7" phone.

NFR3: Touch targets — every tappable control ≥48×48 dp; primary actions and Category options larger.

NFR4: Contrast — text and controls meet WCAG 2.1 AA. No low-vision mode.

NFR5: Responsiveness — cold launch to the Active group page ≤2 s on the Galaxy S25; save Expense → Group page <300 ms; Summary of a 10-Member Group ≤1 s. (TX.3, TX.4, T3.46)

NFR6: Hebrew-first — entire UI in Hebrew, full RTL from day one; Latin names and amounts render correctly inside RTL text; the 17 fixed messages show exactly the PRD Hebrew text; "Member" is always "משתתף"; direction never conveyed by an arrow or symbol; a rendered Summary with Hebrew-only, Latin-only and mixed names is tested. (TX.5, T3.43, T3.44)

NFR7: Currency — ₪ only (ILS), no decimals when whole, otherwise one; no conversion in-app.

NFR8: Offline — every feature works with no network; the app makes no network calls. (TX.1)

NFR9: Durability — a saved change survives app close, system kill and phone restart; every save is all-or-nothing. (TX.2)

NFR10: On-device — all data stored only on the device; no accounts, no server.

NFR11: Every Group, Member and Expense has a stable, globally unique id independent of device or list position.

NFR12: Every record carries creation and last-modification times.

NFR13: Features reach data through a single data-access boundary.

NFR14: Rules that will differ in the multi-user phase (edit/delete permission, when a Group may change, default Payer, source of save order) are each defined in one replaceable place.

NFR15: Money is held as integer tenths of a shekel; the only rounding is the Share (down to ₪0.10).

NFR16: The Transfer calculation is covered by automated tests: all EARS cases, tenths, non-dividing Shares, Leftover with one/several receivers and larger than one Balance, equal-total receivers, ₪0.1 Transfers, tie-breaks with Hebrew/Latin/mixed names, groups of 2–10 Members, and the 10-Member timing.

NFR17: Android 15 (API 35) and above only.

### Additional Requirements

From `ARCHITECTURE-SPINE.md` (AD-1 … AD-23). There is **no new starter template**: the app builds on the existing Flutter scaffold on the `bmad-rebuild` branch, and the **first story must replace** `lib/main.dart` (HomeScreen with a Hebrew literal), `test/widget_test.dart` and the `com.example.groupay` Gradle config with debug-key release signing.

**Project setup and stack**
- AR1: Flutter/Dart app on the existing scaffold, Android only in v1; `core/`, `domain/`, `app/`, `data/` use no Android-only plugin unless behind a `core/` interface (AD-1).
- AR2: Pin the stack: Flutter 3.47.7, Dart 3.13.5, drift 2.35.3, drift_flutter 0.3.1, drift_dev 2.35.2, build_runner 2.16.2 (not 2.17.x), flutter_riverpod 3.4.3, riverpod_generator 4.0.9 / riverpod_annotation 4.0.7, go_router 18.1.2, uuid 4.6.0, flutter_localizations, characters, bundled Heebo font.
- AR3: Folder structure per the Structural Seed: `lib/shell/`, `lib/core/{db,ports,policy,result,money,text,i18n,ui/theme,ui/widgets}`, `lib/features/{groups,expenses,settle_up}/{ui,app,domain,data}` (settle_up has no `data/`), `assets/fonts/`, `test/` mirroring `lib/`.
- AR4: Android config: `applicationId com.mordehay.groupay` (never changes), `minSdk 35`, debug `applicationIdSuffix ".dev"`, release keystore outside git and backed up, `android:allowBackup="false"` and `dataExtractionRules` excluding every domain; the trip build is release-mode with `isDebuggable = true` signed with the release keystore (AD-19).
- AR5: Lints: `flutter_lints`, no analyzer warnings at merge; `*.g.dart` committed. CI is deferred.

**Layering and state**
- AR6: Three feature slices with downward-only imports `settle_up → expenses → groups`; upward facts via ports in `core/ports/` (`PayerUsagePort` and `GroupTotalsPort`, both implemented in `expenses/data` and consumed by `groups`); cross-feature navigation via route paths only (AD-2).
- AR7: Table ownership = write rights: `groups` owns `groups`, `members`, `app_settings`; `expenses` owns `expenses`; `settle_up` only reads (AD-3).
- AR8: Only `data/` and `core/db/` import drift. Repository interfaces in `domain/`, providers declared in `app/` that throw until overridden in `shell/` (AD-4, AD-21).
- AR9: Riverpod only, all providers via `@riverpod`; reads wrap repository `.watch()` streams; writes are notifier methods; DB, repository and port providers `keepAlive: true`; `setState` only for ephemeral input (AD-5).
- AR10: `shell/` is the composition root: `main()`, `go_router` config, `ProviderScope` overrides; text scale clamped to 1.5 (AD-21).

**Data and rules**
- AR11: Every user write is one `db.transaction`: gather facts → call `core/policy` → write. One `AppDatabase` instance (AD-6).
- AR12: `core/policy` pure functions returning `Verdict` (allowed or `MessageKey`): `isGroupMutable`, `mayArchive`, `mayRestore`, `maySetActive`, `mayAddMember`, `mayRemoveMember`, `mayModifyExpense`, `mayRecordExpense`, `maySummarize`, `defaultPayer`, `nextSaveSeq`, `nextMemberSeq` (AD-7).
- AR13: Ids are device-generated UUID v7 strings; `createdAt`/`modifiedAt` UTC epoch-ms `int`, set only by repositories from one clock provider (AD-8).
- AR14: `expenses.saveSeq` and `members.memberSeq` = `MAX + 1` per Group, assigned once in the insert transaction, never changed; `UNIQUE(groupId, saveSeq)` and `UNIQUE(groupId, memberSeq)`. List order, default Payer and Leftover tie-break use `saveSeq`; earliest Member, payer-picker order and avatar color use `memberSeq` (AD-9).
- AR15: Hard delete for Members and Expenses (SQL `DELETE`, no `deletedAt`); Groups only archived (AD-10).
- AR16: An Expense stores no participants; the Transfer list is one pure function in `settle_up/domain` over one read-transaction snapshot, an exact search over zero-sum partitions (never greedy), run only when `maySummarize` allows (AD-11).
- AR17: Money is `Tenths` (extension type over `int`) in `core/money`, integer columns, never `double`; keypad parsing and bounds only in `core/money`; display only via `formatShekel()` (₪, thousands grouping, 0 or 1 decimal, LTR-isolated) (AD-12).
- AR18: `core/text` alone defines name normalization (trim), `nameKey` (case-fold), grapheme length and FR15 collation. `groups.nameKey UNIQUE` (incl. archived), `UNIQUE(members.groupId, nameKey)`; never SQL `lower()`/`NOCASE` (AD-13).
- AR19: Locale fixed to `he`, RTL; every visible string from the `MessageKey` table in `core/i18n` (no Hebrew literals in widgets); names enter sentences only via `isolateName()` (FSI/PDI + hyphen rule) (AD-14).
- AR20: Repository writes return `Result<T>`; violations are `Failure(MessageKey)`; exceptions only for bugs/I-O (AD-15).
- AR21: Navigation only via `go_router` in `shell/`. Routes: `/` with `create`, `group/:id` (`add`, `edit/:eid`, `settings`, `summary`) and `archive` (`group/:id`, its `summary`). `activeGroupId` read before `runApp` and passed as `initialLocation`. After create/restore `go('/group/:id')`. Read-only from `isGroupMutable`; a redirect blocks `add`/`edit`/`settings` for archived Groups. `PopScope` + shared exit sheet guard unsaved input. All routes `NoTransitionPage` (AD-16).
- AR22: Active group = `app_settings.activeGroupId` (nullable FK, single row, owned by `groups`); archiving clears it in the same transaction; no shared_preferences (AD-17).
- AR23: Schema: `beforeOpen` sets `PRAGMA foreign_keys = ON` and `synchronous = FULL`; `expenses(groupId, payerId)` → `members(groupId, id)` `ON DELETE RESTRICT`; Category as a stable Dart-enum string key; `schemaVersion` 1; every schema change bumps the version, adds a `drift_dev make-migrations` step (DB listed in `build.yaml`) and commits the snapshot and generated test (AD-18).
- AR24: All tables, indexes and FKs defined in `core/db/tables/` and registered in `AppDatabase`; generated rows named `*Row`, used only in `data/`, mapped to domain entities (AD-20).
- AR25: Save-once: the entity id is generated when the form opens; insert is a no-op if the id exists; write notifiers ignore calls while a save is in flight; Save disabled during save; screen closes only after success. Applies to Groups, Members, Expenses and edits (AD-23).

**Testing conventions**
- AR26: Unit tests for every `core/policy`, `core/text` and `core/money` function; the `settle_up/domain` calculation has a test for every NFR16 case and for 10 Members in ≤1 s; repositories tested on `NativeDatabase.memory()`; generated migration tests; Summary golden tests with bundled Heebo at text scale 1.0 and 1.5 with Hebrew, Latin and mixed names.

### UX Design Requirements

From DESIGN.md (visual) and EXPERIENCE.md (behavior). Both are in `draft` status; the founder chose to include them.

**Design tokens and theme**
- UX-DR1: Implement the DESIGN.md token set in `core/ui/theme`: all colors (Lagoon gradient `#0F766E`→`#0D9488` at 135°, primary orange `#EA580C`, surfaces, ink levels, input borders, transfer, toggle, archived, badge, danger, scrim), 8 category colors and 6 member colors; typography roles (trip-total 40/800, amount-entry 46/800, screen-title 22/700, header-secondary 18/700, transfer-amount 26/800, button-primary 19/700, button-secondary 16/600, row-title 16/600, row-amount 17/700, keypad-digit 24/600, avatar-initial 22/800, label 12/600, meta 12/400, message 14/400), all Heebo; radii sm 10, md 14, lg 18, xl 24, full; spacing 4/8/12/16/20/24, list-fade 56, margin 16. Light theme only. Feature `ui/` has no color, font-size or radius literals.
- UX-DR2: Contrast rules: every text on the gradient is ≥18sp bold (or ≥24sp regular); labels on orange ≥19sp bold; badges/chips on the gradient use the dark 25% ink overlay, never a white overlay; meta text no lighter than `ink-secondary`. Category colors are never text color.
- UX-DR3: Font scaling up to 150%: all sizes in sp, fixed heights are minimums that grow, labels wrap instead of truncating; screens scroll when content does not fit (Add expense switches to the two-page Category row instead).

**Shared components (`core/ui/widgets`)**
- UX-DR4: `AppScaffold` owning edge-to-edge insets (Android 15) and keyboard handling.
- UX-DR5: Header block: Lagoon gradient; nav line (a right-pointing chevron icon + label: "חזרה", "ארכיון" or "הקבוצות שלי"; "🗂 בארכיון" badge when archived); group name with "⚙ ✎" chip (single entry to Group settings, hidden when archived); Trip total; secondary line "{n} משתתפים · {m} הוצאות" / share line; 8dp category share stripe with segments proportional to each Category's share and 2dp gaps, recomputed on every Expense change (Group page and Summary).
- UX-DR6: Compact top bar (56dp gradient) for add/edit expense and create group: ✕ on the start side, group name centered, red "🗑 מחיקה" chip on edit.
- UX-DR7: Pill buttons: primary (orange, 64dp, glow shadow, ≤1 per screen, start/right side ~2/3 width) and secondary (white, teal border, 64dp, ~1/3 width); always text-labeled, never icon-only; disabled = 40% opacity, no shadow, label unchanged.
- UX-DR8: `showAppSheet<T>()` bottom sheet (grab handle, title, body, optional warning strip, button row with primary on the start side, scrim). Dismiss via cancel, scrim or back changes nothing (`null` = dismissed). Used for: Active-group, Exit, Delete, Archive, Remove-member and Rename sheets. Never centered dialogs.
- UX-DR9: Exit sheet: title "לצאת ללא שמירה?", body "מה שהזנת לא יישמר.", "יציאה" (danger) / "המשך עריכה". Unsaved input = on Add: any Amount/Description, a selected Category or a non-default Payer; on Edit: any field differing from the saved Expense. With no unsaved input the screen closes at once.
- UX-DR10: Member avatar: 44dp circle in a 48dp slot/hit area, member color by add order (`memberSeq`, member 7 wraps to color 1), initial in avatar-initial; first word of the name under the circle (full name when first words collide), wraps to 2 lines, never truncated. Helpers `memberColorIndex()` and `avatarLabel()`.
- UX-DR11: Snackbar helper using the root `scaffoldMessengerKey`: ink pill, white text, above the button bar, auto-dismiss, no undo; used only for "ההוצאה נמחקה".
- UX-DR12: Motion: exactly two animations — new Expense row slides into the top of the list after Save, and bottom sheets slide up/down — both through one helper that skips them when Android "Remove animations" is on. Everything else instant; no haptics.

**Screens and patterns**
- UX-DR13: Group list (home): centered header titles, list starts below the header (no overlap); Group cards (name, member count, total); Active group card has a 6dp orange start edge and "⭐ פעילה"; empty state "כאן תופיע רשימת הקבוצות" with "+ קבוצה חדשה" still present; "🗂 ארכיון (n)" link at the bottom, hidden when there are 0 archived Groups.
- UX-DR14: Archive view: same layout as the group list with gray archived cards (`archived-card-surface`/`-ink`, no colored edge); tapping a card opens the Group page read-only; each card has a "↩ שחזור" text button.
- UX-DR15: Create group in two stages on one screen: stage 1 field "שם הקבוצה" + "יצירת קבוצה" (✕ leaves without creating); on save the Active-group sheet slides up immediately (body "האפליקציה תיפתח ישר לתוך הקבוצה הזו.", "כן, להפוך לפעילה" / "לא עכשיו", warning strip when another Group is active); any answer opens stage 2: group name becomes the top-bar title, "משתתפים" section with add-member field, avatar member list (saved as added), "סיום" → new Group page (Create is replaced, back goes to the list). Inline validation messages under the field.
- UX-DR16: Group page: header block, Expense cards overlapping the header by 16dp, 56dp fade above the bottom bar (no tray; list bottom padding = bar + fade), 4–5 large rows visible; bottom bar "+ הוספת הוצאה" (primary) and "סיכום" (secondary, always visible). With <2 Members both disabled and the hint above the bar in message/ink-muted. Empty state "עדיין אין הוצאות" with ₪0 and empty stripe. Back goes to the group list even after launching into the Active group.
- UX-DR17: Expense row: white card ≥72dp, 6dp start-edge stripe and 46dp emoji circle tinted 15% in the Category color, title = Category name or Description for *Other*, meta "payer · date time", amount on the end side. Tap → Edit; long-press → Delete sheet; no swipe gestures. An edited Expense keeps its place.
- UX-DR18: Add/Edit expense layout (top to bottom): compact top bar → Amount (46sp, ₪ tinted `currency-mark`, caret) → payer picker → 4×2 Category grid → custom 3×4 keypad → wide "שמירה". No section labels. Keypad and Save pinned inside system insets; the region above never scrolls. Initial state: Amount empty, default Payer selected, no Category.
- UX-DR19: Payer picker: 6 avatars per row in 48dp slots with 8dp gaps; one row ≤6 Members, second row (start-aligned) for 7–10; fixed `memberSeq` order; selected = 3dp canvas gap ring + 2dp member-color ring; unselected at 55% opacity; never scrolls.
- UX-DR20: Category tile: 64dp, emoji 22sp above the name (✈️ טיסה, 🏨 מלון, 🚗 רכב, ⛽ דלק, 🍝 מסעדה, 🛒 אוכל ושתייה, 🎡 אטרקציות, 📝 אחר in the fixed order); selected = 2dp border + 16% tint in the Category color, bold label; tap selects and replaces, never saves; *Other* reveals the Description field.
- UX-DR21: Two-page Category row, used only when the 4×2 grid does not fit: page 1 = first four, page 2 = last four (on the end/left side), never a third page; tile size kept; first tile of the other page peeks ~¼ tile; two 8dp page dots (indicators only) centered `spacing.2` below; one swipe snaps a page; selection persists across pages; Add opens on page 1, Edit on the page holding the saved Category, after an error the row stays put; keypad stays open.
- UX-DR22: Custom keypad: white panel with xl top corners, keys 1–9, `.`, 0, ⌫ in LTR digit order, 48dp keys, no "00"; blocks a second decimal digit. *Other* state swaps the keypad for a Description field (placeholder "מה קנית?") with the system keyboard and Save just above it.
- UX-DR23: Save behavior: inline error in `danger` with all input kept; on success exactly one save, Save accepts no further taps, screen closes immediately (<300 ms). Edit initial meta line "נרשם {date time} · נערך עכשיו".
- UX-DR24: Delete sheet: title "למחוק את ההוצאה?", body = expense line + "אי אפשר לבטל את הפעולה.", "מחיקה" / "ביטול"; after delete the snackbar "ההוצאה נמחקה".
- UX-DR25: Group settings (from "⚙ ✎"): "שם הקבוצה ›" → Rename sheet; Member rows with ✎ (Rename sheet) and ✕; "קבוצה פעילה" Toggle (52×30dp); "🗂 העברה לארכיון". Not reachable for archived Groups.
- UX-DR26: Active toggle: on with no other active → active at once, no sheet; on with another active → Active-group sheet with the warning, toggle stays off until "כן, להפוך לפעילה"; cancel/scrim/back reverts to off; off → unset at once, no sheet. Every change saved immediately.
- UX-DR27: Member removal from settings: Payer → inline refusal "לא ניתן להסיר משתתף שיש הוצאה על שמו" under the row in danger (replaces any previous message); Group has Expenses → Remove-member sheet "להסיר את {name}?" / "ההוצאות יתחלקו מחדש בין {n} המשתתפים הנותרים." / "הסרה" / "ביטול"; no Expenses → removed immediately.
- UX-DR28: Rename sheet: text field with Name-field rules; invalid name messages inside the sheet; current name kept on rejection.
- UX-DR29: Archive sheet: "להעביר את “{group}” לארכיון?" / "הנתונים נשמרים ואפשר לשחזר בכל רגע." / "העברה לארכיון" / "ביטול".
- UX-DR30: Archived Group page: header nav chevron icon + "ארכיון", badge "🗂 בארכיון", no "⚙ ✎"; rows view-only (tap and long-press do nothing); archive note strip "🗂 הקבוצה בארכיון ולכן לקריאה בלבד. שחזור יחזיר את האפשרות לערוך." above the bar; "↩ שחזור מהארכיון" in the primary slot (no confirmation) with "סיכום" beside it. After restore the same page stays open without badge/note and back leads to the group list.
- UX-DR31: Summary: header block (name, Trip total, share line "{n} משתתפים · ₪{share} לאחד", stripe) → "מי מעביר למי" title → Transfer cards with 8dp gaps, or "החשבון מאוזן, אין צורך בהעברות" → archive note "🗂 הקבוצה בארכיון ולכן לקריאה בלבד." when archived. No bottom button bar. ≤6 Members fixed; 7–10 header and title fixed, cards scroll with a bottom fade when more exist. Above 100% font scale the whole Summary may scroll.
- UX-DR32: Transfer card: `transfer-surface` with 6dp orange start edge, ≥64dp, flat; decorative pair of 32dp initial-only avatars (debtor, receiver, 4dp apart, nothing between them) at the start; the sentence "תשלום נדרש מ{debtor} ל{receiver}" in row-title; amount in transfer-amount ending the line; long names wrap, amount stays at the end; not tappable, no toggle, no arrow anywhere.
- UX-DR33: Voice: fixed messages exactly as in the PRD table with no added emoji or punctuation; free texts in second-person masculine; emoji only in free texts and Category icons.

### FR Coverage Map

FR1: Epic 1 / Story 1.1 - Create a Group
FR2: Epic 1 / Story 1.1 - Add Members by name
FR3: Epic 1 / Story 1.1 - Rename a Member
FR4: Epic 1 / Story 1.1 - Remove a Member (non-Payer only)
FR5: Epic 1 / Story 1.1 - Rename a Group
FR6: Epic 1 / Story 1.2 - Archive and restore a Group
FR7: Epic 1 / Story 1.2 - Offer to set a new Group as active
FR8: Epic 1 / Story 1.2 - Set or unset the Active group
FR9: Epic 1 / Story 1.2 - Launch into the Active group
FR10: Epic 1 / Story 1.3 - Add an Expense fast
FR11: Epic 1 / Story 1.3 - Validate an Expense
FR12: Epic 1 / Story 1.3 - View the Expense list
FR13: Epic 1 / Story 1.3 - Edit an Expense
FR14: Epic 1 / Story 1.3 - Delete an Expense
FR15: Epic 1 / Story 1.4 - Compute the Transfer list
FR16: Epic 1 / Story 1.4 - Show the Summary

NFR1-NFR17 apply to every story. Each AR and UX-DR is delivered by the first story that needs it.

## Epic List

### Epic 1: Shared Expense Splitting
The Organizer sets up a Group for a trip, records every shared Expense at the checkout one-handed and offline in at most 4 taps, and at trip's end gets one screenshot that says who transfers how much to whom.
**FRs covered:** FR1-FR16 (all). NFR1-NFR17 apply to every story.

Story sequence (one epic, at most 4 stories, founder 2026-11-01; splits PRD §8.1 Story 1 in two):
1. Story 1.1 - Groups and Members (FR1-FR5), including scaffold replacement and the shared kernel
2. Story 1.2 - Active group, launch and archive (FR6-FR9)
3. Story 1.3 - Expenses (FR10-FR14)
4. Story 1.4 - Settle up (FR15-FR16)

## Epic 1: Shared Expense Splitting

The Organizer sets up a Group for a trip, records every shared Expense at the checkout one-handed and offline in at most 4 taps, and at trip's end gets one screenshot that says who transfers how much to whom. NFR1-NFR17 apply to every story. EARS test IDs in parentheses are the acceptance test references.

### Story 1.1: Create a Group and manage its Members

As the Organizer,
I want to create a Group for my trip and add, rename and remove its Members by typing their names,
So that the trip's people are recorded on my phone before the first Expense.

**Scope:** FR1-FR5. This story replaces the scaffold and lays down the shared kernel that later stories build on. It creates only the `groups` and `members` tables. FR4's Payer check and the Remove-member sheet go live in Story 1.3, when Expenses exist.

**Acceptance Criteria:**

**Project foundation (AR1-AR5, AR8-AR10, AR13, AR15, AR18-AR20, AR23-AR26, UX-DR1-UX-DR4, UX-DR7, UX-DR8, UX-DR33)**

**Given** the existing scaffold on `bmad-rebuild`
**When** this story is done
**Then** `lib/main.dart` (HomeScreen with a Hebrew literal), `test/widget_test.dart` and the `com.example.groupay` Gradle config with debug-key release signing are replaced
**And** `pubspec.yaml` pins the Stack versions of AR2 (build_runner 2.16.2), and Heebo is bundled under `assets/fonts/` with no runtime font fetching
**And** the folder layout matches the Structural Seed (AR3): `shell/`, `core/{db,ports,policy,result,money,text,i18n,ui}`, and the `groups` and `expenses` feature folders
**And** Android uses `applicationId com.mordehay.groupay`, `minSdk 35`, debug `applicationIdSuffix ".dev"`, release signing from a keystore kept outside git, `allowBackup="false"` and `dataExtractionRules` that exclude every domain (AR4)
**And** `flutter analyze` reports no warnings, and generated `*.g.dart` files are committed (AR5).

**Given** the app starts
**When** `shell/` builds it
**Then** `main()`, the `go_router` config and the `ProviderScope` overrides live only in `shell/`, and repository and port providers throw until `shell/` overrides them with their drift implementations (AR8, AR10)
**And** the locale is fixed to `he` with RTL layout, the text scale is clamped to 1.5, and the light-only `ThemeData` comes from the DESIGN.md tokens in `core/ui/theme` (UX-DR1)
**And** every visible string comes from the `MessageKey` table in `core/i18n`; widgets contain no Hebrew literals, and feature `ui/` contains no color, font-size or radius literals (AR19, UX-DR1)
**And** every route uses `NoTransitionPage` (AR21).

**Given** the database opens
**When** `beforeOpen` runs
**Then** `PRAGMA foreign_keys = ON` and `synchronous = FULL` are set, `schemaVersion` is 1, and the AR23 migration setup (`build.yaml`, `make-migrations`, committed snapshot and generated test) is in place
**And** all tables are defined in `core/db/tables/`, and their `*Row` classes are used only in `data/` (AR23, AR24)
**And** `groups` holds `id` (UUID v7 string), `name`, `nameKey` (`UNIQUE` across all Groups), `createdAt`, `modifiedAt`
**And** `members` holds `id`, `groupId` (FK), `name`, `nameKey`, `memberSeq`, `createdAt`, `modifiedAt`, with `UNIQUE(groupId, nameKey)` and `UNIQUE(groupId, memberSeq)` (AR13, AR14, AR18).

**Given** the shared kernel
**When** its unit tests run
**Then** `core/text` covers trim normalization, the case-folded `nameKey`, grapheme-cluster length (an emoji or a letter with niqqud counts as one) and the FR15 collation (Hebrew order, then Latin A-Z ignoring case, then digits, then geresh, then Unicode value; final letters fold; a prefix sorts first; Unicode value breaks remaining ties)
**And** `core/money` covers `Tenths` and `formatShekel()` (₪, thousands grouping, no decimal when whole and otherwise exactly one, isolated as an LTR run)
**And** `core/i18n` covers `isolateName()` (FSI/PDI wrapping, plus a hyphen after a Hebrew prefix when the name does not start with a Hebrew letter)
**And** `core/policy` covers `mayAddMember`, `mayRemoveMember` and `nextMemberSeq`
**And** every repository write returns `Result<T>`, with `Failure(MessageKey)` for an expected rejection (AR12, AR20, AR26).

**FR1: Create a Group (UX-DR5, UX-DR6, UX-DR13, UX-DR15)**

**Given** no Groups exist
**When** the Organizer opens the app
**Then** the group list shows "כאן תופיע רשימת הקבוצות", and the "+ קבוצה חדשה" button is still present (T1.3).

**Given** stage 1 of the Create group screen
**When** the Organizer types "Trip to Eilat" and taps "יצירת קבוצה"
**Then** the Group is saved in one transaction and appears in the group list as a card showing its name and member count (T1.1)
**And** the same screen moves to stage 2: the group name becomes the top-bar title, and the "משתתפים" section opens with the add-member field and the member list.

**Given** the group-name field
**When** the Organizer types a 21st character or pastes a longer name
**Then** only the first 20 grapheme clusters are accepted, and leading and trailing spaces are removed on save (T1.36).

**Given** stage 1
**When** the Organizer saves an empty or whitespace-only name
**Then** "נדרש שם" shows inline under the field, and no Group is created (T1.4, T1.31).

**Given** a Group "Budapest" exists
**When** the Organizer creates " budapest "
**Then** "כבר קיימת קבוצה בשם הזה" shows inline, and no Group is created (T1.21; `nameKey` uniqueness also covers archived Groups, which T1.22 checks in Story 1.2).

**Given** stage 1
**When** the Organizer taps ✕
**Then** the screen closes, and nothing is created.

**Given** a valid name on stage 1
**When** the Organizer taps "יצירת קבוצה" twice quickly
**Then** exactly one Group exists, and no false "already exists" message is shown
**And** this works because the id is generated when the form opens, the insert does nothing if that id already exists, the notifier ignores calls while a save is in flight, and the button is disabled during the save (AR25).

**Given** stage 2
**When** the Organizer taps "סיום" or uses system back
**Then** the app runs `go('/group/:id')` and opens the new Group's page, and back from that page leads to the group list (AR21)
**And** the Group page shows the header block (UX-DR5): the nav (chevron icon + "הקבוצות שלי"), the group name with the "⚙ ✎" chip that opens Group settings (UX-DR25), the Trip total `₪0` and the line "{n} משתתפים". The Expense list and the bottom button bar arrive in Stories 1.3 and 1.4.

**FR2: Add Members (UX-DR10)**

**Given** stage 2 of Create group, or Group settings
**When** the Organizer adds "Dana"
**Then** Dana appears at once as an avatar row in her member color (assigned by `memberSeq`; member 7 wraps back to color 1), with the first word of her name under the circle (T1.2)
**And** the Member is saved as soon as it is added, in one transaction, with `memberSeq = MAX + 1` assigned once inside that transaction (AR11, AR14).

**Given** "Dana" is already in the Group
**When** the Organizer adds "Dana" or " dana "
**Then** "כבר יש משתתף בשם הזה" shows inline under the field, and no Member is added (T1.5, T1.6).

**Given** the add-member field
**When** the Organizer adds an empty or whitespace-only name
**Then** "נדרש שם" shows inline, and no Member is added (T1.7).

**Given** the member-name field
**When** the Organizer types "Alexandrina" or pastes a 15-character name
**Then** the field keeps exactly the first 10 grapheme clusters ("Alexandrin") (T1.34, T1.35).

**Given** a Group with 10 Members
**When** the Organizer adds "Gil"
**Then** "קבוצות מוגבלות ל-10 משתתפים" shows inline under the field, and nothing is added (T1.33).

**Given** two Members whose names start with the same first word
**When** their avatars are shown
**Then** both show their full name under the circle
**And** a name of up to 10 characters wraps to two lines and is never truncated (UX-DR10).

**FR3: Rename a Member (UX-DR25, UX-DR28)**

**Given** Group settings with the Member "Dana"
**When** the Organizer taps that Member's ✎ and saves "Danna" in the Rename sheet
**Then** "Danna" appears in the member list (T1.12, member-list part; the Expense and Transfer parts are checked in Stories 1.3 and 1.4).

**Given** the Member "dana"
**When** the Organizer renames her to "Dana"
**Then** the rename succeeds with no error, because the uniqueness check excludes the Member being renamed (T1.38).

**Given** the Member "Dana"
**When** the Organizer saves an empty name or the name of another Member
**Then** "נדרש שם" or "כבר יש משתתף בשם הזה" shows inside the sheet, and the name stays "Dana" (T1.39)
**And** the field accepts at most 10 grapheme clusters (T1.37)
**And** dismissing the sheet with "ביטול", the scrim or system back changes nothing (UX-DR8).

**FR4: Remove a Member**

**Given** Group settings for a Group with no Expenses
**When** the Organizer taps ✕ on a Member row
**Then** the Member is removed at once, with no sheet, and disappears from the member list; the removal is an SQL `DELETE` (AR15)
**And** the removal goes through `mayRemoveMember`, using facts from `PayerUsagePort`. The port is declared in `core/ports` and consumed by `groups`. Until Story 1.3 provides its drift implementation in `expenses/data`, `shell/` binds a stand-in that reports no Payer usage (AR6, AR12).

**FR5: Rename a Group**

**Given** the Group "Budapest"
**When** the Organizer opens "שם הקבוצה ›" in Group settings and saves "Budapest 2026"
**Then** the new name appears in the group list and on the Group page (T1.17; the Summary part is checked in Story 1.4).

**Given** the Group "Budapest"
**When** the Organizer saves an empty or whitespace-only name
**Then** "נדרש שם" shows inside the sheet, and the name stays "Budapest" (T1.18, T1.25).

**Given** the Groups "Budapest" and "Eilat"
**When** the Organizer renames "Eilat" to "Budapest"
**Then** "כבר קיימת קבוצה בשם הזה" shows, and the name stays "Eilat" (T1.23).

**Given** the Group "Budapest"
**When** the Organizer saves it as "Budapest", unchanged
**Then** the save succeeds, and no error is shown (T1.24).

**Quality**

**Given** the `groups` and `members` repositories
**When** their tests run on `NativeDatabase.memory()`
**Then** each write is one transaction that gathers its facts, calls `core/policy` and only then writes
**And** ids are UUID v7, `createdAt` is set once, and `modifiedAt` is set on insert and on every edit, all from one clock provider (AR11, AR13, AR26)
**And** with airplane mode on, every action in this story works, and the app makes no network call (NFR8; TX.1 for this story's scope).

### Story 1.2: Open straight into the trip, and archive old Groups

As the Organizer,
I want the app to open directly on my current trip's Group, and to archive Groups I no longer need,
So that the checkout flow starts at zero taps and my group list stays short.

**Scope:** FR6-FR9. Adds the `app_settings` table and the Group archive column through the first schema migration (`schemaVersion` 2). The Expense parts of read-only mode are enforced in Story 1.3, and the Summary parts in Story 1.4, both through the `isGroupMutable` policy delivered here.

**Acceptance Criteria:**

**Schema and rules (AR7, AR12, AR17, AR22, AR23)**

**Given** the database from Story 1.1
**When** this story's schema change lands
**Then** `groups` gains a nullable `archivedAt` (UTC epoch ms), and a single-row `app_settings` table holds a nullable `activeGroupId` FK to `groups`, owned and written only by the `groups` feature (AR7, AR22)
**And** `schemaVersion` is bumped to 2, with a migration step generated by `make-migrations` and the committed snapshot and generated migration test passing (AR23)
**And** no other store, such as shared_preferences, holds the Active group.

**Given** `core/policy`
**When** its unit tests run
**Then** `isGroupMutable`, `mayArchive`, `mayRestore` and `maySetActive` exist as pure functions returning a `Verdict`, and `mayArchive`, `mayRestore` and `maySetActive` do not call `isGroupMutable` (AR12)
**And** the rename-Group, add-Member, rename-Member and remove-Member writes from Story 1.1 now also check `isGroupMutable` inside their transactions.

**FR7: Offer to set a new Group as active (UX-DR8, UX-DR15)**

**Given** no Groups exist
**When** the Organizer creates "Budapest" on stage 1
**Then** the Active-group sheet slides up at once, before any Member can be added, with the title "להפוך את הקבוצה לקבוצה הפעילה?", the body "האפליקציה תיפתח ישר לתוך הקבוצה הזו." and the buttons "כן, להפוך לפעילה" / "לא עכשיו" (T1.40)
**And** whatever the answer, and also on scrim or back, the sheet closes and stage 2 opens.

**Given** no Group is active
**When** the Organizer confirms the sheet for "Budapest"
**Then** "Budapest" is the Active group, and relaunching the app opens directly on Budapest's page (T1.8).

**Given** "Eilat" is the Active group
**When** the Organizer creates "Budapest"
**Then** the sheet shows the warning strip "הקבוצה 'Eilat' תפסיק להיות הקבוצה הפעילה" before the change is applied (the name enters the sentence through `isolateName()`)
**And** after confirming, only "Budapest" is active (T1.9).

**Given** "Eilat" is the Active group
**When** the Organizer creates "Budapest" and declines with "לא עכשיו", the scrim or back
**Then** "Eilat" stays the Active group (T1.19).

**FR8: Set or unset the Active group at any time (UX-DR13, UX-DR25, UX-DR26)**

**Given** Group settings for a Group, with no Group active
**When** the Organizer switches the "קבוצה פעילה" toggle on
**Then** the Group becomes the Active group at once, with no sheet, and the change is saved immediately.

**Given** "Eilat" is active, and Group settings is open for "Budapest"
**When** the Organizer switches the toggle on
**Then** the Active-group sheet opens with "הקבוצה 'Eilat' תפסיק להיות הקבוצה הפעילה", and the toggle stays off until "כן, להפוך לפעילה" is tapped
**And** after confirming, only "Budapest" is active and relaunching opens Budapest's page (T1.32)
**And** on "לא עכשיו", the scrim or back, the toggle returns to off and "Eilat" stays active.

**Given** "Budapest" is active
**When** the Organizer switches its toggle off
**Then** the Active group is unset at once, with no sheet; the group list shows no "⭐ פעילה"; and the next launch opens the group list (T1.10).

**Given** any moment
**When** the Active group changes
**Then** at most one Group is active, and the Active group's card in the group list has a 6dp orange start edge and the badge "⭐ פעילה" (UX-DR13).

**FR9: Launch into the Active group (AR21)**

**Given** "Budapest" is active and the app is not running
**When** the Organizer launches the app
**Then** `shell/` reads `activeGroupId` before `runApp` and passes the Group route as `initialLocation`, so Budapest's page shows with no intermediate screen and the group list never flashes first
**And** cold launch to that page takes at most 2 seconds on the Galaxy S25 (NFR5, TX.3).

**Given** no Group is active
**When** the Organizer launches the app
**Then** the group list shows.

**Given** the app launched straight into "Budapest"
**When** the Organizer taps the nav (chevron icon + "הקבוצות שלי") or uses system back
**Then** the group list shows, and other Groups can be opened (T1.11).

**FR6: Archive a Group (UX-DR14, UX-DR29, UX-DR30)**

**Given** Group settings for "Budapest", which is the Active group
**When** the Organizer taps "🗂 העברה לארכיון" and confirms the Archive sheet ("להעביר את “Budapest” לארכיון?", "הנתונים נשמרים ואפשר לשחזר בכל רגע.", "העברה לארכיון" / "ביטול")
**Then** in one transaction the Group is archived and `activeGroupId` is cleared (AR17)
**And** Budapest disappears from the group list, appears in the Archive view, and is no longer active (T1.15)
**And** "ביטול", the scrim or back changes nothing.

**Given** at least one archived Group
**When** the Organizer opens the group list
**Then** the link "🗂 ארכיון (n)" shows at its bottom, and it is hidden when there are no archived Groups
**And** the Archive view uses the group-list layout with gray archived cards (`archived-card-surface` / `archived-card-ink`, no colored edge), each with a "↩ שחזור" text button.

**Given** "Budapest" is archived
**When** the Organizer creates a Group named "Budapest"
**Then** "כבר קיימת קבוצה בשם הזה" shows, and no Group is created (T1.22).

**Given** "Budapest" is archived
**When** the Organizer taps its card in the Archive view
**Then** the Group page opens read-only: header nav chevron icon + "ארכיון", badge "🗂 בארכיון", no "⚙ ✎" chip, and the archive note "🗂 הקבוצה בארכיון ולכן לקריאה בלבד. שחזור יחזיר את האפשרות לערוך." directly above a bottom bar whose primary slot is "↩ שחזור מהארכיון"
**And** routes to `add`, `edit` and `settings` for an archived Group are redirected away, and read-only mode comes from `isGroupMutable`, never from the route (AR21)
**And** renaming the Group, adding, renaming or removing a Member, and setting it active are all impossible, both in the UI and in the repositories, where they return `Failure(MessageKey)` (T1.26 for Members, name and Active; Expenses in Story 1.3, Summary in Story 1.4).

**Given** "Budapest" is archived
**When** the Organizer taps "↩ שחזור מהארכיון" on its page, or "↩ שחזור" on its Archive card
**Then** it is restored with no confirmation, all its Members unchanged, and every action available again (T1.16)
**And** either way the app runs `go('/group/:id')` (AR21): from its own page the same page stays open without the badge and note, and back now leads to the group list
**And** a restored Group is not made active automatically.

**Quality**

**Given** the Active-group and archive repositories
**When** their tests run on `NativeDatabase.memory()`
**Then** setting active, unsetting, archiving and restoring are each one transaction that checks `maySetActive`, `mayArchive` or `mayRestore` before writing (AR11)
**And** the launch-route choice is covered by a test for both cases: Active group set and no Active group.

### Story 1.3: Record, fix and delete Expenses at the checkout

As the Organizer,
I want to record each shared Expense in at most 4 taps, one-handed, and fix or delete it later,
So that every payment of the trip is captured the moment it happens and stays correct.

**Scope:** FR10-FR14, plus the parts of FR2, FR3, FR4 and FR6 that need Expenses. Adds the `expenses` table (`schemaVersion` 3). The Summary button and screen arrive in Story 1.4.

**Acceptance Criteria:**

**Schema, rules and ports (AR6, AR7, AR9, AR11, AR12, AR14, AR15, AR17, AR23, AR25)**

**Given** the database from Story 1.2
**When** this story's schema change lands
**Then** an `expenses` table, owned and written only by the `expenses` feature, holds `id` (UUID v7), `groupId`, `payerId`, `amount` (integer tenths), `category` (stable string key of a Dart enum, never localized text), `description` (nullable), `saveSeq`, `createdAt`, `modifiedAt`
**And** `UNIQUE(groupId, saveSeq)` holds, and `expenses(groupId, payerId)` references `members(groupId, id)` with `ON DELETE RESTRICT` (SQLite needs a `UNIQUE(groupId, id)` on `members` as the FK target; add it in the same migration if Story 1.1 did not)
**And** an Expense stores no participant list (AR16)
**And** `schemaVersion` is bumped to 3, with the generated migration step, snapshot and migration test committed (AR23).

**Given** `core/policy`
**When** its unit tests run
**Then** `mayRecordExpense` (at least 2 Members), `mayModifyExpense`, `defaultPayer` and `nextSaveSeq` exist as pure functions, and every Expense write also checks `isGroupMutable` (AR12)
**And** `saveSeq = MAX + 1` per Group is assigned once inside the insert transaction and never changed by an edit (AR14).

**Given** `PayerUsagePort`
**When** this story lands
**Then** its drift implementation lives in `expenses/data`, depends only on `AppDatabase`, and replaces the Story 1.1 stand-in in the `shell/` overrides (AR6, AR9)
**And** the group-list card total comes from `GroupTotalsPort` in `core/ports`, implemented in `expenses/data` in the same way, so `groups` never imports `expenses` (AR6, AD-2).

**Group page and Expense list: FR12 (UX-DR5, UX-DR7, UX-DR16, UX-DR17)**

**Given** a Group with at least two Members and no Expenses
**When** the Organizer opens its page
**Then** it shows "עדיין אין הוצאות", the Trip total `₪0` and an empty category stripe (T2.2)
**And** the bottom bar shows "+ הוספת הוצאה" as the primary button on the right, taking about two thirds of the width, in the lower half of the screen (NFR2).

**Given** Expenses of ₪300 and ₪87.4
**When** the Organizer opens the Group page
**Then** the header shows the Trip total "₪387.4" and the line "{n} משתתפים · {m} הוצאות" (T2.14)
**And** the 8dp category share stripe shows one segment per Category, proportional to its share of the Trip total, and recomputes on every Expense change
**And** the group-list card shows the same total.

**Given** a list of Expenses
**When** it is shown
**Then** Expenses are ordered newest first by `saveSeq`, never by the clock (T2.25: after A, B, C, a clock set back one day, then D, the list reads D, C, B, A)
**And** each row is a white card of at least 72dp with a 6dp start-edge stripe and a 46dp emoji circle tinted 15% in the Category color, the Category name (or the Description for *Other*) as title, the meta line "payer · date time" (first-save time), and the amount through `formatShekel()` on the end side
**And** the list fades into the canvas over 56dp above the bottom bar, and the last row comes to rest above the buttons, never under them.

**Given** a Group with fewer than two Members
**When** the Organizer opens its page
**Then** "+ הוספת הוצאה" is disabled (40% opacity, no shadow, label unchanged, does nothing when tapped), and "יש להוסיף לפחות שני משתתפים כדי לרשום הוצאות" shows directly above the bottom bar (T2.22)
**And** the repository also refuses the insert through `mayRecordExpense`.

**Add an Expense: FR10 (UX-DR4, UX-DR6, UX-DR12, UX-DR18-UX-DR23, NFR1-NFR3)**

**Given** the Group page
**When** the Organizer taps "+ הוספת הוצאה"
**Then** the Add expense screen opens with, from top to bottom: compact top bar (✕ on the start side, group name centered), Amount empty with a caret (46sp, ₪ tinted `currency-mark`), payer picker, 4×2 Category grid, custom keypad and a wide "שמירה" button
**And** there are no section labels, the keypad and Save are pinned to the bottom inside the system insets, and the region above them never scrolls
**And** no Category is selected, and the Expense id is generated now (AR25).

**Given** the last saved Expense (highest `saveSeq`) was paid by Motty
**When** the Organizer taps "+ הוספת הוצאה"
**Then** the Amount is focused with the keypad open and Motty is the selected Payer (T2.8).

**Given** a new Group whose Members were added in the order Motty, Dana, with no Expenses
**When** the Organizer taps "+ הוספת הוצאה"
**Then** the Payer is Motty, the earliest-added Member still in the Group (T2.9).

**Given** Expenses paid by Motty and then by Dana, and Dana's Expense is deleted
**When** the Organizer taps "+ הוספת הוצאה"
**Then** the Payer is Motty (T2.26).

**Given** the payer picker
**When** it is shown
**Then** every Member (up to 10) is visible at once as a 44dp avatar in a 48dp slot, 6 per row, in `memberSeq` order: one row for up to 6 Members, a second start-aligned row for 7-10, never scrolling
**And** the selected Payer has a 3dp canvas gap ring plus a 2dp ring in the member color, and unselected avatars show at 55% opacity
**And** one tap selects another Member and the keypad stays open.

**Given** the Category grid
**When** it is shown
**Then** the eight 64dp tiles appear in the fixed order ✈️ טיסה, 🏨 מלון, 🚗 רכב, ⛽ דלק, 🍝 מסעדה, 🛒 אוכל ושתייה, 🎡 אטרקציות, 📝 אחר
**And** a tap selects a tile (2dp border, 16% tint, bold label) and replaces any previous selection, and never saves on its own.

**Given** the 4×2 grid does not fit at the required touch-target size (small screen, a second payer row, or font scale up to 150%)
**When** the Add expense screen opens
**Then** the Categories show as a two-page sideways row: page 1 holds the first four, page 2 (on the left) the last four, with no third page
**And** the first tile of the other page peeks in about a quarter tile, two 8dp page dots sit centered 8dp below the row, and one swipe snaps to the other page with the keypad still open (T2.18)
**And** the selection stays selected across pages, Add opens on page 1, and after a validation error the row stays where it was.

**Given** the custom keypad
**When** the Organizer types "87.45"
**Then** the field shows 87.4, because a second digit after the decimal point is not accepted (T2.4)
**And** the keypad has keys 1-9, `.`, 0 and ⌫ in LTR digit order, 48dp keys and no "00" key, and parsing and bounds live only in `core/money` (AR17).

**Given** Amount 87.4 typed and the keypad open
**When** the Organizer taps "Food & drink" and then "שמירה"
**Then** the Expense is saved without the keypad having been closed first (T2.17).

**Given** a Group with Dana, Yossi and Noa
**When** the Organizer saves Dana, ₪300, Hotel
**Then** in one transaction the Expense is stored exactly once, and the app returns to the Group page within 300 ms (NFR5, TX.4)
**And** the new row slides gently into the top of the list, showing Dana, ₪300, Hotel and the time it was saved (T2.1).

**Given** a valid Expense on screen
**When** the Organizer taps "שמירה" twice quickly
**Then** exactly one Expense is added and the app is on the Group page (T2.21)
**And** Save is disabled during the save, the notifier ignores calls while a save is in flight, the insert does nothing if the id already exists, and the screen closes only after success (AR25).

**Given** the Active group is set and the last Payer is correct
**When** the Organizer launches the app and adds 87.4 Food & drink
**Then** the Expense is saved in at most 4 taps, not counting typing the Amount (T2.10, NFR1).

**Given** the two-page Category row and a correct last Payer
**When** the Organizer launches the app and adds ₪50 with each Category in turn
**Then** every Expense is saved in at most 4 taps, counting each swipe as a tap (T2.19).

**Given** the Active group is set and the last Payer is Motty
**When** the Organizer launches, taps "+ הוספת הוצאה", types 200, taps Dana, taps ⛽ דלק and taps "שמירה"
**Then** the Expense is saved with Payer Dana in 4 taps, within the 5-tap budget, and the next "+ הוספת הוצאה" defaults to Dana (T2.20).

**Given** an Expense saved at 10:00
**When** the Organizer edits its Amount at 12:00 and saves
**Then** the list still shows 10:00 for it, because the recorded time is `createdAt` and cannot be set by hand (T2.29, AR8).

**Leaving with unsaved input: FR10 (UX-DR9)**

**Given** Amount 87 typed on a new Expense
**When** the Organizer uses the back gesture or ✕ and confirms "יציאה" in the Exit sheet ("לצאת ללא שמירה?", "מה שהזנת לא יישמר.")
**Then** the Group page shows and no Expense was added (T2.27).

**Given** Amount 87 typed on a new Expense
**When** the Organizer uses the back gesture and taps "המשך עריכה", the scrim or back
**Then** the Expense screen shows with 87 still entered (T2.28).

**Given** a new Expense with no typed Amount, no Description, no Category and the default Payer, or an edit with no field changed
**When** the Organizer leaves the screen
**Then** it closes at once with no sheet
**And** the guard uses `PopScope` with the shared exit sheet (AR21).

**Validation: FR11**

**Given** an Amount that is empty, 0, -50 or 1,000,001
**When** the Organizer taps "שמירה"
**Then** the Expense is not saved, does not appear in the list, and "סכום לא תקין" shows inline in `danger` (T2.3a-T2.3d)
**And** with Payer Dana, Category Hotel and Amount 0, Dana and Hotel stay selected (T2.15).

**Given** Amount 1,000,000 and Category Hotel
**When** the Organizer taps "שמירה"
**Then** the Expense is saved (T2.3e).

**Given** Amount 87.4 and no Category
**When** the Organizer taps "שמירה"
**Then** the Expense is not saved and "נא לבחור קטגוריה" shows (T2.5).

**Given** Amount 50 and Category Other
**When** the Organizer taps 📝 אחר
**Then** the keypad is replaced by a Description field (placeholder "מה קנית?") with the system text keyboard, and Save sits just above it
**And** saving with an empty or whitespace-only Description is refused with "נדרש תיאור או בחירת קטגוריה" (T2.6, T2.23)
**And** saving with "Umbrella" adds a row showing "Umbrella" (T2.7).

**Edit an Expense: FR13 (UX-DR17, UX-DR21, UX-DR23)**

**Given** an Expense of ₪870
**When** the Organizer taps its row, changes the Amount to 87 and saves
**Then** the edit screen opened with every field filled and the meta line "נרשם {date time} · נערך עכשיו"
**And** the list shows ₪87, the Trip total drops by ₪783, and the row keeps its place because its `saveSeq` is unchanged (T2.11)
**And** `modifiedAt` is updated and `createdAt` is not (NFR12).

**Given** an Expense of ₪87
**When** the Organizer changes its Amount to 0 and saves
**Then** the change is not saved and "סכום לא תקין" shows (T2.24).

**Given** an Expense whose Category is on page 2 of the two-page row
**When** the Organizer opens it for editing
**Then** the row opens on page 2.

**Given** an Expense whose Payer is changed in the edit screen
**When** the Organizer saves
**Then** its `saveSeq` and recorded time do not change.

**Delete an Expense: FR14 (UX-DR11, UX-DR24)**

**Given** an Expense of ₪87
**When** the Organizer long-presses its row, or taps "🗑 מחיקה" in the edit screen, and confirms "מחיקה" in the Delete sheet ("למחוק את ההוצאה?", the expense line, "אי אפשר לבטל את הפעולה.")
**Then** the Expense is removed with an SQL `DELETE`, the Trip total drops by ₪87, and the snackbar "ההוצאה נמחקה" appears with no undo (T2.12, AR15).

**Given** an Expense of ₪87
**When** the Organizer long-presses it and taps "ביטול", the scrim or back
**Then** the Expense stays in the list unchanged (T2.13).

**Given** the Expense list
**When** the Organizer swipes a row
**Then** nothing happens: there is no swipe-to-delete.

**Members and archive with Expenses: FR2, FR3, FR4, FR6 (UX-DR27, UX-DR30)**

**Given** Member Yossi is the Payer of an Expense
**When** the Organizer taps ✕ on Yossi's row in Group settings
**Then** Yossi is not removed, and "לא ניתן להסיר משתתף שיש הוצאה על שמו" shows inline under his row in `danger`, replacing any previous message (T1.14)
**And** the repository refuses it through `mayRemoveMember` with facts from `PayerUsagePort`, and the FK `ON DELETE RESTRICT` backs this up.

**Given** a Group with Expenses, where Noa paid for nothing
**When** the Organizer taps ✕ on Noa
**Then** the Remove-member sheet opens ("להסיר את נועה?", "ההוצאות יתחלקו מחדש בין 3 המשתתפים הנותרים.", "הסרה" / "ביטול"), and "ביטול" changes nothing.

**Given** Member Dana paid an Expense
**When** the Organizer renames her to "Danna"
**Then** "Danna" appears on all of her Expense rows (T1.12, Expense part).

**Given** "Budapest" is archived and has Expenses
**When** the Organizer opens it from the Archive view
**Then** the Expense list, Trip total and stripe show as usual, but tapping or long-pressing a row does nothing, "+ הוספת הוצאה" is replaced by "↩ שחזור מהארכיון", and the `add` and `edit` routes redirect away (T1.26, Expense part)
**And** the repository refuses adding, editing and deleting through `isGroupMutable` and `mayModifyExpense`.

**Quality**

**Given** the `expenses` repository
**When** its tests run on `NativeDatabase.memory()`
**Then** add, edit and delete are each one transaction that gathers facts, calls `core/policy` and only then writes, and an interrupted save stores either the whole change or none of it (NFR9)
**And** reads are providers wrapping `.watch()` streams, so the list, Trip total, stripe and card total update with no manual refresh (AR9).

**Given** a Group with Members and Expenses
**When** the app is force-stopped and the phone restarts
**Then** all Groups, Members and Expenses are unchanged (TX.2).

**Given** the Android "Remove animations" setting is on
**When** an Expense is saved or a sheet opens
**Then** the row slide-in and the sheet slide are skipped; these are the only two animations in the app and both go through one helper (UX-DR12).

### Story 1.4: Settle up with one screenshot

As the Organizer,
I want a Summary that shows the Trip total and the shortest list of who pays whom how much,
So that I can send one screenshot to the trip's WhatsApp group and my friends settle up without asking anything.

**Scope:** FR15-FR16, plus the Summary parts of FR2, FR3, FR4, FR5 and FR6. Adds the `settle_up` feature (`ui`, `app`, `domain`; no `data`, no tables). It only reads.

**Acceptance Criteria:**

**Transfer calculation: FR15 (AR11, AR16, AR17, AR18, NFR15, NFR16)**

**Given** the `settle_up/domain` calculation
**When** it runs
**Then** it is one pure function whose input is one snapshot of the Group's Members and Expenses, read in a single read transaction through the `groups` and `expenses` repository interfaces, and it runs only when `maySummarize` allows (at least 2 Members)
**And** every amount is `Tenths`, `double` never holds money, and no widget or SQL query computes a Share, a Balance or a Transfer (AR16, AR17)
**And** the Share is the Trip total divided by the number of Members, rounded down to ₪0.10, and each starting Balance is paid minus Share.

**Given** the starting Balances add up to a Leftover
**When** the Leftover step runs
**Then** it is taken only from receivers, first from the one who paid the smallest total; a Balance stops at zero and the rest moves to the next-smallest; a debtor's Balance never changes
**And** between receivers with equal totals, the one whose first Expense (lowest `saveSeq` among the Expenses they currently pay) was saved later absorbs first; the clock is never used
**And** afterwards the Balances add up to exactly zero.

**Given** the Balances after the Leftover step
**When** the Transfer list is built
**Then** it is an exact search over zero-sum partitions, never greedy matching, and returns the minimum number of Transfers
**And** every Transfer goes from a negative Balance to a positive one, so no Member both sends and receives; only such lists are candidates
**And** among minimal lists it chooses the one whose (debtor, receiver) sequence, sorted by debtor then receiver, comes first under the `core/text` collation (AR18)
**And** the list is empty exactly when every Balance is zero, and there is no minimum Transfer: ₪0.1 is shown.

**Given** the unit tests of the calculation
**When** they run
**Then** each of these gives exactly the expected Transfers:
- Dana 300, Yossi 0, Noa 0 → Yossi → Dana ₪100, Noa → Dana ₪100 (T3.1)
- Dana 100, Yossi 100 → no Transfers (T3.3)
- Dana 100, Yossi 0, Noa 0 → Yossi → Dana ₪33.3, Noa → Dana ₪33.3 (T3.4)
- Dana 87.4, Yossi 0 → Yossi → Dana ₪43.7 (T3.5)
- מוטי 400, דנה 200, יוסי 0, נועה 0 → יוסי → דנה ₪50, יוסי → מוטי ₪100, נועה → מוטי ₪150 (T3.6)
- Dana 33.4, Yossi 33.3, Noa 33.3 → no Transfers (T3.15)
- Dana 100.5, Yossi 100 → Yossi → Dana ₪0.2 (T3.16)
- Dana 101.5, Yossi 100, Noa 100 → Yossi → Dana ₪0.5, Noa → Dana ₪0.5 (T3.18)
- Dana 3, Yossi 0, Noa 0, Avi 0 → each of Yossi, Noa, Avi → Dana ₪0.7 (T3.19)
- Zoe 400, דנה 200, Adam 0, יוסי 0 → יוסי → דנה ₪50, יוסי → Zoe ₪100, Adam → Zoe ₪150 (T3.20)
- אבי 100.1, גיל 100, בני 0, דוד 0 → בני → אבי ₪0.1, בני → גיל ₪49.9, דוד → אבי ₪50 (T3.31)
- אברהם 60, יצחק 40, יעקב 0 → יעקב → אברהם ₪26.7, יעקב → יצחק ₪6.6 (T3.32)
- אברהם 50 (saved first), יצחק 50 (saved second), יעקב 0 → יעקב → אברהם ₪16.7, יעקב → יצחק ₪16.6 (T3.33, T3.39)
- אבי 30.2, בני 10.1, גיל 0, דוד 0 → גיל → אבי ₪10, דוד → אבי ₪10 (T3.35)
- מוטי 400, דנה 200, גיל 0, ג'ני 0 → גיל → דנה ₪50, גיל → מוטי ₪100, ג'ני → מוטי ₪150 (T3.37)
- מוטי 400, נועה 200, דניאל 0, דני2 0 → דניאל → מוטי ₪100, דניאל → נועה ₪50, דני2 → מוטי ₪150 (T3.38)
**And** the suite also covers uneven tenths, a Leftover over several receivers, ties between minimal lists with Hebrew, Latin and mixed names, and Groups of 2 to 10 Members (NFR16)
**And** a 10-Member case completes within 1 second (NFR5).

**Given** the T3.6 Group
**When** "יוסי" is renamed to "שי" and the Summary is opened again
**Then** the Transfers are נועה → דנה ₪50, נועה → מוטי ₪100, שי → מוטי ₪150, and each Member's total paid or received is unchanged (T3.17).

**Given** the T3.33 Group
**When** "אברהם" is renamed to "תום"
**Then** the Transfers are יעקב → יצחק ₪16.6, יעקב → תום ₪16.7 (T3.34).

**Given** the T3.33 Group
**When** the phone's time zone changes
**Then** the Transfers are unchanged (T3.40).

**Given** יצחק paid ₪50 first, the phone's clock is then set back one day, and אברהם pays ₪50; יעקב paid 0
**When** the Summary is computed
**Then** יצחק counts as having paid earlier: יעקב → אברהם ₪16.6, יעקב → יצחק ₪16.7 (T3.45).

**Summary screen: FR16 (AR19, UX-DR5, UX-DR31, UX-DR32, UX-DR33)**

**Given** a Group page
**When** it is shown
**Then** "סיכום" is always visible as the secondary button on the left of the bottom bar, about one third of the width
**And** with fewer than two Members it is disabled (40% opacity, does nothing) (T3.2).

**Given** the Group "Budapest" with Transfers
**When** the Organizer taps "סיכום"
**Then** the Summary shows the header block with the group name, the Trip total, the share line "{n} משתתפים · ₪{share} לאחד" and the category stripe, then the title "מי מעביר למי", then one Transfer card per Transfer with an 8dp gap (T3.7)
**And** there is no bottom button bar, no Balance table and no breakdown of the calculation.

**Given** a Transfer
**When** its card is shown
**Then** it reads "תשלום נדרש מ{debtor} ל{receiver} ₪N", built from the `MessageKey` table, with each name passed through `isolateName()` and the amount through `formatShekel()`
**And** the card has the `transfer-surface` background, a 6dp orange start edge, a decorative pair of 32dp initial-only avatars (debtor, then receiver, 4dp apart, nothing between them), the sentence in row-title and the amount in transfer-amount closing the line
**And** no arrow or other direction symbol appears anywhere, the card is not tappable, and long names wrap while the amount stays at the end.

**Given** Members דנה (paid 300), יוסי and נועה
**When** the Organizer opens the Summary and takes a screenshot
**Then** the lines read "תשלום נדרש מיוסי לדנה ₪100" and "תשלום נדרש מנועה לדנה ₪100" (T3.43).

**Given** Members Zoe (paid 300), Adam and דנה
**When** the Organizer opens the Summary and takes a screenshot
**Then** the lines read "תשלום נדרש מ-Adam ל-Zoe ₪100" and "תשלום נדרש מדנה ל-Zoe ₪100", with each line's word order intact (T3.44).

**Given** every Balance is zero
**When** the Organizer opens the Summary
**Then** "החשבון מאוזן, אין צורך בהעברות" shows in place of the cards (T3.3, T3.15).

**Given** a Group of up to 6 Members at the default font size on the Galaxy S25
**When** the Organizer opens the Summary
**Then** the header, the title and every Transfer card fit on one screen with no scroll (T3.8; the on-device measurement of whether 5 long-name Transfers fit, EXPERIENCE.md OQ1, is set aside by the founder for now, 2026-11-01).

**Given** a Group of 10 Members with Expenses
**When** the Organizer opens the Summary
**Then** it appears within 1 second (NFR5), the header and "מי מעביר למי" stay fixed, and only the Transfer cards scroll, fading into the canvas over 56dp at the bottom edge when more cards exist (T3.46)
**And** above 100% font scale the whole Summary may scroll.

**Summary across the other features: FR2-FR6**

**Given** Dana paid 300 and Yossi paid nothing
**When** the Organizer adds Member Noa and opens the Summary
**Then** the Transfers are Yossi → Dana ₪100 and Noa → Dana ₪100 (T1.20).

**Given** Dana paid 300, Yossi and Noa paid nothing
**When** the Organizer removes Noa and opens the Summary
**Then** the Summary shows Yossi → Dana ₪150 (T1.13).

**Given** Member Dana paid an Expense
**When** she is renamed to "Danna"
**Then** the Summary shows "Danna" and the Transfer amounts are unchanged (T1.12, Transfer part).

**Given** the Group "Budapest"
**When** it is renamed to "Budapest 2026"
**Then** the Summary header shows "Budapest 2026" (T1.17, Summary part).

**Given** Dana paid ₪300, with Members Dana, Yossi and Noa
**When** the Organizer edits the Expense to ₪150 and opens the Summary
**Then** the Transfers are Yossi → Dana ₪50 and Noa → Dana ₪50 (T2.16).

**Given** "Budapest" is archived
**When** the Organizer opens its Summary from its read-only page (route `archive/group/:id/summary`)
**Then** the Summary shows as usual, with the badge "🗂 בארכיון" and the archive note "🗂 הקבוצה בארכיון ולכן לקריאה בלבד." under the cards (T1.26, Summary part)
**And** on the archived Group page "סיכום" sits beside "↩ שחזור מהארכיון".

**Quality (AR26, NFR6, NFR8)**

**Given** the Summary golden tests
**When** they run with bundled Heebo at text scale 1.0 and 1.5
**Then** they cover Hebrew-only, Latin-only and mixed names, with every line in the correct RTL word order and no arrow (NFR6).

**Given** Member names "Dan", "דנה" and "Zoe Lee"
**When** the Organizer opens the Group page, the Expense list and the Summary
**Then** every screen is right-to-left and every name and amount displays in the correct order (TX.5).

**Given** airplane mode is on
**When** the Organizer creates a Group, adds Members and Expenses and opens the Summary
**Then** every action works and the app makes no network call (TX.1).
