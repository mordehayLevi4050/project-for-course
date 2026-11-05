---
name: GrouPay
status: final
created: 2026-10-26
updated: 2026-11-02
sources:
  - ../../../specs/spec-groupay/SPEC.md
  - ../../../specs/spec-groupay/ui-messages.md
  - ../../../specs/spec-groupay/glossary.md
  - ../../briefs/brief-groupay-2026-10-26/brief.md
  - ../../prds/prd-groupay-2026-10-26/prd.md
  - ../../../../ears-requirements.md
---

# GrouPay: Experience Spine

## Foundation

- **Form factor:** a single Android phone (Android 15+), portrait, held in one hand by a right-handed Organizer. There is no tablet, web or iOS surface in v1. Layout fit is checked on the reference device, the Samsung Galaxy S25 (6.2"); the trip phone is the Galaxy S25 Ultra (6.9"); a layout that fits the S25 also fits the Ultra (SPEC › Constraints).
- **Language:** Hebrew-first with a full RTL layout. *Start* means the right edge. Amounts and Latin names render as LTR runs inside RTL text.
- **UI system:** none named. The app inherits Android conventions for system back, the text keyboard and snackbars. The amount entry uses a **custom in-app keypad**, not the system keyboard.
- **Offline:** every surface works with no network (PRD NFR-8). There are no loading states for remote data.
- **Visual identity:** `DESIGN.md`. This spine owns behavior and references DESIGN.md tokens by `{path.to.token}`.
- **Vocabulary:** the full glossary in `specs/spec-groupay/glossary.md` is binding (Organizer, Group, Member, Archived group, Active group, Expense, Amount, Payer, Category, Description, Trip total, Share, Balance, Leftover, Summary, Transfer, Transfer list). In the UI, "Member" is always "משתתף".
- **Deferred:** Paid marks, the Group lock, Payments and the "settled" status are not in v1 (`specs/spec-groupay/future-phases.md`). Their earlier design survives only in the gray, flagged screens of `mockups/settle-up-screens.html`. Nothing in this spine depends on them.

## Information Architecture

| Surface | Reached from | Purpose | PRD |
|---|---|---|---|
| Group list (home) | Launch with no Active group · "☰ הקבוצות שלי" on Group page | All non-archived Groups | FR-1, FR-6, FR-9 |
| Archive | "🗂 ארכיון (n)" link at the bottom of the Group list | View and restore archived Groups. Same layout as the Group list, with Group cards in gray. Tapping a card opens that Group's page read-only | FR-6 |
| Create group | "+ קבוצה חדשה" on the Group list | Two stages on one screen: name the Group and save it, then add Members | FR-1, FR-2, FR-7 |
| Active-group sheet | Right after the Group is saved on Create group, before any Members are added · switching the Active toggle on in Group settings while another Group is active | Offer to make the Group active, warning when another Group stops being active | FR-7, FR-8 |
| Group page | Launch with an Active group (no intermediate screen) · "סיום" on Create group · tap a Group card · tap an archived card in Archive (read-only) | Trip total, category stripe, Expense list, Add expense, Summary | FR-6, FR-9, FR-10, FR-12, FR-16 |
| Add expense | "+ הוספת הוצאה" on the Group page (enabled from 2 Members) | Record an Expense in ≤4 taps (≤5 with a changed Payer) | FR-10, FR-11 |
| Edit expense | Tap an Expense row (non-archived Group) | Change any field, or delete | FR-13, FR-14 |
| Exit sheet | ✕ or system back on Add/Edit expense with unsaved input | Confirm leaving without saving | FR-10 |
| Delete sheet | "🗑 מחיקה" on Edit expense · long-press an Expense row | Confirm deletion | FR-14 |
| Group settings | Tap the group name ("⚙ ✎") in the Group page header | Rename Group, Members, Active toggle, Archive | FR-2–FR-6, FR-8 |
| Rename sheet | "שם הקבוצה ›" or a Member's ✎ in Group settings | Text field to rename a Group or a Member | FR-3, FR-5 |
| Archive sheet | "🗂 העברה לארכיון" in Group settings | Confirm archiving | FR-6 |
| Remove-member sheet | ✕ on a Member row in Group settings (same control as on Create group), when the Group has Expenses | Warn that shares will be recalculated, then confirm | FR-4 |
| Summary | "סיכום" on the Group page | Group name, Trip total, share line, Transfer list | FR-15, FR-16 |

Navigation is a shallow stack: Group list → Group page → {Add/Edit expense, Group settings, Summary}. From an archived card the stack is Group list → Archive → Group page → Summary. Sheets stack at most one level deep. System back always goes one level up. From the Group page, back goes to the Group list (or to Archive for an archived Group), even when the app launched straight into the Active group. Create group is replaced by the new Group's page when it closes, so back from that page goes to the Group list. Confirming the Archive sheet replaces the stack with the Group list. A restore, from an archived Group page or from a card in Archive, opens the restored Group page, with back leading to the Group list; the Organizer is never left on an empty Archive.

