---
title: "Product Brief: GrouPay"
status: final
created: 2026-10-26
updated: 2026-10-26
---

# Product Brief: GrouPay

## Executive summary

GrouPay is a Hebrew-first mobile app for splitting shared expenses on short group trips and outings. Every time friends travel abroad together, settling up turns into a mess: one person paid for the flights and the hotel, others paid for meals and fuel, nobody kept a record, and the evening after the trip is spent reconstructing who owes whom.

GrouPay makes recording an expense fast enough that people actually do it: at most 4 taps from launch, not counting typing the amount. At the end of the trip, it shows exactly who should transfer how much to whom. The first version runs offline on one device, and the group's organizer records expenses for everyone.

v1 is built as a course project (one epic, three stories) and gets a real test on the founder's trip abroad at the end of December 2026. If the core works, GrouPay expands to multi-device groups, settling up through Bit and Hebrew voice entry, and possibly a broader hub for the whole trip.

## The problem

A few friends fly abroad together for a few days. One of them books the flights, the hotel and the rental car. The others pick up the restaurants and the fuel along the way. Nobody writes anything down as it happens, and by the end of the trip settling up has turned into a tangle. The hard part is not adding up totals. It is working out **who should transfer how much to whom**, and rebuilding from memory and screenshots what everyone paid.

The burden falls on the group's organized member: the person who paid for the big-ticket items and has the most money to get back. Existing apps either add friction to every entry (Splitwise's free tier caps entries per day and shows ads) or are general-purpose trackers not built around a quick trip. When recording feels like a chore, people skip it, and the reckoning gets worse.

## Who this serves

**v1, the organizer:** the one member of the group who keeps track. They pay for much of the trip and record every expense, their own and everyone else's, on their own phone. Success for them is entering an expense in a few seconds while still at the table, and ending the trip with a clear list of transfers.

**Later, every group member:** each friend records their own expenses from their own device. This is where the original pain ("my friends don't keep records") actually gets solved. It needs accounts and sync, and it is deliberately not part of v1.

## The solution

The app opens straight into the trip that is happening now. Adding an expense means typing the amount, confirming the payer (pre-filled with the last payer) and tapping a category from a short fixed list; *Other* asks for a few words. Every expense is split equally among the members. Any expense can be edited or deleted to fix a mistake.

The summary screen answers the one question that actually hurts: **who transfers how much to whom.** It shows a short list of transfers in whole shekels, not a table of balances the group still has to work out. Agorot are rounded in favor of whoever paid. Once everyone has settled up, the group can be **locked**, which freezes the record of the trip. Everything is stored on the phone, so the app works on a mountain road with no signal.

The visual design draws on the feel of PassportCard: travel and financial confidence together. It is inspiration only; v1 does not copy that brand.

## What makes this different

Offline use and no signup are table stakes, not an edge: Splid already offers both for free. GrouPay's bet is narrower:

- **Built for Israelis, Hebrew-first.** The interface is RTL Hebrew from day one, not a translation added later. Research found no Hebrew-first app for splitting expenses.
- **Speed is the core design rule.** Saving an expense takes at most 4 taps from launch, not counting typing the amount. Every feature is judged against that number.
- **Later: settle up through Bit.** The summary turns into actual transfers. Bit collects money but doesn't track who owes whom; GrouPay would close that loop. _Feasibility is unverified: no public third-party API is confirmed._
- **Later: Hebrew voice entry.** Saying "300 שקל דלק, יוסי שילם" records the expense. As far as research found, nobody has shipped this in Hebrew.

Honestly, none of these is a moat. A Hebrew UI can be copied. The real advantage is focus and execution speed: a narrow product built for one audience and one situation, short trips.

## Scope

**v1 must-haves.** These are needed for the December trip test, and all of them fit within the three course stories:

1. **Create a trip group.** Name it and add members by typing their names. One group can be marked *active*, and the app opens straight into it.
2. **Add an expense fast.** Enter the amount, the payer (defaults to the last payer) and a category from a fixed list: flight, hotel, car, fuel, restaurant, food & drink (groceries, snacks, drinks), attractions, other. Choosing *Other* requires a short description. Expenses are split equally among all members. Any expense can be edited or deleted, except in a locked group.
3. **Settle up.** A summary screen lists explicit transfers ("Yossi → Dana ₪100"), not just net balances. Transfers are whole numbers; agorot are rounded in favor of the payer, so the person who paid never comes out short. After settling up, the organizer can lock the group so that no further changes are possible; only the organizer can unlock it.
4. **Work offline.** Data is stored locally on the device, so the app works fully offline.

**Out of v1:** user accounts, a server, multi-device sync, a second currency or exchange rates, unequal splits, category breakdown reports, Bit integration, voice entry.

## Success criteria

**Course (v1 build):** all three stories are implemented and every EARS test case passes.

**Product (December 2026 trip test):**

- Every expense on the trip is recorded in GrouPay, with no fallback to notes or WhatsApp.
- Recording an expense takes at most 4 taps from launch, not counting typing the amount.
- Friends understand the summary screen without explanation and settle up according to it.
- Settling up takes minutes, not an evening.

## Vision

Depth first: GrouPay earns its place as the fastest way for an Israeli group to split trip expenses. Once the core is proven, the next steps are:

1. Multi-user groups, where each friend records from their own phone and joining takes almost no effort.
2. Unequal splits: leave a member out of an expense (for example, someone who skipped a restaurant). Splitting among everyone stays the default.
3. Spending breakdown by category. This is why v1 already separates restaurant from food & drink.
4. Settling up through Bit, straight from the summary screen.
5. Hebrew voice entry.

Breadth may follow: a trip hub that also holds flight tickets and the itinerary.

## Open questions

- **Long-term positioning:** a trip-management hub or financial group management? Neither market is empty. Splitwise and Splid own splitting; TripIt and Wanderlog own trip planning, and Wanderlog reportedly includes expense splitting. The founder is still deciding.
- **Bit integration:** is it feasible? No public third-party API is confirmed.
- **Currency:** the December trip will use one group currency, and members will convert other currencies in their heads. That friction is accepted for the test. A second currency with a fixed rate is the first candidate for v1.1.
- **Group lock in the multi-user phase:** v1 has no accounts, so whoever holds the phone (the organizer) locks and unlocks. Later, only a group admin can approve changes to a locked group. Admin roles still have to be defined.
- **EARS doc alignment:** Story 2 needs categories and editing/deleting expenses, which the EARS doc currently lists as out of scope. Story 3 must change from net balances to explicit transfers and gain the group lock.
