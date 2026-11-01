---
reviewed: ../ARCHITECTURE-SPINE.md (updated 2026-11-01, status draft)
inputs: ../.memlog.md, ../../../prds/prd-groupay-2026-10-26/prd.md, ux EXPERIENCE.md / DESIGN.md (spot checks), pubspec.yaml, pubspec.lock, android/app/build.gradle.kts, lib/main.dart, test/widget_test.dart
method: good-spine rubric; versions re-checked against pub.dev API on 2026-11-01
date: 2026-11-01
---

# Spine Review (Rubric): GrouPay v1

## Verdict

**Close, but needs a revision before epics.** The paradigm, layering, table ownership, transaction rule, money type, text/collation centralization and Hebrew string rules are strong, and the stack is verified-current. Before the epics go to separate dev agents, fix two rules that the PRD and UX contradict or leave unsettled (Auto Backup vs NFR-10, and member order vs "never time"). Also close four smaller gaps that would let stories diverge: the NFR-14 Expense edit/delete policy, where `saveSeq` comes from, how the Heebo font is loaded offline, and the save-once mechanism. No finding is a blocker for the paradigm itself.

| Severity | Count |
| --- | --- |
| High | 2 |
| Medium | 6 |
| Low | 8 |

## Findings

### High

**H1. Android Auto Backup is filed as "Deferred / open question", but the PRD already decides it.**
NFR-10 says "all data is stored only on the device", and PRD section 7 says "It has no backup or restore in v1". Android Auto Backup is on by default and uploads `groupay.sqlite` to the user's Google Drive. That contradicts NFR-10 and is invisible to the user. It also cannot really "wait": the first story that touches `AndroidManifest.xml` decides it by default, and a restored backup can bring back a DB whose schema does not match after reinstall. An open question also does not belong in a Deferred table. The spine has no Open Questions section.
*Fix:* add the rule to AD-19 (or a new AD): `android:allowBackup="false"` plus `dataExtractionRules`/`fullBackupContent` that exclude everything. Bind it to NFR-10. Remove the Deferred row. If the founder really wants backup, it is a PRD change (section 7), not an architecture deferral.

**H2. AD-9 "never time" contradicts the member ordering that the PRD and UX require, and AD-9 gives no source for it.**
FR-10 says the default Payer, when a Group has no Expenses, is "the earliest-added Member still in the Group". EXPERIENCE.md says Payer avatars "keep a fixed order, the order the Members were added". AD-9 says the default Payer "use[s] `saveSeq` only, never time", but `saveSeq` exists only on Expenses. One story will order Members by `createdAt`, which is clock-based: a wrong clock or a time-zone change, as AD-9 warns, can reorder them. Another story will use rowid or insertion order. These give different defaults.
*Fix:* add a per-Group `memberSeq` (or `addedSeq`) on `members`, assigned in the add-Member transaction like `saveSeq`. State in AD-9 that both "earliest-added Member" and the avatar order use it. Add a `core/policy` function for it, since the default Payer is an NFR-14 rule.

### Medium

**M1. The NFR-14 "who may edit or delete an Expense" rule is missing from AD-7.**
NFR-14 names four rules: edit/delete permission, Group mutability, default Payer, and save-order source. AD-7 lists mutability, default Payer and save order, plus FR-4 and FR-8, but no `mayEditExpense` / `mayDeleteExpense`. The binds list claims NFR-14, yet the multi-user "payer-only editing" rule from the addendum would then have to be rewritten into the expenses repository instead of replaced in one place.
*Fix:* add `mayEditExpense(facts)` and `mayDeleteExpense(facts)` to AD-7. In v1 they return allowed when the Group is mutable. Require the FR-13 and FR-14 write paths to call them.

**M2. AD-7's "every write to a Group ... checks `isGroupMutable`" blocks FR-6 restore as written.**
Restoring an Archived group is a write to an immutable Group. Archiving and unsetting the Active group (AD-17) also touch Group and settings rows. One agent will apply the rule literally and break restore. Another will special-case it ad hoc.
*Fix:* state the exceptions explicitly: archive/restore and Active-group changes use their own policy functions (`mayArchive`, `mayRestore`, FR-8 `maySetActive`). `isGroupMutable` guards name, Member and Expense writes only.

