import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'platform.dart';
import 'nordic.dart';

class WatchInstall extends StatefulWidget {
  const WatchInstall({super.key, required this.language});
  final String language;
  @override
  State<WatchInstall> createState() => _WatchInstallState();
}

class _WatchInstallState extends State<WatchInstall> {
  final host = TextEditingController();
  final pairPort = TextEditingController();
  final code = TextEditingController();
  final port = TextEditingController();
  bool busy = false, paired = false, installed = false;
  String? error;
  String t(String de, String en) => widget.language == 'de' ? de : en;
  @override
  void dispose() {
    host.dispose();
    pairPort.dispose();
    code.dispose();
    port.dispose();
    super.dispose();
  }

  Future<void> run(bool pair) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await Device.call(pair ? 'watchPair' : 'watchInstall', {
        'host': host.text.trim(),
        'port': int.tryParse((pair ? pairPort : port).text.trim()) ?? 0,
        if (pair) 'code': code.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        if (pair) {
          paired = true;
          code.clear();
        } else {
          installed = true;
        }
      });
    } on PlatformException catch (e) {
      if (mounted) {
        setState(
          () => error =
              '${t('Bitte IP, Port und WLAN-Verbindung prüfen.', 'Check the IP, port and Wi-Fi connection.')}\n${e.message ?? e.code}',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = t(
            'Installation nicht verfügbar.',
            'Installation unavailable.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool secret = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextField(
      controller: controller,
      enabled: !busy,
      obscureText: secret,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) {
        if (controller == host && paired) setState(() => paired = false);
      },
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(t('Deine Uhr verbinden', 'Connect your watch')),
        automaticallyImplyLeading: !busy,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(Icons.watch_rounded, size: 48),
                const SizedBox(height: 16),
                Text(
                  t(
                    'Dein Training. Auch ohne Handy.',
                    'Your practice. Without your phone.',
                  ),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  t(
                    'Handy und Uhr müssen im selben WLAN sein. Die APK ist bereits in dieser App enthalten – kein Download und kein Computer nötig.',
                    'Connect phone and watch to the same Wi-Fi. The APK is included in this app — no download or computer needed.',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  t('1 · Uhr vorbereiten', '1 · Prepare your watch'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    'Auf der Uhr: Einstellungen → System → Info → Versionen. Tippe siebenmal auf die Build-Nummer. Öffne danach die Entwickleroptionen und aktiviere ADB-Debugging und WLAN-Debugging. Die Bezeichnungen können je nach Uhr abweichen.',
                    'On your watch: Settings → System → About → Versions. Tap the build number seven times. Open Developer options and enable ADB debugging and Wireless debugging. Names may vary between watches.',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  t('2 · Mit Code koppeln', '2 · Pair with a code'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    'Wähle auf der Uhr „Gerät mit Kopplungscode koppeln“. Trage die IP-Adresse, den dort angezeigten Kopplungsport und den sechsstelligen Code ein. Halte diese Seite auf der Uhr geöffnet.',
                    'On your watch, choose “Pair device with pairing code”. Enter its IP address, pairing port and six-digit code. Keep that screen open on the watch.',
                  ),
                ),
                field(host, t('IP-Adresse der Uhr', 'Watch IP address')),
                field(pairPort, t('Kopplungsport', 'Pairing port')),
                field(
                  code,
                  t('Kopplungscode (6 Ziffern)', 'Pairing code (6 digits)'),
                  secret: true,
                ),
                OutlinedButton(
                  onPressed: busy ? null : () => run(true),
                  child: Text(
                    paired
                        ? t('Gekoppelt · erneut koppeln', 'Paired · pair again')
                        : t('Koppeln', 'Pair'),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  t(
                    '3 · Installieren oder aktualisieren',
                    '3 · Install or update',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    'Gehe auf der Uhr eine Seite zurück zu WLAN-Debugging. Verwende jetzt den Verbindungsport unter „IP-Adresse und Port“ – er unterscheidet sich vom Kopplungsport. Eine bereits gekoppelte Uhr kannst du direkt aktualisieren.',
                    'Return to the Wireless debugging screen on your watch. Enter the connection port from “IP address & port” — it differs from the pairing port. Previously paired watches can be updated directly.',
                  ),
                ),
                field(port, t('Verbindungsport', 'Connection port')),
                const SizedBox(height: 12),
                SunButton(
                  onPressed: busy ? null : () => run(false),
                  icon: Icons.download_rounded,
                  label: busy
                      ? t('Bitte warten …', 'Please wait …')
                      : t('Wear-App installieren', 'Install Wear app'),
                ),
                if (busy) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  Text(
                    t(
                      'Die Übertragung kann einige Minuten dauern. Lass beide Geräte verbunden.',
                      'Transfer may take a few minutes. Keep both devices connected.',
                    ),
                  ),
                ],
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Semantics(liveRegion: true, child: Text('⚠ $error')),
                  ),
                if (installed)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        t(
                          '✓ Installiert. Öffne Easy Hof auf der Uhr und erlaube bei Bedarf den Zugriff auf die Herzfrequenz. Schalte WLAN-Debugging jetzt wieder aus. Für den Trainings-Sync muss deine Uhr regulär mit diesem Smartphone gekoppelt sein.',
                          '✓ Installed. Open Easy Hof on your watch and allow heart-rate access if wanted. Turn Wireless debugging off again. Training sync requires your watch to be paired normally with this phone.',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
