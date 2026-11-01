# Adversarial Review: ARCHITECTURE-SPINE.md (GrouPay v1)

- **Reviewed:** `../ARCHITECTURE-SPINE.md` (updated 2026-11-01), with `../.memlog.md` and PRD `prd-groupay-2026-10-26/prd.md`
- **Reviewer stance:** adversary. For each hole there are two units, built separately by agents that obey every AD literally, and they still fail to fit together.
- **Date:** 2026-11-01

## Verdict

**NOT READY TO BUILD: 3 critical, 5 high, 5 medium, 2 low.** The paradigm is sound and most single-feature rules are tight. But the layer table, AD-2 ("`core/` imports no feature") and the Structural Seed contradict each other at three load-bearing points: `core/db`, `core/routing`, and the guard facts that `expenses/data` needs from `groups`. Because no reading satisfies every rule at once, each agent has to break a different rule, and the two halves will not fit. Patch the spine with the rules below before stories are written.

Severity key: **Critical** = no build can satisfy all ADs at once, so agents will diverge. **High** = two compliant builds are incompatible at runtime or in their data. **Medium** = a compliant build has a correctness or guard gap. **Low** = drift that will cost later.

---

## Critical

### C1. `core/db` must register feature-owned tables, so core imports features, and cross-feature FKs import `data/`

**Pair:** groups agent (owns `Groups`, `Members`, `AppSettings` tables, AD-3) and expenses agent (owns `Expenses`, needs `payerId → members.id`, AD-18) against the `core/db` author.

- The Seed says `core/db` holds "AppDatabase (registers every table)". In drift that means `@DriftDatabase(tables: [Groups, Members, Expenses, AppSettings])`, which must import the table classes. If the tables sit in `features/*/data` (the place AD-3 ownership suggests), then `core` imports features, which AD-2 forbids.
- drift generates the row data classes and companions into the database's `.g.dart`. Every `features/*/data` therefore imports `core/db` for them, while `core/db` imports `features/*/data` for the table definitions. That is a cycle.
- AD-18 requires `expenses.payerId REFERENCES members(id)`. A typed drift FK (`references(Members, #id)`) means `expenses/data` imports `groups/data`, which AD-2 forbids ("never its `data/`").
- By default drift names its row classes `Group`, `Member` and `Expense`. Those are the obvious names for the domain entities too, so mapper code that imports both gets ambiguous names.

**Divergence:** agent A puts all tables in `core/db/tables/` (ownership becomes convention only). Agent B keeps tables in `features/x/data` and builds `AppDatabase` somewhere else. Agent C writes the FK as a raw `customConstraint` string. Each choice breaks a different AD, and the codegen will not compile across them.

**Proposed rule (new AD-20, Schema location):** *All drift table definitions live in `core/db/tables/<feature>_tables.dart`. Ownership (AD-3) is about who writes: only the owning feature's `data/` may call insert, update or delete on a table. Cross-feature FKs are declared there with typed `references()`. Every table uses `@DataClassName('<Entity>Row')`, so the names `Group`, `Member` and `Expense` belong only to domain entities. A lint or test asserts that no file outside `features/<owner>/data` writes to a table.*

### C2. Guard facts from a lower feature cannot be read inside the write transaction

**Pair:** expenses agent (`DriftExpenseRepository.create`) and groups agent (`GroupRepository`, `MemberRepository`).

- AD-7 says every Expense write checks `isGroupMutable`. FR-10 adds that the Payer must be a current Member, with at least 2 Members. All of these facts are owned by `groups`.
- AD-6 says the repository gathers those facts inside the transaction. AD-3 says other features read owned data only through the owner's repository interface or a port.
- The layer table says `data/` may import **only own `domain/` and `core/`**. So `DriftExpenseRepository` (in `expenses/data`) may not import `groups/domain`'s `GroupRepository`. Ports cover only the upward direction (a lower feature needing a fact from a higher one). For this downward case there is no legal path from `expenses/data` to the facts.

**Divergence:** agent A gathers the facts in the `expenses/app` notifier before calling the repository. That is legal under the layer table, but the check runs outside the transaction, so AD-6 is broken (check-then-act). Agent B queries `groups`/`members` directly with drift inside `DriftExpenseRepository`, which breaks AD-3. Agent C adds a `GroupFactsPort` in `core/ports`, but AD-2 defines ports only for the upward direction. All three pass review against some reading of the spine.

