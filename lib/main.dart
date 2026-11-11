import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'breathing.dart';
import 'breathing_view.dart';
import 'platform.dart';
import 'nordic.dart';
import 'privacy_policy.dart';
import 'manual_cold.dart';
import 'training_history.dart';
import 'wear_companion.dart';

const isWear = bool.fromEnvironment('WEAR');
void main() => runApp(const EasyHof());

class EasyHof extends StatefulWidget {
  const EasyHof({super.key, this.elapsedMs});
  final int Function()? elapsedMs;
  @override
  State<EasyHof> createState() => _EasyHofState();
}

class _EasyHofState extends State<EasyHof> with WidgetsBindingObserver {
  late BuildContext dialogContext;
  String language =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'de'
      ? 'de'
      : 'en';
  bool voice = true;
  bool haptics = true;
  int rounds = 3, breaths = 30, pace = 6, tab = isWear ? 1 : 0;
  int goal = 180;
  String coldType = 'shower';
  double temperature = 5;
  bool temperatureKnown = true;
  bool busy = false, loaded = false;
  String? error;
  Map<String, dynamic> data = {};
  BreathingSession? breathing;
  Timer? timer;
  final Stopwatch clock = Stopwatch();
  int get elapsed => widget.elapsedMs?.call() ?? clock.elapsedMilliseconds;
  int lastTick = 0;
  bool completing = false;
  String? lastCue;
  String? breathingId;
  int pulseTicks = 0;
  final landscape = ValueNotifier<double>(0);
  Map<String, dynamic>? pendingBreathing;
  final started = <String, String>{};
  String t(String de, String en) => language == 'de' ? de : en;
  Map<String, dynamic>? get cold => data['active'] is Map
      ? Map<String, dynamic>.from(data['active'] as Map)
      : null;
  List<Map<String, dynamic>> get history => (data['sessions'] as List? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    init();
    clock.start();
    timer = Timer.periodic(const Duration(milliseconds: 200), (_) => tick());
  }

  Future<void> init() async {
    try {
      final raw = await Device.call<String>('settings');
      if (raw != null && raw.isNotEmpty) {
        final s = jsonDecode(raw) as Map;
        language = s['language'] == 'en' ? 'en' : 'de';
        voice = s['voice'] != false;
        haptics = s['haptics'] != false;
        rounds = (s['rounds'] as num? ?? 3).toInt().clamp(1, 10);
        breaths = (s['breaths'] as num? ?? 30).toInt().clamp(10, 60);
        pace = (s['pace'] as num? ?? 6).toInt().clamp(4, 8);
      }
      await refresh();
    } catch (_) {
      error = t('Daten konnten nicht geladen werden.', 'Could not load data.');
    }
    if (mounted) setState(() => loaded = true);
  }

  Future<void> settings() async {
    try {
      await Device.call('settings', {
        'json': jsonEncode({
          'language': language,
          'voice': voice,
          'haptics': haptics,
          'rounds': rounds,
          'breaths': breaths,
          'pace': pace,
        }),
      });
    } catch (_) {
      showError(
        t(
          'Einstellungen konnten nicht gespeichert werden.',
          'Could not save settings.',
        ),
      );
    }
  }

  Future<void> refresh() async {
    final next = await Device.snapshot();
    if (mounted) {
      setState(() {
        data = next;
        if (isWear && next['companionSettings'] is Map) {
          final value = next['companionSettings']['language'];
          if (value == 'de' || value == 'en') language = value as String;
        }
      });
    }
  }

