# Transfer Calculation (FR-15 / CAP-15)

## Algorithm

1. **Exact units.** Every Amount is a multiple of ₪0.10, and every step below works in whole tenths, so the calculation is exact.
2. **Share.** The Share is the Trip total divided by the number of Members, rounded down to ₪0.10.
3. **Starting Balance.** For each Member: the sum of the Amounts they paid, minus the Share.
4. **Leftover.** The starting Balances add up to the Leftover, not to zero. The Leftover is taken off the receivers (Members with a positive Balance); debtors are never touched.
   - It is taken first from the receiver who paid the smallest total.
   - If that would push their Balance below zero, it stops at zero, and the rest comes from the receiver with the next-smallest total, and so on.
   - Afterwards the Balances add up to exactly zero.
5. **Equal-total receivers.** When two receivers paid the same total, the Leftover is taken first from the one whose first Expense was saved later.
   - A receiver's first Expense is the one with the lowest save-order number among the Expenses they currently pay for.
   - The device clock is never used here. Editing, including changing the Payer, never changes a save-order number.
6. **Minimal list.** The Transfer list contains the minimum number of Transfers that settles every Balance.
   - Every Transfer goes from a negative Balance to a positive Balance, so no Member both sends and receives.
   - Only lists that follow this rule are candidates for the minimum and for the tie-break.
7. **Tie-break.** When several minimal lists exist:
   - Sort each candidate's Transfers by debtor name, then by receiver name.
   - Choose the list whose sequence of (debtor, receiver) pairs comes first in alphabetical order.
   - The Summary shows the Transfers in this same order.
8. **Rename.** Renaming a Member can change which pairs appear, but never a Balance or what any Member pays or receives in total. The Leftover step uses only amounts and save order, never names.
9. **Empty list.** The list is empty exactly when every Balance is zero; the Summary then shows "Everyone is settled up". There is no minimum Transfer: ₪0.1 is shown.

## Alphabetical order

Names are compared character by character. A name that is the start of a longer name comes first ("דן" before "דנה").

Character order:
1. Hebrew letters, in alphabet order
2. Latin A–Z, ignoring case
3. digits 0–9
4. the geresh (׳ or ')
5. any other character, by Unicode value

A final letter counts as its regular form: ך=כ, ם=מ, ן=נ, ף=פ, ץ=צ. Names that are still equal after these rules are ordered by Unicode value.

## Amount display (whole app)

- Whole amounts have no decimals: "₪44".
- Other amounts have exactly one decimal: "₪33.3".
- Never two decimals. This applies to the Trip total and the Expense list too.

## Implementation note

The minimal list plus the tie-break requires an exhaustive search over the zero-sum partitions of the Balances, comparing every minimal candidate. The greedy "largest debtor pays largest receiver" approach breaks the tie-break and fails EARS T3.6 and T3.31. With at most 10 Members, the exhaustive search fits within the 1-second Summary limit.

## Worked examples

| Paid | Share / Leftover | Transfers |
|---|---|---|
| Dana 300, Yossi 0, Noa 0 | 100 / 0 | Yossi → Dana 100; Noa → Dana 100 |
| Dana 100, Yossi 0, Noa 0 | 33.3 / 0.1, taken from Dana | Yossi → Dana 33.3; Noa → Dana 33.3 |
| Dana 101.5, Yossi 100, Noa 100 | 100.5 / 0 | Yossi → Dana 0.5; Noa → Dana 0.5 |
| אברהם 60, יצחק 40, יעקב 0 | 33.3 / 0.1, taken from יצחק (paid less) | יעקב → אברהם 26.7; יעקב → יצחק 6.6 |
| אברהם 50 (saved 1st), יצחק 50 (saved 2nd), יעקב 0 | 33.3 / 0.1, taken from יצחק (saved later) | יעקב → אברהם 16.7; יעקב → יצחק 16.6 |
| אבי 30.2, בני 10.1, גיל 0, דוד 0 | 10 / 0.3: בני 0.1→0, then 0.2 from אבי | גיל → אבי 10; דוד → אבי 10 |
| מוטי 400, דנה 200, יוסי 0, נועה 0 | 150 / 0 | יוסי → דנה 50; יוסי → מוטי 100; נועה → מוטי 150 |

All amounts are in ₪.
