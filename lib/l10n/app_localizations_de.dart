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
  String get exactAlarm => 'Pünktlich Benachrichtigen';

  @override
  String get exactAlarmSub => 'Sendet eine Benachrichtigung.';

  @override
  String get silentNotif => 'Nur Textbenachrichtigung';

  @override
  String get silentNotifSub => 'Kein Adhan/Ton, nur visueller Alarm.';

  @override
  String warningAlarm(String minute) {
    return '$minute Min Vorher Warnen';
  }

  @override
  String get warningAlarmSub => 'Kurzer Benachrichtigungston.';

  @override
  String get settings => 'Einstellungen';

  @override
  String get changeLanguage => 'Sprache Ändern';

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
  String get notifTitleUpcoming => 'Zeit nähert sich';

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
  String get changeLocation => 'Standort Ändern';

  @override
  String get citySelect => 'Stadt Auswählen';

  @override
  String get districtSelect => 'Bezirk Auswählen';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get locationWarning =>
      'Die Auswahl des Bezirks ist wichtig für genaue Gebetszeiten.';

  @override
  String get menuNotifications => 'Benachrichtigungsberechtigungen';

  @override
  String get menuNotificationsSub => 'Hier prüfen, falls Sie keine Töne hören.';

  @override
  String get menuTroubleshoot => 'Keine Benachrichtigungen?';

  @override
  String get menuTroubleshootSub =>
      'Batterieeinstellungen für Samsung/Xiaomi anpassen.';

  @override
  String get timeAdjustTitle => 'Gebetszeiten anpassen';

  @override
  String get timeAdjustSub => 'Zeiten minutengenau korrigieren';

  @override
  String get timeAdjustInfo =>
      'Die Zeiten werden für Ihren Standort nach der Diyanet-Methode berechnet. Wenn sie leicht von Ihrer örtlichen Moschee abweichen, können Sie jede Zeit um einige Minuten vor- oder zurückstellen. Die Anpassung gilt für den Startbildschirm, die Widgets und die Gebetsbenachrichtigungen.';

  @override
  String get timeAdjustReset => 'Zurücksetzen';

  @override
  String timeAdjustMinutes(String value) {
    return '$value Min.';
  }

  @override
  String get timeAdjustSaved => 'Gebetszeiten aktualisiert';

  @override
  String get sectionSupport => 'SUPPORT';

  @override
  String get shareApp => 'Mit Freunden Teilen';

  @override
  String get rateApp => 'Bewerten Sie uns';

  @override
  String get contactUs => 'Kontakt & Fehler Melden';

  @override
  String shareText(String link) {
    return 'Ich habe eine tolle Gebetszeiten-App gefunden! Hier herunterladen: $link';
  }

  @override
  String get batteryDialogTitle => 'Lösung für Benachrichtigungsprobleme';

  @override
  String get batteryDialogBody =>
      'Ihr Telefon schließt die App möglicherweise, um Akku zu sparen. Um dies zu verhindern:\n\n1. Öffnen Sie die Ansicht \'Zuletzt verwendete Apps\'.\n2. Halten Sie die \'Vaktinde\'-App gedrückt oder tippen Sie auf ihr Logo.\n3. Tippen Sie auf das Schloss-Symbol 🔒, um sie zu sperren.\n\nGehen Sie außerdem zu Einstellungen > Apps > Vaktinde > Akku > \'Nicht eingeschränkt\' auswählen.';

  @override
  String get okUnderstood => 'OK, Ich Verstehe';

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
    return 'Liste Religiöser Tage für $year';
  }

  @override
  String get missedPrayersTitle => 'Verpasste Gebete Tracker';

  @override
  String get missedPrayersInfo =>
      'Notieren Sie hier verpasste Gebete und ziehen Sie diese nach dem Nachholen ab.\n(Tippen Sie auf die Zahl zur manuellen Eingabe)';

  @override
  String editMissedTitle(String title) {
    return 'Verpasstes $title Bearbeiten';
  }

  @override
  String get missedCountLabel => 'Anzahl Verpasster Gebete';

  @override
  String get missedCountHint => 'Z.B.: 150';

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
  String get fridayMessagesTitle => 'Freitagsnachrichten';

  @override
  String get esmaulHusnaTitle => 'Namen Allahs';

  @override
  String get closeCaps => 'SCHLIEßEN';

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
  String get cashAmount => 'Bargeld auf Hand & Bank';

  @override
  String get debtAmount => 'Gesamtschulden (Abzuziehen)';

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
  String get goldQuarter => 'Viertelgold';

  @override
  String get goldFull => 'Vollgold';

  @override
  String get typeOther => 'Andere (Manuell)';

  @override
  String get usd => 'US-Dollar (USD)';

  @override
  String get eur => 'Euro (EUR)';

  @override
  String get gbp => 'Britisches Pfund (GBP)';

  @override
  String get sectionAppearance => 'ERSCHEINUNGSBILD & SPRACHE';

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
  String get zakatEligible => 'Zakat ist erforderlich';

  @override
  String get zakatNotEligible => 'Zakat ist nicht erforderlich';

  @override
  String get nisabLimit => 'Nisab-Grenze (80,18 g Gold)';

  @override
  String get belowNisabMessage =>
      'Da Ihr Nettovermögen unter dem Nisab-Betrag (Reichtumsgrenze) liegt, ist Zakat nicht obligatorisch.';

  @override
  String get searchLocationTitle => 'Standort Suchen (Weltweit)';

  @override
  String get searchLocationHint => 'Stadt oder Land (Z.B.: Paris)';

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
  String get timeLeftTo => 'Verbleibende Zeit bis Ende: ';

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
      'Berechnen Sie Ihre Zakat detailliert gemäß den religiösen Vorgaben und aktuellen Marktpreisen.';

  @override
  String get cashAndCurrencyTitle => 'Bargeld und Währungsvermögen';

  @override
  String get cashTurkishLira => 'Bargeld (Lokale Währung)';

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
  String get receivablesTitle => 'Forderungen (Einbringlich)';

  @override
  String get receivableType => 'Art (Bargeld, Währung, Gold)';

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
  String get debtsTitle => 'Schulden (Abzuziehen)';

  @override
  String get debtType => 'Schuldenart (Bargeld, Währung, Gold)';

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
  String get agriSoilless => 'Landwirtschaft (Erdenlos)';

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
      'Die Kompasskalibrierung ist schwach. Bitte zeichnen Sie mit dem Telefon eine \'8\' in die Luft.';

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
  String get dhikrKalima => 'Kalima-i Tawhid';

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
  String get setTarget => 'Ziel Setzen';

  @override
  String get dhikrOther => 'Andere (Eigener Dhikr)';

  @override
  String get customDhikrTitle => 'Eigenen Dhikr Hinzufügen';

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
  String get appearance => 'Erscheinungsbild';

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
      'Erhalten Sie zu den Gebetszeiten Alarme mit Ihrem gewünschten Ton. Verpassen Sie nie Ihre Gottesdienste.';

  @override
  String get introTitle3 => 'Erweiterte Tools';

  @override
  String get introDesc3 =>
      'Stärken Sie Ihre Spiritualität mit animiertem Zähler, Nachhol-Tracker, Namen Allahs und Zakat-Rechner.';

  @override
  String get introSkip => 'Überspringen';

  @override
  String get introNext => 'Weiter';

  @override
  String get introStart => 'Jetzt Starten';

  @override
  String get dhikrListTitle => 'Dhikr-Liste';

  @override
  String get addCustomDhikr => 'Neuen Eigenen Dhikr Hinzufügen';

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
  String get totalDhikr => 'Gesamter Dhikr';

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
  String get dhikrYunus => 'Gebet von Prophet Yunus';

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
  String get locationFoundNoName => 'Standort gefunden, aber kein Name.';

  @override
  String get dailyAyahTitle => 'Ayah des Tages';

  @override
  String get remainingTime => 'Verbleibend';

  @override
  String get onboardingWelcome => 'Hoş Geldiniz / Willkommen';

  @override
  String get onboardingSelectLanguage =>
      'Lütfen kullanmak istediğiniz dili seçin.\nBitte wählen Sie Ihre bevorzugte Sprache.';

  @override
  String get turnRight => 'Rechts abbiegen ➔';

  @override
  String get turnSlightRight => 'Leicht rechts abbiegen ➔';

  @override
  String get turnLeft => '⬅ Links abbiegen';

  @override
  String get turnSlightLeft => '⬅ Leicht links abbiegen';

  @override
  String get calibrationRequired => 'Kalibrierung Erforderlich';

  @override
  String get gold22kGram => '22 Karat Gramm Gold';

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
  String get goldHalf => 'Halb-Gold';

  @override
  String get goldGremse => 'Gremse-Gold';

  @override
  String get goldAtaBesli => 'Ata Besli';

  @override
  String get goldResat => 'Resat-Gold';

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
  String get holdToEdit => '(Gedrückt halten zum Bearbeiten)';

  @override
  String get editCounterTitle => 'Zähler Bearbeiten';

  @override
  String get editCounterHint => 'Z.B.: 2000';

  @override
  String get editTargetHint => 'Z.B.: 99';

  @override
  String get resetCounterConfirm =>
      'Sind Sie sicher, dass Sie den Zähler zurücksetzen möchten?';

  @override
  String get dhikrTarget => 'Ziel:';

  @override
  String get imsakiyeTitle => 'Gebetskalender';

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
      'Bitte wählen Sie zuerst Ihren Standort, um den Gebetskalender zu sehen. Sie können ihn auf dem Startbildschirm oder in den Einstellungen festlegen.';

  @override
  String get imsakiyeShareError =>
      'Der Gebetskalender konnte nicht geteilt werden. Bitte versuchen Sie es erneut.';

  @override
  String get ramadanSahurLeft => 'Zeit bis Sahur';

  @override
  String get ramadanIftarLeft => 'Zeit bis Iftar';

  @override
  String ramadanDayLabel(int day) {
    return 'Ramadan, Tag $day';
  }
}
