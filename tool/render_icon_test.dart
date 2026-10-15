// Renders GroupayLogo to the PNGs used by flutter_launcher_icons.
// Run: flutter test tool/render_icon_test.dart && dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/widgets/groupay_logo.dart';

Future<void> _render(String path, GroupayLogoPainter painter) async {
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), const Size(size, size));
  final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path)..createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('render launcher icon images', (tester) async {
    await tester.runAsync(() async {
      // Full icon on white (iOS and legacy Android).
      await _render(
        'assets/icon/icon.png',
        GroupayLogoPainter(scale: 0.86, background: Colors.white),
      );
      // Adaptive icon foreground: keep the mark inside Android's safe zone.
      await _render(
        'assets/icon/icon_foreground.png',
        GroupayLogoPainter(scale: 0.6),
      );
    });
  });
}
