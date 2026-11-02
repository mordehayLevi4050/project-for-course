---
title: 'Story 1.1 (part 1): Project foundation and shared kernel'
type: 'feature'
created: '2026-11-02'
status: 'ready-for-dev'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-1-context.md'
  - '{project-root}/_bmad-output/planning-artifacts/architecture/architecture-groupay-2026-10-29/ARCHITECTURE-SPINE.md'
  - '{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-groupay-2026-10-26/DESIGN.md'
  - '{project-root}/CLAUDE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The repo is still the throwaway Flutter scaffold (`com.example.groupay`, a Hebrew literal in `main.dart`, release signed with the debug key), so no story can be built on the spine's architecture.

**Approach:** Replace the scaffold with the spine's layered structure, Android identity and signing, and the shared kernel that every later story reuses: `core/{result,money,text,i18n,policy,ports,db,ui}` plus `shell/`. The app launches RTL in Heebo and shows the empty group list. This covers the "Project foundation" and "shared kernel" ACs of Story 1.1 (epics.md lines 257–287). The FR1–FR5 flows are deferred to part 2 (see `deferred-work.md`).

**Decisions:**
- Release keystore: Claude creates it now (option A). It goes outside the repo at `%USERPROFILE%\.groupay\groupay-release.jks`, with generated passwords stored in the gitignored `android/key.properties`. The user backs up both files to their Google Drive.
- Scope split: this spec covers only the foundation. Story 1.1 stays in progress until part 2 ships.

## Boundaries & Constraints

**Always:**
- Pinned stack: drift 2.35.3, drift_flutter 0.3.1, drift_dev 2.35.2, build_runner 2.16.2, flutter_riverpod 3.4.3, riverpod_generator 4.0.9, riverpod_annotation 4.0.7, go_router 18.1.2, uuid 4.6.0, flutter_localizations, characters. Heebo is bundled in `assets/fonts/`. `flutter analyze` reports no warnings, and `*.g.dart` files are committed.
- Android: `namespace` and `applicationId` are `com.mordehay.groupay`. `minSdk 35`. Debug builds use `applicationIdSuffix ".dev"`. Release signs only from `key.properties`; if that file is missing, the release build fails loudly and never falls back to the debug key. `allowBackup="false"`. `dataExtractionRules` and `fullBackupContent` exclude every domain.
- CLAUDE.md layer and import rules apply. `domain/` and `core/` (except `db`, `ui`) are pure Dart. Fixed strings come only from `MessageKey`, copied verbatim from `ears-requirements.md` / `ui-messages.md`. No feature `ui/` literals for color, font size or radius.
- DB: `beforeOpen` sets `PRAGMA foreign_keys = ON` and `synchronous = FULL`. `schemaVersion 1` with `groups` and `members`, exactly as epics.md lines 278–279 define them, plus `UNIQUE(groupId, id)` on `members`. Tables live only in `core/db/tables/`. Committed `make-migrations` snapshot and generated test.

**Never:**
- No groups repositories, notifiers, entities or FR1–FR5 screens; no `expenses`, `app_settings`, archive or Summary.
- No `google_fonts`, network calls, `double` money, SQL `lower()`/`NOCASE`, `shared_preferences`.
- Never commit the keystore, `key.properties` or any password.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| formatShekel | 0; 12; 12.5 (125 tenths); 1,234,567.8 | "₪0"; "₪12"; "₪12.5"; "₪1,234,567.8", LTR-isolated | N/A |
| Grapheme length | "👍🏽", "שָׁלוֹם", 25-char paste into a 20 limit | 1; 4 (each letter with its niqqud counts once); first 20 kept | N/A |
| nameKey | " Dana ", "dana", "DANA" | equal keys; display name trimmed | N/A |
| Collation | Hebrew, Latin (mixed case), digits, geresh, emoji; final letters; a prefix | order per FR15: Hebrew → Latin A–Z case-insensitive → digits → geresh → Unicode; ך≡כ; a prefix sorts first; Unicode breaks ties | N/A |
| isolateName | "Dana" after "מ" | `מ-⁨Dana⁩` (FSI/PDI, hyphen only before a name that does not start with a Hebrew letter) | N/A |
| mayAddMember | 9 / 10 Members | Allow / Deny(`membersLimit`) | Failure(MessageKey) |
| mayRemoveMember | Payer usage false / true | Allow / Deny(payer message key) | Failure(MessageKey) |
| nextMemberSeq | [] / [1, 2, 5] | 1 / 6 | N/A |
| Release w/o key | `key.properties` missing | `flutter build apk --release` fails with a clear message | Gradle error |

</frozen-after-approval>

## Code Map

