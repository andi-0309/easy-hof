import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_hof/main.dart';
import 'package:easy_hof/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  void setupDevice(WidgetTester tester, {bool active = false}) {
    tester.view.physicalSize = const Size(192, 192);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(Device.channel, (call) async {
          if (call.method == 'settings') return jsonEncode({'language': 'de'});
          if (call.method == 'snapshot') {
            return jsonEncode({
              'sessions': [
                {
                  'id': 'test-id',
                  'kind': 'bath',
                  'source': 'wear',
                  'startedAt': '2026-11-08T10:00:00Z',
                  'durationMs': 65000,
                  'temperature': 8.5,
                  'hrCount': 2,
                  'hrSum': 150,
                  'hrMin': 70,
                  'hrMax': 80,
                },
              ],
              if (active)
                'active': {
                  'kind': 'bath',
                  'durationMs': 65000,
                  'bpm': 80,
                  'hrStatus': 'ok',
                  'temperature': 8.5,
                  'goalSeconds': 120,
                },
            });
          }
          return null;
        });
  }

  testWidgets('small watch cold controls and navigation do not overflow', (
    tester,
  ) async {
    setupDevice(tester);
    await tester.pumpWidget(const EasyHof());
    await tester.pumpAndSettle();
    expect(find.text('Starten').hitTestable(), findsOneWidget);
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.drag(find.byType(ListView), const Offset(0, 3000));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  }, skip: !isWear);

  testWidgets('active watch exposes stop without scrolling', (tester) async {
    setupDevice(tester, active: true);
    await tester.pumpWidget(const EasyHof());
    await tester.pumpAndSettle();
    expect(find.text('1:05'), findsOneWidget);
    expect(find.text('Beenden').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  }, skip: !isWear);
}
