import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'breathing.dart';
import 'nordic.dart';
import 'wear_scroll.dart';
import 'water_lock.dart';

/// A circular interaction area on every watch. Rectangular surplus remains scenery.
class WearCompanion extends StatefulWidget {
  const WearCompanion({
    super.key,
    required this.data,
    required this.language,
    required this.busy,
    this.error,
    required this.onStartCold,
    required this.onStopCold,
    required this.onStartPulse,
    required this.onStopPulse,
  });
  final Map<String, dynamic> data;
  final String language;
  final bool busy;
  final String? error;
  final Future<void> Function(String, int, double?) onStartCold;
  final VoidCallback onStopCold, onStartPulse, onStopPulse;
  @override
  State<WearCompanion> createState() => _WearCompanionState();
}

class _WearCompanionState extends State<WearCompanion> {
  String page = 'home', kind = 'shower';
  int seconds = 180;
  double? temperature = 5;
  @override
  void didUpdateWidget(covariant WearCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.data['active'] != null && widget.data['active'] == null) ||
        (oldWidget.data['watchPulse'] != null &&
            widget.data['watchPulse'] == null)) {
      page = 'home';
    }
  }

  String t(String de, String en) => widget.language == 'de' ? de : en;
  Widget button(
    String label,
    VoidCallback onTap, {
    NordicTone tone = NordicTone.ice,
    bool compact = false,
  }) => NordicButton(
    height: 44,
    fontSize: compact ? 13 : 14,
    radius: 22,
    padding: EdgeInsets.symmetric(horizontal: compact ? 3 : 8, vertical: 8),
    tone: tone,
    onPressed: widget.busy ? null : onTap,
    child: Text(label, textAlign: TextAlign.center),
  );
  Widget gap() => const SizedBox(height: 10);
  Widget heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
  );
  Widget back() =>
      button(t('Zurück', 'Back'), () => setState(() => page = 'home'));
  Widget stepper(String value, VoidCallback minus, VoidCallback plus) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            for (var i = 0; i < 3; i++)
              if (i == 1)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: 40,
                  child: NordicButton(
                    height: 44,
                    minWidth: 32,
                    fontSize: 20,
                    padding: EdgeInsets.zero,
                    radius: 16,
                    onPressed: i == 0 ? minus : plus,
                    child: Text(i == 0 ? '−' : '+'),
                  ),
                ),
          ],
        ),
      );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final diameter = math.min(box.maxWidth, box.maxHeight);
      final active = widget.data['active'] as Map?;
      final pulse = widget.data['watchPulse'] as Map?;
      final children = <Widget>[];
      if (active != null) {
        children.addAll([
          Text(
            active['kind'] == 'bath'
                ? t('Eisbad', 'Ice bath')
                : t('Dusche', 'Shower'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            durationLabel((active['durationMs'] as num? ?? 0).toInt()),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            active['bpm'] == null
                ? t('♥ Warte auf Puls', '♥ Waiting for pulse')
                : '♥ ${active['bpm']} bpm',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.1),
          ),
          const SizedBox(height: 9),
          Builder(
            builder: (context) => WearWaterLock.lockedOf(context)
                ? const SizedBox(height: 48)
                : button(
                    t('Beenden', 'Finish'),
                    widget.onStopCold,
                    tone: NordicTone.sun,
                  ),
          ),
          gap(),
          if (active['temperature'] != null)
            Text('${active['temperature']} °C', textAlign: TextAlign.center),
        ]);
      } else if (pulse != null) {
        children.addAll([
          heading(t('Atmen', 'Breathe')),
          Text(
            pulse['bpm'] == null ? '♥ —' : '♥ ${pulse['bpm']}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
          gap(),
          Text(
            pulse['waiting'] == true
                ? t('Bereit', 'Ready')
                : t('Training am Telefon', 'Training on phone'),
            textAlign: TextAlign.center,
          ),
          gap(),
          button(
            t('Beenden', 'Finish'),
            widget.onStopPulse,
            tone: NordicTone.sun,
          ),
        ]);
      } else if (page == 'time') {
        children.addAll([
          heading(t('Zielzeit', 'Target time')),
          stepper(
            seconds == 0 ? t('Ohne', 'None') : durationLabel(seconds * 1000),
            () => setState(() => seconds = math.max(0, seconds - 30)),
            () => setState(() => seconds = math.min(1800, seconds + 30)),
          ),
          button(
            t('Weiter', 'Next'),
            () => setState(() => page = 'temperature'),
            tone: NordicTone.sun,
          ),
          gap(),
          back(),
        ]);
      } else if (page == 'temperature') {
        children.addAll([
          heading(t('Temperatur', 'Temperature')),
          if (temperature == null) ...[
            button(
              t('Ohne Angabe', 'Skip temperature'),
              () => widget.onStartCold(kind, seconds, null),
              tone: NordicTone.sun,
            ),
            gap(),
            button(
              t('Einstellen', 'Set temperature'),
              () => setState(() => temperature = 5),
            ),
          ] else ...[
            stepper(
              '${temperature!.toStringAsFixed(0)} °C',
              () =>
                  setState(() => temperature = math.max(-2, temperature! - 1)),
              () =>
                  setState(() => temperature = math.min(40, temperature! + 1)),
            ),
            button(
              t('Starten', 'Start'),
              () => widget.onStartCold(kind, seconds, temperature),
              tone: NordicTone.sun,
            ),
          ],
          gap(),
          back(),
        ]);
      } else {
        children.addAll([
          heading('Easy Hof'),
          Row(
            children: [
              Expanded(
                child: button(
                  t('Dusche', 'Shower'),
                  () => setState(() {
                    kind = 'shower';
                    seconds = 180;
                    temperature = 5;
                    page = 'time';
                  }),
                  tone: NordicTone.sun,
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: button(
                  t('Eisbad', 'Ice bath'),
                  () => setState(() {
                    kind = 'bath';
                    seconds = 300;
                    temperature = 5;
                    page = 'time';
                  }),
                  compact: true,
                ),
              ),
            ],
          ),
          gap(),
          button(t('Atmen', 'Breathe'), widget.onStartPulse),
          gap(),
        ]);
      }
      if (widget.error != null) {
        children.add(Text(widget.error!, textAlign: TextAlign.center));
      }
      return Center(
        child: ClipOval(
          child: SizedBox.square(
            dimension: diameter,
            child: WearWaterLock(
              language: widget.language,
              activeId: active == null
                  ? null
                  : (active['id'] ?? active['kind']).toString(),
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                removeBottom: true,
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: WearScroll(
                    key: ValueKey('${active != null}-${pulse != null}-$page'),
                    padding: EdgeInsets.fromLTRB(
                      diameter * .17,
                      diameter * (active != null ? .14 : .19),
                      diameter * .17,
                      diameter * .23,
                    ),
                    children: children,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class WearConfirmation extends StatelessWidget {
  const WearConfirmation({
    super.key,
    required this.title,
    required this.message,
    required this.back,
    required this.accept,
  });
  final String title, message, back, accept;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final d = math.min(box.maxWidth, box.maxHeight);
      return Center(
        child: ClipOval(
          child: SizedBox.square(
            dimension: d,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  d * .17,
                  d * .16,
                  d * .17,
                  d * .17,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: NordicButton(
                            height: 32,
                            minWidth: 32,
                            radius: 12,
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(context, false),
                            child: Icon(
                              Icons.arrow_back,
                              size: 18,
                              semanticLabel: back,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: WearScroll(
                        children: [
                          Text(
                            message,
                            style: const TextStyle(fontSize: 12, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    NordicButton(
                      height: 44,
                      fontSize: 14,
                      tone: NordicTone.sun,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(accept),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
