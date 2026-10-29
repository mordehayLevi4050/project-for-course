---
name: GrouPay
description: Hebrew-first Android app for splitting trip expenses. Minimalist, professional, colorful. Big buttons, few taps, light theme only.
status: draft
created: 2026-10-26
updated: 2026-10-29
sources:
  - ../../briefs/brief-groupay-2026-10-26/brief.md
  - ../../prds/prd-groupay-2026-10-26/prd.md
  - ../../../../ears-requirements.md
colors:
  header-start: '#0F766E'
  header-end: '#0D9488'
  on-header: '#FFFFFF'
  primary: '#EA580C'
  on-primary: '#FFFFFF'
  surface-base: '#F3F8F7'
  surface-raised: '#FFFFFF'
  ink: '#0B2B28'
  ink-secondary: '#6B7280'
  ink-muted: '#475569'
  secondary-ink: '#0F766E'
  secondary-border: '#99CFC9'
  input-border: '#CDE3DF'
  input-border-focus: '#0D9488'
  currency-mark: '#0D9488'
  transfer-surface: '#E6F4F1'
  transfer-edge: '#EA580C'
  toggle-off: '#CBD5E1'
  toggle-on: '#0F766E'
  archived-surface: '#E2E8F0'
  archived-ink: '#334155'
  archived-card-surface: '#F1F3F5'
  archived-card-ink: '#4B5563'
  badge-active-surface: '#FFEDD5'
  badge-active-ink: '#9A3412'
  badge-on-header-surface: '#0B2B2840'
  danger: '#B91C1C'
  on-danger: '#FFFFFF'
  scrim: 'rgba(11,43,40,0.45)'
  category-flight: '#3B82F6'
  category-hotel: '#8B5CF6'
  category-car: '#14B8A6'
  category-fuel: '#F59E0B'
  category-restaurant: '#EF4444'
  category-food-drink: '#22C55E'
  category-attractions: '#EC4899'
  category-other: '#64748B'
  member-1: '#1D4ED8'
  member-2: '#9333EA'
  member-3: '#C2410C'
  member-4: '#BE185D'
  member-5: '#047857'
  member-6: '#A16207'
  on-member: '#FFFFFF'
typography:
  trip-total:
    fontFamily: Heebo
    fontSize: 40sp
    fontWeight: 800
  amount-entry:
    fontFamily: Heebo
    fontSize: 46sp
    fontWeight: 800
  screen-title:
    fontFamily: Heebo
    fontSize: 22sp
    fontWeight: 700
  header-secondary:
    fontFamily: Heebo
    fontSize: 18sp
    fontWeight: 700
  transfer-amount:
    fontFamily: Heebo
    fontSize: 26sp
    fontWeight: 800
  button-primary:
    fontFamily: Heebo
    fontSize: 19sp
    fontWeight: 700
  button-secondary:
    fontFamily: Heebo
    fontSize: 16sp
    fontWeight: 600
  row-title:
    fontFamily: Heebo
    fontSize: 16sp
    fontWeight: 600
  row-amount:
    fontFamily: Heebo
    fontSize: 17sp
    fontWeight: 700
  keypad-digit:
    fontFamily: Heebo
    fontSize: 24sp
    fontWeight: 600
  avatar-initial:
    fontFamily: Heebo
    fontSize: 22sp
    fontWeight: 800
  label:
    fontFamily: Heebo
    fontSize: 12sp
    fontWeight: 600
  meta:
    fontFamily: Heebo
    fontSize: 12sp
    fontWeight: 400
  message:
    fontFamily: Heebo
    fontSize: 14sp
    fontWeight: 400
rounded:
  sm: 10dp
  md: 14dp
  lg: 18dp
  xl: 24dp
  full: 9999px
spacing:
  '1': 4dp
  '2': 8dp
  '3': 12dp
  '4': 16dp
  '5': 20dp
  '6': 24dp
  list-fade: 56dp
  margin-mobile: 16dp
