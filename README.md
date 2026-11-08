# Easy Hof

Eine einfache Flutter-App für angeleitete Atemübungen und Kältetraining. Android-Smartphone und eigenständige Wear-OS-App, Deutsch und Englisch. Keine Werbung, kein Konto, kein eigener Server.

## Funktionen

- **Atmen:** 1–10 Runden, 10–60 Atemzüge, 4/6/8 Sekunden pro Atemzug. Animation und deutsche/englische Android-Offline-Stimme. Freies Atemhalten bis zum manuellen Fortsetzen, 15 Sekunden Erholungsatem mit jederzeit möglichem Ausatmen, dann 5 Sekunden normales Atmen. Pause und vorzeitiges Beenden.
- **Kälte:** Dusche oder Eisbad, Stoppuhr, optionale Zielzeit mit Vibration, manuell eingegebene Temperatur in 0,5-°C-Schritten. Keine Notizen.
- **Wear OS:** Eigenständiger Kälte-Timer mit optionalem Puls. Erfasst Mittelwert/Minimum/Maximum gültiger Sensorwerte. Fehlende/alte/unzuverlässige Messwerte werden explizit gekennzeichnet. Aufzeichnung läuft bei ausgeschaltetem Display weiter.
- **Verlauf:** Atemhaltezeiten pro Runde, Dauer, Temperatur, Pulsstatistik, Herkunftsgerät und vorzeitiger Abbruch. Einzelne Einheiten löschen.
- **Sync:** Wear OS Data Layer zwischen gekoppelten Geräten, auch nach Offline-Aufzeichnung. Gleiche Paket-ID und Signatur für beide APKs. Eindeutige IDs verhindern Duplikate; Löschmarkierungen verhindern Wiederherstellung gelöschter Daten durch alte Offline-Kopien.
- **Backup:** Auf dem Smartphone Verlauf als JSON über den Android-Dateidialog exportieren/importieren. IDs bleiben erhalten; doppelte Einheiten werden zusammengeführt. Die Datei enthält Trainingsdaten und sollte an einem selbst gewählten sicheren Ort liegen.
- **Datenschutz:** Lokale Speicherung, Android-Cloud-Backup deaktiviert, keine Internetberechtigung in Release-APKs, keine Analyse-Dienste. Geräte-Sync nutzt die vom Betriebssystem bereitgestellte Google-Play-Services/Wear-OS-Verbindung; kein Easy-Hof-Backend. Ohne Play Services bleiben die lokalen Funktionen nutzbar, Geräte-Sync ist dann nicht verfügbar.

## Installation

