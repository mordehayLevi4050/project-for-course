# Future Phases

None of this is built in v1. It is recorded so that v1 does not make it expensive to add later (NFR-11–14). Items that bind v1 are marked **v1 impact**.

## Next version

- **Second currency with a fixed rate.** The first candidate for v1.1. The trip's conversion friction (NFR-7) is input for it.
- **Draft Expenses.** Save an Amount only and add the Category later.
  - A draft is excluded from the settlement until it has a Category, and the Group shows an "incomplete expense" warning while any draft exists.
  - Excluding drafts steers users away from *Other*, which keeps Category analytics accurate.
  - **v1 impact:** "Category required" must be a validation rule, not a structural constraint in the data model.
- **Location per Expense** via Google Maps, viewable on a map.
  - Location permission is optional, and declining it never blocks recording an Expense.
  - Offline, the app stores coordinates; showing place names or a map needs a connection.
- **Text export of the Summary** for Groups too large for one screenshot.
- **Unequal splits.**
  - A Member who joins mid-trip can share earlier Expenses or only later ones (v1 always shares all).
  - A Member who drops out is excluded from later Expenses (v1 only blocks removing a Payer).
- **Settling-up tracking** (was FR-17 to FR-19, removed on 2026-10-29):
  - **Paid mark:** the Organizer marks a Transfer as paid. The mark shows on screenshots.
  - **Lock:** any marked Transfer locks the Group's Members and Expenses. Clearing the last mark unlocks the Group.
  - **Payments:** when a mark is cleared, the app asks *No, marked by mistake* / *Yes, the money was transferred* / *Cancel*. *Yes* records a Payment from the debtor to the receiver for the full Transfer amount.
    - A Payment counts in Balances but not in the Trip total, and has its own section on the Summary.
    - A Payment can be deleted only while the Group is unlocked.
  - **Settled:** a Group is settled when every Transfer is marked, or when no Transfers remain and at least one Payment exists.
  - **Decide before building (validation finding C2):** pick one of two approaches.
    - (a) Snapshot the Transfer list at the first Paid mark, give each snapshot Transfer a stable ID, and have Paid marks reference it.
    - (b) Prove that recomputing after each Payment reproduces the remaining Transfers, and cover that with a property test.
  - Also needed: all-or-nothing saving for clear-mark-plus-Payment, a lock message that names its trigger (a Transfer marked as paid), and IDs for Payments and Paid marks.

## Multi-user phase

- Accounts, a server and sync.
- **Joining:** only registered users can be added to a Group. An unregistered friend gets a signup link via WhatsApp. Each added Member confirms participation.
  - Joining must take almost no effort, because signup friction is where competitors lose users.
- **Permissions:** only the Member who paid an Expense can edit or delete it. In v1 the Organizer can edit or delete anything.
- **Lock:** the Group locks only after each receiver confirms they received the money.
- **Default Payer:** the logged-in user.
- **Save order:** must work across devices.
- **v1 impact:** each of these rules lives in one replaceable place (NFR-14).

## Later

- Spending breakdown by Category
- Settling through Bit
- Hebrew voice entry
- A web version (not committed; depends on the time left before the trip)

## Open for later phases (not blocking v1)

- Long-term positioning: trip hub or group finance?
- Is Bit integration feasible?
- Admin roles in the multi-user phase.
