import 'package:flutter_test/flutter_test.dart';
import 'package:easy_hof/breathing.dart';

void main() {
  test('complete cycles count exhalations before open-ended retention', () {
    final b = BreathingSession(rounds: 2, breaths: 30, cycleSeconds: 6)
      ..start();
    b.advance(3000 + 30 * 6000);
    expect(b.phase, BreathPhase.retention);
    expect(b.breath, 30);
    b.advance(45000);
    expect(b.phase, BreathPhase.retention);
    b.breatheAgain();
    expect(b.retentions, [45000]);
    expect(b.phase, BreathPhase.recovery);
    b.advance(15000);
    expect(b.phase, BreathPhase.rest);
    b.advance(5000);
    expect(b.round, 2);
    expect(b.breath, 1);
    b.advance(30 * 6000);
    b.advance(12000);
    b.breatheAgain();
    b.advance(20000);
    expect(b.phase, BreathPhase.done);
    expect(b.retentions, [45000, 12000]);
  });
  test('paused time and duplicate retention taps are ignored', () {
    final b = BreathingSession(breaths: 1)..start();
    b.advance(9000);
    b.advance(7000);
    b.paused = true;
    b.advance(90000);
    b.breatheAgain();
    expect(b.retentions, isEmpty);
    expect(b.phaseMs, 7000);
    b.paused = false;
    b.breatheAgain();
    b.breatheAgain();
    expect(b.retentions, [7000]);
  });
  test('stopped and completed sessions never advance', () {
    final b = BreathingSession(rounds: 1, breaths: 1)..start();
    b.advance(9000);
    b.breatheAgain();
    b.advance(20000);
    final total = b.totalMs;
    b.advance(9000);
    expect(b.totalMs, total);
    expect(durationLabel(65000), '1:05');
  });
}
