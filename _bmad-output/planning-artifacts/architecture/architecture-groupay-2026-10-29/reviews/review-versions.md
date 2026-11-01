# Review: Stack versions and technical claims (reality check)

- **Target:** `../ARCHITECTURE-SPINE.md` (status: draft, updated 2026-11-01), with `../.memlog.md`
- **Reviewed:** 2026-11-01
- **Method:** pub.dev JSON API (`https://pub.dev/api/packages/<name>`) for every pinned package; a real `flutter pub get --dry-run` of the exact Stack table in a scratch project; the Flutter releases feed; drift 2.35.3 and uuid 4.6.0 sources from the local pub cache; official drift and go_router docs; and read-only inspection of the local Flutter install and the `android/` scaffold. The spine was not edited.

## Verdict

**FAIL (one blocker).** The Stack table as written does not resolve. `build_runner 2.17.1` and `riverpod_generator 4.0.9` cannot be installed together. The memlog itself left this pairing "to be confirmed by pub get". This review ran that pub get, and it fails. Every other version and every AD technical claim checked out, with minor caveats listed below.

## Findings

| # | Severity | Finding | Fix |
| --- | --- | --- | --- |
| V-1 | **High (blocker)** | `build_runner 2.17.1` requires `build >=5.0.0 <5.1.0`. `riverpod_generator 4.0.9` (latest, 2026-09-03) requires `build >=3.0.0 <5.0.0`. pub rejects the combination: *"riverpod_generator >=3.0.0 is incompatible with build_runner >=2.17.1 ... version solving failed."* `build_runner 2.17.0` is **retracted** on pub.dev, so the newest usable version is **2.16.2** (`build ^4.0.9`). | Change the Stack row to `build_runner 2.16.2`, and note "capped until riverpod_generator allows build 5". A dry-run with 2.16.2 resolves cleanly: build 4.0.11, analyzer 14.7.0, all other pins unchanged. |
| V-2 | Low | `go_router` 18.1.2 was published 2026-10-29. The spine pins 18.1.1. 18.1.2 is a patch fix (web text-field focus in shell routes), with no API change. | Optional: bump to 18.1.2, or keep 18.1.1. Both resolve. |
| V-3 | Low | Flutter stable is now **3.47.9 / Dart 3.13.7** (2026-10-29). The local install and the spine are on 3.47.7 / 3.13.5. Same minor version, so all package SDK floors are still met. | Optional: `flutter upgrade` before scaffolding and update the Stack row. Otherwise record 3.47.7 as a deliberate pin. |
| V-4 | Low | AD-16: go_router docs confirm that a sub-route stacks on its parent (it behaves like `push`), so `go('/group/:id')` leaves `/` beneath it. Back returns to the group list, and FR-9 holds. But "`/archive` → `/archive/group/:id`" is ambiguous. If `/archive` is a **top-level** route, back from Archive does not return to `/`. | State that `archive` is a child route of `/` (`/archive` = `/` + `archive`), like `group/:id`. |
| V-5 | Low | AD-18 says "committed drift schema dump + migration test". Current drift docs use `dart run drift_dev make-migrations`. It requires listing the database under `drift_dev: options: databases:` in `build.yaml`, writes schema JSON to `drift_schemas/` and tests to `test/drift/`, and generates `*.steps.dart`. The older `drift_dev schema dump/steps/generate` commands are the legacy path. | Name `make-migrations`, its `build.yaml` entry, and the initial run at schemaVersion 1 in AD-18 or the Conventions table, so the first story sets it up. |
| V-6 | Low | Testing convention: the Summary golden test with Hebrew/Latin/mixed names (NFR-6). `flutter_test` renders text with the Ahem test font by default, so Hebrew glyphs and bidi order would not be visible in the golden. | Load a real Hebrew-capable font in the golden test setup (`FontLoader`), or use a golden helper that loads app fonts. |

## Version-by-version check (pub.dev, 2026-11-01)

