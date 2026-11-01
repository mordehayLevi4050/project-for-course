# Functional Rules

These are the detailed acceptance rules for each FR. FR-N corresponds to CAP-N in SPEC.md. FR-15 is in `transfer-calculation.md`. The quoted messages are the English test references; the app shows the Hebrew text from `ui-messages.md`.

## Name rules (shared by FR-1, FR-2, FR-3, FR-5)

- Length limits: a Group name is at most 20 characters, a Member name at most 10. A character is a user-perceived character, so an emoji or a letter with niqqud counts as one.
- The field blocks typing beyond the limit. A pasted name is cut to the limit. Leading and trailing spaces are removed on save.
- An empty or whitespace-only name is rejected with "Name required". Nothing is created or changed.
- Duplicate checks ignore leading and trailing spaces and letter case.

## Groups and Members

**FR-1 Create a Group.**
- A new Group appears in the group list right away.
- A name already used by another Group, including an Archived group, is rejected with "Group already exists".
- While no Groups exist, the group list shows "The list of groups will appear here".

**FR-2 Add Members.**
- A new Member appears in the member list right away.
- A name already in the Group is rejected with "Member already exists".
- An 11th Member is rejected with "A group can have at most 10 members".
- A Member added after Expenses exist shares all of the Group's Expenses, including earlier ones.

**FR-3 Rename a Member.**
- The new name shows everywhere, including past Expenses and the Summary.
- Renaming never changes a Balance or what any Member pays or receives in total. It can change which pairs appear in the Transfer list.
- The FR-2 rules apply to the new name. The uniqueness check excludes the Member being renamed, so "dana" → "Dana" is allowed. If the new name is rejected, the old name stays.

**FR-4 Remove a Member.**
- Removing a Member who is the Payer of any Expense is refused with "A member with expenses in their name cannot be removed".
- After a removal, every Expense is split equally among the remaining Members.

**FR-5 Rename a Group.**
- The FR-1 rules apply, compared against all other Groups. Saving a Group under its own current name is not a duplicate.
- If the new name is rejected, the old name stays.

**FR-6 Archive a Group.**
- Archiving hides the Group from the group list. Groups cannot be deleted in v1.
- All Members and Expenses are kept unchanged.
- Archiving the Active group also unsets it as the Active group.
- Archived groups appear in a separate Archive view and can be restored from there.
- An Archived group is read-only. Its Expenses and Summary can be viewed. Its Members, Expenses and name cannot change, and it cannot be set as the Active group. Restoring it brings back every action.
- How each screen looks and behaves for an Archived group is set in EXPERIENCE.md.

## Active group and launch

**FR-7 Offer to set a new Group as active.**
- As soon as a new Group is saved, before any Members are added, the app asks "Make this the active group?".
- If the Organizer confirms while another Group is active, the app first shows "'{name}' will no longer be the active group".
- Declining leaves the current Active group unchanged.

**FR-8 Set or unset the Active group.**
- Any non-archived Group can be set as active, and the Active group can be unset, at any time.
- At most one Group is active at any moment.

**FR-9 Launch.**
- With an Active group set, launch shows that Group's page with no intermediate screen.
- Without one, launch shows the group list.
- From the Active group's page, the group list is always reachable.

## Expenses

**FR-10 Add an Expense.**
- There is one prominent *Add expense* control on the Group page.
- While the Group has fewer than 2 Members, *Add expense* is disabled and the page shows "Add at least two members to record expenses" next to it.
- The screen opens with the Amount field focused and a numeric keypad open, with a decimal separator.
- Entering the Amount, choosing a Category, choosing a Payer and saving never require closing the keypad first.
- **Default Payer:** the current Payer of the Expense with the highest save-order number in this Group, so deletions and Payer edits count. With no Expenses, the default is the earliest-added Member still in the Group.
- **Payer options:** all Members (up to 10) are visible at once as directly tappable options, with no menu and no swipe. The selected one is clearly marked, and one tap selects another Member.
- **Category options:** shown as directly tappable options, normally all at once in a grid. If they don't fit at the required target size (for example on a small screen or with a large font), they sit in a sideways row of at most two pages. One swipe reaches page 2, the keypad stays open, and the swipe counts as a tap.
- **Tap budget:** ≤4 taps from launch with the default Payer and ≤5 with a changed Payer (SPEC Constraints). The UJ-2 reference flow takes 3, or 4 with a swipe.
- **Recorded time:** the time the Expense was first saved. Editing never changes it, and it cannot be set by hand (no back-dating).
- **Unsaved input:** leaving the screen with unsaved input, for example with system Back, asks "Exit without saving?". Confirming discards the input; cancelling keeps it. This dialog is outside the tap budget.
- **Save once:** *Save* on a valid Expense saves it exactly once and immediately returns to the Group page, with the new Expense at the top. A second tap before the screen closes creates nothing. The same applies to saving an edit.

**FR-11 Validate an Expense.** On any failure, the entered data stays on screen.
- An empty, zero or negative Amount, or one above ₪1,000,000, is rejected with "Please enter a valid amount".
- The keypad does not accept a second digit after the decimal separator (₪100.1 can be entered, ₪100.01 cannot).
- No Category → "Please choose a category".
- *Other* with an empty or whitespace-only Description → "Description required, or choose a category".

**FR-12 Expense list.**
- Expenses are listed newest first by save order.
- Each row shows the Payer, Amount, Category (or the Description for *Other*) and the recorded time.
- The Trip total is shown on the Group page.
- With no Expenses, the page shows "No expenses yet".

**FR-13 Edit an Expense.**
- Tapping an Expense opens the edit screen with every field filled. Any field can be changed.
- FR-11 validation applies.
- The list, Trip total and Summary update right away.
- Editing never changes the Expense's save-order number, including when its Payer changes.

**FR-14 Delete an Expense.**
- An Expense can be deleted from the edit screen or by long-pressing it in the list.
- Every deletion asks "Delete this expense?". Cancelling leaves the Expense unchanged.

## Summary

**FR-16 Show the Summary.**
- Available for any Group with at least 2 Members. Below 2, the entry point is disabled.
- Shows the Group name, the Trip total and the Transfer list, in the order set by `transfer-calculation.md`.
- Each Transfer is one line, "תשלום נדרש מ{debtor} ל{receiver} ₪N". The words alone carry the direction; no arrow or symbol is used.
- Each name is isolated for bidirectional display, so a Latin-script or mixed name never reorders the line. A name that doesn't start with a Hebrew letter gets a hyphen after the prefix: "מ-Dan לדנה", "מדנה ל-Zoe".
- **Fit:** for up to 6 Members, the name, total and list fit on one screen with no scroll, on the reference device (Galaxy S25) at the default font size. For 7–10 Members only the list may scroll; the name and total stay in view.
- Someone who has never seen the app understands the Summary from a screenshot alone.
- When there is nothing to settle, it shows "Everyone is settled up".
- A rendered Summary with Hebrew-only, Latin-only and mixed names is checked as part of the tests.
