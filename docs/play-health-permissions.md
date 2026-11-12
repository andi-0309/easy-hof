# Google Play: Berechtigungen für Gesundheitsdaten

## android.permission.BODY_SENSORS

Easy Hof verwendet diese Berechtigung auf Wear-OS-Uhren mit Android 15 (API 35)
oder älter, um während eines vom Nutzer aktiv gestarteten Trainings (Dusche, Eisbad oder Atmen) den Herzfrequenzsensor auszulesen. Der aktuelle Puls wird während der
Sitzung angezeigt. Ein Vordergrunddienst hält die laufende Sitzung aufrecht.
Nach Ende der Sitzung endet die Sensorabfrage. Es gibt keine fortlaufende
Pulserfassung außerhalb aktiv gestarteter Trainingseinheiten. Im Verlauf werden
Durchschnitt, Minimum und Maximum aus lokalen Sitzungsstatistiken dargestellt.
Für neue Sitzungen speichert die App zusätzlich einen zeitlichen Pulsverlauf mit bis zu einem Messpunkt alle fünf Sekunden. Diese Ergebnisse werden über die Wear OS Data Layer mit dem gekoppelten
Smartphone synchronisiert. Die Berechtigung ist optional; ohne sie funktioniert
der Kältetimer weiter. Die Daten dienen der persönlichen Trainingsdokumentation
und werden nicht für Werbung, medizinische Diagnosen oder Alarmierung verwendet.

## android.permission.health.READ_HEART_RATE

Easy Hof verwendet diese Berechtigung auf Wear-OS-Uhren ab Android 16 (API 36)
für die optionale Herzfrequenzerfassung während eines vom Nutzer aktiv gestarteten
Trainings (Dusche, Eisbad oder Atmen). Die App zeigt den aktuellen Puls an und
speichert lokale Sitzungsstatistiken zur Darstellung von Durchschnitt, Minimum
und Maximum. Ein Vordergrunddienst hält die aktive Sitzung aufrecht; nach Ende
der Sitzung endet die Sensorabfrage. Es gibt keine fortlaufende Erfassung
außerhalb gestarteter Sitzungen. Neue Sitzungen speichern zusätzlich einen Pulsverlauf mit bis zu einem Messpunkt alle fünf Sekunden. Die Ergebnisse werden über die Wear OS Data
Layer mit dem gekoppelten Smartphone synchronisiert. Die Berechtigung kann
verweigert oder widerrufen werden; der Kältetimer bleibt ohne Pulswerte nutzbar.
Die Daten dienen ausschließlich der persönlichen Trainingsdokumentation und
werden nicht für Werbung, medizinische Diagnosen oder Alarmierung verwendet.

## Öffentliche Datenschutzerklärung

https://github.com/andi-0309/easy-hof/blob/main/PRIVACY.md

Die Erklärung ist zusätzlich in Deutsch und Englisch offline in den
App-Einstellungen unter Datenschutz enthalten. Die Texte beschreiben die aktuelle
Implementierung und müssen bei Änderungen der Erfassung/Synchronisierung mit
angepasst werden.

## Health Connect am Telefon (ab 1.4.0)

### android.permission.health.WRITE_EXERCISE

Nach ausdrücklicher Aktivierung schreibt Easy Hof die Start- und Endzeiten sowie
den Typ selbst aufgezeichneter oder manuell erfasster Einheiten als allgemeines
Training in Health Connect. Die Funktion dient dem persönlichen Trainingsarchiv.
Die lokale Historie bleibt ohne Freigabe nutzbar. Daten anderer Apps werden nicht
gelesen. Wassertemperatur und Atemhaltezeiten verbleiben in Easy Hof.

### android.permission.health.WRITE_HEART_RATE

Nach ausdrücklicher Aktivierung schreibt Easy Hof vorhandene, während des Trainings
über Health Services auf der gekoppelten Wear-OS-Uhr gemessene Pulswerte mit ihren
tatsächlichen Zeitpunkten in Health Connect. Es werden keine Werte erfunden und
keine Herzfrequenzdaten anderer Apps gelesen. Die Daten dienen dem persönlichen
Trainingsarchiv, nicht Diagnose, Therapie, Werbung oder Alarmierung.

Die zusätzlichen Schreibberechtigungen müssen vor der Veröffentlichung in der
Play Console unter Gesundheits-Apps für den Telefon-Build erklärt werden.
