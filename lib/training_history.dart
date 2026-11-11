import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'breathing.dart';
import 'nordic.dart';

DateTime? sessionDay(Map<String, dynamic> s) {
  final date = DateTime.tryParse(s['startedAt'] as String? ?? '')?.toLocal();
  return date == null ? null : DateTime(date.year, date.month, date.day);
}

int activeStreak(List<Map<String, dynamic>> sessions, DateTime now) {
  final days = sessions.map(sessionDay).whereType<DateTime>().toSet();
  var date = DateTime(now.year, now.month, now.day);
  if (!days.contains(date)) {
    date = DateTime(date.year, date.month, date.day - 1);
  }
  var count = 0;
  while (days.contains(date)) {
    count++;
    date = DateTime(date.year, date.month, date.day - 1);
  }
  return count;
}

Color trainingColor(String kind) => switch (kind) {
  'breathing' => sun,
  'bath' => const Color(0xFF6CA9EF),
  _ => const Color(0xFF58B6AC),
};
IconData trainingIcon(String kind) => switch (kind) {
  'breathing' => Icons.air_rounded,
  'bath' => Icons.ac_unit_rounded,
  _ => Icons.shower_rounded,
};
String trainingName(String kind, bool de) => switch (kind) {
  'breathing' => de ? 'Atmen' : 'Breathing',
  'bath' => de ? 'Eisbad' : 'Ice bath',
  _ => de ? 'Dusche' : 'Shower',
};

class TrainingHistory extends StatefulWidget {
  const TrainingHistory({
    super.key,
    required this.sessions,
    required this.language,
    required this.onDelete,
    this.manualButton,
  });
  final List<Map<String, dynamic>> sessions;
  final String language;
  final Future<bool> Function(Map<String, dynamic>) onDelete;
  final Widget? manualButton;
  @override
  State<TrainingHistory> createState() => _TrainingHistoryState();
}