Unter [GitHub Actions](https://github.com/andreas-aichele/easy-hof/actions/workflows/android.yml) einen erfolgreichen Lauf öffnen und die Artefakte `easy-hof-phone-dev` und `easy-hof-wear-dev` herunterladen und entpacken. Die Phone-APK auf dem Smartphone installieren; Wear-APK über ADB auf der Uhr installieren:

```sh
adb -s PHONE_SERIAL install -r app-phone-release.apk
adb -s WATCH_SERIAL install -r app-wear-release.apk
```

Android 9 / API 28 oder neuer. Für die Watch wird eine Wear-OS-Uhr mit Android API 28+ benötigt; Herzfrequenz setzt einen kompatiblen Sensor voraus. Auf beiden Geräten muss dieselbe Build-/Signaturfamilie installiert sein. Die Uhr vorher regulär mit dem Smartphone koppeln. Unter **Einstellungen → Synchronisieren** kann der automatische Sync zusätzlich manuell angestoßen werden. „Übertragung vorgemerkt“ bedeutet im System hinterlegt, nicht bestätigter Empfang auf dem anderen Gerät.

Für Sprache eine **Offline-Stimme** für Deutsch bzw. Englisch in den Android-Sprachausgabe-Einstellungen installieren. Die App wählt ausschließlich Stimmen ohne Netzwerkbedarf. Fehlt die Stimme, wird vor dem Start auf den Betrieb ohne Sprache hingewiesen.

## Entwicklung

Flutter **3.47.9**, Dart aus diesem SDK, JDK 17, Android SDK 36. Die Flutter-App wird in zwei Flavors gebaut:

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test test/breathing_test.dart test/widget_test.dart
flutter test --dart-define=WEAR=true test/wear_test.dart
flutter build apk --release --flavor phone
flutter build apk --release --flavor wear --dart-define=WEAR=true
cd android
./gradlew :app:testPhoneDebugUnitTest
```

CI führt Formatprüfung, Analyse, Tests und beide APK-Builds bei Push, Pull Request und manuell aus. Keine automatische Veröffentlichung im Play Store.

### Signierung

CI baut beide APKs im **gleichen Job** mit demselben automatisch erzeugten Android-Testschlüssel. So funktioniert die Geräte-Synchronisierung innerhalb eines Build-Paars. Der private Testschlüssel wird nicht veröffentlicht. Bei einem neuen CI-Lauf ändert sich dieser Schlüssel: Vor Installation eines neuen Entwicklungspaars müssen alte Installationen entfernt werden; lokale Daten gehen dabei verloren, sofern sie nicht vorher exportiert wurden.

Für dauerhafte Nutzung externen privaten Keystore über `KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` bereitstellen und für beide Geräte verwenden. Die CI unterstützt optional die Repository-Secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`. Mit diesen werden beide APKs stabil signiert. Schlüssel niemals ins Repository einchecken. Ein einmaliger Wechsel von Test- auf private Signatur erfordert Neuinstallation.

## Verhalten & Grenzen

- Atemübungen sind auf dem Smartphone verfügbar; die Uhr konzentriert sich auf Kälte und Verlauf. Beim Verlassen der Atemansicht oder Ausschalten des Displays pausiert die Übung. Keine heimlich weiterlaufenden Atemphasen.
- Kälte-Timer nutzt monotone Zeit, Foreground-Service und einen auf zwei Stunden begrenzten Wake-Lock. Nach zwei Stunden wird die Einheit automatisch als vorzeitig beendet gespeichert.
- Android kann Apps trotzdem beenden. Alle fünf Sekunden wird ein Kälte-Checkpoint gespeichert; nach Prozessende/Neustart wird dieser als unterbrochene Einheit wiederhergestellt. Es werden keine fiktiven Pulswerte oder nachträglichen Laufzeiten erzeugt.
- Herzfrequenz ist eine Sensor-Zusammenfassung, kein lückenloses medizinisches Signal. Es werden keine Rohdatenkurven aufgezeichnet. Temperatur stammt von der manuellen Eingabe, nicht vom Hauttemperatursensor.
- Aktive Atemübungen sind flüchtig, abgeschlossene/gezielt beendete Übungen werden gespeichert. Noch nicht gespeicherte Atemübungen gehen bei erzwungenem Prozessende verloren.
- Sync erfordert die Systemkomponenten von Google/Wear OS und eine vorhandene Verbindung. Noch nicht gekoppelte Geräte synchronisieren nicht. Diese App unterhält keine eigene Cloud, kontrolliert aber nicht das Transport-Routing der Wear-OS-Systemdienste.

## Sicherheit

Atemübungen ausschließlich sitzend oder liegend an einem sicheren, trockenen Ort — nie im Wasser, in der Dusche oder beim Fahren. Kein Wettkampf um Atemhaltezeiten. Bei Unwohlsein abbrechen. Im Eisbad normal atmen und nicht allein trainieren. Bei Schwangerschaft, Epilepsie oder Herz-/Kreislauferkrankungen vorher ärztlich abklären. Puls ist bei Kälte möglicherweise ungenau und kein Sicherheitsindikator. Keine medizinische Anwendung, keine offizielle Wim-Hof-App.

Grundlage: [Offizielle Atemtechnik](https://www.wimhofmethod.com/breathing-exercises), [WHM FAQ](https://www.wimhofmethod.com/faq).

## Noch am Gerät prüfen

Vor einer stabilen Veröffentlichung: echte Pixel Watch (Sensorzugriff, Berechtigung verweigert, Display aus), Bluetooth-Trennung und späterer Sync, identische Signatur, Offline-Stimmen, Prozessende/Neustart und Batterieverbrauch. Emulator- und Unit-Tests ersetzen diese Hardwaretests nicht.
