# Validation Report — PRD: GrouPay

- **PRD:** `_bmad-output/planning-artifacts/prds/prd-groupay-2026-10-26/prd.md`
- **Rubric:** `.claude/skills/bmad-prd/assets/prd-validation-checklist.md`
- **Run at:** 2026-10-27
- **Grade:** Poor. On the rubric alone it would be Fair; the two critical findings from the adversarial review set the grade.

## Overall verdict
The PRD is very precise for a project of this size. The settlement maths (FR-15, FR-19) gives one exact answer in every case, and all of its worked examples are correct when recomputed by hand. Scope and non-goals are stated explicitly, and the positioning is honest about Splid. The main risks are at the edges of the core journey. First, recording an expense paid by someone other than the Organizer is unspecified. Second, converting foreign currency in people's heads on a trip abroad (NFR-7) distorts the accuracy and clarity metrics the trip is meant to test.

The adversarial review adds two critical findings. Both are small to fix in the text, but both would mislead architecture. The "A → B ₪N" arrow does not mirror in RTL Hebrew text, so the screenshot can show the payment going the wrong way. The Transfer list is defined as "the minimal set", but FR-17/FR-19 require it to be saved and left unchanged while Paid marks exist, and no stored entity is defined for it. The adversarial review also found eight high-severity gaps:
- no Member cap, although an exact minimum (NP-hard) is required
- no all-or-nothing saving for multi-step actions
- zero-Member division
- success metrics that can't be measured

The uncommitted EARS rewrite is largely aligned with the PRD. However, it adds founder-set Hebrew message texts and a lock message that the PRD does not contain, and the lock message contradicts the PRD's reason for the lock. Because the PRD wins wherever the two documents differ, those founder decisions are currently not protected.

## Dimension verdicts
- Decision-readiness: adequate
- Substance over theater: strong
- Strategic coherence: adequate
- Done-ness clarity: adequate
- Scope honesty: strong
- Downstream usability: strong
- Shape fit: strong

## Findings by severity

### Critical (2)
**[Adversarial]** C1: Transfer arrow reverses meaning in RTL (Glossary "Transfer", FR-15/16, NFR-6)
The → character does not mirror in right-to-left text. "יוסי → דנה" is laid out with the arrow pointing at the debtor.
Fix: Add an NFR that every direction is unambiguous in RTL. Use direction-free wording, or use ← with each name isolated for bidi. Add a test on a rendered screenshot.

**[Adversarial]** C2: The Transfer list is defined as "the minimal set" but must be saved and frozen while locked (Glossary, FR-15, FR-17, FR-19)
Recalculating the list risks leaving Paid marks pointing at Transfers that no longer exist. Saving it means a stored entity is missing from NFR-11.
Fix: Snapshot the list at the first Paid mark, give each Transfer a stable ID, and have marks reference that ID. Alternatively, prove the invariant as a property test.

### High (12)
**[Decision-readiness]** Currency conversion accepted without weighing its effect on the test (NFR-7; SM-2/3/4)
Fix: Add an Open Question. At minimum, set one agreed rate for the whole trip and a rounding rule.

**[Strategic coherence]** Recording an expense paid by another Member is unspecified (UJ-2, FR-10, NFR-1, SM-1)
Fix: Add a journey and a Payer-selection bullet with its own tap bound. State that the recorded time is entry time.

**[Adversarial]** H1: No Member cap, but an exact minimum plus tie-break is required (FR-2, FR-15)
Fix: Cap Members, add a latency NFR for the Summary, and extend the tests up to the cap.

**[Adversarial]** H2: Groups with zero or one Member: division by zero and no Payer (FR-10, FR-15, FR-4)
Fix: Disable Add expense below the minimum, compute Share only when there are 2 or more Members, and add tests.

**[Adversarial]** H3: No all-or-nothing saving or double-tap protection (NFR-9, FR-19)
Fix: Add an NFR that every action is saved all-or-nothing, and make Save ignore repeated taps.

**[Adversarial]** H4: The time-based tie-break depends on the phone's clock, and the save-order number isn't server-ready (FR-15, NFR-11/12)
Fix: Make the sequence number or a logical clock the primary order.

**[Adversarial]** H5: A "no disputes" goal with no way for friends to check amounts (§7, FR-16, SM-3/4)
Fix: Show the per-person Share, or record disputes as an accepted risk with a counter-metric.

