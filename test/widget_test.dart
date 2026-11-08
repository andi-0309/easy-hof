import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_hof/main.dart';
import 'package:easy_hof/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(Device.channel, (call) async {
          if (call.method == 'settings') return jsonEncode({'language': 'en'});
          if (call.method == 'snapshot') {
            return jsonEncode({'sessions': [], 'syncStatus': 'ready'});
          }
          if (call.method == 'voiceAvailable') return true;
          return null;
        });
  });
  testWidgets('phone navigation and settings are usable', (tester) async {
    await tester.pumpWidget(const EasyHof());
    await tester.pumpAndSettle();
    expect(find.text('Start breathing'), findsOneWidget);
    await tester.tap(find.text('Cold'));
    await tester.pumpAndSettle();
    expect(find.text('Temperature'), findsOneWidget);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('0 sessions'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DE'));
    await tester.pumpAndSettle();
    expect(find.text('Sprache & Stimme'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('breathing safety dialog opens below navigator', (tester) async {
    await tester.pumpWidget(const EasyHof());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start breathing'));
    await tester.pumpAndSettle();
    expect(find.text('Breathe safely'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
