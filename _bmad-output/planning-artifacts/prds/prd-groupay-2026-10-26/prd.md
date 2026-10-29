---
title: "PRD: GrouPay"
status: final
created: 2026-10-26
updated: 2026-10-29
---

# PRD: GrouPay

## 0. Document Purpose

This PRD defines GrouPay v1: the version built as a course project and tested for real on the founder's trip abroad in December 2026. Its readers are the founder and the course lecturer. It feeds three downstream steps: **architecture** (which must keep a future move to server-side data cheap), **UX design** (where speed and ergonomics are the product's differentiator), and **epics and stories** (one epic, three course stories; see §8).

It builds on the final product brief (`planning-artifacts/briefs/brief-groupay-2026-10-26/brief.md`) and supersedes both the brief and `ears-requirements.md` where they differ (§8.2); for example, the brief's whole-shekel rounding was replaced by exact ₪0.10 Transfers (FR-15). Vocabulary is fixed by the Glossary (§3). Each feature groups its FRs, which are numbered globally. Inferred items, when any are open, are tagged `[ASSUMPTION]` and indexed in §11. Next-version ideas and multi-user rules live in `addendum.md`; competitive research stays in the brief.

## 1. Vision

GrouPay is a Hebrew-first Android app for splitting shared expenses on short group trips. On a typical trip one friend books the flights, the hotel and the car, the others pick up meals and fuel, and nobody writes anything down. Settling up then turns into an evening of rebuilding the trip from memory and screenshots.

GrouPay makes recording an expense fast enough that it actually happens: at the checkout, one-handed, in at most 4 taps from launch. At the end of the trip it answers the one question that hurts, **who transfers how much to whom**, as a short list that fits in one screenshot for the group's WhatsApp chat.

v1 runs entirely on one phone, offline, operated by the group's organizer. It is deliberately shaped so that multi-device groups with a server can be added later without rebuilding it.

**Positioning.** Offline use and no signup are table stakes, not an edge: Splid already offers both for free, and a one-device v1 risks looking like Splid's offline mode. GrouPay's bet is narrower: Hebrew-first RTL for Israeli groups, and speed as the core design rule. None of this is a moat; the advantage is focus and execution speed for one audience in one situation: short trips.

**Look and feel.** The visual design draws on the feel of PassportCard: travel and financial confidence together. This is inspiration only; v1 does not copy that brand.

## 2. Target User

### 2.1 Jobs To Be Done

- **Functional:** record each shared expense in seconds, at the moment it happens, without signal.
- **Functional:** at trip's end, get an exact, minimal list of transfers that the friends accept without argument.
- **Emotional:** stop being "the one who has to chase everyone" and stop worrying about forgetting what I paid.
- **Social:** hand friends a summary that is clear on its own, so settling up is not a debate.

### 2.2 Non-Users (v1)

- Group members other than the Organizer: in v1 they never install or touch the app; they only see a screenshot of the Summary. They become users in the multi-user phase, which is where the original pain ("my friends don't keep records") is solved; v1 deliberately does not solve it.
- Long-term households, roommates or ongoing shared budgets: GrouPay targets short trips and outings.
- iPhone users: v1 targets Android only (§6).

### 2.3 Key User Journeys

The protagonist of every v1 journey is **Motty**, the group's organizer. He uses the app right-handed, usually seated or standing still indoors, without gloves. He pays for much of the trip and has the most money to get back.

- **UJ-1. Motty sets up the trip from home a month ahead.**
  - **Entry state:** at home, booking flights for the group about one month before the trip. No group exists yet for this trip.
  - **Path:** opens GrouPay → creates a group named "Budapest December" → as soon as the group is saved, the app asks *"Make this the active group?"* → he confirms (if another group was active, the app tells him that one will stop being active) → types the member names: himself, Dana, Yossi, Noa → he records the first expense, the flights, right away.
  - **Climax:** from now on every launch opens straight into "Budapest December".
  - **Resolution:** he can still go back to the group list, edit other groups, or unset the active group at any time.
  - **Edge case:** he types "Dana" twice; the app rejects the duplicate and says the member already exists.

