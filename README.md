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
| Übersichtlicher Trainingsverlauf | Eigenständiges Training mit Wear OS |

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

Starte ein Kältetraining direkt am Handgelenk – auch wenn dein Smartphone zu Hause
liegt. Dauer, Temperatur und optional Herzfrequenz werden auf der Uhr erfasst.
Sind die regulär gekoppelten Geräte wieder verbunden, können sie ihre Sitzungen
abgleichen. Herzfrequenzzugriff ist optional und benötigt die Sensorberechtigung.

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