→ Visual references: `mockups/key-screens.html` (Group list, Group page, Add expense, Summary, plus Add expense and Summary with 10 Members), `mockups/secondary-screens.html` (Create group in both stages with the Active-group sheet, Edit expense with the Delete sheet, the Exit sheet, Group settings, Group page with fewer than 2 Members) and `mockups/settle-up-screens.html` (archived Group page and Summary, the two-page Category row; the settle-up tracking screens in that file are marked as deferred). These spines win on conflict with any mockup.

## Voice and Tone

Brand posture lives in `DESIGN.md` › Brand & Style. Here are the microcopy rules:

- **Fixed messages:** the 17 texts in `specs/spec-groupay/ui-messages.md` (NFR-6) are shown **exactly** as written there, with no added emoji or punctuation. That table is the only source for them; the copy below mirrors it.
- **Free texts** (button labels, sheet bodies, hints and any other text not in the table): errors and validation are neutral and short and say what to do next; success moments may be celebratory, with emoji.
- **Address in free texts:** second person, **masculine** grammatical form (e.g. "מחק"). This was the founder's explicit choice. The fixed messages keep their own form (e.g. "נא לבחור קטגוריה").
- **Emoji:** allowed in free texts (🗑, 🗂, ⭐) and used as Category icons. Never added to a fixed message.
- **Transfer line:** always the fixed form "תשלום נדרש מ{debtor} ל{receiver} ₪N". Direction is carried by the words alone (see Component Patterns › Transfer card).
- **Expense time (FR-12):** an Expense first saved today shows the time only, `HH:mm` ("14:32"), with no word "היום". An Expense from any earlier day, including yesterday, shows the date only, `dd.mm` ("13.12"), with no time, no year and no "אתמול". The time is always the first-save time.

Fixed messages (`ui-messages.md`, NFR-6; the related requirement is in parentheses):

| Situation | Hebrew string |
|---|---|
| Empty Group list (FR-1) | "כאן תופיע רשימת הקבוצות" |
| Empty or whitespace-only name: Group, Member, rename (FR-1, FR-2, FR-3, FR-5) | "נדרש שם" |
| Duplicate Group name, create or rename (FR-1, FR-5) | "כבר קיימת קבוצה בשם הזה" |
| Duplicate Member, add or rename (FR-2, FR-3) | "כבר יש משתתף בשם הזה" |
| Eleventh Member (FR-2) | "קבוצות מוגבלות ל-10 משתתפים" |
| Remove a Member who paid (FR-4) | "לא ניתן להסיר משתתף שיש הוצאה על שמו" |
| Active-group sheet title (FR-7) | "להפוך את הקבוצה לקבוצה הפעילה?" |
| Another Group is active (FR-7) | "הקבוצה '{name}' תפסיק להיות הקבוצה הפעילה" |
| Fewer than 2 Members, next to the disabled *Add expense* (FR-10) | "יש להוסיף לפחות שני משתתפים כדי לרשום הוצאות" |
| Exit sheet title (FR-10) | "לצאת ללא שמירה?" |
| Invalid amount (FR-11) | "סכום לא תקין" |
| No Category (FR-11) | "נא לבחור קטגוריה" |
| *Other* without a Description (FR-11) | "נדרש תיאור או בחירת קטגוריה" |
| No Expenses (FR-12) | "עדיין אין הוצאות" |
| Delete sheet title (FR-14) | "למחוק את ההוצאה?" |
| Transfer line (FR-16) | "תשלום נדרש מ{debtor} ל{receiver} ₪N" |
| No Transfers needed (FR-16) | "החשבון מאוזן, אין צורך בהעברות" |

Free texts (secondary; may be refined without a SPEC change):