- **UJ-2. Motty records a grocery purchase at the checkout, one-handed.**
  - **Entry state:** standing at a grocery checkout abroad, no signal, a bag in his left hand, "Budapest December" set as active.
  - **Path:** opens GrouPay → it opens directly on the group page → taps the large *Add expense* button in the thumb zone *(tap 1)* → the amount field is focused with the numeric keypad open → types 87.4 *(typing, not counted)* → the payer is already "Motty" because he was the last payer *(0 taps)* → taps the category *Food & drink* *(tap 2)* → taps *Save* *(tap 3)*.
  - **Climax:** he is back on the group page and the expense is at the top of the list. Three taps.
  - **Resolution:** phone back in pocket before the cashier finishes bagging.
  - **Edge case:** he picks *Other*; the app then requires a short description before saving.
  - **Edge case:** at the gas station Dana pays for fuel. Motty records it on the spot: *Add expense*, types the amount, taps *Dana* as Payer, taps *Fuel*, taps *Save*. That is 4 taps, within the 5-tap budget for a changed Payer. The next Expense defaults to Dana as Payer.
  - **Edge case:** on a phone where the Category grid does not fit and *Food & drink* is on the second page of the Category row, he swipes the row once to reveal it. The swipe counts as a tap, so the flow takes 4 taps, still within the budget.

- **UJ-3. Motty fixes a mistake, at the checkout or that evening.**
  - **Entry state:** on the group page, either seconds after saving or scrolling the list in the hotel that evening. He notices ₪870 instead of ₪87.
  - **Path:** taps the expense in the list → the edit screen opens with all fields filled → corrects the amount → saves. To remove a duplicate entry instead, he long-presses it in the list (or uses *Delete* on the edit screen) → confirms in a dialog.
  - **Climax:** the list and the totals reflect the correction immediately.
  - **Resolution:** the record is right again, and the Summary at trip's end will be built on correct data.
  - **Edge case:** he tries to remove Yossi, who paid for fuel; the app refuses because Yossi has expenses in his name.

- **UJ-4. Motty settles up on the flight home.**
  - **Entry state:** on the return flight or just after landing, in airplane mode. All trip expenses are recorded.
  - **Path:** opens GrouPay → opens the summary → sees the group name, the trip total (₪8,400) and a short transfer list ("תשלום נדרש מיוסי לדנה ₪100", "תשלום נדרש מנועה למוטי ₪1,250") → takes one screenshot → sends it to the trip's WhatsApp group.
  - **Climax:** friends who never installed GrouPay understand the screenshot without explanation and transfer the money.
  - **Resolution:** the money moves outside the app. v1 does not track who has already paid (§6.2).

## 3. Glossary

- **Organizer** — the one person who operates GrouPay in v1 and records expenses for the whole group. Usually also a Member.
- **Group** — a named set of Members and Expenses for one trip or outing, with a name unique among all Groups, including Archived groups. Has zero to 10 Members and zero or more Expenses.
- **Member** — a person in a Group, identified by a name unique within that Group. Members do not need the app in v1.
- **Archived group** — a Group hidden from the group list. Not deleted; its data is unchanged.
- **Active group** — at most one Group marked so that the app opens directly into it at launch.
- **Expense** — one payment: an Amount, exactly one Payer (a Member), a Category, and, for *Other*, a Description. Always split equally among all Members of its Group.
- **Amount** — a positive sum in shekels (₪) with at most one decimal place, so always a multiple of ₪0.10 (for example ₪87.4), stored exactly as entered.
- **Payer** — the Member who paid an Expense.
- **Category** — one of a fixed list: Flight, Hotel, Car, Fuel, Restaurant, Food & drink, Attractions, Other. *Food & drink* covers groceries, snacks and drinks bought outside restaurants; it is kept separate from *Restaurant* so that future spending breakdowns by Category are meaningful.
- **Description** — short free text; required only when Category is *Other*.
- **Trip total** — the sum of all Expense Amounts in a Group.
- **Share** — the Trip total divided by the number of Members, rounded down to a multiple of ₪0.10 (₪100 ÷ 3 gives ₪33.3).
- **Leftover** — the Trip total minus Share × number of Members: what rounding the Share down leaves uncovered, always less than ₪0.10 per Member. Absorbed by the receivers (FR-15).
- **Balance** — for a Member, what they paid minus the Share, after the Leftover is taken off the receivers (FR-15). Internal to the calculation; not shown as a table.
- **Summary** — the screen showing the Group name, Trip total and the Transfer list.
- **Transfer** — one instruction that Member A pays Member B ₪N, where N is a multiple of ₪0.10. This PRD writes it as "A → B ₪N" for brevity only; the app never displays the arrow and shows each Transfer as defined in FR-16.
- **Transfer list** — the minimal set of Transfers that settles all Balances. Always computed from the Group's current Expenses and Members.

## 4. Features

### 4.1 Groups and Members

