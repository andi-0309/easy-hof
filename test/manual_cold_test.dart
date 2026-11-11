import 'dart:convert';

import 'package:easy_hof/main.dart';
import 'package:easy_hof/manual_cold.dart';
import 'package:easy_hof/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> reveal(
  WidgetTester tester,
  Finder target,
  double delta, {
  Finder? scrollable,
}) async {
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    target,
    delta,
    scrollable: scrollable ?? find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final kind in ['shower', 'bath']) {
    testWidgets(
      'manual $kind saves a completed session without sensor access',
      (tester) async {
        final calls = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(Device.channel, (call) async {
              calls.add(call);
              return null;
            });
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ManualColdSession(language: 'en', initialKind: kind),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('manual-date')));
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsOneWidget);
        final chosenDate = tester
            .widget<DatePickerDialog>(find.byType(DatePickerDialog))
            .initialDate!;
        Navigator.of(tester.element(find.byType(DatePickerDialog))).pop();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('manual-time')));
        await tester.pumpAndSettle();
        expect(find.byType(TimePickerDialog), findsOneWidget);
        final chosenTime = tester
            .widget<TimePickerDialog>(find.byType(TimePickerDialog))
            .initialTime;
        final expectedEnd = DateTime(
          chosenDate.year,
          chosenDate.month,
          chosenDate.day,
          chosenTime.hour,
          chosenTime.minute,
        );
        final ok = MaterialLocalizations.of(
          tester.element(find.byType(TimePickerDialog)),
        ).okButtonLabel;
        await tester.tap(find.text(ok));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const ValueKey('Minutes')), '3');
        await tester.enterText(find.byKey(const ValueKey('Seconds')), '15');
        await reveal(tester, find.byKey(const Key('manual-temperature')), 200);
        if (kind == 'bath') {
          await tester.enterText(
            find.byKey(const Key('manual-temperature')),
            '7,5',
          );
        }
        await reveal(tester, find.text('Save'), 200);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        final saved =
            jsonDecode((calls.single.arguments as Map)['json'] as String)
                as Map;
        expect(calls.single.method, 'saveSession');
        expect(saved['kind'], kind);
        expect(saved['manual'], true);
        expect(saved['durationMs'], 195000);
        expect(
          DateTime.parse(saved['startedAt'] as String).toLocal(),
          expectedEnd.subtract(const Duration(seconds: 195)),
        );
        expect(saved.containsKey('hrCount'), false);
        if (kind == 'bath') {
          expect(saved['temperature'], 7.5);
        } else {
          expect(saved['temperature'], 5.0);
        }
        expect(find.text('Open'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'invalid duration is rejected and save retry keeps the same record ID',
    (tester) async {
      final saved = <Map>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(Device.channel, (call) async {
            saved.add(
              jsonDecode((call.arguments as Map)['json'] as String) as Map,
            );
            throw PlatformException(code: 'storage');
          });
      await tester.pumpWidget(
        const MaterialApp(home: ManualColdSession(language: 'en')),
      );
      await tester.enterText(find.byKey(const ValueKey('Minutes')), '0');
      await reveal(tester, find.text('Save'), 200);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saved, isEmpty);
      expect(
        find.text('Duration must be between 1 second and 24 hours.'),
        findsOneWidget,
      );
      await reveal(tester, find.byKey(const ValueKey('Minutes')), -200);
      await tester.enterText(find.byKey(const ValueKey('Minutes')), '1');
      await reveal(tester, find.text('Save'), 200);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Could not save. Please try again.'), findsOneWidget);
      await reveal(tester, find.text('Save'), 200);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saved, hasLength(2));
      expect(saved[0]['id'], saved[1]['id']);
      expect(find.byType(ManualColdSession), findsOneWidget);
    },
  );

  testWidgets('manual entry is available on phone only', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(Device.channel, (call) async {
          if (call.method == 'settings') return jsonEncode({'language': 'en'});
          if (call.method == 'snapshot') return jsonEncode({'sessions': []});
          return null;
        });
    await tester.pumpWidget(const EasyHof());
    await tester.pumpAndSettle();
    if (!isWear) {
      await tester.tap(find.text('Cold').last);
      await tester.pumpAndSettle();
    }
    if (isWear) {
      expect(find.text('Add manually'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      return;
    }
    await reveal(
      tester,
      find.text('Add manually'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Add manually'));
    await tester.pumpAndSettle();
    expect(find.byType(ManualColdSession), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('manual form fits a small watch screen', (tester) async {
    tester.view.physicalSize = const Size(192, 192);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: ManualColdSession(language: 'de')),
    );
    for (var i = 0; i < 10; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
