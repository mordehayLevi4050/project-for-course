---
review: reconcile-prd
target: ../ARCHITECTURE-SPINE.md (updated 2026-11-01)
companion: ../.memlog.md
source: ../../../prds/prd-groupay-2026-10-26/prd.md + addendum.md
date: 2026-11-01
---

# Review: Spine vs PRD Reconciliation

## Verdict

**Needs revision before epics.** The spine covers the structural core well: ids, money, save order, computed split, table ownership, the text and collation rules, archive and Active-group storage, bidi. No AD contradicts an FR outright. However, it contradicts the PRD on one delivery point (which build runs on the trip phone). It also leaves several guard rules unbound to any AD, so the add and edit flows, or `groups` and `expenses`, can each implement them their own way. The biggest gaps are FR-10 save-once, the count guards (10 Members max, at least 2 Members), the NFR-14 Expense edit/delete permission, the mechanism for Group-name uniqueness, and the launch and Summary paths behind NFR-5.

Severity scale: **High** means a requirement will likely be silently dropped or will contradict the PRD. **Medium** means two units will likely diverge. **Low** means worth one line in the spine or a story note.

## Findings

### F1 — FR-10 save-once / double-tap idempotency has no architectural home [High]

- **PRD:** FR-10: "A second tap on *Save* before the screen closes creates nothing. The same applies to saving an edit (FR-13)." NFR-5 says saving returns to the Group page in under 300 ms.
- **Spine:** Nothing. AD-6 makes a write atomic, but it does not make it idempotent. AD-8 says ids are generated on the device, but not *where* or *when*.
- **Risk:** The add screen and the edit screen will each invent a guard, or forget one: a disabled button, a notifier `isSaving` flag, or a pop-before-await. A double tap on create Expense makes two rows with two `saveSeq` values. The same issue hits other create actions. A double tap on create Group or add Member makes the second insert fail uniqueness, so the UI wrongly shows "Group already exists" or "Member already exists" after a successful save.
- **Fix:** Add a rule, either inside AD-6 or as a new AD: *every create action receives its UUID v7 when the form opens (the notifier holds it). The repository insert is keyed on that id and is a no-op if the id already exists, so a duplicate submit returns the existing `Success`. The notifier also ignores submits while a save is in flight. The screen pops only after the `Success`.* Apply it to Group, Member, and Expense creation and to Expense edits. Edits are idempotent by id already, but the second tap must not re-run validation against a closed screen.

### F2 — Build type on the trip phone contradicts PRD §9 [High]

- **PRD:** §9: "The trip phone runs a debug build, so the Organizer can copy the app's database to a computer with `adb`". SM-C1 and SM-C2 depend on that copy. NFR-5 sets a cold launch of 2 seconds or less.
- **Spine:** AD-19 says "A release is a release APK installed on the Organizer's phone". Debug builds get the `.dev` suffix, which makes them a *different app* with different data.
- **Contradiction:** `adb run-as` only works on debuggable builds, so a release APK cannot be read with adb, and the counter-metrics become unmeasurable. The literal PRD wording has its own problem: a Flutter *debug* (JIT) build will likely miss NFR-5's 2-second cold launch, and it would install under `.dev`.
- **Fix:** Decide the trip build explicitly in AD-19, then ask the PM to align the PRD §9 wording. Recommended: a release-mode (AOT) build under the permanent `com.mordehay.groupay`, signed with the release keystore and marked `debuggable true` for the trip build only. That keeps `run-as` working while keeping the performance and the signature. Alternatively, accept a debug-only metric extraction path and state that NFR-5 is measured on the release build.

### F3 — Count and threshold guards are missing from the core/policy list [Medium-High]

- **PRD:**
  - FR-2: "A Group has at most 10 Members … rejected with 'A group can have at most 10 members'".
  - FR-10: *Add expense* is disabled while the Group has fewer than 2 Members.
  - FR-16: the Summary entry is disabled with fewer than 2 Members.
  - FR-4 makes this reachable: a Group with Expenses can drop to 1 Member.
- **Spine:** AD-7 lists only remove-Member, `isGroupMutable`, set-active, default Payer, and next `saveSeq`. The 10-Member cap is not mentioned anywhere.
- **Risk:**
  - The cap is checked only in the UI, not in the add-Member transaction (AD-6).
  - The "at least 2" rule is computed separately on the Group page, the Summary button, and the `/summary` route, which can be reached directly through go_router.
  - The Transfer function gets called with 0 or 1 Members and divides by zero.