components:
  header-block:
    background: 'linear-gradient(135deg, {colors.header-start}, {colors.header-end})'
    textColor: '{colors.on-header}'
    padding: '{spacing.3} {spacing.5} 30dp'
  button-primary:
    background: '{colors.primary}'
    textColor: '{colors.on-primary}'
    typography: '{typography.button-primary}'
    height: 64dp
    rounded: '{rounded.full}'
    shadow: '0 6dp 16dp {colors.primary} @35%'
  button-secondary:
    background: '{colors.surface-raised}'
    textColor: '{colors.secondary-ink}'
    border: '1.5dp {colors.secondary-border}'
    typography: '{typography.button-secondary}'
    height: 64dp
    rounded: '{rounded.full}'
  expense-row:
    background: '{colors.surface-raised}'
    minHeight: 72dp
    rounded: '{rounded.lg}'
    edge: '6dp start-edge, category color'
    iconCircle: '46dp, category color @15% tint'
  category-tile:
    background: '{colors.surface-raised}'
    height: 64dp
    rounded: '{rounded.lg}'
    selectedBorder: '2dp category color'
    selectedBackground: 'category color @16% tint'
  member-avatar:
    size: 44dp
    slot: 48dp wide, 48dp hit area
    background: '{colors.member-1}..{colors.member-6} by add order'
    textColor: '{colors.on-member}'
    typography: '{typography.avatar-initial}'
    rounded: '{rounded.full}'
  payer-picker:
    columns: 6
    rowGap: '{spacing.2}'
    rows: '1 for up to 6 Members, 2 for 7-10'
  transfer-card:
    background: '{colors.transfer-surface}'
    edge: '6dp start-edge {colors.transfer-edge}'
    textColor: '{colors.ink}'
    typography: '{typography.row-title}'
    amountTypography: '{typography.transfer-amount}'
    avatarSize: 32dp
    minHeight: 64dp
    rounded: '{rounded.lg}'
  button-disabled:
    opacity: 40%
    shadow: none
  page-dot:
    size: 8dp
    activeColor: '{colors.secondary-ink}'
    inactive: '1.5dp ring {colors.ink-secondary}'
    gap: '{spacing.2}'
  keypad-key:
    background: '{colors.surface-base}'
    height: 48dp
    rounded: '{rounded.md}'
    typography: '{typography.keypad-digit}'
  bottom-sheet:
    background: '{colors.surface-raised}'
    rounded: '{rounded.xl} {rounded.xl} 0 0'
    scrim: '{colors.scrim}'
---

## Brand & Style

GrouPay is the place where a trip's money gets sorted out, so it has to feel trustworthy and light at once. Three words set the posture: **minimalist, professional, colorful**. The color comes from two places: a bold teal header that says *travel*, and a fixed color per expense category that turns the list into something you can scan at a glance. Everything else stays quiet: white cards on a pale teal-white canvas, generous rows, no clutter.

The touchstones are explicit. From **PassportCard** GrouPay borrows colorfulness: a confident colored block at the top of the screen. From **Bit** it borrows big, obvious buttons and a flow you understand without reading. **PayBox** is the counter-example: an overcrowded, uninviting screen. When in doubt, show less.

Light theme only. There is no dark mode in v1.

## Colors