**M3. The source of `saveSeq` is not pinned, and the obvious implementation breaks AD-3.**
AD-9 says `saveSeq` is "monotonic within its Group" and assigned "through the `core/policy` save-order function". It does not say where the counter lives. One agent stores a `nextSeq` column on `groups`, which `expenses` would then write, breaking AD-3 (`groups` owns that table). Another computes `MAX(saveSeq)+1` over the Group's Expenses. After the newest Expense is hard-deleted (AD-10), that reuses a number, so the sequence is not strictly monotonic over history. The rule needs to say which behavior is intended.
*Fix:* pin it: "`saveSeq = MAX(saveSeq)+1` over the Group's current Expenses, read inside the create transaction; reuse after deleting the top Expense is acceptable in v1." Or: "a counter in an `expenses`-owned table." Add a unique index on `(groupId, saveSeq)`. The pure policy function takes the current max as a fact.

**M4. Font loading is not decided, and the likely default breaks NFR-8.**
DESIGN.md uses `fontFamily: Heebo` throughout. Heebo is not a system font on Android. The usual shortcut, the `google_fonts` package, downloads the font at runtime: a network call that breaks NFR-8 ("makes no network calls"), with a fallback font when offline. The NFR-6 golden test also needs the real font loaded in tests, or every glyph renders as boxes.
*Fix:* add a rule (AD-14 or Conventions): bundle Heebo as a `pubspec.yaml` font asset. No runtime font fetching (`google_fonts` is banned, or allowed only with `allowRuntimeFetching = false` and the font bundled). Golden tests load the bundled font.

**M5. Save-once (FR-10 and FR-13; also create Group/Member) has no shared mechanism.**
FR-10 and EXPERIENCE.md require that "a second tap on Save before the screen closes creates nothing". AD-5 and AD-15 do not say where that is enforced. Expect one story to disable the button in widget `setState`, one to guard in the notifier, and one to rely on navigation timing. Create-group (FR-1, followed by the FR-7 sheet) has the same double-tap risk.
*Fix:* one line in AD-5: "Write notifiers expose an in-flight state; a write method called while one is in flight is a no-op, and the primary action is disabled while in flight."

**M6. The spine does not say how it treats the existing code, and the memlog misdescribes that code.**
The memlog says the scaffold is the "default counter app". In fact `lib/main.dart` (commit "exercise 2") holds `GroupayApp` / `HomeScreen` with a hard-coded Hebrew literal `'קבוצה חדשה'`, no `ProviderScope`, no router and no RTL locale. `test/widget_test.dart` asserts that literal. Both violate AD-14, AD-5 and AD-16. `build.gradle.kts` has `com.example.groupay`, `minSdk = flutter.minSdkVersion` and release signed with the debug key, all of which AD-19 changes. These are legitimate changes, but the spine never says "replace, don't ratify". A dev agent may keep `HomeScreen` and the test, or treat the Gradle TODOs as already settled.
*Fix:* add a short "Existing code" note: `main.dart` and `widget_test.dart` are replaced by the Structural Seed. AD-19's Gradle values (applicationId, `.dev` suffix, `minSdk 35`, release `signingConfig`) are a required change in the first story. Pubspec SDK `^3.13.5` and Java/Kotlin 17 are kept. Correct the memlog line.

### Low

