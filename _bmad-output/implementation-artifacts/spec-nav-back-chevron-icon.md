---
title: 'Back chevron icon in every nav line and the compact top bar'
type: 'feature'
created: '2026-11-05'
status: 'done'
baseline_commit: 'db58f80cca65ddf92f74c49884d231dedd5fda8d'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/CLAUDE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Back navigation is drawn as text glyphs: "→" (an arrow with a shaft) in "→ חזרה", "→ ארכיון", "→ הקבוצות שלי" and the compact top bar, and "☰" in the Group page's "☰ הקבוצות שלי". Motty wants a plain chevron instead. Heebo also has no "→" glyph, so goldens show a box.

**Approach:** Use one shared nav-label widget in `core/ui/widgets`: a right-pointing chevron `Icon` (›) on the start side, then the label text. Use it in every header nav line and the archive screen. The compact top bar back becomes the chevron icon alone. The MessageKey labels lose their glyph prefix.

**Decisions:**
- Direction right (›), drawn as an `Icon`, not a text glyph (Motty, 2026-11-05).
- It applies to every back affordance: Summary "חזרה", archived Group page "ארכיון", Archive screen "הקבוצות שלי", Group page "הקבוצות שלי" (replacing ☰) and the compact top bar back. ✕ close is unchanged.

## Boundaries & Constraints

**Always:** the chevron is `Icons.chevron_right` from the bundled MaterialIcons font (offline). It is sized from the label's text style and scales with text (`applyTextScaling: true`). It takes the label's color (white `onHeader` on the gradient, the Archive screen included — corrected by Motty, 2026-11-05). The 48dp hit area and the wrapping behaviour stay. An icon-only control has the semantics label "חזרה" from MessageKey. No color, size or radius literals in feature `ui/`. Docs change before code: DESIGN.md and EXPERIENCE.md nav mentions.

**Never:** no route or navigation behaviour change, no new dependency, no text glyph "›"/"<", no change to ✕ close or the badge.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Group page | unarchived | chevron + "הקבוצות שלי"; no ☰; tap → `/` | N/A |
| Archived page | archived | chevron + "ארכיון"; tap → `/archive` | N/A |
| Summary | any | chevron + "חזרה"; tap as before | N/A |
| Archive screen | open | chevron + "הקבוצות שלי"; tap → `/` | N/A |
| Compact top bar | Group settings back | chevron icon only, semantics "חזרה"; tap goes back | N/A |
| Text scale 1.5 | nav line | icon grows with text; nothing clipped | N/A |

</frozen-after-approval>

## Code Map

- `lib/core/i18n/message_key.dart` -- `summaryNav` → 'חזרה', `archiveNav` → 'ארכיון', `archiveBackNav` and `groupListNav` → 'הקבוצות שלי', `back` → 'חזרה' (now the semantics label of the icon-only control); update the doc comments. `test/core/i18n/i18n_test.dart` lines 93, 95, 199 plus rows for `groupListNav`/`back`.
- `lib/core/ui/widgets/nav_back_label.dart` (new) -- `NavBackLabel({label, style})`: `Row(mainAxisSize: min)` with the chevron `Icon` (size = `style.fontSize`, color = `style.color`, `applyTextScaling: true`), an `AppSpacing.s1` gap and a `Flexible` `Text` that wraps.
- `lib/core/ui/widgets/group_header.dart:58-76` -- the nav `Text` → `NavBackLabel(label: navLabel, style: headerSecondary.merge(_onHeader))`.
- `lib/features/groups/ui/archive_screen.dart:55-58` -- the `Text` → `NavBackLabel(... style: AppTextStyles.headerSecondary)`. The Archive header is on the gradient: set the color explicitly to `AppColors.onHeader` (it was inherited white).
- `lib/core/ui/widgets/compact_top_bar.dart:46-48,62-80` -- back renders the chevron `Icon` (screenTitle size, `onHeader`) wrapped in `Semantics(label: MessageKey.back.text, button: true)`; close keeps the ✕ text. Update the class doc ("→" back).
- Tests that find `MessageKey.back.text` (`active_archive_flow_test.dart:201`, `group_settings_flow_test.dart:101,146`) → `find.bySemanticsLabel(MessageKey.back.text)` or `find.byIcon(Icons.chevron_right)`. The `find.text(...Nav.text)` finders keep working.
- `test/features/settle_up/ui/goldens/*.png` -- regenerate with `--update-goldens`, since the Summary nav changes.
- `_bmad-output/planning-artifacts/ux-designs/ux-groupay-2026-10-26/DESIGN.md:323-324`, `EXPERIENCE.md:31,88,158` and any "→ חזרה"/"→ ארכיון"/"→ הקבוצות שלי" mention -- describe the chevron icon + label.

