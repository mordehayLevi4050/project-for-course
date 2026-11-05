---
title: 'Keep the 4×2 Category grid with two Payer rows when it really fits'
type: 'feature'
created: '2026-11-05'
status: 'ready-for-dev'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/CLAUDE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** On Add/Edit expense with 7–10 Members, the Categories switch to the two-page row even on screens where the 4×2 grid fits. `_TopMetrics` in `add_expense_screen.dart` is deliberately pessimistic: every line is counted at 1.4× and every label at two lines. Measured on the emulator (411×914dp, insets 50/24), the region is 464dp, the real grid layout needs ~422dp, and the estimate says 468dp, so it uses two pages.

**Approach:** Decide grid vs two-page from the real laid-out height instead of the estimate. When the Payer picker has two rows, shrink the Amount and the Category tiles a little.

**Decisions (Motty, 2026-11-05):**
- Use the real measurement and a light shrink, applied only when the Payer picker has two rows.
- On the Galaxy S25 (360×780dp) the grid still does not fit (~110dp short), so the two-page row stays there. The existing ~30dp safety-net scroll on S25 with 10 Members also stays, and is out of scope.

## Boundaries & Constraints

**Always:**
- The grid is chosen only when its real height fits the region. There is no visible flash or jump between layouts on first build or on rebuild.
- The decision is re-made on text scale, Member count, Edit meta line and screen size.
- Shrink values are new tokens in `core/ui/theme/tokens.dart` and documented in DESIGN.md before code. The shrink is light: Amount at most ~6sp smaller, tile at most ~8dp shorter, touch targets ≥48dp, labels never truncated.
- One Payer row looks exactly as today.

**Never:**
- No change to keypad, Save or Payer picker sizes.
- No scrolling added, and no change to the two-page row's behaviour.
- No change to the 1-row layout or to text scale >1.0 outcomes beyond what the real measurement implies.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Emulator, 10 Members | 1080×2400 dpr 2.625, insets 50/24dp, scale 1.0 | 4×2 grid, compact Amount and tiles, nothing scrolls | N/A |
| S25, 10 Members | 1080×2340 dpr 3, insets 32/24dp | two-page row (as today) | N/A |
| 6 Members | either screen | unchanged sizes; grid wherever it fits today | N/A |
| Edit, 10 Members | emulator, meta line shown | grid if it fits, otherwise two-page | N/A |
| Scale 1.5 | 2 Members, phone | two-page row (existing test) | N/A |
| Long names | 10 Members with 10-letter names wrapping to two lines | decision matches the real rendered height | N/A |

</frozen-after-approval>

## Code Map

- `lib/features/expenses/ui/add_expense_screen.dart:285-365,505-551` -- `_TopMetrics` and the `LayoutBuilder` that sets `twoPage`. Replace the pessimistic estimate with an exact one. For example, measure lines with `TextPainter` for the real styles, the real tile labels at the real tile width, and the real Member names under the avatars. Or use any other approach that measures the real layout in one pass without a flash. A test must prove the estimate equals the rendered grid region height within 1dp.
- `lib/features/expenses/ui/category_picker.dart:71-90` -- `_tileHeight` and the grid tile sizing. Takes a `compact` flag for the shorter tile.
- `lib/features/expenses/ui/payer_picker.dart` -- read only. Avatar 44dp plus a name of up to two lines (`AppTextStyles.label`).
- `lib/core/ui/theme/tokens.dart:130,192` -- `categoryTileHeight` 64 and `amountEntry` 46sp. Add the compact variants (e.g. `amountEntryCompact`, `categoryTileHeightCompact` / tighter tile padding).
- `test/features/expenses/ui/add_expense_flow_test.dart:563` -- the scale-1.5 two-page test (keep). Helpers `seed`, `openGroup`, `openAdd`, `usePhone` (360×780). Set insets via `tester.view.padding`/`viewPadding` (`FakeViewPadding`).
- `_bmad-output/planning-artifacts/ux-designs/ux-groupay-2026-10-26/DESIGN.md:300` (Add/edit composition) and `EXPERIENCE.md:161` (7–10 Members row) -- describe the compact sizes and that the two-page row applies only when the measured grid does not fit.

## Tasks & Acceptance

**Execution:**
- [ ] DESIGN.md / EXPERIENCE.md -- compact Amount/tile sizes for two Payer rows, and the measured fit rule.
- [ ] `tokens.dart` -- compact tokens.
- [ ] `add_expense_screen.dart`, `category_picker.dart` -- exact fit decision and compact sizes when two Payer rows.
- [ ] `test/features/expenses/ui/add_expense_flow_test.dart` (with Heebo) -- every matrix row; estimate-vs-render agreement for 2, 6, 10 Members × short/long names × scale 1.0/1.3 on both screen sizes; no `Scrollable` overscroll (`maxScrollExtent == 0`) whenever the grid is chosen.

**Acceptance Criteria:**
- Given the change, when `flutter analyze` and `flutter test --timeout 60s` run, then both pass with zero issues.
- Given emulator-5554 with a 10-Member Group, when the Organizer opens Add expense, then all eight Categories show in two rows with no page dots, and Save works with the default Payer in the same taps as before.

## Implementation Notes

## Spec Change Log

## Review Triage Log

## Verification

**Commands:**
- `flutter analyze` -- "No issues found!"
- `flutter test --timeout 60s` -- all pass