- `lib/main.dart`, `test/widget_test.dart` -- scaffold. Replace `main.dart` with a one-line delegate to `shell/`'s `main()` (keeps `flutter run` working), and delete `widget_test.dart`.
- `android/app/build.gradle.kts` -- the `com.example.groupay` namespace and id, `flutter.minSdkVersion`, and release `signingConfig = debug`. Rewrite all of these.
- `android/app/src/main/kotlin/com/example/groupay/MainActivity.kt` -- move to `com/mordehay/groupay/` and change the package.
- `android/app/src/main/AndroidManifest.xml` -- add the backup attributes and label "GrouPay". Add `res/xml/data_extraction_rules.xml` and `res/xml/backup_rules.xml`.
- `android/.gitignore` already ignores `key.properties`, `*.jks` and `*.keystore`, so it needs no change.
- `pubspec.yaml` -- keep `sdk: ^3.13.5`. Drop `cupertino_icons`.
- The pub cache already has every pinned package except go_router 18.1.2, which `pub get` will fetch.
- Installed Flutter 3.47.7 / Dart 3.13.5 match the spine.
- Heebo static TTFs and `OFL.txt` come from the `google/fonts` GitHub repo (`ofl/heebo`) and are fetched once. If only the variable TTF exists, bundle it plus the weights DESIGN.md uses.
- `keytool` -- from the JDK bundled with Android Studio (`jbr\bin\keytool.exe`) or on PATH.
- DESIGN.md frontmatter -- the token source (colors, type scale, radii, spacing, 6 member colors, 8 category colors).

## Tasks & Acceptance

**Execution:**
- [ ] `pubspec.yaml`, `build.yaml`, `analysis_options.yaml`, `assets/fonts/` -- pin the stack, register Heebo, register `AppDatabase` in `build.yaml` for drift's `make-migrations`, enable `riverpod_generator`.
- [ ] `%USERPROFILE%\.groupay\groupay-release.jks`, `android/key.properties` -- create an RSA 2048 key valid for 10000 days with alias `groupay` and random passwords via `keytool`. Write `storeFile` (absolute path), `storePassword`, `keyAlias` and `keyPassword`.
- [ ] `android/app/build.gradle.kts`, `MainActivity.kt`, `AndroidManifest.xml`, `res/xml/*` -- apply the AR4 config. The release `signingConfig` reads `key.properties` and throws a `GradleException` when the file is missing and a release task runs.
- [ ] `lib/core/result/` -- `Result<T>` = `Ok(T)` | `Failure(MessageKey)`.
- [ ] `lib/core/money/` -- `Tenths` extension type, keypad parsing and bounds (>0, ≤ ₪1,000,000, ≤1 decimal), `formatShekel()`.
- [ ] `lib/core/text/` -- `normalizeName`, `nameKey`, `graphemeLength`, a `GraphemeLimitFormatter` (`TextInputFormatter`; it lives under `core/text` but may import `flutter/services`), `compareNames` (FR15).
- [ ] `lib/core/i18n/` -- `MessageKey` enum with Hebrew text for this story's and Story 1.1's keys (including `nameRequired`, `groupNameTaken`, `memberNameTaken`, `membersLimit`, `emptyGroupList`, `newGroup`), and `isolateName()`.
- [ ] `lib/core/policy/` -- `Verdict` (Allow/Deny(MessageKey)), `mayAddMember`, `mayRemoveMember`, `nextMemberSeq`.
- [ ] `lib/core/ports/payer_usage_port.dart`, `lib/core/time/clock.dart` -- the port interface (`Future<bool> isPayer(groupId, memberId)`) and the `Clock` interface returning UTC epoch ms.
- [ ] `lib/core/db/` -- `AppDatabase`, `tables/{groups,members}.dart`, pragmas, a connection via drift_flutter, a `NativeDatabase.memory()` test hook, `drift_schemas/` and the generated migration test.
- [ ] `lib/core/ui/theme/`, `lib/core/ui/widgets/app_scaffold.dart`, `motion.dart` -- tokens, the light `ThemeData` with Heebo, `AppScaffold`, and the animation helper that honors `disableAnimations`.
- [ ] `lib/features/{groups,expenses}/{ui,app,domain,data}/.gitkeep`, `lib/features/groups/ui/group_list_screen.dart` -- empty layer folders plus a static empty-state list screen ("כאן תופיע רשימת הקבוצות" and the "+ קבוצה חדשה" button; tapping it does nothing yet).
- [ ] `lib/shell/` -- `main()`, the `ProviderScope` with `AppDatabase`, `Clock` and a `PayerUsagePort` stand-in that returns false, a `go_router` `/` route using `NoTransitionPage`, locale `he` with RTL and the delegates, and the text scale clamped to 1.5.
- [ ] `test/core/**`, `test/shell/app_test.dart` -- unit tests for every matrix row and every public core function; a DB test (pragmas on, constraints rejecting a duplicate `nameKey` and `memberSeq`); a widget smoke test (RTL, empty state shown, text scale clamped).

**Acceptance Criteria:**
- Given the finished part, when `flutter analyze` and `flutter test` run, then both pass with zero issues.
- Given `flutter run -d emulator-5554`, then `com.mordehay.groupay.dev` installs and shows the RTL empty group list in Heebo.
- Given `flutter build apk --release`, then the APK is signed with the release key (`apksigner verify --print-certs` shows the `groupay` certificate, not the Android Debug one).
- Given `git status`, then no `.jks` file or `key.properties` is tracked.

## Implementation Notes

## Spec Change Log

## Review Triage Log

## Verification

**Commands:**
- `flutter pub get` -- resolves to the pinned versions
- `dart run build_runner build --delete-conflicting-outputs` -- succeeds
- `dart run drift_dev make-migrations` -- writes the v1 snapshot and test
- `flutter analyze` -- "No issues found!"
- `flutter test` -- all pass
- `flutter build apk --release` followed by `apksigner verify --print-certs` -- shows the groupay certificate
