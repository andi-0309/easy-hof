import 'package:easy_hof/training_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'streak counts calendar days, accepts yesterday and ignores future days',
    () {
      final sessions = [
        for (final day in [8, 9, 10, 12])
          {'startedAt': DateTime(2026, 11, day, 12).toUtc().toIso8601String()},
      ];
      expect(activeStreak(sessions, DateTime(2026, 11, 11)), 3);
      expect(activeStreak(sessions, DateTime(2026, 11, 14)), 0);
    },
  );
  testWidgets(
    'calendar opens the chosen day, preserves trace gaps and deletes sessions',
    (tester) async {
      final now = DateTime.now();
      final session = <String, dynamic>{
        'id': 'trace',
        'kind': 'bath',
        'startedAt': now.toUtc().toIso8601String(),
        'durationMs': 60000,
        'hrSamples': [
          [0, 80],
          [5000, 85],
          [30000, 70],
        ],
        'hrCount': 3,
        'hrSum': 235,
        'hrMin': 70,
        'hrMax': 85,
      };
      var deletes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrainingHistory(
                sessions: [session],
                language: 'en',
                onDelete: (_) async {
                  deletes++;
                  return true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.ensureVisible(
        find.byKey(ValueKey('day-${now.year}-${now.month}-${now.day}')),
      );
      await tester.tap(
        find.byKey(ValueKey('day-${now.year}-${now.month}-${now.day}')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TrainingDay), findsOneWidget);
      expect(find.text('Heart-rate trace'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Delete'));
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(deletes, 1);
      expect(find.text('No sessions on this day.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('old summaries and manual entries do not invent a trace', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HeartRateChart(
            session: {'hrCount': 2, 'hrSum': 160, 'hrMin': 70, 'hrMax': 90},
            language: 'en',
          ),
        ),
      ),
    );
    expect(find.text('No heart-rate trace available.'), findsOneWidget);
  });
}
