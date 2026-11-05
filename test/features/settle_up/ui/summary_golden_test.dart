import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';
import 'package:groupay/core/ids/new_id.dart';
import 'package:groupay/core/money/tenths.dart';
import 'package:groupay/core/result/result.dart';
import 'package:groupay/core/ui/widgets/bottom_fade.dart';
import 'package:groupay/features/expenses/data/drift_expense_repository.dart';
import 'package:groupay/features/expenses/data/drift_payer_usage.dart';
import 'package:groupay/features/expenses/domain/category.dart';
import 'package:groupay/features/groups/data/drift_group_repository.dart';
import 'package:groupay/features/groups/data/drift_member_repository.dart';
import 'package:groupay/features/groups/domain/group.dart';
import 'package:groupay/features/groups/domain/member.dart';
import 'package:groupay/features/settle_up/ui/summary_screen.dart';
import 'package:groupay/features/settle_up/ui/transfer_card.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_clock.dart';
import '../../../support/heebo.dart';

/// Story 1.4: Summary goldens (NFR-6, TX.5, EXPERIENCE.md OQ1) on the
/// Galaxy S25 frame (1080×2340 at dpr 3) with the bundled Heebo, at text
/// scale 1.0 and 1.5, with Hebrew, Latin and mixed names.
///
/// The PNGs were generated on Windows; glyph rasterizing differs a little
/// between platforms. Heebo has no "→" or emoji glyphs, so the goldens show
/// a box in their place (on the device the system fallback font draws them).
void main() {
  late AppDatabase db;
  late DriftGroupRepository groups;
  late DriftMemberRepository members;
  late DriftExpenseRepository expenses;

  setUpAll(loadHeebo);

  setUp(() {
    db = AppDatabase.memory();
    final clock = FakeClock(
      DateTime.utc(2026, 12, 14, 10).millisecondsSinceEpoch,
    );
    groups = DriftGroupRepository(db, clock);
    members = DriftMemberRepository(db, clock, DriftPayerUsage(db));
    expenses = DriftExpenseRepository(db, clock, members);
  });
  tearDown(() => db.close());

  /// A Group named [group] with [names] as Members; [paid] maps a Member to
  /// the tenths that Member paid, in one Expense each.
  Future<String> seed(
    List<String> names,
    Map<String, int> paid, {
    String group = 'Budapest',
    bool archived = false,
  }) async {
    final g =
        (await groups.createGroup(id: newId(), name: group) as Ok<Group>).value;
    final byName = <String, Member>{};
    for (final n in names) {
      byName[n] = (await members.addMember(
        id: newId(),
        groupId: g.id,
        name: n,
      ) as Ok<Member>).value;
    }
    for (final MapEntry(key: name, value: tenths) in paid.entries) {
      expect(
        await expenses.add(
          id: newId(),
          groupId: g.id,
          payerId: byName[name]!.id,
          amount: Tenths(tenths),
          category: Category.hotel,
        ),
        isA<Ok<Object?>>(),
      );
    }
    if (archived) expect(await groups.archive(id: g.id), isA<Ok<void>>());
    return g.id;
  }

  /// The scroll range of the Summary body.
  double maxScroll(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byType(SummaryScreen),
          matching: find.byType(Scrollable),
        ),
      )
      .position
      .maxScrollExtent;

  /// Pumps the Summary of the Group [seedGroup] creates at both text scales
  /// and compares it with `goldens/summary_<name>_<scale>.png`. [atDefault]
  /// runs extra checks at text scale 1.0.
  void golden(
    String name,
    Future<String> Function() seedGroup, {
    bool archived = false,
    void Function(WidgetTester tester)? atDefault,
  }) {
    for (final scale in const [1.0, 1.5]) {
      final label = scale == 1.0 ? '1_0' : '1_5';
      testWidgets('golden: $name at text scale $scale', (tester) async {
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        try {
          final g = await seedGroup();
          final base = archived ? '/archive/group/$g' : '/group/$g';
          await pumpGrouPay(tester, db, initialLocation: '$base/summary');
          expect(find.byType(SummaryScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (scale == 1.0) atDefault?.call(tester);
          await expectLater(
            find.byType(SummaryScreen),
            matchesGoldenFile('goldens/summary_${name}_$label.png'),
          );
        } finally {
          await unmountGrouPay(tester);
        }
      });
    }
  }

  // T3.6: Hebrew names only.
  golden(
    'hebrew',
    () => seed(['מוטי', 'דנה', 'יוסי', 'נועה'], {'מוטי': 4000, 'דנה': 2000}),
  );

  // Latin names only.
  golden('latin', () => seed(['Dana', 'Yossi', 'Noa'], {'Dana': 3000}));

  // TX.5: mixed names, one with a space.
  golden('mixed', () => seed(['Dan', 'דנה', 'Zoe Lee'], {'Dan': 3000}));

  // OQ1: 6 Members, 5 Transfers of ₪8,333.3 with 10-letter Hebrew names
  // fit with no scroll.
  golden(
    'long_hebrew',
    () => seed(
      [
        'אביגיל כהן',
        'דוד אברמוב',
        'יוסף מזרחי',
        'מיכל ברקוב',
        'נועה שפירא',
        'שירה לנדאו',
      ],
      {'אביגיל כהן': 499998},
    ),
    atDefault: (tester) {
      expect(find.byType(TransferCard), findsNWidgets(5));
      expect(maxScroll(tester), 0);
      expect(find.byType(BottomFade), findsNothing);
    },
  );

  // OQ1: with 10-letter Latin names the cards wrap and scroll, with the fade.
  golden(
    'long_latin',
    () => seed(
      [
        'Alexandros',
        'Bernadette',
        'Christophe',
        'Evangeline',
        'Jacqueline',
        'Maximilian',
      ],
      {'Alexandros': 499998},
    ),
    atDefault: (tester) {
      expect(find.byType(TransferCard), findsNWidgets(5));
      expect(maxScroll(tester), greaterThan(0));
      expect(find.byType(BottomFade), findsOneWidget);
    },
  );

  // FR-6: the archived Summary, with the badge and the note.
  golden(
    'archived',
    () => seed(['Dana', 'Yossi'], {'Dana': 3000}, archived: true),
    archived: true,
  );

  // T3.46: 10 Members, 9 Transfers; the cards scroll under the fixed title.
  golden(
    'ten_members',
    () => seed(
      [
        'אביגיל',
        'בתיה',
        'גילה',
        'דנה',
        'הדס',
        'ורד',
        'זיוה',
        'חנה',
        'טל',
        'יעל',
      ],
      {'אביגיל': 10000},
    ),
    atDefault: (tester) {
      expect(maxScroll(tester), greaterThan(0));
      expect(find.byType(BottomFade), findsOneWidget);
    },
  );
}
