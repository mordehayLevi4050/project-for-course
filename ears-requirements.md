# EARS Requirements – GrouPay

## Epic: Shared Expense Splitting

Allow a group's organizer to record shared trip expenses on one phone and get the exact list of transfers that settles the group (for example, a trip where one person pays for the flight, another for the hotel, and a third for the car).

**Source:** aligned with the GrouPay PRD (`_bmad-output/planning-artifacts/prds/prd-groupay-2026-10-26/prd.md`) as of 2026-10-29. Requirement references (FR-N, NFR-N) point to that document.

**Conventions:**
- The app UI is in Hebrew. The quoted messages below are the English reference strings for the tests; the app shows the Hebrew text from the table below. "Member" is always "משתתף" in the UI.
- All amounts are in ₪.
- In requirements and expected results, "A → B ₪N" is shorthand for one transfer line. The app never shows the arrow; it displays the line as "Payment due from A to B ₪N" ("תשלום נדרש מA לB ₪N", FR-16).
- Categories (fixed list): Flight, Hotel, Car, Fuel, Restaurant, Food & drink, Attractions, Other.

**Fixed Hebrew messages** (set by the founder; the app must show exactly this text; same table as PRD NFR-6):

| English reference | Hebrew (shown in app) |
|---|---|
| "A member with expenses in their name cannot be removed" | "לא ניתן להסיר משתתף שיש הוצאה על שמו" |
| "Description required, or choose a category" | "נדרש תיאור או בחירת קטגוריה" |
| "Name required" | "נדרש שם" |
| "Group already exists" | "כבר קיימת קבוצה בשם הזה" |
| "Member already exists" | "כבר יש משתתף בשם הזה" |
| "A group can have at most 10 members" | "קבוצות מוגבלות ל-10 משתתפים" |
| "Add at least two members to record expenses" | "יש להוסיף לפחות שני משתתפים כדי לרשום הוצאות" |
| "Please enter a valid amount" | "סכום לא תקין" |
| "Please choose a category" | "נא לבחור קטגוריה" |
| "No expenses yet" | "עדיין אין הוצאות" |
| "The list of groups will appear here" | "כאן תופיע רשימת הקבוצות" |
| "Everyone is settled up" | "החשבון מאוזן, אין צורך בהעברות" |
| "Payment due from {debtor} to {receiver} ₪N" | "תשלום נדרש מ{debtor} ל{receiver} ₪N" |
| "Make this the active group?" | "להפוך את הקבוצה לקבוצה הפעילה?" |
| "'{name}' will no longer be the active group" | "הקבוצה '{name}' תפסיק להיות הקבוצה הפעילה" |
| "Delete this expense?" | "למחוק את ההוצאה?" |
| "Exit without saving?" | "לצאת ללא שמירה?" |

**Out of scope:** unequal splits, multiple currencies and currency conversion, user login and multi-device sync, deleting a group, expenses without a category (drafts), expense location, receipt photos, text export of the summary, settling through Bit, marking transfers as paid, locking a group, recording payments, a "settled" group status (next version).

---

## Story 1: Create a Group

Covers FR-1 – FR-9.

### Event-Driven Requirements (When)

- **When** the user creates a group with a name, the group will appear on the home page.
- **When** the user adds a member's name to the group, the member will appear in the group's member list.
- **When** the user saves a new group, before any members are added, the app will ask: "Make this the active group?".
- **When** the user confirms making a group active while another group is active, the app will display "'{name}' will no longer be the active group" for the previous group, and only the new group will be active.
- **When** the user declines making a new group active, the current active group (if any) will remain unchanged.
- **When** the user sets an existing, non-archived group as active, it will become the only active group.
- **When** the user unsets the active group, the next launch will open on the group list.
- **When** the user launches the app while an active group is set, the app will open directly on that group's page.
- **When** the user renames a group, the new name will appear on the home page, on the group's page and on its summary.
- **When** the user renames a member, the new name will appear in the member list and on all of that member's expenses, and no member's total paid or received will change.
- **When** the user adds a member to a group that already has expenses, the new member will share all of the group's expenses, including earlier ones.
- **When** the user removes a member who is not the payer of any expense, the member will disappear from the member list and all expenses will be split equally among the remaining members.
- **When** the user archives a group, the group will disappear from the home page and appear in the Archive view.
- **When** the user archives the active group, the group will no longer be active.
- **When** the user restores a group from the Archive view, the group will appear on the home page again with all its members and expenses, and all actions will be available again.

