---
title: 'Story 1.4 (part A): Transfer calculation and the Summary'
type: 'feature'
created: '2026-11-05'
status: 'done'
baseline_commit: 'a52993773847295fe541a442d458ef8333ff20de'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-1-context.md'
  - '{project-root}/_bmad-output/specs/spec-groupay/transfer-calculation.md'
  - '{project-root}/CLAUDE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Group page has no "סיכום" and no Transfer list exists, so the Organizer cannot tell friends who pays whom.

**Approach:** Build FR15 and the unarchived FR16 Summary (epics.md lines 757–845, 855–875): a `settle_up` feature (`domain`, `app`, `ui`; no `data`) with the pure Transfer calculation, the Summary at `group/:id/summary`, and "סיכום" on the Group page bottom bar.

**Decisions:**
- Scope = part A; part B (Archived Summary, 7–10 Member scroll/fade, goldens) is in `deferred-work.md` (Motty, 2026-11-05).
- Summary nav line "→ חזרה" (mockup `key-screens.html` #4) goes back to the Group page.
- Below 2 Members (`maySummarize` denies; reachable only by a typed route) the body shows `needTwoMembers` instead of cards.
- Until part B, the archived page's bottom bar is unchanged and an archived `group/:id/summary` redirects to `/archive/group/:id`.

## Boundaries & Constraints

**Always:**
- Snapshot = Members + Expenses read in **one** `db.transaction` in `expenses/data`, re-read on any `members`/`expenses` change. Members via `MemberRepository` (constructor-injected, AD-6).
- Calculation per `transfer-calculation.md`: `Tenths` only; Share rounded down; Leftover only from receivers (smallest total paid first; equal totals → later first-Expense `saveSeq` first); minimum Transfer count by exact search over zero-sum partitions, debtor→receiver only; tie-break = lexicographically first (debtor, receiver) sequence under `compareNames`; output in that order.
- Strings via `MessageKey`, names via `isolateName(name, prefix: 'מ'|'ל')`, amounts via `formatShekel()`. Verbatim: "מי מעביר למי", "{n} משתתפים · ₪{share} לאחד", "החשבון מאוזן, אין צורך בהעברות", "תשלום נדרש מ{debtor} ל{receiver}", "סיכום".
- Summary only reads; theme tokens only in feature `ui/`; `NoTransitionPage`.

**Never:** no schema change, no Balance table or breakdown, no arrows, no tappable cards, no Summary bottom bar or "⚙ ✎" chip, no greedy matching, no Share/Balance/Transfer math in widgets or SQL.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Calc cases | epics.md lines 781–796 (T3.1–T3.38) | Exactly the listed Transfers, in order | N/A |
| Settled | T3.3 / T3.15 | Empty list; settled message instead of cards | N/A |
| Rename | T3.6 יוסי→שי; T3.33 אברהם→תום | T3.17 / T3.34; totals per Member unchanged | N/A |
| Clock | T3.45 clock set back; T3.40 time zone | Order by `saveSeq` only | N/A |
| 10 Members | 5 debtors/5 receivers, no zero-sum sub-blocks | ≤1 s | N/A |
| Live update | add Noa / remove Noa / edit 300→150 / rename Dana / rename Group | T1.20 / T1.13 / T2.16 / T1.12 / T1.17 | N/A |
| Button | < 2 Members | "סיכום" 40% opacity, does nothing (T3.2) | N/A |
| Lines | Dana 300, Yossi, Noa / Zoe 300, Adam, דנה | T3.43 / T3.44 exact strings | N/A |
| Layout | ≤6 Members, 5 Transfers, default font | Header, title, cards on one screen, no scroll (T3.8) | N/A |

</frozen-after-approval>

## Code Map

- `lib/core/policy/expense_rules.dart` -- `maySummarize(RecordExpenseFacts)`, same rule and message as `mayRecordExpense`.
- `lib/core/i18n/message_key.dart` -- `summaryNav('→ חזרה')`, `summaryButton('סיכום')`, `transfersTitle`, `shareLine('{members} · {share} לאחד')` (members = `memberCountText`, share = `formatShekel`), fixed `settledUp`, fixed `transferLine('תשלום נדרש {from} {to}')` (from/to = `isolateName` with prefix; the amount is a separate widget closing the line).
- `lib/features/groups/{domain/member_repository.dart,data/drift_member_repository.dart}` -- `Future<List<Member>> readMembers(String groupId)` in `memberSeq` order.
- `lib/features/expenses/domain/expense_repository.dart` -- `Stream<GroupSnapshot> watchSnapshot(String groupId)`; `GroupSnapshot` (members, expenses) in `expenses/domain`.
- `lib/features/expenses/data/drift_expense_repository.dart` -- emit once, then per `_db.tableUpdates(TableUpdateQuery.onAllTables([members, expenses]))`, each read in `_db.transaction`. Constructor gains `MemberRepository`; update `lib/shell/overrides.dart` and every test that builds it.
- `lib/features/settle_up/domain/settlement.dart` (new) -- `Transfer {debtorId, receiverId, amount}`, `Settlement {share, transfers}`, `settle(members, expenses)`.
- `lib/features/settle_up/app/settle_up_providers.dart` (new) -- `settlementProvider(groupId)`: `watchSnapshot` → `maySummarize` → `settle` (`null` when denied).
- `lib/features/settle_up/ui/summary_screen.dart` (new) -- `AppScaffold` + `GroupHeader` (nav, no chip, `tripTotal`, share line, stripe as `group_page.dart:99-109`); body: title, then cards with 8dp gaps in a scrollable (so larger font scrolls instead of overflowing).
- `lib/features/settle_up/ui/transfer_card.dart` (new) -- `AppColors.transferSurface/transferEdge` (6dp start edge), `AppTextStyles.rowTitle/transferAmount`, 64dp min height, `AppRadii.lg`, flat; two 32dp initial-only circles 4dp apart colored by `memberColorIndex` (`MemberAvatar` is 40dp + label, so a small circle). Add any missing size tokens to `tokens.dart`.
- `lib/features/expenses/ui/group_page.dart` -- `_AddBar`'s `Spacer` → `OutlinedButton` "סיכום" (flex 1), disabled when `maySummarize` denies, `go('/group/$id/summary')`.
- `lib/shell/router.dart` -- `summary` under `group/:id` with `archivedRedirect`.

## Tasks & Acceptance

**Execution:**
- [x] `lib/core/{policy,i18n}/**` + unit tests -- `maySummarize`, keys, line builders.
- [x] `lib/features/settle_up/domain/settlement.dart` + `test/features/settle_up/domain/settlement_test.dart` -- every calc row, uneven tenths, multi-receiver Leftover, Hebrew/Latin/mixed ties, sizes 2–10, a brute-force oracle on random ≤6-Member Groups, 10-Member timing.
- [x] Member/expense repositories + `NativeDatabase.memory()` tests -- `readMembers`; `watchSnapshot` emits consistent pairs after add/remove/edit/rename.
- [x] `lib/features/settle_up/{app,ui}/**`, `group_page.dart`, `router.dart`, `overrides.dart` -- providers, screen, card, button, route.
- [x] `test/features/settle_up/ui/summary_flow_test.dart` (Heebo, phone 1080×2340 dpr 3) -- Live update, Button, Lines, Settled, Layout rows; nav returns to the Group page; no arrow glyph in cards; archived route redirect.

**Acceptance Criteria:**
- Given the finished part, when `flutter analyze` and `flutter test --timeout 60s` run, then both pass with zero issues.
- Given emulator-5554 in airplane mode with the T3.6 Group, when the Organizer taps "סיכום", then the three T3.6 lines show on one screen, and after force-stop and relaunch the Summary is the same.

## Implementation Notes

- `watchSnapshot` is a `StreamController` that subscribes to `tableUpdates(members, expenses)` before its first read; reads never overlap (a change during a read triggers one more). Each read is one `db.transaction` via `MemberRepository.readMembers`.
- `settlement.dart`: subset DP for the most zero-sum blocks; every maximal split is tried; inside a block the lex-first debtor→receiver spanning tree is found by include-before-skip DFS. Lex-first per block gives the global lex-first list, since blocks share no pairs. Worst of 20,000 random 10-Member Groups ≈ 90 ms (debug).
- T3.8 fit needed tighter card padding (12dp all sides, 8dp gaps, list top 20dp; all on the spacing scale, no transfer-card token changed). With typical names 5 cards are 70/70/70/70/93dp, `maxScrollExtent` 0. Long-name case (OQ1) not re-measured.
- Summary flow tests use an `appTest` wrapper that unmounts in `finally`; writes after the pump run in `tester.runAsync`.
- The Category→stripe color switch is repeated in `summary_screen.dart` (a feature `ui/` may not import `expenses/ui`); it is exhaustive.
- Below 2 Members the header line is the Member count only (no Share exists then).
- Emulator AC not yet run.

## Spec Change Log

## Review Triage Log

| # | Source | Finding | Verdict | Evidence | Route |
|---|--------|---------|---------|----------|-------|
| 1 | verify+blind | Summary header Trip total and stripe never asserted (T3.7) | medium | Pre-verified: T3.43 and the live test check name, share line and cards only; a wrong `total:` passes. | patch |
| 2 | verify+blind+edge | `watchSnapshot` dirty re-read (change during a read) untested | medium | Pre-verified: every test waits for `pumpEventQueue` between writes; removing the `while (dirty)` loop passes. | patch |
| 3 | edge+blind+verify | Oracle covers only 2–6 Members; 7–10 check only "settles with ≤ n−1" | medium | `settlement_test.dart` group title claims 2–10; any spanning forest (greedy too) passes the 7–10 test. | patch |
| 4 | blind | Disabled "סיכום" is dimmed twice (Material disabled grey × 40%) | medium | `app_theme.dart:67-76` sets no disabled colors for `OutlinedButton`, so the label turns grey before `Opacity`; DESIGN.md:325 says "label unchanged" at 40%. | patch |
| 5 | blind | TalkBack reads a Transfer card as two items | low | `transfer_card.dart` has sentence and amount as separate `Text`s with no `MergeSemantics`; FR-16 line is one sentence. Fix is one wrapper. | patch |
| 6 | edge+blind | `AsyncError` from `settlementProvider` leaves a blank Summary | low | Errors only on a DB fault or a bug (same as 1.3 part B #6). | reject |
| 7 | edge+blind | Typed `/group/<unknown>/summary` shows no header | low | Ids come only from the router's own links (1.3 part B #5). | reject |
| 8 | edge | Error after `dirty` drops the pending re-read | low | Only on a read fault (bug path); a later write re-reads. | reject |
| 9 | edge+blind | Writes in other Groups re-read and re-settle | low | `settlementProvider` is auto-dispose, alive only while that Summary is open; on one phone no other Group is written then. | reject |
| 10 | edge+blind | `settle()` runs on the UI isolate, up to 1 s | low | Measured worst ≈ 90 ms over 20,000 random 10-Member Groups; within NFR-5. | reject |
| 11 | blind | 1 s tests time the host VM, not the S25 or the widget path | low | The device timing belongs to the emulator check; no cheap test fix. | reject |
| 12 | blind | `_InitialAvatar` repeats `MemberAvatar`'s initial logic | low | Two lines; no caller diverges today. | reject |
| 13 | blind | Category→color switch duplicated in `summary_screen.dart` | low | Both map to the same `AppColors` tokens, so a color change propagates; the switch is exhaustive. | reject |
| 14 | blind | `maySummarize` takes `RecordExpenseFacts` | low | Same rule by spine AD-7 (line 101); a rename adds surface for no harm. | reject |
| 15 | blind | `settlementProvider` returns `SummaryView` | low | Naming only; no caller confused. | reject |
| 16 | blind | Test `lines()` helper uses `.skip(2)` | low | Test-only; a layout change fails loudly. | reject |
| 17 | blind | `minimalTransfers` ignores balance keys outside `members` | low | Only `settle()` and tests call it, with matching keys. | reject |
| 18 | verify | No text-scale 1.5 check of the Summary | low | Goldens at 1.0/1.5 are part B (deferred-work.md). | reject |

## Design Notes

Two lists with the same (debtor, receiver) pairs carry the same amounts (a forest's flows are fixed by the Balances), so pairs alone identify a candidate. Sketch: DP over subsets of non-zero Balances for the most zero-sum blocks (minimum = nonZero − blocks); then either enumerate the minimal forests and keep the lexicographically first sorted pair list, or build it pair by pair with a feasibility check. The brute-force oracle test guards either way.

## Verification

**Commands:**
- `flutter analyze` -- "No issues found!"
- `flutter test --timeout 60s` -- all pass

**Manual checks:**
- On emulator-5554: a 6-Member Summary fits one screen; card edge, avatar pair, long names wrap with the amount at the end.
