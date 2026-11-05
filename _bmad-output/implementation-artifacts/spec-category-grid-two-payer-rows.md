---
title: 'Keep the 4×2 Category grid with two Payer rows when it really fits'
type: 'feature'
created: '2026-11-05'
status: 'done'
route: 'dispatch'
baseline_commit: 'f57e26d96754bcf3685b8783ff1eb3c051e99ddd'
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
- [x] DESIGN.md / EXPERIENCE.md -- compact Amount/tile sizes for two Payer rows, and the measured fit rule.
- [x] `tokens.dart` -- compact tokens.
- [x] `add_expense_screen.dart`, `category_picker.dart` -- exact fit decision and compact sizes when two Payer rows.
- [x] `test/features/expenses/ui/add_expense_flow_test.dart` (with Heebo) -- every matrix row; estimate-vs-render agreement for 2, 6, 10 Members × short/long names × scale 1.0/1.3 on both screen sizes; no `Scrollable` overscroll (`maxScrollExtent == 0`) whenever the grid is chosen.

**Acceptance Criteria:**
- Given the change, when `flutter analyze` and `flutter test --timeout 60s` run, then both pass with zero issues.
- Given emulator-5554 with a 10-Member Group, when the Organizer opens Add expense, then all eight Categories show in two rows with no page dots, and Save works with the default Payer in the same taps as before.

## Implementation Notes

- Exact fit: `ExpenseRegionMetrics.gridRegionHeight()` in `add_expense_screen.dart` measures every line with `core/ui/text_height.dart` (`TextPainter` with the same style merge, scaler, bold-text, locale and height behavior as `Text`), the payer labels at 48dp, and calls `categoryGridHeight()` from `category_picker.dart`. The grid now renders each row at exactly that height (replacing `IntrinsicHeight`); labels are measured regular and bold so selecting a tile never changes the size.
- Compact sizes apply only when two Payer rows and the grid is chosen; the two-page row keeps the full sizes. Tokens: `amountEntryCompact` 40sp, `categoryTileHeightCompact` 56dp, `categoryTilePaddingCompact` 0 (vertical).
- Test numbers (Heebo, no emoji font): 6 Members fit the emulator (339 vs 464dp); on S25 with 32/24 insets 6 Members miss by 4dp (352 vs 348), so they use the two-page row there, as the old estimate also did.

## Spec Change Log

## Review Triage Log

Iteration 0 (blind-hunter BH, edge-case-hunter ECH, verification-gap VG):

| # | Finding | Verdict | Evidence | Route |
|---|---------|---------|----------|-------|
| VG1 | `textHeight()` bold-text branch never exercised by a test | medium | Pre-verified gap: no test sets `FakeAccessibilityFeatures(boldText: true)`; the branch drives every fit measurement. | patch (test) |
| VG2 | Two-page `_tileHeight` does not use `textHeight()`/boldText | low | Pre-existing code; spec forbids changing the two-page row; emoji height is weight-independent, labels already measured at w800. | reject |
| VG3+BH9b | Edit test and 6-Members S25 test accept either layout (`if (!twoPage())`, `twoPage() == !fits`) | low | Assertions only check themselves; outcomes are deterministic in the test env (Edit emulator grid; S25 6 Members two-page per Implementation Notes). Direct correction. | patch (test) |
| BH1/ECH4/ECH5 | Fixed `SizedBox` rows instead of `IntrinsicHeight` can clip if measurement is short (device emoji font) | false | `textHeight()` uses the same `TextPainter` engine and font fallback as `Text`, so the device emoji font is measured too; tile = padding+border+emoji+label exactly as summed; estimate==render asserted across the matrix and on selection. | reject |
| BH2 | Strict `>` vs 1dp test tolerance; only grid rows are rounded | false | Render and estimate sum the same values from the same functions (rows rounded in both); `maxScrollExtent == 0` passes in every grid case. | reject |
| BH3/ECH3 | Fit depends on live buffer/error text, layout may flip while typing | false | Amount and message are `maxLines: 1` in a single font (Heebo covers digits, ₪ and Hebrew), so their line height is content-independent; the slot is reserved so render height never changes either. | reject |
| BH4 | Picker re-measures rows at its own width, twice per build | low | Widths agree today (test within 1dp); fix adds public surface (pass heights in). | reject |
| BH5 | Payer picker height duplicated in `add_expense_screen.dart` | low | Duplication is guarded by estimate-vs-render tests at 2/6/10 Members × short/long names; moving it adds public surface to a read-only file. | reject |
| BH6/ECH1 | `textHeight` ignores softWrap/overflow/strutStyle; `clamp` returns num; no unit test | false | No ancestor `DefaultTextStyle` sets softWrap/overflow/strut (only `app_scaffold.dart:43` merges a color); `double.clamp` returns `double` (analyze clean); indirectly tested via the matrix. | reject |
| BH7 | Matrix stops at scale 1.3, no 1.5; no 360dp screen | low | 1.5 is the app's max scale and untested for estimate==render; adding it to the loop is a direct change. The S25 case is 360dp wide, so that part is false. | patch (test) |
| BH8 | Edit covered by one case only | low | Meta line path uses the same measurement already covered; extending the matrix is more than a direct fix. | reject |
| BH9a | Constant-only assertions (≤6sp, ≤8dp) | false | They intentionally pin the spec's shrink limits on the tokens. | reject |
| BH10 | DESIGN.md says one payer row fits 360×780, but 6 Members on S25 use two-page (4dp short in tests) | maybe-false (medium if true) | Pre-existing (old estimate same); test env has no emoji font so the real-device margin is unknown. | defer |
| BH11 | Compact tile padding 0 lets label touch the border at larger scales | low | Cosmetic; at 1.0 the 56dp min leaves space around centered content; flush only when a row grows at large scale. | reject |
| ECH2 | Empty members on first frame → grid then flip | false | Add/Edit is nested under `group/:id`, whose `GroupPage` watches `membersProvider`, so the value is already loaded when the screen opens. | reject |
| ECH6 | One Payer row rows now sized for the bold label and rounded up | low | At most a sub-dp/one-line difference at large scale; reverting reintroduces the jump on selection the intent forbids. | reject |

## Verification

**Commands:**
- `flutter analyze` -- "No issues found!"
- `flutter test --timeout 60s` -- all pass
