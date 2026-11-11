import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_hof/main.dart';
import 'package:easy_hof/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'both offline privacy policies are included in the asset bundle',
    () async {
      for (final language in ['de', 'en']) {
        final text = await rootBundle.loadString(
          'assets/privacy/privacy-$language.txt',
        );
        expect(text, contains('io.github.andi_0309.easyhof'));
        expect(text, contains('BODY_SENSORS'));
        expect(text, contains('READ_HEART_RATE'));
        expect(text, contains('https://github.com/andi-0309/easy-hof/issues'));
      }
    },
  );
  testWidgets(
    'privacy policy can be read from settings without a network call',
    (tester) async {
      final policy = await tester.runAsync(
        () => rootBundle.loadString('assets/privacy/privacy-en.txt'),
      );
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(Device.channel, (call) async {
            calls.add(call);
            if (call.method == 'settings') {
              return jsonEncode({'language': 'en'});
            }
            if (call.method == 'snapshot') return jsonEncode({'sessions': []});
            return null;
          });
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: _PrivacyBundle(policy!),
          child: const EasyHof(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Privacy policy'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Privacy policy'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectableText), findsOneWidget);
      expect(calls.any((call) => call.method == 'openWatchStore'), isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class _PrivacyBundle extends CachingAssetBundle {
  _PrivacyBundle(this.policy);
  final String policy;

  @override
  Future<ByteData> load(String key) => rootBundle.load(key);

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    if (key.startsWith('assets/privacy/')) {
      return Future.value(policy);
    }
    return rootBundle.loadString(key, cache: cache);
  }
}
