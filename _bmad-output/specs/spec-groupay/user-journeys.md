# User Journeys

Every v1 journey follows Motty, the Organizer. He uses the phone right-handed, without gloves, usually indoors and seated or standing still. He pays for much of the trip and has the most money to get back. SM-2 is checked by walking UJ-2 and its fuel edge case on the trip phone.

## UJ-1: Set up the trip a month ahead (CAP-1, 2, 7, 8, 9)

1. Create the Group "Budapest December".
2. The app asks "Make this the active group?" Confirm it. If another Group was active, the app first says that Group will stop being active.
3. Add Members: himself, Dana, Yossi, Noa.
4. Record the first Expense, the flights.

From then on, every launch opens straight into the Group. He can still return to the group list, edit other Groups, or unset the Active group at any time.

**Edge case:** typing "Dana" twice is rejected with "Member already exists".

## UJ-2: Grocery checkout, one-handed, offline (CAP-9, 10)

Starting point: the Group is active, there is no signal, and his left hand holds a bag.

1. Launch. The Group page opens.
2. Tap 1: *Add expense*. The Amount field is focused and the keypad is open.
3. Type 87.4. Typing does not count toward the budget.
4. The Payer is already Motty, because he was the last Payer (0 taps).
5. Tap 2: *Food & drink*.
6. Tap 3: *Save*. He is back on the Group page with the Expense at the top.

**Edge cases:**
- **Other:** choosing *Other* requires a Description before saving.
- **Fuel paid by Dana:** *Add expense*, type the amount, *Dana*, *Fuel*, *Save*. That is 4 taps, within the 5-tap budget. The next Expense defaults to Dana as Payer.
- **Two-page Category row:** if *Food & drink* is on page 2, one swipe reveals it. The flow takes 4 taps, within budget.

## UJ-3: Fix a mistake (CAP-3, 4, 13, 14)

- **Wrong amount (₪870 instead of ₪87):** tap the Expense, correct it, save. The list and totals update right away.
- **Duplicate entry:** long-press it, or use *Delete* on the edit screen, then confirm.

**Edge case:** removing Yossi, who paid for fuel, is refused.

## UJ-4: Settle up on the flight home, in airplane mode (CAP-15, 16)

1. Open the Summary. It shows the Group name, the total (₪8,400) and Transfer lines, for example "תשלום נדרש מיוסי לדנה ₪100" and "תשלום נדרש מנועה למוטי ₪1,250".
2. Take one screenshot and send it to the WhatsApp group.

Friends who never installed the app understand the screenshot and transfer the money. The money moves outside the app, and v1 does not track it.