**Description:** The Organizer creates a Group per trip, names it, and adds Members by typing their names. Groups appear on the home screen (the group list). Members can be renamed and, when they have no Expenses as Payer, removed. Realizes UJ-1, UJ-3.

#### FR-1: Create a Group
The Organizer can create a Group by giving it a name. Realizes UJ-1.
- A new Group appears in the group list immediately.
- A Group name is at most 20 characters. A character is a user-perceived character, so an emoji or a letter with niqqud counts as one. The field blocks input beyond the limit, a pasted name is cut to the limit, and leading and trailing spaces are removed on save.
- An empty or whitespace-only name is rejected with "Name required", and no Group is created.
- A name that already belongs to another Group, including an Archived group, is rejected with "Group already exists", and no Group is created. The comparison ignores leading/trailing spaces and letter case.
- While no Groups exist, the group list shows "The list of groups will appear here".

#### FR-2: Add Members by name
The Organizer can add Members to a Group by typing a name. Realizes UJ-1.
- The new Member appears in the Group's member list immediately.
- A name that already exists in the Group is rejected with "Member already exists". The comparison ignores leading/trailing spaces and letter case.
- An empty or whitespace-only name is rejected with "Name required".
- A Member name is at most 10 characters. A character is a user-perceived character, so an emoji or a letter with niqqud counts as one. The field blocks input beyond the limit, a pasted name is cut to the limit, and leading and trailing spaces are removed on save.
- A Group has at most 10 Members. Adding an eleventh is rejected with "A group can have at most 10 members", and no Member is added.
- A Member added after Expenses exist shares all of the Group's Expenses, including earlier ones (equal split).

#### FR-3: Rename a Member
The Organizer can rename a Member of a Group. Realizes UJ-3.
- The new name appears everywhere the Member is shown, including past Expenses and the Summary.
- Renaming never changes any Balance, or the total that any Member pays or receives. It can change which pairs appear in the Transfer list (FR-15).
- The empty-name, uniqueness and 10-character rules of FR-2 apply to the new name; an empty or whitespace-only name is rejected with "Name required" and the Member keeps their current name. The uniqueness check excludes the Member being renamed, so changing only letter case ("dana" to "Dana") is allowed.

#### FR-4: Remove a Member
The Organizer can remove a Member from a Group only if that Member is not the Payer of any Expense. Realizes UJ-3.
- Removing a Member who is a Payer is refused with "A member with expenses in their name cannot be removed".
- After a removal, every Expense is split equally among the remaining Members.

#### FR-5: Rename a Group
The Organizer can rename a Group. Realizes UJ-1.
- An empty or whitespace-only name is rejected with "Name required", and the Group keeps its current name.
- The uniqueness and 20-character rules of FR-1 apply to the new name, compared against all other Groups. Saving a Group under its own current name is not a duplicate.

#### FR-6: Archive a Group
The Organizer can archive a Group, which hides it from the group list. Groups cannot be deleted in v1.
- An Archived group keeps all its Members and Expenses unchanged.
- Archiving the Active group also unsets it as the Active group.
- Archived groups can be viewed in a separate Archive view and restored to the group list.
- An Archived group is read-only until restored: its Expenses and Summary can be viewed, but Members, Expenses and the Group name cannot be changed, and it cannot be set as the Active group. Restoring it brings back all actions.

**Out of Scope:** deleting a Group; choosing Members from contacts, inviting registered users, members confirming participation (multi-user phase; see addendum).

### 4.2 Active Group and Launch

**Description:** Speed starts at launch. If an Active group is set, the app opens directly on that Group's page; otherwise it opens on the group list. Realizes UJ-1, UJ-2, UJ-4.

#### FR-7: Offer to set a new Group as active
As soon as a new Group is saved, before any Members are added, the app asks "Make this the active group?". Realizes UJ-1.
- If the Organizer confirms and another Group is already active, the app shows "'{name}' will no longer be the active group" before applying the change.
- Declining leaves the current Active group unchanged.

#### FR-8: Set or unset the Active group at any time
The Organizer can set any non-archived Group as the Active group, or unset the Active group, at any time. Realizes UJ-1.
- At most one Group is active at any moment.
- An Archived group cannot be set as the Active group (FR-6).

#### FR-9: Launch into the Active group
When an Active group is set, launching the app shows that Group's page with no intermediate screen. Realizes UJ-2.
- When no Active group is set, launching shows the group list.
- From the Active group's page the Organizer can always navigate back to the group list and open other Groups.

### 4.3 Expenses