### State-Driven Requirements (While)

- **While** no groups have been created, the home screen will display: "The list of groups will appear here".
- **While** no active group is set, launching the app will show the home page (group list).
- **While** an active group is set, the user can still navigate from the group's page back to the home page and open other groups.
- **While** a group is archived, the user can view its expenses and summary, but cannot add, edit or delete expenses, add, rename or remove members, rename the group, or set it as the active group.
- **While** a group has 10 members, the user cannot add another member.

### Unwanted Behavior Requirements (If)

- **If** the user creates or renames a group with an empty or whitespace-only name, the change will not be made and an error message will be displayed: "Name required".
- **If** the user tries to create or rename a group to a name that already belongs to another group, including an archived group, ignoring leading/trailing spaces and letter case, the change will not be made and an error message will be displayed: "Group already exists".
- **If** the user tries to type a group name longer than 20 characters, the name field will not accept the extra characters; a pasted name is cut to 20 characters; leading and trailing spaces are removed on save. A character is a user-perceived character (an emoji or a letter with niqqud counts as one).
- **If** the user tries to add a member, or rename a member, with an empty or whitespace-only name, the change will not be made and an error message will be displayed: "Name required".
- **If** the user tries to add or rename a member to a name that already exists in the group, ignoring leading/trailing spaces and letter case and excluding the member being renamed, the change will not be made and an error message will be displayed: "Member already exists".
- **If** the user tries to type a member name longer than 10 characters, the name field will not accept the extra characters; a pasted name is cut to 10 characters; leading and trailing spaces are removed on save.
- **If** the user tries to add an eleventh member, the member will not be added and an error message will be displayed: "A group can have at most 10 members".
- **If** the user tries to remove a member who is the payer of at least one expense, the member will not be removed and an error message will be displayed: "A member with expenses in their name cannot be removed".

### Test Cases