**Proposed rule (amend the layer table and AD-6):** *`data/` may import lower features' `domain/` repository interfaces. A repository receives the lower repositories it needs through its constructor, and calls them inside its own `db.transaction`. Each guarded write has a named fact-gathering step listed in the story, e.g. `ExpenseWriteFacts {groupArchived, memberIds, memberCount}`.* (Another option: allow read-only cross-feature drift reads inside `data/`, and state that this is an exception to AD-3.)

### C3. `core/routing` must import feature screens and the Active group, and no feature can own the Group page

**Pair:** groups agent (Group page `/group/:id`, member settings, archive) and expenses / settle_up agents (expense list, *Add expense*, Summary entry on the same page).

- AD-16 and the Seed place the go_router config in `core/routing`. The route table has to name `GroupListScreen`, `ExpenseEditScreen`, `SummaryScreen` and so on, all in `features/*/ui`, so `core` imports features (AD-2 forbids this). The FR-9 launch redirect needs `app_settings.activeGroupId`, owned by `groups`, which is another upward import.
- The Group page (FR-10, FR-12, FR-16) shows Members, the expense list, the Trip total, *Add expense* and the Summary button. `groups/ui` cannot import `expenses` or `settle_up` (downward-only rule). `expenses/ui` can show the expense list but cannot reach `settle_up`. Only `settle_up/ui` or a layer above the features can compose that page, and no AD assigns it.

**Divergence:** the groups agent builds `/group/:id` with members and placeholders. The expenses agent builds its own `/group/:id` list screen. Both register the route, and the router author has to pick one or break AD-2.

**Proposed rule (new AD-21, Composition root):** *`lib/app/` (above all features) holds `router.dart`, the `ProviderScope` overrides, and the composite screens that span features: the Group page and the archived Group page. It may import every feature's `ui/` and `app/`. `core/routing` is removed. Each feature exports its screens through `features/<f>/ui/<f>_screens.dart`. The launch redirect reads `activeGroupIdProvider` from `groups/app`.*

---

## High

### H1. No composition root for repositories and ports, so a hidden provider cycle appears

**Pair:** groups agent (`memberRepositoryProvider`, which needs `PayerUsagePort`) and expenses agent (`PayerUsagePort` implementation, `expenseRepositoryProvider`, which needs group facts per C2).

- `app/` may not import its own `data/`, so `groups/app` cannot construct `DriftMemberRepository`. The spine never says where `DriftXRepository` objects are constructed or where the port provider is declared and overridden.
- With the obvious wiring the graph is: `memberRepository → payerUsagePort → (expenses impl built from) expenseRepository → groupRepository / memberRepository` (for the C2 facts). Riverpod throws a `CircularDependencyError` at runtime. Each agent's half is acyclic and compliant. Only the combination is cyclic.

**Proposed rule (add to AD-2 and AD-5):** *Port implementations are standalone classes that take only `AppDatabase`, never another repository. Repository interface providers are declared in `<f>/domain`-facing `app/` files as `throw UnimplementedError` stubs, or in `lib/app/providers.dart`, and are bound to the drift implementations in the composition root (C3). Every story that adds a dependency edge between providers updates a provider dependency diagram in the spine, and that diagram must stay acyclic.*

### H2. `@riverpod` defaults to autoDispose, so the "one AppDatabase" rule breaks

**Pair:** the `core/db` author (`@riverpod AppDatabase appDatabase(Ref ref)`, AD-5 literal) and any feature whose screens come and go.

- In riverpod_generator, `@riverpod` providers are autoDispose by default. When the last listener leaves, the database is disposed. If the author closes it in `onDispose`, the next read opens a second instance while background streams still hold the old one. AD-6 ("exactly one AppDatabase") is broken without anyone breaking AD-5.

**Proposed rule (amend AD-5):** *`AppDatabase`, every repository provider and every port provider are declared `@Riverpod(keepAlive: true)`. Only screen-scoped UI state providers may be autoDispose.*

### H3. Who owns the `saveSeq` source: MAX+1 on `expenses` or a counter on `groups`

**Pair:** expenses agent and groups agent, both reading AD-9 "increases monotonically within its Group".