- **Fix:** Add `mayAddMember(memberCount)` (enforced inside the add transaction, `Failure(groupMemberLimit)`), `mayRecordExpense(memberCount)`, and `maySummarize(memberCount)` to AD-7. Put the constant `maxMembers = 10` in core/policy. State a precondition of at least 2 Members on the settle_up function, so that it returns an empty or invalid result instead of throwing.

### F4 — NFR-14 "who may edit or delete an Expense" has no named policy [Medium]

- **PRD:** NFR-14 lists four rules that change in the multi-user phase: Expense edit/delete permission, Group mutability, default Payer, and the save-order source. The addendum adds that only the Payer may edit in the multi-user phase.
- **Spine:** AD-7 covers three of the four. Edit/delete permission is folded into `isGroupMutable`.
- **Risk:** In the multi-user phase, payer-only editing has to be threaded into every Expense write site. That is exactly the "rewrite rather than replace" that NFR-14 forbids.
- **Fix:** Add `mayModifyExpense(actor, expense, groupFacts)` to AD-7. In v1 it returns `isGroupMutable`. Both the edit and delete paths, including the long-press delete on the list (FR-14), call it.

### F5 — Group and Member uniqueness: no enforcement mechanism, and archived Groups are easy to miss [Medium]

- **PRD:**
  - FR-1/FR-5: Group names are unique among *all* Groups, "including an Archived group". The compare ignores surrounding spaces and letter case. Saving a Group under its own name is allowed.
  - FR-2/FR-3: Member names are unique within the Group, excluding the Member being renamed, so a case-only rename is allowed.
- **Spine:** AD-13 defines the compare key but not *where* it is enforced or stored.
- **Risk:**
  - The repository reuses its "visible groups" query, which filters out archived Groups, for the duplicate check.
  - A story uses SQL `lower()`, which folds ASCII only, so Hebrew and Latin text with diacritics behave differently from the Dart compare key.
  - Rename forgets to exclude its own row.
- **Fix:** Add to AD-13/AD-18: persist a `nameKey` column computed only by `core/text`. Add a `UNIQUE(nameKey)` index on `groups`, covering archived and active Groups alike, and `UNIQUE(groupId, nameKey)` on `members`. The repository maps a constraint violation, or a pre-check inside the transaction, to `Failure(groupExists|memberExists)`. A rename compares against rows where `id != self`.

### F6 — FR-9 / NFR-5 launch path: "no intermediate screen" is not guaranteed [Medium]

- **PRD:** FR-9 opens the Active group's page "with no intermediate screen". NFR-5 sets a cold launch of 2 seconds or less.
- **Spine:** AD-16 says to use `go('/group/:id')` at launch. That reads as: render `/` first, then navigate, which flashes the group list. The spine does not say where `activeGroupId` is read.
- **Fix:** In AD-16/AD-17, read `app_settings.activeGroupId` once before `runApp`, or behind a splash-free router `redirect` that awaits the read. Build the router with an initial location, `/group/:id` stacked on `/`, so that back still returns to `/`. Add a cold-launch measurement to the testing conventions, on the release build (see F2).

### F7 — FR-15 algorithm constraint and NFR-5 Summary timing are not in the spine [Medium]

- **PRD/addendum:**
  - Minimum Transfers plus the alphabetical tie-break need an exhaustive search over zero-sum partitions. Greedy matching "fails EARS T3.6 and T3.31".
  - Transfers go only from debtors to receivers.
  - The 10-Member Summary must appear within 1 second on a *mid-range phone*.
- **Spine:** AD-11 says "one pure function". The testing convention is "10 Members in ≤1s", which in practice gets run on the dev PC.
- **Risk:**
  - A dev agent implements greedy matching.
  - The search runs on the UI isolate and recomputes on every `.watch()` emission, which causes jank.
  - The 1-second test passes on a PC but not on the phone.
- **Fix:** In AD-11:
  - Cite the addendum note: exhaustive partition search, not greedy, with the debtor-to-receiver-only candidate set.
  - Run the computation through `Isolate.run`, or prove that the worst case stays below a frame budget.
  - Specify a worst-case 10-Member fixture with a timing budget that has a safety margin, for example 250 ms on the PC.

### F8 — "Earliest-added Member" needs an ordering key; AD-9 forbids clocks [Medium]

- **PRD:** FR-10: with no Expenses, the default Payer is "the earliest-added Member still in the Group".
- **Spine:** AD-9 gives Expenses a `saveSeq`, but Members have no order key. The only candidates are `createdAt` (clock) or UUID v7 (also clock-derived). The display order of Payer options and of the member list is also undefined, so the Expense screen and Group settings may order Members differently.
- **Fix:** Add a per-Group `addSeq` on `members`, assigned like `saveSeq` (AD-9). The default-Payer policy and every Member list (Payer grid, settings) use it. Only the Summary uses the AD-13 collation.

