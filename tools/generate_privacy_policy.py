"""Keep the public privacy statement and bundled offline copies in sync."""
from pathlib import Path

DATE = '2026-11-11'
URL = 'https://github.com/andi-0309/easy-hof/blob/main/PRIVACY.md'
CONTACT = 'https://github.com/andi-0309/easy-hof/issues'

POLICY = {
    'de': ('Datenschutzerklärung – Easy Hof', [
        ('Geltungsbereich und Kontakt',
         'Diese Erklärung beschreibt Easy Hof für Android und Wear OS mit dem Paketnamen io.github.andi_0309.easyhof. Entwickler und Datenschutzkontakt ist der Projektbetreuer andi-0309.\n\n'
         f'Kontakt für Datenschutzfragen: {CONTACT}\n'
         'GitHub-Anfragen sind öffentlich und benötigen ein GitHub-Konto. Für eine Anfrage sind keine Gesundheitsdaten erforderlich; für vertrauliche Anliegen kann dort zunächst ein privater Kontaktweg vereinbart werden.'),
        ('Trainingsdaten auf deinen Geräten',
         'Easy Hof verarbeitet die von dir gestarteten Atem- und Kältesitzungen sowie manuell nachgetragene Duschen und Eisbäder. Manuelle Einträge enthalten keine Pulsmessungen. Dazu gehören Art, Startzeit, Dauer, optionale Zielzeit und manuell eingegebene Wassertemperatur. Bei Atemübungen werden außerdem Runden, Atemzüge, Tempo und Atemhaltezeiten gespeichert. Technische Sitzungskennungen, Änderungszeitpunkte und die Herkunft Smartphone/Uhr dienen dem Abgleich der Einträge. Sprache, Audio, Vibration und Übungsparameter werden als Einstellungen gespeichert und vom Telefon an die gekoppelte Uhr übertragen.\n\n'
         'Es gibt kein Easy-Hof-Benutzerkonto. Die Trainingsfunktionen und eingebundenen Audiodateien und Schriften funktionieren offline. Der Entwickler betreibt keinen Server, der deine Trainings- oder Herzfrequenzdaten empfängt.'),
        ('Optionale Herzfrequenz auf der Uhr',
         'Nach deiner Freigabe liest die Wear-OS-App während eines von dir aktiv gestarteten Kältetrainings oder nach deiner Bestätigung auf der Uhr für ein Atemtraining am gekoppelten Telefon den Herzfrequenzsensor der Uhr aus. Der aktuelle Puls wird während der Sitzung angezeigt. Ein Vordergrunddienst hält das laufende Training aufrecht, auch wenn du die App-Ansicht verlässt. Die Sensorabfrage endet mit der Sitzung oder dem Ende des Trainingsdienstes. Es findet keine fortlaufende Pulserfassung außerhalb eines gestarteten Trainings statt.\n\n'
         'Gespeichert werden statistische Sitzungswerte: Minimum, Maximum sowie Anzahl und Summe der berücksichtigten Messwerte zur Berechnung des Durchschnitts. Ab Version 1.2.0 wird bei neuen Aufzeichnungen zusätzlich ein Pulsverlauf mit höchstens einem Messpunkt je fünf Sekunden gespeichert. Jeder Messpunkt enthält die seit Sitzungsbeginn verstrichene Zeit und den Pulswert. Maximal 1.441 Punkte pro Sitzung halten Speicherung und Geräteabgleich begrenzt. Fehlende Messungen werden nicht ergänzt. Ältere Sitzungen und manuelle Einträge haben keinen nachträglich rekonstruierten Pulsverlauf. Die Werte dienen deiner persönlichen Trainingsübersicht, nicht der medizinischen Diagnose, Behandlung oder Alarmierung.\n\n'
         'Auf Uhren bis Android 15 (API 35) wird BODY_SENSORS verwendet; ab Android 16 (API 36) READ_HEART_RATE. Die Berechtigung ist optional. Du kannst sie verweigern oder in den Systemeinstellungen widerrufen und das Training ohne Pulswerte fortsetzen. Auf dem Smartphone fordert Easy Hof diese Sensorberechtigungen nicht an.'),
        ('Synchronisierung zwischen Smartphone und Uhr',
         'Beim Atemtraining überträgt das Telefon Sitzungskennung, Startzeit, aktive Übungszeit, Pause-/Endestatus, Sprache und Übertragungszeitpunkt an die Uhr. Nach deiner Bestätigung sendet die Uhr aktuelle Pulswerte, Pulsverlauf und Zusammenfassung an das Telefon. Messpunkte werden auf die aktive Übungszeit bezogen; Pausen und Verbindungslücken werden nicht mit erfundenen Werten gefüllt. Nach 90 Sekunden ohne Aktualisierung vom Telefon endet die Sensoraufnahme. Diese Informationen werden nur zwischen deinen gekoppelten Geräten verarbeitet.\n\n'
         'Gespeicherte Sitzungen einschließlich vorhandener Herzfrequenz-Zusammenfassungen, Pulsverläufe und Löschmarkierungen werden über die Wear OS Data Layer der Google Play-Dienste mit der Easy-Hof-App auf deinen gekoppelten Geräten abgeglichen. Eine Übertragung kann später erfolgen, sobald wieder eine Verbindung besteht. Die Sitzungs-Synchronisierung ist Bestandteil der App und wird bei verfügbarer Verbindung automatisch angestoßen; es gibt derzeit keinen separaten Sync-Ausschalter.\n\n'
         'Für den Geräteabgleich werden Google Play-Dienste verwendet. Transport und technische Verarbeitung durch diese Plattformdienste richten sich auch nach deren Bedingungen und deinen Geräteeinstellungen. Die App sendet diese Daten nicht an einen vom Easy-Hof-Entwickler betriebenen Dienst. Informationen zu Google: https://policies.google.com/privacy'),
        ('Speicherung, Export und Löschen',
         'Sitzungen und Einstellungen liegen im privaten App-Speicher des jeweiligen Geräts. Sie bleiben dort, bis du sie löschst oder die App-Daten entfernst; eine automatische zeitliche Löschung ist nicht eingerichtet. Die App deaktiviert die Android-Cloud-Sicherung und den automatischen App-Datentransfer in ihrer Sicherungskonfiguration.\n\n'
         'Auf dem Smartphone kannst du den Verlauf auf eigenen Wunsch als JSON-Datei exportieren oder eine solche Sicherung importieren. Die Exportdatei kann Trainings- und Herzfrequenzwerte enthalten und erhält von Easy Hof keine zusätzliche Dateiverschlüsselung. Du wählst den Speicherort über Android; ein ausgewählter Cloud-Dateianbieter kann die Datei nach seinen eigenen Regeln übertragen und speichern. Der Entwickler erhält die Exportdatei nicht automatisch.\n\n'
         'Beim Löschen einer Sitzung werden deren Trainings- und Pulswerte im App-Verlauf durch eine technische Löschmarkierung ersetzt. Kennung und Löschzeitpunkt können verbleiben, damit ein älterer Eintrag auf einem anderen Gerät nicht erneut importiert wird. Für das Löschen synchronisierter Einheiten lass deine Geräte nach der Löschung wieder synchronisieren. Kopien auf noch nicht verbundenen Geräten oder in exportierten Dateien bleiben bis zu ihrer jeweiligen Löschung bestehen. Das Entfernen lokaler App-Daten löscht nicht automatisch separat gespeicherte Sicherungen oder die Kopie auf einem anderen Gerät.'),
        ('Werbung, Analysen und externe Dienste',
         'Easy Hof enthält keine Werbung und keine eigenen Analyse- oder Crash-Tracking-SDKs. Trainings- und Herzfrequenzdaten werden vom Entwickler nicht zu Werbezwecken verwendet oder verkauft.\n\n'
         'Google Play, Google Play-Dienste und Android/Wear OS können unabhängig davon technische Betriebs- und Diagnosedaten nach ihren eigenen Einstellungen und Datenschutzhinweisen verarbeiten und etwa Fehlerberichte über Google Play bereitstellen. Wenn du den Store-Link in Easy Hof öffnest, wird der Google Play Store beziehungsweise dein Browser aufgerufen. Es werden dabei keine Sitzungsdaten als URL-Parameter übergeben.\n\n'
         'Diese öffentliche Erklärung und der Quellcode werden auf GitHub gehostet. Beim Aufruf der GitHub-Seite verarbeitet GitHub technische Zugriffsdaten nach seinen eigenen Datenschutzhinweisen: https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement . Die in der App enthaltene Kopie dieser Erklärung kann offline gelesen werden.'),
        ('Deine Kontrolle und Änderungen',
         'Du entscheidest, wann du ein Training startest und ob du die Herzfrequenzberechtigung erteilst. Du kannst Berechtigungen in den Systemeinstellungen verwalten sowie Einheiten in der App löschen und den Verlauf exportieren. Fragen zu dieser Erklärung oder zur Datenverarbeitung kannst du über den oben angegebenen Kontaktweg stellen.\n\n'
         'Bei Änderungen der Datenverarbeitung wird diese Erklärung aktualisiert. Die veröffentlichte Onlinefassung gilt für den dort beschriebenen Versionsstand; die App enthält die zu ihrem Build gehörende Offlinefassung.'),
    ]),
    'en': ('Privacy policy – Easy Hof', [
        ('Scope and contact',
         'This policy describes Easy Hof for Android and Wear OS, package io.github.andi_0309.easyhof. The developer and privacy contact is project maintainer andi-0309.\n\n'
         f'Contact for privacy enquiries: {CONTACT}\n'
         'GitHub issues are public and require a GitHub account. Health information is not required for an enquiry; a private contact channel can first be arranged there for confidential matters.'),
        ('Training data on your devices',
         'Easy Hof processes the breathing and cold sessions you start, as well as showers and ice baths you add manually. Manual entries do not contain heart-rate readings. This includes session type, start time, duration, optional target time and manually entered water temperature. Breathing sessions also store rounds, breaths, pace and breath-hold durations. Technical session identifiers, update timestamps and phone/watch origin support synchronization. Language, audio, haptics and exercise parameters are saved as settings and transferred from your phone to your paired watch.\n\n'
         'There is no Easy Hof user account. Training functions, bundled audio and fonts work offline. The developer does not operate a server that receives your training or heart-rate data.'),
        ('Optional heart rate on the watch',
         'With your permission, the Wear OS app reads the watch heart-rate sensor during a cold session you actively start, or after you confirm on the watch for a breathing session on your paired phone. The current heart rate is displayed during the session. A foreground service keeps the active training running when you leave the app view. Sensor access ends with the session or training service. There is no ongoing heart-rate collection outside an actively started training session.\n\n'
         'Stored session statistics comprise minimum, maximum, and the count and sum of accepted measurements used to calculate the average. From version 1.2.0, new recordings also store a heart-rate trace with at most one sample every five seconds. Each sample contains elapsed time from session start and the heart-rate value. Storage is limited to 1,441 samples per session. Missing readings are not filled in. Older sessions and manual entries do not have reconstructed heart-rate traces. Values support your personal training overview, not medical diagnosis, treatment or alerts.\n\n'
         'Watches through Android 15 (API 35) use BODY_SENSORS; Android 16 (API 36) and later use READ_HEART_RATE. Permission is optional. You can decline or revoke it in system settings and continue training without heart-rate values. The phone app does not request these sensor permissions.'),
        ('Phone and watch synchronization',
         'For breathing, your phone sends the session identifier, start time, active exercise time, pause/end status, language and transmission timestamp to your watch. After your confirmation, the watch sends current heart rate, trace and summary to your phone. Samples follow the active exercise timeline; pauses and connection gaps are not filled with invented readings. Sensor recording ends after 90 seconds without phone updates. These details are processed only between your paired devices.\n\n'
         'Stored sessions, including available heart-rate summaries, heart-rate traces and deletion markers, are synchronized with Easy Hof on your paired devices through the Google Play services Wear OS Data Layer. Transfer may occur later when connectivity returns. Session synchronization is part of the app and is triggered automatically when a connection is available; there is currently no separate switch to disable sync.\n\n'
         'Device synchronization uses Google Play services. Transport and technical processing by platform services are also governed by their terms and your device settings. The app does not send these records to a service operated by the Easy Hof developer. Google privacy information: https://policies.google.com/privacy'),
        ('Storage, export and deletion',
         'Sessions and settings are stored in each device’s private app storage until you delete them or remove app data. There is no automatic age-based deletion. The app disables Android cloud backup and automatic app-data transfer in its backup configuration.\n\n'
         'On the phone, you can explicitly export history to a JSON file or import such a backup. The exported file can contain training and heart-rate data and is not additionally encrypted by Easy Hof. You choose its location through Android; a cloud document provider you select may transfer and retain it under its own rules. The developer does not automatically receive the export.\n\n'
         'Deleting a session replaces its training and heart-rate contents in the app history with a technical deletion marker. Its identifier and deletion timestamp may remain to prevent reimporting an older copy from another device. Let your devices synchronize after deleting synchronized sessions. Copies on disconnected devices or in exported files remain until individually deleted. Removing local app data does not automatically delete separate backup files or copies on another device.'),
        ('Advertising, analytics and external services',
         'Easy Hof has no advertising or dedicated analytics/crash-tracking SDKs. The developer does not use training or heart-rate data for advertising or sell it.\n\n'
         'Google Play, Google Play services and Android/Wear OS may independently process technical operational and diagnostic data under their own settings and privacy notices, and may provide diagnostics through Google Play. Opening the store link launches Google Play or your browser without adding session data to the URL.\n\n'
         'This public policy and source code are hosted on GitHub. Visiting the GitHub page allows GitHub to process technical access data under its own privacy statement: https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement . The copy bundled with the app can be read offline.'),
        ('Your controls and policy updates',
         'You choose when to start training and whether to grant heart-rate permission. Manage permissions in system settings, delete sessions in the app and export history. Use the contact above for privacy questions.\n\n'
         'This policy is updated when data processing changes. The online policy describes the version indicated there; each app build includes its corresponding offline copy.'),
    ]),
}


def render():
    document = []
    for language, (title, sections) in POLICY.items():
        updated = 'Stand' if language == 'de' else 'Last updated'
        document.append(f'# {title}\n\n{updated}: {DATE}\n')
        lines = [title, f'{updated}: {DATE}', f'Online: {URL}', '']
        for number, (heading, body) in enumerate(sections, 1):
            document.append(f'## {number}. {heading}\n\n{body}\n')
            lines.extend([f'{number}. {heading}', '', body, ''])
        asset = Path(f'assets/privacy/privacy-{language}.txt')
        asset.parent.mkdir(parents=True, exist_ok=True)
        asset.write_text('\n'.join(lines), encoding='utf-8')
        document.append('\n---\n')
    Path('PRIVACY.md').write_text('\n'.join(document).rstrip() + '\n', encoding='utf-8')


if __name__ == '__main__':
    render()
