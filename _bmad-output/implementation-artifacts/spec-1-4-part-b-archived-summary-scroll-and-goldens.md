---
title: 'Story 1.4 (part B): Archived Summary, 7–10 Member scroll and Summary goldens'
type: 'feature'
created: '2026-11-05'
status: 'done'
baseline_commit: '2bbe1c5f353630012d96abe8e0c85d777cf401d6'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-1-context.md'
  - '{project-root}/_bmad-output/implementation-artifacts/spec-1-4-settle-up-with-one-screenshot.md'
  - '{project-root}/CLAUDE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** An Archived group has no Summary (its route redirects to the read-only page), a 7–10 Member Summary scrolls header-title-cards as one list with no fade, and no golden test locks the Summary's RTL rendering.

**Approach:** Finish Story 1.4 (epics.md lines 846–886): the Archived Summary at `archive/group/:id/summary` with "סיכום" beside "↩ שחזור מהארכיון", a fixed title with only the cards scrolling and a 56dp bottom fade while more cards are below, and Summary goldens with bundled Heebo at text scale 1.0 and 1.5.

**Decisions:**
- The archive note on the Summary is "🗂 הקבוצה בארכיון ולכן לקריאה בלבד." (EXPERIENCE.md:106, a new MessageKey), pinned under the card area so it stays in view at 10 Members.
- Archived "→ חזרה" goes to `/archive/group/:id`; `group/:id/summary` of an Archived group redirects to `/archive/group/:id/summary`.
- Above text scale 1.0 the title, cards and note scroll together under the fixed header (the "may scroll" of T3.46); the fade rule is the same.
- OQ1 (Motty, 2026-11-05): accept. 5 Transfers with 10-letter Hebrew names fit with no scroll; with 10-letter Latin names and a decimal amount (₪8,333.3) the cards wrap to 3 lines and scroll with the fade. The golden pins both; no Transfer card token changes.
- Spec size ~1,800 tokens kept as one part (Motty).

## Boundaries & Constraints

**Always:** badge, note and nav target come from `isGroupMutable` on the loaded Group, never the route; the fade shows only while `extentAfter > 0`; "סיכום" on the archived page obeys `maySummarize` and the 40% rule; theme tokens only in feature `ui/`; `NoTransitionPage`; T3.8 still has `maxScrollExtent == 0`.

**Never:** no schema change, no new policy, no change to `settlement.dart`, no "⚙ ✎" chip or bottom bar on the Summary, no arrows, no emoji added to fixed messages.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Archived Summary | "Budapest" archived, Dana 300, Yossi | Same lines as unarchived + badge + note under cards; no chip (T1.26) | N/A |
| Archived bar | archived page, ≥2 Members | "↩ שחזור מהארכיון" (flex 2) + "סיכום" (flex 1) → `/archive/group/:id/summary` | N/A |
| Old route | archived, `/group/:id/summary` | Redirects to `/archive/group/:id/summary` | N/A |
| Back | archived Summary "→ חזרה" | Archived Group page | N/A |
| 10 Members | 9 Transfers, scale 1.0 | Header + title fixed; cards scroll; fade at bottom; fade gone at scroll end (T3.46) | N/A |
| ≤6 Members | T3.8 data | No scroll, no fade | N/A |
| Scale 1.5 | any | Nothing clipped or overflowed; body scrolls | N/A |

</frozen-after-approval>

## Code Map

