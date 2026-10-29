# Review: EARS ↔ PRD Consistency (GrouPay)

**Reviewed:** `ears-requirements.md` (working copy, uncommitted), `prd.md` (status final, updated 2026-10-27), `addendum.md`. Date: 2026-10-27.

## Verdict

The uncommitted EARS rewrite is substantially aligned with the PRD: every FR-1 – FR-19 has an EARS counterpart, and all 40+ worked numeric test cases (rounding, Leftover, tie-break, Payments) recompute correctly against the FR-15 rules. There are no critical contradictions in amounts, limits or calculation rules. The main problems come from the edit itself. It adds a founder-mandated **Fixed Hebrew messages** table and an exact **lock message** that the PRD does not contain. The lock message also contradicts the PRD's description of why a group is locked. Because PRD §0 says the PRD supersedes EARS where they differ, these founder decisions are currently not secured. Smaller gaps remain: EARS omits a few precise FR-15 rules (receivers with no Expenses, the formal tie-break definition), FR-8 "set active at any time", and almost all NFRs. PRD §8.2 no longer describes what was actually changed in EARS. Fix the PRD for the new message decisions (2 high, 1 medium), and fix EARS for the missing rules and NFR coverage.

**Counts:** Critical 0 · High 2 · Medium 5 · Low 14

**Note on the diff:** `git diff` against HEAD shows a near-total rewrite. The committed version is still the original pre-PRD EARS with "Calculate" and the per-member owed amounts. PRD §8.2 says EARS "was updated on 2026-10-26", but that update exists only as uncommitted changes.

---

## High

### H1. Lock message: the EARS exact string contradicts the PRD's stated reason
- **EARS:** line 18 (Fixed messages table) and line 187: "The group is locked to changes after transfers between members" / "הקבוצה ננעלת לשינויים לאחר ביצוע העברות בין חברים". Also T3.9.
- **PRD:** FR-18: "the Group page explains that the Group is locked because a payment was marked". There is no fixed string.
- **Problem:** this is new in the edit. The PRD gives no exact text, and the meaning differs. PRD: the lock is caused by a *Paid mark*. EARS: the lock happens "after transfers between members" (Hebrew: "after transfers were carried out"). A Paid mark can be set by mistake (FR-19 "No, marked by mistake"), so the EARS wording claims money moved when it may not have. The PRD's own wording "a payment was marked" also blurs the Glossary terms *Payment* (a record created when a mark is cleared) and *Paid mark*.
- **Fix:** **PRD** FR-18 should quote the exact message (English reference and Hebrew). Ask the founder to confirm the wording against the Paid-mark trigger. A suggested alternative is "The group is locked because a transfer was marked as paid". Also change "a payment was marked" to "a Transfer was marked as paid" to respect the Glossary.

### H2. Founder-fixed Hebrew messages exist only in EARS
- **EARS:** lines 11–18: "**Fixed Hebrew messages** (set by the founder; the app must show exactly this text)". The table has 4 strings.
- **PRD:** NFR-6: "The user-facing messages quoted in this PRD are shown in Hebrew; the English strings are the EARS test references." There is no Hebrew text. §11: "All assumptions were confirmed by the founder … and are now stated as requirements."
- **Problem:** the edit introduces a binding requirement (exact Hebrew text) with no PRD counterpart. Under PRD §0 ("supersedes `ears-requirements.md` where they differ"), downstream readers could treat these strings as optional.
- **Fix:** **PRD** NFR-6 should add the table, or reference EARS as the source of truth for exact UI strings, and note the founder decision date.

---

## Medium

### M1. "Description required, or choose a category" message missing from the PRD
- **EARS:** line 17, line 124, T2.6.
- **PRD:** FR-11: "Category *Other* requires a non-empty Description." No message is defined. Every other FR-11 rule has a quoted message.
- **Fix:** **PRD** FR-11 should add the message. Also state whether a whitespace-only Description counts as empty. EARS says "without a description" and the PRD says "non-empty".