- **Lagoon gradient (`{colors.header-start}` → `{colors.header-end}`, 135°)** is the brand surface. It sits behind the header block on the home screen, the Group page and the Summary, and behind the compact top bar on full-screen forms. It holds the group name and the Trip total. Text on it is always `{colors.on-header}`. **Contrast rule:** white on `{colors.header-end}` is 3.74:1, so every text on the gradient must be large text (≥18sp bold, or ≥24sp regular). This is why secondary header lines use `{typography.header-secondary}`.
- **Orange (`{colors.primary}`)** is the single action color: *Add expense*, *Save*, *New group*, and the confirm button in bottom sheets. It also marks the active group in the group list and the Transfer card edge on the Summary. White on orange is 3.56:1, so labels on it always use `{typography.button-primary}` (19sp bold) or larger.
- **Canvas (`{colors.surface-base}`)** is the page background. **Cards (`{colors.surface-raised}`)** are white.
- **Ink (`{colors.ink}`)** is primary text. **`{colors.ink-secondary}`** is for meta lines (payer · time), and passes AA on both canvas (4.51:1) and white (4.83:1). Do not go lighter.
- **Category colors** are fixed and never change meaning: Flight `{colors.category-flight}`, Hotel `{colors.category-hotel}`, Car `{colors.category-car}`, Fuel `{colors.category-fuel}`, Restaurant `{colors.category-restaurant}`, Food & drink `{colors.category-food-drink}`, Attractions `{colors.category-attractions}`, Other `{colors.category-other}`. They are used only as non-text marks: the row's start-edge stripe, the 15% tint behind the emoji, the selected category tile, and segments of the category share stripe. Never as text color.
- **Member colors (`{colors.member-1}` … `{colors.member-6}`)** fill member avatar circles. They are assigned automatically in the order members were added; member 7 starts again at `{colors.member-1}`, so in a 10-Member Group members 7–10 repeat colors 1–4 and the initial letter and name tell them apart. All pass AA with white initials (≥4.9:1). They are darker than the category hues on purpose, so a person never reads as a category.
- **Transfer card:** `{colors.transfer-surface}` with a `{colors.transfer-edge}` start edge and `{colors.ink}` text. There is a single Transfer style in v1 (no paid state).
- **Status badges:** active (`{colors.badge-active-surface}` / `{colors.badge-active-ink}`) and archived (`{colors.archived-surface}` / `{colors.archived-ink}`). On the gradient, badges and the "⚙ ✎" chip use `{colors.badge-on-header-surface}` (`{colors.ink}` at 25% opacity) with white text. This overlay darkens the gradient, so white text on it is 7.07:1 over `{colors.header-start}` and 5.22:1 over `{colors.header-end}` (worst case), above the 4.5:1 AA floor even for normal-size text. Never use a light (white) overlay on the gradient: it lowers contrast (22% white gave 2.74:1 over `{colors.header-end}`).
- **Archived surfaces:** archived Group cards use `{colors.archived-card-surface}` with `{colors.archived-card-ink}` text (6.8:1); the archive note uses `{colors.archived-surface}` with `{colors.archived-ink}`.
- **Removed on 2026-10-29 (deferred to the next version, PRD §6.2):** the paid-transfer, locked and settled-badge colors and the Payment row. Their values are kept with the earlier design in the PRD `addendum.md`. The archived colors above reuse two of the old values under new names.
- **Danger (`{colors.danger}`)** is only for delete actions and validation messages.

## Typography

One family: **Heebo** (Google Fonts), bundled with the app so it works offline. It is clean and geometric, and its numerals are clear at large sizes.

| Role | Token | Used for |
|---|---|---|
| Trip total | `{typography.trip-total}` | Total in the header block |
| Amount entry | `{typography.amount-entry}` | Amount on the add/edit screen |
| Transfer amount | `{typography.transfer-amount}` | Amount on a transfer card |
| Screen title | `{typography.screen-title}` | Group name in header, top-bar title |
| Header secondary | `{typography.header-secondary}` | "4 משתתפים · 8 הוצאות", share line. Large on purpose (contrast rule). |
| Button primary / secondary | `{typography.button-primary}` / `{typography.button-secondary}` | Pill buttons |
| Row title / amount | `{typography.row-title}` / `{typography.row-amount}` | Expense rows, group cards |
| Keypad digit | `{typography.keypad-digit}` | Custom keypad |
| Avatar initial | `{typography.avatar-initial}` | Letter inside member circle, enlarged so members stay distinct when colors repeat |
| Label / meta / message | `{typography.label}` / `{typography.meta}` / `{typography.message}` | Field labels, row meta, inline messages |

**Font scaling.** All sizes are `sp` and follow the system font scale up to 150%. Every fixed height in this file (buttons, rows, tiles, keypad keys, top bar) is a minimum: it grows with its text, and labels wrap to a second line instead of truncating. Category tile labels and avatar names may take two lines.

Amounts are always rendered as an LTR run inside RTL text, with the `₪` before the number. Whole amounts have no decimals (`₪1,250`); any other amount has exactly one decimal (`₪87.4`, `₪33.3`), never two. This applies everywhere: lists, the Trip total, the share line and Transfers (PRD FR-15). On the amount entry screen the `₪` is tinted `{colors.currency-mark}`.

## Layout & Spacing

Scale: 4 / 8 / 12 / 16 / 20 / 24 dp. Side margin `{spacing.margin-mobile}`. Single column, full RTL: start is the right edge.

**Thumb zone.** Every primary action sits in the bottom band of the screen. The primary button is on the **right** (start) and takes about two thirds of the width. The secondary button is on the left and takes about one third.

**Group page composition** (top to bottom): header block → expense cards, which overlap the header's bottom edge by 16dp → fade → bottom button bar. Rows are large on purpose: only **4–5 expenses** are visible without scrolling.

**List-to-button separation.** The list fades into `{colors.surface-base}` over `{spacing.list-fade}` above the button bar. There is no tray. The list has bottom padding equal to the bar height plus the fade, so the last row comes to rest above the buttons, never under them.

