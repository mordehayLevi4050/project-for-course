---
type: review
lens: reconcile-ux
target: ../ARCHITECTURE-SPINE.md (+ ../.memlog.md)
against:
  - ../../../ux-designs/ux-groupay-2026-10-26/EXPERIENCE.md
  - ../../../ux-designs/ux-groupay-2026-10-26/DESIGN.md
date: 2026-11-01
verdict: revise-before-stories
---

# Review: Architecture spine reconciled against the UX spines

## Verdict

**Revise before stories.** The data, policy, money and bidi-name rules hold up well against the UX. The gaps are on the presentation side. The spine names `go_router`, `core/i18n` and `isolateName()`, then stops. It has no home for shared widgets or theme. It contradicts EXPERIENCE.md on two back-stack behaviors. It also sets no rule for edge-to-edge insets, motion, AsyncValue states or the font scale cap. The three features (`groups`, `expenses`, `settle_up`) will be built separately, and each of these gaps will be filled three different ways. One finding is a hard conflict with AD-2 (shared widgets cannot be imported across features). One is a contradiction with AD-16 (back after restore).

Scope: only UX requirements whose implementation crosses feature or layer boundaries. Per-screen visuals are ignored.

Severity: **High** means features will diverge, or a spine rule blocks a UX requirement. **Medium** means divergence is likely without a one-line rule. **Low** means clarify.

## Findings

### F1 (High). Shared UI components and theme have no home, and AD-2 forbids sharing them

- **UX:** DESIGN.md defines tokens (colors, typography, rounded, spacing) and components used across features. The Member avatar appears in Create group and Group settings (`groups`), in the payer picker (`expenses`) and in the Transfer card (`settle_up`). The header block (gradient, category stripe) appears on the Group page and the Summary. Bottom sheet, primary/secondary/disabled buttons, inline message and snackbar are used everywhere. DESIGN.md says "Light theme only".
- **Spine:** Deferred says "Visual design tokens and component structure: owned by DESIGN.md". AD-2 says a feature may import a lower feature's `domain/` and public `app/`, **never its `ui/`**. The structural seed has no `core/theme` or `core/widgets`.
- **Divergence:** `settle_up/ui` legally cannot reuse `groups/ui`'s avatar or `expenses/ui`'s header block, so each feature re-implements them. DESIGN.md is a document, not code, so "owned by DESIGN.md" leaves the code-level owner undefined. Hex literals and `TextStyle`s will be scattered across widgets.
- **Fix:** Add an AD such as "Design system in `core/ui`". `core/ui/theme/` holds the DESIGN.md tokens as Dart constants plus one `ThemeData` (light only, `ThemeMode.light`, Heebo). `core/ui/widgets/` holds the cross-feature components (MemberAvatar, HeaderBlock + CategoryStripe, PrimaryButton/SecondaryButton with disabled state, AppBottomSheet, InlineMessage, Snackbar helper, CompactTopBar). The rule is "No color, font size or radius literal in feature `ui/`; only tokens from `core/ui/theme`", which parallels the AD-14 "no Hebrew literals" rule. `core/ui` imports no feature, so it stays consistent with AD-2. Add `core/ui/` to the structural seed. Change the Deferred line to: "Token *values* are owned by DESIGN.md; their code home is `core/ui/theme`."

### F2 (High). AD-16 route table misses Create group and contradicts two back behaviors

EXPERIENCE.md › Information Architecture and the Component Patterns rules require:

1. **Create group** is a full screen. AD-16's route list omits it. EXPERIENCE says "Create group is replaced by the new Group's page when it closes, so back from that page goes to the Group list". In stage 2, both "סיום" **and system back** open the new Group's page. So system back on this screen must not pop to `/`.
2. **Restore from an archived Group page:** "After a restore the same page stays open … Back now leads to the Group list." Under AD-16 the page is at `/archive/group/:id`, and back pops to `/archive`. That contradicts the UX.
3. **Exit sheet interception:** on Add and Edit expense, system back with unsaved input must open the Exit sheet instead of popping. AD-16 says "only go_router navigates" but sets no rule for intercepting back. Each screen will choose its own mechanism (`PopScope`, `WillPopScope`, or a router redirect).
4. **One screen, two routes:** the Group page is mounted at both `/group/:id` and `/archive/group/:id`. Nothing says read-only mode comes from the Group's archived state rather than from the route. If a feature keys off the route, a restored Group still renders read-only until the user navigates away.

- **Fix:** Extend AD-16 with these rules:
  - Add `/create`. Leaving Create group after save (either "סיום" or back in stage 2) uses `go('/group/:newId')`, which replaces the route. ✕ in stage 1 pops.
  - Restore runs `go('/group/:id')`, which rewrites the stack so back reaches `/`.
  - Read-only state is derived only from `group.isArchived` (via the AD-7 `isGroupMutable`), never from the route path.
  - Back interception for unsaved input uses `PopScope(canPop: !dirty)` plus the shared Exit sheet. Bottom sheets are modal overlays (`showModalBottomSheet` via `core/ui`), not routes, so system back dismisses the sheet first.
  - Edit, add and settings routes are not reachable for an archived Group: a route redirect guards them with `isGroupMutable`.