| Situation | Hebrew string |
|---|---|
| Group list | Header "GrouPay" over "הקבוצות שלי" · button "+ קבוצה חדשה" · link "🗂 ארכיון ({n})" |
| Group page header | Nav "☰ הקבוצות שלי" (archived: "→ ארכיון") · secondary line "{n} משתתפים · {m} הוצאות", with the singulars "משתתף אחד" and "הוצאה אחת" |
| Group card | Group name · "{n} משתתפים" (singular "משתתף אחד") · Trip total "₪{total}" on the end side |
| Active-group sheet (FR-7) | Body "האפליקציה תיפתח ישר לתוך הקבוצה הזו." · buttons "כן, להפוך לפעילה" / "לא עכשיו" |
| Create group | Top-bar title "קבוצה חדשה" (stage 1; the group name in stage 2) · field label "שם הקבוצה" · button "יצירת קבוצה" (stage 1) · section label "משתתפים" · add-member placeholder "שם המשתתף" · button "סיום" (stage 2) |
| Group settings | Title "הגדרות קבוצה" · rows "שם הקבוצה ›" (current name as value), "קבוצה פעילה", section label "משתתפים ({n})", "+ הוספת משתתף", "🗂 העברה לארכיון" |
| Rename sheet (FR-3, FR-5) | Title "שינוי שם" · buttons "שמירה" / "ביטול" |
| Edit expense | Top-bar chip "🗑 מחיקה" · meta line "נרשם {time}", plus " · נערך {time}" only after the Expense has been saved with a change (both use the Expense time format above) |
| Save button (FR-10) | "שמירה" |
| Description placeholder (FR-11) | "מה קנית?" |
| Exit sheet (FR-10) | Body "מה שהזנת לא יישמר." · buttons "יציאה" / "המשך עריכה" |
| Archive sheet (FR-6) | Title "להעביר את “{group}” לארכיון?" · body "הנתונים נשמרים ואפשר לשחזר בכל רגע." · buttons "העברה לארכיון" / "ביטול" |
| Remove-member sheet (FR-4) | Title "להסיר את {name}?" · body (only when the Group has Expenses) "ההוצאות יתחלקו מחדש בין {n} המשתתפים הנותרים.", or "כל ההוצאות יחולו על המשתתף הנותר." when one Member remains · buttons "הסרה" / "ביטול" |
| Delete sheet (FR-14) | Body = expense line "{emoji} {category or Description} · {payer} · ₪{amount}" (e.g. "🛒 אוכל ושתייה · מוטי · ₪87.4") + "אי אפשר לבטל את הפעולה." · buttons "מחיקה" / "ביטול" |
| Archived card (FR-6) | Text button "↩ שחזור" |
| After a delete | Snackbar "ההוצאה נמחקה" |
| Summary section title | "מי מעביר למי" |
| Summary share line | "{n} משתתפים · ₪{share} לאחד" |
| Archived Group page (FR-6) | Archive note "🗂 הקבוצה בארכיון ולכן לקריאה בלבד. שחזור יחזיר את האפשרות לערוך." · primary button "↩ שחזור מהארכיון" |
| Archived Summary (FR-6) | "🗂 הקבוצה בארכיון ולכן לקריאה בלבד." |
| Badges | "⭐ פעילה" · "🗂 בארכיון" |

## Component Patterns

Behavioral only. Visual specs live in `DESIGN.md` › Components.