class _TrainingHistoryState extends State<TrainingHistory> {
  late DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  bool get de => widget.language == 'de';
  String t(String a, String b) => de ? a : b;
  @override
  Widget build(BuildContext context) {
    final local = MaterialLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 260;
    final records = widget.sessions.where((s) {
      final d = sessionDay(s);
      return d != null && d.year == month.year && d.month == month.month;
    }).toList();
    final byDay = <int, List<Map<String, dynamic>>>{};
    for (final s in records) {
      byDay.putIfAbsent(sessionDay(s)!.day, () => []).add(s);
    }
    final firstIndex = local.firstDayOfWeekIndex;
    final offset = (month.weekday % 7 - firstIndex + 7) % 7;
    final count = DateUtils.getDaysInMonth(month.year, month.month);
    final today = DateTime.now();
    final streak = activeStreak(widget.sessions, today);
    Widget summary(String kind) {
      final items = records.where((s) => s['kind'] == kind).toList();
      final total = items.fold<int>(
        0,
        (sum, s) => sum + (s['durationMs'] as num? ?? 0).toInt(),
      );
      return NordicCard(
        padding: EdgeInsets.all(compact ? 6 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(trainingIcon(kind), color: trainingColor(kind), size: 22),
            const SizedBox(height: 6),
            Text(
              '${items.length}',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!compact)
              Text(
                trainingName(kind, de),
                style: const TextStyle(fontSize: 12),
              ),
            Text(durationLabel(total), style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact)
          Text(
            t('Deine Routine im Blick', 'Your rhythm at a glance'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        Text(
          compact
              ? t('$streak Tage in Folge', '$streak-day streak')
              : t(
                  '$streak aktive Tage in Folge',
                  '$streak active days in a row',
                ),
          style: compact ? const TextStyle(fontSize: 12) : null,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final kind in ['breathing', 'shower', 'bath'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: summary(kind),
                ),
              ),
          ],
        ),
        NordicCard(
          padding: EdgeInsets.all(compact ? 8 : 16),
          child: Column(
            children: [
              Row(
                children: [
                  NordicIconButton(
                    tooltip: t('Voriger Monat', 'Previous month'),
                    onPressed: () => setState(
                      () => month = DateTime(month.year, month.month - 1),
                    ),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      local.formatMonthYear(month),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: compact ? 12 : 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  NordicIconButton(
                    tooltip: t('Nächster Monat', 'Next month'),
                    onPressed: () => setState(
                      () => month = DateTime(month.year, month.month + 1),
                    ),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              Text(
                t(
                  '${records.length} Einheiten · ${byDay.length} aktive Tage',
                  '${records.length} sessions · ${byDay.length} active days',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.2,
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < 7; i++)
                          Expanded(
                            child: Text(
                              local.narrowWeekdays[(firstIndex + i) % 7],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (
                      var row = 0;
                      row < ((offset + count) / 7).ceil();
                      row++
                    )
                      Row(
                        children: [
                          for (var col = 0; col < 7; col++)
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final day = row * 7 + col - offset + 1;
                                  if (day < 1 || day > count) {
                                    return SizedBox(height: compact ? 38 : 50);
                                  }
                                  final sessions = byDay[day] ?? [];
                                  final date = DateTime(
                                    month.year,
                                    month.month,
                                    day,
                                  );
                                  final kinds = sessions
                                      .map((s) => s['kind'] as String)
                                      .toSet();
                                  final isToday = DateUtils.isSameDay(
                                    date,
                                    today,
                                  );
                                  return Semantics(
                                    label:
                                        '${local.formatFullDate(date)}, ${sessions.length} ${t('Einheiten', 'sessions')}',
                                    button: true,
                                    child: InkWell(
                                      key: ValueKey(
                                        'day-${date.year}-${date.month}-$day',
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => TrainingDay(
                                            date: date,
                                            sessions: sessions,
                                            language: widget.language,
                                            onDelete: widget.onDelete,
                                          ),
                                        ),
                                      ),
                                      child: Container(
                                        height: compact ? 38 : 50,
                                        margin: const EdgeInsets.all(1),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: nordicButtonColors(
                                              sessions.isEmpty
                                                  ? NordicTone.ice
                                                  : NordicTone.petrol,
                                            ),
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0xFF197F94),
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                          border: isToday
                                              ? Border.all(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  width: 1.5,
                                                )
                                              : null,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '$day',
                                              style: TextStyle(
                                                fontSize: compact ? 10 : 13,
                                                color: sessions.isEmpty
                                                    ? fjord
                                                    : Colors.white,
                                                fontWeight: sessions.isEmpty
                                                    ? FontWeight.w400
                                                    : FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                for (final kind in [
                                                  'breathing',
                                                  'shower',
                                                  'bath',
                                                ])
                                                  if (kinds.contains(kind))
                                                    Container(
                                                      width: compact ? 3 : 5,
                                                      height: compact ? 3 : 5,
                                                      margin:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 1,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: trainingColor(
                                                          kind,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  for (final kind in ['breathing', 'shower', 'bath'])
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trainingIcon(kind),
                          size: 14,
                          color: trainingColor(kind),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trainingName(kind, de),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                t(
                  'Tippe auf einen Tag für deine Einheiten.',
                  'Tap a day to see your sessions.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        if (widget.manualButton != null) ...[
          const SizedBox(height: 12),
          widget.manualButton!,
        ],
      ],
    );
  }
}

class TrainingDay extends StatefulWidget {
  const TrainingDay({
    super.key,
    required this.date,
    required this.sessions,
    required this.language,
    required this.onDelete,
  });
  final DateTime date;
  final List<Map<String, dynamic>> sessions;
  final String language;
  final Future<bool> Function(Map<String, dynamic>) onDelete;
  @override
  State<TrainingDay> createState() => _TrainingDayState();
}

class _TrainingDayState extends State<TrainingDay> {
  late final sessions = [...widget.sessions]
    ..sort(
      (a, b) => (b['startedAt'] as String).compareTo(a['startedAt'] as String),
    );
  bool busy = false;
  String? error;
  String t(String de, String en) => widget.language == 'de' ? de : en;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 260;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: compact ? 44 : 56,
        title: Text(
          MaterialLocalizations.of(context).formatShortDate(widget.date),
          style: TextStyle(fontSize: compact ? 15 : 20),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: EdgeInsets.all(compact ? 16 : 24),
              children: [
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (sessions.isEmpty)
                  NordicCard(
                    child: Text(
                      t(
                        'An diesem Tag keine Einheiten.',
                        'No sessions on this day.',
                      ),
                    ),
                  ),
                for (final s in sessions)
                  NordicCard(
                    padding: EdgeInsets.all(compact ? 12 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          trainingIcon(s['kind'] as String),
                          color: trainingColor(s['kind'] as String),
                        ),
                        Text(
                          trainingName(
                            s['kind'] as String,
                            widget.language == 'de',
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          MaterialLocalizations.of(context).formatTimeOfDay(
                            TimeOfDay.fromDateTime(
                              DateTime.parse(
                                s['startedAt'] as String,
                              ).toLocal(),
                            ),
                            alwaysUse24HourFormat:
                                MediaQuery.alwaysUse24HourFormatOf(context),
                          ),
                        ),
                        Text(
                          durationLabel((s['durationMs'] as num? ?? 0).toInt()),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (s['temperature'] != null)
                          Text('${s['temperature']} °C'),
                        if (s['manual'] == true)
                          Text(t('Manuell nachgetragen', 'Added manually')),
                        if (s['retentions'] is List)
                          Text(
                            '${t('Atemhalten', 'Breath holds')}: ${(s['retentions'] as List).map((v) => durationLabel((v as num).toInt())).join(' · ')}',
                          ),
                        if ((s['hrCount'] as num? ?? 0) > 0)
                          Text(
                            '♥ Ø ${(s['hrSum'] as num) ~/ (s['hrCount'] as num)} · ${s['hrMin']}–${s['hrMax']} bpm',
                          ),
                        if (s['kind'] != 'breathing')
                          HeartRateChart(session: s, language: widget.language),
                        if (s['interrupted'] == true)
                          Text(t('Vorzeitig beendet', 'Ended early')),
                        Text(
                          s['source'] == 'wear'
                              ? t('Von der Uhr', 'From watch')
                              : t('Vom Smartphone', 'From phone'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: NordicIconButton(
                            tooltip: t('Löschen', 'Delete'),
                            icon: const Icon(Icons.delete_outline),
                            onPressed: busy
                                ? null
                                : () async {
                                    setState(() {
                                      busy = true;
                                      error = null;
                                    });
                                    try {
                                      if (await widget.onDelete(s) && mounted) {
                                        setState(() => sessions.remove(s));
                                      }
                                    } catch (_) {
                                      if (mounted) {
                                        setState(
                                          () => error = t(
                                            'Löschen fehlgeschlagen.',
                                            'Could not delete.',
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted) setState(() => busy = false);
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeartRateChart extends StatefulWidget {
  const HeartRateChart({
    super.key,
    required this.session,
    required this.language,
  });
  final Map<String, dynamic> session;
  final String language;
  @override
  State<HeartRateChart> createState() => _HeartRateChartState();
}

class _HeartRateChartState extends State<HeartRateChart> {
  int? selected;
  @override
  Widget build(BuildContext context) {
    final points = (widget.session['hrSamples'] as List? ?? [])
        .whereType<List>()
        .where((p) => p.length == 2 && p[0] is num && p[1] is num)
        .map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList();
    final de = widget.language == 'de';
    final compact = MediaQuery.sizeOf(context).width < 260;
    if (points.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          de
              ? 'Keine Verlaufsmessung vorhanden.'
              : 'No heart-rate trace available.',
        ),
      );
    }
    final duration = math
        .max(
          (widget.session['durationMs'] as num? ?? 1).toDouble(),
          points.last.dx,
        )
        .clamp(1.0, double.infinity)
        .toDouble();
    final minBpm = points.map((p) => p.dy).reduce(math.min).floor() - 5;
    final maxBpm = points.map((p) => p.dy).reduce(math.max).ceil() + 5;
    final index = selected?.clamp(0, points.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          de ? 'Pulsverlauf' : (compact ? 'Pulse trace' : 'Heart-rate trace'),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: compact ? 12 : 16,
          ),
        ),
        Text(
          index == null
              ? (compact
                    ? '$minBpm–$maxBpm bpm'
                    : '$minBpm–$maxBpm bpm · ${de ? 'Skala' : 'scale'}')
              : '${durationLabel(points[index].dx.toInt())} · ${points[index].dy.round()} bpm',
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, box) => Semantics(
            label: de
                ? 'Pulsverlauf. Tippen für einzelne Messpunkte.'
                : 'Heart-rate trace. Tap to inspect readings.',
            child: GestureDetector(
              onTapDown: (tap) {
                final time = tap.localPosition.dx / box.maxWidth * duration;
                var nearest = 0;
                for (var i = 1; i < points.length; i++) {
                  if ((points[i].dx - time).abs() <
                      (points[nearest].dx - time).abs()) {
                    nearest = i;
                  }
                }
                setState(() => selected = nearest);
              },
              child: SizedBox(
                height: compact ? 80 : 130,
                width: double.infinity,
                child: CustomPaint(
                  painter: _HeartPainter(
                    points,
                    duration,
                    minBpm.toDouble(),
                    maxBpm.toDouble(),
                    Theme.of(context).colorScheme.primary,
                    index,
                  ),
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [const Text('0:00'), Text(durationLabel(duration.toInt()))],
        ),
        Text(
          de
              ? 'Zeit seit Beginn · Lücken ohne Messwerte'
              : 'Time from start · gaps have no readings',
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}

class _HeartPainter extends CustomPainter {
  _HeartPainter(
    this.points,
    this.duration,
    this.low,
    this.high,
    this.color,
    this.selected,
  );
  final List<Offset> points;
  final double duration, low, high;
  final Color color;
  final int? selected;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = color.withValues(alpha: .15)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    Offset place(Offset p) => Offset(
      (p.dx / duration * size.width).clamp(0, size.width).toDouble(),
      size.height - (p.dy - low) / (high - low) * size.height,
    );
    final line = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    var start = 0;
    for (var i = 1; i <= points.length; i++) {
      if (i == points.length || points[i].dx - points[i - 1].dx > 15000) {
        final path = Path()
          ..moveTo(place(points[start]).dx, place(points[start]).dy);
        for (var j = start + 1; j < i; j++) {
          final p = place(points[j]);
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, line);
        final fill = Path.from(path)
          ..lineTo(place(points[i - 1]).dx, size.height)
          ..lineTo(place(points[start]).dx, size.height)
          ..close();
        canvas.drawPath(
          fill,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: .25),
                color.withValues(alpha: .01),
              ],
            ).createShader(Offset.zero & size),
        );
        start = i;
      }
    }
    for (final index in {0, points.length - 1, ?selected}) {
      canvas.drawCircle(
        place(points[index]),
        selected == index ? 5 : 3,
        Paint()..color = color,
      );
    }
    if (selected != null) {
      final p = place(points[selected!]);
      canvas.drawLine(
        Offset(p.dx, 0),
        Offset(p.dx, size.height),
        Paint()
          ..color = color.withValues(alpha: .4)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_HeartPainter old) => true;
}