  int refreshTicks = 0;
  bool refreshing = false;
  void tick() {
    final now = elapsed;
    final delta = now - lastTick;
    lastTick = now;
    final b = breathing;
    if (b != null && !b.paused && b.phase != BreathPhase.done) {
      // A stalled UI must never silently skip breathing instructions.
      if (delta > 1500) {
        b.paused = true;
        Device.call('stopSpeech');
      } else {
        b.advance(delta);
        cue();
      }
      if (mounted) setState(() {});
      if (b.phase == BreathPhase.done && !completing) finishBreathing();
    }
    if (b != null) {
      final limit = b.phaseLimit ?? 1;
      final progress = (b.phaseMs / limit).clamp(0.0, 1.0);
      landscape.value = switch (b.phase) {
        BreathPhase.inhale => progress,
        BreathPhase.exhale => 1 - progress,
        BreathPhase.recovery => 1,
        _ => 0,
      };
      if (++pulseTicks % 5 == 0) sendBreathingPulse();
    } else {
      landscape.value = 0;
    }
    if (++refreshTicks % 5 == 0 && !refreshing) {
      refreshing = true;
      refresh()
          .catchError((Object _) {})
          .whenComplete(() => refreshing = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && breathing != null) {
      breathing!.paused = true;
      sendBreathingPulse();
      Device.call('stopSpeech');
      if (mounted) setState(() {});
    }
    if (state == AppLifecycleState.resumed) {
      lastTick = elapsed;
      refresh();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    clock.stop();
    WidgetsBinding.instance.removeObserver(this);
    landscape.dispose();
    super.dispose();
  }

  void showError(String message) {
    if (mounted) setState(() => error = message);
  }

  Future<void> action(Future<void> Function() fn) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await fn();
    } on PlatformException catch (e) {
      showError(e.message ?? t('Aktion fehlgeschlagen.', 'Action failed.'));
    } catch (_) {
      showError(
        t(
          'Aktion fehlgeschlagen. Bitte erneut versuchen.',
          'Action failed. Please try again.',
        ),
      );
    }
    if (mounted) setState(() => busy = false);
  }

