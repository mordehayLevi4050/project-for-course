# Reconcile: ears-requirements.md vs PRD (2026-10-29)

Sources: `ears-requirements.md` and `prd.md` (prd-groupay-2026-10-26), both updated 2026-10-29.

## Summary

- FR coverage: 16/16 FRs have EARS requirements and tests. NFR-5/6/8/9: all 4 have a cross-cutting statement and tests, but NFR-5's 1-second Summary limit is missing from the requirement text (see G1).
- EARS requirements without a PRD basis: none blocking (1 low note, G6).
- Values: 10 members, 10/20 characters, 4/5 taps, ₪1,000,000 (inclusive, T2.3e), 2 s / 300 ms / 1 s all match.
- Hebrew message table: the 16 rows are identical in both docs. Checked with a diff; the only difference is the PRD's "(FR-16)" annotation.
- Rules: the save-order tie-break, the Leftover step, the "תשלום נדרש מ{debtor} ל{receiver} ₪N" wording and the hyphen rule match word for word. The hyphen example is wrong in both docs (G2).
- Numeric tests recomputed against the FR-15 rules: 33 tests with numbers. 33 match. None are wrong.
- Leftover paid/lock/payment/settled references: none active. The remaining ones are only out-of-scope lists, removed-ID notes and deferral text (G7).

Totals: 0 high, 2 medium, 5 low.

## Findings

### G1 (Medium): NFR-5 Summary 1-second limit has no EARS requirement statement
PRD NFR-5 requires: "the Summary of a 10-Member Group appears within 1 second". The EARS cross-cutting requirement (line 258) states only the 2 s cold launch and the 300 ms save. T3.46 tests the 1 s limit, but no requirement states it. Fix: add "and display the summary of a 10-member group within 1 second" to the NFR-5 line.

### G2 (Medium): The hyphen example contradicts the hyphen rule, in both docs
The rule says a hyphen follows the prefix only when the name does not start with a Hebrew letter. The example "מ-Dan ל-דנה" puts a hyphen before דנה, which is Hebrew. The correct example is "מ-Dan לדנה". The error appears in PRD FR-16 (line 234) and in EARS Story 3 (line 199). T3.44 applies the rule correctly ("מדנה ל-Zoe"), so the tests are fine.

### G3 (Low): The PRD states the changed-Payer tap budget two ways
FR-10 says "at most 5 taps from launch (one more for each swipe needed to reach the Member)". This reads as if the budget grows with swipes. NFR-1 says at most 5 taps, with each swipe counted as a tap. EARS (line 147) follows NFR-1. Fix FR-10's parenthetical so the two agree.

### G4 (Low): The order of displayed Transfer lines is unspecified; T3.44 lists lines out of sort order
The tie-break sorts candidate lists by debtor then receiver, but neither doc says the Summary displays the lines in that order. T3.20 lists יוסי before Adam, which follows the sort (Hebrew sorts before Latin). T3.44 lists Adam before דנה, which does not. Fix: either state the display order (debtor, then receiver) and reorder T3.44, or say that line order is not tested.

### G5 (Low): Coverage gaps in the tests
- NFR-9 all-or-nothing (interrupted) save has no test. TX.2 covers persistence only.
- NFR-6 / FR-16 call for a "mixed" name (a Latin and Hebrew mix inside one name) in the screenshot test. T3.44 and TX.5 mix names across the group, but no single name mixes scripts.
- FR-10 says a double tap on *Save* creates nothing for an edit too (FR-13). T2.21 covers only a new Expense.
- In the EARS requirement text, FR-13 ("Summary reflects the change") and FR-3 ("new name appears on the Summary") are missing; tests T2.16 and T3.17/T3.34 cover them.

### G6 (Low): The EARS rule for whitespace-only Member names is only implied by the PRD
EARS line 75 rejects "empty or whitespace-only" Member names. PRD FR-2 says only "An empty name is rejected". The rule follows from trimming, but FR-2 should say it outright, as FR-1 does for Group names.

### G7 (Info): Leftover deferral vocabulary
The only remaining mentions are in out-of-scope lists (EARS line 36; PRD §4.4, §6.2, §7), in the removed-ID notes (EARS lines 119 and 250) and in multi-user "lock on recipient confirmation" (§6.2). None of them is an active requirement. A minor wording risk: the PRD Glossary defines Expense as "one payment" (line 83), and NFR-14's "when a Group may be changed" is a lock-era phrase. Both are acceptable.

## Numeric test recomputation (FR-15)

| Test | Recomputed | Result |
|---|---|---|
| T1.13 | share 150; Yossi→Dana 150 | OK |
| T1.20 | share 100; 2 × 100 | OK |
| T2.11 / T2.12 / T2.14 | −783 / −87 / 387.4 | OK |
| T2.3d / T2.3e | 1,000,001 rejected / 1,000,000 accepted | OK |
| T2.4 | 87.45 → 87.4 | OK |
| T2.16 | share 50; 2 × 50 | OK |
| T2.20 | Add(1), Dana(2), Fuel(3), Save(4) = 4 ≤ 5; next default Dana | OK |
| T2.25 | D, C, B, A by save order | OK |
| T3.1 / T3.3 | 2 × 100 / settled | OK |
| T3.4 | share 33.3, leftover 0.1 off Dana; 2 × 33.3 | OK |
| T3.5 | 43.7 | OK |
| T3.6 | share 150; tree (יוסי,דנה)(יוסי,מוטי)(נועה,מוטי) beats (יוסי,מוטי)… | OK |
| T3.15 | share 33.3; Dana +0.1 → 0; settled | OK |
| T3.16 | share 100.2; Dana +0.3 → 0.2 | OK |
| T3.17 | נועה<שי; (נועה,דנה 50)(נועה,מוטי 100)(שי,מוטי 150) | OK |
| T3.18 | share 100.5; 2 × 0.5 | OK |
| T3.19 | share 0.7, leftover 0.2 off Dana; 3 × 0.7 | OK |
| T3.20 | Hebrew<Latin: יוסי first; matches | OK |
| T3.31 | share 50; גיל 50→49.9; the (בני,אבי)(בני,גיל)(דוד,אבי) list wins | OK |
| T3.32 | 26.7 / 6.6 | OK |
| T3.33 / T3.39 / T3.40 | 16.7 / 16.6 (יצחק saved later) | OK |
| T3.34 | יצחק<תום ordering; amounts unchanged | OK |
| T3.35 | share 10, leftover 0.3: בני 0.1→0, אבי 20.2→20; 2 × 10 | OK |
| T3.37 | גיל<ג'ני (geresh after letters) | OK |
| T3.38 | דניאל<דני2 (digits after letters); the (דניאל,מוטי)(דניאל,נועה)… list wins | OK |
| T3.43 | "תשלום נדרש מיוסי לדנה ₪100", "…מנועה לדנה ₪100" | OK |
| T3.44 | "מ-Adam ל-Zoe ₪100", "מדנה ל-Zoe ₪100" (amounts correct; see G4 on order) | OK |
| T3.45 | יצחק seq 1, אברהם seq 2 → אברהם absorbs: 16.6 / יצחק 16.7 | OK |
| T3.46 | 1 s limit matches NFR-5 | OK |
