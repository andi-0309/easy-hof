import 'dart:math';

import 'package:flutter/material.dart';

import 'platform.dart';
import 'nordic.dart';

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
  DateTime finished = DateTime.now();
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
    finished = DateTime(now.year, now.month, now.day, now.hour, now.minute);
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: finished.isAfter(now) ? now : finished,
      firstDate: DateTime(1970),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(
        () => finished = DateTime(
          picked.year,
          picked.month,
          picked.day,
          finished.hour,
          finished.minute,
        ),
      );
    }
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(finished),
    );
    if (picked != null && mounted) {
      setState(
        () => finished = DateTime(
          finished.year,
          finished.month,
          finished.day,
          picked.hour,
          picked.minute,
        ),
      );
    }
  }

  int get durationSeconds =>
      (int.tryParse(minutes.text) ?? 0) * 60 +
      (int.tryParse(seconds.text) ?? 0);

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    final end = finished;
    if (end.isAfter(DateTime.now())) {
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
    for (final c in [minutes, seconds, temperature]) {
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
                    Text(t('Beendet am', 'Finished on')),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('manual-date'),
                      onPressed: saving ? null : pickDate,
                      icon: const Icon(Icons.calendar_today_rounded),
                      label: Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(finished),
                      ),
                    ),
                    gap(),
                    Text(t('Uhrzeit', 'Time')),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('manual-time'),
                      onPressed: saving ? null : pickTime,
                      icon: const Icon(Icons.schedule_rounded),
                      label: Text(
                        MaterialLocalizations.of(context).formatTimeOfDay(
                          TimeOfDay.fromDateTime(finished),
                          alwaysUse24HourFormat:
                              MediaQuery.alwaysUse24HourFormatOf(context),
                        ),
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
                    SunButton(
                      onPressed: saving ? null : save,
                      icon: Icons.check_rounded,
                      label: saving
                          ? t('Speichern …', 'Saving …')
                          : t('Speichern', 'Save'),
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
