@Tags(['export'])
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aj_assistant/features/auth/widgets/seal_logo.dart';

/// Exports the app icon as a 1024x1024 PNG using Flutter's real renderer.
///
/// Run from the project root:
///   flutter test test/export_logo_test.dart --tags export
///
/// Output: assets/app_icon.png
void main() {
  testWidgets('export app icon', (tester) async {
    // Force a square 1024x1024 surface.
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;

    // Load the real CormorantGaramond font.
    final fontData =
        File('assets/fonts/CormorantGaramond.ttf').readAsBytesSync();
    final fontLoader = FontLoader('CormorantGaramond')
      ..addFont(Future.value(ByteData.sublistView(fontData)));
    await fontLoader.load();

    final key = GlobalKey();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1024, 1024)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: Container(
              width: 1024,
              height: 1024,
              color: const Color(0xFFF6F1E9), // cream washi paper background
              alignment: Alignment.center,
              padding: const EdgeInsets.all(100), // ~10% padding
              child: const SealLogo(
                color: Color(0xFFD94E33), // vermillion seal
                textColor: Color(0xFF1C1917), // charcoal text
                size: 824, // 1024 - 2*100
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final outputDir = Directory('assets');
    if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

    File('assets/app_icon.png').writeAsBytesSync(pngBytes);
    debugPrint('Exported app_icon.png (${image.width}x${image.height})');

    // Reset the test surface.
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