### M2. Leftover tie rule incomplete in EARS
- **EARS:** line 164: "the receiver whose first expense was recorded later will absorb the leftover first … equal times are ordered by save order".
- **PRD:** FR-15: "A receiver's first Expense is the one with the earliest creation time among the Expenses they are currently the Payer of … A receiver with no Expenses counts as later than any receiver with Expenses; between two such receivers, the Member added later counts as later."
- **Problem:** a receiver with no Expenses is reachable through Payments, for example a Member who sent a Payment and then becomes owed after later Expense changes. EARS has neither the rule nor a test, and NFR-16 requires tests for "receivers with equal totals".
- **Fix:** **EARS** should add both clauses to line 164 and add a test, for example two receivers with ₪0 paid each, where one is positive only because of a Payment.

### M3. FR-8 "set or unset the Active group at any time" has no EARS event requirement
- **EARS:** the Active group is set only through the creation prompt (lines 32–35). Unset is at line 36. Line 188 mentions "set or unset the group as active" only *while locked*, and T3.14 tests it only for a locked group.
- **PRD:** FR-8: "The Organizer can set any non-archived Group as the Active group, or unset the Active group, at any time … At most one Group is active at any moment."
- **Fix:** **EARS** should add "When the user sets an existing group as active, it becomes the only active group" and a test (set an existing unlocked group active while another is active).

### M4. NFRs largely absent from EARS
- **EARS:** covers only NFR-1 (line 117), parts of NFR-6/7 (conventions, line 166) and NFR-15/16 implicitly.
- **PRD:** NFR-2 – NFR-5, NFR-8 – NFR-14 and NFR-17 have no EARS counterpart. Some of these are testable and core to the product: NFR-8 (no network calls, full offline), NFR-9 (data survives app kill and restart), NFR-5 (launch within 2 s, save under 300 ms), NFR-3 (48×48 dp) and NFR-6 (Latin names and amounts render correctly inside RTL).
- **Fix:** **EARS** should add a "Cross-cutting (Ubiquitous)" section with "The app shall …" statements and tests for at least NFR-5, NFR-6 (RTL mixed script), NFR-8 and NFR-9. Alternatively, **PRD** §8.1 could state explicitly that EARS covers functional behavior only.

### M5. Only 4 of about 13 user-facing messages have fixed Hebrew text
- **EARS:** the table at lines 13–18 fixes 4 strings. "Name required", "Group already exists", "Member already exists", "Please enter a valid amount", "Please choose a category", "No expenses yet", "Everyone is settled up", "The list of groups will appear here", and the three FR-19 dialog choices have no fixed Hebrew.
- **PRD:** gives no Hebrew text at all (NFR-6).
- **Problem:** tests on the Hebrew UI cannot verify most messages, and nothing says whether the remaining translations are free or still to be fixed.
- **Fix:** **both docs** should either complete the table for all messages or state that only the 4 listed are fixed and the rest are free translations.

---

## Low

