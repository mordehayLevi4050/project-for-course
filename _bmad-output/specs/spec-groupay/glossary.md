# Glossary

These terms are binding. In the UI, "Member" is always "משתתף".

- **Organizer:** the one person who operates GrouPay in v1 and records Expenses for the whole Group. Usually also a Member.
- **Group:** a named set of Members and Expenses for one trip or outing. Its name is unique among all Groups, including Archived groups. It has 0–10 Members and zero or more Expenses.
- **Member:** a person in a Group, identified by a name unique within that Group. Members do not need the app in v1.
- **Archived group:** a Group hidden from the group list. It is not deleted and its data is unchanged. It is read-only until restored.
- **Active group:** at most one Group, marked so that the app opens directly into it at launch.
- **Expense:** one payment, made of an Amount, exactly one Payer (a Member), a Category, and a Description when the Category is *Other*. Always split equally among all current Members of its Group.
- **Amount:** a positive sum in ₪ with at most one decimal place, so always a multiple of ₪0.10. Stored exactly as entered.
- **Payer:** the Member who paid an Expense.
- **Category:** one of a fixed list: Flight, Hotel, Car, Fuel, Restaurant, Food & drink, Attractions, Other. *Food & drink* covers groceries, snacks and drinks bought outside restaurants. It is kept separate from *Restaurant* so that a future breakdown by Category is meaningful.
- **Description:** short free text, required only when the Category is *Other*.
- **Save order:** a sequence number each Expense gets when it is first saved. Editing never changes it. It decides list order and tie-breaks; the device clock is never used for either.
- **Trip total:** the sum of all Expense Amounts in a Group.
- **Share:** the Trip total divided by the number of Members, rounded down to a multiple of ₪0.10. For example, ₪100 ÷ 3 = ₪33.3.
- **Leftover:** the Trip total minus Share × the number of Members. Always less than ₪0.10 per Member. Absorbed by the receivers (`transfer-calculation.md`).
- **Balance:** what a Member paid minus the Share, after the Leftover step. Used only inside the calculation; never shown as a table.
- **Summary:** the screen that shows the Group name, the Trip total and the Transfer list.
- **Transfer:** one instruction that Member A pays Member B ₪N, where N is a multiple of ₪0.10. These docs write it as "A → B ₪N" for brevity only. The app never shows the arrow.
- **Transfer list:** the minimal set of Transfers that settles all Balances. Always computed from the Group's current Expenses and Members.