**[Adversarial]** H6: Success metrics are self-judged, have nothing to check against, and can't be read from the device (§9)
Fix: Add a stats export or a documented adb procedure, and give each metric a threshold.

**[Adversarial]** H7: The lock and archive rules cut across all three stories but are scheduled in Story 3 (§8.1)
Fix: Define a single "can modify Group" check in Story 1, and split Story 3.

**[Adversarial]** H8: Names with no length limit break the one-screen Summary (FR-1, FR-2, FR-16)
Fix: Set maximum lengths, or specify how names are truncated.

**[EARS]** H1: The EARS lock message contradicts the PRD's reason for the lock (EARS l.18/187, FR-18)
Fix: Quote the exact message in FR-18 and have the founder confirm it.

**[EARS]** H2: The founder's fixed Hebrew messages exist only in EARS (EARS l.11–18, NFR-6)
Fix: Add the table to NFR-6, or name EARS as the source of truth for UI strings.

### Medium (23)
- **[Decision-readiness]** No open items despite a real-world launch (§10, §11). Fix: reopen them, or list them as accepted risks.
- **[Strategic coherence]** SM-1 and SM-5 have no measurement method or threshold (§9). Fix: list review with target 0; ≤ 15 minutes.
- **[Done-ness]** No Member cap while FR-15 requires an exact minimum (FR-15, NFR-16). Fix: cap or performance limit.
- **[Done-ness]** "Understandable from a screenshot alone" is not testable (FR-16). Fix: name the content rules.
- **[Done-ness]** Reference devices are unnamed (FR-16, NFR-5). Fix: name the model or a dp viewport.
- **[Downstream]** Story sizing is uneven (§8.1). Fix: note an internal split of Story 3.
- **[Adversarial]** M1–M12, detailed in `review-adversarial-general.md`:
  - default Payer ambiguity
  - removing a Member silently changes everyone's Shares
  - unclear tap-budget start point
  - name normalization
  - Amount input grammar
  - reference devices
  - "settled up" shown when there are no Expenses
  - migrations and Auto Backup
  - SM-3 is trivially satisfied
  - whether the PRD or EARS is authoritative
  - unsaved Expense lost when the app is killed
  - no stated reason for the Leftover rule
- **[EARS]** M1: "Description required" message missing from FR-11.
- **[EARS]** M2: Leftover rule for a receiver with no Expenses missing from EARS.
- **[EARS]** M3: FR-8 "set active at any time" has no EARS requirement.
- **[EARS]** M4: NFRs largely absent from EARS (NFR-5, 6, 8, 9).
- **[EARS]** M5: Only 4 of about 13 messages have fixed Hebrew text.

### Low (27)
- **[Rubric]** Six low findings:
  - "Look and feel" is a mood, not an input (§1)
  - SM-2 checks the spec, not the bet
  - the lock message has no text (FR-18)
  - default-Payer edge cases (FR-10)
  - no entry point for the Archive view (FR-6)
  - journey links point to journeys that don't show the action (FR-3, FR-5)
- **[Adversarial]** L1–L7:
  - FR-7 and UJ-1 give a different order of steps
  - archived names can't be reused
  - no limit on Description length
  - thousands separator and ₪ position
  - display time zone
  - layout assumes right-thumb use only
  - "no open assumptions" is overstated
- **[EARS]** L1–L14:
  - §8.2 is out of date and EARS is uncommitted
  - the tie-break is defined informally in EARS
  - the Archive rule sits under the wrong heading
  - test IDs are out of order
  - "Payments" is missing from archive and restore
  - whitespace-only and empty names
  - keeping entered data on screen after an error, and edit validation
  - Expense list display details
  - Payment limits
  - the Category list is missing from EARS
  - the "both apply" removal case is untested
  - the Hebrew term for Member is inconsistent
  - the display order of Transfers is unspecified
  - no test that ₪1,000,000 is accepted

## Mechanical notes
- NFR-17 sits between NFR-7 and NFR-8. Renumber it, or move it to the end of §5.
- Stale boilerplate in §0: it mentions `[ASSUMPTION]` tags and a research section in the addendum, and neither exists.
- Glossary capitalization drifts ("Archived group" / "archived Group"). UI surface names are not in the Glossary.
- NFR-1 never states that tap counting starts after the launcher icon tap.
- Cross-references all resolve. The Assumptions Index is consistent.

## Reviewer files
- `review-rubric.md`
- `review-adversarial-general.md`
- `review-ears-consistency.md`
