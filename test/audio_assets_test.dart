import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all speech clips are in the Flutter asset bundle', () async {
    for (final language in ['de', 'en']) {
      final finalExhale = base64Decode(
        (await rootBundle.loadString(
          'assets/audio/$language/final_exhale.b64',
        )).trim(),
      );
      expect(finalExhale.length, greaterThan(4000));
      for (final cue in [
        'welcome',
        'countdown',
        'inhale',
        'exhale',
        'retention',
        'recovery',
        'rest',
        'done',
      ]) {
        final data = await rootBundle.load('assets/audio/$language/$cue.mp3');
        expect(data.lengthInBytes, greaterThan(4000));
      }
    }
  });
}
