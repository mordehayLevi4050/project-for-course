# PRD Quality Review — GrouPay (prd-groupay-2026-10-26, revision 2026-10-29)

## Overall verdict
This is a decision-ready, unusually precise PRD. Its thesis (speed at the checkout plus Hebrew-first RTL for one organizer on one trip) runs through the UJs, FRs, NFRs and metrics, and the 2026-10-29 deferrals (settling-up tracking, currency outside the app, no Balance breakdown) are stated as accepted risks with named consequences. What remains is a small set of done-ness gaps: a display example in FR-16 that contradicts its own rule, an undefined reference device for the performance and fit bounds, and an unspecified default-Payer fallback. None blocks story creation, but each will cause a test argument if left as is.

## Decision-readiness — strong
Decisions are stated as decisions, and the PRD says what each one gives up. §1 Positioning admits that offline use and no signup are "table stakes, not an edge" and that "None of this is a moat". §2.2 says v1 "deliberately does not solve" the original pain ("my friends don't keep records"). §7 turns each deferral into an accepted risk with its cost: "losing the phone loses its Groups; this risk is accepted for the test"; no Balance table, "the risk that this leads to disputes is accepted for the test (SM-3, SM-4)"; after the screenshot is sent, "a late correction is settled by hand among the friends". NFR-7 handles currency the same way: conversion time is excluded from the tap budget and exchange-rate disputes are excluded from SM-3, so the metric is not polluted by the decision. These are clear statements of founder decisions, and per instructions they are not re-litigated here.

Open Questions (§10) has a single item, and it really is open (long-term positioning, Bit feasibility, admin roles). It sits outside v1, which is right for a PRD at this stage.

One tension is left implicit: FR-10 asks for an open numeric keypad, a Payer grid of up to 10 Members, a Category grid of 8 options "larger than" 48 dp (NFR-3) and *Save* all reachable together, with primary actions in the lower half (NFR-2). The PRD hands the layout to UX ("The exact layout is a UX decision") and allows a two-page swipe row as an escape valve. It does not flag that on a 6" screen these constraints may not all fit, so the 4-tap budget could break.

### Findings
- **medium** Layout feasibility of the Expense screen not flagged (§4.3 FR-10; NFR-2, NFR-3) — The keypad, a Payer grid of up to 10, 8 Category targets above 48 dp and *Save* must all be reachable at once in the lower half. The two-page row helps, but nothing says what gives way if the Payer row *and* the Category row both need a swipe: that is up to 6 taps, beyond the 5-tap budget in NFR-1. *Fix:* add a `[NOTE FOR PM]` or a priority rule, e.g. "if both rows need paging, the Payer row pages and the Category row stays a grid", or state the worst-case tap count explicitly.

## Substance over theater — strong
There is one protagonist (Motty), and his traits drive the requirements: right-handed (NFR-2 right-thumb zone), standing at a checkout with no signal (NFR-8, FR-10 keypad), pays the most (default Payer). The Vision is specific to this product: "at the checkout, one-handed, in at most 4 taps from launch", "fits in one screenshot for the group's WhatsApp chat". The NFRs carry numbers: 2 s cold launch, 300 ms save, 1 s Summary for 10 Members, 48 dp, WCAG 2.1 AA, whole tenths of a shekel. The differentiation claim is deliberately modest and honest.

### Findings
- **low** "Look and feel" paragraph is not actionable (§1, "draws on the feel of PassportCard: travel and financial confidence together") — No requirement or UX constraint follows from it. *Fix:* move it to the addendum as UX input, or leave it and accept it as tone-setting.

## Strategic coherence — adequate
The thesis is clear: get the expense recorded at the moment it happens and answer "who transfers how much to whom" in one screenshot. Feature priority follows from it. Active-group launch (§4.2) exists only to save taps, and the Summary's fit and RTL rules (FR-16) exist only to make the screenshot work. Counter-metrics are named, have thresholds and are tied to what they counterbalance (SM-C1 edits after save at most 15%, SM-C2 *Other* under 10%). The MVP is a coherent "experience" MVP that serves one trip.

