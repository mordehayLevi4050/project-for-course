# Reconcile: Brief -> PRD (GrouPay)

- **Input:** `planning-artifacts/briefs/brief-groupay-2026-10-26/brief.md` (+ `addendum.md`)
- **Against:** `prds/prd-groupay-2026-10-26/prd.md` (+ `addendum.md`), PRD updated 2026-10-29
- **Date:** 2026-10-29
- **Excluded (deliberate founder decisions, 2026-10-29):** Paid marks / group lock / Payments deferred (in PRD §6.2 + addendum); currency conversion outside the app (NFR-7); 10-Member cap (FR-2); "תשלום נדרש מ.. ל.." wording (FR-16).

## Gaps

### G1. Rounding principle contradicted, change not recorded — HIGH
- **Brief:** "a short list of transfers in **whole shekels**"; "agorot are rounded **in favor of whoever paid**", "so the person who paid **never comes out short**" (Solution; Scope item 3).
- **PRD:** Transfers are multiples of ₪0.10, and a ₪0.1 Transfer is shown (FR-15, §3 Transfer). The Share is rounded down and the Leftover is **taken off the receivers** (the payers), so a payer can come out up to ₪0.10 short (FR-15, NFR-15, worked example 2: Dana absorbs ₪0.1).
- **Why it matters:** two brief rules, whole shekels and "the payer never comes out short", are reversed. The PRD never says it departs from the brief here: §0 lists `ears-requirements.md` as superseded, not the brief. The amounts are tiny, but the brief stated a principle ("the payer never comes out short") that the PRD now contradicts in silence.
- **Suggested fix:** add one line to FR-15 or §7 recording the founder's decision: tenths instead of whole shekels, and receivers absorbing the Leftover, along with the reason (exactness, or a minimal list). Alternatively, restore the rule that the payer is never short.

### G2. Competitive research and the market-gap reasoning have nowhere to live — MEDIUM
- **Brief + brief addendum:** the competitor table (Splitwise caps/ads, Tricount, Settle Up paywalls, Splid, Spliit, LAYA, Bit), "no Hebrew-first splitting app found", and the gaps that look real: **free categories** (competitors paywall them) and a **Bit/PayBox** settle-up hand-off.
- **PRD:** §0 says "research live[s] in `addendum.md`", but the PRD addendum has no research section. §1 Positioning keeps only the Splid point. "Free categories" as a differentiator and PayBox appear nowhere.
- **Suggested fix:** fix the dangling reference in §0, either by linking to the brief addendum or by copying the takeaways into the PRD addendum. Also note "free categories" (and no ads or entry caps, which follows from the brief's complaint about Splitwise friction) as part of the positioning.

### G3. "Every feature is judged against that number" narrowed — LOW
- **Brief:** "Speed is the core design rule... **Every feature** is judged against that number."
- **PRD:** NFR-1 says only that "any new v1 UI **on this path** must stay within the budget". The brief made the tap budget a governing principle for every product decision. The PRD makes it a constraint on one flow.
- **Suggested fix:** restate it as a design principle in §1 or §5.1. For example: any feature that adds friction to recording is rejected or redesigned.

### G4. Later-phase detail and principles from the brief dropped — LOW
- **Unequal splits:** the brief's principle "splitting among everyone **stays the default**" is not in the PRD or its addendum. The addendum covers late joiners and dropouts, but not which split is the default.
- **Bit:** the brief marks feasibility as unverified and expects it "may come down to deep links or sharing a payment request". The PRD keeps only "settling through Bit" plus an open question.
- **Hebrew voice entry:** the brief's example ("300 שקל דלק, יוסי שילם"), its reason (it directly serves the speed goal), and its needs (Hebrew speech-to-text plus parsing of amount, category and payer) are dropped. The PRD lists only the name.
- **Suggested fix:** add a short "Later features" block to the PRD addendum carrying these notes.

## Checked, no gap
- PassportCard look and feel (inspiration only): carried into §1.
- "Not a moat; focus and execution speed": carried into §1.
- The one-device v1 being close to Splid: carried into §1.
- Organizer persona and the friends' pain solved only in the multi-user phase: carried into §2.2.
- Frictionless joining and payer default in the multi-user phase: in the PRD addendum under Principles.
- Category breakdown as the reason Restaurant and Food & drink are separate: §3 Category.
- Brief success criteria: "no fallback to notes or WhatsApp" was explicitly replaced as unmeasurable (SM-1). "Minutes, not an evening" became SM-5.
- EARS alignment open question: resolved in §8.2.
- Long-term positioning, Bit feasibility and admin roles: §10.
- Trip hub (breadth): consistent with the §7 non-goal plus the open question in §10.