- `lib/features/settle_up/ui/summary_screen.dart` -- restructure body: scale 1.0 → `Column(title, Expanded(card scroller + fade), note?)`; scale > 1.0 → one `ListView(title, cards, note?)`. Read-only via `isGroupMutable((isArchived: group.isArchived))` → `badgeLabel: MessageKey.archivedBadge.text`, nav `/archive/group/$id`. Keep `_Note`, `_stripeColor`.
- `lib/core/ui/widgets/bottom_fade.dart` (new) -- the 56dp `surfaceBase` gradient now private in `group_page.dart:168-187`; `group_page.dart`'s `_ListWithFade` uses it (always on); the Summary shows it from a `ScrollController`/`ScrollMetricsNotification` when `extentAfter > 0`.
- `lib/core/i18n/message_key.dart` -- add `archiveSummaryNote` beside `archiveNote` (line 98); add its row to the i18n unit test.
- `lib/features/expenses/ui/group_page.dart` -- `_ArchivedBar`: `Spacer` → `OutlinedButton` "סיכום" with the same `Opacity` pattern as `_AddBar` (lines 228–236), `go('/archive/group/$groupId/summary')`.
- `lib/shell/router.dart` -- `group/:id/summary` redirect → `/archive/group/$id/summary`; add `summary` child under `archive` › `group/:id` (no redirect). Update the doc comment.
- `test/features/settle_up/ui/summary_flow_test.dart` -- replace the test at line 330 with the redirect; reuse `seed`, `record`, `open`, `lines`, `appTest`.
- `test/support/heebo.dart` -- `loadHeebo()` for goldens. Text scale via `tester.platformDispatcher.textScaleFactorTestValue`; app clamps at 1.5 (`lib/shell/app.dart:33`).

## Tasks & Acceptance

**Execution:**
- [x] `lib/core/i18n/message_key.dart` + its test -- `archiveSummaryNote`.
- [x] `lib/core/ui/widgets/bottom_fade.dart`, `group_page.dart` -- extract the fade; archived bar "סיכום".
- [x] `lib/shell/router.dart` -- archived summary route and redirect.
- [x] `lib/features/settle_up/ui/summary_screen.dart` -- archived header/note, fixed title, scroller with conditional fade, scale > 1.0 layout.
- [x] `test/features/settle_up/ui/summary_flow_test.dart` -- every matrix row: archived lines/badge/note/no chip, bar button enabled/40%, redirect, back, 10-Member fixed title + fade on then off at scroll end, T3.8 no fade, scale 1.5 no overflow exception.
- [x] `test/features/settle_up/ui/summary_golden_test.dart` + `goldens/*.png` -- phone 1080×2340 dpr 3, Heebo, scale 1.0 and 1.5: Hebrew-only (T3.6), Latin-only, mixed "Dan"/"דנה"/"Zoe Lee" (TX.5), 5 long-name Transfers in Hebrew (asserts no scroll) and in Latin at ₪8,333.3 each (scrolls, fade shown), archived, 10 Members.

**Acceptance Criteria:**
- Given the finished part, when `flutter analyze` and `flutter test --timeout 60s` run, then both pass with zero issues.
- Given emulator-5554 with an Archived group, when the Organizer opens it from Archive and taps "סיכום", then the Summary shows the badge and the note under the cards, and "→ חזרה" returns to the archived page.

## Implementation Notes

- `archiveSummaryNote` has the same text as the internal `groupArchived` failure key; kept separate because one is UI copy and the other a repository refusal.
- The archive note strip moved to `core/ui/widgets/archive_note.dart` (`ArchiveNote`), used by the archived Group page and the archived Summary, so the Summary does not repeat its tokens.
- `_FadingScroll` (private to `summary_screen.dart`) listens to `ScrollMetricsNotification` (fires after the first layout and on every metrics change) and `ScrollNotification` at depth 0, and shows `BottomFade` while `extentAfter > 0`. The Group page keeps its always-on fade via `BottomFade.positioned()`.
- "Above text scale 1.0" is detected as `MediaQuery.textScalerOf(context).scale(16) > 16.01`.
- Found and fixed a part A bug: `CategoryStripe` segments were 0dp tall (a `Row` in a fixed-height `SizedBox` without `CrossAxisAlignment.stretch`, and `DecoratedBox` has no height of its own), so the stripe was invisible on the Group page and the Summary. One line in `category_stripe.dart`; T3.43 now asserts the segment height is `AppSizes.stripeHeight`.
- OQ1 confirmed by golden: 5 Transfers of ₪8,333.3 with 10-grapheme Hebrew two-word names fit (`maxScrollExtent == 0`); with 10-letter Latin names the cards wrap to 3 lines, breaking inside the word (e.g. "Bernadett|e"), and scroll with the fade.
- Heebo has no glyph for "→" or the emoji, so the goldens show a box there; on the device the system fallback font draws them.