**Home screen exception.** The header titles are centered, and the group list starts with a clear gap below the header. Cards do not overlap it.

**Summary composition** (top to bottom; PRD FR-16): header block → "מי מעביר למי" title → Transfer cards with an 8dp gap, or "החשבון מאוזן, אין צורך בהעברות" when there are none → archive note, when archived. There is no bottom button bar on the Summary. Up to 6 Members everything is fixed. For 7–10 Members the header and the title stay fixed, and the Transfer cards scroll inside the remaining height; their bottom edge fades into `{colors.surface-base}` over `{spacing.list-fade}` when more cards exist.

**Add/edit expense composition** (top to bottom): compact top bar → amount → payer picker (`components.payer-picker`: 6 avatars per row, one row up to 6 Members, two rows for 7–10, never scrolls) → 4×2 category grid → custom keypad (3×4) → wide Save button. No section labels above the payer picker or the grid. The keypad and Save are pinned to the bottom inside the system insets (Android 15 draws edge-to-edge). The region above them never scrolls. Estimated height at default font is about 655dp before insets with one payer row, which fits 360×780dp phones with either navigation mode. A second payer row adds about 70dp (about 725dp), which fits gesture navigation only; when it does not fit, the two-page Category row below takes over and saves about 50dp. Six 48dp slots with 8dp gaps fill the 328dp content width of a 360dp phone exactly. If the 4×2 grid does not fit at the required touch-target size (small screen or enlarged font), the Categories switch to a sideways row of at most two pages, and one swipe shows the second page (PRD FR-10). The row keeps the tile size, and the first tile of the other page peeks in about a quarter tile at the edge. Two page dots (`components.page-dot`) sit centered under the row, `{spacing.2}` below it. The *Other* state swaps the keypad for a description field plus the system text keyboard, with Save just above it.

## Elevation & Depth

Elevation is minimal and used for two jobs only:

- **Cards lift slightly** off the canvas (`0 1dp 3dp` at 6%). This applies to expense rows, group cards and category tiles.
- **The orange primary button glows** (`0 6dp 16dp` orange at 35%). It is the only element with a strong shadow, so it reads as *the* thing to press.

Bottom sheets sit over `{colors.scrim}`. Transfer cards are flat (no shadow); their tint and edge set them apart.

## Shapes

Soft and friendly, never sharp.

- `{rounded.full}`: all buttons (pills), avatars, the Active toggle, emoji circles.
- `{rounded.xl}`: top corners of bottom sheets and of the keypad panel.
- `{rounded.lg}`: expense rows, transfer cards, group cards, category tiles.
- `{rounded.md}`: keypad keys, text fields.
- `{rounded.sm}`: badges.

## Components