| ID | Input | Action | Expected Result |
|---|---|---|---|
| T1.1 | Group name "Trip to Eilat" | Create group | The group appears on the home page |
| T1.2 | Member name "Dana" | Add member | Dana appears in the member list |
| T1.3 | No groups exist | Open home screen | "The list of groups will appear here" is displayed |
| T1.4 | Empty group name | Create group | The group is not created, does not appear in the group list, and "Name required" is displayed |
| T1.5 | "Dana" already in the group | Add member "Dana" | The member is not added, a second "Dana" does not appear in the member list, and "Member already exists" is displayed |
| T1.6 | "Dana" already in the group | Add member " dana " | The member is not added and "Member already exists" is displayed |
| T1.7 | Empty member name | Add member | The member is not added and "Name required" is displayed |
| T1.8 | New group "Budapest", no active group | Finish creating group, confirm "Make this the active group?" | "Budapest" is the active group; relaunching the app opens directly on Budapest's page |
| T1.9 | "Eilat" is active, new group "Budapest" | Finish creating "Budapest", confirm | "'Eilat' will no longer be the active group" is displayed; after confirming, only "Budapest" is active |
| T1.10 | "Budapest" is active | Unset active group, relaunch app | The app opens on the home page |
| T1.11 | "Budapest" is active | From Budapest's page, go back | The home page is shown and other groups can be opened |
| T1.12 | Member "Dana" paid an expense | Rename "Dana" to "Danna" | "Danna" appears in the member list and on Dana's expenses; the transfer amounts are unchanged |
| T1.13 | Dana paid 300; Yossi and Noa paid nothing | Remove "Noa", open summary | Noa disappears from the member list; the summary shows "Yossi → Dana ₪150" |
| T1.14 | Member "Yossi" paid an expense | Remove "Yossi" | Yossi is not removed and "A member with expenses in their name cannot be removed" is displayed |
| T1.15 | "Budapest" is the active group | Archive "Budapest" | Budapest disappears from the home page, appears in the Archive view, and is no longer active |
| T1.16 | "Budapest" is archived | Restore "Budapest" | Budapest appears on the home page with all its members and expenses, and can be edited |
| T1.17 | Group "Budapest" | Rename to "Budapest 2026" | "Budapest 2026" appears on the home page, the group page and the summary |
| T1.18 | Group "Budapest" | Rename to an empty name | The name stays "Budapest" and "Name required" is displayed |
| T1.19 | "Eilat" is active, new group "Budapest" | Finish creating "Budapest", decline | "Eilat" remains the active group |
| T1.20 | Dana paid 300, Yossi paid nothing | Add member "Noa", open summary | Transfers: "Yossi → Dana ₪100", "Noa → Dana ₪100" |
| T1.21 | Group "Budapest" exists | Create group " budapest " | The group is not created, a second "Budapest" does not appear in the group list, and "Group already exists" is displayed |
| T1.22 | "Budapest" is archived | Create group "Budapest" | The group is not created and "Group already exists" is displayed |
| T1.23 | Groups "Budapest" and "Eilat" exist | Rename "Eilat" to "Budapest" | The name stays "Eilat" and "Group already exists" is displayed |
| T1.24 | Group "Budapest" | Rename to "Budapest" (unchanged) and save | The save succeeds and no error is displayed |
| T1.25 | Group "Budapest" | Rename to a whitespace-only name | The name stays "Budapest" and "Name required" is displayed |
| T1.26 | "Budapest" is archived, with expenses | Open "Budapest" from the Archive view; try to add, edit or delete an expense, add, rename or remove a member, rename the group, set it as active | Expenses and the summary are visible; none of the actions is possible |
| T1.31 | Whitespace-only group name | Create group | The group is not created and "Name required" is displayed |
| T1.32 | Groups "Eilat" (active) and "Budapest" exist | Open "Budapest", set it as active, relaunch app | Only "Budapest" is active; the app opens on Budapest's page |
| T1.33 | Group with 10 members | Add member "Gil" | Gil is not added and "A group can have at most 10 members" is displayed |
| T1.34 | Member name field | Type "Alexandrina" (11 characters) | The field shows "Alexandrin": exactly 10 characters are accepted |
| T1.35 | Member name field | Paste a 15-character name | Only the first 10 characters are accepted |
| T1.36 | Group name field | Type a 21-character name | Only the first 20 characters are accepted |
| T1.37 | Member "Dana" | Rename to an 11-character name | Only 10 characters are accepted |
| T1.38 | Member "dana" | Rename to "Dana" | The rename succeeds and no error is displayed |
| T1.39 | Member "Dana" | Rename to an empty name | The name stays "Dana" and "Name required" is displayed |
| T1.40 | No groups | Create group "Budapest" | "Make this the active group?" is asked immediately, before any member is added |

IDs T1.27 – T1.30 were removed on 2026-10-29 together with paid marks and payments.

---

## Story 2: Add Expenses

Covers FR-10 – FR-14.

### Event-Driven Requirements (When)

- **When** the user taps "Add expense", the expense screen will open with the amount field focused and a numeric keypad (with a decimal separator) open.
- **When** the expense screen opens, the payer will default to the current payer of the existing expense with the highest save order in the group; if the group has no expenses, it will default to the earliest-added member still in the group.
- **When** the user leaves the expense screen (new or edit) with unsaved input, the app will ask "Exit without saving?"; confirming discards the input, cancelling returns to the screen with the input intact.
- **When** the user taps a member among the payer options on the expense screen, that member will become the payer and be clearly marked as selected, without closing the keypad.
- **When** the user taps "Save" on a valid expense with an amount, a payer and a category, the expense will be saved exactly once and the app will immediately return to the group page, with the expense at the top of the expense list.
- **When** the user taps "Save" again before the expense screen closes, no additional expense will be created.
- **When** an expense is saved, its recorded date and time will be the time it was saved; it cannot be changed.
- **When** the user taps an expense in the list, an edit screen will open with all of the expense's fields filled.
- **When** the user saves an edited expense, the expense list and the trip total will reflect the change, and the validation rules below apply.
- **When** the user long-presses an expense in the list, or taps "Delete" on the edit screen, a confirmation dialog will be displayed: "Delete this expense?".
- **When** the user confirms the deletion, the expense will be removed from the list and the trip total will be updated; **when** the user cancels, the expense will remain unchanged.