- Expenses agent: `SELECT MAX(saveSeq) FROM expenses WHERE groupId=?`, then `nextSaveSeq(max)`. After the newest Expense is hard-deleted (AD-10), its number is **reused**. So the sequence is not monotonic over the Group's history, and a future sync log sees two different Expenses with the same `(groupId, saveSeq)`.
- Groups agent: reads "within its Group" as a Group property, and adds `groups.lastSaveSeq` so numbers are never reused. Then the expenses repository has to write the `groups` table, which breaks AD-3. Or groups exposes `allocateSaveSeq()` on its repository, a second entity owner for the sequence.
- Neither choice adds `UNIQUE(groupId, saveSeq)`.

**Proposed rule (amend AD-9):** *The fact passed to `nextSaveSeq` is `MAX(saveSeq)` over that Group's current Expenses, read by `DriftExpenseRepository` inside the create transaction. Reuse after deleting the newest Expense is accepted in v1, and the sync phase will replace the source (NFR-14). `expenses` has `UNIQUE(groupId, saveSeq)`. No other table stores sequence state.* (If no reuse is wanted, assign the counter column to `groups` explicitly and expose it through a `SaveSeqPort` or the C2 path.)

### H4. "Earliest-added Member" has no clock-free source

**Pair:** groups agent (Member entity and its order) and expenses agent (FR-10 default Payer through `core/policy`).

- FR-10 falls back to "the earliest-added Member still in the Group". AD-9 says the default Payer uses `saveSeq` only, never time. But Members have no sequence. The only ordering facts are `createdAt` (a clock) and the UUID v7 id (also clock-derived).
- The groups agent returns Members ordered by `createdAt`. The expenses agent, obeying AD-9, refuses time and falls back to FR-15 collation or the list as returned. After a clock change, the defaults differ.

**Proposed rule (amend AD-9):** *Members carry `addSeq`, a per-Group monotonic int assigned in the add transaction by `core/policy.nextMemberSeq`. `MemberRepository.watchMembers` returns Members ordered by `addSeq`. The default-Payer policy receives `(latestExpensePayerId?, memberIdsByAddSeq)`.*

### H5. Policy functions have no fact vocabulary, so entity shapes get duplicated

**Pair:** the `core/policy` author and the groups and expenses agents.

- `core/policy` cannot import features, so it cannot see `Member`, `Expense` or `Group`. Agent A writes `defaultPayer(List<PolicyMember>, PolicyExpense?)` with core-side mirror classes, which creates a second definition of each entity. Agent B writes `defaultPayer(List<String> ids, String? lastPayer)`. Feature agents write adapters for whichever version they saw first.
- `Verdict`, `Result` and `Failure` have no stated home, and the type of `messageKey` (`String` or an enum) is unstated. FR-7's message needs a `{name}` argument.

**Proposed rule (amend AD-7 and AD-15):** *`core/policy` signatures take only primitives, `Tenths`, and fact records defined next to each function (`MemberRemovalFacts {bool isPayer}`, `DefaultPayerFacts {...}`). They never take entity types. `Result<T>`, `Failure` and `Verdict` live in `core/result`. `messageKey` is the `MessageKey` enum from `core/i18n`, with typed arguments for parameterized messages. The spine lists every policy signature.*

---

## Medium

### M1. `isGroupMutable` applied literally blocks Restore, and the guard list has gaps

- AD-7 says "every write to a Group … checks `isGroupMutable`". Restore is a write to an archived Group, so a literal implementation refuses it. Archive itself is fine. An agent that adds a Restore exemption is not "obeying to the letter".
- Guards that are UI-only can be bypassed. "Add expense disabled with fewer than 2 Members" (FR-10) and "Summary disabled with fewer than 2 Members" (FR-16) have no repository-side or calculation-side check. A deep link to `/group/:id/add` or `/summary` gets past them.
- **Rule:** *AD-7 lists every guarded write with its policy function: create/rename/archive/restore Group; add/rename/remove Member; create/edit/delete Expense; set/unset Active group. Restore is exempt from `isGroupMutable` and checks `isArchived == true` instead. `mayRecordExpense(memberCount, archived)` is checked in the repository, and the routes redirect when it fails.*

### M2. The Payer is not tied to the Expense's Group

- `payerId → members.id` (AD-18) only proves the Member exists, not that the Member belongs to `expense.groupId`. An edit that sets the Payer to a Member of another Group passes every AD and corrupts both Groups' Transfer lists.
- **Rule:** *A composite FK `(groupId, payerId) → members(groupId, id)` with `UNIQUE(groupId, id)` on `members`, plus an in-transaction check (C2) that `payerId` is in the Group's current Members.*

### M3. settle_up reads two streams that are not one snapshot, and its input shape is not defined

