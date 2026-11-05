- source_spec: `_bmad-output/implementation-artifacts/spec-1-1-create-a-group-and-manage-its-members.md`
  summary: Story 1.1 part 2 — FR1–FR5 user flows (group list with data, two-stage Create group, Group page header, Group settings with add/rename/remove Member and rename Group sheets), the groups domain/data/app layers (entities, transactional drift repositories, notifiers with AR25 save-once), the shared widgets they need (showAppSheet, exit sheet, avatar, gradient header, pill buttons, compact top bar), and their repository and widget tests (epics.md lines 289–401).
  evidence: Split at the step-02 token gate (full spec ~3,100 tokens vs the 1,600 target); the user chose to ship the project foundation and shared kernel first. Story 1.1 stays in-progress in sprint-status until this part is done.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-1-create-a-group-and-manage-its-members.md`
  summary: The Remove-member sheet body "ההוצאות יתחלקו מחדש בין {n} המשתתפים הנותרים." reads wrongly when one Member remains (n=1); EXPERIENCE.md needs a singular variant before part 2 uses it.
  evidence: MessageKey.removeMemberBody copies EXPERIENCE.md:99 verbatim; removing a Member from a two-Member Group yields "בין 1 המשתתפים הנותרים".

- source_spec: `_bmad-output/implementation-artifacts/spec-1-1-part-2a-create-group-and-add-members.md`
  summary: Story 1.1 part 2b — Group settings (FR3 rename Member, FR4 remove Member via PayerUsagePort, FR5 rename Group) with the Rename sheet on `showAppSheet<T>()`, wiring the Group page "⚙ ✎" chip; decided: "+ הוספת משתתף" in settings reveals the same inline add-member field as Create group stage 2 (epics.md lines 354–393).
  evidence: Split at the step-02 token gate (~2,300 tokens vs the 1,600 target); the user chose to ship create + add Members first.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-3-record-fix-and-delete-expenses-at-the-checkout.md`
  summary: Story 1.3 part B — fix and delete Expenses (FR13, FR14 and the Expense parts of FR3/FR4/FR6): Edit expense at `group/:id/edit/:eid` (prefilled, two-page row opens on the saved Category's page, `saveSeq`/`createdAt` unchanged, `modifiedAt` updated), `mayModifyExpense`, Delete via long-press or the "🗑 מחיקה" chip with the Delete sheet and the "ההוצאה נמחקה" snackbar (root `scaffoldMessengerKey`), view-only rows in an Archived group with the `edit` redirect, the Remove-member sheet body when the Group has Expenses, and the rename-shows-on-rows test (epics.md lines 638–640, 678–730). Decided by Motty: (1) edit meta line follows EXPERIENCE.md:94 — "נרשם {time}", plus " · נערך {time}" only after the Expense was saved with a change; (2) when the removal would leave one Member, the Remove-member body is the singular "כל ההוצאות יחולו על המשתתף הנותר." instead of "ההוצאות יתחלקו מחדש בין {n} המשתתפים הנותרים.".
  evidence: Split at the step-02 token gate (full spec ~2,800 tokens vs the 1,600 target); the user chose to ship recording Expenses first. Story 1.3 stays in-progress in sprint-status until part B is done.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-3-record-fix-and-delete-expenses-at-the-checkout.md`
  summary: Add expense (and Edit expense in part B) — add a small section label above the Payer avatar row and another above the Category picker, because on the emulator it was not clear enough that the name circles choose the Payer. Requested by Motty after the part A emulator check. Label text must be added to EXPERIENCE.md and the MessageKey table before the code.
  open_questions: (1) the label wording (proposed: "מי שילם?" and "קטגוריה"); (2) how the two labels fit without breaking the "no scrolling above keypad" layout rule. Motty decides when this is picked up.
  evidence: Motty's emulator check of commit 04762ac — the Payer row and Category picker have no visible label on add_expense_screen.dart.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-3-record-fix-and-delete-expenses-at-the-checkout.md`
  summary: When the Category is "Other", reject a description made only of digits — e.g. "888" is rejected, "דלק ו80" is accepted. Proposed rule: the trimmed description must contain at least one letter (any script, via a `core/text` helper), enforced in the save transaction through the `core/policy` verdict, not only in the UI. Requested by Motty after the part A emulator check.
  open_questions: (1) the rejection message wording (new MessageKey, added to ui-messages.md / EXPERIENCE.md first); (2) whether punctuation- or emoji-only descriptions (e.g. "!!!", "⛽") are rejected too. Motty decides when this is picked up.
  evidence: Today "Other" accepts any non-empty description, so "888" saves as a valid Expense description.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-3-part-b-fix-and-delete-expenses.md`
  summary: Reconcile `epics.md` with Motty's Story 1.3 decisions — lines 198/682 still say the Edit meta opens as "נרשם {date time} · נערך עכשיו", and lines 202/721 lack the singular Remove-member body "כל ההוצאות יחולו על המשתתף הנותר."; the earlier n=1 wording entry in this file is now resolved by part B.
  evidence: Blind review of part B; EXPERIENCE.md:94 and :99 carry the decided wording, epics.md does not.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-4-settle-up-with-one-screenshot.md`
  summary: Story 1.4 part B — the Summary of an Archived group (`archive/group/:id/summary`, `group/:id/summary` redirecting there when archived, "סיכום" beside "↩ שחזור מהארכיון", header badge "🗂 בארכיון" and the archive note under the cards), the 7–10 Member layout (header and "מי מעביר למי" fixed, only the cards scroll, 56dp bottom fade only while more cards are below; whole Summary may scroll above 100% font), and the Summary golden tests with bundled Heebo at text scale 1.0 and 1.5 (Hebrew-only, Latin-only, mixed, 5 long-name Transfers, archived) (epics.md lines 846–886).
  evidence: Split at the step-02 token gate (full spec ~2,400 tokens vs the 1,600 target); the user chose to ship the Transfer calculation and the basic Summary first. Story 1.4 stays in-progress in sprint-status until part B is done.
