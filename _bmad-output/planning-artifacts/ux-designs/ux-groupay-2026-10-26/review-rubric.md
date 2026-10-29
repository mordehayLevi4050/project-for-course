# Spine Pair Review — groupay

Reviewed 2026-10-29 against PRD final (2026-10-29), `ears-requirements.md`, the bmad-ux examples and `design-md-spec.md`. Scope: DESIGN.md, EXPERIENCE.md, .memlog.md and the three mockups. Settle-up screens 1–4 and 7 were treated as intentionally deferred.

## Overall verdict

The pair is a usable contract. Every `{token}` reference resolves, none of the removed settle-up tokens are left, all 17 NFR-6 fixed messages match the PRD exactly, the four UJs match the PRD word for word, and no spine statement contradicts a PRD business or calculation rule. There are two high findings. FR-8 (set or unset the Active group at any time) has no behavioral spec beyond a toggle name. The white header badge and chip on their 22% overlay drop below the WCAG AA 3:1 large-text floor (NFR-4) at the light end of the gradient. The other gaps are secondary components and states that a story developer would otherwise have to guess.

## 1. Flow coverage — adequate

Checked: each PRD UJ (UJ-1…UJ-4) has a Key Flow with the same name, a named protagonist (Motty), numbered steps, a bold Climax and a failure or edge path. Checked: the PRD edge cases (duplicate "Dana", *Other* without Description, changed Payer at 4 taps, swipe to page 2, refusing to remove Yossi) appear in the flows. Checked: the EARS Story 1–3 event requirements trace to a flow, a state or a component rule.

### Findings
- **high** FR-8 / UJ-1 Resolution ("he can still … unset the active group at any time") has no flow and no behavior. EXPERIENCE names "Active toggle" only in the IA (EXPERIENCE.md l.37) and in the archived state (l.153). Nothing says what switching it on does while another Group is active (whether the FR-7 warning "הקבוצה '{name}' תפסיק להיות הקבוצה הפעילה" appears or the switch is silent), what switching it off does (the next launch opens the Group list, EARS l.53), or whether the change applies at once. *Fix:* add a Component Patterns row "Active toggle (FR-8)" and Group settings states for "toggle on, another Group active", "toggle on, none active" and "toggle off". Add one short UJ-1 Resolution line to the flow.
- **medium** FR-6 archive and restore has no flow, even though PRD §10 Q3 hands its per-screen behavior to UX. The pieces are scattered across IA, State Patterns and Component Patterns, but the end-to-end sequence is not written anywhere: Group settings → Archive sheet → confirm → where the Organizer lands → Archive view → open read-only → restore. *Fix:* add a short "Archive and restore" flow (protagonist Motty, after the Eilat trip). It should include the landing surface after confirming.
- **low** UJ-4 has no failure or alternate path. The obvious one is "no Transfers needed → 'החשבון מאוזן, אין צורך בהעברות'" (EXPERIENCE.md l.244–251). *Fix:* add a one-line alternate path.

## 2. Token completeness — adequate

Checked: extracted every `{colors|typography|rounded|spacing.*}` reference in both files (61 distinct). All of them are defined in the DESIGN.md YAML. Every color token has a value. Grep for `transfer-paid`, `transfer-open`, `locked`, `badge-settled`, `transfer-card-open/paid` and `payment-row` finds nothing in either spine, except the intentional "Removed on 2026-10-29" notes. Recomputed the stated contrast ratios (white on header-end 3.74, white on orange 3.56, ink-secondary 4.51 and 4.83, archived card 6.79). All are correct.

