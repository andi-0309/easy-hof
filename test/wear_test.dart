import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_hof/main.dart';
import 'package:easy_hof/platform.dart';
import 'package:easy_hof/wear_companion.dart';
import 'nordic_release_test.dart' show screenshot;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> fonts(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final family in ['Inter', 'Manrope']) {
        await (FontLoader(
          family,
        )..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
      }
    });
  }

  void setup(
    WidgetTester tester, {
    Size size = const Size(192, 192),
    bool active = false,
    bool request = false,
    List<MethodCall>? calls,
  }) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(Device.channel, (call) async {
          calls?.add(call);
          if (call.method == 'settings') return jsonEncode({'language': 'de'});
          if (call.method == 'snapshot') {
            return jsonEncode({
              'sessions': [],
              if (request)
                'breathingRequest': {
                  'id': 'breath-test',
                  'sentAt': DateTime.now().millisecondsSinceEpoch,
                  'ended': false,
                },
              if (active)
                'active': {
                  'kind': 'bath',
                  'durationMs': 65000,
                  'bpm': 80,
                  'temperature': 8.5,
                },
            });
          }
          if (call.method == 'requestHeartRate') return true;
          return null;
        });
  }

  testWidgets('round shortcuts lead to separate time and temperature steps', (
    tester,
  ) async {
    setup(tester);
    await fonts(tester);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: const EasyHof()));
    await tester.pumpAndSettle();
    expect(find.text('Zielzeit'), findsNothing);
    expect(find.byIcon(Icons.settings), findsNothing);
    expect(find.byIcon(Icons.history), findsNothing);
    await screenshot(tester, key, 'wear-shortcuts');
    await tester.tap(find.text('Dusche'));
    await tester.pumpAndSettle();
    expect(find.text('Zielzeit'), findsOneWidget);
    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();
    expect(find.text('0:30'), findsOneWidget);
    await screenshot(tester, key, 'wear-time');
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('Temperatur'), findsOneWidget);
    await tester.tap(find.text('Einstellen'));
    await tester.pumpAndSettle();
    expect(find.text('15.0 °C'), findsOneWidget);
    await screenshot(tester, key, 'wear-temperature');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  }, skip: !isWear);
  testWidgets('active round watch exposes stop and live pulse', (tester) async {
    setup(tester, active: true);
    await fonts(tester);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: const EasyHof()));
    await tester.pumpAndSettle();
    expect(find.text('1:05'), findsOneWidget);
    expect(find.text('Beenden').hitTestable(), findsOneWidget);
    await screenshot(tester, key, 'wear-active');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  }, skip: !isWear);
  testWidgets('rectangular watches center a circular interaction surface', (
    tester,
  ) async {
    setup(tester, size: const Size(240, 320));
    await tester.pumpWidget(const EasyHof());
    await tester.pumpAndSettle();
    final oval = find
        .descendant(
          of: find.byType(WearCompanion),
          matching: find.byType(ClipOval),
        )
        .first;
    expect(tester.getSize(oval), const Size(240, 240));
    expect(tester.getTopLeft(oval).dy, 40);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dusche'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  }, skip: !isWear);
  testWidgets('phone breathing request offers explicit watch sensor consent', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    setup(tester, request: true, calls: calls);
    await tester.pumpWidget(const EasyHof());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Puls starten'));
    await tester.pumpAndSettle();
    expect(calls.where((c) => c.method == 'requestHeartRate'), isEmpty);
    await tester.tap(find.text('Verstanden'));
    await tester.pumpAndSettle();
    expect(calls.any((c) => c.method == 'requestHeartRate'), isTrue);
    expect(calls.any((c) => c.method == 'startBreathingPulse'), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  }, skip: !isWear);
}
