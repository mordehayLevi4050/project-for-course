- source_spec: `_bmad-output/implementation-artifacts/spec-1-1-create-a-group-and-manage-its-members.md`
  summary: Story 1.1 part 2 — FR1–FR5 user flows (group list with data, two-stage Create group, Group page header, Group settings with add/rename/remove Member and rename Group sheets), the groups domain/data/app layers (entities, transactional drift repositories, notifiers with AR25 save-once), the shared widgets they need (showAppSheet, exit sheet, avatar, gradient header, pill buttons, compact top bar), and their repository and widget tests (epics.md lines 289–401).
  evidence: Split at the step-02 token gate (full spec ~3,100 tokens vs the 1,600 target); the user chose to ship the project foundation and shared kernel first. Story 1.1 stays in-progress in sprint-status until this part is done.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-1-create-a-group-and-manage-its-members.md`
  summary: The Remove-member sheet body "ההוצאות יתחלקו מחדש בין {n} המשתתפים הנותרים." reads wrongly when one Member remains (n=1); EXPERIENCE.md needs a singular variant before part 2 uses it.
  evidence: MessageKey.removeMemberBody copies EXPERIENCE.md:99 verbatim; removing a Member from a two-Member Group yields "בין 1 המשתתפים הנותרים".

- source_spec: `_bmad-output/implementation-artifacts/spec-1-1-part-2a-create-group-and-add-members.md`
  summary: Story 1.1 part 2b — Group settings (FR3 rename Member, FR4 remove Member via PayerUsagePort, FR5 rename Group) with the Rename sheet on `showAppSheet<T>()`, wiring the Group page "⚙ ✎" chip; decided: "+ הוספת משתתף" in settings reveals the same inline add-member field as Create group stage 2 (epics.md lines 354–393).
  evidence: Split at the step-02 token gate (~2,300 tokens vs the 1,600 target); the user chose to ship create + add Members first.