### Findings
- **high** The header badge "🗂 בארכיון" and the "⚙ ✎" chip are white text on `{colors.badge-on-header-surface}` (22% white) laid over the gradient. That gives 3.58:1 over `{colors.header-start}` but only **2.74:1 over `{colors.header-end}`**, below the 3:1 large-text minimum. This breaks NFR-4 (WCAG 2.1 AA) and DESIGN's own contrast rule, which was only worked out for the bare gradient (DESIGN.md l.208, l.215, l.278). *Fix:* use a darker overlay (for example a translucent `{colors.ink}` at about 20%, or `{colors.header-start}` solid), or pin badges and chips to the header-start side. Then state the worst-case ratio in Colors.
- **low** `badge-on-header-surface` and `scrim` are `rgba(...)`, not hex as design-md-spec requires (DESIGN.md l.37, l.40). *Fix:* use 8-digit hex (`#FFFFFF38`, `#0B2B2873`).
- **low** Several component token values are prose and cannot be resolved: `background: '{colors.member-1}..{colors.member-6} by add order'`, `edge: '6dp start-edge, category color'`, `rows: '1 for up to 6 Members, 2 for 7-10'`, and an unquoted `slot: 48dp wide, 48dp hit area` (DESIGN.md l.151–169). *Fix:* keep the rule in prose and leave single values in the tokens, or add a `note:` key.
- **low** No contrast target is stated for `badge-active-ink`/`badge-active-surface` (6.38), `archived-ink`/`archived-surface` (8.4), `danger` on canvas (6.03) or the hint in `ink-muted` (7.07). All of these pass. More important, the selected Category tile border is a non-text indicator, and several category hues fall below WCAG 1.4.11's 3:1 on white (Food & drink 2.28, Fuel 2.15). The bold label and the tint make up for it. *Fix:* add one line to Colors that lists these pairs and says the selected state never relies on the border alone.
- **low** `input-border`, `input-border-focus` and `on-danger` are defined but never referenced, and there is no text-field or danger-button component to own them (DESIGN.md l.24–25, l.39). See §3.

## 3. Component coverage — adequate

Checked: every component named in either file was looked up in DESIGN.md › Components (visual) and EXPERIENCE.md › Component Patterns (behavior). The core components are covered on both sides: Header block, Buttons, Expense row, Category tile, Payer picker, Member avatar, Transfer card, Bottom sheet, Snackbar, Keypad, Archive note and Page dots.

### Findings
- **medium** Components with a visual spec but no behavioral row: **Toggle** (see §1 high), **Group card** (what a tap does, and whether long-press does anything), **Archived group card** (the tap and "↩ שחזור" behavior appears only in State Patterns), and **Compact top bar** (✕ and the "🗑 מחיקה" chip appear only inside other rows). *Fix:* add rows to Component Patterns for each.
- **medium** Components used in the spines or mocks with no visual spec in DESIGN.md: **text field / Name field** (create, add-member, rename sheet, Description; the input-border tokens are orphaned), **Member list row** (avatar, name, ✎, ✕; 36dp avatar in the mocks), **Settings row** ("שם הקבוצה ›", "קבוצה פעילה" + toggle), **danger button** variant (Delete "מחיקה", Exit "יציאה"), the **Archive link** "🗂 ארכיון (n)", the "↩ שחזור" text button on archived cards, and the inline **validation message**. *Fix:* add short entries to Components and wire up `input-border*` and `on-danger`.
- **low** Component names differ between the two files: "Keypad" vs "Custom keypad", "Member avatar" vs "Member avatar label", "Page dots" vs `page-dot`, "Archive note" vs "Archive note + restore". *Fix:* use one name everywhere, and put behavioral qualifiers in the row text.
- **low** DESIGN.md l.218 says danger is "only for delete actions and validation messages", but l.288 colors the Exit sheet's "יציאה" with `{colors.danger}`. *Fix:* widen the rule to "destructive actions (delete, discard input)".

## 4. State coverage — adequate

Checked: walked all 13 IA surfaces (Group list, Archive, Create group, Active-group sheet, Group page, Add expense, Edit expense, Exit sheet, Delete sheet, Group settings, Rename, Archive and Remove-member sheets, Summary) against empty, populated, validation, <2 Members, 7–10 Members, archived, font-scale and saving states. Coverage is strong for Add expense, the Group page and the Summary.

