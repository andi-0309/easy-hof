import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_hof/breathing.dart';
import 'package:easy_hof/breathing_view.dart';
import 'package:easy_hof/nordic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'free counter, scenic background and large controls match reference',
    (tester) async {
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = true);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.runAsync(() async {
        for (final family in ['Inter', 'Manrope']) {
          await (FontLoader(
            family,
          )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
        }
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      for (final mode in ['light', 'dark', 'large']) {
        tester.view.physicalSize = mode == 'large'
            ? const Size(320, 600)
            : const Size(390, 844);
        tester.platformDispatcher.textScaleFactorTestValue = mode == 'large'
            ? 2
            : 1;
        var muted = 0;
        final session = BreathingSession(rounds: 3, breaths: 30)
          ..start()
          ..advance(3400);
        final key = GlobalKey();
        Widget app() => RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: nordicTheme(Brightness.light),
            darkTheme: nordicTheme(Brightness.dark),
            themeMode: mode == 'dark' ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) => NordicBackdrop(child: child!),
            home: BreathingPage(
              session: session,
              language: 'de',
              voice: true,
              onToggleVoice: () => muted++,
              onTogglePause: () {},
              onFinish: () {},
              onBreatheAgain: () {},
              onExhale: () {},
              onRetry: () {},
            ),
          ),
        );
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        expect(find.text('1 / 30'), findsOneWidget);
        expect(find.byType(NordicCard), findsNothing);
        expect(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is MountainPainter,
          ),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip('Ton ausschalten'));
        await tester.pumpAndSettle();
        expect(muted, 1);
        if (Platform.environment['NORDIC_SCREENSHOTS'] == '1' &&
            mode != 'large') {
          await tester.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            Directory('build/screenshots').createSync(recursive: true);
            File(
              'build/screenshots/reference-$mode.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        session.phase = BreathPhase.retention;
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        expect(find.text('Ich atme wieder').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
      debugDisableShadows = true;
    },
  );
}
