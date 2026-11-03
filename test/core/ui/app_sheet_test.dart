import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/ui/theme/app_theme.dart';
import 'package:groupay/core/ui/theme/tokens.dart';
import 'package:groupay/core/ui/widgets/app_sheet.dart';
import 'package:groupay/core/ui/widgets/confirm_sheet.dart';
import 'package:groupay/core/ui/widgets/rename_sheet.dart';

/// Pumps a page with one button that runs [open] and records its result.
Future<List<Object?>> pumpOpener(
  WidgetTester tester,
  Future<Object?> Function(BuildContext context) open, {
  bool disableAnimations = false,
}) async {
  final results = <Object?>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async => results.add(await open(context)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  group('showAppSheet', () {
    Future<Object?> openPlain(BuildContext context) => showAppSheet<String>(
      context,
      builder: (context) => TextButton(
        onPressed: () => Navigator.of(context).pop('picked'),
        child: const Text('pick'),
      ),
    );

    testWidgets('resolves null when the scrim is tapped', (tester) async {
      final results = await pumpOpener(tester, openPlain);
      expect(find.text('pick'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('pick'), findsNothing);
      expect(results, [null]);
    });

    testWidgets('resolves null on system back', (tester) async {
      final results = await pumpOpener(tester, openPlain);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(results, [null]);
    });

    testWidgets('resolves the value the sheet pops with', (tester) async {
      final results = await pumpOpener(tester, openPlain);
      await tester.tap(find.text('pick'));
      await tester.pumpAndSettle();
      expect(results, ['picked']);
    });

    testWidgets('is a bottom sheet over the scrim, never a dialog', (
      tester,
    ) async {
      await pumpOpener(tester, openPlain);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      final barrier = tester.widget<ModalBarrier>(
        find.byType(ModalBarrier).last,
      );
      expect(barrier.color, AppColors.scrim);
      // The sheet sits at the bottom of the screen.
      final screen = tester.getSize(find.byType(Scaffold));
      expect(tester.getBottomLeft(find.byType(BottomSheet)).dy, screen.height);
    });

    testWidgets('opens instantly when Remove animations is on', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => openPlain(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump();
      expect(find.text('pick'), findsOneWidget);
      final route = ModalRoute.of(tester.element(find.text('pick')))!;
      expect(route.animation!.status, AnimationStatus.completed);
    });

    testWidgets('slides when animations are on', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openPlain(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final route = ModalRoute.of(tester.element(find.text('pick')))!;
      expect(route.animation!.status, AnimationStatus.forward);
      await tester.pumpAndSettle();
      expect(route.animation!.status, AnimationStatus.completed);
    });
  });

  group('showConfirmSheet', () {
    Future<Object?> openConfirm(BuildContext context) => showConfirmSheet(
      context,
      title: 'T',
      confirmLabel: MessageKey.removeMemberConfirm.text,
    );

    testWidgets('confirm → true', (tester) async {
      final results = await pumpOpener(tester, openConfirm);
      expect(find.text('T'), findsOneWidget);
      await tester.tap(find.text(MessageKey.removeMemberConfirm.text));
      await tester.pumpAndSettle();
      expect(results, [true]);
    });

    testWidgets('"ביטול" → null', (tester) async {
      final results = await pumpOpener(tester, openConfirm);
      await tester.tap(find.text(MessageKey.cancel.text));
      await tester.pumpAndSettle();
      expect(results, [null]);
    });

    testWidgets('the confirm is a danger button on the start side', (
      tester,
    ) async {
      await pumpOpener(tester, openConfirm);
      final confirm = find.widgetWithText(
        FilledButton,
        MessageKey.removeMemberConfirm.text,
      );
      final style = tester.widget<FilledButton>(confirm).style!;
      expect(style.backgroundColor!.resolve({}), AppColors.danger);
      // LTR test app: start is the left side.
      final cancel = find.text(MessageKey.cancel.text);
      expect(
        tester.getCenter(confirm).dx,
        lessThan(tester.getCenter(cancel).dx),
      );
    });
  });

  group('showRenameSheet', () {
    testWidgets('an error stays inside the open sheet; success closes it', (
      tester,
    ) async {
      final saved = <String>[];
      final results = await pumpOpener(
        tester,
        (context) => showRenameSheet(
          context,
          current: 'Dana',
          maxLength: 10,
          onSave: (name) async {
            saved.add(name);
            return name.trim().isEmpty ? MessageKey.nameRequired : null;
          },
        ),
      );
      final field = find.byType(TextField);
      expect(tester.widget<TextField>(field).controller!.text, 'Dana');

      await tester.enterText(field, ' ');
      await tester.tap(find.text(MessageKey.save.text));
      await tester.pumpAndSettle();
      expect(find.text(MessageKey.nameRequired.text), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(results, isEmpty);

      await tester.enterText(field, 'Danna');
      await tester.tap(find.text(MessageKey.save.text));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(saved, [' ', 'Danna']);
      expect(results, [true]);
    });

    testWidgets('a second submit while saving is ignored', (tester) async {
      final pending = Completer<MessageKey?>();
      var saves = 0;
      final results = await pumpOpener(
        tester,
        (context) => showRenameSheet(
          context,
          current: 'Dana',
          maxLength: 10,
          onSave: (_) {
            saves++;
            return pending.future;
          },
        ),
      );
      await tester.enterText(find.byType(TextField), 'Yossi');
      await tester.tap(find.text(MessageKey.save.text));
      await tester.pump();
      // The keyboard action is not gated by the disabled button.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(saves, 1);
      expect(find.byType(BottomSheet), findsOneWidget);

      pending.complete(MessageKey.memberNameTaken);
      await tester.pumpAndSettle();
      expect(find.text(MessageKey.memberNameTaken.text), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(results, isEmpty);
    });

    testWidgets('"ביטול" closes with null and never saves', (tester) async {
      var saves = 0;
      final results = await pumpOpener(
        tester,
        (context) => showRenameSheet(
          context,
          current: 'Dana',
          maxLength: 10,
          onSave: (_) async {
            saves++;
            return null;
          },
        ),
      );
      await tester.enterText(find.byType(TextField), 'Other');
      await tester.tap(find.text(MessageKey.cancel.text));
      await tester.pumpAndSettle();
      expect(results, [null]);
      expect(saves, 0);
    });
  });
}