**Description:** Adding an Expense is the most frequent action and the core of the product. Every Expense is split equally among all current Members. Realizes UJ-1, UJ-2, UJ-3.

#### FR-10: Add an Expense fast
The Organizer can add an Expense to a Group from a single prominent *Add expense* control on the Group page. Realizes UJ-2.
- While the Group has fewer than two Members, *Add expense* is disabled and the Group page shows "Add at least two members to record expenses" next to it. Removing a Member never leaves an Expense without its Payer (FR-4), so a Group with Expenses always has at least one Member.
- The Expense screen opens with the Amount field focused and a numeric keypad (with a decimal separator) open.
- Payer defaults to the current Payer of the existing Expense with the highest save-order number in this Group (so deletions and Payer edits are taken into account). When the Group has no Expenses, the default is the earliest-added Member still in the Group, which is usually the Organizer.
- Members are shown as directly tappable Payer options on the Expense screen, the same way as Categories: no extra menu to open, the selected Payer is clearly marked, and one tap selects another Member. All Members of the Group (up to 10) are visible at once, with no swipe needed to reach any of them; how that fits beside the keypad and the Categories is a UX decision. The keypad stays open.
- Changing the Payer adds one tap: an Expense paid by someone other than the default Payer takes at most 5 taps from launch in total, including any swipe needed to reach the Category (NFR-1).
- An Expense's recorded time is the time it was first saved (its creation time, NFR-12). Editing never changes it, and it cannot be set by hand: v1 has no back-dating, so an Expense entered late shows the time it was entered.
- Leaving the Expense screen (new or edit) with unsaved input, for example with the system Back gesture, asks "Exit without saving?". Confirming discards the input; cancelling returns to the screen with the input intact. This dialog is not part of the normal flow and does not count toward the tap budget (NFR-1).
- Categories are shown as directly tappable options on the Expense screen, with no extra menu to open. Normally all Categories are visible at once, in a grid. If they don't all fit at the required touch-target size (NFR-3), for example on a small screen or with an enlarged font, they sit in a sideways row of at most two pages: one swipe moves from the first page to the second, and the keypad stays open while swiping. A swipe counts as a tap toward the tap budget (NFR-1).
- Entering the Amount, choosing a Category and saving never require dismissing the keypad first; Categories and *Save* stay reachable while the keypad is open. The exact layout is a UX decision.
- From launch with an Active group set and a correct default Payer, saving takes at most 4 taps, excluding typing the Amount and counting each swipe as a tap (the reference flow in UJ-2 takes 3, or 4 when one swipe is needed to reach the Category).
- Tapping *Save* on a valid Expense saves it exactly once and immediately returns to the Group page, where the new Expense is shown at the top of the list. A second tap on *Save* before the screen closes creates nothing. The same applies to saving an edit (FR-13).

#### FR-11: Validate an Expense
The app refuses to save an invalid Expense and keeps the entered data on screen.
- An empty, zero or negative Amount, or one above ₪1,000,000, is rejected with "Please enter a valid amount".
- An Amount with more than one decimal place cannot be entered: the keypad does not accept a second digit after the decimal separator (₪100.1 can be entered, ₪100.01 cannot).
- A Category is required; saving without one shows "Please choose a category".
- Category *Other* requires a non-empty Description; a whitespace-only Description counts as empty. Saving without one shows "Description required, or choose a category".

#### FR-12: View the Expense list
The Group page lists all Expenses, newest first by save order (FR-15), each showing Payer, Amount, Category (or Description for *Other*), and the Expense's recorded time (FR-10).
- While the Group has no Expenses, the Group page shows "No expenses yet".
- The Group page shows the Trip total.

#### FR-13: Edit an Expense
The Organizer can tap an Expense to open it in an edit screen with all fields filled, then change any field and save. Realizes UJ-3.
- FR-11 validation applies.
- The list, Trip total and Summary reflect the change immediately.

#### FR-14: Delete an Expense
The Organizer can delete an Expense, either from the edit screen or by long-pressing it in the list. Realizes UJ-3.
- Every deletion requires confirmation in a dialog ("Delete this expense?"); cancelling leaves the Expense unchanged.

**Out of Scope:** unequal or partial splits, a second currency, uncategorized draft Expenses, location capture, receipt photos (see §6.2 and the addendum).

### 4.4 Summary and Settling Up

**Description:** The Summary answers "who transfers how much to whom" in a form that survives being screenshotted into WhatsApp. The money itself moves outside the app, and v1 does not track who has paid. Realizes UJ-4.

