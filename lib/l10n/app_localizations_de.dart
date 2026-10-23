// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Vaktinde';

  @override
  String get navZikir => 'Dhikr';

  @override
  String get todayHubTitle => 'Für heute';

  @override
  String get todayQuranOpen => 'Den Heiligen Koran öffnen';

  @override
  String get todayFridayMessage => 'Freitagsgruß senden';

  @override
  String get a11yAlarmSettingsHint => 'Alarmeinstellungen öffnen';

  @override
  String get navQuran => 'Koran';

  @override
  String get showcaseQuran =>
      'Lesen Sie hier den Koran und machen Sie dort weiter, wo Sie aufgehört haben.';

  @override
  String zikirRound(int round) {
    return 'Runde $round';
  }

  @override
  String zikirProgress(int count, int target) {
    return '$count / $target';
  }

  @override
  String get zikirPrevious => 'Vorheriger Dhikr';

  @override
  String get zikirNext => 'Nächster Dhikr';

  @override
  String get zikirCountingSection => 'Zählen';

  @override
  String get zikirRoundMode => 'Am Ziel von vorn beginnen (Runden zählen)';

  @override
  String get zikirVolumeKeys => 'Mit den Lautstärketasten zählen';

  @override
  String get zikirVolumeKeysDesc =>
      'Lauter +1, leiser −1. Nur bei geöffnetem Dhikr-Bildschirm; die Systemlautstärke ändert sich nicht.';

  @override
  String get adPrivacySettings => 'Werbe-Datenschutzeinstellungen';

  @override
  String get adPrivacySettingsSub =>
      'Einwilligung für personalisierte Werbung ändern';

  @override
  String get showcaseLanguage =>
      'Hier können Sie die App-Sprache und weitere Einstellungen ändern.';

  @override
  String get showcaseStory =>
      'Hier lesen Sie den Vers und den Hadith des Tages.';

  @override
  String get showcaseAlarms =>
      'Hier stellen Sie Adhan- und Erinnerungsalarme für jede Gebetszeit ein.';

  @override
  String get showcaseQibla => 'Finden Sie die Qibla-Richtung mit dem Kompass.';

  @override
  String get showcaseZikir => 'Hier zählen Sie Ihren Dhikr.';

  @override
  String get showcaseTracker =>
      'Hier haken Sie Ihre verrichteten Gebete ab. An entschuldigten Tagen halten Sie „Heute“ gedrückt.';

  @override
  String get showcaseTools =>
      'Gebetskalender, Gebetsanleitung, Qada-Rechner und vieles mehr.';

  @override
  String get tipGotIt => 'Verstanden';

  @override
  String get tipTracker =>
      'An entschuldigten Tagen halten Sie den Tagesnamen gedrückt oder tippen auf das Blumensymbol in der Ecke der Karte; diese Tage unterbrechen Ihre Serie nicht. Mit „Versäumte Gebete zu Qada hinzufügen“ ganz unten übernehmen Sie versäumte Gebete in die Qada-Zähler.';

  @override
  String get tipZikir =>
      'Wischen Sie die Karte oben nach links oder rechts, um den Dhikr zu wechseln. Schalten Sie in den Einstellungen „Mit den Lautstärketasten zählen“ ein, um zu zählen, ohne auf den Bildschirm zu schauen.';

  @override
  String get tipQuranReader =>
      'Über „Ansicht“ oben wählen Sie Seite, Vers für Vers oder Übersetzung. Tippen Sie auf einer Seite auf einen Vers, um Übersetzung, Lesezeichen und Teilen zu öffnen.';

  @override
  String get tipAlarmsSilent =>
      'Damit Sie ihn auch bei lautlosem Telefon hören, schalten Sie „Auch im Lautlos-Modus abspielen“ ein.';

  @override
  String get tipWidget =>
      'Fügen Sie ein Vaktinde-Widget zum Startbildschirm hinzu, um die Gebetszeiten zu sehen, ohne die App zu öffnen.';

  @override
  String get tipWidgetAction => 'Widget hinzufügen';

  @override
  String get whatsNewTitle => 'Neuigkeiten';

  @override
  String get whatsNewQuranTitle => 'Koran im unteren Menü';

  @override
  String get whatsNewQuranDesc =>
      'Lesen Sie Seite für Seite wie im gedruckten Mushaf und machen Sie dort weiter, wo Sie aufgehört haben.';

  @override
  String get whatsNewWidgetsTitle => 'Neue Widgets';

  @override
  String get whatsNewWidgetsDesc =>
      'Gebetsring und Gebetstracker: Gebete abhaken, ohne die App zu öffnen.';

  @override
  String get whatsNewStopTitle => 'Adhan mit einem Tipp stoppen';

  @override
  String get whatsNewStopDesc =>
      'Während der Adhan läuft, beendet „Stoppen“ in der Benachrichtigung den Ton sofort.';

  @override
  String get appGuideTitle => 'App kennenlernen';

  @override
  String get appGuideSub => 'Alle Funktionen und ihre Bedienung';

  @override
  String get appGuideReplayTour => 'Einführung erneut ansehen';

  @override
  String get appGuideReplayTourSub =>
      'Die kurze Tour über den Startbildschirm neu starten';

  @override
  String get guideGroupTimes => 'Gebetszeiten & Alarme';

  @override
  String get guideGroupPrayer => 'Gebet';

  @override
  String get guideGroupQuran => 'Koran & Bittgebete';

  @override
  String get guideGroupWidgets => 'Widgets';

  @override
  String get guideLocation =>
      'Tippen Sie auf dem Startbildschirm auf den Ortsnamen; die Ortsliste funktioniert auch offline.';

  @override
  String get guideAlarms =>
      'Adhan, stille Benachrichtigung und Vorab-Erinnerung für jedes Gebet. Ein Tipp auf eine Gebetszeit auf dem Startbildschirm öffnet dies ebenfalls.';

  @override
  String get guideTracker =>
      'Haken Sie Ihre Gebete ab; „Gebetet“ in der Benachrichtigung tut das auch. An entschuldigten Tagen halten Sie den Tagesnamen gedrückt.';

  @override
  String get guideKaza =>
      'Führen Sie Ihre Qada-Zähler; der „Qada-Rechner“ schätzt sie aus der versäumten Zeit.';

  @override
  String get guideQibla =>
      'Halten Sie das Telefon flach; es vibriert, wenn Sie zur Qibla ausgerichtet sind.';

  @override
  String get guideZikir =>
      'Tippen Sie zum Zählen auf den Bildschirm und wischen Sie die Karte, um den Dhikr zu wechseln. Das Zählen mit den Lautstärketasten finden Sie in den Dhikr-Einstellungen.';

  @override
  String get guideQuran =>
      'Wählen Sie unter „Ansicht“ Seite, Vers für Vers oder Übersetzung; ein Tipp auf einen Vers öffnet Übersetzung, Lesezeichen und Teilen. Ihre Stelle wird automatisch gespeichert.';

  @override
  String get guideWidgets =>
      'Gebetszeiten, Countdown, Gebetsring, Ramadan und Gebetstracker (Gebet antippen zum Abhaken). Sie können sie auch hinzufügen, indem Sie eine freie Stelle auf dem Startbildschirm gedrückt halten und „Widgets“ wählen.';

  @override
  String get refreshLocation => 'Standort aktualisieren';

  @override
  String get countryTurkey => 'Türkei';

  @override
  String get locationEuropeKktc => 'Europa / Nordzypern';

  @override
  String get countryGermany => 'Deutschland';

  @override
  String get countryNetherlands => 'Niederlande';

  @override
  String get countryBelgium => 'Belgien';

  @override
  String get countryFrance => 'Frankreich';

  @override
  String get countryAustria => 'Österreich';

  @override
  String get countrySwitzerland => 'Schweiz';

  @override
  String get countryUnitedKingdom => 'Vereinigtes Königreich';

  @override
  String get countryDenmark => 'Dänemark';

  @override
  String get countrySweden => 'Schweden';

  @override
  String get countryNorway => 'Norwegen';

  @override
  String get countryNorthernCyprus => 'Nordzypern';

  @override
  String get provinceCenter => 'Provinzhauptstadt';

  @override
  String get searchOnline => 'Online suchen';

  @override
  String get timesFollowPhoneClock =>
      'Dieser Ort liegt in einer anderen Zeitzone: Die Zeiten werden nach der Uhrzeit Ihres Telefons angezeigt.';

  @override
  String get navTools => 'Werkzeuge';

  @override
  String a11yHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stunden',
      one: '1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String a11yMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Minuten',
      one: '1 Minute',
    );
    return '$_temp0';
  }

  @override
  String a11yHoursMinutes(String hours, String minutes) {
    return '$hours $minutes';
  }

  @override
  String a11yTimeUntil(String vakit, String duration) {
    return 'Noch $duration bis $vakit';
  }

  @override
  String get a11yPrayerPassed => 'vorbei';

  @override
  String a11yTrackerCell(String day, String prayer, String state) {
    return '$day, $prayer: $state';
  }

  @override
  String get a11yNotPrayed => 'Nicht verrichtet';

  @override
  String get a11yNotDue => 'Gebetszeit noch nicht begonnen';

  @override
  String get a11yExcusedDay => 'Entschuldigter Tag';

  @override
  String a11yQiblaTurnRight(int deg) {
    return 'Zur Qibla $deg Grad nach rechts drehen';
  }

  @override
  String a11yQiblaTurnLeft(int deg) {
    return 'Zur Qibla $deg Grad nach links drehen';
  }

  @override
  String get a11yQiblaAligned => 'Sie sind zur Qibla ausgerichtet';

  @override
  String get a11yDecrease => 'Verringern';

  @override
  String get a11yIncrease => 'Erhöhen';

  @override
  String a11yPlaySound(String sound) {
    return '$sound anhören';
  }

  @override
  String get a11yStopSound => 'Stoppen';

  @override
  String get hadithNotFound => 'Hadith-Text nicht gefunden.';

  @override
  String get timesLoadError =>
      'Gebetszeiten konnten nicht geladen werden. Bitte versuchen Sie es erneut.';

  @override
  String get sunriseNotPrayer => 'Sonnenaufgang, keine Gebetszeit';

  @override
  String get currentPrayer => 'Aktuelle Gebetszeit';

  @override
  String get textCopied => 'Text kopiert';

  @override
  String get updateDownloaded => 'Eine neue Version wurde heruntergeladen.';

  @override
  String get restartAction => 'Neu starten';

  @override
  String get qiblaTurnRight => 'Nach rechts drehen';

  @override
  String get qiblaTurnSlightRight => 'Etwas nach rechts drehen';

  @override
  String get qiblaTurnLeft => 'Nach links drehen';

  @override
  String get qiblaTurnSlightLeft => 'Etwas nach links drehen';

  @override
  String phoneHeading(String deg) {
    return 'Ausrichtung des Telefons: $deg°';
  }

  @override
  String get usingSavedLocation => 'Gespeicherter Standort wird verwendet.';

  @override
  String exampleHint(int n) {
    return 'Z. B. $n';
  }

  @override
  String get noCustomDhikr =>
      'Sie haben noch keinen eigenen Dhikr hinzugefügt.';

  @override
  String get messagesShuffled => 'Nachrichten gemischt';

  @override
  String get shareAsImage => 'Als Bild teilen';

  @override
  String get shareAsText => 'Text teilen';

  @override
  String get shareCardFooter => 'Vaktinde bei Google Play';

  @override
  String get fridayGreeting => 'Gesegneter Freitag';

  @override
  String get sendGreeting => 'Glückwünsche senden';

  @override
  String get greetingsTitle => 'Grußbotschaften';

  @override
  String get shuffle => 'Mischen';

  @override
  String get copy => 'Kopieren';

  @override
  String get messageCopied => 'Nachricht kopiert';

  @override
  String versionLabel(String v) {
    return 'Version $v';
  }

  @override
  String get supportMailSubject => 'Vaktinde - Support';

  @override
  String get madeBy => 'Mit ❤️ gemacht von mmdigital';

  @override
  String get permissionPrimingTitle => 'Verpassen Sie keine Gebetszeit';

  @override
  String get permissionPrimingBody =>
      'Für Adhan-Benachrichtigungen benötigen wir die Benachrichtigungsberechtigung und für die Gebetszeiten an Ihrem Ort die Standortberechtigung.';

  @override
  String get continueAction => 'Weiter';

  @override
  String get nextPrayer => 'Nächste Gebetszeit';

  @override
  String get hadithTitle => 'Hadith des Tages';

  @override
  String get share => 'Teilen';

  @override
  String get close => 'Schließen';

  @override
  String get loading => 'Zeiten werden berechnet...';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get noData => 'Keine Daten.';

  @override
  String get imsak => 'Imsak';

  @override
  String get gunes => 'Sonnenaufgang';

  @override
  String get ogle => 'Dhuhr';

  @override
  String get ikindi => 'Asr';

  @override
  String get aksam => 'Maghrib';

  @override
  String get yatsi => 'Ischa';

  @override
  String get exactAlarm => 'Pünktlich benachrichtigen';

  @override
  String get reminderTitleAt => 'Gebetszeit-Erinnerung';

  @override
  String notifBodyUpcomingAt(String vakit, String time) {
    return 'Beginn der $vakit-Zeit: $time';
  }

  @override
  String get endReminderTitleAt => 'Ende der Gebetszeit';

  @override
  String endReminderNotifBodyAt(String vakit, String time) {
    return 'Ende der $vakit-Zeit: $time';
  }

  @override
  String ramadanImsakBodyAt(String time) {
    return 'Die Suhur-Zeit endete um $time. Gesegnetes Fasten!';
  }

  @override
  String get alarmHealthExactOff =>
      'Ohne Wecker-Berechtigung können Adhan und Erinnerungen bis zu etwa einer Stunde zu spät kommen (auch Imsak und Suhur).';

  @override
  String get healthTitle => 'Benachrichtigungen prüfen';

  @override
  String get healthSub =>
      'Kein Adhan? Einstellungen Schritt für Schritt prüfen';

  @override
  String get healthSectionStatus => 'Status';

  @override
  String get healthEzansTitle => 'Adhan-Alarme';

  @override
  String healthEzansOn(String names) {
    return 'Aktiv: $names';
  }

  @override
  String get healthEzansNone => 'Der Adhan ist für keine Gebetszeit aktiviert.';

  @override
  String get healthNextTitle => 'Nächster Adhan';

  @override
  String get healthNextNone => 'Kein geplanter Adhan gefunden.';

  @override
  String get healthReschedule => 'Neu planen';

  @override
  String get healthNotificationsTitle => 'Benachrichtigungen';

  @override
  String get healthNotificationsOk => 'Aktiviert.';

  @override
  String get healthOpenSettings => 'Einstellungen öffnen';

  @override
  String get healthExactTitle => 'Wecker und Erinnerungen';

  @override
  String get healthExactOk => 'Erlaubt: Der Adhan ertönt pünktlich.';

  @override
  String get healthVolumeTitle => 'Ton';

  @override
  String get healthVolumeOk => 'Der Benachrichtigungston ist eingeschaltet.';

  @override
  String get healthVolumeAlarmOk => 'Der Weckerton ist eingeschaltet.';

  @override
  String get healthVolumeSilent =>
      'Ihr Telefon ist lautlos oder auf Vibration gestellt: Der Adhan ist nicht zu hören.';

  @override
  String get healthVolumeNotificationMuted =>
      'Der Benachrichtigungston ist ausgeschaltet: Der Adhan ist nicht zu hören.';

  @override
  String get healthVolumeAlarmMuted =>
      'Der Weckerton ist ausgeschaltet: Der Adhan ist nicht zu hören.';

  @override
  String healthAlarmStreamTip(String setting) {
    return 'Ist „$setting“ aktiviert, ertönt der Adhan in der Lautstärke des Weckers.';
  }

  @override
  String get healthDndTitle => 'Bitte nicht stören';

  @override
  String get healthDndOff => 'Aus.';

  @override
  String get healthDndOn =>
      'Aktiv: Der Adhan ist möglicherweise nicht zu hören.';

  @override
  String healthDndAlarm(String setting) {
    return 'Aktiv, aber dank „$setting“ ertönt der Adhan in der Lautstärke des Weckers.';
  }

  @override
  String get healthBatteryTitle => 'Akkunutzung';

  @override
  String get healthBatteryOk =>
      'Die Akkuoptimierung ist für Vaktinde deaktiviert.';

  @override
  String get healthBatteryOptimized =>
      'Die Akkuoptimierung ist aktiv: Ihr Telefon kann Vaktinde im Hintergrund beenden. Wählen Sie in den App-Einstellungen unter Akku „Uneingeschränkt“ (auf manchen Telefonen „Nicht eingeschränkt“ oder „Keine Beschränkungen“).';

  @override
  String get healthBackgroundTitle => 'Hintergrundaktivität';

  @override
  String healthBackgroundToday(String time) {
    return 'Zuletzt ausgeführt: heute um $time';
  }

  @override
  String healthBackgroundYesterday(String time) {
    return 'Zuletzt ausgeführt: gestern um $time';
  }

  @override
  String get healthBackgroundStale =>
      'Vaktinde lief in den letzten 48 Stunden nicht im Hintergrund: Ihr Telefon beendet die App möglicherweise.';

  @override
  String get healthWidgetTitle => 'Widgets und dauerhafte Benachrichtigung';

  @override
  String healthWidgetLate(int minutes) {
    return 'In den letzten 7 Tagen wurde der Countdown zur Gebetszeit $minutes Min. zu spät aktualisiert: Ihr Telefon hält Vaktinde im Hintergrund zurück. Stellen Sie den Akku auf „Uneingeschränkt“ und folgen Sie den Schritten unten.';
  }

  @override
  String get healthShowSteps => 'Schritte anzeigen';

  @override
  String healthGuideTitle(String brand) {
    return 'Einstellungen für $brand';
  }

  @override
  String get healthGuideTitleGeneric => 'Einstellungen für Ihr Telefon';

  @override
  String get healthGuideStale =>
      'Die Hintergrundaktivität scheint gestoppt zu sein. Damit der Adhan pünktlich ertönt, ändern Sie diese Einstellungen:';

  @override
  String get healthGuideMore =>
      'Ausführliche Anleitungen für Ihr Modell (auf Englisch)';

  @override
  String get healthTestTitle => 'Test-Adhan';

  @override
  String get healthTestInfo =>
      'Sie erhalten in 1 Minute eine Testbenachrichtigung mit demselben Ton und denselben Einstellungen wie beim echten Adhan.';

  @override
  String get healthTestButton => 'Test-Adhan in 1 Min.';

  @override
  String get healthTestScheduled =>
      'Der Test-Adhan ertönt in 1 Minute. Sie können die App schließen.';

  @override
  String get healthTestNotifBody =>
      'Wenn Sie diese Benachrichtigung sehen, funktionieren die Adhan-Benachrichtigungen.';

  @override
  String get healthStepXiaomiAutostart =>
      'Aktivieren Sie in den App-Einstellungen „Autostart“.';

  @override
  String get healthStepXiaomiBattery =>
      'Wählen Sie auf demselben Bildschirm unter Energiesparmodus (bzw. Akku) „Keine Beschränkungen“.';

  @override
  String get healthStepHuaweiLaunch =>
      'Öffnen Sie in den Einstellungen „App-Start“ (unter Akku oder Apps). Deaktivieren Sie für Vaktinde die automatische Verwaltung und lassen Sie im folgenden Fenster alle Optionen aktiviert.';

  @override
  String get healthStepOppoBackground =>
      'Erlauben Sie in den App-Einstellungen unter Akkunutzung die Hintergrundaktivität und den automatischen Start.';

  @override
  String get healthStepVivoBackground =>
      'Erlauben Sie unter Einstellungen > Akku für Vaktinde einen hohen Energieverbrauch im Hintergrund.';

  @override
  String healthStepAutostartIn(String app) {
    return 'Aktivieren Sie den Autostart für Vaktinde in den Einstellungen oder in der App $app.';
  }

  @override
  String get healthStepAppBattery =>
      'Wählen Sie in den App-Einstellungen unter Akku „Uneingeschränkt“ (bzw. „Nicht eingeschränkt“).';

  @override
  String get healthStepSamsungSleeping =>
      'Fügen Sie Vaktinde unter Einstellungen > Akku > Grenzen der Hintergrundnutzung zur Liste „Apps, die nie im Standby sind“ hinzu.';

  @override
  String get healthStepLockRecents =>
      'Sperren Sie Vaktinde in der Ansicht der zuletzt verwendeten Apps (falls Ihr Telefon diese Option bietet).';

  @override
  String get healthDetails => 'Details';

  @override
  String get alarmHealthExactAction => 'Erlauben';

  @override
  String get alarmHealthNotificationsOff =>
      'Benachrichtigungen sind aus, der Adhan ertönt nicht.';

  @override
  String get alarmHealthNotificationsAction => 'Aktivieren';

  @override
  String get ezanAlarmStreamTitle => 'Auch im Lautlos-Modus abspielen';

  @override
  String get ezanAlarmStreamSub =>
      'Der Adhan ertönt in der Lautstärke des Weckers, auch wenn das Telefon stumm ist.';

  @override
  String channelAlarmSound(String soundName) {
    return 'Ton: $soundName (auch lautlos)';
  }

  @override
  String get exactAlarmSub => 'Sendet eine Benachrichtigung.';

  @override
  String get silentNotif => 'Nur Textbenachrichtigung';

  @override
  String get silentNotifSub => 'Kein Adhan/Ton, nur visueller Alarm.';

  @override
  String warningAlarm(String minute) {
    return '$minute Min. vorher erinnern';
  }

  @override
  String get warningAlarmSub => 'Kurzer Benachrichtigungston.';

  @override
  String get settings => 'Einstellungen';

  @override
  String get changeLanguage => 'Sprache ändern';

  @override
  String get waitingLocation => 'Warte auf Standort...';

  @override
  String get noInternet =>
      'Keine Internetverbindung und keine gespeicherten Daten gefunden.';

  @override
  String get gpsOff => 'GPS ist aus. Bitte Standort aktivieren.';

  @override
  String get permissionDenied => 'Standortberechtigung verweigert.';

  @override
  String get locationError => 'Standort konnte nicht ermittelt werden.';

  @override
  String get internetNeeded => 'Internetverbindung ist erforderlich.';

  @override
  String get soundEzan => 'Adhan';

  @override
  String get soundBeep => 'Kurzer Piepton';

  @override
  String get notifTitleTime => 'Gebetszeit';

  @override
  String notifBodyTime(String vakit) {
    return 'Es ist Zeit für $vakit.';
  }

  @override
  String get notifTitleUpcoming => 'Gebetszeit naht';

  @override
  String notifBodyUpcoming(String vakit, int minute) {
    return 'Noch $minute Minuten bis $vakit.';
  }

  @override
  String get navPrayer => 'Startseite';

  @override
  String get navQibla => 'Qibla';

  @override
  String get menuTitle => 'Einstellungen';

  @override
  String get aboutAds => 'Über Werbung';

  @override
  String get adInfoTitle => 'Warum zeigt Vaktinde Werbung?';

  @override
  String get adInfoBody =>
      'Damit wir Vaktinde kostenlos und ohne Registrierung anbieten können, zeigen wir in der App eine begrenzte Anzahl von Anzeigen. Die Werbeeinnahmen helfen uns, die Kosten für die Entwicklung und Wartung der App zu decken.\n\nBeim Öffnen von Koran, Qibla, Dhikr-Zähler, Bittgebeten und Gebetsanleitung werden keine Vollbildanzeigen eingeblendet; auch auf den anderen Bildschirmen setzen wir Werbung nur sparsam ein.\n\nVielen Dank für Ihr Verständnis.';

  @override
  String get adInfoGotIt => 'Verstanden';

  @override
  String get sectionLocation => 'STANDORT & ZEITEN';

  @override
  String get changeLocation => 'Standort ändern';

  @override
  String get citySelect => 'Stadt auswählen';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get timeAdjustTitle => 'Gebetszeiten anpassen';

  @override
  String get tapToCount => 'Zum Zählen tippen';

  @override
  String get timeAdjustSub => 'Zeiten minutengenau korrigieren';

  @override
  String get timeAdjustInfo =>
      'Die Zeiten werden für Ihren Standort nach der Diyanet-Methode berechnet. Wenn sie leicht von den Zeiten Ihrer örtlichen Moschee abweichen, können Sie jede Zeit um einige Minuten vor- oder zurückstellen. Die Anpassung gilt für die Startseite, die Widgets und die Adhan-Benachrichtigungen.';

  @override
  String get timeAdjustReset => 'Zurücksetzen';

  @override
  String timeAdjustMinutes(String value) {
    return '$value Min.';
  }

  @override
  String get timeAdjustSaved => 'Gebetszeiten aktualisiert';

  @override
  String get trackerTitle => 'Gebetstracker';

  @override
  String get trackerExcusedTitle => 'Entschuldigte Tage (Menstruation)';

  @override
  String get trackerExcusedInfo =>
      'Gebete, die während der Menstruation oder der Wochenbettblutung ausfallen, müssen nicht nachgeholt werden. Als entschuldigt markierte Tage unterbrechen die Serie nicht und zählen weder zur Quote noch zu den Qada-Gebeten. An diesen Tagen ausgelassenes Ramadan-Fasten muss jedoch nachgeholt werden. Wenn Sie heute markieren, beginnt eine entschuldigte Zeit: Die folgenden Tage werden automatisch markiert (höchstens 10 Tage); entfernen Sie die Markierung von heute, wenn sie endet. Um einen vergangenen Tag zu markieren oder die Markierung zu entfernen, halten Sie den Namen des Tages gedrückt.';

  @override
  String get trackerExcusedToday => 'Heute als entschuldigt markieren';

  @override
  String get trackerExcusedMark => 'Als entschuldigt markieren';

  @override
  String get trackerExcusedUnmark => 'Markierung „entschuldigt“ entfernen';

  @override
  String get trackerExcusedMarked => 'Als entschuldigt markiert.';

  @override
  String get notifStopAction => 'Stoppen';

  @override
  String get trackerExcusedPeriodStarted =>
      'Entschuldigte Zeit begonnen; die folgenden Tage werden automatisch markiert (höchstens 10 Tage). Wenn sie endet, halten Sie „Heute“ erneut gedrückt.';

  @override
  String get trackerExcusedPeriodEnded => 'Entschuldigte Zeit beendet.';

  @override
  String get excusedSilentEzanTitle => 'Adhan an entschuldigten Tagen stumm';

  @override
  String get excusedSilentEzanSub =>
      'An entschuldigten Tagen kommen Gebetszeit-Benachrichtigungen ohne Ton; Erinnerungen entfallen.';

  @override
  String get trackerExcusedUnmarked => 'Markierung „entschuldigt“ entfernt.';

  @override
  String get trackerExcusedCellSnack =>
      'Dieser Tag ist als entschuldigt markiert, seine Gebete werden nicht gezählt. Um die Markierung zu entfernen, halten Sie den Namen des Tages gedrückt.';

  @override
  String trackerExcusedKazaConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count zu Qada hinzugefügte Gebete dieses Tages werden von den Qada-Zählern abgezogen.',
      one:
          '1 zu Qada hinzugefügtes Gebet dieses Tages wird von den Qada-Zählern abgezogen.',
    );
    return '$_temp0';
  }

  @override
  String get trackerLegendExcused => 'Entschuldigt (Tag gedrückt halten)';

  @override
  String get fastLegendExcused => 'Entschuldigt (wird nachgeholt)';

  @override
  String get trackerToday => 'Heute';

  @override
  String get trackerYesterday => 'Gestern';

  @override
  String get trackerPrayedAction => 'Gebetet';

  @override
  String get trackerLast7Days => 'Letzte 7 Tage';

  @override
  String get trackerCompletion => '30-Tage-Quote';

  @override
  String get trackerStreak => 'Serie';

  @override
  String trackerStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get trackerNotYet => 'Diese Gebetszeit hat noch nicht begonnen.';

  @override
  String get trackerKazaButton => 'Versäumte Gebete zu Qada hinzufügen';

  @override
  String get trackerKazaInfo =>
      'Nicht markierte Gebete der letzten 30 Tage (ab Beginn der Erfassung) werden zu den Qada-Zählern hinzugefügt. Jedes Gebet wird nur einmal hinzugefügt. Wenn Sie ein zu Qada hinzugefügtes Gebet verrichtet haben, tippen Sie darauf: Es wird als verrichtet markiert und vom Qada-Zähler abgezogen.';

  @override
  String trackerKazaConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count nicht markierte Gebete werden zu den Qada-Zählern hinzugefügt. Fortfahren?',
      one:
          '1 nicht markiertes Gebet wird zu den Qada-Zählern hinzugefügt. Fortfahren?',
    );
    return '$_temp0';
  }

  @override
  String get trackerKazaAdd => 'Hinzufügen';

  @override
  String trackerKazaDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Gebete zu Qada hinzugefügt.',
      one: '1 Gebet zu Qada hinzugefügt.',
    );
    return '$_temp0';
  }

  @override
  String get trackerKazaNone => 'Keine Gebete zum Hinzufügen.';

  @override
  String get trackerKazaRemoveTitle => 'Aus Qada entfernen?';

  @override
  String trackerKazaRemoveConfirm(String name, int from, int to) {
    return 'Dieses Gebet wird als verrichtet markiert und die Qada-Anzahl für $name ändert sich von $from auf $to.';
  }

  @override
  String get addWidgetTitle => 'Widget zum Startbildschirm hinzufügen';

  @override
  String get addWidgetSub => 'Gebetszeiten sehen, ohne die App zu öffnen';

  @override
  String get addWidgetHint =>
      'Wählen Sie ein Widget aus – Ihr Startbildschirm fragt dann nach einer Bestätigung.';

  @override
  String get widgetRingName => 'Gebetsring';

  @override
  String get widgetRingDesc =>
      'Quadrat: verbleibende Zeit bis zum nächsten Gebet; der Ring zeigt die seit dem vorherigen vergangene Zeit';

  @override
  String get widgetTrackerName => 'Gebetstracker';

  @override
  String get widgetTrackerDesc =>
      'Breiter Streifen: die fünf Gebete von heute; zum Markieren als verrichtet antippen';

  @override
  String get widgetLargeName => 'Heutige Gebetszeiten';

  @override
  String get widgetLargeDesc =>
      'Großes Format: Standort, islamisches Datum, heutige Gebetszeiten und verbleibende Zeit';

  @override
  String get widgetWideName => 'Nächste Gebetszeit';

  @override
  String get widgetWideDesc =>
      'Breiter Streifen: Standort, islamisches Datum und verbleibende Zeit bis zum nächsten Gebet';

  @override
  String get widgetSmallName => 'Gebets-Countdown';

  @override
  String get widgetSmallDesc =>
      'Kleines Quadrat: verbleibende Zeit bis zum nächsten Gebet';

  @override
  String get trackerLegendPrayed => 'Verrichtet';

  @override
  String get trackerLegendKaza => 'Zu Qada hinzugefügt';

  @override
  String kerahatActive(String range) {
    return 'Jetzt Makruh-Zeit: $range';
  }

  @override
  String kerahatUpcoming(String range) {
    return 'Bald Makruh-Zeit: $range';
  }

  @override
  String get endReminderTitle => 'Vor Ende der Gebetszeit erinnern';

  @override
  String get dailyContentNotifTitle =>
      'Benachrichtigungen für Vers und Hadith des Tages';

  @override
  String get persistentNotifTitle => 'Dauerhafte Benachrichtigung';

  @override
  String get persistentNotifSub =>
      'Zeigt in der Benachrichtigungsleiste die verbleibende Zeit bis zum nächsten Gebet.';

  @override
  String get dailyContentNotifSub =>
      'Sendet jeden Morgen einen Vers und jeden Abend einen Hadith.';

  @override
  String get religiousDaysNotifTitle => 'Benachrichtigungen für religiöse Tage';

  @override
  String get religiousDaysNotifSub =>
      'Erinnert morgens an gesegnete Nächte, Feste und andere religiöse Tage.';

  @override
  String get fridayNotifTitle => 'Freitagsbenachrichtigung';

  @override
  String get fridayNotifSub =>
      'Erinnert freitagmorgens an die Sure Al-Kahf und an Freitagsgrüße.';

  @override
  String get fridayNotifBody =>
      'Vergessen Sie nicht, die Sure Al-Kahf zu lesen und Ihren Liebsten einen Freitagsgruß zu senden.';

  @override
  String get fridayKehfAction => 'Sure Al-Kahf';

  @override
  String get religiousDaysChannel => 'Religiöse Tage und gesegnete Nächte';

  @override
  String get ucAylarBaslangici => 'Beginn der drei heiligen Monate';

  @override
  String get ramazanArefesi => 'Letzter Tag des Ramadan';

  @override
  String get kurbanArefesi => 'Arafat-Tag';

  @override
  String get ucAylarNotifBody =>
      'Heute beginnen die drei heiligen Monate Radschab, Schaban und Ramadan. Mögen sie Ihnen viel Segen bringen.';

  @override
  String get ucAylarRegaipTitle =>
      'Drei heilige Monate und Lailat al-Ragha\'ib';

  @override
  String get ucAylarRegaipNotifBody =>
      'Heute beginnen die drei heiligen Monate, und heute Nacht ist Lailat al-Ragha\'ib. Eine gesegnete Nacht und gesegnete Monate!';

  @override
  String get regaipKandiliNotifBody =>
      'Heute Nacht ist Lailat al-Ragha\'ib. Eine gesegnete Nacht!';

  @override
  String get miracKandiliNotifBody =>
      'Heute ist die Nacht von Isra und Mi\'radsch. Eine gesegnete Nacht!';

  @override
  String get beratKandiliNotifBody =>
      'Heute Nacht ist Lailat al-Bara\'a. Eine gesegnete Nacht!';

  @override
  String get mevlidKandiliNotifBody =>
      'Heute Nacht ist Mawlid an-Nabi. Eine gesegnete Nacht!';

  @override
  String get kadirGecesiNotifBody =>
      'Heute Nacht ist Lailat al-Qadr. Eine gesegnete Nacht!';

  @override
  String get ramazanBaslangiciNotifBody =>
      'Morgen beginnt der Ramadan. Heute Nacht finden das erste Tarawih-Gebet und der erste Suhur statt. Gesegneten Ramadan!';

  @override
  String get ramazanArefesiNotifBody =>
      'Morgen ist Eid al-Fitr (Zuckerfest). Schon jetzt ein gesegnetes Fest!';

  @override
  String get ramazanBayramiNotifBody =>
      'Gesegnetes Fest! Möge Allah unser Fasten und unsere Gebete annehmen.';

  @override
  String get kurbanArefesiNotifBody =>
      'Morgen ist Eid al-Adha (Opferfest). Schon jetzt ein gesegnetes Fest!';

  @override
  String get kurbanBayramiNotifBody =>
      'Gesegnetes Opferfest! Möge Allah Ihre Opfer und guten Taten annehmen.';

  @override
  String get hicriYilbasiNotifBody =>
      'Heute ist das islamische Neujahr. Möge es Ihnen Gutes und Segen bringen.';

  @override
  String get asureGunuNotifBody =>
      'Heute ist der Aschura-Tag. Möge er Ihnen Gutes und Segen bringen.';

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get endReminderSub =>
      'Benachrichtigt vor dem Ende der Zeit eines nicht als verrichtet markierten Gebets.';

  @override
  String get endReminderNotifTitle => 'Gebetszeit endet bald';

  @override
  String endReminderNotifBody(String vakit, int minute) {
    return 'Noch $minute Minuten bis zum Ende der $vakit-Zeit.';
  }

  @override
  String get endReminderChannel => 'Erinnerungen vor Ende der Gebetszeit';

  @override
  String get ramadanIftarTitle => 'Iftar-Zeit';

  @override
  String ramadanIftarBody(String vakit) {
    return 'Die $vakit-Zeit hat begonnen. Gesegnetes Iftar!';
  }

  @override
  String get ramadanImsakTitle => 'Imsak-Zeit';

  @override
  String get ramadanImsakBody =>
      'Die Suhur-Zeit ist vorbei. Gesegnetes Fasten!';

  @override
  String get sectionSupport => 'SUPPORT';

  @override
  String get shareApp => 'Mit Freunden teilen';

  @override
  String get rateApp => 'Bewerten Sie uns';

  @override
  String get contactUs => 'Kontakt & Fehler melden';

  @override
  String shareText(String link) {
    return 'Ich habe eine tolle Gebetszeiten-App gefunden! Hier herunterladen: $link';
  }

  @override
  String get okUnderstood => 'OK, verstanden';

  @override
  String get religiousDaysTitle => 'Religiöse Tage';

  @override
  String get noDataFound => 'Keine Daten gefunden.';

  @override
  String noDataForYear(int year) {
    return 'Keine Daten für das Jahr $year gefunden.';
  }

  @override
  String religiousDaysListTitle(int year) {
    return 'Religiöse Tage $year';
  }

  @override
  String get missedPrayersTitle => 'Qada-Tracker';

  @override
  String get kazaCalcTitle => 'Qada-Rechner';

  @override
  String get kazaCalcSubtitle => 'Qada aus der Zeit ohne Gebet schätzen';

  @override
  String get kazaCalcPeriod => 'Zeit ohne Gebet';

  @override
  String get kazaCalcYears => 'Jahre';

  @override
  String get kazaCalcMonths => 'Monate';

  @override
  String get kazaCalcOptional => 'Optional';

  @override
  String get kazaCalcExcused => 'Menstruationstage pro Monat (Durchschnitt)';

  @override
  String get kazaCalcRamadans => 'Nicht gefastete Ramadan-Monate';

  @override
  String get kazaCalcOptionalInfo =>
      'Gebete, die während der Menstruation ausfallen, müssen nicht nachgeholt werden; diese Tage werden von den Gebeten abgezogen. Beim Fasten wird nichts abgezogen: Auch während der Menstruation ausgelassenes Ramadan-Fasten muss nachgeholt werden. Jeder Ramadan zählt als 30 Tage.';

  @override
  String get kazaCalcResult => 'Geschätztes Qada';

  @override
  String get kazaCalcEachPrayer => 'Jedes Gebet und Witr';

  @override
  String get kazaCalcNote =>
      'Dies ist eine Schätzung (ein Jahr zählt 365, ein Monat 30 Tage). Für eine verbindliche Auskunft wenden Sie sich an einen Imam oder Religionsgelehrten.';

  @override
  String get kazaCalcAdd => 'Zu den Qada-Zählern hinzufügen';

  @override
  String get kazaCalcConfirmTitle => 'Zu den Qada-Zählern hinzufügen?';

  @override
  String kazaCalcConfirm(int prayers, int fasts) {
    return 'Jedes Gebet und Witr: +$prayers\nFasten: +$fasts\n\nDie Werte werden zu den bisherigen Zahlen addiert; nichts wird überschrieben.';
  }

  @override
  String get kazaCalcAdded => 'Schätzung zu den Qada-Zählern hinzugefügt.';

  @override
  String get missedPrayersInfo =>
      'Notieren Sie hier verpasste Gebete und ziehen Sie diese nach dem Nachholen ab.\n(Tippen Sie auf die Zahl zur manuellen Eingabe)';

  @override
  String editMissedTitle(String title) {
    return 'Qada für $title bearbeiten';
  }

  @override
  String get missedCountLabel => 'Qada-Anzahl';

  @override
  String get missedCountHint => 'Z. B. 150';

  @override
  String get sabah => 'Fajr';

  @override
  String get vitir => 'Witr';

  @override
  String get oruc => 'Fasten';

  @override
  String timeLeftFor(String vakit) {
    return 'Verbleibende Zeit bis $vakit';
  }

  @override
  String get tomorrow => '(Morgen)';

  @override
  String get fridayMessagesTitle => 'Freitagsgrüße';

  @override
  String get esmaulHusnaTitle => 'Namen Allahs';

  @override
  String get zakatTitle => 'Zakat-Rechner';

  @override
  String get fitreTitle => 'Fitra & Fidya';

  @override
  String get toolFitreDesc => 'Fitra und Fidya berechnen';

  @override
  String get trackerTabTrack => 'Gebete';

  @override
  String get trackerTabKaza => 'Qada';

  @override
  String get trackerBadgesTitle => 'Ziele';

  @override
  String trackerBadgeEarned(String date) {
    return 'Erreicht · $date';
  }

  @override
  String trackerBadgeSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Glückwunsch! Sie haben Ihr Serienziel von $count Tagen erreicht.',
    );
    return '$_temp0';
  }

  @override
  String get fitreInfo =>
      'Der Betrag pro Person ist die von Diyanet, der türkischen Religionsbehörde, festgelegte Mindest-Fitra (Sadaqat al-Fitr); die Fitra kann als Geld oder in Form von Lebensmitteln gegeben werden. Fidya zahlen Menschen, die wegen hohen Alters oder einer Krankheit ohne Aussicht auf Heilung nicht fasten können: eine Fitra für jeden Tag. Wenn Sie außerhalb der Türkei leben, können Sie den dort geltenden Betrag eingeben.';

  @override
  String get fitreAmountLabel => 'Betrag pro Person';

  @override
  String fitreSource(String source, String year) {
    return 'Quelle: $source, $year';
  }

  @override
  String get fitreResetAmount => 'Standardbetrag wiederherstellen';

  @override
  String get fitreSectionTitle => 'Fitra';

  @override
  String get fitrePeopleLabel => 'Anzahl der Personen';

  @override
  String get fidyeSectionTitle => 'Fidya';

  @override
  String get fidyeDaysLabel => 'Anzahl der Tage';

  @override
  String get fitreTotal => 'Gesamt';

  @override
  String get fastTitle => 'Ramadan-Fasten';

  @override
  String fastCount(int done, int total) {
    return '$done/$total Tage';
  }

  @override
  String get fastInfo =>
      'Tippen Sie auf die Tage, an denen Sie gefastet haben. Versäumte Tage werden einmal zum Qada-Fastenzähler hinzugefügt; wenn Sie einen zu Qada hinzugefügten Tag doch gefastet haben, tippen Sie darauf, dann wird er vom Zähler abgezogen.';

  @override
  String get fastLegendFasted => 'Gefastet';

  @override
  String get fastLegendKaza => 'Zu Qada hinzugefügt';

  @override
  String get fastKazaButton => 'Versäumte Fastentage zu Qada hinzufügen';

  @override
  String fastKazaConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count nicht markierte Tage werden zum Qada-Fastenzähler hinzugefügt. Fortfahren?',
      one:
          '1 nicht markierter Tag wird zum Qada-Fastenzähler hinzugefügt. Fortfahren?',
    );
    return '$_temp0';
  }

  @override
  String fastKazaDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage zu Qada hinzugefügt.',
      one: '1 Tag zu Qada hinzugefügt.',
    );
    return '$_temp0';
  }

  @override
  String get fastKazaNone => 'Keine Tage zum Hinzufügen.';

  @override
  String get fastKazaRemoveTitle => 'Aus Qada entfernen?';

  @override
  String fastKazaRemoveConfirm(int from, int to) {
    return 'Dieser Tag wird als gefastet markiert und die Anzahl der Qada-Fastentage ändert sich von $from auf $to.';
  }

  @override
  String get fastFastedAction => 'Gefastet';

  @override
  String get zakatCalculatorTitle => 'Smarter Zakat-Rechner';

  @override
  String get liveRatesLoading => 'Aktuelle Wechselkurse werden abgerufen...';

  @override
  String get liveRatesInfo =>
      'Sie können die automatisch abgerufenen Kurse bei Bedarf manuell bearbeiten.';

  @override
  String get goldType => 'Goldart';

  @override
  String get goldAmount => 'Menge / Gramm';

  @override
  String get goldUnitPrice => 'Einzelpreis';

  @override
  String get currencyType => 'Währungsart';

  @override
  String get currencyAmount => 'Betrag';

  @override
  String get currencyRate => 'Aktueller Kurs';

  @override
  String get calculateButton => 'BERECHNEN';

  @override
  String get zakatResultTitle => 'Ihre zu zahlende Zakat';

  @override
  String get netAssets => 'Nettovermögen:';

  @override
  String get qiblaTitle => 'Qibla-Kompass';

  @override
  String get locationServiceOff =>
      'Ortungsdienst ist aus. Bitte Standort aktivieren.';

  @override
  String get locationPermissionDenied => 'Standortberechtigung verweigert.';

  @override
  String get noCompass => 'Kein Kompass auf diesem Gerät.';

  @override
  String get qiblaFound => 'SIE HABEN DIE QIBLA GEFUNDEN!';

  @override
  String qiblaAngle(String angle) {
    return 'Qibla-Winkel: $angle°';
  }

  @override
  String get keepAwayMetal => 'Von Metallgegenständen fernhalten.';

  @override
  String get goldGram => 'Gramm Gold (24 Karat)';

  @override
  String get goldQuarter => 'Viertel-Goldmünze (Çeyrek)';

  @override
  String get goldFull => 'Ganze Goldmünze (Tam)';

  @override
  String get typeOther => 'Andere (manuell)';

  @override
  String get usd => 'US-Dollar (USD)';

  @override
  String get eur => 'Euro (EUR)';

  @override
  String get gbp => 'Britisches Pfund (GBP)';

  @override
  String get sectionAppearance => 'DARSTELLUNG & SPRACHE';

  @override
  String get appearanceSettings => 'Darstellungseinstellungen';

  @override
  String get appearanceSub => 'Theme, Hintergrund und Schriftgröße';

  @override
  String get textSizeTitle => 'Schriftgröße';

  @override
  String get textSizeNormal => 'Normal';

  @override
  String get textSizeLarge => 'Groß';

  @override
  String get textSizeExtraLarge => 'Sehr groß';

  @override
  String get whatsNewTextSizeDesc =>
      'Vergrößern Sie die Schrift direkt in der App.';

  @override
  String get sectionNotifications => 'BENACHRICHTIGUNGEN';

  @override
  String get notificationSettingsTitle => 'Benachrichtigungen';

  @override
  String get notificationSettingsSub =>
      'Erinnerungen, Vers des Tages, gesegnete Nächte, Freitag, dauerhafte Benachrichtigung';

  @override
  String get ezanAlarmsTitle => 'Adhan-Alarme';

  @override
  String get ezanAlarmsSub => 'Adhan-Ton und Vorab-Erinnerung für jedes Gebet';

  @override
  String get privacyAdsTitle => 'Datenschutz & Werbung';

  @override
  String get privacyAdsSub => 'Datenschutzerklärung und Infos zur Werbung';

  @override
  String get privacyAdsConsentSub =>
      'Werbe-Datenschutzeinstellungen und Datenschutzerklärung';

  @override
  String get themeMode => 'Theme-Modus';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get bgImage => 'Hintergrundbild';

  @override
  String get bgDefault => 'Standard';

  @override
  String get bgPlain => 'Schlicht';

  @override
  String get bgMosque => 'Moschee';

  @override
  String get bgKaaba => 'Kaaba';

  @override
  String get zakatEligible => 'Zakat ist fällig';

  @override
  String get zakatNotEligible => 'Keine Zakat fällig';

  @override
  String get nisabLimit => 'Nisab-Grenze (80,18 g Gold)';

  @override
  String get belowNisabMessage =>
      'Da Ihr Nettovermögen unter dem Nisab-Betrag (Reichtumsgrenze) liegt, ist Zakat nicht obligatorisch.';

  @override
  String get searchLocationTitle => 'Standort suchen (weltweit)';

  @override
  String get searchLocationHint => 'Stadt oder Land (z. B. Paris)';

  @override
  String get searchInitial => 'Geben Sie den gesuchten Ort ein...';

  @override
  String get searchNotFound => 'Standort nicht gefunden.';

  @override
  String get searchError =>
      'Keine Ergebnisse gefunden. Bitte versuchen Sie es erneut.';

  @override
  String locationSelected(String city) {
    return '$city ausgewählt';
  }

  @override
  String channelSoundPrefix(String soundName) {
    return 'Ton: $soundName';
  }

  @override
  String get channelSilentPrayers => 'Stille Adhan-Benachrichtigungen';

  @override
  String get tickerEzan => 'Gebetszeit';

  @override
  String get fetchingLocation => 'Standort wird abgerufen...';

  @override
  String get directionNorth => 'N';

  @override
  String get directionSouth => 'S';

  @override
  String get directionEast => 'O';

  @override
  String get directionWest => 'W';

  @override
  String get zakatDescription =>
      'Berechnen Sie Ihre Zakat detailliert gemäß den Fatwas der Diyanet und aktuellen Marktpreisen.';

  @override
  String get cashAndCurrencyTitle => 'Bargeld und Devisen';

  @override
  String get goldAndSilverTitle => 'Gold und Silber';

  @override
  String get silverGram => 'Silber (Gramm)';

  @override
  String get unitPrice => 'Einzelpreis';

  @override
  String get commercialGoodsTitle => 'Handelsgüter';

  @override
  String get commercialEvalCurrency => 'Bewertungswährung';

  @override
  String get commercialGoodsValue => 'Warenwert';

  @override
  String get exchangeRateValue => 'Wechselkurs';

  @override
  String get receivablesTitle => 'Einbringliche Forderungen';

  @override
  String get receivableType => 'Forderungsart (TL, Devisen, Gold)';

  @override
  String get amountOrCount => 'Betrag / Menge';

  @override
  String get otherAssetsTitle => 'Sonstige Vermögenswerte';

  @override
  String get assetType => 'Art des Vermögenswerts';

  @override
  String get currencyLabel => 'Währung';

  @override
  String get valueOrAmount => 'Wert / Betrag';

  @override
  String get agriProductsTitle => 'Landwirtschaftliche Produkte (Uschr)';

  @override
  String get agriDiyanetNote =>
      'Da für landwirtschaftliche Produkte kein Nisab erforderlich ist, wird der angegebene Betrag direkt zur Zakat-Gesamtsumme hinzugefügt.';

  @override
  String get harvestedProductValue => 'Wert der geernteten Produkte';

  @override
  String get irrigationMethod => 'Bewässerungsmethode';

  @override
  String get debtsTitle => 'Schulden (werden abgezogen)';

  @override
  String get debtType => 'Schuldenart (TL, Devisen, Gold)';

  @override
  String get zakatAgriIncluded =>
      'Einschließlich Zakat auf landwirtschaftliche Produkte (Uschr)';

  @override
  String get assetCheck => 'Scheck';

  @override
  String get assetBond => 'Schuldschein';

  @override
  String get assetSukuk => 'Sukuk';

  @override
  String get assetLeaseCert => 'Leasing-Zertifikat';

  @override
  String get assetStock => 'Aktien';

  @override
  String get agriSoil => 'Landwirtschaft (Boden)';

  @override
  String get agriSoilless => 'Landwirtschaft (erdlos)';

  @override
  String get agriRateNoCost => 'Ohne Kosten (Regen/Fluss) - 10%';

  @override
  String get agriRateCostly => 'Mit Kosten (Motor/Transport) - 5%';

  @override
  String get toImsak => 'Bis Imsak';

  @override
  String get toGunes => 'Bis Sonnenaufgang';

  @override
  String get toOgle => 'Bis Dhuhr';

  @override
  String get toIkindi => 'Bis Asr';

  @override
  String get toAksam => 'Bis Maghrib';

  @override
  String get toYatsi => 'Bis Ischa';

  @override
  String get lowAccuracyWarning =>
      'Der Kompass ist ungenau kalibriert. Bitte zeichnen Sie mit dem Telefon eine \'8\' in die Luft.';

  @override
  String get qiblaDirection => 'Qibla-Richtung';

  @override
  String get zikirmatikTitle => 'Dhikr-Zähler';

  @override
  String get targetReached => 'Ziel erreicht!';

  @override
  String get resetCounter => 'Zurücksetzen';

  @override
  String targetCount(int target) {
    return 'Ziel: $target';
  }

  @override
  String get setTarget => 'Ziel festlegen';

  @override
  String get dhikrOther => 'Eigene Dhikr';

  @override
  String get customDhikrHint => 'Geben Sie Ihren Dhikr ein';

  @override
  String get zikirSettings => 'Einstellungen';

  @override
  String get vibration => 'Vibration';

  @override
  String get sound => 'Soundeffekt';

  @override
  String get keepAwake => 'Bildschirm wach halten';

  @override
  String get appearance => 'Darstellung';

  @override
  String get themeModern => 'Moderner Button';

  @override
  String get themeClassic => 'Klassischer Tasbih';

  @override
  String get dhikrListTitle => 'Dhikr-Liste';

  @override
  String get addCustomDhikr => 'Eigenen Dhikr hinzufügen';

  @override
  String get customDhikrAdded => 'Dhikr erfolgreich hinzugefügt.';

  @override
  String get customDhikrLimit =>
      'Sie können maximal 20 eigene Dhikrs hinzufügen!';

  @override
  String get deleteDhikr => 'Löschen';

  @override
  String get dhikrInfo => 'Bedeutung und Quelle';

  @override
  String get statisticsTitle => 'Statistiken';

  @override
  String zikirTodayCount(int count) {
    return 'Heute: $count';
  }

  @override
  String get monthly => 'Monatlich';

  @override
  String get yearly => 'Jährlich';

  @override
  String get totalDhikr => 'Dhikr insgesamt';

  @override
  String get today => 'Heute';

  @override
  String get statsEmpty => 'Noch keine Dhikr-Daten.';

  @override
  String get dhikrYaAllah => 'Ya Allah (J.J.)';

  @override
  String get dhikrYaRahman => 'Ya Rahman (J.J.)';

  @override
  String get dhikrYaRahim => 'Ya Rahim (J.J.)';

  @override
  String get dhikrYaSafi => 'Ya Shafi (J.J.)';

  @override
  String get dhikrYaRezzak => 'Ya Razzaq (J.J.)';

  @override
  String get dhikrYaFettah => 'Ya Fattah (J.J.)';

  @override
  String get mainDhikrs => 'Basis-Dhikr';

  @override
  String get esmaulHusnaTab => 'Namen Allahs';

  @override
  String get qiblaCalibration =>
      'Für eine genaue Kompassfunktion zeichnen Sie mit dem Telefon eine \'8\' in die Luft.';

  @override
  String get hicriYilbasi => 'Islamisches Neujahr';

  @override
  String get asureGunu => 'Aschura-Tag';

  @override
  String get mevlidKandili => 'Mawlid an-Nabi';

  @override
  String get miracKandili => 'Isra und Mi\'radsch';

  @override
  String get beratKandili => 'Lailat al-Bara\'a';

  @override
  String get ramazanBaslangici => 'Beginn des Ramadan';

  @override
  String get kadirGecesi => 'Lailat al-Qadr';

  @override
  String get ramazanBayrami => 'Eid al-Fitr (Zuckerfest)';

  @override
  String get kurbanBayrami => 'Eid al-Adha (Opferfest)';

  @override
  String get regaipKandili => 'Lailat al-Ragha\'ib';

  @override
  String get tabTimes => 'Zeiten';

  @override
  String get tabAlarms => 'Alarme';

  @override
  String get locationFoundNoName => 'Standort gefunden, aber ohne Ortsnamen.';

  @override
  String get dailyAyahTitle => 'Vers des Tages';

  @override
  String get onboardingWelcome => 'Hoş Geldiniz / Willkommen';

  @override
  String get onboardingSelectLanguage =>
      'Lütfen kullanmak istediğiniz dili seçin.\nBitte wählen Sie Ihre bevorzugte Sprache.';

  @override
  String get calibrationRequired => 'Kalibrierung erforderlich';

  @override
  String get qiblaAccuracyNote =>
      'Der Kompass zeigt die Richtung nur ungefähr an; Metall, Magnete und elektronische Geräte können ihn ablenken.';

  @override
  String get qiblaTipsTitle => 'Für ein genaues Ergebnis';

  @override
  String get qiblaTipFlat => 'Halten Sie das Telefon waagerecht.';

  @override
  String get qiblaTipCalibrate =>
      'Kalibrieren Sie den Kompass, indem Sie mit dem Telefon eine \'8\' in die Luft zeichnen.';

  @override
  String get qiblaTipMagneticCase =>
      'Entfernen Sie eine magnetische Hülle, falls vorhanden.';

  @override
  String get qiblaTipMetal =>
      'Halten Sie Abstand zu Metallgegenständen und elektronischen Geräten.';

  @override
  String get qiblaTipMosque =>
      'Vergleichen Sie nach Möglichkeit mit der Qibla-Richtung einer Moschee.';

  @override
  String qiblaAngleTrueNorth(String angle) {
    return 'Qibla-Winkel: $angle° (bezogen auf geografisch Nord)';
  }

  @override
  String qiblaDeclination(String deg) {
    return 'Magnetische Deklination: $deg° (automatisch korrigiert)';
  }

  @override
  String get qiblaInterferenceWarning =>
      'Magnetische Störung erkannt: Halten Sie das Telefon von Metallgegenständen, magnetischen Hüllen und elektronischen Geräten fern.';

  @override
  String get gold22kGram => 'Gramm Gold (22 Karat)';

  @override
  String get goldAtaToptan => 'Ata Großhandel';

  @override
  String get goldAtaCumhuriyet => 'Ata Cumhuriyet';

  @override
  String get gold22kBracelet => '22 Karat Armband';

  @override
  String get gold18k => '18 Karat Gold';

  @override
  String get gold14k => '14 Karat Gold';

  @override
  String get goldHalf => 'Halbe Goldmünze (Yarım)';

  @override
  String get goldGremse => 'Gremse-Gold';

  @override
  String get goldAtaBesli => 'Ata Beşli';

  @override
  String get goldResat => 'Reşat-Gold';

  @override
  String get goldHamit => 'Hamit-Gold';

  @override
  String get currencyChf => 'Schweizer Franken';

  @override
  String get currencyJpy => 'Japanischer Yen';

  @override
  String get currencySar => 'Saudi-Riyal';

  @override
  String get currencyAud => 'Australischer Dollar';

  @override
  String get currencyCad => 'Kanadischer Dollar';

  @override
  String get currencyRub => 'Russischer Rubel';

  @override
  String get currencyAzn => 'Aserbaidschan-Manat';

  @override
  String get currencyCny => 'Chinesischer Yuan';

  @override
  String get currencyRon => 'Rumänischer Leu';

  @override
  String get currencyAed => 'VAE-Dirham';

  @override
  String get currencyBgn => 'Bulgarischer Lew';

  @override
  String get currencyKwd => 'Kuwait-Dinar';

  @override
  String get currencyTry => 'Türkische Lira';

  @override
  String get editCounterTitle => 'Zähler bearbeiten';

  @override
  String get resetCounterConfirm =>
      'Sind Sie sicher, dass Sie den Zähler zurücksetzen möchten?';

  @override
  String get imsakiyeTitle => 'Gebetskalender';

  @override
  String get widgetRamadanName => 'Ramadan-Countdown';

  @override
  String get widgetRamadanDesc =>
      'Quadrat: Zeit bis zum Iftar und bis zum Ende des Suhur; außerhalb des Ramadan die Tage bis zu seinem Beginn';

  @override
  String widgetRamadanDay(String day) {
    return 'Ramadan · Tag $day';
  }

  @override
  String get widgetRamadanUntil => 'Tage bis zum Ramadan';

  @override
  String get toolsGroupPrayer => 'Gebet';

  @override
  String get toolsGroupInfo => 'Wissen';

  @override
  String get toolsGroupCalc => 'Rechner';

  @override
  String get toolImsakiyeDesc => 'Monats- und Ramadan-Zeiten';

  @override
  String get toolTrackerDesc => 'Verrichtete Gebete und Qada-Zähler';

  @override
  String get toolReligiousDaysDesc => 'Gesegnete Nächte und Feste';

  @override
  String get nearbyMosquesTitle => 'Moscheen in der Nähe';

  @override
  String get toolNearbyMosquesDesc =>
      'Nächstgelegene Moscheen auf der Karte finden';

  @override
  String get nearbyMosquesQuery => 'Moschee';

  @override
  String get nearbyMosquesError => 'Die Karte konnte nicht geöffnet werden.';

  @override
  String get toolEsmaDesc => 'Die 99 Namen und ihre Bedeutung';

  @override
  String get duasTitle => 'Bittgebete';

  @override
  String get duaSearchHint => 'Bittgebete suchen';

  @override
  String get duaNoResults => 'Kein passendes Bittgebet gefunden';

  @override
  String duaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bittgebete',
      one: '1 Bittgebet',
    );
    return '$_temp0';
  }

  @override
  String get prayerGuideTitle => 'Gebetsanleitung';

  @override
  String get toolPrayerGuideDesc =>
      'Gebetswaschung und Gebetsablauf, Schritt für Schritt';

  @override
  String get prayerGuideTabWudu => 'Wudu';

  @override
  String get prayerGuideTabFards => 'Pflichten';

  @override
  String get prayerGuideTabRakats => 'Rak\'as';

  @override
  String get prayerGuideTabSteps => 'Ablauf';

  @override
  String prayerGuideTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-mal',
      one: 'einmal',
    );
    return '$_temp0';
  }

  @override
  String get toolDuasDesc => 'Tasbih, Morgen-, Abend- und Alltagsbittgebete';

  @override
  String get duaTransliteration => 'Umschrift';

  @override
  String get duaMeaning => 'Bedeutung';

  @override
  String get tesbihatTitle => 'Tasbih nach dem Gebet';

  @override
  String get tesbihatDesc => 'Ayat al-Kursi, je 33 Tasbih und Bittgebet';

  @override
  String tesbihatStep(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get tesbihatTapWhenRead => 'Nach dem Rezitieren tippen';

  @override
  String get tesbihatRestart => 'Neu beginnen';

  @override
  String ramadanShareTitle(int day) {
    return 'Ramadan · Tag $day';
  }

  @override
  String ramadanShareIftarIn(String time) {
    return 'Iftar in $time';
  }

  @override
  String ramadanShareSahurIn(String time) {
    return 'Suhur endet in $time';
  }

  @override
  String ramadanShareIftarAt(String time) {
    return 'Iftar $time';
  }

  @override
  String ramadanShareImsakAt(String time) {
    return 'Imsak $time';
  }

  @override
  String ramadanShareHoursMinutes(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String ramadanShareHours(int hours) {
    return '$hours Std.';
  }

  @override
  String ramadanShareMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get toolFridayDesc => 'Fertige Grüße zum Teilen';

  @override
  String get quranTitle => 'Der Heilige Koran';

  @override
  String get quranTabSurahs => 'Suren';

  @override
  String get quranTabJuz => 'Juz';

  @override
  String get quranSearchHint => 'Sure nach Name oder Nummer suchen';

  @override
  String get quranNoResults => 'Keine passende Sure gefunden';

  @override
  String quranJuz(int juz) {
    return 'Juz $juz';
  }

  @override
  String quranPage(int page) {
    return 'Seite $page';
  }

  @override
  String quranAyahRange(int from, int to) {
    return 'Verse $from–$to';
  }

  @override
  String get quranBookmark => 'Lesezeichen';

  @override
  String get quranViewSettings => 'Ansicht';

  @override
  String get quranModePage => 'Seite';

  @override
  String get quranModePageDesc => 'Fortlaufender arabischer Text wie im Mushaf';

  @override
  String get quranModeAyah => 'Vers für Vers';

  @override
  String get quranModeAyahDesc =>
      'Jeder Vers mit Übersetzung auf einer eigenen Karte';

  @override
  String get quranModeTranslation => 'Übersetzung';

  @override
  String get quranModeTranslationDesc =>
      'Nur die Übersetzung, als fortlaufender Text';

  @override
  String get quranArabicSize => 'Arabische Schrift';

  @override
  String get quranTranslationSize => 'Übersetzungstext';

  @override
  String get quranTranslationSmaller => 'Übersetzung verkleinern';

  @override
  String get quranTranslationLarger => 'Übersetzung vergrößern';

  @override
  String get quranGoToAyah => 'Zu Vers springen';

  @override
  String quranAyahNumberLabel(int count) {
    return 'Versnummer (1–$count)';
  }

  @override
  String get quranGo => 'Springen';

  @override
  String get quranPreviousSurah => 'Vorherige Sure';

  @override
  String get quranNextSurah => 'Nächste Sure';

  @override
  String get toolQuranDesc => 'Suren mit arabischem Text und Übersetzung';

  @override
  String get quranContinue => 'Weiterlesen, wo Sie aufgehört haben';

  @override
  String quranAyahRef(String surah, int ayah) {
    return '$surah, Vers $ayah';
  }

  @override
  String quranAyahCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Verse',
      one: '1 Vers',
    );
    return '$_temp0';
  }

  @override
  String get quranMeccan => 'Mekkanisch';

  @override
  String get quranMedinan => 'Medinensisch';

  @override
  String get quranLoadError =>
      'Die Sure konnte nicht geladen werden. Prüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.';

  @override
  String get quranBookmarkSave => 'Lesezeichen setzen';

  @override
  String get quranBookmarkRemove => 'Lesezeichen entfernen';

  @override
  String get quranBookmarkSaved => 'Lesezeichen gesetzt';

  @override
  String get quranBookmarkRemoved => 'Lesezeichen entfernt';

  @override
  String get quranShareAyah => 'Vers teilen';

  @override
  String get quranFontSmaller => 'Arabische Schrift verkleinern';

  @override
  String get quranFontLarger => 'Arabische Schrift vergrößern';

  @override
  String get quranTextSource => 'Arabischer Text: Tanzil-Projekt (tanzil.net)';

  @override
  String get hatimTitle => 'Khatm';

  @override
  String get hatimIntro => 'Lesen Sie den ganzen Koran mit einem Tagesplan.';

  @override
  String get hatimStart => 'Khatm starten';

  @override
  String hatimPagesPerDay(int pages) {
    String _temp0 = intl.Intl.pluralLogic(
      pages,
      locale: localeName,
      other: '$pages Seiten pro Tag',
      one: '1 Seite pro Tag',
    );
    return '$_temp0';
  }

  @override
  String hatimDuration(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: 'in $months Monaten',
      one: 'in 30 Tagen',
    );
    return '$_temp0';
  }

  @override
  String get hatimRamadan => 'Khatm im Ramadan';

  @override
  String hatimProgress(int page, int total, String percent) {
    return 'Seite $page von $total · $percent';
  }

  @override
  String hatimToday(int read, int goal) {
    return 'Heute $read / $goal Seiten';
  }

  @override
  String get hatimContinue => 'Weiterlesen';

  @override
  String get hatimEnterPage => 'Seite eingeben';

  @override
  String hatimPageLabel(int total) {
    return 'Zuletzt gelesene Seite (1–$total)';
  }

  @override
  String get hatimReminder => 'Erinnerung';

  @override
  String get hatimReminderDaily => 'Täglich erinnern';

  @override
  String get hatimReminderTime => 'Uhrzeit';

  @override
  String get hatimChangePlan => 'Plan ändern';

  @override
  String get hatimDelete => 'Khatm löschen';

  @override
  String get hatimDeleteConfirm =>
      'Khatm-Plan und Fortschritt löschen? Die Zahl der abgeschlossenen Khatms bleibt erhalten.';

  @override
  String get hatimDone => 'Khatm abgeschlossen';

  @override
  String get hatimNew => 'Neuer Khatm';

  @override
  String hatimCount(int count) {
    return 'Abgeschlossene Khatms: $count';
  }

  @override
  String get hatimCompleted =>
      'Ihr Khatm ist abgeschlossen. Möge Allah ihn annehmen!';

  @override
  String get hatimReminderChannel => 'Khatm-Erinnerung';

  @override
  String get hatimReminderBody =>
      'Vergessen Sie Ihre heutige Khatm-Lesung nicht.';

  @override
  String hatimTodayRange(int from, int to) {
    return 'Heutige Lesung: Seiten $from–$to';
  }

  @override
  String get hatimMarkRead => 'Gelesen';

  @override
  String get hatimGoalMet => 'Heutige Lesung erledigt';

  @override
  String get hatimDetails => 'Khatm-Details';

  @override
  String hatimTargetLine(String date) {
    return 'Ziel: $date';
  }

  @override
  String get hatimJuzHint =>
      'Tippen Sie auf einen Juz, den Sie im gedruckten Mushaf gelesen haben, um ihn zu markieren.';

  @override
  String hatimJuzMarkRead(int juz) {
    return 'Alles bis zum Ende von Juz $juz als gelesen markieren?';
  }

  @override
  String hatimJuzMarkUnread(int juz) {
    return 'Juz $juz und alles danach als ungelesen markieren?';
  }

  @override
  String get hatimMark => 'Markieren';

  @override
  String get hatimUnmark => 'Markierung entfernen';

  @override
  String get hatimJuzDone => 'gelesen';

  @override
  String get hatimJuzCurrent => 'wird gelesen';

  @override
  String get hatimJuzPending => 'nicht gelesen';

  @override
  String get hatimNote => 'Absicht';

  @override
  String get hatimNoteHint => 'Z. B. für meine verstorbene Mutter';

  @override
  String get hatimNoteAdd => 'Absicht hinzufügen (optional)';

  @override
  String get hatimGroup => 'Gemeinsames Khatm';

  @override
  String get hatimGroupDesc => 'Die 30 Juz verteilen und die Liste senden';

  @override
  String get hatimGroupPeople => 'Anzahl der Personen';

  @override
  String hatimGroupLine(int person, String juz) {
    return 'Person $person: $juz';
  }

  @override
  String hatimGroupRange(int from, int to) {
    return 'Juz $from–$to';
  }

  @override
  String get hatimGroupFooter =>
      'Bitte gebt Bescheid, wenn ihr euren Teil beendet habt. Möge Allah es annehmen.';

  @override
  String get hatimGroupShare => 'Liste teilen';

  @override
  String get hatimDuaHeader => 'Bittgebet nach dem Khatm';

  @override
  String quranTranslationSource(String name) {
    return 'Übersetzung: $name';
  }

  @override
  String get toolZakatDesc => 'Zakat und Ernteabgabe (Uschr) berechnen';

  @override
  String get toolSettingsDesc => 'Standort, Benachrichtigungen, Darstellung';

  @override
  String get sectionBackup => 'DATENSICHERUNG';

  @override
  String get backupExportTitle => 'Daten sichern';

  @override
  String get backupExportSub =>
      'Gebetsprotokoll, Qada, Dhikr und Einstellungen (inkl. Standort) in einer Datei';

  @override
  String get backupImportTitle => 'Sicherung wiederherstellen';

  @override
  String get backupImportSub =>
      'Wählen Sie eine zuvor gespeicherte Sicherungsdatei';

  @override
  String get backupShareSubject => 'Vaktinde-Sicherung';

  @override
  String get backupRestoreConfirmTitle => 'Sicherung wiederherstellen?';

  @override
  String backupRestoreConfirmMessage(String date) {
    return 'Die Sicherung vom $date wird geladen. Ihre aktuellen Daten werden durch die Daten der Sicherung ersetzt: Gebets- und Fastenprotokoll, Qada-Zähler, Dhikr, Adhan- und Benachrichtigungseinstellungen, Standort und Darstellung. Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get backupRestoreConfirm => 'Wiederherstellen';

  @override
  String get backupRestored => 'Sicherung wiederhergestellt.';

  @override
  String get backupInvalidFile =>
      'Diese Datei ist keine gültige Vaktinde-Sicherung.';

  @override
  String get backupNewerVersion =>
      'Diese Sicherung wurde mit einer neueren Version der App erstellt. Aktualisieren Sie die App und versuchen Sie es erneut.';

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count Tage',
      one: 'Morgen',
      zero: 'Heute',
    );
    return '$_temp0';
  }

  @override
  String get previousYear => 'Vorheriges Jahr';

  @override
  String get nextYear => 'Nächstes Jahr';

  @override
  String get previousItem => 'Vorherige';

  @override
  String get nextItem => 'Nächste';

  @override
  String missedChangeConfirm(String name, int from, int to) {
    return 'Die Anzahl für $name ändert sich von $from auf $to. Speichern?';
  }

  @override
  String get shareFailed =>
      'Das hat nicht funktioniert. Bitte versuchen Sie es erneut.';

  @override
  String get zakatCurrencyNote => 'Alle Beträge sind in Türkischer Lira (₺).';

  @override
  String get zakatCashTry => 'Bargeld (₺)';

  @override
  String get zakatRatesUnavailable =>
      'Aktuelle Goldpreise und Wechselkurse sind nicht verfügbar. Bitte geben Sie die Preise selbst ein.';

  @override
  String get zakatGoldGramPrice => 'Preis für 1 g Gold, 24 Karat (₺)';

  @override
  String get zakatGoldGramPriceHelp => 'Damit wird die Nisab-Grenze berechnet.';

  @override
  String get zakatNisabUnknown =>
      'Ohne Goldpreis kann die Nisab-Grenze nicht berechnet werden. Geben Sie den Goldpreis für ein korrektes Ergebnis ein.';

  @override
  String get imsakiyeRamadan => 'Ramadan';

  @override
  String imsakiyeRamadanTitle(int year) {
    return 'Ramadan-Kalender $year';
  }

  @override
  String get imsakiyeDay => 'Tag';

  @override
  String get imsakiyeSunriseShort => 'Sonne';

  @override
  String get imsakiyePrevMonth => 'Vorheriger Monat';

  @override
  String get imsakiyeNextMonth => 'Nächster Monat';

  @override
  String get imsakiyeNoLocation =>
      'Bitte wählen Sie zuerst Ihren Standort, um den Gebetskalender zu sehen. Sie können ihn auf der Startseite oder in den Einstellungen festlegen.';

  @override
  String get imsakiyeShareError =>
      'Der Gebetskalender konnte nicht geteilt werden. Bitte versuchen Sie es erneut.';

  @override
  String get ramadanSahurLeft => 'Suhur endet in';

  @override
  String get ramadanIftarLeft => 'Zeit bis Iftar';

  @override
  String ramadanDayLabel(int day) {
    return 'Ramadan, Tag $day';
  }
}