### Findings
- **high** Group settings has no Active-toggle states (on with another Group active, on with none active, off). Same root cause as §1. EXPERIENCE.md l.153–156.
- **medium** The outcome of archiving is unspecified. FR-6 and EARS l.60 say archiving the Active group also unsets it, but neither the spine nor the badge rules mention this. Also missing: where the Organizer lands after confirming the Archive sheet (the Group page is now archived and Group settings is closed), and what the Archive view shows when its last Group is restored while it is open. Today the link is "hidden at 0", but the user is still on the screen. EXPERIENCE.md l.39, l.131. *Fix:* add a state row for each.
- **medium** The Add expense Error state says "Inline message in `{colors.danger}`" (EXPERIENCE.md l.145) but does not say where. The region above the keypad must never scroll, and its height budget is tight (DESIGN.md l.255: about 655dp, or 725dp with two payer rows). A message that adds height could push the layout over budget. *Fix:* fix the position, for example a single-line slot that replaces the amount caption or sits inside the amount area, and say it reserves no extra height.
- **medium** The Expense row date and time format is unspecified (FR-12). The mocks show three forms: "היום 14:32", "אתמול 15:40" and "14.04 20:10" (key-screens #2, settle-up #5). The Edit initial state shows "נרשם {date time} · נערך עכשיו" before any edit (EXPERIENCE.md l.148), which is ambiguous: is it the last-modification time or literally "now"? *Fix:* add the format rule (today / yesterday / dd.mm) to Voice and Tone, and define the edited fragment (for example only after a saved edit, using NFR-12's last-modification time).
- **low** Edit expense: what happens to the Description when the Category changes from *Other* to another one (cleared or kept) is not stated. On the keypad, a second "." and a leading "." are not specified. *Fix:* one line each in Component Patterns.

## 5. Visual reference coverage — adequate

Checked: all three mockups are linked inline with what they show (DESIGN.md l.310, EXPERIENCE.md l.45), and both files and every mock lead say the spines win on conflict. In the v1-valid screens, every NFR-6 string matches the PRD exactly. "רומא" and "←" Transfer arrows appear only in the gray, flagged deferred screens 1–4 and 7. In key-screens #4 and #6 and settle-up #6, the Transfer lines use `<bdi>`, carry no arrow, hyphenate correctly ("מ-Zoe") and follow the FR-15 order. The amounts in the UJ-4, 10-Member and archived Summaries agree with the FR-15 calculation (Share ₪826.6, Leftover ₪0.2).

### Findings
- **medium** It is unclear whether the "⚙ ✎" chip appears on the Summary. DESIGN's Header block describes the chip with no exception except archived Groups (DESIGN.md l.278), so it would appear on the Summary and in the screenshot sent to friends. The Summary mocks leave it out (key-screens #4 and #6). *Fix:* state in Header block and in the Screenshot Contract that the chip appears on the Group page only.
- **low** Small mismatches between mocks and spine: the wide Save button is 60px in the mocks against 64dp for `button-primary` (key-screens `.wsave`), and DESIGN never says whether Save is a `button-primary`. The Category tile label is 11.5px, below `typography.label` at 12sp. The archived Summary (settle-up #6) has no category stripe, although DESIGN.md l.278 puts the stripe on every Summary. The "מי מעביר למי" title has no typography token (15px in the mocks). *Fix:* name Save's token and height, give the section title a token, and fix the mocks when they are next updated.
- **low** In secondary-screens.html, the footer note still lists three items as "ממתין לאישור" (payer order, Exit wording, disabled style). The memlog records that the founder confirmed all three on 2026-10-29. *Fix:* remove the note.
- **low** The header comment in settle-up-screens.html still names removed DESIGN components (Payment row, Clear-mark sheet, Payments color) and FR-17–FR-19 as "Governing spine sections". It is labeled superseded, but anyone extracting from it could be misled. *Fix:* cut the list down to the v1 screens 5, 6 and 8.
- **low** There is no mock for the Archive view, the Rename sheet, the Archive sheet or the Remove-member sheet. The spine text is enough to build them; this is noted only for completeness.

## 6. Bloat & overspecification — adequate

### Findings
- **low** History and changelog text is mixed into the contract: "Closed in the 2026-10-29 update…" (EXPERIENCE.md l.262), "Product Decisions Under Review", which now holds only a resolved item (l.264–268), and "Removed on 2026-10-29" (DESIGN.md l.217, l.294). *Fix:* move the history to `.memlog.md`, rename the resolved decision to a short "Calculation display" note, and keep a single deferred pointer.
- **low** Both files have `status: draft`, but the memlog records founder confirmation and "spines finalized". *Fix:* set `status: final` when that is intended, so consumers treat the files as binding.

## 7. Inheritance discipline — adequate

Checked: the `sources` paths all resolve (brief, PRD, `../../../../ears-requirements.md`). The UJ headings match the PRD word for word. The 17 NFR-6 fixed messages in EXPERIENCE.md l.61–77 are identical to PRD l.262–278, and EXPERIENCE says no emoji or punctuation may be added. "Member" is "משתתף" throughout. Spine statements checked against FR-1…FR-16 and §7 include default Payer, save order, the 5-tap budget, the Leftover rule, Transfer order, the share line and archive read-only. None contradicts the PRD.

### Findings
- **medium** The deferred-design pointer does not resolve. DESIGN.md l.217 and l.294 and EXPERIENCE.md l.22 say the paid, locked and settled colors and the component specs "are kept with the earlier design in the PRD `addendum.md`". The addendum (§"Deferred from v1") holds only behavior, with no hex values and no visual or component specs. *Fix:* point to `mockups/settle-up-screens.html` and the git history (commit before 2026-10-29), or copy the removed token values into the addendum.
- **low** The Foundation vocabulary list (EXPERIENCE.md l.21) leaves out the Glossary terms **Leftover** and **Balance**, which Product Decisions uses. *Fix:* add them, or write "the full §3 Glossary".
- **low** Some UI texts appear in mocks or prose but not in the free-text table: the Group page secondary line "{n} משתתפים · {m} הוצאות" and its singular "משתתף אחד", the Create group stage-1 top-bar title "קבוצה חדשה", "קבוצה פעילה", "+ הוספת משתתף", "שם הקבוצה ›", and the Delete-sheet expense-line format ("🛒 אוכל ושתייה · מוטי · ₪87"). *Fix:* add them to the free-text table.

## 8. Shape fit — strong

Checked: DESIGN.md has YAML frontmatter with name, description, colors, typography, rounded, spacing and components, and its body follows the canonical order: Brand & Style → Colors → Typography → Layout & Spacing → Elevation & Depth → Shapes → Components → Do's and Don'ts. EXPERIENCE.md has frontmatter with sources and all the required sections: Foundation, IA, Voice and Tone, Component Patterns, State Patterns, Interaction Primitives, Accessibility Floor, Inspiration & Anti-patterns and Key Flows. Responsive is omitted, which is correct for a single surface. Screenshot Contract and Open Questions add useful information.

### Findings
- **medium** NFR-3 hit areas are stated only for buttons, tiles, keypad keys and payer avatars (EXPERIENCE.md l.174). Several small controls have no 48×48dp hit area: the Toggle (52×30dp visual), the ✎ and ✕ icons on Member rows, the "⚙ ✎" and "🗑 מחיקה" chips, the ✕ close, the "↩ שחזור" text button and the Archive link. *Fix:* add one rule: "every control smaller than 48dp has a 48×48dp hit area", and list these controls.
- **medium** FR-16's one-screen guarantee for ≤6 Members is still open (Open Question 1, EXPERIENCE.md l.257). Five Transfers with wrapped names need about 724dp, against about 700–730dp available, and no fallback is committed. A developer cannot verify EARS T3.46 against this. *Fix:* commit a fallback that applies when the budget is exceeded at default font, for example dropping the stripe margin or a tighter header on the Summary. Or mark the item as gating, with an owner and a date tied to PRD §10 Q2.

## Mechanical notes

- Token refs extracted: 61 distinct, 0 unresolved, 0 removed-token leftovers.
- NFR-6 fixed messages: 17 of 17 verbatim in EXPERIENCE.md. Every string used in the v1-valid mock screens is verbatim.
- UJ headings: 4 of 4 verbatim. Each has a protagonist, numbered steps and a climax. 3 of 4 have a failure or edge path.
- Contrast recomputed: white over `badge-on-header-surface` gives 3.58:1 on header-start and 2.74:1 on header-end (fails). Category borders on white: Food & drink 2.28:1, Fuel 2.15:1 (non-text).
- Mock data checks: the UJ-4 Summary (₪8,400, share ₪2,100) and the 10-Member Summary (₪16,000, 8 Transfers, unique minimal list, correct debtor order with Latin last) are consistent with FR-15. The archived Summary (₪2,480 / 3, share ₪826.6, Leftover ₪0.2 taken from מוטי) is also consistent.
- Deferred screens (settle-up 1–4, 7) are gray and flagged. "רומא" and arrows appear only there.
- Unused YAML tokens: `input-border`, `input-border-focus`, `on-danger`.