#### FR-15: Compute the Transfer list
The app computes the Transfer list from all Expenses and Members of the Group. Realizes UJ-4.
- Every Amount is a multiple of ₪0.10 (FR-11), and every step below works in whole multiples of ₪0.10, so the calculation is exact.
- The Share is the Trip total divided by the number of Members, rounded down to a multiple of ₪0.10. For example, ₪100 ÷ 3 gives a Share of ₪33.3.
- Each Member's starting Balance is the sum of the Amounts they paid, minus the Share.
- Because the Share is rounded down, the starting Balances add up to the Leftover instead of zero. The Leftover is taken off the receivers (Members with a positive starting Balance); a debtor's Balance is never changed by this step. It is taken first from the receiver who paid the smallest total of Expense Amounts. If that would bring their Balance below zero, it stops at zero and the rest is taken from the receiver who paid the next-smallest total, and so on. After this step the Balances add up to exactly zero.
- When two receivers paid the same total, the one who paid earlier keeps the higher amount: the Leftover is taken first from the receiver whose first Expense was saved later. "Earlier" means earlier in save order: every Expense gets a save-order sequence number when it is first saved, and the phone's clock is never used for this comparison, so a wrong clock or a time-zone change cannot affect it. A receiver's first Expense is the one with the lowest sequence number among the Expenses they are currently the Payer of. Editing an Expense, including changing its Payer, never changes its sequence number. (Every receiver is the Payer of at least one Expense, since a positive Balance requires having paid more than the Share.)
- The Transfer list contains the minimum number of Transfers that settles all Balances.
- Every Transfer goes from a Member whose Balance is negative to a Member whose Balance is positive. No Member both sends and receives, so a Member who is owed money is never told to pay. Only lists that follow this rule are candidates for the minimum and for the tie-break below.
- When more than one minimal Transfer list exists, the app chooses by the alphabetical order of Member names: the debtor who comes first alphabetically pays the receiver who comes first alphabetically, and so on. Precisely: order each candidate list's Transfers by debtor name, then receiver name, and choose the list whose sequence of (debtor, receiver) pairs comes first.
- Alphabetical order compares names character by character, and a name that is the start of a longer name comes first ("דן" before "דנה"). The order of characters is: Hebrew letters in alphabet order, then Latin letters A–Z ignoring letter case, then digits 0–9, then the geresh (׳ or '), then any other character by its Unicode value. A final letter counts as the same letter in its regular form (ך=כ, ם=מ, ן=נ, ף=פ, ץ=צ). Names that are still equal under these rules are ordered by their Unicode values.
- Renaming a Member can change which pairs appear in the Transfer list, but never any Balance or the total that any Member pays or receives (the Leftover step uses amounts and times, never names).
- The Transfer list is empty exactly when every Balance is zero; that is the "Everyone is settled up" case (FR-16). There is no minimum Transfer amount: a Transfer of ₪0.1 is shown.
- Amounts are shown without decimals when whole ("₪44") and otherwise with exactly one decimal ("₪33.3"), never with two. This applies to every amount in the app, including the Trip total and the Expense list.
- Worked examples (in the "A → B ₪N" notation of §3; FR-16 defines how the app displays them):
  - Dana paid ₪300, Yossi and Noa paid ₪0 → "Yossi → Dana ₪100" and "Noa → Dana ₪100".
  - Dana paid ₪100, Yossi and Noa paid ₪0 → Share ₪33.3, Leftover ₪0.1 absorbed by Dana → "Yossi → Dana ₪33.3" and "Noa → Dana ₪33.3".
  - Dana paid ₪101.5, Yossi and Noa paid ₪100 each → "Yossi → Dana ₪0.5" and "Noa → Dana ₪0.5".
  - Two receivers, different totals: אברהם (Avraham) paid ₪60, יצחק (Yitzhak) ₪40, יעקב (Yaakov) ₪0 → Share ₪33.3, Leftover ₪0.1 taken from יצחק, who paid less → "יעקב → אברהם ₪26.7", "יעקב → יצחק ₪6.6".
  - Two receivers, equal totals: אברהם paid ₪50 (saved first), יצחק paid ₪50 (saved second), יעקב ₪0 → Leftover ₪0.1 taken from יצחק, whose Expense was saved later → "יעקב → אברהם ₪16.7", "יעקב → יצחק ₪16.6".
  - Leftover larger than one receiver's Balance: אבי paid ₪30.2, בני ₪10.1, גיל and דוד ₪0 → Share ₪10, Leftover ₪0.3; בני's ₪0.1 goes to zero and the remaining ₪0.2 is taken from אבי → "גיל → אבי ₪10", "דוד → אבי ₪10".
  - Tie-break, with names entered in Hebrew: מוטי (Motty) paid ₪400, דנה (Dana) ₪200, יוסי (Yossi) and נועה (Noa) ₪0 → "יוסי → דנה ₪50", "יוסי → מוטי ₪100", "נועה → מוטי ₪150".

#### FR-16: Show the Summary
The Organizer can open the Summary of any Group with at least two Members. Realizes UJ-4.
- The Summary shows the Group name, the Trip total and the Transfer list.
- Each Transfer is shown as one line in the form "תשלום נדרש מ{debtor} ל{receiver} ₪N" (EARS reference: "Payment due from {debtor} to {receiver} ₪N"). The direction is carried by the words only; no arrow or other direction symbol is used.
- Each Member name in a Transfer line is isolated for bidirectional display, so a Latin-script or mixed name never reorders the line. When a name does not start with a Hebrew letter, a hyphen follows the prefix ("מ-Dan לדנה", "מדנה ל-Zoe").
- For groups of up to 6 Members, the Group name, Trip total and Transfer list fit on one phone screen without scrolling, on the founder's trip phone at the default font size. For 7 to 10 Members, only the Transfer list may scroll; the Group name and Trip total stay in view.
- The Summary is understandable from a screenshot alone, by someone who has never seen the app.
- Transfers are shown in the FR-15 order: by debtor name, then receiver name, under its alphabetical rule.
- When no Transfers are needed, the Summary shows "Everyone is settled up".
- With fewer than two Members, the entry point to the Summary is disabled.

**Out of Scope:** marking Transfers as paid, locking the Group while settling up, recording Payments, and a "settled" status (next version; see `addendum.md`); text export of the Summary; settling through Bit; recipient confirmation of receipt (multi-user phase).

## 5. Cross-Cutting Non-Functional Requirements

### 5.1 Speed and Ergonomics (the differentiator)

- **NFR-1 Tap budget:** recording an Expense takes at most 4 taps from launch, excluding typing the Amount and counting each swipe as a tap, when an Active group is set and the default Payer is correct (FR-10). When the Payer must be changed, at most 5 taps. Any new v1 UI on this path must stay within the budget.
- **NFR-2 Right-thumb zone:** primary actions (*Add expense*, *Save*) sit in the lower half of the screen, reachable by a right thumb on a typical 6–6.7" Android phone held in one hand.
- **NFR-3 Touch targets:** every tappable control is at least 48×48 dp; primary actions and Category options are larger than that minimum.
- **NFR-4 Contrast:** text and controls meet WCAG 2.1 AA contrast. No dedicated low-vision mode is required.
- **NFR-5 Responsiveness:** cold launch to the Active group page within 2 seconds on a mid-range Android phone; saving an Expense returns to the Group page with no perceptible delay (under 300 ms); the Summary of a 10-Member Group appears within 1 second.

### 5.2 Hebrew-First

- **NFR-6:** the entire UI is in Hebrew with a full right-to-left layout from day one. Amounts and Member names in Latin script display correctly inside RTL text. The user-facing messages quoted in this PRD are shown in Hebrew; the English strings are the EARS test references. Direction (who pays whom) is never conveyed by an arrow or other symbol whose meaning depends on text direction. A rendered Summary screenshot with Hebrew-only, Latin-only and mixed Member names is checked as part of the tests (FR-16).

  Fixed message texts (set by the founder on 2026-10-26 and 2026-10-29; the app shows exactly this Hebrew text):

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
  | "Payment due from {debtor} to {receiver} ₪N" | "תשלום נדרש מ{debtor} ל{receiver} ₪N" (FR-16) |
  | "Make this the active group?" | "להפוך את הקבוצה לקבוצה הפעילה?" |
  | "'{name}' will no longer be the active group" | "הקבוצה '{name}' תפסיק להיות הקבוצה הפעילה" |
  | "Delete this expense?" | "למחוק את ההוצאה?" |
  | "Exit without saving?" | "לצאת ללא שמירה?" |

  "Member" is always "משתתף" in the UI.
- **NFR-7:** all amounts display with the ₪ symbol, with no decimals when whole and one decimal otherwise (FR-15). v1 has a single currency, ILS. Currency conversion stays outside the app in v1. On the December trip to Budapest, spending is in forints or euros, and the Organizer converts each Amount to shekels before entering it. This is an accepted cost of the test: conversion time is not counted in the tap budget (NFR-1), and a disagreement about an exchange rate is not a calculation error under SM-3. How much friction conversion causes on the trip is input for the second-currency feature (§6.2).

### 5.3 Offline and Data Durability

- **NFR-8:** every v1 feature works with no network connection at all. The app makes no network calls.
- **NFR-9:** a saved change is never lost: data survives closing the app, the app being killed by the system, and a phone restart. Every save is all-or-nothing: if it is interrupted, either the whole change is stored or none of it is.
- **NFR-10:** all data is stored only on the device. v1 has no accounts and no server.

### 5.4 Server-Readiness

v1 is local-only, but the data must be shaped so that a server, accounts and multi-device sync can be added later without migrating or reinterpreting existing trip data.

- **NFR-11:** every Group, Member and Expense has a stable, globally unique identifier that does not depend on the device or on list position.
- **NFR-12:** every record carries creation and last-modification times.
- **NFR-13:** features reach data through a single data-access boundary, so a remote store or sync can be introduced behind it without changing feature behavior.
- **NFR-14:** rules that will differ in the multi-user phase (who may edit or delete an Expense, when a Group may be changed, default Payer, and the source of Expense save order, which in the multi-user phase must work across devices) are each defined in one place, so they can be replaced rather than rewritten.

### 5.5 Calculation Correctness

- **NFR-15:** money is never represented in a way that introduces rounding error: every amount is held as a whole number of tenths of a shekel (₪0.10). The only rounding is the Share, rounded down to ₪0.10, with the Leftover absorbed by the receivers (FR-15).
- **NFR-16:** the Transfer calculation is covered by automated tests, including the EARS cases, uneven Amounts with tenths, Shares that don't divide evenly, a Leftover with one and with several receivers, a Leftover larger than one receiver's Balance, receivers with equal totals, Transfers of ₪0.1, ties between minimal lists (with Hebrew, Latin and mixed names), and groups of 2 to 10 Members, including the 10-Member response time (NFR-5).

### 5.6 Platform

- **NFR-17:** v1 runs on Android 15 and above. Other platforms are not supported in v1.

## 6. Scope

### 6.1 In Scope (v1)

- Groups, Members by typed name, rename and conditional removal (§4.1).
- Active group and launch straight into it (§4.2).
- Add, edit and delete Expenses with fixed Categories and equal split (§4.3).
- Summary with minimal Transfers in multiples of ₪0.10, readable in RTL from a screenshot (§4.4).
- Android 15 and above, Hebrew RTL, fully offline (§5).

### 6.2 Out of Scope for v1

Deferred to the next version (detail in `addendum.md`):

- **Draft Expenses** with no Category, excluded from the calculation and flagged as incomplete, to steer users away from *Other*.
- **Location per Expense** via Google Maps, viewable on a map; location permission optional.
- **Text export** of the Summary for WhatsApp, for groups too large for one screenshot.
- **Unequal splits**, including choosing whether a late-joining Member shares earlier Expenses and handling a Member who drops out.
- **Second currency** with a fixed rate (first candidate for v1.1).
- **Settling-up tracking:** Paid marks on Transfers, locking the Group while money is moving, keeping paid money as Payments, and a "settled" status. Deferred on 2026-10-29; the earlier design and the open question it raised are kept in `addendum.md`.

Later phases:

- **Multi-user groups:** accounts, server, sync, WhatsApp signup links, participation confirmation, payer-only editing, lock on recipient confirmation.
- **Other later features:** spending breakdown by Category, settling through Bit, Hebrew voice entry.
- **Web version:** depends on the time left before the December trip once v1 is done; not committed.

## 7. Non-Goals

- GrouPay v1 is not a trip planner. It holds no flights, itineraries or bookings.
- It does not move money; it only says who should transfer what.
- It has no backup or restore in v1. Data lives only on the phone (NFR-10), so losing the phone loses its Groups; this risk is accepted for the test.
- It shows no table of Balances and no breakdown of how a Transfer was calculated. The Transfer list is the answer. If a friend questions an amount, the Organizer answers from the Expense list; the risk that this leads to disputes is accepted for the test (SM-3, SM-4).
- It does not track whether Transfers were paid. The Group stays editable after the screenshot is sent, and any change recomputes the Transfer list in full, without regard to money already transferred. Once friends start paying, the Organizer avoids changing the Group; a late correction is settled by hand among the friends.
- It has no in-app analytics or tracking; success is measured by hand after the trip.
- It does not try to compete on currencies, receipt scanning or cross-platform reach in v1.

## 8. Delivery Structure and Course Alignment

### 8.1 Epic and Stories

One epic, **Shared Expense Splitting**, with three course stories:

| Story | Covers | FRs |
|---|---|---|
| Story 1: Create a Group | Groups, Members, Active group, launch, archive | FR-1 – FR-9 |
| Story 2: Add Expenses | Add, validate, list, edit, delete | FR-10 – FR-14 |
| Story 3: Settle Up | Transfer list, Summary | FR-15 – FR-16 |

The NFRs in §5 apply to all three stories.

### 8.2 Changes Applied to `ears-requirements.md`

The EARS document predates the brief and this PRD. To keep "every EARS test case passes" meaningful, it was updated on 2026-10-26 and 2026-10-29 with these changes:

- Removed "editing or deleting expenses" from out of scope; added requirements and tests for FR-13 and FR-14.
- Story 2: Expenses have a Payer and a Category, with Description only for *Other* (T2.1 input changed from "Hotel" as description to Category *Hotel*). Added the Category and *Other* validations.
- Story 1: added the Active group, rename, removal and archive requirements.
- Story 3: replaced "how much each member owes or should receive" with the Transfer list (T3.1 becomes two Transfers, see FR-15); added the rounding requirements; renamed "Calculate" to the Summary entry point.
- 2026-10-29: removed the Paid mark, lock, Payment and settled-group requirements and their tests, including the lock message (deferred, §6.2). Added the Transfer display "Payment due from A to B ₪N" with RTL screenshot tests, the fixed Hebrew message table (NFR-6), Payer selection and the 5-tap budget, save-once, the 2–10 Member and name-length limits, save-order tie-break and list order, FR-8 "set active at any time", the precise tie-break definition, and a cross-cutting section for NFR-5, 6, 8 and 9.

## 9. Success Metrics

**Course**
- **SM-0:** all three stories implemented and every (updated) EARS test case passes. Validates FR-1 – FR-16.

**Primary (December 2026 trip)**
- **SM-1 Calculation completeness:** every Expense recorded in the Group is counted in the Transfer list. Checked by hand after the trip: an independent calculation from the Expense list gives the same Transfers. Whether expenses went unrecorded cannot be measured and is not a metric. Validates FR-10, FR-15, NFR-8.
- **SM-2 Speed:** recording an Expense takes at most 4 taps from launch with the default Payer, and at most 5 with a changed Payer, excluding typing the Amount. Checked by walking the UJ-2 flow and its fuel edge case on the trip phone. Validates FR-9, FR-10, NFR-1.
- **SM-3 Accuracy:** no friend disputes an amount on the Summary (exchange-rate disagreements excluded, NFR-7). Validates FR-15, NFR-15.
- **SM-4 Clarity:** friends settle up from the screenshot alone, with no explanation needed. Validates FR-16.

**Secondary**
- **SM-5 Same-evening settle-up:** the Summary screenshot is sent on the last evening of the trip, before the friends go home. Validates FR-15, FR-16.

**Counter-metrics (do not optimize)**
- **SM-C1 Edits after save:** the number of Expenses whose last-modification time differs from their creation time (NFR-12). A high count means speed is costing accuracy. Threshold: more than 15% of the trip's Expenses is too high. Counterbalances SM-2.
- **SM-C2 Share of *Other*:** the fraction of Expenses in Category *Other*. A high share means the Category list does not fit real spending and would undermine future Category analytics. Target: under 10%. Counterbalances SM-2.

Both counter-metrics are read by hand from the trip's data after the trip. The trip phone runs a debug build, so the Organizer can copy the app's database to a computer with `adb` and count from it; v1 adds no export, statistics screen or analytics for this (§7).

## 10. Open Questions

1. From the brief, still open for later phases: long-term positioning (trip hub vs. group finance), Bit integration feasibility, admin roles in the multi-user phase.
2. **Reference device** (FR-16, NFR-2, NFR-5): the trip phone model and a mid-range benchmark device are not yet named. Owner: founder. Revisit: before the UX specification.
3. **Archived group, per screen** (FR-6): what tapping or long-pressing an Expense does, how *Add expense* appears, and the empty Archive view. Owner: UX (bmad-ux). Revisit: during the UX specification.

## 11. Assumptions Index

No open assumptions. All assumptions were confirmed by the founder on 2026-10-26, 2026-10-27 and 2026-10-29 and are now stated as requirements.