| Component | Behavioral rules |
|---|---|
| Header block | On the Group page, the group name with "⚙ ✎" is the single entry to Group settings. The "⚙ ✎" chip appears **on the Group page only**: never on the Summary (so it never reaches the screenshot) and never on an archived Group, where nothing in Group settings can change (FR-6). An archived Group's header shows the badge "🗂 בארכיון", the only header badge. The category share stripe recomputes on every Expense change. |
| Compact top bar | On Add expense, Edit expense and Create group. ✕ leaves the screen: on Add/Edit expense it goes through the Exit sheet when there is unsaved input; on Create group stage 1 it leaves without creating anything. On Edit expense, the "🗑 מחיקה" chip opens the Delete sheet. |
| Group card | Tap opens that Group's page. Long-press does nothing. **Order:** the Active group is always first, carrying "⭐ פעילה"; the other Groups follow, newest created first. Archive lists its cards newest created first. Order comes from a creation sequence, never the clock. |
| Archived group card | Tap opens that Group's page read-only. The "↩ שחזור" text button on the card restores the Group and opens its page (same as "↩ שחזור מהארכיון"). Long-press does nothing. |
| Button primary | At most one per screen. Always labeled. Placed on the start (right) side of the bottom bar. |
| Button primary, disabled (*Add expense*) | While the Group has fewer than 2 Members, "+ הוספת הוצאה" is disabled: it does nothing when tapped, and "יש להוסיף לפחות שני משתתפים כדי לרשום הוצאות" sits directly above the bottom bar (FR-10). Members are added through "⚙ ✎" › Group settings. |
| Button secondary ("סיכום") | Always visible on the Group page. Disabled when the Group has fewer than 2 Members (FR-16). |
| Expense row | Tap → Edit expense. Long-press → Delete sheet. Both always work, except in an archived Group, where rows are view-only. Ordered newest first **by save order**, never by clock (FR-12). The time in the meta line is the time the Expense was first saved, in the Expense time format (Voice and Tone), and editing never changes it (FR-10). |
| Category tile | Tap selects and replaces any previous selection. It never saves on its own. Selecting *Other* reveals the Description field. Switching from *Other* to another Category hides the field but keeps its text in the form, so returning to *Other* before saving restores it. On save, a Description is stored only when the Category is *Other* (glossary). |
| Two-page Category row (FR-10) | Used only when the 4×2 grid does not fit at the required touch-target size. The Categories keep the grid's fixed order: page 1 holds the first four (✈️ 🏨 🚗 ⛽) and page 2 the last four (🍝 🛒 🎡 📝), so there is never a third page. Page 2 lies on the end (left) side. **How the user knows there is a second page:** the first tile of the other page peeks in at the edge (about a quarter tile), and two page dots under the row show which page is current. **Moving between pages:** one swipe snaps to the other page; there is no third page. The dots are indicators, not controls. **Selection across pages:** the selected Category stays selected while you swipe, and selecting a tile on one page replaces a selection on the other. **Starting page:** Add expense opens on page 1; Edit expense opens on the page that holds the saved Category; after a validation error the row stays where it was. The keypad stays open throughout. |
| Payer picker (FR-10) | Every Member of the Group (up to 10) is visible at once as a tappable avatar; no swipe or scroll is ever needed to reach one. Up to 6 avatars per row: groups of up to 6 Members use one row, and groups of 7–10 Members use a second row. Avatars keep a fixed order, the order the Members were added; the selected ring marks the Payer. One tap selects another Member and keeps the keypad open. **Default Payer:** the current Payer of the existing Expense with the highest save-order number in the Group, so deletions and Payer edits count. When the Group has no Expenses, the default is the earliest-added Member still in the Group. A changed Payer adds one tap: at most 5 taps from launch, including a swipe on the two-page Category row. |
| Member avatar | The first word of the Member name is shown under the circle. If another Member in the Group has the same first word, both show the full name. The name is a single typed field, and the first word counts as the first name. A name of up to 10 characters may wrap to two lines under the circle; it is never truncated. |
| Add expense layout | The keypad and Save are pinned to the bottom, inside the system insets, and are never covered or pushed off-screen. The region above them (amount, message slot, payer picker, Categories) never scrolls: when it does not fit (a second payer row, a small screen or an enlarged font), the Categories switch to the two-page row (FR-10). There are no section labels above the payer picker or the Categories. |
| Keypad | Digits, `.` and ⌫. `.` on an empty amount enters "0." automatically. A second `.` does nothing, with no message, and so does a second digit after the decimal point (FR-11). It stays visible, except in the *Other* state, where the system text keyboard replaces it. Category tiles and Save stay reachable while it is shown (FR-10). |
| Amount message slot (FR-11) | A single line directly under the amount, always reserved, empty when there is no error. Every FR-11 message ("סכום לא תקין", "נא לבחור קטגוריה", "נדרש תיאור או בחירת קטגוריה") appears there in `{colors.danger}`, replacing any earlier one, so an error never shifts the layout. The message clears on the next change to the input it concerns (amount, Category or Description). |
| Save | Validates per FR-11. On error, all input stays on screen and the message shows in the amount message slot. On success it stores the Expense **exactly once**: any further tap on Save before the screen closes does nothing. It returns immediately to the Group page (under 300 ms, NFR-5), where a new Expense is at the top of the list. An edited Expense keeps its place in the list, because the order is the save order (FR-10, FR-12). |
| Exit sheet (FR-10) | Opens when the Organizer leaves Add or Edit expense (✕ or system back) with unsaved input. Unsaved input means: on Add expense, any typed Amount or Description, a selected Category, or a Payer other than the default; on Edit expense, any field that differs from the saved Expense. With no unsaved input the screen closes at once, with no sheet. **"יציאה":** the input is discarded and the screen closes. **"המשך עריכה", the scrim or system back:** the sheet closes and the input is intact. Not part of the tap budget (NFR-1). |
| Name fields (FR-1, FR-2, FR-3, FR-5) | A Group name is at most 20 characters and a Member name at most 10. A character is a user-perceived character: an emoji or a letter with niqqud counts as one. The field blocks typing beyond the limit, a pasted name is cut to the limit, and leading and trailing spaces are removed on save. Empty or whitespace-only → "נדרש שם". Duplicate checks ignore case and outer spaces. A Group name is compared with every other Group, including archived ones; saving a Group under its own name is not a duplicate. A Member name is compared with the other Members of the Group, so changing only letter case ("dana" → "Dana") is allowed. |
| Member list (Create group, Group settings) | Each added name appears at once as a colored avatar row, in the order added. On a row, ✎ opens the Rename sheet and ✕ removes the Member (FR-4 rules below). At 10 Members, adding another is refused with "קבוצות מוגבלות ל-10 משתתפים" inline under the field, and nothing is added. |
| Transfer card (FR-16) | One card per Transfer, showing the line "תשלום נדרש מ{debtor} ל{receiver} ₪N". **Direction is carried by the words only:** no arrow or other direction symbol appears anywhere in the card (NFR-6). Each name is isolated for bidirectional display, so a Latin or mixed name never reorders the line, and a name that does not start with a Hebrew letter takes a hyphen after the prefix ("מ-Dan לדנה", "מדנה ל-Zoe"). A pair of small avatars (debtor, then receiver) sits at the start of the card as decoration only, with nothing between them. The card is not tappable and has no toggle. Long names wrap inside the card; the amount always ends the line. |
| Transfer list (FR-16) | Ordered by debtor name, then receiver name, under the FR-15 alphabetical rule. Up to 6 Members: everything fits on one screen. 7–10 Members: only the Transfer list scrolls, while the header and the "מי מעביר למי" title stay in view. |
| Bottom sheet | Used for the Active-group prompt (on Create group, and from the Active toggle when another Group is active), the Exit sheet, the Delete sheet (each is the FR-10 or FR-14 confirmation dialog), Archive confirmation, Remove-member warning and Rename (with a text field and the Name-field rules). Dismiss by the cancel button, tapping the scrim, or system back. Dismissing changes nothing. |
| Snackbar | Shown after a delete only. Disappears automatically. There is no undo action. |
| Archive note (FR-6) | On an archived Group page, "↩ שחזור מהארכיון" takes the primary slot of the bottom bar (instead of *Add expense*), with "סיכום" beside it as usual. The archive note sits directly above the bar. Restore needs no confirmation: it is not destructive. After a restore the restored Group page is shown, the badge and note disappear, and the page shows exactly the state the Group had before archiving. Back now leads to the Group list. The "↩ שחזור" button on archived cards in Archive does the same. A restored Group does not become the Active group by itself. |
| Archive sheet (FR-6) | "העברה לארכיון" archives the Group in one action: it becomes read-only, moves to Archive, and, if it was the Active group, is no longer active, so the next launch opens the Group list. The Organizer lands on the Group list. "ביטול", the scrim or back changes nothing. |
| Active toggle (FR-8) | One row in Group settings: "קבוצה פעילה" with the Toggle. It shows whether this Group is the Active group. **Switch on, no other Group active:** the Group becomes the Active group at once, with no sheet. **Switch on, another Group active:** the Active-group sheet opens, with the warning "הקבוצה '{name}' תפסיק להיות הקבוצה הפעילה" naming the current Active group, exactly as on Create group (FR-7). The Toggle stays off until "כן, להפוך לפעילה" is tapped; then this Group becomes the only Active group and the other one stops being active. "לא עכשיו", the scrim or back closes the sheet, the Toggle returns to off, and the current Active group is unchanged. **Switch off:** the Active group is unset at once, with no sheet (not destructive, and switching it back on undoes it). The Group list then shows no "⭐ פעילה", and the next launch opens the Group list (EARS l.53). Every change is saved at once; there is no separate Save. Not shown for an archived Group (Group settings is not reachable). |
| FR-4 refusal (Group settings) | Shown inline under the Member row whose ✕ was tapped, in `{colors.danger}`, and replaces any previous message. Nothing is removed. |