**L1. Stack: go_router is one patch behind.** pub.dev shows go_router 18.1.2 (2026-10-29); the spine pins 18.1.1. Every other version matched on 2026-11-01: drift 2.35.3, drift_dev 2.35.2 (accepts drift <2.36), drift_flutter 0.3.1, build_runner 2.17.1, flutter_riverpod 3.4.3, riverpod_generator 4.0.9 / riverpod_annotation 4.0.7 (which depends on riverpod 3.4.3, so the memlog's "pairing to be confirmed" is resolved: compatible), and uuid 4.6.0. The analyzer ranges overlap at 14.3 to 15. *Fix:* bump to 18.1.2, or state "pinned at verification date", and drop the open pairing note from the memlog.

**L2. The i18n mechanism is unnamed.** AD-14 says "`core/i18n` message-key table" but not whether that is Flutter gen-l10n (ARB plus `flutter_localizations` / `generate: true`) or a hand-written Dart map. Two stories could start both. *Fix:* name one mechanism.

**L3. Some homes are missing from the Structural Seed.** It has no folder for `Result`/`Failure` (AD-15), the UUID v7 generator, or an injectable clock (AD-8; the memlog had `core/ids`, the seed dropped it). The `Tenths` ↔ int drift `TypeConverter` (AD-12) also needs a home. Without these, each repository calls `Uuid().v7()` and `DateTime.now()` itself, and tests cannot control them. *Fix:* add `core/result/`, `core/ids/` (id plus clock providers), and a "`Tenths` column via one shared TypeConverter" convention.

**L4. Several rules have no enforcement mechanism.** AD-2, AD-4 and AD-14 ("only `data/` imports drift", "no Hebrew literals in widgets", "never another feature's `data/` or `ui/`") are checked only by review. *Fix:* add one convention: a test that scans `lib/` imports and string literals and fails on violations, or an analyzer plugin. This is cheap, and it keeps parallel agents honest.

**L5. The operational envelope has small gaps.** Deployment and environments (debug `.dev` vs release) are good. Missing: (a) a versionCode/versionName bump rule for each release APK, plus a pre-trip "install release over the previous release and confirm the data survives" check, which is the real NFR-9 risk on update; (b) how the APK reaches the phone (adb or file transfer). Logging, telemetry and CI are correctly deferred. *Fix:* add one line to AD-19.

**L6. Recorded-time display is unowned.** AD-8 stores UTC milliseconds, and the list and edit screens show "date time". Without a single `formatRecordedTime()` (local time zone, fixed format), the list and the edit meta line can differ. *Fix:* add it to `core/i18n` or `core/text` next to `formatShekel()`.

**L7. NFR-1..4 are not bound and not explicitly handed off.** The tap budget, thumb zone, touch targets and contrast are UX-owned, but the spine binds NFR-5..17 and its Deferred row covers only "visual design tokens". *Fix:* extend that Deferred row to "NFR-1..4 and visual tokens: owned by DESIGN.md/EXPERIENCE.md".

**L8. Restated spec detail (bloat and drift risk).** AD-13 restates the whole FR-15 collation, and AD-14 restates the hyphen-after-prefix rule. If the PRD or UX changes, the spine silently diverges. *Fix:* keep the ownership rule ("only `core/text` compares/orders names; collation = FR-15") and cite the spec instead of copying it. Elsewhere the spine is appropriately terse, and the Prevents lines are expected, not bloat.

## Rubric Checklist

| Criterion | Result | Notes |
| --- | --- | --- |
| Fixes the real divergence points, misses none | Partial | Strong core set (AD-2..AD-18). Missed: member order (H2), saveSeq source (M3), font loading (M4), save-once (M5), i18n mechanism (L2), id/clock/Result homes (L3), time format (L6). |
| Every Rule is enforceable and prevents its divergence | Mostly | AD-7's wording is too broad (M2) and too narrow (M1). AD-9 conflicts with the member-order requirement (H2). Import/literal rules have no check (L4). |
| Nothing Deferred can let units diverge | Fail (1 item) | The Auto Backup row is a live decision with an NFR-10 conflict (H1). The other rows are safe. |
| Named tech verified-current | Pass (minor) | All pinned versions exist and are mutually compatible. go_router has a newer patch (L1). |
| Ratifies rather than contradicts existing code | Partial | The intended changes to `main.dart`, the test and Gradle are not called out (M6). Pubspec SDK and JVM 17 are consistent. |
| Covers FR-1..16 and NFRs | Mostly | All FRs are mapped. NFR-14 is incomplete (M1). NFR-8 is at risk from fonts (M4). NFR-10 is at risk from backup (H1). NFR-1..4 have no hand-off (L7). |
| Every owned dimension decided, deferred, or open | Partial | No Open Questions section exists, and its one open item sits in Deferred. The operational envelope is mostly covered (L5). |
| Terse, no rationale bloat | Pass (minor) | AD-13 and AD-14 copy spec text (L8). |

## Process Notes

- The memlog marks AD-5 (generator-only), AD-11, AD-13, AD-17 and AD-18 as "[proposed] ... user to confirm in review". The spine presents them as settled rules. Confirm them with the founder before changing `status: draft`.
- The memlog's "default counter app" description of `bmad-rebuild` is out of date (see M6).
