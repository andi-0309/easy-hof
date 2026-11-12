<div align="center">

# Easy Hof
### Ein klarer Kopf. Ein ruhiger Atem. Dein Moment.

Offline-Atemtraining und Kälteroutinen für **Android & Wear OS**.
Deutsch und Englisch. Ohne Konto. Ohne Abo. Ohne Tracking.

[![Build](https://github.com/andi-0309/easy-hof/actions/workflows/android.yml/badge.svg)](https://github.com/andi-0309/easy-hof/actions/workflows/android.yml)
[![Release](https://img.shields.io/github/v/release/andi-0309/easy-hof)](https://github.com/andi-0309/easy-hof/releases)
[![Flutter](https://img.shields.io/badge/Built_with-Flutter-075B68)](https://flutter.dev)

[**App herunterladen**](https://github.com/andi-0309/easy-hof/releases/latest) · [Installation](#installation) · [Wear OS](#deine-uhr-deine-routine) · [Datenschutz](PRIVACY.md) · [Mitmachen](#mitmachen)

**Nordic Elements:** Vektorberge, nordische Farben und plastische Bedienelemente – auf Smartphone und Uhr.

</div>

## Weniger Ablenkung. Mehr bei dir.

Easy Hof begleitet dich durch Atemrunden, die kalte Dusche und dein Eisbad.
Eine ruhige Oberfläche im Stil **Nordic Elements** verbindet Eisblau und Petrol
mit warmen Sonnenakzenten. Große Bedienelemente, klare Zahlen und ein dunkles
Design für den Abend lassen Platz für das Wesentliche: deine Routine.

| Atme in deinem Rhythmus | Finde deinen Moment in der Kälte |
| --- | --- |
| Einstellbare Runden, Atemzüge und Tempo | Dusche und Eisbad getrennt erfassen |
| Sanfte Atemgeräusche zum Mitatmen | Dauer und optionale Temperatur festhalten |
| Deutsche und englische Sprachführung | Optionales Zeitziel |
| Atemhalten ohne Leistungsdruck | Herzfrequenz auf unterstützten Uhren |
| Übersichtlicher Trainingsverlauf | Schnelle Aufzeichnung mit Wear OS |

Du hast ohne Timer trainiert? Trage Duschen und Eisbäder mit Datum, Dauer und
optionaler Temperatur nach – direkt unter **Kälte** oder im **Verlauf**, auf dem
Smartphone. Die Einträge werden mit deinen Geräten abgeglichen.

Der Verlauf zeigt kompakte Monatskarten und einen Trainingskalender. Tippe auf
einen Tag für deine Einheiten und die Pulsverläufe neuer Uhr-Aufzeichnungen.

Alle Ansagen, Atemgeräusche und Schriften sind in der App enthalten. Dein Training
funktioniert offline. Sitzungen bleiben lokal, lassen sich als JSON sichern und
zwischen gekoppeltem Smartphone und Uhr über die Wear OS Data Layer abgleichen.
Keine eigene Cloud, kein Benutzerkonto, keine Analyse-SDKs. Die Google-Play-Dienste
werden für die Kommunikation zwischen Uhr und Smartphone benötigt.

## Installation

### Mit Obtainium: Updates direkt von GitHub

1. Installiere [Obtainium](https://github.com/ImranR98/Obtainium/releases/latest) auf deinem Android-Smartphone.
2. Wähle **App hinzufügen** und füge diese URL ein:
   ```text
   https://github.com/andi-0309/easy-hof
   ```
3. Setze den **APK-Filter / regulären Ausdruck** auf:
   ```regex
   ^easy-hof-phone\.apk$
   ```
   Damit wählt Obtainium die Smartphone-App, nicht die separate Wear-APK.
4. Füge die App hinzu, installiere sie und erlaube Obtainium bei Bedarf das
   Installieren unbekannter Apps. Künftige veröffentlichte Releases werden über
   diese Quelle gefunden.

Obtainium verwendet **Releases**, keine temporären Actions-Artefakte. Falls noch kein
Release veröffentlicht wurde, gibt es dort noch keine installierbare Version.

### Direkt herunterladen

Öffne die [Releases](https://github.com/andi-0309/easy-hof/releases), lade
`easy-hof-phone.apk` und installiere sie auf dem Smartphone. `easy-hof-wear.apk`
ist ausschließlich für die Uhr. Für beide APKs liegen SHA-256-Prüfsummen bei.
Android 9+ für das Smartphone. Die Uhr-App wird über Google Play verteilt.

## Deine Uhr. Deine Routine.

Die Uhr ist die kompakte Ergänzung zum Telefon: Wähle **Dusche** oder **Eisbad**,
stelle danach Zielzeit und Temperatur ein und starte die Aufzeichnung. Die
kreisförmige Bedienfläche ist für runde Displays optimiert; eckige Displays zeigen
im zusätzlichen Platz die Landschaft. Verlauf und Einstellungen bleiben am Telefon.
Eine laufende Kälteaufzeichnung funktioniert auch bei vorübergehend getrennter
Verbindung und wird später synchronisiert.

**Puls beim Atmen:** Starte **Atmen** auf der Uhr und erteile beim Trainingsstart
den optionalen Sensorzugriff. Die Uhr ist bis zu drei Minuten für das Atemtraining
am Telefon bereit und verbindet sich dann automatisch mit der Einheit. Du kannst
auch zuerst am Telefon beginnen. Ein zusätzlicher Puls-Menüpunkt entfällt.
Ohne Freigabe oder Messwerte läuft die Atemübung am Telefon weiter. Die
Übertragung benötigt eine Geräteverbindung und Google Play-Dienste.

**Kälte-Standardwerte:** Dusche 3 Minuten, Eisbad 5 Minuten, Temperatur 5 °C.
Zielzeit und Temperatur lassen sich vor dem Start ändern; die Temperaturtasten
verwenden 1-Grad-Schritte. Beim Erreichen der Zielzeit vibriert die Uhr deutlich.

**Krone & Wassersperre:** Die Krone scrollt Listen und Dialoge. Beim Start einer
Dusche oder eines Eisbads sperrt Easy Hof seine Touch-Bedienung automatisch.
Drehe die Krone, bis der Ring um das Schloss vollständig gefüllt ist, um wieder
bedienen zu können. Die Sperre gilt innerhalb von Easy Hof; sie aktiviert keinen
herstellerspezifischen systemweiten Wassermodus und keine Lautsprecherentleerung.

**Installation über Google Play:**

1. Installiere Easy Hof auf deinem Smartphone – über GitHub/Obtainium oder Google Play.
2. Öffne **Einstellungen → Uhr-App installieren**. Der Button öffnet den Play-Store-Eintrag.
3. Wähle deine Uhr unter **Auf weiteren Geräten installieren** aus oder öffne den
   Play Store direkt auf der Uhr und installiere Easy Hof dort.
4. Verwende dasselbe Google-Konto auf Smartphone und Uhr. Für den internen Test
   muss dieses Konto als Tester eingetragen sein und die Testeinladung annehmen.

Die Uhr-App steht im Play Store bereit, sobald der entsprechende Test oder Release
freigeschaltet ist. Der Store übernimmt auch ihre Updates. Die Smartphone-App
enthält keinen WLAN-/ADB-Installer und keine eingebettete Wear-APK. Beide
Installationsquellen öffnen denselben Store-Eintrag für die Uhr. Für die
Synchronisierung benötigen beide Apps denselben Paketnamen und dieselbe Signatur.

## Bewusst trainieren

Atemübungen nur sitzend oder liegend an einem sicheren, trockenen Ort durchführen.
**Nie im Wasser, unter der Dusche oder beim Fahren.** Nicht erzwingen und bei
Unwohlsein abbrechen. Easy Hof ist eine unabhängige App, kein Medizinprodukt und
keine offizielle App der Wim-Hof-Methode. Medizinische Hinweise stehen vor dem
Training direkt in der App.

## Mitmachen

Fehler gefunden oder eine Idee? [Eröffne ein Issue](https://github.com/andi-0309/easy-hof/issues).
Bitte nenne Gerät, Android-/Wear-OS-Version und Schritte zum Nachstellen.
Beiträge zu Bedienbarkeit, Übersetzungen und Barrierefreiheit sind willkommen.

- [Builds, Signierung & Releases](docs/RELEASING.md)
- [Audio-Erzeugung und Herkunft](assets/audio/README.md)
- [Design und Drittanbieter](docs/ATTRIBUTIONS.md)

Der Quellcode ist einsehbar; eine Projektlizenz wird vom Maintainer festgelegt.
Die enthaltenen Schriften und Bibliotheken behalten ihre jeweiligen Lizenzen.

---

**English:** Easy Hof is an offline Android and Wear OS companion for guided
breathing and cold routines. Follow natural breath sounds, choose German or
English guidance, and keep your history on your devices. Install the phone APK
through Obtainium using the repository URL and the `^easy-hof-phone\.apk$` filter.
Use **Settings → Install watch app** to open Google Play and install Easy Hof
on your watch. Watch updates are delivered through Google Play. No Easy Hof account,
subscription or analytics.

### Live-Puls und Health Connect

Ab Version 1.4.0 nutzt die Uhr **Health Services** für den Live-Puls während
Atmung und Kältetraining (Wear OS 3 oder neuer). Telefon und Uhr tauschen aktuelle
Werte direkt aus; abgeschlossene Einheiten werden dauerhaft synchronisiert.
Ein bereits laufendes Training einer anderen App wird nicht übernommen.

Unter **Einstellungen → Health Connect** lässt sich am Telefon optional ein Archiv
für Trainingszeiten und gemessene Pulsverläufe aktivieren. Easy Hof liest keine
Daten anderer Apps. Die eigene Historie, Temperatur und Atemhaltezeiten bleiben
lokal verfügbar. Ältere Atemeinheiten ohne zuverlässige Endzeit bleiben ausschließlich
in Easy Hof. Ohne Freigabe funktionieren Timer, Übungen und lokale Historie weiter.
Health Connect muss auf dem Telefon verfügbar sein (ab Android 14 Teil des Systems).
Nach dem Trennen bleiben bereits archivierte Kopien in Health Connect erhalten.

Die Uhrenansicht verwendet einen schwarzen OLED-Hintergrund mit dezenten Bergen
und kontrastreichen 3D-Buttons.
