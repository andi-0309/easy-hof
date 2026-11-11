import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'breathing.dart';
import 'nordic.dart';

class BreathingPage extends StatelessWidget {
  const BreathingPage({
    super.key,
    required this.session,
    required this.language,
    required this.voice,
    required this.onToggleVoice,
    required this.onTogglePause,
    required this.onFinish,
    required this.onBreatheAgain,
    required this.onExhale,
    required this.onRetry,
    this.error,
    this.pendingSave = false,
  });
  final BreathingSession session;
  final String language;
  final bool voice, pendingSave;
  final String? error;
  final VoidCallback onToggleVoice,
      onTogglePause,
      onFinish,
      onBreatheAgain,
      onExhale,
      onRetry;
  String t(String de, String en) => language == 'de' ? de : en;

  @override
  Widget build(BuildContext context) {
    final b = session;
    final colors = Theme.of(context).colorScheme;
    final phase = b.paused
        ? t('Pausiert', 'Paused')
        : switch (b.phase) {
            BreathPhase.countdown => t('Ankommen', 'Settle in'),
            BreathPhase.inhale => t('Einatmen', 'Breathe in'),
            BreathPhase.exhale =>
              b.isFinalExhale
                  ? t('Entspannt ausatmen', 'Exhale gently')
                  : t('Ausatmen', 'Breathe out'),
            BreathPhase.retention => t(
              'Nach dem Ausatmen halten',
              'Hold after exhaling',
            ),
            BreathPhase.recovery => t('Einatmen & halten', 'Breathe in & hold'),
            BreathPhase.rest => t('Normal atmen', 'Breathe normally'),
            _ => t('Geschafft', 'Finished'),
          };
    final subtitle = b.paused
        ? t('Setze fort, wenn du bereit bist.', 'Continue when you are ready.')
        : switch (b.phase) {
            BreathPhase.inhale => t(
              'Ruhig und tief einatmen',
              'Breathe in deeply and gently',
            ),
            BreathPhase.exhale =>
              b.isFinalExhale
                  ? t(
                      'Letzten Atemzug locker ausströmen lassen. Nicht pressen.',
                      'Let the last breath flow out naturally. Do not push.',
                    )
                  : t(
                      'Lass die Luft locker ausströmen',
                      'Let your breath flow out naturally',
                    ),
            BreathPhase.retention => t(
              'Atme wieder, sobald du Luft brauchst.',
              'Breathe when you need air.',
            ),
            BreathPhase.recovery => t(
              'Kurz halten. Ohne Druck.',
              'Hold briefly, without forcing.',
            ),
            BreathPhase.rest => t(
              'Atme ganz normal weiter.',
              'Keep breathing naturally.',
            ),
            _ => t('Mach es dir bequem.', 'Get comfortable.'),
          };
    final cyclic =
        b.phase == BreathPhase.inhale || b.phase == BreathPhase.exhale;
    final count = cyclic
        ? '${b.breath} / ${b.breaths}'
        : b.phaseLimit == null
        ? durationLabel(b.phaseMs)
        : '${((b.phaseLimit! - b.phaseMs) / 1000).ceil()}';
    final label = cyclic
        ? t('Atemzüge', 'Breaths')
        : b.phase == BreathPhase.retention
        ? t('Atemhaltezeit', 'Breath-hold time')
        : t('Sekunden', 'Seconds');
    final primary =
        b.phase == BreathPhase.retention || b.phase == BreathPhase.recovery;
    return PopScope(
      canPop: false,
      child: Scaffold(
        bottomNavigationBar: primary
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: SunButton(
                    large: true,
                    icon: Icons.air_rounded,
                    label: b.phase == BreathPhase.retention
                        ? t('Ich atme wieder', 'I am breathing again')
                        : t('Jetzt ausatmen', 'Exhale now'),
                    onPressed: b.paused
                        ? null
                        : b.phase == BreathPhase.retention
                        ? onBreatheAgain
                        : onExhale,
                  ),
                ),
              )
            : null,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final width = math.min(box.maxWidth, 560.0);
              final counterSize = (width * .25).clamp(64.0, 112.0);
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: IntrinsicHeight(
                    child: Center(
                      child: SizedBox(
                        width: width,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${t('Runde', 'Round')} ${b.round} / ${b.rounds}',
                                          style: const TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ExcludeSemantics(
                                          child: Row(
                                            children: [
                                              for (
                                                var i = 1;
                                                i <= b.rounds;
                                                i++
                                              ) ...[
                                                if (i > 1)
                                                  Container(
                                                    width: 8,
                                                    height: 2,
                                                    color: colors.primary
                                                        .withValues(alpha: .25),
                                                  ),
                                                Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: i <= b.round
                                                        ? colors.primary
                                                        : colors.surface,
                                                    border: Border.all(
                                                      color: colors.primary
                                                          .withValues(
                                                            alpha: i <= b.round
                                                                ? 1
                                                                : .3,
                                                          ),
                                                      width: 1.5,
                                                    ),
                                                    boxShadow: i == b.round
                                                        ? [
                                                            BoxShadow(
                                                              color: colors
                                                                  .primary
                                                                  .withValues(
                                                                    alpha: .2,
                                                                  ),
                                                              blurRadius: 6,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    2,
                                                                  ),
                                                            ),
                                                          ]
                                                        : [],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colors.surface,
                                      border: Border.all(
                                        color: colors.primary.withValues(
                                          alpha: .25,
                                        ),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.primary.withValues(
                                            alpha: .2,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      tooltip: voice
                                          ? t('Ton ausschalten', 'Mute audio')
                                          : t(
                                              'Ton einschalten',
                                              'Enable audio',
                                            ),
                                      onPressed: onToggleVoice,
                                      iconSize: 26,
                                      padding: const EdgeInsets.all(13),
                                      icon: Icon(
                                        voice
                                            ? Icons.volume_up_rounded
                                            : Icons.volume_off_rounded,
                                        color: colors.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: math.min(38, box.maxHeight * .05),
                              ),
                              if (error != null)
                                Text(
                                  error!,
                                  style: TextStyle(color: colors.error),
                                ),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  phase,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: width < 350 ? 32 : 38,
                                    fontWeight: FontWeight.w800,
                                    color: colors.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  height: 1.4,
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(
                                height: math.min(38, box.maxHeight * .05),
                              ),
                              SizedBox(
                                height: counterSize * 1.22,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    count,
                                    key: const Key('breathing-counter'),
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: counterSize,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -3,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              // Leave the scenic background unobstructed between counter and controls.
                              SizedBox(
                                height: primary
                                    ? 36
                                    : math.max(100, box.maxHeight * .15),
                              ),
                              if (pendingSave)
                                SunButton(
                                  large: true,
                                  label: t('Erneut speichern', 'Retry save'),
                                  icon: Icons.refresh_rounded,
                                  onPressed: onRetry,
                                )
                              else ...[
                                SunButton(
                                  large: true,
                                  height: 64,
                                  secondary: true,
                                  label: b.paused
                                      ? t('Fortsetzen', 'Resume')
                                      : t('Pause', 'Pause'),
                                  icon: b.paused
                                      ? Icons.play_arrow_rounded
                                      : Icons.pause_rounded,
                                  onPressed: onTogglePause,
                                ),
                                const SizedBox(height: 18),
                                SunButton(
                                  large: true,
                                  height: 64,
                                  deep: true,
                                  label: t('Beenden', 'Finish'),
                                  icon: Icons.stop_rounded,
                                  onPressed: onFinish,
                                ),
                              ],
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