### F9 — `createdAt` / `modifiedAt` semantics break SM-C1 [Medium]

- **PRD:** SM-C1 counts Expenses "whose last-modification time differs from their creation time" (NFR-12).
- **Spine:** AD-8 says only repositories set the times. It does not say *when* `modifiedAt` changes.
- **Risk:**
  - Two separate `now()` reads on insert make every Expense look edited.
  - An edit saved with no change bumps `modifiedAt`.
  - Renaming a Member might touch that Member's Expenses.
  
  Any of these makes the counter-metric meaningless.
- **Fix:** In AD-8: on create, `modifiedAt = createdAt` from a single clock read. On update, bump `modifiedAt` only when a persisted field of *that* record changes. An unchanged edit is a no-op write. Changes to related records never touch other records' times.

### F10 — Amount parse and bounds are not centralized [Medium]

- **PRD:** FR-11: the Amount must be greater than 0 and at most ₪1,000,000. The keypad refuses a second decimal digit. The message is "Please enter a valid amount". FR-13 reuses this validation on edit.
- **Spine:** AD-12 centralizes formatting (`formatShekel`) but not *parsing* or bounds.
- **Fix:** Add `parseShekelInput(String) → Tenths?`, the input formatter that limits input to one decimal, and `maxAmount = Tenths(10000000)` to `core/money`. Expense validation in `expenses/domain` uses them for both add and edit.

### F11 — Unsaved-changes guard: one mechanism for add and edit, and how it fits go_router [Low-Medium]

- **PRD:** FR-10: leaving the add *or* edit screen with unsaved input asks "Exit without saving?". Confirm discards the input; cancel keeps it.
- **Spine:** Silent. AD-5 keeps keypad input in `setState`, so the edit screen needs a baseline to diff against. AD-16 makes go_router the only navigator, and with `PopScope` the system back gesture and `context.pop` behave differently.
- **Fix:** In the Consistency Conventions table, add one shared `UnsavedChangesGuard`, a `PopScope` wrapper plus a dirty check (current form vs initial snapshot), used by both Expense routes. State that it does not fire after a successful save (see F1).

### F12 — Android Auto Backup is left open, but the PRD implies a decision [Low-Medium]

- **PRD:** NFR-10: "all data is stored only on the device". §7: there is no backup or restore in v1. NFR-8: no network calls.
- **Spine:** Lists Auto Backup (on by default) as an open question.
- **Fix:** Resolve it now as `android:allowBackup="false"`, or record an explicit PRD deviation. Leaving it open ships cloud backup by default. While here, assert that the release manifest has no `INTERNET` permission, which makes NFR-8 testable.

### F13 — Addendum: Category required must be a validation rule, not a structural constraint [Low]

- **Addendum:** Requiring a Category should be a validation rule, so that draft Expenses can be added later cheaply.
- **Spine:** AD-18 stores the Category as a string key and says nothing about nullability.
- **Fix:** Make `expenses.category` nullable in the schema. FR-11 ("Please choose a category") is enforced in `expenses/domain` validation.

### F14 — Durability pragma for NFR-9 "phone restart" [Low]

- **PRD:** NFR-9 requires that saved data survive a phone restart.
- **Risk:** If WAL is enabled with `synchronous=NORMAL`, the last committed transaction can be lost on power loss.
- **Fix:** In `core/db`, pin the journal mode and `synchronous=FULL` explicitly rather than relying on package defaults.

### F15 — Smaller text-rule gaps [Low]

- **Limit and trim order:** FR-1/FR-2 apply the 20/10-character limit, and trimming happens on save. The spine should state that the repository also validates the trimmed grapheme length, and that the constants `groupNameMax = 20` and `memberNameMax = 10` live in `core/text`, so field formatters and repository checks share them.
- **Description:** The PRD gives no maximum length. Decide on a cap or none. Also decide whether the Description is trimmed and stored, and whether it is cleared when the Category changes away from *Other*. Otherwise the list (FR-12) may show stale text.
- **Recorded time display:** Times are UTC (AD-8). FR-12 displays a time; specify device-local time, given travel across time zones.

## Covered Well (no action)

FR-4 payer guard (PayerUsagePort + RESTRICT FK) · FR-6 read-only via `isGroupMutable` on every write, and archive clears the Active group in the same transaction · FR-8 at most one Active group (single-row `app_settings`) · FR-2/FR-4 re-split (AD-11) · FR-15 save-order tie-break and list order (AD-9) · FR-15 collation (AD-13 matches the PRD exactly) · NFR-7/15 Tenths · NFR-6 i18n keys and `isolateName` · NFR-11/12/13 · NFR-17 minSdk 35.