## Tasks & Acceptance

**Execution:**
- [x] DESIGN.md / EXPERIENCE.md -- the nav line is the chevron icon + label, and the compact bar back is the chevron icon.
- [x] `message_key.dart` + `i18n_test.dart` -- labels without glyphs.
- [x] `nav_back_label.dart` + `test/core/ui/widgets/nav_back_label_test.dart` -- icon is `chevron_right`, takes the style's color and size, the text wraps.
- [x] `group_header.dart`, `archive_screen.dart`, `compact_top_bar.dart` -- use it.
- [x] Flow tests -- update the back finders; assert no "☰" or "→" text remains on the Group page, Summary and Group settings; one test at text scale 1.5 with no overflow on the Group page nav.
- [x] Goldens regenerated and inspected.

**Acceptance Criteria:**
- Given the change, when `flutter analyze` and `flutter test --timeout 60s` run, then both pass with zero issues.
- Given emulator-5554, when the Organizer opens the Group page, Group settings, the Summary and Archive, then each back control shows a right-pointing chevron with no arrow shaft and no ☰.

## Implementation Notes

- Emulator AC passed (Motty, 2026-11-05): every back control shows the right-pointing chevron, no arrow shaft and no ☰; the Archive nav is white.

## Spec Change Log

## Review Triage Log

| # | Source | Finding | Verdict | Evidence | Route |
|---|--------|---------|---------|----------|-------|
| 1 | edge | Archive nav set to `AppColors.ink` on the teal gradient | high | `archive_screen.dart:34` passes the nav as `AppScaffold.header`, which paints the gradient; baseline text inherited white. Root cause was the frozen line "ink on the Archive screen"; Motty approved correcting it to `onHeader`. | patch |
| 2 | edge | Compact bar back `Semantics(excludeSemantics: true)` drops the tap action | medium | Excluding child semantics removes the GestureDetector's `onTap` action, so TalkBack double-tap does nothing. | patch |
| 3 | blind | Header nav line has no button semantics now that the glyph is gone | low | Bare `GestureDetector`; one `Semantics(button: true)` wrapper is direct. | patch |
| 4 | verify | Archive screen chevron not asserted by any test | medium | Pre-verified: only `find.text(archiveBackNav)` at `active_archive_flow_test.dart:307`. | patch |
| 5 | blind | `epics.md` still has "☰"/"→" nav labels | low | Lines ~178, ~205, ~324; doc edit. | patch |
| 6 | blind | Archive view mention sits in the EXPERIENCE.md "Group page header" row | low | Doc placement; direct move. | patch |
| 7 | blind | New doc-comment lines exceed 80 columns | low | `compact_top_bar.dart`, `group_header.dart`; rewrap. | patch |
| 8 | blind | Unrelated reformat in `summary_flow_test.dart` ~405 | low | Not part of this change; revert. | patch |
| 9 | blind+edge | `NavBackLabel`/`NavChevron` style contract (size/color) unchecked | low | Every caller passes a style with both set; fix adds asserts/branches. | reject |
| 10 | blind | Chevron centred against a wrapped label | low | "חזרה"/"ארכיון"/"הקבוצות שלי" fit one line at 1.5 on a 360dp phone; fix adds alignment logic. | reject |
| 11 | blind | No test that ✕ close stays a glyph; no Archive tap-to-`/` test; archived page chevron | low | ✕ path untouched; tap behaviour unchanged and covered elsewhere; archived page shares `GroupHeader` (chevron asserted on Group page and Summary). | reject |
| 12 | blind | Scale-1.5 nav test lives in `add_expense_flow_test.dart` | low | Placement only. | reject |
| 13 | blind | `loadHeebo()` also loads MaterialIcons under the old name | low | Naming; the doc comment says it. | reject |
| 14 | blind | No guard against "→"/"☰" returning in any MessageKey | low | Speculative; fix adds a new test. | reject |
| 15 | blind | Golden comment does not mention regeneration | low | Commit history records it. | reject |
| 16 | blind | Spec not in the diff; Verification has no results | false | The spec is excluded from the review diff by design and is updated at step 5. | reject |

## Verification

**Commands:**
- `flutter analyze` -- "No issues found!"
- `flutter test --timeout 60s` -- all pass

**Manual checks:**
- Open a regenerated Summary golden: the nav shows the chevron (MaterialIcons is bundled, so it should render rather than a box).