| Package | Spine | Latest on pub.dev | Published | Dart SDK constraint | Compatible with Dart 3.13.5 | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Flutter / Dart | 3.47.7 / 3.13.5 | 3.47.9 / 3.13.7 | 2026-10-29 | — | — | Local `flutter --version` confirms 3.47.7 / 3.13.5 (V-3) |
| drift | 2.35.3 | 2.35.3 | 2026-10-23 | `>=3.10.0 <4.0.0` | Yes | depends on `sqlite3 ^3.4.0` (native assets via hooks) |
| drift_dev | 2.35.2 | 2.35.2 | 2026-10-23 | `>=3.10.0 <4.0.0` | Yes | `drift >=2.30.0 <2.36.0` (accepts 2.35.3); `build >=3.0.0 <6.0.0`; `analyzer >=13 <15`. drift and drift_dev being on different patch numbers is normal. |
| drift_flutter | 0.3.1 | 0.3.1 | 2026-07-11 | `>=3.10.0 <4.0.0` | Yes | `drift ^2.30.0`; `sqlite3_flutter_libs ^0.6.0+eol` (now a stub; sqlite ships via `sqlite3` 3.x hooks) |
| build_runner | 2.17.1 | 2.17.1 | 2026-10-14 | `^3.11.0` | Yes | **Conflicts with riverpod_generator (V-1)**. 2.17.0 retracted. Use 2.16.2 (`^3.11.0`, `build ^4.0.9`). |
| flutter_riverpod | 3.4.3 | 3.4.3 | 2026-09-03 | `^3.12.0` | Yes | pins `riverpod 3.4.3` exactly |
| riverpod_annotation | 4.0.7 | 4.0.7 | 2026-09-03 | `^3.12.0` | Yes | pins `riverpod 3.4.3`, the same as flutter_riverpod, so the pair matches |
| riverpod_generator | 4.0.9 | 4.0.9 | 2026-09-03 | `^3.12.0` | Yes | pins `riverpod_annotation 4.0.7` exactly; `build <5.0.0` (V-1); `analyzer >=13 <15` |
| go_router | 18.1.1 | 18.1.2 | 2026-10-20 (pin) | `^3.12.0`, Flutter `>=3.44.0` | Yes | 18.0.0 moved to `material_ui`/`cupertino_ui` and raised the floor to Flutter 3.44 / Dart 3.12 (V-2) |
| uuid | 4.6.0 | 4.6.0 | 2026-07-15 | `>=3.0.0 <4.0.0` | Yes | `String v7({V7Options? config})` present in `lib/uuid.dart` (pub cache). riverpod 3.4.3 depends on `uuid ^4.5.1`, so no conflict. |
| analyzer (transitive) | — | 14.7.0 | 2026-10-29 | `^3.13.0` | Yes | Requires Dart >=3.13.0. The project's Dart floor `^3.13.5` satisfies it. |

**Riverpod pairing:** `riverpod_generator 4.x` with `flutter_riverpod 3.x` is the intended pairing. The generator major version is one ahead of the runtime. `riverpod_annotation 4.0.7` and `flutter_riverpod 3.4.3` both pin `riverpod 3.4.3`, so they match exactly. Confirmed by the dry-run resolution.

**Resolution evidence.** Scratch pubspec with `environment: sdk: ^3.13.5` and exactly the Stack pins:
- With `build_runner: 2.17.1`, resolution **fails** (message quoted in V-1).
- With `build_runner: 2.17.0`, resolution fails: "doesn't match any versions" (retracted).
- With `build_runner: 2.16.2`, resolution **succeeds**: drift 2.35.3, drift_dev 2.35.2, drift_flutter 0.3.1, flutter_riverpod 3.4.3, riverpod_generator 4.0.9, go_router 18.1.1, uuid 4.6.0, build 4.0.11, analyzer 14.7.0.

## AD technical claims

