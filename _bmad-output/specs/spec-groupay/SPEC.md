---
id: SPEC-groupay
companions:
  - glossary.md
  - functional-rules.md
  - transfer-calculation.md
  - ui-messages.md
  - user-journeys.md
  - future-phases.md
  - ../../planning-artifacts/ux-designs/ux-groupay-2026-10-26/DESIGN.md
  - ../../planning-artifacts/ux-designs/ux-groupay-2026-10-26/EXPERIENCE.md
  - ../../planning-artifacts/architecture/architecture-groupay-2026-10-29/ARCHITECTURE-SPINE.md
  - ../../../ears-requirements.md
sources:
  - ../../planning-artifacts/prds/prd-groupay-2026-10-26/prd.md
  - ../../planning-artifacts/prds/prd-groupay-2026-10-26/addendum.md
---

> **Canonical contract.** This SPEC and the files in `companions:` are the complete, preservation-validated contract for what to build, test, and validate. Source documents listed in frontmatter are for traceability — consult them only if you need narrative rationale or prose color this contract intentionally omits.

# GrouPay v1

## Why

**Pain + vision.** On short group trips one friend pays for flights, hotel and car, others pay for meals and fuel, and nobody writes anything down. Settling up then means rebuilding the trip from memory. GrouPay v1 is a Hebrew-first Android app that the group's Organizer runs alone, offline, on one phone. Recording an expense has to be fast enough to do at the checkout, one-handed. At the trip's end the app answers *who transfers how much to whom* in one screenshot for the group's WhatsApp chat. Offline use and no signup are table stakes (Splid already offers both). GrouPay's bet is Hebrew-first RTL plus speed as the core design rule. v1 is a course project, tested on the founder's trip to Budapest in December 2026. It is shaped so that multi-device groups with a server can be added later without a rebuild. Vocabulary is fixed by `glossary.md`. Each CAP-N matches FR-N in `functional-rules.md`, `ears-requirements.md` and the architecture spine.

## Capabilities

- **CAP-1** (FR-1)
  - **intent:** The Organizer can create a named Group for a trip.
  - **success:** The Group appears in the group list right away. An empty name, a duplicate name (including Archived groups; case and outer spaces ignored) or a name over 20 characters is refused, as `functional-rules.md` FR-1 specifies.
- **CAP-2** (FR-2)
  - **intent:** The Organizer can add Members to a Group by typing names.
  - **success:** The Member appears right away. Empty or duplicate names, names over 10 characters and an 11th Member are refused with the fixed messages. A late-added Member shares all existing Expenses.
- **CAP-3** (FR-3)
  - **intent:** The Organizer can rename a Member.
  - **success:** The new name shows everywhere, including past Expenses and the Summary. No Balance changes. A case-only rename is allowed.
- **CAP-4** (FR-4)
  - **intent:** The Organizer can remove a Member who is not the Payer of any Expense.
  - **success:** Removing a Payer is refused with the fixed message. After a removal, every Expense splits equally among the remaining Members.
- **CAP-5** (FR-5)
  - **intent:** The Organizer can rename a Group.
  - **success:** The CAP-1 name rules apply against all other Groups. Saving the Group under its current name succeeds.
- **CAP-6** (FR-6)
  - **intent:** The Organizer can archive a Group to hide it, and restore it later. Groups cannot be deleted.
  - **success:** An Archived group keeps all its data, appears only in the Archive view and is read-only: no edits, cannot be set active. Archiving the Active group unsets it. Restoring brings back every action.
- **CAP-7** (FR-7)
  - **intent:** Right after a new Group is saved, the app offers to make it the Active group.
  - **success:** Confirming while another Group is active first shows the "no longer active" warning. Declining leaves the current Active group unchanged.
- **CAP-8** (FR-8)
  - **intent:** The Organizer can set any non-archived Group as active, or unset the Active group, at any time.
  - **success:** At most one Group is active at any moment. An Archived group cannot become active.