  Future<bool> confirm(String title, String message, {String? accept}) async =>
      await showDialog<bool>(
        context: dialogContext,
        builder: (context) => isWear
            ? WearConfirmation(
                title: title,
                message: message,
                back: t('Zurück', 'Back'),
                accept: accept ?? t('Verstanden', 'Understood'),
              )
            : AlertDialog(
                title: Text(title),
                content: SingleChildScrollView(child: Text(message)),
                actions: [
                  NordicButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(t('Zurück', 'Back')),
                  ),
                  NordicButton(
                    tone: NordicTone.sun,
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(accept ?? t('Verstanden', 'Understood')),
                  ),
                ],
              ),
      ) ??
      false;

  Future<void> startBreathing() async {
    if (cold != null) {
      showError(
        t('Beende zuerst das Kältetraining.', 'Finish cold training first.'),
      );
      return;
    }
    if (!await confirm(
      t('Sicher atmen', 'Breathe safely'),
      t(
        'Nur im Sitzen oder Liegen an einem sicheren, trockenen Ort. Nie im Wasser, in der Dusche oder beim Fahren. Ohnmacht ist möglich. Nicht erzwingen; bei Unwohlsein abbrechen. Bei Schwangerschaft, Epilepsie oder Herz-/Kreislauferkrankungen vorher ärztlich abklären.',
        'Sit or lie down in a safe, dry place. Never in water, in the shower or while driving. Fainting is possible. Do not force it; stop if unwell. Seek medical advice first if pregnant or if you have epilepsy or a cardiovascular condition.',
      ),
    )) {
      return;
    }
    breathingId =
        'breath-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(0x100000000)}';
    final b = BreathingSession(
      rounds: rounds,
      breaths: breaths,
      cycleSeconds: pace,
    )..start();
    started['breathing'] = DateTime.now().toUtc().toIso8601String();
    lastTick = elapsed;
    lastCue = null;
    completing = false;
    await Device.call('keepScreen', {'enabled': true});
    setState(() => breathing = b);
    sendBreathingPulse();
    cue();
  }

  void cue() {
    final b = breathing;
    if (b == null || b.paused) return;
    final key = '${b.phase}-${b.round}-${b.breath}';
    if (lastCue == key) return;
    lastCue = key;
    if (voice && b.phase != BreathPhase.ready) {
      Device.playCue(
        b.isFinalExhale ? 'final_exhale' : b.phase.name,
        language,
        seconds:
            (b.phase == BreathPhase.inhale || b.phase == BreathPhase.exhale)
            ? pace ~/ 2
            : null,
      ).catchError((Object _) {
        if (mounted) {
          setState(() {
            voice = false;
            error = t(
              'Audio konnte nicht abgespielt werden. Die Übung läuft ohne Sprache weiter.',
              'Audio could not be played. The session continues without speech.',
            );
          });
        }
      });
    }
    if (haptics &&
        (b.phase == BreathPhase.retention || b.phase == BreathPhase.done)) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> finishBreathing({bool interrupted = false}) async {
    if (completing) return;
    completing = true;
    final b = breathing!;
    await Device.call('keepScreen', {'enabled': false});
    if (interrupted) await Device.call('stopSpeech');
    pendingBreathing = {
      'id': breathingId,
      'kind': 'breathing',
      'startedAt': started['breathing'],
      'durationMs': b.totalMs,
      'retentions': b.retentions,
      'rounds': b.rounds,
      'breaths': b.breaths,
      'cycleSeconds': b.cycleSeconds,
      'interrupted': interrupted,
    };
    await sendBreathingPulse(ended: true);
    await saveBreathing();
  }

  Future<void> sendBreathingPulse({bool ended = false}) async {
    final b = breathing;
    if (isWear || b == null || breathingId == null) return;
    try {
      await Device.call('breathingPulse', {
        'json': jsonEncode({
          'id': breathingId,
          'startedAt': started['breathing'],
          'elapsedMs': b.totalMs,
          'paused': b.paused,
          'ended': ended || completing,
          'language': language,
          'sentAt': DateTime.now().millisecondsSinceEpoch,
        }),
      });
    } catch (_) {
      /* Optional pulse never blocks the breathing exercise. */
    }
  }

  Future<void> saveBreathing() async {
    try {
      await Device.save(pendingBreathing!);
      await refresh();
      pendingBreathing = null;
      if (mounted) {
        setState(() {
          breathing = null;
          tab = 2;
          completing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          breathing!.paused = true;
          error = t(
            'Speichern fehlgeschlagen. Bitte erneut speichern.',
            'Save failed. Please retry.',
          );
        });
      }
    }
  }

  Future<void> addManualCold() async {
    if (isWear) return;
    final saved = await Navigator.of(dialogContext).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ManualColdSession(language: language, initialKind: coldType),
      ),
    );
    if (saved == true && mounted) {
      await refresh();
      setState(() => tab = 2);
    }
  }

  Widget manualColdButton() => NordicButton.icon(
    onPressed: busy ? null : () => action(addManualCold),
    icon: const Icon(Icons.add_rounded),
    label: Text(t('Manuell nachtragen', 'Add manually')),
  );

  Future<void> startCold() async {
    if (!isWear &&
        !await confirm(
          t('Kältetraining', 'Cold training'),
          t(
                'Im Wasser normal weiteratmen — keine Atemhalteübungen. Eisbad nicht allein. Beende die Einheit bei Unwohlsein. Die Zielzeit ist optional, keine Empfehlung. Pulswerte können bei Kälte ungenau sein und sind kein Sicherheitssignal.',
                'Breathe normally in water — no breath holds. Do not ice bathe alone. Stop if unwell. A target time is optional, not a recommendation. Heart rate can be inaccurate in cold conditions and is not a safety indicator.',
              ) +
              (isWear
                  ? t(
                      '\n\nOptionaler Pulszugriff: Mit deiner Freigabe zeigt Easy Hof während dieser Sitzung deinen Puls an. Pulsverlauf, Durchschnitt, Minimum und Maximum werden auf der Uhr gespeichert und über Google Play-Dienste mit deinem gekoppelten Smartphone synchronisiert. Du kannst die Sensorberechtigung ablehnen; der Timer bleibt ohne Pulswerte nutzbar.',
                      '\n\nOptional heart rate: With your permission, Easy Hof displays your heart rate during this session. Heart-rate trace, average, minimum and maximum are stored on the watch and synchronized with your paired phone through Google Play services. You can decline sensor permission and continue using the timer without heart-rate values.',
                    )
                  : ''),
        )) {
      return;
    }
    bool hr = false;
    if (isWear) hr = await Device.call<bool>('requestHeartRate') ?? false;
    await Device.call<bool>('requestNotifications');
    await Device.call('startCold', {
      'kind': coldType,
      'temperature': temperatureKnown ? temperature : null,
      'goalSeconds': goal,
      'heartRate': hr,
      'language': language,
    });
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Easy Hof',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: {
        ...WidgetsBinding.instance.platformDispatcher.locales.where(
          GlobalMaterialLocalizations.delegate.isSupported,
        ),
        const Locale('de'),
        const Locale('en'),
      }.toList(),
      builder: (context, child) =>
          NordicBackdrop(breath: landscape, child: child!),
      theme: nordicTheme(Brightness.light, wear: isWear),
      darkTheme: nordicTheme(Brightness.dark, wear: isWear),
      themeMode: isWear ? ThemeMode.dark : ThemeMode.system,
      home: Builder(
        builder: (innerContext) {
          // Dialogs need a context below MaterialApp.
          return _HomeScope(owner: this);
        },
      ),
    );
  }

  Widget content(BuildContext context) {
    if (!loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (breathing != null) return breathingView(context);
    if (isWear) {
      return WearCompanion(
        data: data,
        language: language,
        busy: busy,
        error: error,
        onStartCold: (kind, seconds, temp) => action(() async {
          coldType = kind;
          goal = seconds;
          temperatureKnown = temp != null;
          temperature = temp ?? 5;
          await startCold();
        }),
        onStopCold: () => action(() async {
          await Device.call('stopCold');
          await refresh();
        }),
        onStartPulse: () => action(() async {
          final allowed = await Device.call<bool>('requestHeartRate') ?? false;
          await Device.call<bool>('requestNotifications');
          if (allowed) {
            await Device.call('startBreathingPulse');
          } else {
            showError(
              t(
                'Pulszugriff nicht freigegeben.',
                'Heart-rate access was not granted.',
              ),
            );
          }
          await refresh();
        }),
        onStopPulse: () => action(() async {
          await Device.call('stopBreathingPulse');
          await refresh();
        }),
      );
    }
    final title = [
      t('Atmen', 'Breathe'),
      t('Kälte', 'Cold'),
      t('Verlauf', 'History'),
      t('Einstellungen', 'Settings'),
    ][tab];
    final body = switch (tab) {
      0 => breathingSetup(),
      1 => coldView(),
      2 => historyView(),
      _ => settingsView(),
    };
    return Scaffold(
      appBar: isWear
          ? null
          : NordicAppBar(
              title: const Text('Easy Hof'),
              actions: [
                NordicIconButton(
                  tooltip: t('Einstellungen', 'Settings'),
                  onPressed: () => setState(() => tab = 3),
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: nordicPageWidth),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                isWear ? 18 : 24,
                isWear ? 18 : 16,
                isWear ? 18 : 24,
                isWear ? 40 : 24,
              ),
              children: [
                if (isWear)
                  Row(
                    children: [
                      NordicIconButton(
                        tooltip: t('Kälte', 'Cold'),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => tab = 1),
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      NordicIconButton(
                        tooltip: tab == 2
                            ? t('Einstellungen', 'Settings')
                            : t('Verlauf', 'History'),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => tab = tab == 2 ? 3 : 2),
                        icon: Icon(
                          tab == 2 ? Icons.settings : Icons.history,
                          size: 20,
                        ),
                      ),
                    ],
                  )
                else
                  Text(title, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                if (error != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(error!),
                          NordicButton(
                            onPressed: () => setState(() => error = null),
                            child: Text(t('Schließen', 'Dismiss')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ...body,
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: isWear
          ? null
          : NordicNavigationBar(
              selectedIndex: tab == 3 ? 0 : tab,
              onDestinationSelected: (i) => setState(() => tab = i),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.air_rounded),
                  label: t('Atmen', 'Breathe'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.ac_unit_rounded),
                  label: t('Kälte', 'Cold'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.insights_rounded),
                  label: t('Verlauf', 'History'),
                ),
              ],
            ),
    );
  }

  Widget panel(List<Widget> children) => NordicCard(
    padding: EdgeInsets.all(isWear ? 10 : 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
  Widget space() => const SizedBox(height: 16);
  Widget numberControl(
    String label,
    int value,
    int min,
    int max,
    void Function(int) change, {
    int step = 1,
    String? display,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          NordicIconButton(
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            tooltip: t('Weniger', 'Less'),
            onPressed: value > min
                ? () => change((value - step).clamp(min, max))
                : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Flexible(
            child: Text(
              display ?? '$value',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          NordicIconButton(
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            tooltip: t('Mehr', 'More'),
            onPressed: value < max
                ? () => change((value + step).clamp(min, max))
                : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    ],
  );

  List<Widget> breathingSetup() => [
    Text(
      t('Ein ruhiger Moment. Nur für dich.', 'A quiet moment. Just for you.'),
    ),
    panel([
      Text(
        t('Dein Atemrhythmus', 'Your breathing rhythm'),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
      space(),
      numberControl(t('Runden', 'Rounds'), rounds, 1, 10, (v) {
        setState(() => rounds = v);
        settings();
      }),
      numberControl(
        t('Atemzüge pro Runde', 'Breaths per round'),
        breaths,
        10,
        60,
        (v) {
          setState(() => breaths = v);
          settings();
        },
        step: 5,
      ),
      numberControl(
        t('Tempo pro Atemzug', 'Time per breath'),
        pace,
        4,
        8,
        (v) {
          setState(() => pace = v);
          settings();
        },
        step: 2,
        display: '$pace s',
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(t('Sprachführung', 'Voice guidance')),
        subtitle: Text(
          t(
            'Atemgeräusche & deutsche Ansagen',
            'Breath sounds & English guidance',
          ),
        ),
        value: voice,
        onChanged: (v) {
          setState(() => voice = v);
          settings();
        },
      ),
      space(),
      SunButton(
        onPressed: busy || cold != null ? null : () => action(startBreathing),
        label: t('Atmen starten', 'Start breathing'),
      ),
    ]),
    Text(
      t(
        'Atemhaltezeit ohne Zielvorgabe. Du entscheidest, wann du wieder atmest.',
        'No breath-hold target. You decide when to breathe again.',
      ),
    ),
    if (cold != null)
      Text(
        t(
          'Ein Kältetraining läuft. Beende es vor der Atemübung.',
          'Cold training is running. Finish it before breathing.',
        ),
      ),
  ];

  List<Widget> coldView() {
    final a = cold;
    if (a != null) {
      final elapsed = (a['durationMs'] as num? ?? 0).toInt();
      final bpm = a['bpm'];
      return [
        panel([
          Text(
            a['kind'] == 'bath'
                ? t('Eisbad läuft', 'Ice bath running')
                : t('Dusche läuft', 'Shower running'),
          ),
          space(),
          Center(
            child: Text(
              durationLabel(elapsed),
              style: TextStyle(
                fontSize: isWear ? 38 : 64,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (a['temperature'] != null)
            Center(child: Text('${a['temperature']} °C')),
          space(),
          if (isWear)
            Center(
              child: Text(
                bpm == null
                    ? t('♥ Kein Messwert', '♥ No reading')
                    : '♥ ${(bpm as num).round()} bpm',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          if (isWear && a['hrStatus'] != null)
            Text(
              hrStatus(a['hrStatus'].toString()),
              textAlign: TextAlign.center,
            ),
          if ((a['goalSeconds'] as num? ?? 0) > 0)
            Text(
              '${t('Ziel', 'Target')}: ${durationLabel((a['goalSeconds'] as num).toInt() * 1000)}${a['goalReached'] == true ? ' ✓' : ''}',
              textAlign: TextAlign.center,
            ),
          space(),
          NordicButton.icon(
            onPressed: busy
                ? null
                : () => action(() async {
                    await Device.call('stopCold');
                    await refresh();
                    setState(() => tab = 2);
                  }),
            icon: const Icon(Icons.stop_rounded),
            label: Text(t('Beenden', 'Finish')),
          ),
          Text(
            t('Normal weiteratmen.', 'Keep breathing normally.'),
            textAlign: TextAlign.center,
          ),
        ]),
      ];
    }
    return [
      Text(
        t(
          'Dusche oder Eisbad. In deinem Tempo.',
          'Shower or ice bath. At your pace.',
        ),
      ),
      panel([
        if (isWear)
          NordicDropdown<String>(
            height: 48,
            isExpanded: true,
            value: coldType,
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
            onChanged: (v) => setState(() => coldType = v!),
          )
        else
          NordicSegmented<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: 'shower',
                label: Text(t('Dusche', 'Shower')),
              ),
              ButtonSegment(
                value: 'bath',
                label: Text(t('Eisbad', 'Ice bath')),
              ),
            ],
            selected: {coldType},
            onSelectionChanged: (s) => setState(() {
              coldType = s.first;
              goal = coldType == 'bath' ? 300 : 180;
              temperature = 5;
            }),
          ),
        space(),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t('Temperatur', 'Temperature')),
          subtitle: Text(t('Manuell gemessen', 'Measured manually')),
          value: temperatureKnown,
          onChanged: (v) => setState(() => temperatureKnown = v),
        ),
        if (temperatureKnown)
          numberControl(
            '°C',
            temperature.round(),
            -2,
            40,
            (v) => setState(() => temperature = v.toDouble()),
            display: '${temperature.toStringAsFixed(0)} °C',
          ),
        numberControl(
          t('Optionale Zielzeit', 'Optional target time'),
          goal,
          0,
          1800,
          (v) => setState(() => goal = v),
          step: 30,
          display: goal == 0 ? t('Ohne', 'None') : durationLabel(goal * 1000),
        ),
        space(),
        SunButton(
          onPressed: busy ? null : () => action(startCold),
          label: t('Starten', 'Start'),
        ),
        space(),
        if (!isWear) manualColdButton(),
      ]),
      Text(
        isWear
            ? t(
                'Puls wird bei erteilter Berechtigung erfasst. Spätere Synchronisierung mit deinem Smartphone.',
                'Heart rate is recorded with permission. Syncs with your phone later.',
              )
            : t(
                'Deine Uhr unterstützt dich beim Aufzeichnen und synchronisiert mit diesem Verlauf.',
                'Your watch helps record training and syncs to this history.',
              ),
      ),
    ];
  }

  String hrStatus(String status) => switch (status) {
    'denied' => t('Pulszugriff nicht erlaubt', 'Heart rate access not granted'),
    'unavailable' => t('Kein Pulssensor verfügbar', 'No heart rate sensor'),
    'waiting' => t('Warte auf Sensor …', 'Waiting for sensor …'),
    'unreliable' => t('Kein zuverlässiges Signal', 'No reliable signal'),
    'stale' => t('Warte auf aktuellen Messwert', 'Waiting for fresh reading'),
    _ => '',
  };

  List<Widget> historyView() => [
    TrainingHistory(
      sessions: history,
      language: language,
      manualButton: isWear ? null : manualColdButton(),
      onDelete: (session) async {
        if (!await confirm(
          t('Einheit löschen?', 'Delete session?'),
          t(
            'Wird beim nächsten Sync auch auf dem anderen Gerät gelöscht.',
            'Will also be deleted on your other device after syncing.',
          ),
          accept: t('Löschen', 'Delete'),
        )) {
          return false;
        }
        await Device.call('deleteSession', {'id': session['id']});
        await refresh();
        return true;
      },
    ),
  ];

  String dateLabel(String? iso) {
    final d = DateTime.tryParse(iso ?? '')?.toLocal();
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  List<Widget> settingsView() => [
    if (!isWear)
      panel([
        const Icon(Icons.watch_rounded, size: 32),
        space(),
        Text(
          t('Easy Hof auf deiner Uhr', 'Easy Hof on your watch'),
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        space(),
        Text(
          t(
            'Öffne Google Play und wähle deine Uhr unter „Auf weiteren Geräten installieren“. Verwende auf beiden Geräten dasselbe Google-Konto.',
            'Open Google Play and select your watch under “Install on more devices”. Use the same Google account on both devices.',
          ),
        ),
        space(),
        SunButton(
          icon: Icons.download_rounded,
          label: t('Uhr-App installieren', 'Install watch app'),
          onPressed: () => action(() async {
            await Device.call('openWatchStore');
          }),
        ),
      ]),
    panel([
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(t('Vibration', 'Haptics')),
        value: haptics,
        onChanged: (value) {
          setState(() => haptics = value);
          settings();
        },
      ),
      Text(
        t('Sprache & Stimme', 'Language & voice'),
        style: const TextStyle(fontSize: 20),
      ),
      space(),
      NordicSegmented<String>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: 'de', label: Text('DE')),
          ButtonSegment(value: 'en', label: Text('EN')),
        ],
        selected: {language},
        onSelectionChanged: (v) {
          setState(() => language = v.first);
          settings();
        },
      ),
      NordicButton.icon(
        onPressed: () => action(() async {
          await Device.playCue('welcome', language);
        }),
        icon: const Icon(Icons.volume_up_outlined),
        label: Text(t('Stimme testen', 'Test voice')),
      ),
      Text(
        t(
          'Die Ansagen sind fest in der App enthalten. Keine Systemstimme und kein Download nötig.',
          'Voice clips are included in the app. No system voice or download needed.',
        ),
      ),
    ]),
    panel([
      Text(
        t('Smartphone & Uhr', 'Phone & watch'),
        style: const TextStyle(fontSize: 20),
      ),
      space(),
      Text(
        t(
          'Beide Apps auf gekoppelten Geräten installieren. Einheiten werden automatisch übertragen, wenn eine Verbindung besteht. Kein Easy-Hof-Konto, kein eigener Server.',
          'Install both apps on paired devices. Sessions transfer automatically when connected. No Easy Hof account or backend.',
        ),
      ),
      space(),
      Text(syncLabel()),
      if (data['lastReceived'] != null)
        Text(
          '${t('Zuletzt empfangen', 'Last received')}: ${dateLabel(data['lastReceived'] as String)}',
        ),
      NordicButton.icon(
        onPressed: busy
            ? null
            : () => action(() async {
                await Device.call('sync');
                await refresh();
              }),
        icon: const Icon(Icons.sync),
        label: Text(t('Synchronisieren', 'Sync now')),
      ),
    ]),
    if (!isWear)
      panel([
        Text(
          t('Lokales Backup', 'Local backup'),
          style: const TextStyle(fontSize: 20),
        ),
        space(),
        Text(
          t(
            'Verlauf als JSON-Datei sichern oder wiederherstellen. Gleiche Einheiten werden nicht doppelt importiert.',
            'Save or restore history as a JSON file. Existing sessions are not duplicated.',
          ),
        ),
        NordicButton.icon(
          onPressed: busy
              ? null
              : () => action(() async {
                  await Device.call('exportBackup');
                }),
          icon: const Icon(Icons.file_download_outlined),
          label: Text(t('Exportieren', 'Export')),
        ),
        NordicButton.icon(
          onPressed: busy
              ? null
              : () => action(() async {
                  await Device.call('importBackup');
                  await refresh();
                }),
          icon: const Icon(Icons.file_upload_outlined),
          label: Text(t('Importieren', 'Import')),
        ),
      ]),
    panel([
      Text(
        t('Privat. Übersichtlich. Easy Hof.', 'Private. Simple. Easy Hof.'),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      space(),
      Text(
        t(
          'Trainingsdaten werden lokal gespeichert. Keine Werbung, keine Analyse-Dienste. Temperatur wird manuell eingegeben; Puls benötigt eine kompatible Uhr. Keine medizinische Anwendung und keine offizielle Wim-Hof-App.',
          'Training data is stored locally. No ads or analytics. Temperature is entered manually; heart rate needs a compatible watch. Not a medical app or an official Wim Hof app.',
        ),
      ),
      const SizedBox(height: 8),
      NordicButton.icon(
        icon: const Icon(Icons.privacy_tip_outlined),
        label: Text(t('Datenschutz', 'Privacy policy')),
        onPressed: () => Navigator.of(dialogContext).push(
          MaterialPageRoute<void>(
            builder: (_) => PrivacyPolicy(language: language),
          ),
        ),
      ),
      const Text('Version 1.3.1'),
    ]),
  ];

  String syncLabel() => switch (data['syncStatus']) {
    'queued' => t('Übertragung vorgemerkt', 'Transfer queued'),
    'received' => t('Daten empfangen', 'Data received'),
    'unavailable' => t(
      'Verbindung nicht verfügbar. Daten bleiben lokal.',
      'Connection unavailable. Data stays local.',
    ),
    _ => t('Bereit für Geräte-Sync', 'Ready for device sync'),
  };

  Widget breathingView(BuildContext context) => BreathingPage(
    session: breathing!,
    language: language,
    voice: voice,
    error: error,
    pendingSave: pendingBreathing != null,
    heartRate:
        data['breathingPulse'] is Map &&
            data['breathingPulse']['id'] == breathingId
        ? Map<String, dynamic>.from(data['breathingPulse'] as Map)
        : null,
    onToggleVoice: () => action(() async {
      setState(() => voice = !voice);
      if (!voice) {
        await Device.call('stopSpeech');
      } else {
        lastCue = null;
        cue();
      }
      await settings();
    }),
    onTogglePause: () {
      setState(() {
        breathing!.paused = !breathing!.paused;
        lastTick = elapsed;
      });
      sendBreathingPulse();
      if (breathing!.paused) {
        Device.call('stopSpeech');
      } else {
        lastCue = null;
        cue();
      }
    },
    onBreatheAgain: () {
      breathing!.breatheAgain();
      cue();
      setState(() {});
    },
    onExhale: () {
      breathing!.phase = BreathPhase.rest;
      breathing!.phaseMs = 0;
      cue();
      setState(() {});
    },
    onRetry: () => action(saveBreathing),
    onFinish: () => action(() async {
      breathing!.paused = true;
      await Device.call('stopSpeech');
      setState(() {});
      if (await confirm(
        t('Einheit beenden?', 'End session?'),
        t(
          'Abgeschlossene Runden werden gespeichert.',
          'Completed rounds will be saved.',
        ),
        accept: t('Beenden', 'Finish'),
      )) {
        await finishBreathing(interrupted: true);
      }
    }),
  );
}

// Keep dialog and theme lookups under MaterialApp without a global navigator.
class _HomeScope extends StatelessWidget {
  const _HomeScope({required this.owner});
  final _EasyHofState owner;
  @override
  Widget build(BuildContext context) {
    owner.dialogContext = context;
    return owner.content(context);
  }
}
