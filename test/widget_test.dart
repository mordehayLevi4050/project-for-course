import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groupay/main.dart';

void main() {
  testWidgets('Home screen shows the app title and the new group button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GroupayApp());

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Groupay')),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(ElevatedButton, 'קבוצה חדשה'),
      findsOneWidget,
    );
  });
}
