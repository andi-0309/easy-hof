import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_hof/main.dart';
import 'package:easy_hof/platform.dart';
import 'package:easy_hof/training_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> screenshot(WidgetTester tester, GlobalKey key, String name) async {
  if (Platform.environment['NORDIC_SCREENSHOTS'] != '1') return;
  await tester.runAsync(() async {
    final image =
        await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
            .toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('build/screenshots')..createSync(recursive: true);
    File(
      '${folder.path}/$name.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('calendar detail and breathing transition use Nordic controls', (
    tester,
  ) async {
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(isWear ? 192 : 390, isWear ? 192 : 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
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
    final calls = <MethodCall>[];
    final now = DateTime.now();
    final sessions = [
      for (var i = 0; i < 9; i++)
        <String, dynamic>{
          'id': 'sample-$i',
          'kind': ['bath', 'shower', 'breathing'][i % 3],
          'startedAt': DateTime(
            now.year,
            now.month,
            now.day - i,
            9,
          ).toUtc().toIso8601String(),
          'source': 'wear',
          'durationMs': 180000,
          if (i % 3 == 0) ...{
            'temperature': 8.5,
            'hrCount': 5,
            'hrSum': 400,
            'hrMin': 72,
            'hrMax': 90,
            'hrSamples': [
              [0, 90],
              [5000, 87],
              [10000, 85],
              [15000, 83],
              [20000, 80],
              [25000, 79],
              [30000, 76],
              [35000, 74],
              [40000, 72],
              [45000, 75],
              [50000, 76],
              [55000, 78],
              [60000, 80],
              [65000, 79],
            ],
          },
        },
    ];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(Device.channel, (call) async {
          calls.add(call);
          if (call.method == 'settings') {
            return jsonEncode({
              'language': 'en',
              'rounds': 1,
              'breaths': 10,
              'pace': 4,
            });
          }
          if (call.method == 'snapshot') {
            return jsonEncode({'sessions': sessions});
          }
          return null;
        });
    var elapsedMs = 0;
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: EasyHof(elapsedMs: () => elapsedMs),
      ),
    );
    await tester.pumpAndSettle();
    if (isWear) {
      await screenshot(tester, key, 'wear-cold');
      await tester.tap(find.byIcon(Icons.history));
    } else {
      await tester.tap(find.text('History').last);
    }
    await tester.pumpAndSettle();
    await screenshot(tester, key, isWear ? 'wear-history' : 'phone-history');
    final day = find.byKey(ValueKey('day-${now.year}-${now.month}-${now.day}'));
    await tester.scrollUntilVisible(
      day,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(day);
    await tester.pumpAndSettle();
    expect(find.byType(TrainingDay), findsOneWidget);
    await screenshot(tester, key, isWear ? 'wear-day' : 'phone-day');
    await tester.scrollUntilVisible(
      find.text(isWear ? 'Pulse trace' : 'Heart-rate trace'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await screenshot(tester, key, isWear ? 'wear-pulse' : 'phone-pulse');
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    if (!isWear) {
      await tester.tap(find.text('Breathe').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Start breathing'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Start breathing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Understood'));
      for (var i = 0; i < 207; i++) {
        elapsedMs += 200;
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.text('Exhale gently'), findsOneWidget);
      expect(
        calls.any(
          (c) =>
              c.method == 'playCue' &&
              (c.arguments as Map)['cue'] == 'final_exhale',
        ),
        isTrue,
      );
      await screenshot(tester, key, 'phone-final-exhale');
      for (var i = 0; i < 30; i++) {
        elapsedMs += 200;
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.text('Hold after exhaling'), findsOneWidget);
      expect(find.text('I am breathing again').hitTestable(), findsOneWidget);
      await screenshot(tester, key, 'phone-retention');
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await screenshot(tester, key, 'phone-retention-dark');
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    debugDisableShadows = true;
  }, skip: isWear);
}
