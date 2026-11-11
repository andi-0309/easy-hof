import 'package:easy_hof/nordic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'primary face stays orange without Material tint in both themes',
    (tester) async {
      for (final brightness in Brightness.values) {
        for (final enabled in [true, false]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: nordicTheme(brightness),
              home: Scaffold(
                body: SunButton(
                  label: 'Start',
                  onPressed: enabled ? () {} : null,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final face = tester.widget<AnimatedContainer>(
            find.descendant(
              of: find.byType(SunButton),
              matching: find.byType(AnimatedContainer),
            ),
          );
          expect(
            ((face.decoration as BoxDecoration).gradient as LinearGradient)
                .colors,
            nordicButtonColors(NordicTone.sun, disabled: !enabled),
          );
          final material = tester.widget<Material>(
            find.descendant(
              of: find.byType(NordicButton),
              matching: find.byType(Material),
            ),
          );
          expect(material.elevation, 0);
          expect(material.color, Colors.transparent);
          expect(material.surfaceTintColor, Colors.transparent);
          expect(find.byType(FilledButton), findsNothing);
        }
      }
    },
  );
  testWidgets('shared selection and icon actions remain functional', (
    tester,
  ) async {
    var choice = 'de';
    var icons = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                NordicSegmented<String>(
                  segments: const [
                    ButtonSegment(value: 'de', label: Text('DE')),
                    ButtonSegment(value: 'en', label: Text('EN')),
                  ],
                  selected: {choice},
                  onSelectionChanged: (value) =>
                      setState(() => choice = value.first),
                ),
                NordicIconButton(
                  tooltip: 'Action',
                  onPressed: () => icons++,
                  icon: const Icon(Icons.settings),
                ),
                NordicDropdown<String>(
                  value: choice,
                  items: const [
                    DropdownMenuItem(value: 'de', child: Text('German')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (value) => setState(() => choice = value!),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(choice, 'en');
    await tester.tap(find.byTooltip('Action'));
    expect(icons, 1);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('German'));
    await tester.pumpAndSettle();
    expect(choice, 'de');
    expect(tester.takeException(), isNull);
  });
}