**Pair:** settle_up agent (combines `membersProvider(groupId)` and `expensesProvider(groupId)`) and the groups and expenses agents (their public providers).

- The Members stream and the Expenses stream re-query on their own. Right after adding a Member and then an Expense, the combined value can briefly hold an Expense whose `payerId` is not in the Members list. The pure function then throws, or counts that Expense in the Trip total but in no Balance.
- AD-2 says "public `app/` providers", but none are named and their shapes are not given. The expenses agent may expose list items that already include the payer name and leave out `saveSeq`. settle_up needs `saveSeq` for the Leftover tie-break.
- The calculation is undefined for 0 or 1 Members (division by zero), and Summary's only protection is a disabled button (M1).
- **Rule:** *The domain `Expense` entity includes `saveSeq`, `payerId` and `amount: Tenths`. Each feature lists its public providers in `<f>/app/<f>_public.dart`. The settle_up input is `SettleInput {members, expenses}` built from one provider that recomputes from both streams and drops a snapshot whose payerIds are not all in the Members list. `computeTransfers` returns an empty result for fewer than 2 Members and asserts that every payer is a Member.*

### M4. Double-tap Save and where ids are generated

- FR-10: a second tap on *Save* creates nothing. AD-8 says ids are generated on device but not where. If the repository generates the UUID on each call, two quick taps make two Expenses, unless the notifier has an in-flight lock that another agent did not build.
- **Rule:** *The notifier for a form creates the entity id once, when the screen opens, and passes it to `create`. The repository insert is idempotent on that id (`insertOrIgnore` returns the existing record). Notifier write methods ignore calls while a write is pending.*

### M5. Category key stability and its owner

- AD-18 says "stable string key". drift's `textEnum` stores `enum.name`, so renaming an enum value silently changes the stored data. `intEnum` stores the index, so reordering breaks it. `core/i18n` cannot import `expenses/domain`'s `Category` to map its labels, so one agent puts the enum in `core` and another in `expenses/domain`.
- **Rule:** *`enum Category` lives in `expenses/domain`, and each value has an explicit `const String key` (`flight, hotel, car, fuel, restaurant, food_drink, attractions, other`) that is never renamed. Storage goes through a `TypeConverter` on `key`, never `textEnum` or `intEnum`. Labels use `MessageKey.category_<key>`, and the mapping lives in `expenses/ui`.*

---

## Low

### L1. Name uniqueness in SQL against `core/text`
An agent adds `UNIQUE(name COLLATE NOCASE)` as a backstop. SQLite's NOCASE folds ASCII only, and it disagrees with the `core/text` compare key on Hebrew final letters and Unicode case. That breaks AD-13 ("no other code compares names"), and the two checks give different answers. **Rule:** *Store a `nameKey` column computed by `core/text.compareKey`, with `UNIQUE(nameKey)` for Groups and `UNIQUE(groupId, nameKey)` for Members. No SQL collation on names.*

### L2. Clock source and when `modifiedAt` changes
Each repository calls `DateTime.now()` on its own, so tests can't be deterministic. It is also unstated whether adding a Member, or archiving, bumps the Group's `modifiedAt`. Sync will need that to be consistent. **Rule:** *A `clockProvider` in `core/time` (epoch-millis UTC). `modifiedAt` changes only on the record's own columns. Child changes do not touch the parent.*

---

## Summary of proposed spine changes

| # | Change | Closes |
| --- | --- | --- |
| AD-20 (new) | Tables defined in `core/db/tables`, ownership = write right, `*Row` data class names | C1 |
| AD-21 (new) | `lib/app/` composition root: router, overrides, composite Group page | C3, H1 |
| Layer table and AD-6 | `data/` may import lower features' `domain/` interfaces; facts gathered in the transaction | C2 |
| AD-2 and AD-5 | Port implementations depend only on `AppDatabase`; keepAlive for db, repositories and ports; provider graph kept acyclic | H1, H2 |
| AD-9 | MAX+1 source and UNIQUE; Member `addSeq` | H3, H4 |
| AD-7 and AD-15 | Fact records, policy signature list, `core/result`, `MessageKey` enum, full guarded-write list | H5, M1 |
| AD-18 | Composite payer FK, `nameKey` columns, Category `TypeConverter` | M2, M5, L1 |
| AD-11 | Public provider files, `SettleInput` snapshot, n<2 behavior | M3 |
| AD-8 | Id created by the form notifier, idempotent insert, `clockProvider` | M4, L2 |