| # | Title | EARS | PRD | Suggested fix |
|---|---|---|---|---|
| L1 | §8.2 change log is stale and EARS is uncommitted | whole file (diff vs HEAD = full rewrite); line 7 "aligned with the GrouPay PRD" | §8.2: "updated on 2026-10-26 with these changes", which lists 4 items and omits Payments, the Archive read-only rule, Hebrew messages, the tie-break and the tap-budget swipe | **PRD** §8.2: list all changes and date them 2026-10-27; commit the EARS file |
| L2 | Tie-break defined informally; fallbacks missing | line 168: "the debtor first in alphabetical order pays the receiver first … and so on"; "then the geresh" | FR-15: "order each candidate list's Transfers by debtor name, then receiver name, and choose the list whose sequence of (debtor, receiver) pairs comes first"; "geresh (׳ or ')"; "Names that are still equal … ordered by their Unicode values" | **EARS** line 168: copy the precise definition, both geresh forms and the Unicode fallback (needed for names such as "דן" vs "דנ", which are not duplicates but sort as equal) |
| L3 | Archive read-only rule under the wrong heading | line 44, a **While** statement listed under "Event-Driven (When)" | FR-6 | **EARS**: move to State-Driven |
| L4 | Test IDs out of order | T1.26–T1.30 (lines 87–91) come before T1.23–T1.25 (lines 92–94) | — | **EARS**: reorder |
| L5 | Archive and restore do not mention Payments | line 43: "with all its members, expenses and paid marks" | FR-6: "keeps all its Members, Expenses and Paid marks unchanged" | **Both**: add "and Payments" |
| L6 | Whitespace-only and rename-to-empty for names | line 54 "empty name" (create; T1.25 covers whitespace only for rename); line 56 member "empty name"; nothing for renaming a member to empty | FR-1/FR-5 "empty or whitespace-only"; FR-2 "An empty name"; FR-3 applies only the uniqueness rule | **EARS** line 54: add "or whitespace-only" and a create test. **PRD** FR-2/FR-3: state the whitespace-only and empty rules for Member add and rename, then mirror them in EARS |
| L7 | "Keeps entered data on screen" and edit validation not stated as requirements | only T2.15 checks this; line 108 has no validation clause | FR-11: "keeps the entered data on screen"; FR-13: "FR-11 validation applies" | **EARS**: add both as requirements, plus an invalid-edit test |
| L8 | Expense list display details | line 106: "payer, amount, category and the date and time" | FR-12: "Category (or Description for *Other*)", "newest first" | **EARS** line 106: add the Description-for-Other rule and the newest-first ordering |
| L9 | Payment limits and out-of-scope items missing | line 20 out of scope; no requirement that Payments cannot be edited or be partial | FR-19: "A Payment cannot be edited"; "Partial Payments cannot be recorded"; §4.3/4.4 out of scope: receipt photos, recipient confirmation, partial Payment | **EARS**: add these to the out-of-scope list or as requirements |
| L10 | Fixed Category list not in EARS | T2.18/T2.19 depend on how many Categories exist | Glossary: 8 Categories (Flight … Other) | **EARS**: list the Categories in Conventions |
| L11 | "Both apply" removal case untested | line 59 implies the Expense message takes priority; no test | FR-4: "When both apply, the Expense message is shown" | **EARS**: add a test for a Member who is a Payer and has a Payment |
| L12 | Hebrew term for Member is inconsistent | line 15/16 "משתתף", line 18 "חברים" | Glossary: Member | **EARS** (founder): use one Hebrew term |
| L13 | Display order of Transfers unspecified | T3.34 expects "יעקב → יצחק" listed before "יעקב → תום" | FR-15 defines the choice of list, not its display order | **PRD** FR-16: state the display order (for example the tie-break order), then mirror it in EARS |
| L14 | Amount upper-boundary test | T2.3d tests 1,000,001 only | FR-11: "above ₪1,000,000" rejected | **EARS**: add a test that ₪1,000,000 is accepted |

Non-testable PRD items that are reasonably absent from EARS: FR-16 "understandable from a screenshot alone" (covered by SM-4) and FR-17 "A Paid mark is identified by its Transfer's pair" (an implementation detail).

---

## Verified consistent (no action)

- Amount limits and precision (FR-11 ↔ lines 121–122, T2.3a–d, T2.4); tap budget with swipes (FR-10/NFR-1 ↔ lines 114, 117, T2.10, T2.18–19).
- Share, Leftover and Balance formula, and the no-minimum Transfer (FR-15 ↔ lines 162–167). All numeric tests were recomputed and match: T1.13, T1.20, T1.30, T2.16, T3.1, T3.4–T3.6, T3.15–T3.20, T3.26–T3.27, T3.30–T3.35, T3.37–T3.38, T3.41–T3.42.
- Lock, Settled group, Payments and the three-choice dialog (FR-17 – FR-19 ↔ lines 169–189).
- Archive read-only behavior, and a Locked group staying archivable and settable as active (FR-6, FR-8, FR-18 ↔ lines 41–44, 188, T1.26–T1.28, T3.14).
- Member removal with Payments, and deleting a Payment (FR-4, FR-19 ↔ lines 58–59, 179, T1.29–T1.30, T3.28–T3.29).
