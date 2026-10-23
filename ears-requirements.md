# EARS Requirements – GrouPay

## Epic: Shared Expense Splitting

Allow a group of people to record shared expenses and see how much each member owes (for example, a trip where one person pays for the flight, another for the hotel, and a third for the car).

**Out of scope:** unequal splits, multiple currencies, user login, editing or deleting expenses.

---

## Story 1: Create a Group

### Event-Driven Requirements (When)

- **When** the user starts a new group, the group will appear on the home page.
- **When** the user adds a member's name to the group, the member will appear in the group's member list.

### State-Driven Requirements (While)

- **While** no groups have been created, the home screen will display: "The list of groups will appear here".

### Unwanted Behavior Requirements (If)

- **If** the user opened a group and did not give it a name, the group will not open and an error message will be displayed: "Name required".
- **If** the user tries to add a member with a name that already exists in the group, the member will not be added and an error message will be displayed: "Member already exists".

### Test Cases

| ID | Input | Action | Expected Result |
|---|---|---|---|
| T1.1 | Group name "Trip to Eilat" | Create group | The group appears on the home page |
| T1.2 | Member name "Dana" | Add member | Dana appears in the member list |
| T1.3 | No groups exist | Open home screen | "The list of groups will appear here" is displayed |
| T1.4 | Empty group name | Create group | The group does not open, does not appear in the group list, and "Name required" is displayed |
| T1.5 | "Dana" already in the group | Add member "Dana" | The member is not added, a second "Dana" does not appear in the member list, and "Member already exists" is displayed |

---

## Story 2: Add Expenses

### Event-Driven Requirements (When)

- **When** a member adds an expense with an amount and a description, the expense will appear in the group's expense list under that member's name.

### State-Driven Requirements (While)

- **While** the group has no expenses, a message will be displayed: "No expenses yet".

### Unwanted Behavior Requirements (If)

- **If** the user enters an amount that is empty, zero or negative, the expense will not be saved and an error message will be displayed: "Please enter a valid amount".

### Test Cases

| ID | Input | Action | Expected Result |
|---|---|---|---|
| T2.1 | Dana, 300, "Hotel" | Add expense | The expense appears in the expense list under Dana |
| T2.2 | Group with no expenses | Open group | "No expenses yet" is displayed |
| T2.3a | Empty amount | Add expense | The expense is not saved, does not appear in the expense list, and "Please enter a valid amount" is displayed |
| T2.3b | Amount 0 | Add expense | The expense is not saved, does not appear in the expense list, and "Please enter a valid amount" is displayed |
| T2.3c | Amount -50 | Add expense | The expense is not saved, does not appear in the expense list, and "Please enter a valid amount" is displayed |

---

## Story 3: Calculate Balances

### Event-Driven Requirements (When)

- **When** the user clicks "Calculate", the app will divide the total expenses equally between all members and display how much each member owes or should receive.

### State-Driven Requirements (While)

- **While** the group has fewer than two members, the "Calculate" button will be disabled.

### Unwanted Behavior Requirements (If)

- **If** all members paid the same amount, the message "Everyone is settled up" will be displayed.

### Test Cases

| ID | Input | Action | Expected Result |
|---|---|---|---|
| T3.1 | Dana paid 300, Yossi 0, Noa 0 | Click "Calculate" | Dana should receive 200, Yossi owes 100, Noa owes 100 |
| T3.2 | Group with one member | Open group | The "Calculate" button is disabled |
| T3.3 | Dana paid 100, Yossi paid 100 | Click "Calculate" | "Everyone is settled up" is displayed |
