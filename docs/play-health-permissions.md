# Google Play: Berechtigungen für Gesundheitsdaten

## android.permission.BODY_SENSORS

Easy Hof verwendet diese Berechtigung auf Wear-OS-Uhren mit Android 15 (API 35)
oder älter, um während eines vom Nutzer aktiv gestarteten Kältetrainings (Dusche
oder Eisbad) den Herzfrequenzsensor auszulesen. Der aktuelle Puls wird während der
Sitzung angezeigt. Ein Vordergrunddienst hält die laufende Sitzung aufrecht.
Nach Ende der Sitzung endet die Sensorabfrage. Es gibt keine fortlaufende
Pulserfassung außerhalb aktiv gestarteter Kältesitzungen. Im Verlauf werden
Durchschnitt, Minimum und Maximum aus lokalen Sitzungsstatistiken dargestellt.
Diese Ergebnisse werden über die Wear OS Data Layer mit dem gekoppelten
Smartphone synchronisiert. Die Berechtigung ist optional; ohne sie funktioniert
der Kältetimer weiter. Die Daten dienen der persönlichen Trainingsdokumentation
und werden nicht für Werbung, medizinische Diagnosen oder Alarmierung verwendet.

## android.permission.health.READ_HEART_RATE

Easy Hof verwendet diese Berechtigung auf Wear-OS-Uhren ab Android 16 (API 36)
für die optionale Herzfrequenzerfassung während eines vom Nutzer aktiv gestarteten
Kältetrainings (Dusche oder Eisbad). Die App zeigt den aktuellen Puls an und
speichert lokale Sitzungsstatistiken zur Darstellung von Durchschnitt, Minimum
und Maximum. Ein Vordergrunddienst hält die aktive Sitzung aufrecht; nach Ende
der Sitzung endet die Sensorabfrage. Es gibt keine fortlaufende Erfassung
außerhalb gestarteter Sitzungen. Die Ergebnisse werden über die Wear OS Data
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