### F3 (Medium). Bottom-sheet contract has no shared rule

- **UX:** There are six sheets (Active-group, Exit, Delete, Archive, Remove-member, Rename). Sheets stack at most one level deep and are never centered dialogs. Dismissing by cancel, scrim or system back "changes nothing". The confirm button is on the start side. On the Active-group sheet, dismissal must revert the toggle to off. On the Rename sheet, validation errors show inside the sheet and the sheet stays open.
- **Spine:** silent.
- **Divergence:** some features will write before the sheet resolves, or treat a scrim tap differently from cancel. Rename might close on a `Failure` instead of showing it inline. The Active toggle might flip optimistically.
- **Fix:** Add one rule. All sheets go through `core/ui` `showAppSheet<T>()`, which returns `T?`, and `null` means dismissed. The write runs only after a confirm result. Toggles and other optimistic controls render from provider state, never local state, so a dismissal reverts them automatically. A sheet that edits data (Rename) calls the notifier itself, stays open on `Failure(messageKey)` and shows the message inline. No `showDialog`.

### F4 (Medium). Edge-to-edge insets, keyboard and snackbar placement have no shared scaffold

- **UX:** Android 15 draws edge-to-edge. On Add expense, the keypad and Save are pinned "inside the system insets, never covered". In the *Other* state, Save moves above the IME. On the Group page, the list's bottom padding equals the bar height plus the fade. The snackbar sits "above the button bar" and appears on the Group page **after** Edit expense has been popped (delete from the edit screen).
- **Spine:** minSdk 35 forces edge-to-edge, but there is no inset rule.
- **Divergence:** each screen handles `SafeArea`, `viewInsets` and `resizeToAvoidBottomInset` differently. Bottom bars overlap the gesture nav on some screens. A snackbar shown from a popped screen's `ScaffoldMessenger` is lost.
- **Fix:** Add a `core/ui` `AppScaffold` (header slot, body, bottom-bar slot) that owns system-bar insets and IME handling. Feature screens never use raw `Scaffold`/`SafeArea`. Use one root `scaffoldMessengerKey` on `MaterialApp.router`, and send snackbars through a `core/ui` helper so they survive a pop.

### F5 (Medium). Motion and accessibility floor are not wired at the app root

- **UX:** "Only two animations … Everything else is instant", which includes route transitions. Both animations are skipped when "Remove animations" is on. Font scale is supported up to 150%, and above that is "not committed". Touch targets are ≥48dp.
- **Spine:** go_router defaults to the Material slide/fade page transition, and AD-16 doesn't override it. There is no text-scale rule.
- **Divergence:** routes will get default transitions. The sheet and list-insert animations will each check `disableAnimations` differently or not at all. Without a cap, 200% font breaks the no-scroll Add expense layout that the spine is meant to hold.
- **Fix:** In `core/routing`, every route uses `NoTransitionPage`. In `main.dart`, clamp `TextScaler` to a maximum of 1.5 via a `MediaQuery` builder, so the UX floor becomes the ceiling the layouts are tested against. The two permitted animations read `MediaQuery.disableAnimationsOf(context)` through a `core/ui` helper. Add a widget-test convention: key screens are tested at text scale 1.0 and 1.5.

### F6 (Medium). AsyncValue loading and error states have no rule

- **UX:** "There are no loading states for remote data". The state tables define only Empty and Populated. Save "returns immediately" (under 300 ms), and any further Save tap does nothing.
- **Spine:** AD-5 says reads come from `.watch()` stream providers, so every screen gets `AsyncValue` with a loading first frame and a possible error. AD-15 covers write errors only.
- **Divergence:** one screen shows a spinner on the first frame, another an empty-state flash ("עדיין אין הוצאות" before the rows arrive), and another crashes on `AsyncError`. The double-tap guard on Save gets implemented sometimes in the widget and sometimes in the notifier.
- **Fix:** Add one rule. `AsyncLoading` renders the screen's chrome with an empty body: no spinner, and no empty-state text until the first data arrives. `AsyncError` is a bug path: show one generic `core/i18n` error key and log it in debug. Write notifiers expose an in-flight flag and ignore re-entry, which enforces "stores exactly once". The screen pops on `Success`.

### F7 (Medium). The bidi rules cover Member names only; Group names and amounts are unprotected

