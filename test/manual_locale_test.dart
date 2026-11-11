import 'package:easy_hof/manual_cold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'date and time pickers follow device locale independently of app text',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('de'),
          supportedLocales: [Locale('de'), Locale('en')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: ManualColdSession(language: 'en'),
        ),
      );
      await tester.tap(find.byKey(const Key('manual-date')));
      await tester.pumpAndSettle();
      final date = tester.element(find.byType(DatePickerDialog));
      expect(Localizations.localeOf(date).languageCode, 'de');
      Navigator.of(date).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('manual-time')));
      await tester.tap(find.byKey(const Key('manual-time')));
      await tester.pumpAndSettle();
      expect(
        Localizations.localeOf(
          tester.element(find.byType(TimePickerDialog)),
        ).languageCode,
        'de',
      );
    },
  );
}