| Claim | Where | Verdict | Evidence |
| --- | --- | --- | --- |
| drift transactions are zone-scoped, so nested repository/port calls on the same `AppDatabase` join the transaction | AD-6, memlog | **Confirmed** | drift 2.35.3 `lib/src/runtime/api/connection_user.dart`: `transaction()` runs in `runZoned(..., zoneValues: {_zoneRootUserKey: user})`. `resolvedEngine` reads `Zone.current[_zoneRootUserKey]` and uses it only if `fromZone.attachedDatabase == attachedDatabase`. Joining therefore depends on **database identity**, which supports AD-6's single-instance rule. A second `AppDatabase` instance would silently not join. Docs caveats to add to the story checklist: every query inside the transaction must be `await`ed; no timers or unawaited work using the DB inside it; streams created outside the transaction emit only after commit. Tests must override the DB provider with one `NativeDatabase.memory()` instance shared by every repository and port. |
| `PRAGMA foreign_keys = ON` setup in drift | AD-18 | **Confirmed** | drift migrations docs: `MigrationStrategy(beforeOpen: (details) async { await customStatement('PRAGMA foreign_keys = ON'); })`. It runs on every open. Note: SQLite ignores this pragma inside a transaction. For a future table-rebuild migration, turn FKs off in `beforeOpen`/migration and run `PRAGMA foreign_key_check`, per drift's advanced migration guidance. |
| drift schema dump + migration test tooling | AD-18 | **Confirmed, terminology dated** | See V-5: `make-migrations` is the current workflow. Schema JSON goes to `drift_schemas/`, a migration test to `test/drift/`, and steps to `*.steps.dart`. |
| Dart extension types (`Tenths` over `int`) | AD-12 | **Confirmed** | Extension types exist since Dart 3.3 and the project is on 3.13.5. Practical note: drift columns are `int`. Wrapping/unwrapping happens either in the repository or through a `TypeConverter<Tenths, int>` (`.map(...)`). Choose one convention so all features do it the same way. |
| go_router nested routes produce the back stack on `go()` | AD-16 | **Confirmed** | go_router Configuration topic: a sub-route is displayed "equivalent to calling `push()`, where a new screen is displayed above the previous screen". A matched nested route builds parent and child pages, so back from `/group/:id` returns to `/`. See V-4 for the archive branch. |
| Android `minSdk 35`, `applicationIdSuffix` with Kotlin DSL | AD-19 | **Confirmed** | Scaffold `android/app/build.gradle.kts` uses the Kotlin DSL (AGP 9.1.0, Kotlin 2.4.0). Flutter 3.47.7 defaults (`FlutterExtension.kt`): minSdk 24, compileSdk 36, targetSdk 36. `minSdk = 35` is a valid override at or below compileSdk. Kotlin DSL form: `buildTypes { debug { applicationIdSuffix = ".dev" } }` (the scaffold already uses the `release { }` accessor). The scaffold still has `namespace`/`applicationId = "com.example.groupay"` and release signing with the debug key (template TODO). Both must change in the scaffold story for AD-19. |
| Unicode FSI/PDI rendering in Flutter `Text` | AD-14 | **Confirmed (no known defect)** | Flutter ships `Unicode.FSI` (U+2068) / `Unicode.PDI` (U+2069) in `package:flutter/foundation.dart`. The engine's paragraph layout uses ICU's UBA, which supports isolates (Unicode 6.3+). No open Flutter bug found for isolate rendering. Use the `Unicode` constants rather than literals. See V-6 for how to verify this in golden tests. |

## Memlog verification trail

- 2026-10-29 entries: drift 2.35.3, flutter_riverpod 3.4.3, uuid 4.6.0, go_router 18.1.1. All still accurate or the latest patch (go_router now 18.1.2).
- 2026-11-01 entry: drift_flutter 0.3.1, drift_dev 2.35.2, build_runner 2.17.1, riverpod_generator 4.0.9 / riverpod_annotation 4.0.7. Each version exists and is the latest, but the memlog deferred the compatibility check. That check fails (V-1). Every version number was looked up on pub.dev; none was taken from training data. The gap is in compatibility, not version freshness.

## Sources

- pub.dev package API: drift, drift_dev, drift_flutter, build_runner, build, flutter_riverpod, riverpod, riverpod_annotation, riverpod_generator, go_router, uuid, analyzer, source_gen, sqlite3, sqlite3_flutter_libs (`https://pub.dev/api/packages/<name>`)
- [Flutter releases feed](https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json)
- [drift: Transactions](https://drift.simonbinder.eu/dart_api/transactions/)
- [drift: Migrations](https://drift.simonbinder.eu/migrations/)
- [go_router changelog](https://pub.dev/packages/go_router/changelog)
- [go_router Configuration topic](https://pub.dev/documentation/go_router/latest/topics/Configuration-topic.html)
- [go_router Navigation topic](https://pub.dev/documentation/go_router/latest/topics/Navigation-topic.html)
- [Flutter `Unicode.FSI` constant](https://api.flutter.dev/flutter/foundation/Unicode/FSI-constant.html)
- Local: `flutter --version`, `C:/src/flutter/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt`, pub cache `drift-2.35.3/lib/src/runtime/api/connection_user.dart`, `uuid-4.6.0/lib/uuid.dart`, `android/app/build.gradle.kts`
