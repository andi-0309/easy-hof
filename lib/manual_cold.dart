import 'dart:math';

import 'package:flutter/material.dart';

import 'platform.dart';

/// A completed session uses the same durable storage and sync as timed sessions.
class ManualColdSession extends StatefulWidget {
  const ManualColdSession({
    super.key,
    required this.language,
    this.initialKind = 'shower',
  });
  final String language;
  final String initialKind;

  @override
  State<ManualColdSession> createState() => _ManualColdSessionState();
}

class _ManualColdSessionState extends State<ManualColdSession> {
  final form = GlobalKey<FormState>();
  final minutes = TextEditingController(text: '2');
  final seconds = TextEditingController(text: '0');
  final temperature = TextEditingController();
  late final TextEditingController date;
  late final TextEditingController time;
  late String kind;
  final id =
      'manual-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(0x100000000)}';
  bool saving = false;
  String? error;
  String t(String de, String en) => widget.language == 'de' ? de : en;

  @override
  void initState() {
    super.initState();
    kind = widget.initialKind;
    final now = DateTime.now();
    date = TextEditingController(text: dateText(now));
    time = TextEditingController(text: timeText(now));
  }

  String dateText(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String timeText(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  DateTime? finishedAt() {
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})$',
    ).firstMatch('${date.text.trim()} ${time.text.trim()}');
    if (match == null) return null;
    final parts = [for (var i = 1; i <= 5; i++) int.parse(match.group(i)!)];
    final d = DateTime(parts[0], parts[1], parts[2], parts[3], parts[4]);
    if (d.year < 1970 ||
        dateText(d) != date.text.trim() ||
        timeText(d) != time.text.trim()) {
      return null;
    }
    return d;
  }

  int get durationSeconds =>
      (int.tryParse(minutes.text) ?? 0) * 60 +
      (int.tryParse(seconds.text) ?? 0);

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    final end = finishedAt();
    if (end == null || end.isAfter(DateTime.now())) {
      setState(
        () => error = t(
          'Bitte einen gültigen Zeitpunkt in der Vergangenheit eingeben.',
          'Enter a valid date and time in the past.',
        ),
      );
      return;
    }
    if (durationSeconds <= 0 || durationSeconds > 86400) {
      setState(
        () => error = t(
          'Die Dauer muss zwischen 1 Sekunde und 24 Stunden liegen.',
          'Duration must be between 1 second and 24 hours.',
        ),
      );
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await Device.save({
        'id': id,
        'kind': kind,
        'manual': true,
        'startedAt': end
            .subtract(Duration(seconds: durationSeconds))
            .toUtc()
            .toIso8601String(),
        'durationMs': durationSeconds * 1000,
        if (temperature.text.trim().isNotEmpty)
          'temperature': double.parse(
            temperature.text.trim().replaceAll(',', '.'),
          ),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = t(
            'Speichern fehlgeschlagen. Bitte erneut versuchen.',
            'Could not save. Please try again.',
          );
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in [minutes, seconds, temperature, date, time]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 300;
    Widget gap() => const SizedBox(height: 16);
    Widget numberField(
      TextEditingController controller,
      String label,
      int max,
    ) => TextFormField(
      key: ValueKey(label),
      controller: controller,
      enabled: !saving,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final n = int.tryParse(value ?? '');
        return n == null || n < 0 || n > max
            ? t('Zahl von 0 bis $max', 'Number from 0 to $max')
            : null;
      },
    );
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            t('Nachtragen', 'Add entry'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          automaticallyImplyLeading: !saving,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  children: [
                    Text(
                      t(
                        'Dusche oder Eisbad nachträglich erfassen.',
                        'Log a completed shower or ice bath.',
                      ),
                    ),
                    gap(),
                    DropdownButtonFormField<String>(
                      initialValue: kind,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: t('Training', 'Training'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'shower',
                          child: Text(t('Dusche', 'Shower')),
                        ),
                        DropdownMenuItem(
                          value: 'bath',
                          child: Text(t('Eisbad', 'Ice bath')),
                        ),
                      ],
                      onChanged: saving
                          ? null
                          : (value) => setState(() => kind = value!),
                    ),
                    gap(),
                    TextFormField(
                      key: const Key('manual-date'),
                      controller: date,
                      keyboardType: TextInputType.datetime,
                      enabled: !saving,
                      decoration: InputDecoration(
                        labelText: t('Beendet am', 'Finished on'),
                        helperText: t('JJJJ-MM-TT', 'YYYY-MM-DD'),
                        suffixIcon: compact
                            ? null
                            : IconButton(
                                tooltip: t('Datum auswählen', 'Choose date'),
                                icon: const Icon(Icons.calendar_today_outlined),
                                onPressed: saving
                                    ? null
                                    : () async {
                                        final now = DateTime.now();
                                        final selected = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              finishedAt() != null &&
                                                  !finishedAt()!.isAfter(now)
                                              ? finishedAt()!
                                              : now,
                                          firstDate: DateTime(1970),
                                          lastDate: now,
                                        );
                                        if (selected != null) {
                                          date.text = dateText(selected);
                                        }
                                      },
                              ),
                      ),
                      validator: (_) => finishedAt() == null
                          ? t(
                              'Gültiges Datum und Uhrzeit eingeben.',
                              'Enter a valid date and time.',
                            )
                          : null,
                    ),
                    gap(),
                    TextFormField(
                      key: const Key('manual-time'),
                      controller: time,
                      enabled: !saving,
                      keyboardType: TextInputType.datetime,
                      decoration: InputDecoration(
                        labelText: t('Uhrzeit', 'Time'),
                        helperText: 'HH:mm',
                      ),
                    ),
                    gap(),
                    if (compact) ...[
                      numberField(minutes, t('Minuten', 'Minutes'), 1440),
                      gap(),
                      numberField(seconds, t('Sekunden', 'Seconds'), 59),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: numberField(
                              minutes,
                              t('Minuten', 'Minutes'),
                              1440,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: numberField(
                              seconds,
                              t('Sekunden', 'Seconds'),
                              59,
                            ),
                          ),
                        ],
                      ),
                    gap(),
                    TextFormField(
                      key: const Key('manual-temperature'),
                      controller: temperature,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: InputDecoration(
                        labelText: t(
                          'Temperatur (optional)',
                          'Temperature (optional)',
                        ),
                        suffixText: '°C',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final n = double.tryParse(
                          value.trim().replaceAll(',', '.'),
                        );
                        return n == null || !n.isFinite || n < -2 || n > 40
                            ? t(
                                'Temperatur von −2 bis 40 °C',
                                'Temperature from −2 to 40 °C',
                              )
                            : null;
                      },
                    ),
                    gap(),
                    Text(
                      t(
                        'Manuelle Einträge enthalten keine Pulsmessung und werden mit deinen Geräten synchronisiert.',
                        'Manual entries have no heart-rate readings and sync with your devices.',
                      ),
                    ),
                    if (error != null) ...[
                      gap(),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    gap(),
                    FilledButton.icon(
                      onPressed: saving ? null : save,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        saving
                            ? t('Speichern …', 'Saving …')
                            : t('Speichern', 'Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
