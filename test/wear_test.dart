import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_hof/main.dart';
import 'package:easy_hof/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('small watch has no overflow in cold, history and settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(192, 192);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(Device.channel, (call) async {
          if (call.method == 'settings') return jsonEncode({'language': 'de'});
          if (call.method == 'snapshot') return jsonEncode({'sessions': []});
          return null;
        });
    await tester.pumpWidget(const EasyHof());
    await tester.pumpAndSettle();
    expect(find.text('Starten'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  }, skip: !isWear);
}
