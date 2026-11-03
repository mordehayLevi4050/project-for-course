import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/ui/theme/app_theme.dart';
import 'package:groupay/core/ui/theme/tokens.dart';
import 'package:groupay/core/ui/widgets/app_scaffold.dart';
import 'package:groupay/core/ui/widgets/motion.dart';

void main() {
  group('appAnimationDuration', () {
    Future<Duration> durationWith(
      WidgetTester tester, {
      required bool disableAnimations,
    }) async {
      late Duration result;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Builder(
            builder: (context) {
              result = appAnimationDuration(context, AppAnimation.sheetSlide);
              return const SizedBox();
            },
          ),
        ),
      );
      return result;
    }

    testWidgets('animates normally', (tester) async {
      expect(
        await durationWith(tester, disableAnimations: false),
        AppAnimation.sheetSlide.duration,
      );
    });

    testWidgets('is zero when Remove animations is on', (tester) async {
      expect(
        await durationWith(tester, disableAnimations: true),
        Duration.zero,
      );
    });

    test('exactly the two allowed animations exist', () {
      expect(AppAnimation.values, hasLength(2));
    });
  });

  test('theme is light and uses the tokens and Heebo', () {
    final theme = buildAppTheme();
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.scaffoldBackgroundColor, AppColors.surfaceBase);
    expect(theme.textTheme.bodyMedium!.fontFamily, appFontFamily);
    expect(AppColors.members, hasLength(6));
  });

  testWidgets('AppScaffold shows header, body and bottom bar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppScaffold(
          header: Text('H'),
          body: Text('B'),
          bottomBar: Text('F'),
        ),
      ),
    );
    expect(find.text('H'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('F'), findsOneWidget);
    final headerStyle = DefaultTextStyle.of(tester.element(find.text('H')));
    expect(headerStyle.style.color, AppColors.onHeader);
  });
}