### State-Driven Requirements (While)

- **While** the numeric keypad is open on the expense screen, the payer options, the category options and "Save" will remain visible and tappable; all payer options (up to 10 members) are visible at once with no swipe; if not all category options fit in a grid, they will be shown in a sideways row of at most two pages, and one swipe will show the second page without closing the keypad.
- **While** the group has fewer than two members, "Add expense" will be disabled and the group page will display next to it: "Add at least two members to record expenses".
- **While** the group has no expenses, a message will be displayed: "No expenses yet".
- **While** the group has expenses, the group page will display the trip total, and the expense list will show every expense newest first by save order, each with its payer, amount, category (or description for "Other"), and the date and time it was first saved (editing never changes it).
- **While** an active group is set and the default payer is correct, saving an expense will take at most 4 taps from app launch, not counting typing the amount; each swipe counts as a tap.
- **While** an active group is set and the payer must be changed, saving an expense will take at most 5 taps from app launch, not counting typing the amount; each swipe counts as a tap.

### Unwanted Behavior Requirements (If)

- **If** the user enters an amount that is empty, zero, negative or above ₪1,000,000, the expense will not be saved, the entered data will stay on screen, and an error message will be displayed: "Please enter a valid amount".
- **If** the user tries to type a second digit after the decimal separator, the amount field will not accept it.
- **If** the user saves without choosing a category, the expense will not be saved, the entered data will stay on screen, and an error message will be displayed: "Please choose a category".
- **If** the user chooses the category "Other" with an empty or whitespace-only description, the expense will not be saved, the entered data will stay on screen, and an error message will be displayed: "Description required, or choose a category".

### Test Cases

| ID | Input | Action | Expected Result |
|---|---|---|---|
| T2.1 | Dana, 300, category Hotel | Add expense | The expense appears at the top of the expense list with payer Dana, ₪300, Hotel, and the date and time it was saved |
| T2.2 | Group with two members, no expenses | Open group | "No expenses yet" is displayed |
| T2.3a | Empty amount | Add expense | The expense is not saved, does not appear in the expense list, and "Please enter a valid amount" is displayed |
| T2.3b | Amount 0 | Add expense | The expense is not saved, does not appear in the expense list, and "Please enter a valid amount" is displayed |
| T2.3c | Amount -50 | Add expense | The expense is not saved, does not appear in the expense list, and "Please enter a valid amount" is displayed |
| T2.3d | Amount 1,000,001 | Add expense | The expense is not saved and "Please enter a valid amount" is displayed |
| T2.3e | Amount 1,000,000, category Hotel | Add expense | The expense is saved |
| T2.4 | Type "87.45" | Enter amount | The field shows 87.4 |
| T2.5 | Amount 87.4, no category | Save | The expense is not saved and "Please choose a category" is displayed |
| T2.6 | Amount 50, category Other, empty description | Save | The expense is not saved and "Description required, or choose a category" is displayed |
| T2.7 | Amount 50, category Other, description "Umbrella" | Save | The expense appears in the list showing "Umbrella" |
| T2.8 | Last expense was paid by Motty | Tap "Add expense" | The amount field is focused with the numeric keypad open, and the payer is Motty |
| T2.9 | New group; members added in order Motty, Dana | Tap "Add expense" | The payer is Motty |
| T2.10 | Active group set, last payer correct | Launch app, add 87.4 Food & drink | The expense is saved in at most 4 taps, not counting typing the amount |
| T2.11 | Expense ₪870 | Tap it, change amount to 87, save | The list shows ₪87 and the trip total decreases by ₪783 |
| T2.12 | Expense ₪87 | Long-press it, confirm "Delete this expense?" | The expense is removed and the trip total decreases by ₪87 |
| T2.13 | Expense ₪87 | Long-press it, cancel | The expense remains in the list unchanged |
| T2.14 | Expenses ₪300 and ₪87.4 | Open group | The trip total ₪387.4 is displayed |
| T2.15 | Payer Dana, category Hotel, amount 0 | Save | The expense is not saved; Dana and Hotel remain selected on the screen |
| T2.16 | Dana paid 300; members Dana, Yossi, Noa | Edit the expense to 150, open summary | Transfers: "Yossi → Dana ₪50", "Noa → Dana ₪50" |
| T2.17 | Expense screen open, amount 87.4 typed, keypad open | Tap "Food & drink", tap "Save" | The expense is saved without the keypad being closed first |
| T2.18 | Expense screen open with the system font enlarged so the category grid does not fit, keypad open | Swipe the category row sideways once, tap the last category | The second page shows the remaining categories, there is no third page, the last category can be selected, and the keypad stays open |
| T2.19 | Active group set, last payer correct, category row in its two-page form | Launch app, add 50 with each category in turn, including those on the second page | Every expense is saved in at most 4 taps, counting each swipe as a tap and not counting typing the amount |
| T2.20 | Active group set, last payer Motty | Launch app, tap "Add expense", type 200, tap "Dana", tap "Fuel", tap "Save" | The expense is saved with payer Dana in 4 taps (within the 5-tap budget); the next "Add expense" defaults to Dana |
| T2.21 | Valid expense on screen | Tap "Save" twice quickly | Exactly one expense is added; the app is on the group page |
| T2.22 | Group with one member | Open group | "Add expense" is disabled and "Add at least two members to record expenses" is displayed |
| T2.23 | Amount 50, category Other, description "   " | Save | The expense is not saved and "Description required, or choose a category" is displayed |
| T2.24 | Expense ₪87 | Tap it, change amount to 0, save | The change is not saved and "Please enter a valid amount" is displayed |
| T2.25 | Expenses saved in order A, B, C; then the phone's clock is set back one day; expense D saved | Open group | The list shows D, C, B, A from top to bottom |
| T2.26 | Expenses by Motty then Dana; delete Dana's expense | Tap "Add expense" | The payer is Motty |
| T2.27 | Amount 87 typed on a new expense | Back gesture, confirm "Exit without saving?" | The group page is shown and no expense was added |
| T2.28 | Amount 87 typed on a new expense | Back gesture, cancel | The expense screen is shown with 87 still entered |
| T2.29 | Expense saved at 10:00 | At 12:00, edit its amount and save | The list still shows 10:00 for it |

