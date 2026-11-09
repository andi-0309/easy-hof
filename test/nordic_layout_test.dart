import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_hof/main.dart';
import 'package:easy_hof/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Nordic phone layout supports small screens, dark mode and large text',
    (tester) async {
      debugDisableShadows = false;

      await tester.runAsync(() async {
        for (final family in ['Inter', 'Manrope']) {
          await (FontLoader(
            family,
          )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
        }
      });
      await tester.runAsync(() async {
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      final boundary = GlobalKey();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(Device.channel, (call) async {
            if (call.method == 'settings') {
              return jsonEncode({'language': 'de'});
            }
            if (call.method == 'snapshot') return jsonEncode({'sessions': []});
            return null;
          });
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final dark in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          tester.view.physicalSize = Size(scale == 1 ? 360 : 320, 800);
          tester.platformDispatcher.platformBrightnessTestValue = dark
              ? Brightness.dark
              : Brightness.light;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          await tester.pumpWidget(
            RepaintBoundary(key: boundary, child: const EasyHof()),
          );
          await tester.pumpAndSettle();
          await tester.runAsync(
            () => precacheImage(
              const AssetImage('assets/images/nordic-mountains.webp'),
              tester.element(find.byType(Scaffold).first),
            ),
          );
          await tester.pumpAndSettle();
          for (final tab in ['Atmen', 'Kälte', 'Verlauf']) {
            await tester.tap(find.text(tab).last);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (scale == 1 &&
                Platform.environment['NORDIC_SCREENSHOTS'] == '1') {
              await tester.runAsync(() async {
                final image =
                    await (boundary.currentContext!.findRenderObject()!
                            as RenderRepaintBoundary)
                        .toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final folder = Directory('build/screenshots')
                  ..createSync(recursive: true);
                File(
                  '${folder.path}/${dark ? 'dark' : 'light'}-$tab.png',
                ).writeAsBytesSync(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -1500),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await tester.tap(find.byIcon(Icons.tune_rounded));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Uhr-App installieren'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Uhr-App installieren'));
          await tester.pumpAndSettle();
          expect(find.text('Deine Uhr verbinden'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
      }
      debugDisableShadows = true;
    },
  );
}