The weaker link is that the primary metrics mostly confirm that v1 works, not that the bet pays off. SM-2 restates NFR-1 ("at most 4 taps... checked by walking the UJ-2 flow") as a spec check, not an outcome. SM-1 openly says that whether expenses went unrecorded "cannot be measured", which is honest but leaves the core thesis ("fast enough that it actually happens") without even a proxy. For a course project tested on a single trip this is acceptable, so the verdict is adequate rather than thin.

### Findings
- **medium** No proxy for the core thesis "recording actually happens" (§9 SM-1, SM-2) — The speed metric checks the spec, not the behavior. A cheap proxy exists in the data v1 already keeps: the share of Expenses saved on the day they occurred, or the count of Expenses the Organizer added after the trip from memory (self-reported). *Fix:* add one secondary SM, e.g. "Organizer reports at most N Expenses reconstructed after the fact", read by hand like the counter-metrics.
- **low** SM-5 traceability is thin (§9, "Validates FR-15, FR-16") — Same-evening settle-up depends mostly on behavior, not on those FRs. *Fix:* say it validates the thesis (Vision, settle-up pain) rather than specific FRs.

## Done-ness clarity — adequate
Most FRs have testable consequences with exact messages, limits and examples. FR-15 is exemplary: integer tenths, Leftover absorption with a tie-break keyed to save order rather than the phone's clock, a fully defined collation (final letters, geresh, digits, Unicode fallback) and seven worked examples. I checked all seven by hand and they are arithmetically correct, including the tie-break in the Motty/Dana/Yossi/Noa case and the cascade in the אבי/בני case. FR-10 defines tap counting precisely (swipes count, typing does not). Validation messages are fixed verbatim in NFR-6.

The gaps are few but concrete, and story creation will hit them.