- **CAP-9** (FR-9)
  - **intent:** Launching the app opens the Active group's page directly.
  - **success:** With an Active group set, launch shows its page with no intermediate screen. Without one, launch shows the group list. The group list is always reachable from a Group page.
- **CAP-10** (FR-10)
  - **intent:** The Organizer can record an Expense (Amount, Payer, Category) at the checkout, one-handed.
  - **success:** The UJ-2 flow saves within the NFR-1 tap budget, the new Expense appears at the top of the list, and a double tap on *Save* creates exactly one Expense. *Add expense* is disabled while the Group has fewer than 2 Members. The other rules are in `functional-rules.md` FR-10.
- **CAP-11** (FR-11)
  - **intent:** The app refuses to save an invalid Expense and keeps the entered data on screen.
  - **success:** Each FR-11 case (invalid Amount, a second decimal digit, missing Category, *Other* without a Description) is blocked with its fixed message.
- **CAP-12** (FR-12)
  - **intent:** The Group page lists all Expenses and the Trip total.
  - **success:** Expenses are listed newest first by save order. Each row shows Payer, Amount, Category (or Description for *Other*) and the time it was first saved. An empty Group shows "No expenses yet".
- **CAP-13** (FR-13)
  - **intent:** The Organizer can open an Expense, change any field and save it.
  - **success:** FR-11 validation applies. The list, Trip total and Summary update right away. The recorded time and save order never change.
- **CAP-14** (FR-14)
  - **intent:** The Organizer can delete an Expense from the edit screen or by long-press.
  - **success:** Every deletion asks for confirmation. Cancelling leaves the Expense unchanged.
- **CAP-15** (FR-15)
  - **intent:** The app computes the minimal Transfer list that settles the Group, exactly, in ₪0.10 units.
  - **success:** Every worked example and rule in `transfer-calculation.md` holds, and so does every Story 3 EARS case. The Transfer list is empty exactly when all Balances are zero.
- **CAP-16** (FR-16)
  - **intent:** The Organizer can open a Summary that someone who has never seen the app understands from a screenshot.
  - **success:** It shows the Group name, Trip total and Transfer lines in the "תשלום נדרש מ… ל… ₪N" form, with no arrows and bidi-isolated names. It fits one screen without scrolling for up to 6 Members on the reference device. With nothing to settle it shows "Everyone is settled up". It is disabled below 2 Members.

## Constraints

- **Tap budget (NFR-1):** with an Active group and the correct default Payer, recording an Expense takes ≤4 taps from launch. With a changed Payer it takes ≤5. Each swipe counts as a tap; typing the Amount does not. Any new UI on this path must stay within the budget.
- **Ergonomics (NFR-2–4):** *Add expense* and *Save* sit in the lower half, in right-thumb reach on a 6–6.7" phone. Every target is ≥48×48 dp, and primary actions and Categories are larger. Contrast meets WCAG 2.1 AA.
- **Responsiveness (NFR-5):** cold launch to the Active group page in ≤2 s on the reference device. Saving an Expense returns to the Group page in <300 ms. The Summary of a 10-Member Group appears in ≤1 s.
- **Hebrew-first (NFR-6):** the whole UI is Hebrew with a full RTL layout. Messages use the exact texts in `ui-messages.md`. Latin-script names and amounts render correctly inside RTL text. Direction (who pays whom) is never shown by an arrow or any other direction-dependent symbol.
- **Currency (NFR-7):** ILS only, shown as ₪ with no decimals when whole and one decimal otherwise, never two. The Organizer converts foreign amounts by hand before entering them. Conversion time is outside the tap budget, and a disagreement about an exchange rate does not count as a calculation error.
- **Offline and on-device (NFR-8–10):** every feature works with no network, and the app makes no network calls. All data stays on the device, with no accounts or server. A saved change survives app close, the system killing the app and a reboot. Every save is all-or-nothing.
- **Server-readiness (NFR-11–14):** every Group, Member and Expense has a stable, globally unique ID and carries creation and last-modified times. Features reach data only through one data-access boundary. Rules that will change in the multi-user phase are each defined in one place: edit/delete permission, when a Group may change, the default Payer and the source of save order.
- **Exact money (NFR-15):** amounts are integer tenths of a shekel. The only rounding is the Share, rounded down to ₪0.10.
- **Ordering:** save-order sequence numbers decide list order and calculation tie-breaks. The device clock is never used for ordering.
- **Test coverage (NFR-16):** automated tests cover the Transfer calculation. They include the EARS cases, tenths, Shares that don't divide evenly, the Leftover (one receiver, several receivers, larger than one Balance), equal-total receivers, ₪0.1 Transfers, tie-breaks with Hebrew, Latin and mixed names, groups of 2–10 Members, and the 10-Member timing.
- **Platform (NFR-17):** Android 15 and above only.
- **Devices:** the reference device for layout fit, thumb reach and performance is the Samsung Galaxy S25 (6.2"). The trip phone is the Samsung Galaxy S25 Ultra (6.9"), where SM-2 is walked. A layout that fits the S25 is expected to fit the larger Ultra.
- **Scale:** at most 10 Members per Group. The exhaustive Transfer search depends on this limit.
- **Look and feel:** follow the founder's mockups (`mockups/key-screens.html`, `secondary-screens.html` and `settle-up-screens.html` in the UX folder) as rendered through DESIGN.md and EXPERIENCE.md. The mockups win over any third-party touchstone those docs mention (for example PassportCard).

