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
  String get adPrivacySettings => 'Werbe-Datenschutzeinstellungen';

  @override
  String get adPrivacySettingsSub =>
      'Einwilligung für personalisierte Werbung ändern';

  @override
  String get showcaseLanguage => 'Hier können Sie die App-Sprache ändern.';

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
  String get refreshLocation => 'Standort aktualisieren';

  @override
  String get navTools => 'Werkzeuge';

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
  String get ok => 'OK';

  @override
  String get nextPrayer => 'Nächste Gebetszeit';

  @override
  String get hadithTitle => 'Hadith des Tages';

  @override
  String get readMore => 'Weiterlesen...';

  @override
  String get share => 'Teilen';

  @override
  String get close => 'Schließen';

  @override
  String get loading => 'Zeiten werden berechnet...';

  @override
  String get error => 'Fehler';

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
  String get navMenu => 'Menü';

  @override
  String get menuTitle => 'Einstellungen';

  @override
  String get sectionLocation => 'STANDORT & ZEITEN';

  @override
  String get changeLocation => 'Standort ändern';

  @override
  String get citySelect => 'Stadt auswählen';

  @override
  String get districtSelect => 'Bezirk auswählen';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get locationWarning =>
      'Die Auswahl des Bezirks ist wichtig für genaue Gebetszeiten.';

  @override
  String get menuNotifications => 'Berechtigungen für Benachrichtigungen';

  @override
  String get menuNotificationsSub => 'Hier prüfen, falls Sie keine Töne hören.';

  @override
  String get menuTroubleshoot => 'Keine Benachrichtigungen?';

  @override
  String get menuTroubleshootSub =>
      'Akkueinstellungen für Samsung/Xiaomi anpassen.';

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
      'Nicht markierte Gebete der letzten 30 Tage (ab Beginn der Erfassung) werden zu den Qada-Zählern hinzugefügt. Jedes Gebet wird nur einmal hinzugefügt.';

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
  String get trackerKazaLocked =>
      'Dieses Gebet wurde zu Qada hinzugefügt. Wenn Sie es nachgeholt haben, können Sie es im Qada-Tracker abziehen.';

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
      'Benachrichtigung für Vers und Hadith des Tages';

  @override
  String get dailyContentNotifSub =>
      'Sendet jeden Morgen einen Vers und jeden Abend einen Hadith.';

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
  String get batteryDialogTitle => 'Lösung für Benachrichtigungsprobleme';

  @override
  String get batteryDialogBody =>
      'Ihr Telefon schließt die App möglicherweise, um Akku zu sparen. Um dies zu verhindern:\n\n1. Öffnen Sie die Ansicht \'Zuletzt verwendete Apps\'.\n2. Halten Sie die \'Vaktinde\'-App gedrückt oder tippen Sie auf ihr Logo.\n3. Tippen Sie auf das Schloss-Symbol 🔒, um sie zu sperren.\n\nWählen Sie außerdem unter Einstellungen > Apps > Vaktinde > Akku die Option \'Nicht eingeschränkt\'.';

  @override
  String get okUnderstood => 'OK, verstanden';

  @override
  String get religiousDaysTitle => 'Religiöse Tage';

  @override
  String errorOccurred(String error) {
    return 'Ein Fehler ist aufgetreten: $error';
  }

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
  String get closeCaps => 'SCHLIESSEN';

  @override
  String get zakatTitle => 'Zakat-Rechner';

  @override
  String get zakatCalculatorTitle => 'Smarter Zakat-Rechner';

  @override
  String get liveRatesLoading => 'Aktuelle Wechselkurse werden abgerufen...';

  @override
  String get liveRatesInfo =>
      'Sie können die automatisch abgerufenen Kurse bei Bedarf manuell bearbeiten.';

  @override
  String get sectionGold => 'Goldvermögen';

  @override
  String get goldType => 'Goldart';

  @override
  String get goldAmount => 'Menge / Gramm';

  @override
  String get goldUnitPrice => 'Einzelpreis';

  @override
  String get sectionCurrency => 'Währungsvermögen';

  @override
  String get currencyType => 'Währungsart';

  @override
  String get currencyAmount => 'Betrag';

  @override
  String get currencyRate => 'Aktueller Kurs';

  @override
  String get sectionCashDebt => 'Bargeld & Schulden';

  @override
  String get cashAmount => 'Bargeld & Bankguthaben (TL)';

  @override
  String get debtAmount => 'Gesamtschulden (werden abgezogen)';

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
  String get locationPermissionForever =>
      'Standortberechtigung dauerhaft verweigert. Bitte in den Einstellungen aktivieren.';

  @override
  String compassError(String error) {
    return 'Sensorfehler: $error';
  }

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
  String get appearanceSub => 'Theme und Hintergrund';

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
  String get bgMosque => 'Moschee';

  @override
  String get bgKaaba => 'Kaaba';

  @override
  String get bgQuran => 'Koran';

  @override
  String get none => 'Keines';

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
  String get stickyChannelName => 'Permanenter Zähler';

  @override
  String get stickyChannelDesc => 'Zeigt die verbleibende Zeit an';

  @override
  String get timeLeftTo => 'Bis zum Ende der Gebetszeit: ';

  @override
  String get locationFallbackMessage =>
      'Standort konnte nicht abgerufen werden, Standardwerte werden verwendet.';

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
  String get calibrationInstruction =>
      '(Zeichnen Sie eine \'8\' zur Kalibrierung)';

  @override
  String get zakatDescription =>
      'Berechnen Sie Ihre Zakat detailliert gemäß den Fatwas der Diyanet und aktuellen Marktpreisen.';

  @override
  String get cashAndCurrencyTitle => 'Bargeld und Devisen';

  @override
  String get cashTurkishLira => 'Bargeld in Türkischer Lira (TL)';

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
  String get dhikrSubhanallah => 'Subhanallah';

  @override
  String get dhikrElhamdulillah => 'Alhamdulillah';

  @override
  String get dhikrAllahuEkber => 'Allahu Akbar';

  @override
  String get dhikrKalima => 'Kalimat at-Tawhid';

  @override
  String get dhikrSalavat => 'Salawat';

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
  String get customDhikrTitle => 'Eigenen Dhikr hinzufügen';

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
  String get introTitle1 => 'Willkommen bei Vaktinde';

  @override
  String get introDesc1 =>
      'Verfolgen Sie Gebetszeiten, Dhikr und religiöse Tage einfach mit unserer modernen Oberfläche.';

  @override
  String get introTitle2 => 'Smarte Benachrichtigungen';

  @override
  String get introDesc2 =>
      'Erhalten Sie zu den Gebetszeiten eine Benachrichtigung mit dem Ton Ihrer Wahl. Verpassen Sie nie wieder ein Gebet.';

  @override
  String get introTitle3 => 'Erweiterte Tools';

  @override
  String get introDesc3 =>
      'Stärken Sie Ihre Spiritualität mit dem animierten Dhikr-Zähler, dem Qada-Tracker, den Namen Allahs und dem Zakat-Rechner.';

  @override
  String get introSkip => 'Überspringen';

  @override
  String get introNext => 'Weiter';

  @override
  String get introStart => 'Jetzt starten';

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
  String get statisticsTitle => 'Statistiken';

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
  String get dhikrEstagfirullah => 'Astaghfirullah';

  @override
  String get dhikrLaHavle => 'La Hawla wa la Quwwata';

  @override
  String get dhikrHasbunallah => 'Hasbunallah';

  @override
  String get dhikrSubhanallahi => 'Subhanallahi wa bihamdihi';

  @override
  String get dhikrYunus => 'Bittgebet des Propheten Yunus';

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
  String get remainingTime => 'Verbleibend';

  @override
  String get onboardingWelcome => 'Hoş Geldiniz / Willkommen';

  @override
  String get onboardingSelectLanguage =>
      'Lütfen kullanmak istediğiniz dili seçin.\nBitte wählen Sie Ihre bevorzugte Sprache.';

  @override
  String get turnRight => 'Nach rechts drehen ➔';

  @override
  String get turnSlightRight => 'Leicht nach rechts drehen ➔';

  @override
  String get turnLeft => '⬅ Nach links drehen';

  @override
  String get turnSlightLeft => '⬅ Leicht nach links drehen';

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
      'Kalibrieren Sie, indem Sie mit dem Telefon eine \'8\' in die Luft zeichnen.';

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
  String get holdToEdit => 'Zum Bearbeiten gedrückt halten';

  @override
  String get editCounterTitle => 'Zähler bearbeiten';

  @override
  String get editCounterHint => 'Z. B. 2000';

  @override
  String get editTargetHint => 'Z. B. 99';

  @override
  String get resetCounterConfirm =>
      'Sind Sie sicher, dass Sie den Zähler zurücksetzen möchten?';

  @override
  String get dhikrTarget => 'Ziel:';

  @override
  String get imsakiyeTitle => 'Gebetskalender';

  @override
  String get toolsGroupPrayer => 'Gebet';

  @override
  String get toolsGroupInfo => 'Wissen';

  @override
  String get toolsGroupCalc => 'Rechner';

  @override
  String get toolImsakiyeDesc => 'Monats- und Ramadan-Zeiten';

  @override
  String get toolTrackerDesc => 'Verrichtete Gebete abhaken';

  @override
  String get toolKazaDesc => 'Zähler für versäumte Gebete und Fasten';

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
  String get toolFridayDesc => 'Fertige Grüße zum Teilen';

  @override
  String get toolZakatDesc => 'Zakat und Ernteabgabe (Uschr) berechnen';

  @override
  String get toolSettingsDesc => 'Standort, Benachrichtigungen, Darstellung';

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