---

## Story 3: Settle Up

Covers FR-15 – FR-16.

### Event-Driven Requirements (When)

- **When** the user opens the summary, the app will display the group name, the trip total, and the minimum number of transfers that settles the group, with expenses split equally among all members, ordered by debtor name and then receiver name using the alphabetical rule below.
- **When** the app displays a transfer, it will show one line "Payment due from {debtor} to {receiver} ₪N" ("תשלום נדרש מ{debtor} ל{receiver} ₪N"), with no arrow or other direction symbol; each name is isolated for bidirectional display, and a name that does not start with a Hebrew letter is preceded by a hyphen after the prefix ("מ-Dan לדנה", "מדנה ל-Zoe").
- **When** the app computes transfers, it will compute each member's share as the trip total divided by the number of members, rounded down to a multiple of ₪0.10, and each member's balance as what they paid minus the share.
- **When** rounding the share down leaves a leftover, the app will take it off the receivers (members with a positive balance), starting with the receiver who paid the smallest total of expenses; a receiver's balance never goes below zero, and the rest is taken from the receiver who paid the next-smallest total. A debtor's balance is never changed by this step.
- **When** two receivers paid the same total, the receiver whose first expense was saved later will absorb the leftover first, so the one who paid earlier keeps the higher amount. "Earlier" is decided by save order only, never by the phone's clock; editing an expense (including its payer) never changes its save order.
- **When** the app computes transfers, it will compute the minimum number of transfers on the balances after the leftover step; every transfer is a multiple of ₪0.10, and there is no minimum transfer amount.
- **When** the app displays an amount, it will show no decimals when the amount is whole ("₪44") and exactly one decimal otherwise ("₪33.3").
- **When** the app computes transfers, every transfer will go from a member with a negative balance to a member with a positive balance, and no member will both send and receive; only such lists count for the minimum and the tie-break.
- **When** more than one minimal transfer list exists, the app will order each candidate list's transfers by debtor name, then receiver name, and choose the list whose sequence of (debtor, receiver) pairs comes first alphabetically. Names are compared character by character, a name that is the start of a longer name comes first, and characters are ordered: Hebrew letters, then Latin letters A–Z ignoring case, then digits, then the geresh (׳ or '), then any other character by its Unicode value; a final letter counts as its regular form; names still equal under these rules are ordered by their Unicode values. Renaming a member may change the pairs but never the total any member pays or receives.