## State Patterns

| Surface | State | Treatment |
|---|---|---|
| Group list | Empty | "כאן תופיע רשימת הקבוצות", with "+ קבוצה חדשה" still present |
| Group list | Populated | Group cards. The Active group carries "⭐ פעילה" and an orange start edge. No other status badges in v1 |
| Archive | Empty | The link is hidden when there are 0 archived Groups. The view itself is never shown empty: every restore leaves it for the restored Group page |
| Archive | Populated | Gray Group cards. Tapping a card opens its Group page read-only. Each card also carries a "↩ שחזור" text button that restores the Group and opens its page (FR-6) |
| Create group | Stage 1, naming | Group-name field and "יצירת קבוצה". ✕ leaves without creating anything |
| Create group | Stage 1, invalid name | "נדרש שם" or "כבר קיימת קבוצה בשם הזה" inline under the field. Nothing is created |
| Create group | Group saved | The Group is created and appears in the Group list. The Active-group sheet slides up at once, before any Members are added. When another Group is active, the sheet shows "הקבוצה '{name}' תפסיק להיות הקבוצה הפעילה" before the change is applied. Either answer, the scrim or back closes the sheet and opens stage 2 |
| Create group | Stage 2, Members | The group name becomes the top-bar title. The Members section opens: add-member field, Member list, "סיום". Members are saved as they are added. "סיום" or system back opens the new Group's page |
| Create group, Group settings | Member validation | "נדרש שם", "כבר יש משתתף בשם הזה" or "קבוצות מוגבלות ל-10 משתתפים" inline under the field. Nothing is added |
| Group page | No Expenses | "עדיין אין הוצאות". The Trip total shows ₪0 and the stripe is empty |
| Group page | < 2 Members | "+ הוספת הוצאה" and "סיכום" are disabled, and "יש להוסיף לפחות שני משתתפים כדי לרשום הוצאות" shows above the bottom bar |
| Group page | Archived (FR-6) | Header nav "→ ארכיון", badge "🗂 בארכיון", no "⚙ ✎" chip. Archive note above the bottom bar; "↩ שחזור מהארכיון" in the primary slot and "סיכום" beside it. Rows are view-only (tap and long-press do nothing). The Expense list, Trip total and stripe are shown as usual |
| Add expense | Initial | Amount empty with the caret showing, keypad active, default Payer selected, no Category selected |
| Add expense, Edit expense | 7–10 Members | The payer picker takes a second row. If the region above the keypad no longer fits, the Categories use the two-page row |
| Add expense | Other | Description field and system text keyboard. Save moves above the keyboard |
| Add expense, Edit expense | Category grid does not fit (FR-10) | Two-page Category row with edge peek and two page dots, as in Component Patterns. The keypad stays open |
| Add expense, Edit expense | Error | The FR-11 message in the amount message slot, in `{colors.danger}`. No height changes. All input is kept |
| Add expense, Edit expense | *Other*, then another Category | Description field hidden, its text kept in the form; not stored on save |
| Add expense, Edit expense | Leaving with unsaved input | Exit sheet "לצאת ללא שמירה?" |
| Add expense, Edit expense | Saving | After the first Save tap the screen accepts no further Save; it closes at once |
| Edit expense | Initial, never edited | All fields prefilled. Meta line "נרשם {time}". The recorded time is the first-save time and never changes |
| Edit expense | Initial, edited before | Meta line "נרשם {time} · נערך {time}", the second time being the last-modification time (NFR-12) |
| Summary | Transfers, ≤6 Members | Header, "מי מעביר למי" and every Transfer card on one screen, no scroll (default font, reference device Galaxy S25) |
| Summary | Transfers, 7–10 Members | Header and "מי מעביר למי" stay fixed; the Transfer cards scroll below them, with a fade at the bottom edge when more cards exist |
| Summary | No Transfers (FR-16) | "החשבון מאוזן, אין צורך בהעברות" in place of the cards |
| Summary | Archived (FR-6) | Badge "🗂 בארכיון" and the archive note under the cards. Everything else as in the matching unarchived state |
| Group settings | Archived | Not reachable: the "⚙ ✎" chip is hidden (FR-6). Nothing in it could change while archived, including the Active toggle |
| Group settings | Active toggle on, no other Group active | Toggle on. Switching it off unsets the Active group at once, with no sheet |
| Group settings | Active toggle off, no Group active | Toggle off. Switching it on makes this Group active at once, with no sheet |
| Group settings | Active toggle off, another Group active | Toggle off. Switching it on opens the Active-group sheet with "הקבוצה '{name}' תפסיק להיות הקבוצה הפעילה". Nothing changes until the Organizer confirms; on cancel the Toggle returns to off |
| Group settings | Archive confirmed | The Group moves to Archive (and stops being the Active group if it was). Group settings closes and the Group list is shown |
| Group settings | Remove a Member who paid | Refused with "לא ניתן להסיר משתתף שיש הוצאה על שמו", inline under the row. Nothing changes |
| Group settings | Remove a Member, Group has Expenses | Remove-member sheet warns that Expenses will be split among the remaining Members. "ביטול" changes nothing |
| Group settings | Remove a Member, no Expenses | Removed immediately, no sheet |
| Rename sheet | Invalid name | "נדרש שם", "כבר קיימת קבוצה בשם הזה" or "כבר יש משתתף בשם הזה" inside the sheet. The current name is kept |