### Findings
- **medium** FR-16 hyphen example contradicts its own rule (§4.4 FR-16, "When a name does not start with a Hebrew letter, a hyphen follows the prefix ("מ-Dan ל-דנה")") — דנה starts with a Hebrew letter, so under the rule it should read "לדנה" with no hyphen. EARS T3.44 applies the rule correctly ("מדנה ל-Zoe"), so the PRD example and the test disagree. The same wrong example also appears in the EARS requirement text (ears-requirements.md line 199). *Fix:* change the example to "מ-Dan לדנה" in both places.
- **medium** Reference device for performance and fit bounds is undefined (NFR-5 "a mid-range Android phone"; FR-16 "the founder's trip phone at the default font size"; NFR-2 "typical 6–6.7\" Android phone") — These are three different and unnamed devices. NFR-5 and the FR-16 fit rule are therefore bounds measured against an adjective. *Fix:* name the trip phone model (and screen size/density) once, e.g. in §5.3, and make it the reference device for NFR-2, NFR-5 and FR-16.
- **medium** Default-Payer fallback unspecified (§4.3 FR-10, "Payer defaults to the Payer of the most recently added Expense in this Group... the default is the first Member added") — Undefined when the most recent Expense has been deleted or had its Payer edited, and when the first Member added has since been removed. This rule sits on the tap-budget path and is one of the rules NFR-14 isolates, so it needs to be exact. *Fix:* define it as "Payer of the Expense with the highest save-order number that still exists; if none, the earliest-added Member still in the Group", and state whether editing a Payer affects it.
- **low** Active-group prompt timing differs between UJ-1 and FR-7 — UJ-1 asks "on finishing" adding Members; FR-7 asks "After creating a Group". *Fix:* pick one trigger (e.g. when the Organizer leaves the new Group's member setup) and use it in both places.
- **low** FR-3 does not carry over the empty-name rule — It imports "uniqueness and 10-character rules of FR-2" but not "Name required", whereas FR-5 states the equivalent rule explicitly. *Fix:* add "An empty or whitespace-only name is rejected with "Name required" and the Member keeps the current name."
- **low** Group with Expenses but one Member is undefined (FR-4, FR-10, FR-16) — FR-10 itself notes such a Group can exist. *Add expense* and the Summary are both disabled, but it is not said whether existing Expenses can still be edited or deleted. *Fix:* one line under FR-4 or FR-10.
- **low** Paste behavior for over-long names (FR-1, FR-2, "cannot be typed or pasted in") — It is unclear whether a pasted name is truncated or rejected, and whether the field limit counts raw or trimmed characters (the rule says "counted after trimming"). *Fix:* state "pasted text is truncated to the limit", and say whether leading/trailing spaces count toward the field cap.
- **low** FR-16 "understandable from a screenshot alone, by someone who has never seen the app" — Not engineer-testable on its own. It is covered in practice by the fixed line format, the RTL screenshot tests (NFR-6) and SM-4. *Fix:* optionally reword it as the outcome SM-4 measures, keeping the testable rules above it as the acceptance criteria.

## Scope honesty — strong
Omissions are explicit. Each feature has an Out of Scope line, §6.2 separates the next version from later phases, and §7 Non-Goals does real work: it states the operational consequence of each deferral (backup, payment tracking, Balance table, analytics). The 2026-10-29 de-scoping of settling-up tracking is disclosed rather than silent: §6.2 dates it, the addendum keeps the old design and the unresolved C2 question ("Decide before rebuilding"), and §8.2 records the matching EARS deletions. Open-items density is very low: one Open Question, zero open assumptions (§11 records that all were confirmed by the founder). That suits a green-light-to-build course PRD.

No findings.

## Downstream usability — adequate
The Glossary is strong and used consistently for the main nouns (Group, Member, Expense, Payer, Share, Leftover, Transfer list). FR/UJ/SM IDs are unique and resolve. §8.1 maps FRs to the three course stories cleanly, and NFR-14 tells architecture exactly which rules must be swappable. The addendum's architecture note (Category as validation, not structure) is useful input for the next version.

Some load-bearing terms live only inside FRs. A story implementer reading only their own story's FRs would miss them.

### Findings
- **low** Key terms not in the Glossary — "save order" (defined in FR-15, used by FR-12 and NFR-14), "receiver" and "debtor" (used throughout FR-15/FR-16), "group list" and "Group page" (used across §4.1–4.3). *Fix:* add Save order, Receiver, Debtor, Group list and Group page to §3.
- **low** App-wide amount format lives in a calculation FR (FR-15, "This applies to every amount in the app, including the Trip total and the Expense list") — Story 2 (FR-12) depends on a rule placed in Story 3. NFR-7 points to it, which helps. *Fix:* move the format rule into NFR-7 and have FR-15 reference it.

## Shape fit — strong
This is a consumer app with one real operator, built as a course project and tested on one trip. The shape matches: four UJs with a single named protagonist carrying context inline (entry state, hands, signal), FRs grouped by the three course stories, and a light but real NFR section. Rigor is high where it pays: FR-15's determinism exists because the EARS tests must be exact. It stays light elsewhere, with no personas beyond Motty and no market sizing. The PRD sits at the top of a chain (UX → architecture → stories), and it invests in traceability accordingly.

No findings.

## Mechanical notes
- **ID order:** NFR-17 (§5.3 Platform) sits between NFR-7 and NFR-8. The IDs are unique and contiguous, but not in document order. Renumbering is optional; leaving it avoids churn in the EARS cross-references.
- **"Realizes" links:** FR-3 (Rename a Member) cites UJ-3, which contains no rename. FR-5 (Rename a Group) cites UJ-1, which only implies it ("edit other groups"). Either add a one-line edge case to a UJ or drop the link.
- **Case drift:** "organizer" (§1 Vision, §2.3 lead-in) vs "Organizer" (Glossary and FRs); "group page" (UJ-2, UJ-3) vs "Group page" (FRs). "Payment" is capitalized in §4.4 Out of Scope and §6.2 but is not a Glossary term (acceptable, since it is deferred; an addendum-only definition would do).
- **Assumptions roundtrip:** §0 says inferred items are tagged `[ASSUMPTION]` and indexed in §11. There are no inline tags, and §11 says none are open, so the roundtrip is consistent. The §0 sentence could say "were tagged" to avoid suggesting tags exist.
- **EARS sync:** §8.2's 2026-10-29 changes are reflected in ears-requirements.md (removed T-IDs are noted, and the Transfer display and message table are present). The only divergence found is the shared "ל-דנה" example (see Done-ness).
- **Required sections:** all present for the stakes (Vision, users/UJs, Glossary, FRs, NFRs, Scope, Non-Goals, SMs with counter-metrics, Open Questions, Assumptions Index).
