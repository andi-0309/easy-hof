import 'dart:convert';
import 'package:easy_hof/main.dart';
import 'package:easy_hof/nordic.dart';
import 'package:easy_hof/platform.dart';
import 'package:easy_hof/training_history.dart';
import 'package:easy_hof/wear_scroll.dart';
import 'package:easy_hof/breathing_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cold defaults follow the selected training kind', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(Device.channel, (call) async {
          if (call.method == 'settings') return jsonEncode({'language': 'en'});
          if (call.method == 'snapshot') return jsonEncode({'sessions': []});
          return null;
        });
    await tester.pumpWidget(const EasyHof());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cold').last);
    await tester.pumpAndSettle();
    expect(find.text('3:00'), findsOneWidget);
    await tester.tap(find.text('Ice bath'));
    await tester.pumpAndSettle();
    expect(find.text('5:00'), findsOneWidget);
    await tester.tap(find.text('Shower'));
    await tester.pumpAndSettle();
    expect(find.text('3:00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  }, skip: isWear);
  testWidgets(
    'phone back and settings use the same raised control and content grid',
    (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: nordicTheme(Brightness.light),
          home: Builder(
            builder: (context) => Scaffold(
              appBar: NordicAppBar(
                title: const Text('Home'),
                actions: [
                  NordicIconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => TrainingDay(
                        date: DateTime(2026, 11, 11),
                        sessions: const [],
                        language: 'en',
                        onDelete: (_) async => true,
                      ),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      final settings = tester.getRect(find.byType(NordicIconButton));
      expect(settings.width, 48);
      expect(settings.right, 656);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final back = tester.getRect(find.byType(NordicIconButton));
      expect(back.width, settings.width);
      expect(back.left, 144);
      expect(tester.takeException(), isNull);
    },
    skip: isWear,
  );
  testWidgets('morph retains outgoing content during a soft transition', (
    tester,
  ) async {
    Widget app(String value) => MaterialApp(
      home: Scaffold(
        body: MorphText(value, style: const TextStyle(fontSize: 60)),
      ),
    );
    await tester.pumpWidget(app('0:09'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app('0:10'));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('0:09'), findsOneWidget);
    expect(find.text('0:10'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('0:09'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'crown scrolls the visible route without moving the page behind a dialog',
    (tester) async {
      late BuildContext homeContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              homeContext = context;
              return Scaffold(
                body: WearScroll(
                  children: [
                    for (var i = 0; i < 40; i++)
                      SizedBox(height: 50, child: Text('Item $i')),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> rotate(double delta) async {
        tester.binding.channelBuffers.push(
          'io.github.andi_0309.easyhof/rotary',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('scroll', delta),
          ),
          (_) {},
        );
        await tester.pump();
      }

      await rotate(80);
      final parent = tester.widget<ListView>(find.byType(ListView)).controller!;
      expect(parent.offset, 80);
      showDialog<void>(
        context: homeContext,
        builder: (_) => Dialog(
          child: SizedBox(
            height: 200,
            child: WearScroll(
              children: [
                for (var i = 0; i < 20; i++)
                  SizedBox(height: 50, child: Text('Dialog $i')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await rotate(60);
      expect(parent.offset, 80);
      final dialog = tester
          .widget<ListView>(find.byType(ListView).last)
          .controller!;
      expect(dialog.offset, 60);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
