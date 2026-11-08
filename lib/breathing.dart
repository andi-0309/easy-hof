enum BreathPhase {
  ready,
  countdown,
  inhale,
  exhale,
  retention,
  recovery,
  rest,
  done,
}

/// Deterministic session clock. Only active foreground time is advanced.
class BreathingSession {
  BreathingSession({this.rounds = 3, this.breaths = 30, this.cycleSeconds = 6});
  final int rounds;
  final int breaths;
  final int cycleSeconds;
  BreathPhase phase = BreathPhase.ready;
  int round = 1;
  int breath = 1;
  int phaseMs = 0;
  int totalMs = 0;
  bool paused = false;
  final List<int> retentions = [];

  void start() {
    phase = BreathPhase.countdown;
  }

  int? get phaseLimit => switch (phase) {
    BreathPhase.countdown => 3000,
    BreathPhase.inhale || BreathPhase.exhale => cycleSeconds * 500,
    BreathPhase.recovery => 15000,
    BreathPhase.rest => 5000,
    _ => null,
  };

  void advance(int milliseconds) {
    if (paused || phase == BreathPhase.ready || phase == BreathPhase.done) {
      return;
    }
    totalMs += milliseconds;
    phaseMs += milliseconds;
    while (phaseLimit != null && phaseMs >= phaseLimit!) {
      phaseMs -= phaseLimit!;
      switch (phase) {
        case BreathPhase.countdown:
          phase = BreathPhase.inhale;
        case BreathPhase.inhale:
          phase = BreathPhase.exhale;
        case BreathPhase.exhale:
          if (breath == breaths) {
            phase = BreathPhase.retention;
          } else {
            breath++;
            phase = BreathPhase.inhale;
          }
        case BreathPhase.recovery:
          phase = BreathPhase.rest;
        case BreathPhase.rest:
          if (round == rounds) {
            phase = BreathPhase.done;
            phaseMs = 0;
          } else {
            round++;
            breath = 1;
            phase = BreathPhase.inhale;
          }
        default:
          break;
      }
    }
  }

  void breatheAgain() {
    if (phase != BreathPhase.retention || paused) return;
    retentions.add(phaseMs);
    phaseMs = 0;
    phase = BreathPhase.recovery;
  }
}

String durationLabel(int milliseconds) {
  final seconds = milliseconds ~/ 1000;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
