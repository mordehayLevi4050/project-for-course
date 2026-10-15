# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

GrouPay is a Flutter app (Android now, iOS later) for splitting shared trip/restaurant expenses equally within a group, styled after the Israeli bit app. Single local user, no accounts; all data lives in one JSON file on the device. It is a learning project for a course, published at https://github.com/mordehayLevi4050/project-for-course.

- The app UI is Hebrew, right-to-left, amounts in shekels (₪). UI strings are hardcoded Hebrew in the widgets (no l10n files).
- README and code/comments are in English.
- Plans live in `docs/plans/` (set via `plansDirectory` in `.claude/settings.json`), numbered by stage, e.g. `01-home-and-group-screens.md`.

## Commands

Flutter is not on the PATH in Claude Code sessions; call it by full path: `C:\src\flutter\bin\flutter.bat`. The Android SDK is at `C:\Android\Sdk` (adb: `C:\Android\Sdk\platform-tools\adb.exe`).

```bash
flutter analyze                                   # lint, must stay clean
flutter test                                      # all tests
flutter test test/settlement_test.dart            # one file
flutter test test/settlement_test.dart --plain-name "leftover agorot"   # one test by name
flutter emulators --launch Pixel_6a               # the only AVD
flutter run -d emulator-5554
```

Regenerating the launcher icon after changing `GroupayLogo`:

```bash
flutter test tool/render_icon_test.dart   # renders assets/icon/icon.png and icon_foreground.png
dart run flutter_launcher_icons            # config is in pubspec.yaml
```

## Architecture

- **Single source of truth:** `AppState` (`lib/state/app_state.dart`, a `ChangeNotifier` provided at the root in `main.dart`) holds the full `List<Group>`. Every mutation replaces the group via `copyWith`, calls `notifyListeners()`, then saves the whole list. Screens read it with `context.watch<AppState>()` and look groups up by id (`groupById`) rather than holding `Group` objects, so they always reflect the latest state.
- **Models are immutable** (`lib/models/`). A `Group` owns its `members` and `expenses`; an `Expense` references its payer by `payerId`. Expenses are stored newest-first.
- **Persistence:** `GroupStore` interface in `lib/data/json_storage.dart`. `JsonStorage` writes `groupay_data.json` (`{version, groups}`) via a temp file + rename. Tests inject an in-memory `GroupStore` instead.
- **Money:** all amounts are `int` agorot. Use `formatShekels` / `parseShekels` in `lib/logic/money.dart`; never store doubles.
- **Settlement is derived, never stored:** `Settlement.of(group)` (`lib/logic/settlement.dart`) computes equal shares (leftover agorot go one each to the first members, so shares sum exactly to the total), balances (paid − share) and greedy minimal transfers. It is recomputed on every build of the group screen.
- **Domain rules enforced in `AppState`:** duplicate member names in a group are rejected (`addMember` returns false); a member who paid an expense cannot be deleted (`deleteMember` returns false).
- **Screens:** `GroupsScreen` (home) → `GroupScreen` (who-owes-whom `SettlementCard` at the top, expense list below) → `AddExpenseScreen`; members are managed in a bottom sheet (`members_sheet.dart`). Every screen uses `GroupayAppBar` (logo + "GrouPay" + optional subtitle).
- **Logo:** `GroupayLogo` is drawn with `CustomPainter` (including the ₪ sign as paths, so it does not depend on fonts); the same painter renders the launcher icon PNGs.

## RTL and testing gotchas

- In RTL, directional icons like `Icons.arrow_forward` are mirrored automatically. Don't use invisible bidi marks (e.g. U+200E) to fix text ordering; they garbled mixed name/amount text before. Put the parts in separate `Text` widgets in a `Row` instead.
- Widget tests: call `tester.pump()` after `enterText` before tapping a button whose enabled state depends on the text. Pop routes via `tester.state<NavigatorState>(find.byType(Navigator)).pop()`; `tester.pageBack()` does not find the back button here. The test font is wide, so text in `Row`s must be wrapped in `Expanded`/`Flexible` or tests fail on overflow.

## Environment notes

- Building for Android needs NDK 28.2.13676358 (installed in `C:\Android\Sdk\ndk`).
- Emulator keyboard: the AVD keeps `hw.keyboard=yes`, and Gboard's "Show on-screen keyboard while using physical keyboard" is enabled; Hebrew is added to Gboard. To type into the emulator from scripts, use `adb emu event text <text>` (adb `input text` cannot type Hebrew).
- `git push` uses a repo-local credential helper (`!gh auth git-credential` in `.git/config`); don't change the global git config.
