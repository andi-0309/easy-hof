<div align="center">

# Easy Hof
### Ein klarer Kopf. Ein ruhiger Atem. Dein Moment.

Offline-Atemtraining und Kälteroutinen für **Android & Wear OS**.
Deutsch und Englisch. Ohne Konto. Ohne Abo. Ohne Tracking.

[![Build](https://github.com/andi-0309/easy-hof/actions/workflows/android.yml/badge.svg)](https://github.com/andi-0309/easy-hof/actions/workflows/android.yml)
[![Release](https://img.shields.io/github/v/release/andi-0309/easy-hof)](https://github.com/andi-0309/easy-hof/releases)
[![Flutter](https://img.shields.io/badge/Built_with-Flutter-075B68)](https://flutter.dev)

[**App herunterladen**](https://github.com/andi-0309/easy-hof/releases/latest) · [Installation](#installation) · [Wear OS](#deine-uhr-deine-routine) · [Mitmachen](#mitmachen)

![Nordic Elements – warme Lichtflächen und kühle Bergschatten](assets/images/nordic-mountains.webp)

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
Android 9+ für das Smartphone; für die integrierte WLAN-Installation Wear OS 3+.

## Deine Uhr. Deine Routine.

Starte ein Kältetraining direkt am Handgelenk – auch wenn dein Smartphone zu Hause
liegt. Dauer, Temperatur und optional Herzfrequenz werden auf der Uhr erfasst.
Sind die regulär gekoppelten Geräte wieder verbunden, können sie ihre Sitzungen
abgleichen. Herzfrequenzzugriff ist optional und benötigt die Sensorberechtigung.

**Installation aus Easy Hof, ohne Computer:**

1. Verbinde Uhr und Smartphone mit demselben WLAN.
2. Öffne auf dem Smartphone **Easy Hof → Einstellungen → Uhr-App installieren**.
3. Aktiviere auf der Uhr Entwickleroptionen, ADB-Debugging und WLAN-Debugging.
4. Wähle auf der Uhr **Mit Kopplungscode koppeln** und trage IP-Adresse,
   Kopplungsport und Code in Easy Hof ein.
5. Gehe auf der Uhr zurück zur WLAN-Debugging-Seite. Übernimm den dortigen
   **Verbindungsport** (anders als der Kopplungsport) und tippe auf **Installieren**.
6. Öffne Easy Hof auf der Uhr. Deaktiviere WLAN-Debugging danach wieder.

Die passende Wear-APK ist bereits in der Smartphone-App enthalten. Updates der
Uhr installierst du über denselben Bildschirm; nach dem Handy-Update ist auch die
neue Wear-APK enthalten. Obtainium aktualisiert die Uhr **nicht automatisch**.
Beide Apps müssen aus derselben Release-Serie mit identischer Signatur stammen.
Die WLAN-Verbindung dient nur der von dir gestarteten Installation. Es werden
keine Trainingsdaten an einen Server übertragen.

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
Use **Settings → Install watch app** to pair via Wireless debugging and install
the included watch APK. No account, subscription or analytics.