## Interaction Primitives

- **Tap budget (NFR-1):** Launch → Group page (0) → *Add expense* (1) → type amount (not counted) → Category (2) → Save (3). With a changed Payer: *Add expense* (1) → Payer (2) → Category (3) → Save (4), or 5 when the Category needs a swipe. A swipe counts as a tap. Any new control on this path must keep the budget at ≤4 with the default Payer and ≤5 with a changed one. The Exit sheet is outside the normal flow and does not count.
- **Tap** to act. **Long-press** on an Expense row means delete (with confirmation). There is no swipe-to-delete.
- **Horizontal scroll** only in the two-page Category row used when the Category grid does not fit (FR-10). It snaps page by page. The payer picker never scrolls.
- **Vertical scroll on the Summary** only inside the Transfer list, and only for 7–10 Members (FR-16). Above 100% font scale the whole Summary may scroll (see Accessibility Floor).
- **Bottom sheets** for confirmations, never centered dialogs. They keep the decision in the thumb zone.
- **Motion:** only two animations. (1) After Save, a new Expense row slides gently into the top of the list. (2) Bottom sheets slide up and down. Everything else is instant. When Android "Remove animations" is on, both are skipped.
- **Haptics:** none.
- **Banned:** icon-only buttons, auto-save on Category tap, swipe gestures on rows, arrows or any other direction symbol in a Transfer.

## Accessibility Floor

Visual contrast lives in `DESIGN.md` › Colors. The behavioral floor is the PRD floor and no more:

- Every tappable control is ≥48×48dp. Primary buttons (64dp tall), Category tiles (64dp) and payer avatars (44dp circle in a 48dp-wide slot with a 48dp hit area) meet or exceed this (NFR-3). Any control drawn smaller than 48dp gets a 48×48dp hit area around it: the Toggle (52×30dp), the ✎ and ✕ on Member rows, the "⚙ ✎" and "🗑 מחיקה" chips, the ✕ close, the "↩ שחזור" text button, the "🗂 ארכיון (n)" link and the add-member "+" button.
- Primary actions sit in the bottom half, on the right (NFR-2).
- WCAG 2.1 AA contrast is enforced through the DESIGN.md text-size rules on the gradient and the orange button (NFR-4).
- System "Remove animations" is respected.
- **System font scale up to 150%:** no text is clipped and no control becomes unreachable. Text wraps instead of truncating, and components with fixed heights in `DESIGN.md` grow to fit (fixed heights are minimums). Screens scroll when content no longer fits; on Add expense the Categories switch to the two-page row instead.
- The FR-16 one-screen Summary is guaranteed only at the default font size; above it, the Summary scrolls.
- **Not committed in v1:** TalkBack labelling, and font scales above 150%.

## Inspiration & Anti-patterns

- **Lifted from Bit:** big, obvious buttons and a flow understood without reading. The custom amount keypad follows Bit's transfer screen.
- **Lifted from PassportCard:** colorfulness, through a confident colored header block.
- **Rejected: PayBox.** An uninviting, unintuitive, overcrowded screen. This is the reason for 4–5 rows per screen, one action color and text on every button.
- **Rejected in this design session:** an all-white minimal look (too little color); a link stacked under the primary button (crowded); a summary card that read as part of the list instead of a header; an icon-only summary button; an arrow between names, whose meaning flips with text direction.

## Screenshot Contract

The Summary is a deliverable in its own right: it gets sent as an image to friends who never installed the app (FR-16, SM-4).

- It must read on its own: the group name, Trip total, share line, and the "מי מעביר למי" Transfer cards. No app controls appear in it: the Summary header has no "⚙ ✎" chip.
- **Every Transfer reads as a sentence:** "תשלום נדרש מיוסי לדנה ₪100". Who pays whom comes from the words "מ" and "ל" alone, never from an arrow, a symbol or the position of the avatars. The decorative avatar pair carries no direction meaning.
- Names are bidi-isolated, so Hebrew, Latin and mixed names keep the word order of the line ("תשלום נדרש מ-Adam ל-Zoe ₪100"). A rendered screenshot with Hebrew-only, Latin-only and mixed names is part of the tests (NFR-6, EARS T3.43–T3.44).
- For ≤6 Members, the header and all Transfer cards fit on one screen with no scroll, at default font size, on the reference device (Galaxy S25). For 7–10 Members, the group name and Trip total stay in view and only the Transfer list scrolls, so one screenshot may not hold every Transfer. Text export of the Summary is deferred (`future-phases.md`). See Open Question 1 for the height check.
- No Balance table and no breakdown of how a Transfer was calculated (SPEC › Non-goals): only Transfer cards. The single share line ("₪2,100 לאחד") stays; it shows the Share, not a Balance.
- **Calculation display (FR-15):** the share line shows the Share (rounded down to ₪0.10, `transfer-calculation.md`); each debtor's Transfers add up to exactly the Share minus what they paid, so the numbers in the screenshot agree.

## Key Flows

UJ-1…UJ-4 are the journeys of the same number in `specs/spec-groupay/user-journeys.md`; the headings keep the PRD journey names verbatim. The protagonist is **Motty**, the Organizer.

### UJ-1. Motty sets up the trip from home a month ahead

1. On the Group list, Motty taps "+ קבוצה חדשה".
2. He types "בודפשט דצמבר" and taps "יצירת קבוצה". The Group is saved.
3. At once the Active-group sheet slides up: "להפוך את הקבוצה לקבוצה הפעילה?", with the warning "הקבוצה 'אילת סוכות' תפסיק להיות הקבוצה הפעילה".
4. He taps "כן, להפוך לפעילה". The sheet closes and the Members section opens on the same screen.
5. He adds members one by one: מוטי, דנה, יוסי, נועה. Each appears with its color and its first name under the circle.
6. He types "דנה" again. The inline message "כבר יש משתתף בשם הזה" appears and nothing is added.
7. He taps "סיום" and lands on the Group page.
8. **Climax:** from now on every launch opens straight into "בודפשט דצמבר". He records the flights right away.
9. **Resolution:** he can still change this at any time. In "⚙ ✎" › Group settings, switching "קבוצה פעילה" off unsets the Active group, so the next launch opens the Group list. Switching it on for another Group shows the same warning as in step 3 before the change is applied (FR-8).

Failure: an empty group name → "נדרש שם", and no Group is created.

### UJ-2. Motty records a grocery purchase at the checkout, one-handed