- **UX:** "Amounts and Latin names render as LTR runs inside RTL text", with `₪` before the number and thousands grouping (`₪1,250`, `₪8,400`). Sentences embed Group names too: "הקבוצה '{name}' תפסיק להיות הקבוצה הפעילה" and "להעביר את “{group}” לארכיון?". A Group name may be Latin or mixed.
- **Spine:** AD-14 isolates **Member** names only. AD-12's `formatShekel()` specifies decimals but not thousands grouping or LTR isolation.
- **Divergence:** Latin Group names reorder the Active-group warning. Some widgets wrap amounts in `Directionality(ltr)`, others insert LRI/PDI, others neither. Grouping commas appear on some screens and not others.
- **Fix:** Widen AD-14 so that **every user-supplied name (Group or Member)** enters a sentence via `isolateName()`. Make `formatShekel()` the single source for grouping (`,` every 3 digits) and wrap its output in LTR isolation (LRI…PDI) so callers never add direction themselves. Add both to the `core/money` and `core/text` unit tests.

### F8 (Medium). Member add order and avatar label rules are cross-feature but have no owner

- **UX:** Member colors `member-1..6` are assigned "in the order members were added", with member 7 reusing color 1. The payer picker keeps "the order the Members were added". The default Payer with no Expenses is "the earliest-added Member" (AD-7 lists this). The avatar label is the first word, or the full name when two Members share a first word. These rules are used by `groups`, `expenses` and `settle_up`.
- **Spine:** AD-8 bans ordering by clock for Expenses (AD-9) but defines no Member ordering key. Nothing says whether a Member's color index is stored or computed: after a Member is removed, do the others keep their colors or shift? No location is given for the first-word/disambiguation rule.
- **Divergence:** the Transfer card avatars and the payer picker could color the same Member differently. Different features might order Members by `createdAt` and by `rowid`.
- **Fix:** Add a per-Group monotonic `members.joinSeq` (same pattern as AD-9). Member order is always `joinSeq`. Decide whether the color index is `joinSeq`-based (stable after a removal; recommended so a person's color never changes) or index-based. Put `memberColorIndex()` and `avatarLabel(members)` in `core/text` (or `groups/domain`, exposed through public `app/`), and only those functions are used.

### F9 (Low). Screenshot contract needs the bundled font, and the golden test needs more cases

- **UX:** "Heebo … bundled with the app so it works offline". The screenshot contract requires that 6 Members (5 Transfers) fit on one screen at default font, and that for 7–10 Members the header stays fixed while only the list scrolls. A rendered screenshot with Hebrew-only, Latin-only and mixed names is part of the tests.
- **Spine:** the Stack has no font asset entry. The Summary golden test covers names only.
- **Fix:** Bundle Heebo as a `pubspec` asset (no `google_fonts` runtime fetch, NFR-8), and load it in golden tests (otherwise goldens render in the Ahem test font and prove nothing about bidi). Extend the golden cases: 6 Members with 5 Transfers at 360×780 (no scroll), 10 Members (fixed header, scrolling list), and the no-transfers state. The phone size stays an open question (EXPERIENCE Open Question 1).

### F10 (Low). Derived header numbers have no assigned home

- **UX:** the Trip total and category share stripe appear on the Group page (`expenses`) and the Summary (`settle_up`). The stripe "recomputes on every Expense change".
- **Spine:** AD-11 forbids widgets from computing Share, Balance or Transfer, but says nothing about the Trip total or category shares.
- **Fix:** Put `tripTotal()` and `categoryShares()` as pure functions in `expenses/domain`, which `settle_up` reuses. No widget sums amounts.

### F11 (Low). Restore versus Active-group state is ambiguous

- **UX:** after a restore, the page shows "exactly the state the Group had before archiving".
- **Spine:** AD-17 clears `activeGroupId` when a Group is archived, so a restored Group is no longer Active.
- **Fix:** State explicitly in AD-17 that a restore does not re-activate the Group. "State" in the UX means content (Members and Expenses). Confirm this with the UX owner.

## Checked and consistent

- Fixed Hebrew strings in one table: AD-14 `core/i18n` matches the NFR-6 table rule.
- Transfer sentence with no arrow, isolated names, hyphen after a prefix: AD-14 matches.
- Expense list order and default Payer by save order, not clock: AD-9 matches.
- Recorded time never changes on edit: AD-8 matches.
- Archived read-only enforced on writes: AD-7 `isGroupMutable` matches. See F2 for the UI side.
- Launch into the Active group with back to the list: AD-16 `go('/group/:id')` matches.
- FR-4 refusal and other expected rejections shown inline: AD-15 `Failure(messageKey)` matches.
- Offline with no remote loading: NFR-8 and the Deferred telemetry entry match.

## Memlog notes

- The memlog's layout decision lists `core/{money,ids,db,policy,i18n}`, but the spine seed has `ports`, `text` and `routing` and no `ids`. That is a minor drift. Make sure the ids helper (UUID v7) has a stated home.
- The memlog records that the user went ahead without fixing 10 medium UX findings (`review-rubric.md`). None of them is re-raised here unless it has an architectural seam.
