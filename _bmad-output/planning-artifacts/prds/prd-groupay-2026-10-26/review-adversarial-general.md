# Adversarial Review: PRD GrouPay (revision 2026-10-29)

Reviewed: `prd.md` and `addendum.md` (PRD dated 2026-10-29). `ears-requirements.md` was only grepped, to check whether removed features left anything behind there and whether the hyphen example is repeated.

## Verdict

The PRD is in good shape. The settlement math holds up: all seven worked examples in FR-15 and the EARS cases I spot-checked (T3.16, T3.17, T3.19, T3.31, T3.37, T3.45) recompute correctly. The removal of settling-up tracking is clean, with one small leftover in NFR-14. The deferred items are stated consistently in §6.2, §7, §4.4 Out of Scope and the addendum. Two findings still block downstream work:

1. The tap budget for a changed Payer is defined two different ways, and the Payer and Category layout constraints may not be physically satisfiable with 10 Members.
2. The bidi hyphen rule in FR-16 is contradicted by its own example, and the same example is repeated in the EARS tests.

The rest are medium or low gaps. They are about edit-time semantics, default-Payer edge cases, name-length counting, the Expense-screen flow and archived-group interactions. Close them before writing stories, so the acceptance criteria don't have to make the decisions.

**Counts:** critical 0, high 2, medium 10, low 13.

---

## High

### H1. The changed-Payer tap budget contradicts itself, and the Payer row may not fit in "two pages"
- **Location:** FR-10 (Payer bullets, Category bullet); NFR-1; UJ-2 fuel edge case.
- **Quoted:** FR-10: "at most 5 taps from launch (one more for each swipe needed to reach the Member)". NFR-1: "When the Payer must be changed, at most 5 taps", with swipes "counting each swipe as a tap". FR-10: "The same grid-or-row layout rule as Categories applies" (which says "a sideways row of at most two pages").
- **Why:**
  - FR-10 lets the 5-tap budget grow with Member swipes. NFR-1 caps it at 5, swipes included. Take a Payer on page 2 and a Category on page 2: that is Add + swipe + Payer + swipe + Category + Save = 6 taps. FR-10 allows it; NFR-1 forbids it. UX cannot design the layout and QA cannot write the test until one rule wins.
  - Feasibility is a separate problem. Up to 10 Payer options (names up to 10 characters), 8 Category options "larger than" 48 dp, an Amount field, *Save* in the lower-half thumb zone (NFR-2), all with the numeric keypad open. The system keypad covers most of that lower half. Ten Hebrew names of 10 characters at 48 dp or more may need more than two pages of a row, which the "at most two pages" rule forbids. Nothing says what happens then.
  - Whether the keypad is the system IME or an in-app keypad is an architecture decision. FR-11's "the keypad does not accept a second digit" and FR-10's "keypad stays open while swiping" both depend on it.
- **Fix:**
  - Pick one budget and state it in both places, for example: "changed Payer: at most 5 taps + 1 per swipe for Payer and per swipe for Category", or a hard 6.
  - Say what happens when Members or Categories don't fit in two pages: allow 3 pages, or truncate long names on the chips.
  - Say whether *Save* may sit directly above the keypad and still count as the "lower half".
  - Either allow an in-app numeric keypad explicitly, or tell UX to settle that before architecture.

### H2. The FR-16 hyphen rule contradicts its own example (repeated in EARS)
- **Location:** FR-16, bullet 3. `ears-requirements.md` line ~199.
- **Quoted:** "When a name does not start with a Hebrew letter, a hyphen follows the prefix ("מ-Dan ל-דנה")."
- **Why:** "דנה" starts with a Hebrew letter, so by the rule its line should read "לדנה", without a hyphen. The example shows "ל-דנה". The rule could be per name, or "once any name is Latin, hyphenate both". This text decides the fixed Transfer string and the RTL screenshot tests (NFR-6). Story 3's acceptance criteria cannot be written unambiguously.
- **Fix:** Correct the example to "מ-Dan לדנה" (per-name rule) in both the PRD and EARS. Add one EARS case with a Latin receiver and a Hebrew debtor.

---

## Medium