1. He opens GrouPay. It opens straight onto the "בודפשט דצמבר" Group page.
2. He taps "+ הוספת הוצאה" with his right thumb *(tap 1)*.
3. The amount is focused on the Keypad. He types 87.4.
4. The Payer is already מוטי, highlighted, because he paid the last Expense *(0 taps)*.
5. He taps 🛒 אוכל ושתייה *(tap 2)*.
6. He taps the wide "שמירה" under the keypad *(tap 3)*.
7. **Climax:** he is back on the Group page and the expense slides in at the top of the list. Three taps, and the phone is back in his pocket.

Failure: he taps 📝 אחר → the Description field and text keyboard appear; Save with it empty → "נדרש תיאור או בחירת קטגוריה", and all input is kept.

Edge case (FR-10): at the gas station Dana pays for fuel. Motty records it on the spot: "+ הוספת הוצאה" *(tap 1)*, types the amount, taps דנה in the payer picker *(tap 2)*, taps ⛽ דלק *(tap 3)*, taps "שמירה" *(tap 4)*. Four taps, within the 5-tap budget for a changed Payer. The next Expense defaults to דנה.

Edge case (FR-10): on a phone where the grid does not fit, the Category row shows two dots and the edge of the next tile. 🛒 אוכל ושתייה is on page 2, so he swipes the row once *(tap 2)*, taps it *(tap 3)* and saves *(tap 4)*. The keypad never closes.

Edge case (FR-10): he starts an Expense, then presses back before saving. The Exit sheet asks "לצאת ללא שמירה?". "המשך עריכה" brings him back with the amount intact.

### UJ-3. Motty fixes a mistake, at the checkout or that evening

1. On the Group page he spots ₪870 instead of ₪87 and taps the row.
2. Edit expense opens with everything filled in. He corrects the amount and taps "שמירה". The row keeps its place in the list and its recorded time.
3. To remove a duplicate instead, he long-presses its row (or taps "🗑 מחיקה" on the edit screen), and the Delete sheet slides up: "למחוק את ההוצאה?".
4. He taps "מחיקה". The snackbar "ההוצאה נמחקה" appears.
5. **Climax:** the list, Trip total and category stripe reflect the correction immediately.

Failure: in Group settings he tries to remove יוסי, who paid for fuel → "לא ניתן להסיר משתתף שיש הוצאה על שמו". Removing נועה, who paid for nothing, first shows the Remove-member sheet: "ההוצאות יתחלקו מחדש בין 3 המשתתפים הנותרים."

### UJ-4. Motty settles up on the flight home

1. In airplane mode, on the Group page, he taps "סיכום".
2. The Summary shows the Lagoon header (בודפשט דצמבר, ₪8,400, "4 משתתפים · ₪2,100 לאחד", category stripe) and two Transfer cards: "תשלום נדרש מיוסי לדנה ₪100" and "תשלום נדרש מנועה למוטי ₪1,250".
3. He takes one screenshot and sends it to the trip's WhatsApp group.
4. **Climax:** friends who never installed GrouPay understand it at once and transfer the money.

Resolution: the money moves outside the app. v1 does not track who has already paid (SPEC › Non-goals).

Alternate path (FR-16): when every Balance is zero, the Summary shows "החשבון מאוזן, אין צורך בהעברות" in place of the cards, and that is the screenshot he sends.

### Archive and restore. Motty puts away the Eilat trip

1. Back from "אילת סוכות", Motty opens its Group page and taps "⚙ ✎".
2. In Group settings he taps "🗂 העברה לארכיון". The Archive sheet asks "להעביר את “אילת סוכות” לארכיון?".
3. He taps "העברה לארכיון". He lands on the Group list. "אילת סוכות" is gone from it, and the link now reads "🗂 ארכיון (1)". It was the Active group, so it is no longer active and the next launch opens the Group list.
4. Months later a friend asks what he owes. Motty taps "🗂 ארכיון (1)" and then the gray "אילת סוכות" card. Its Group page opens read-only, with "🗂 בארכיון" in the header and no "⚙ ✎".
5. He taps "סיכום" and screenshots the read-only Summary.
6. **Climax:** nothing was lost. The Expenses and the Transfers are exactly as they were on the day he archived it.
7. **Resolution:** to add a forgotten receipt he taps "↩ שחזור מהארכיון". The badge and note disappear and the Group page is editable again; back leads to the Group list.

Alternate path: tapping "↩ שחזור" on the card in Archive restores the Group the same way and opens its page.

## Open Questions

The SPEC stays authoritative; this spine does not change any business or calculation rule.

1. **Summary height check (FR-16, EARS T3.46). Owner: the founder. Verified in the Summary story (Story 3).** Estimated from the DESIGN.md tokens at default font: header block about 212dp, section title about 52dp, each Transfer card about 72dp including its gap (about 92dp when long names wrap to two lines). A 6-Member Group can need 5 Transfers: about 624dp, or about 724dp with wrapped names. No fallback layout is committed. A golden test or an on-device screenshot on the Galaxy S25 at default font checks that 5 Transfers with long, wrapped names fit with no scroll; if they do not, the founder decides the fix then.