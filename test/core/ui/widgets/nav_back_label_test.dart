import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/ui/theme/tokens.dart';
import 'package:groupay/core/ui/widgets/nav_back_label.dart';

void main() {
  final style = AppTextStyles.headerSecondary.copyWith(
    color: AppColors.onHeader,
  );

  Future<void> pump(WidgetTester tester, String label, {double? width}) {
    return tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SizedBox(
            width: width,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: NavBackLabel(label: label, style: style),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the chevron_right icon takes the style size and color', (
    tester,
  ) async {
    await pump(tester, 'חזרה');
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, Icons.chevron_right);
    expect(icon.size, style.fontSize);
    expect(icon.color, style.color);
    expect(icon.applyTextScaling, isTrue);
    // Not mirrored under RTL: it points right (›).
    expect(
      Directionality.of(tester.element(find.byType(Icon))),
      TextDirection.ltr,
    );
    expect(
      find.descendant(of: find.byType(Icon), matching: find.byType(Transform)),
      findsNothing,
    );
    expect(find.text('חזרה'), findsOneWidget);
    expect(tester.widget<Text>(find.text('חזרה')).style, style);
  });

  testWidgets('the icon sits on the start (right) side in RTL', (tester) async {
    await pump(tester, 'הקבוצות שלי');
    final icon = tester.getRect(find.byType(Icon));
    final text = tester.getRect(find.text('הקבוצות שלי'));
    expect(icon.left, greaterThanOrEqualTo(text.right));
  });

  testWidgets('a long label wraps instead of overflowing', (tester) async {
    const long = 'הקבוצות שלי הקבוצות שלי הקבוצות שלי';
    await pump(tester, long, width: 120);
    expect(tester.takeException(), isNull);
    final text = tester.getSize(find.text(long));
    expect(text.width, lessThanOrEqualTo(120));
    expect(text.height, greaterThan(style.fontSize! * 2));
  });

  testWidgets('the icon grows with the text scale', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: NavBackLabel(label: 'חזרה', style: style),
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byType(Icon));
    expect(size.width, style.fontSize! * 1.5);
  });
}
