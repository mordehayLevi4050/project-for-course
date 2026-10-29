# Addendum: GrouPay PRD

This addendum holds detail that supports the PRD but belongs downstream (architecture, UX) or falls outside v1 scope. It covers next-version features, settling-up tracking deferred from v1, architecture notes, and the multi-user phase.

## Next-version features raised during PRD discovery

### Draft (uncategorized) Expenses
- The user can save an Expense with an amount only, at the checkout, and add the Category later.
- A draft is **excluded from the settlement** until a Category is chosen, and the Group shows an "incomplete expense" warning while any draft exists.
- **Why exclude rather than include:** in an equal split the Category doesn't change the math, so excluding drafts is a deliberate choice. It steers users toward picking a real Category instead of falling back to *Other*, so that Category analytics (a vision item) stay accurate.
- **Architecture note:** the v1 data model should not make adding this later expensive (for example, requiring a Category at save time should be a validation rule, not a structural constraint).

### Location per Expense
- Capture the location where an Expense was recorded, using Google Maps services, and let the user see Expenses on a map later. Seeing "a gas station" on the map helps the user recall whether it was fuel or a convenience-store purchase.
- Location permission is **optional**; declining it must never block recording an Expense.
- Offline, the phone can store coordinates; resolving them to a place name or map view needs connectivity.

### Text export of the Summary
- For Groups too large to fit the Summary in one screenshot, export the Summary as plain text to paste into a WhatsApp message.

### Member joining mid-trip (with unequal splits)
- When a Member is added to a Group that already has Expenses, the Organizer chooses whether the new Member shares prior Expenses or only Expenses from now on. v1 always includes them in all Expenses.

### Member dropping out (with unequal splits)
- Example: someone booked a flight but ended up not joining. With partial splits, none of the Expenses from that point on are assigned to them. v1 simply blocks removing a Member who is the Payer of any Expense.

## Deferred from v1: settling-up tracking

Until 2026-10-29 the PRD specified this as FR-17 to FR-19; it was then removed from v1 so the first version ships without it. The design to start from in the next version:
- **Paid mark:** the Organizer marks each Transfer on the Summary as paid once the money moves. The marks appear on screenshots.
- **Lock:** while at least one Transfer is marked, the Group's Members and Expenses cannot change. Clearing the last mark unlocks the Group.
- **Payments:** when a mark is cleared, the app asks whether the money really moved (*No, marked by mistake* / *Yes, the money was transferred* / *Cancel*). On *Yes* it records a Payment from the debtor to the receiver for the full Transfer amount. A Payment counts in the Balances but not in the Trip total, and appears in its own section on the Summary. It can be deleted only while the Group is unlocked.
- **Settled status:** a Group counts as settled when every Transfer is marked, or when no Transfers remain and at least one Payment exists.
- **Decide before rebuilding (validation finding C2, 2026-10-27):** the old design defined the Transfer list as always computed, yet required it to stay frozen while any Paid mark existed, and identified Paid marks only by the pair of names. The next version must choose one of two approaches: (a) snapshot the Transfer list at the first Paid mark, give each snapshot Transfer a stable ID and have Paid marks reference it; or (b) prove that recomputing after each Payment always reproduces the remaining Transfers, and cover that with a property test. It also needs: all-or-nothing saving for the clear-mark-plus-record-Payment action, an exact lock message that matches the trigger (a Transfer marked as paid, not "after transfers"), and Payment and Paid-mark IDs (NFR-11).
- **Why defer:** v1 has no data about already-paid money, so after the screenshot is sent the Organizer simply avoids changing the Group (PRD §7). This costs little on a short trip with one settle-up at the end.

## Architecture notes

### Transfer calculation (FR-15)
- The minimum number of Transfers plus the alphabetical tie-break means the app must search all zero-sum partitions of the Balances and compare every minimal candidate list. The classic greedy "largest debtor pays largest receiver" matching does not satisfy the tie-break and fails EARS T3.6 and T3.31.
- With at most 10 Members (FR-2) the exhaustive search fits within the 1-second Summary bound (NFR-5).

## Multi-user phase

### Adding Members
- Only registered users can be added to a Group. An unregistered friend gets a signup link via WhatsApp.
- Each added Member must confirm their participation in the Group.

### Expense permissions
- Only the Member who recorded (paid) an Expense can edit or delete it. In v1 the Organizer can edit or delete any Expense.

### Lock
- The Group locks only after each receiver confirms they received the money.

### Principles (from the brief)
- **Frictionless joining:** joining a Group must take almost no effort, because signup friction is where competitors lose users. The "registered users only" and "confirm participation" steps above must be designed against this principle.
- **Payer default:** the Payer defaults to the logged-in user, unless they say otherwise.