- **Header block.** Lagoon gradient. Contents: nav line (back or "☰ הקבוצות שלי", plus the badge "🗂 בארכיון" when archived) → group name with a **"⚙ ✎" tap affordance chip** (hidden on an archived Group) → Trip total in `{typography.trip-total}` → secondary line in `{typography.header-secondary}` → **category share stripe**: 8dp tall, segments proportional to each category's share of the Trip total, in category colors, with 2dp gaps. The stripe appears on the Group page and the Summary.
- **Compact top bar** (add/edit, create group). Gradient, 56dp. ✕ close on the start side, the group name centered. On edit, a red **"🗑 מחיקה"** chip on the end side (`{colors.danger}`).
- **Button primary / secondary.** See tokens. They always carry a text label. Never icon-only. **Disabled** (`components.button-disabled`): the same button at 40% opacity with no shadow, label unchanged. Used for "+ הוספת הוצאה" and "סיכום" while the Group has fewer than 2 Members; the fixed hint sits above the bar in `{typography.message}`, `{colors.ink-muted}`.
- **Expense row.** White card, 6dp start-edge stripe and 46dp tinted emoji circle in the category color, title (category name, or the Description for *Other*), meta line "payer · date time", amount on the end side.
- **Category tile.** Emoji (22sp) above the name. When selected: 2dp border and 16% tint in the category color, bold label. Emoji: ✈️ Flight · 🏨 Hotel · 🚗 Car · ⛽ Fuel · 🍝 Restaurant · 🛒 Food & drink · 🎡 Attractions · 📝 Other.
- **Member avatar.** Circle in the member color, showing the first letter of the first name in `{typography.avatar-initial}`. **The first name always appears under the circle.** If two members share a first name, both show first and last name. Selected state (payer picker): a 3dp canvas gap ring plus a 2dp ring in the member's color. Unselected avatars are shown at 55% opacity.
- **Payer picker** (PRD FR-10). A grid of member avatars, 6 per row, each in a 48dp-wide slot (`components.payer-picker`). One row up to 6 Members; a second row, aligned to the start side, for 7–10. A name of up to 10 characters wraps to two lines under the circle and is never truncated. No horizontal scroll and no edge fade.
- **Transfer card** (PRD FR-16). One line per Transfer: from the start side, a decorative pair of 32dp member avatars (debtor, then receiver, 4dp apart, with **nothing between them**), then the sentence "תשלום נדרש מ{debtor} ל{receiver}" in `{typography.row-title}`, then the amount in `{typography.transfer-amount}` closing the line on the end side. **No arrow and no other direction symbol** anywhere in the card (NFR-6). Names are bidi-isolated runs. Long names wrap to a second line inside the card; the amount stays at the end. The small avatars show only the initial; the names are in the sentence, so no name is printed under them. No toggle, no stamp, not tappable.
- **Toggle.** 52×30dp, `{colors.toggle-off}` / `{colors.toggle-on}`. Used only for the Active setting in Group settings.
- **Group card** (home). Name, member count, total. The active group gets a 6dp orange start edge plus the badge "⭐ פעילה".
- **Bottom sheet.** Grab handle, title, body, optional warning strip (`{colors.badge-active-surface}`), and a button row with primary on the start side. The Exit sheet uses the Delete sheet's anatomy, with "יציאה" in `{colors.danger}` and "המשך עריכה" as the secondary button.
- **Archived group card.** Same anatomy as the Group card, but with `{colors.archived-card-surface}` background, `{colors.archived-card-ink}` text and no colored edge.
- **Archive note** (PRD FR-6). On an archived Group page and Summary: a strip in `{colors.archived-surface}` with `{colors.archived-ink}` text in `{typography.message}`, starting with 🗂. On the Group page it sits right above the bottom bar, where "↩ שחזור מהארכיון" is the orange primary button. On the Summary it sits under the Transfer cards. The header shows the badge "🗂 בארכיון".
- **Page dots** (PRD FR-10). Two 8dp dots per `components.page-dot`: current page filled `{colors.secondary-ink}`, other page an outlined ring in `{colors.ink-secondary}`. Shown only for the two-page Category row.
- **Snackbar.** Pill in `{colors.ink}` with white text, at the bottom above the button bar. Used for "ההוצאה נמחקה".
- **Keypad.** White panel with `{rounded.xl}` top corners. Keys 1–9, `.`, 0, ⌫, in LTR digit order. There is no "00" key. Below it is the wide Save button.
- **Deferred to the next version (2026-10-29).** The Transfer toggle and paid card, Payments section, Payment row, Clear-mark sheet, Payment delete sheet, Lock box and the "🔒 נעולה" / "✓ מסולקת" badges are removed from v1 (PRD §6.2). Their earlier specs are preserved in the PRD `addendum.md` and in the marked screens of `mockups/settle-up-screens.html`.

## Do's and Don'ts

| Do | Don't |
|---|---|
| One action color (orange), used on the primary button of each screen | A second competing accent, or orange used decoratively |
| Category color as stripe, tint and selection border | Category color as text, or on a full row background |
| Text on the gradient ≥18sp bold | Small regular text on the header |
| Orange-button labels ≥19sp bold | Shrinking a primary label to fit |
| Text label on every button | Icon-only buttons (rejected in the design session) |
| 4–5 big rows visible, with a fade before the buttons | Packing more rows in, or rows touching the button bar |
| Transfer direction in words: "תשלום נדרש מ… ל…" | Arrows or any direction symbol between names or avatars |
| First name under every avatar (except the decorative pair on a Transfer card, whose names are in the sentence) | Initials-only avatars elsewhere |
| All Members visible in the payer picker, wrapping to a second row | A horizontally scrolling payer row |

Visual references: `mockups/key-screens.html` (Group list, Group page, Add expense, Summary, plus Add expense and Summary with 10 Members), `mockups/secondary-screens.html` (Create group in two stages, Edit expense with the Delete sheet, Exit sheet, Group settings, Group page with fewer than 2 Members) and `mockups/settle-up-screens.html` (archived Group page and Summary, two-page Category row; its settle-up tracking screens are marked as deferred). This spine wins on conflict with any mockup.
