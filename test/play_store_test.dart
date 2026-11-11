import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_hof/main.dart';
import 'package:easy_hof/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Play build opens the store from watch installation', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(Device.channel, (call) async {
          calls.add(call);
          if (call.method == 'settings') return jsonEncode({'language': 'en'});
          if (call.method == 'snapshot') return jsonEncode({'sessions': []});
          return null;
        });
    await tester.pumpWidget(const EasyHof());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Install watch app'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Install watch app'));
    await tester.pumpAndSettle();
    expect(calls.any((call) => call.method == 'openWatchStore'), isTrue);
    expect(calls.any((call) => call.method == 'watchPair'), isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