### M1. "Recorded time" on edit is ambiguous
- **Location:** FR-10, FR-12, FR-13, NFR-12, SM-C1.
- **Quoted:** "its recorded time is always the time it was saved, and cannot be changed"; FR-12 shows "the date and time the Expense was recorded".
- **Why:** An Expense is "saved" again on every edit (FR-10's own "The same applies to saving an edit"). The PRD doesn't say which time the list shows: the first save or the last one. Showing the last save would break the "when it happened" meaning, and it would make the list's displayed times disagree with its save-order sort.
- **Fix:** "The displayed time is the creation time (NFR-12) and never changes on edit; the last-modification time is not shown."

### M2. Leftover sentence in FR-10 describes multi-user or untestable behavior
- **Location:** FR-10, bullet 6.
- **Quoted:** "The Expense is recorded when it happens, by whoever is with the Payer".
- **Why:** In v1 only the Organizer operates the app (§3), so "whoever is with the Payer" reads as multi-user wording left behind. As a requirement it can't be tested. It also implies no back-dating, yet UJ-1 records flights a month early, and a forgotten expense entered later gets the wrong date with no recourse. That is a real gap that the "cannot be changed" rule makes worse.
- **Fix:** Delete the clause. Keep only "its recorded time is the time it was first saved and cannot be changed (no back-dating in v1)". State the back-dating limit as an accepted constraint.

### M3. Default-Payer edge cases are undefined
- **Location:** FR-10, Payer default bullet.
- **Quoted:** "Payer defaults to the Payer of the most recently added Expense in this Group. For a Group's first Expense, the default is the first Member added".
- **Why:** These cases are not covered:
  - The most recent Expense is deleted.
  - The most recent Expense's Payer is changed by an edit.
  - The "first Member added" has since been removed, which is possible while they have no Expenses.
  - All Expenses are deleted after some existed.

  NFR-14 makes this rule replaceable, but it still has to be defined.
- **Fix:** "Default = Payer of the existing Expense with the highest save-order number (current Payer, after edits). If there is none, the earliest-added current Member."

### M4. The 10/20-character limits don't say what a "character" is, and the trimming rule conflicts with the input filter
- **Location:** FR-1, FR-2.
- **Quoted:** "at most 10 characters, counted after trimming leading and trailing spaces. The name field does not accept an eleventh character".
- **Why:**
  - Emoji, Hebrew niqqud and combining marks make "character" ambiguous: UTF-16 units, code points or graphemes.
  - If the count is taken after trimming, the field must accept more than 10 raw characters when spaces are present, yet it "does not accept an eleventh". The two rules contradict.
  - Paste behavior (truncate or reject) is unstated.
- **Fix:** Define a character as a user-perceived character (grapheme). Either "the field blocks input beyond N characters and trims on save", or count raw characters. Say that a paste is truncated to N.

### M5. Renaming a Member to an empty name or its own name is unspecified
- **Location:** FR-3 (compare FR-5).
- **Quoted:** "The uniqueness and 10-character rules of FR-2 apply to the new name."
- **Why:** The "Name required" rule is not included. FR-5 handles empty names and "own current name is not a duplicate" for Groups; FR-3 handles neither. Renaming "dana" to "Dana" would be rejected as a duplicate of itself.
- **Fix:** Mirror FR-5: empty or whitespace-only gives "Name required" and the old name is kept; the comparison excludes the Member being renamed.

### M6. Leaving the Expense screen with unsaved input is undefined
- **Location:** FR-10, FR-11, FR-13.
- **Why:** At a checkout, a stray Android back gesture is likely. The PRD doesn't say whether typed data is discarded silently, kept as a draft (Draft Expenses are out of scope) or confirmed in a dialog. A confirmation dialog would cost taps. UX and the EARS tests need a rule.
- **Fix:** State it: "Back discards an unsaved new Expense without confirmation; on the edit screen it discards the changes", or the opposite.

### M7. FR-7 timing contradicts UJ-1
- **Location:** FR-7 vs UJ-1 path.
- **Quoted:** FR-7: "After creating a Group, the app asks". UJ-1: "types the member names ... on finishing, the app asks".
- **Why:** FR-1 creates the Group the moment it has a name. UJ-1 puts the question after adding Members. That is a different screen flow: one combined create-and-members step, or two steps. Story 1's acceptance tests and the UX flow depend on it.
- **Fix:** State in FR-7 when exactly the question appears: right after the name is saved, or when the Organizer finishes the member step.

### M8. Archived read-only mode is under-specified for the screens it touches
- **Location:** FR-6 bullet 4, versus FR-10, FR-13, FR-14.
- **Quoted:** "its Expenses and Summary can be viewed, but Members, Expenses and the Group name cannot be changed".
- **Why:** These are not defined for an archived Group:
  - Tapping an Expense: does it open the edit screen read-only, or nothing?
  - Long-press delete.
  - *Add expense*: hidden or disabled.
  - The Archive view's empty state.
  - Whether archiving needs a confirmation.

  Each expense FR is written without the archived exception, so a story can implement them and pass while violating FR-6.
- **Fix:** Add one line to each of FR-10, FR-13 and FR-14 ("not available in an Archived group"). State what a tap does, and give the Archive view's empty-state text.

### M9. The Summary display order of Transfers is unspecified
- **Location:** FR-15 tie-break, FR-16.
- **Quoted:** "order each candidate list's Transfers by debtor name, then receiver name" (used only for choosing the list).
- **Why:** The rule picks which list is used, not the order in which lines are shown. The EARS tests list Transfers in that order and the screenshot test depends on it, but no requirement fixes it.
- **Fix:** In FR-16: "Transfers are shown in the FR-15 order (debtor, then receiver, by the FR-15 alphabetical rule)."

### M10. The tie-break forces exhaustive search, and the PRD should say so for architecture
- **Location:** FR-15 (minimum count plus lexicographic tie-break), NFR-5.
- **Why:** The minimum number of Transfers is a subset-partition problem. The lexicographic tie-break also means the app must enumerate all minimal candidate lists, so no greedy algorithm qualifies. With 10 Members that's feasible within 1 s, but an architect or developer reading "minimal set" will reach for the classic greedy matching, which fails T3.6 and T3.31. The behavior is fully defined; the implementation consequence is not stated.
- **Fix:** Add a note to FR-15 or the addendum: "Requires exhaustive search over zero-sum partitions; greedy matching does not satisfy the tie-break. n ≤ 10 keeps this within NFR-5."

---

## Low

1. **Thousands separator not defined.** FR-15 display rule versus UJ-4 "₪8,400", "₪1,250". The display rule defines decimals only. Fix: "Thousands are grouped with a comma."
2. **Summary with zero Expenses says "Everyone is settled up".** FR-15 and FR-16: with 2+ Members and no Expenses every Balance is 0. That's technically right but odd. Fix: accept it explicitly, or show "No expenses yet".
3. **A Group can have 1 Member and Expenses.** FR-4 allows removing a non-Payer, so a 2-Member Group with Expenses can drop to 1. *Add expense* and the Summary are then disabled, but editing the existing Expenses isn't addressed. Fix: say that editing is allowed, or block removal below 2 Members once Expenses exist.
4. **SM-5 contradicts UJ-4.** SM-5 says "sent on the last evening of the trip, before the friends go home"; UJ-4's entry state is "on the return flight or just after landing". Fix: align one with the other.
5. **FR-16 "understandable from a screenshot alone" can't be tested as an FR.** It is really SM-4. Fix: move it to SM-4, or replace it with a testable proxy (no arrows, full names, the fixed string).
6. **NFR-6 "is checked as part of the tests" is vague.** It doesn't say whether this is a golden-image test or a manual check. Fix: say which.
7. **Description has no maximum length.** The Glossary says "short free text" without a number. It is shown in the list in place of the Category, so length matters. Fix: give a limit (for example 30) with the same input rule as names.
8. **Integer width for money.** Amounts up to ₪1,000,000 are 10^7 tenths each; a 32-bit total overflows after about 214 such Expenses. Fix: NFR-15 "stored as 64-bit integers".
9. **Time zone for displayed times.** Recording happens abroad and may be viewed back home. It isn't said whether times show the device's current zone or the recording zone. Fix: "shown in the device's current time zone", and store UTC (NFR-12, server-readiness).
10. **Leftover in NFR-14 from the removed lock.** "when a Group may be changed" was there for the lock; in v1 it now only covers archive read-only. Fix: reword it to "archive read-only rule", or keep it and add a note.
11. **Ordering of the group list, member list and Payer options is unstated.** This matters for thumb muscle memory and for which chip sits on page 1 (relevant to H1). Fix: for example "Payer options in the order Members were added".
12. **Bidi isolation is only required for Transfer lines.** NFR-6 covers Member names and amounts, but Group names ("Budapest 2026") and Descriptions in Latin are also shown inside RTL layout, including on the Summary screenshot. Fix: extend the isolation to all user-entered text.
13. **Debug build versus performance NFRs.** §9 says the trip phone runs a debug build for `adb` access, while NFR-5 sets timing targets without saying which build they are measured on. Debug builds can be noticeably slower. Fix: "NFR-5 is measured on a release-configured build that is debuggable", or state which build is used.

Notes, not findings: the addendum's "the member who recorded (paid)" mixes recorder and payer for the multi-user phase, which needs settling there, not in v1. UJ-2 doesn't mention the forint-to-shekel conversion the Organizer does in his head at the checkout; NFR-7 decides this, so it is fine, but a line in UJ-2 would keep the journey honest.