## Non-goals

- Not a trip planner: no flights, itineraries or bookings.
- Never moves money. It only says who should transfer what. No Bit settlement.
- Does not track whether Transfers were paid. The Group stays editable after the Summary is shared, and any change recomputes the Transfer list in full. Paid marks, locking, Payments and a "settled" status are deferred (`future-phases.md`).
- No Balance table and no breakdown of how a Transfer was calculated. The Transfer list is the answer.
- No backup or restore. Losing the phone loses its data, and that risk is accepted.
- No in-app analytics, tracking, statistics screen or data export.
- Not in v1: Group deletion; unequal or partial splits; a second currency; draft Expenses; location capture; receipt photos; text export of the Summary; back-dating Expenses; contacts or invites; iOS or web.
- Other Members never use the app in v1. They only see the Summary screenshot. The "friends don't keep records" pain is solved in the multi-user phase, not in v1.
- Long-term households and ongoing shared budgets are out of scope.

## Success signal

- **Course (SM-0):** one epic, *Shared Expense Splitting*, with three stories: Story 1 Create a Group (CAP-1–9), Story 2 Add Expenses (CAP-10–14) and Story 3 Settle Up (CAP-15–16). Every constraint applies to all three. All three are implemented and every EARS case in `ears-requirements.md` passes.
- **December 2026 trip:** on the last evening, the Organizer sends one Summary screenshot to the WhatsApp group (SM-5). Friends settle from that screenshot alone (SM-4) and dispute no amount, excluding exchange-rate disagreements (SM-3). A hand calculation from the Expense list gives the same Transfers (SM-1). Walking UJ-2 and its fuel edge case on the trip phone takes ≤4 and ≤5 taps (SM-2).
- **Guardrails, read by hand after the trip from the database copied with `adb` (debuggable release build, AD-19):** fewer than 15% of Expenses edited after saving (SM-C1), and fewer than 10% of Expenses in *Other* (SM-C2).

## Assumptions

- "Samsung 25" is read as the Galaxy S25, not the Galaxy A25.
- The Galaxy S25 replaces the PRD's unnamed "mid-range phone" as the NFR-5 benchmark. The S25 is a flagship, so the timing targets on it are less demanding than the PRD intended.

## Open Questions

- Does the Summary hold 5 Transfers with long, wrapped names on one Galaxy S25 screen (EXPERIENCE.md OQ1)? This now needs a measurement on the device, not a decision.