### State-Driven Requirements (While)

- **While** the group has up to 6 members, the group name, trip total and transfer list will fit on one screen without scrolling at the default font size on the trip phone.
- **While** the group has 7 to 10 members, only the transfer list may scroll; the group name and trip total stay in view.
- **While** the group has fewer than two members, the summary button will be disabled.

### Unwanted Behavior Requirements (If)

- **If** every balance is zero after the leftover step (no transfers are needed), the message "Everyone is settled up" will be displayed.

### Test Cases

| ID | Input | Action | Expected Result |
|---|---|---|---|
| T3.1 | Dana paid 300, Yossi 0, Noa 0 | Open summary | Transfers: "Yossi → Dana ₪100", "Noa → Dana ₪100"; trip total ₪300 |
| T3.2 | Group with one member | Open group | The summary button is disabled |
| T3.3 | Dana paid 100, Yossi paid 100 | Open summary | "Everyone is settled up" is displayed |
| T3.4 | Dana paid 100, Yossi 0, Noa 0 | Open summary | Transfers: "Yossi → Dana ₪33.3", "Noa → Dana ₪33.3" (Dana absorbs the ₪0.1 leftover) |
| T3.5 | Dana paid 87.4, Yossi 0 | Open summary | Transfer: "Yossi → Dana ₪43.7" |
| T3.6 | Members entered in Hebrew: מוטי paid 400, דנה 200, יוסי 0, נועה 0 | Open summary | Exactly these 3 transfers: "יוסי → דנה ₪50", "יוסי → מוטי ₪100", "נועה → מוטי ₪150" |
| T3.7 | Group "Budapest" with transfers | Open summary | The group name "Budapest" and the trip total are displayed |
| T3.8 | Group of 6 members with expenses, default font size on the trip phone | Open summary | The whole summary is visible on one screen without scrolling |
| T3.15 | Dana paid 33.4, Yossi 33.3, Noa 33.3 | Open summary | "Everyone is settled up" is displayed (share ₪33.3; Dana absorbs the ₪0.1 leftover) |
| T3.16 | Dana paid 100.5, Yossi 100 | Open summary | Transfer: "Yossi → Dana ₪0.2" (share ₪100.2) |
| T3.17 | As T3.6 | Open summary, rename "יוסי" to "שי", open summary again | Second summary: "נועה → דנה ₪50", "נועה → מוטי ₪100", "שי → מוטי ₪150"; each member's total paid or received is unchanged |
| T3.18 | Dana paid 101.5, Yossi 100, Noa 100 | Open summary | Transfers: "Yossi → Dana ₪0.5", "Noa → Dana ₪0.5" |
| T3.19 | Dana paid 3, Yossi 0, Noa 0, Avi 0 | Open summary | Transfers: "Yossi → Dana ₪0.7", "Noa → Dana ₪0.7", "Avi → Dana ₪0.7" (share ₪0.7; Dana absorbs the ₪0.2 leftover) |
| T3.20 | Members "Zoe" paid 400, "דנה" 200, "Adam" 0, "יוסי" 0 | Open summary | Exactly these 3 transfers: "יוסי → דנה ₪50", "יוסי → Zoe ₪100", "Adam → Zoe ₪150" (Hebrew names sort before Latin names) |
| T3.31 | Members entered in Hebrew: אבי paid 100.1, גיל 100, בני 0, דוד 0 | Open summary | Exactly these 3 transfers: "בני → אבי ₪0.1", "בני → גיל ₪49.9", "דוד → אבי ₪50" (גיל, who paid less, absorbs the ₪0.1 leftover); no transfer from אבי or גיל |
| T3.32 | Members entered in Hebrew: אברהם paid 60, יצחק 40, יעקב 0 | Open summary | Transfers: "יעקב → אברהם ₪26.7", "יעקב → יצחק ₪6.6" (יצחק, who paid less, absorbs the ₪0.1 leftover) |
| T3.33 | Members entered in Hebrew: אברהם paid 50 (saved first), יצחק paid 50 (saved second), יעקב 0 | Open summary | Transfers: "יעקב → אברהם ₪16.7", "יעקב → יצחק ₪16.6" |
| T3.34 | As T3.33 | Rename "אברהם" to "תום", open summary | Transfers: "יעקב → יצחק ₪16.6", "יעקב → תום ₪16.7"; each member's amount is unchanged |
| T3.35 | Members entered in Hebrew: אבי paid 30.2, בני 10.1, גיל 0, דוד 0 | Open summary | Transfers: "גיל → אבי ₪10", "דוד → אבי ₪10" (share ₪10, leftover ₪0.3: בני's ₪0.1 goes to zero, the remaining ₪0.2 is taken from אבי) |
| T3.37 | Members entered in Hebrew: מוטי paid 400, דנה 200, גיל 0, ג'ני 0 | Open summary | Exactly these 3 transfers: "גיל → דנה ₪50", "גיל → מוטי ₪100", "ג'ני → מוטי ₪150" (the geresh sorts after letters) |
| T3.38 | Members entered in Hebrew: מוטי paid 400, נועה 200, דניאל 0, דני2 0 | Open summary | Exactly these 3 transfers: "דניאל → מוטי ₪100", "דניאל → נועה ₪50", "דני2 → מוטי ₪150" (digits sort after letters) |
| T3.39 | אברהם paid 50 and יצחק paid 50 a few seconds later in the same minute, יעקב 0 | Open summary | Transfers: "יעקב → אברהם ₪16.7", "יעקב → יצחק ₪16.6" |
| T3.40 | As T3.33, then change the phone's time zone | Open summary | The transfers are unchanged |
| T3.43 | Members entered in Hebrew: דנה paid 300, יוסי 0, נועה 0 | Open summary, take a screenshot | The lines read "תשלום נדרש מיוסי לדנה ₪100" and "תשלום נדרש מנועה לדנה ₪100"; no arrow appears |
| T3.44 | Members "Zoe" paid 300, "Adam" 0, "דנה" 0 | Open summary, take a screenshot | The lines read "תשלום נדרש מ-Adam ל-Zoe ₪100" and "תשלום נדרש מדנה ל-Zoe ₪100"; each line's word order is intact |
| T3.45 | יצחק paid 50 first; the phone's clock is then set back one day; אברהם paid 50; יעקב 0 | Open summary | יצחק counts as having paid earlier: transfers "יעקב → אברהם ₪16.6", "יעקב → יצחק ₪16.7" |
| T3.46 | Group of 10 members with expenses, default font size on the trip phone | Open summary | The summary appears within 1 second; the group name and trip total stay visible while the transfer list scrolls |

IDs T3.9 – T3.14, T3.21 – T3.30, T3.36, T3.41 and T3.42 were removed on 2026-10-29 together with paid marks, the lock and payments.

---

## Cross-Cutting Requirements (Ubiquitous)

- The app **shall** work fully with no network connection and make no network calls (NFR-8).
- The app **shall** keep every saved change after the app is closed, killed by the system, or the phone restarts, and every save **shall** be all-or-nothing (NFR-9).
- The app **shall** open the active group's page within 2 seconds of a cold launch, return to the group page within 300 ms of saving an expense, and show the summary of a 10-member group within 1 second (NFR-5).
- The app **shall** show its entire UI in Hebrew with a right-to-left layout, and Latin-script names and amounts **shall** display correctly inside Hebrew text (NFR-6).

| ID | Input | Action | Expected Result |
|---|---|---|---|
| TX.1 | Airplane mode on | Create a group, add members and expenses, open summary | Every action works |
| TX.2 | Group with expenses | Force-stop the app, restart the phone, open the app | All groups, members and expenses are unchanged |
| TX.3 | Active group set, app not running, mid-range phone | Launch app | The active group's page is shown within 2 seconds |
| TX.4 | Valid expense on screen | Tap "Save" | The group page is shown within 300 ms |
| TX.5 | Member names "Dan", "דנה", "Zoe Lee" | Open group page, expense list and summary | All screens are right-to-left; every name and amount displays in the correct order |