- Emulator AC passed (Motty, 2026-11-05): the archived Summary showed the badge and the note under the cards, "→ חזרה" returned to the archived page, the 7–10 Member scroll and fade and the category stripe looked right.

## Spec Change Log

## Review Triage Log

| # | Source | Finding | Verdict | Evidence | Route |
|---|--------|---------|---------|----------|-------|
| 1 | blind | Archive note lands at the screen bottom, far below few cards | medium | Default-font branch puts the cards `ListView` in `Expanded`, so it always fills the body; DESIGN.md:341 says "under the Transfer cards". | patch |
| 2 | verify+blind | Pinned note at 10 Members, scale 1.0, archived is untested | medium | Pre-verified: T1.26 has 2 Members, the 1.5 test runs the other branch, T3.46 has no note. | patch |
| 3 | blind | T3.46 comment claims cards never scroll over the title; only `pixels > 0` checked | low | Test-only; adding one rect assertion is direct. | patch |
| 4 | blind | `SummaryScreen` doc ties scrolling to 7–10 Members | low | OQ1 decision: long Latin names scroll at 6 Members; doc correction. | patch |
| 5 | blind | `_scaleProbe = 16` is a font-size literal in feature `ui/` | low | CLAUDE.md forbids font-size literals in feature `ui/`; swap for a token. | patch |
| 6 | edge | Golden `seed` ignores `expenses.add`/`archive` results | low | `summary_golden_test.dart:62-71` awaits without checking; a Failure records a wrong baseline. | patch |
| 7 | blind | Goldens platform-dependent and lack glyphs, undocumented in the test | low | No CI (`.github` absent); a doc line in the test file is direct. | patch |
| 8 | blind | New core widgets / stripe have no `test/core/ui/widgets` tests | low | CLAUDE.md requires unit tests for policy/text/money only; stripe height is asserted in T3.43; fix adds new test files. | reject |
| 9 | blind | 40%-disabled "סיכום" block duplicated in `_AddBar` and `_ArchivedBar` | low | Both use `AppOpacity.disabled`; extraction adds a widget. | reject |
| 10 | blind+edge | `/archive/group/:id/summary` of an unarchived Group not redirected | low | Reachable only by a typed route; read-only state comes from `isGroupMutable`, so the screen is correct and "→ חזרה" goes to `/group/:id`. | reject |
| 11 | edge | Tapping archived "סיכום" during an in-flight Restore is pulled to `/group/:id` | low | Restore is one local transaction (ms); the user lands on the restored page, the expected restore outcome. | reject |
| 12 | edge | Fixed title + note may overflow in landscape at scale 1.0 | maybe-false | No orientation lock (`AndroidManifest.xml`), but the fixed header is pre-existing on every page; would need a landscape widget test to settle. | defer |
| 13 | edge | Body renders in non-archived layout if settlement arrives before `groupProvider` | low | Local streams; at most one frame, header hidden in that frame too. | reject |
| 14 | blind | `extentAfter > 0` lacks an epsilon, fade may stay at scroll end | false | Clamping physics sets `pixels == maxScrollExtent` at the end; T3.46 asserts the fade is gone at the end and passes at dpr 3. | reject |
| 15 | blind | Golden `seed` duplicates the flow test's seeding | low | Test-only duplication; extraction into `test/support` is more than a direct fix. | reject |

## Verification

**Commands:**
- `flutter analyze` -- "No issues found!"
- `flutter test --timeout 60s` -- all pass (goldens created with `--update-goldens`, then pass without it)

**Manual checks:**
- Open each golden PNG: RTL word order, no arrow, nothing clipped at 1.5.
