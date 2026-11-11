import 'dart:convert';
import 'package:easy_hof/main.dart';
import 'package:easy_hof/nordic.dart';
import 'package:easy_hof/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'phone breathing requests watch pulse, pauses and ends the same session',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var elapsed = 0;
      Map<String, dynamic>? request, saved;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(Device.channel, (call) async {
            if (call.method == 'settings') {
              return jsonEncode({
                'language': 'en',
                'rounds': 1,
                'breaths': 10,
                'pace': 4,
              });
            }
            if (call.method == 'breathingPulse') {
              request = Map<String, dynamic>.from(
                jsonDecode((call.arguments as Map)['json'] as String) as Map,
              );
            }
            if (call.method == 'saveSession') {
              saved = Map<String, dynamic>.from(
                jsonDecode((call.arguments as Map)['json'] as String) as Map,
              );
            }
            if (call.method == 'snapshot') {
              return jsonEncode({
                'sessions': [],
                if (request != null)
                  'breathingPulse': {
                    'id': request!['id'],
                    'bpm': 80,
                    'sentAt': DateTime.now().millisecondsSinceEpoch,
                  },
              });
            }
            return null;
          });
      await tester.pumpWidget(EasyHof(elapsedMs: () => elapsed));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -350));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start breathing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Understood'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(request!['ended'], false);
      final id = request!['id'];
      for (var i = 0; i < 20; i++) {
        elapsed += 200;
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.text('♥ 80 bpm'), findsOneWidget);
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byWidgetPredicate(
                      (w) => w is CustomPaint && w.painter is MountainPainter,
                    ),
                  )
                  .painter
              as MountainPainter;
      expect(painter.breath, greaterThan(0));
      await tester.tap(find.text('Pause'));
      await tester.pumpAndSettle();
      expect(request!['paused'], true);
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish').last);
      await tester.pumpAndSettle();
      expect(request!['ended'], true);
      expect(saved!['id'], id);
      expect(saved!['kind'], 'breathing');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    skip: isWear,
  );
  testWidgets('reduced motion keeps the mountain background still', (
    tester,
  ) async {
    final amount = ValueNotifier<double>(1);
    addTearDown(amount.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: NordicBackdrop(breath: amount, child: child!),
        ),
        home: const Scaffold(),
      ),
    );
    await tester.pumpAndSettle();
    final painter =
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (w) => w is CustomPaint && w.painter is MountainPainter,
                  ),
                )
                .painter
            as MountainPainter;
    expect(painter.breath, 0);
    expect(tester.takeException(), isNull);
  });
}
