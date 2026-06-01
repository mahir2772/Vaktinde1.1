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
  String get nextPrayer => 'Nächstes Gebet';

  @override
  String get hadithTitle => 'Hadith des Tages';

  @override
  String get readMore => 'Mehr lesen...';

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
  String get imsak => 'Fadschr';

  @override
  String get gunes => 'Sonnenaufgang';

  @override
  String get ogle => 'Duhur';

  @override
  String get ikindi => 'Asr';

  @override
  String get aksam => 'Maghrib';

  @override
  String get yatsi => 'Ischa';

  @override
  String get exactAlarm => 'Pünktlich benachrichtigen';

  @override
  String get exactAlarmSub => 'Sendet eine Benachrichtigung.';

  @override
  String get silentNotif => 'Nur Textbenachrichtigung';

  @override
  String get silentNotifSub => 'Kein Ton/Adhan, nur Warnung.';

  @override
  String warningAlarm(String minute) {
    return '$minute Min. vorher warnen';
  }

  @override
  String get warningAlarmSub => 'Kurzer Benachrichtigungston.';

  @override
  String get settings => 'Einstellungen';

  @override
  String get changeLanguage => 'Sprache ändern';

  @override
  String get waitingLocation => 'Standort wird ermittelt...';

  @override
  String get noInternet =>
      'Keine Internetverbindung und keine gespeicherten Daten gefunden.';

  @override
  String get gpsOff => 'GPS ist aus. Bitte Standort aktivieren.';

  @override
  String get permissionDenied => 'Standortzugriff verweigert.';

  @override
  String get locationError => 'Standort konnte nicht abgerufen werden.';

  @override
  String get internetNeeded => 'Internetverbindung erforderlich.';

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
  String get notifTitleUpcoming => 'Zeit naht';

  @override
  String notifBodyUpcoming(String vakit, int minute) {
    return 'Noch $minute Minuten bis $vakit.';
  }

  @override
  String get navPrayer => 'Zeiten';

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
  String get citySelect => 'Stadt wählen';

  @override
  String get districtSelect => 'Bezirk wählen';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get locationWarning =>
      'Die Wahl des Bezirks ist wichtig für genaue Gebetszeiten.';

  @override
  String get menuNotifications => 'Benachrichtigungsrechte';

  @override
  String get menuNotificationsSub => 'Hier prüfen, wenn kein Ton kommt.';

  @override
  String get menuTroubleshoot => 'Keine Benachrichtigungen?';

  @override
  String get menuTroubleshootSub => 'Batterieeinstellungen für Samsung/Xiaomi.';

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
    return 'Ich habe eine tolle Gebetszeiten-App gefunden! Download: $link';
  }

  @override
  String get batteryDialogTitle => 'Benachrichtigungsprobleme beheben';

  @override
  String get batteryDialogBody =>
      'Ihr Telefon beendet die App möglicherweise, um Akku zu sparen. Um dies zu verhindern:\n\n1. Öffnen Sie die letzten Apps (Quadrat-Taste).\n2. Halten Sie die \'Vaktinde\'-App gedrückt oder tippen Sie auf das Logo.\n3. Tippen Sie auf das Schloss-Symbol 🔒, um sie zu sperren.\n\nGehen Sie außerdem zu Einstellungen > Apps > Vaktinde > Akku > Nicht eingeschränkt.';

  @override
  String get okUnderstood => 'Verstanden';

  @override
  String get religiousDaysTitle => 'Religiöse Tage';

  @override
  String errorOccurred(String error) {
    return 'Fehler aufgetreten: $error';
  }

  @override
  String get noDataFound => 'Keine Daten gefunden.';

  @override
  String noDataForYear(int year) {
    return 'Keine Daten für das Jahr $year gefunden.';
  }

  @override
  String religiousDaysListTitle(int year) {
    return 'Liste der religiösen Tage $year';
  }

  @override
  String get missedPrayersTitle => 'Verpasste Gebete';

  @override
  String get missedPrayersInfo =>
      'Notieren Sie hier Ihre verpassten Gebete und reduzieren Sie sie, wenn Sie sie nachgeholt haben.\n(Tippen Sie auf die Zahl zur manuellen Eingabe)';

  @override
  String editMissedTitle(String title) {
    return '$title bearbeiten';
  }

  @override
  String get missedCountLabel => 'Anzahl';

  @override
  String get missedCountHint => 'Bsp: 150';

  @override
  String get sabah => 'Fadschr';

  @override
  String get vitir => 'Witr';

  @override
  String get oruc => 'Fasten';

  @override
  String timeLeftFor(String vakit) {
    return 'Verbleibende Zeit für $vakit';
  }

  @override
  String get tomorrow => '(Morgen)';

  @override
  String get fridayMessagesTitle => 'Freitagsnachrichten';

  @override
  String get esmaulHusnaTitle => '99 Namen Allahs';

  @override
  String get closeCaps => 'SCHLIESSEN';

  @override
  String get zakatTitle => 'Zakat-Rechner';

  @override
  String get zakatCalculatorTitle => 'Intelligenter Zakat-Rechner';

  @override
  String get liveRatesLoading => 'Aktuelle Kurse werden geladen...';

  @override
  String get liveRatesInfo =>
      'Sie können die automatisch abgerufenen Kurse bei Bedarf manuell anpassen.';

  @override
  String get sectionGold => 'Goldvermögen';

  @override
  String get goldType => 'Goldart';

  @override
  String get goldAmount => 'Menge / Gramm';

  @override
  String get goldUnitPrice => 'Stückpreis (TL)';

  @override
  String get sectionCurrency => 'Währungsvermögen';

  @override
  String get currencyType => 'Währungstyp';

  @override
  String get currencyAmount => 'Betrag';

  @override
  String get currencyRate => 'Aktueller Kurs (TL)';

  @override
  String get sectionCashDebt => 'Bargeld & Schulden';

  @override
  String get cashAmount => 'Bargeld & Bank (TL)';

  @override
  String get debtAmount => 'Gesamtschulden (Abzuziehen)';

  @override
  String get calculateButton => 'BERECHNEN';

  @override
  String get zakatResultTitle => 'Zu zahlende Zakat';

  @override
  String get netAssets => 'Nettovermögen:';

  @override
  String get qiblaTitle => 'Qibla-Kompass';

  @override
  String get locationServiceOff =>
      'Standortdienst ist deaktiviert. Bitte aktivieren.';

  @override
  String get locationPermissionDenied => 'Standortzugriff verweigert.';

  @override
  String get locationPermissionForever =>
      'Standortzugriff dauerhaft verweigert. In Einstellungen aktivieren.';

  @override
  String compassError(String error) {
    return 'Sensorfehler: $error';
  }

  @override
  String get noCompass => 'Kein Kompass auf dem Gerät.';

  @override
  String get qiblaFound => 'SIE HABEN DIE QIBLA GEFUNDEN!';

  @override
  String qiblaAngle(String angle) {
    return 'Qibla-Winkel: $angle°';
  }

  @override
  String get keepAwayMetal => 'Von Metallgegenständen fernhalten.';

  @override
  String get goldGram => 'Gramm Gold (24K)';

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
  String get sectionAppearance => 'AUSSEHEN & SPRACHE';

  @override
  String get appearanceSettings => 'Erscheinungsbild';

  @override
  String get appearanceSub => 'Design & Hintergrund';

  @override
  String get themeMode => 'Design-Modus';

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
  String get none => 'Keine';

  @override
  String get zakatEligible => 'Zakat ist erforderlich';

  @override
  String get zakatNotEligible => 'Zakat nicht erforderlich';

  @override
  String get nisabLimit => 'Nisab-Grenze (80,18g Gold)';

  @override
  String get belowNisabMessage =>
      'Zakat ist nicht verpflichtend, da Ihr Nettovermögen unter der Nisab-Grenze liegt.';

  @override
  String get searchLocationTitle => 'Standort suchen (Weltweit)';

  @override
  String get searchLocationHint => 'Stadt oder Land (z.B. Paris)';

  @override
  String get searchInitial => 'Tippen zum Suchen...';

  @override
  String get searchNotFound => 'Standort nicht gefunden.';

  @override
  String get searchError => 'Keine Ergebnisse. Bitte versuchen Sie es erneut.';

  @override
  String locationSelected(String city) {
    return '$city ausgewählt';
  }

  @override
  String channelSoundPrefix(String soundName) {
    return 'Ton: $soundName';
  }

  @override
  String get channelSilentPrayers => 'Stumme Gebetsbenachrichtigungen';

  @override
  String get tickerEzan => 'Gebetszeit';

  @override
  String get stickyChannelName => 'Dauerhafter Timer';

  @override
  String get stickyChannelDesc =>
      'Zeigt die verbleibende Zeit für das Gebet an';

  @override
  String get timeLeftTo => 'Verbleibende Zeit bis: ';

  @override
  String get locationFallbackMessage =>
      'Standort konnte nicht abgerufen werden, Standardwert wird verwendet.';

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
      'Berechnen Sie Ihre Zakat detailliert nach den Fatwas des Präsidiums für Religionsangelegenheiten und den aktuellen Ankaufs-/Verkaufskursen des Marktes.';

  @override
  String get cashAndCurrencyTitle => 'Bargeld und Währungsvermögen';

  @override
  String get cashTurkishLira => 'Bargeld Türkische Lira (TRY)';

  @override
  String get goldAndSilverTitle => 'Gold und Silber';

  @override
  String get silverGram => 'Silber (Gramm)';

  @override
  String get unitPrice => 'Stückpreis';

  @override
  String get commercialGoodsTitle => 'Handelswaren';

  @override
  String get commercialEvalCurrency => 'Bewertungswährung';

  @override
  String get commercialGoodsValue => 'Warenwert';

  @override
  String get exchangeRateValue => 'Wechselkurs';

  @override
  String get receivablesTitle => 'Forderungen (Einbringlich)';

  @override
  String get receivableType => 'Art der Forderung (TRY, Fremdwährung, Gold)';

  @override
  String get amountOrCount => 'Menge / Anzahl';

  @override
  String get otherAssetsTitle => 'Sonstige Vermögenswerte';

  @override
  String get assetType => 'Anlageklasse';

  @override
  String get currencyLabel => 'Währung';

  @override
  String get valueOrAmount => 'Wert / Menge';

  @override
  String get agriProductsTitle => 'Landwirtschaftliche Produkte (Uschr)';

  @override
  String get agriDiyanetNote =>
      'Da bei der Zakat-Berechnung landwirtschaftlicher Produkte kein Nisab-Betrag erforderlich ist, wird der von Ihnen deklarierte Betrag direkt zum Zakat-Korb hinzugefügt.';

  @override
  String get harvestedProductValue => 'Geernteter Produktwert (TRY)';

  @override
  String get irrigationMethod => 'Bewässerungsmethode';

  @override
  String get debtsTitle => 'Schulden (Abzuziehen)';

  @override
  String get debtType => 'Schuldenart (TRY, Fremdwährung, Gold)';

  @override
  String get zakatAgriIncluded =>
      'Inklusive Zakat für landwirtschaftliche Produkte (Uschr)';

  @override
  String get assetCheck => 'Scheck';

  @override
  String get assetBond => 'Schuldschein';

  @override
  String get assetSukuk => 'Sukuk';

  @override
  String get assetLeaseCert => 'Leasingzertifikat';

  @override
  String get assetStock => 'Aktie';

  @override
  String get agriSoil => 'Landwirtschaftliches Produkt (Bodenbau)';

  @override
  String get agriSoilless => 'Landwirtschaftliches Produkt (Bodenloser Anbau)';

  @override
  String get agriRateNoCost => 'Kostenlos (Regen/Fluss) - 10%';

  @override
  String get agriRateCostly => 'Kostenpflichtig (Motor/Transport) - 5%';

  @override
  String get toImsak => 'Bis Fadschr';

  @override
  String get toGunes => 'Bis Sonnenaufgang';

  @override
  String get toOgle => 'Bis Duhur';

  @override
  String get toIkindi => 'Bis Asr';

  @override
  String get toAksam => 'Bis Maghrib';

  @override
  String get toYatsi => 'Bis Ischa';

  @override
  String get lowAccuracyWarning =>
      'Kompasskalibrierung ist schwach. Bitte zeichnen Sie eine \'8\' in die Luft.';

  @override
  String get qiblaDirection => 'Qibla-Richtung';

  @override
  String get zikirmatikTitle => 'Dhikr Zähler';

  @override
  String get dhikrSubhanallah => 'Subhanallah';

  @override
  String get dhikrElhamdulillah => 'Alhamdulillah';

  @override
  String get dhikrAllahuEkber => 'Allahu Akbar';

  @override
  String get dhikrKalima => 'Kalima';

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
  String get dhikrOther => 'Andere (Eigener Dhikr)';

  @override
  String get customDhikrTitle => 'Eigenen Dhikr hinzufügen';

  @override
  String get customDhikrHint => 'Geben Sie hier Ihren Dhikr ein';

  @override
  String get zikirSettings => 'الإعدادات';

  @override
  String get vibration => 'اهتزاز';

  @override
  String get sound => 'تأثير الصوت';

  @override
  String get keepAwake => 'إبقاء الشاشة قيد التشغيل';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeModern => 'زر حديث';

  @override
  String get themeClassic => 'تسبيح كلاسيكي';

  @override
  String get introTitle1 => 'Willkommen bei Vaktinde';

  @override
  String get introDesc1 =>
      'Verfolgen Sie Gebetszeiten, Ihre Dhikrs und religiöse Tage ganz einfach mit einer modernen und eleganten Benutzeroberfläche.';

  @override
  String get introTitle2 => 'Intelligente Benachrichtigungen';

  @override
  String get introDesc2 =>
      'Lassen Sie sich zu den Gebetszeiten mit Ihrem bevorzugten Ton benachrichtigen. Verpassen Sie nie wieder Ihre Gebete.';

  @override
  String get introTitle3 => 'Erweiterte Werkzeuge';

  @override
  String get introDesc3 =>
      'Stärken Sie Ihre Spiritualität mit Werkzeugen wie dem animierten Dhikr-Zähler, verpassten Gebeten und dem Zakat-Rechner.';

  @override
  String get introSkip => 'Überspringen';

  @override
  String get introNext => 'Weiter';

  @override
  String get introStart => 'Loslegen';

  @override
  String get dhikrListTitle => 'Dhikr-Liste';

  @override
  String get addCustomDhikr => 'Benutzerdefinierten Dhikr hinzufügen';

  @override
  String get customDhikrAdded => 'Dhikr erfolgreich hinzugefügt.';

  @override
  String get customDhikrLimit =>
      'Sie können bis zu 20 benutzerdefinierte Dhikrs hinzufügen!';

  @override
  String get deleteDhikr => 'Löschen';

  @override
  String get statisticsTitle => 'Statistiken';

  @override
  String get monthly => 'Monatlich';

  @override
  String get yearly => 'Jährlich';

  @override
  String get totalDhikr => 'Gesamte Dhikrs';

  @override
  String get today => 'Heute';

  @override
  String get statsEmpty => 'Noch keine Dhikr-Daten vorhanden.';

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
  String get dhikrYaAllah => 'Ya Allah';

  @override
  String get dhikrYaRahman => 'Ya Rahman';

  @override
  String get dhikrYaRahim => 'Ya Rahim';

  @override
  String get dhikrYaSafi => 'Ya Schafi';

  @override
  String get dhikrYaRezzak => 'Ya Razzak';

  @override
  String get dhikrYaFettah => 'Ya Fattah';

  @override
  String get mainDhikrs => 'Haupt-Dhikrs';

  @override
  String get esmaulHusnaTab => 'Esmaul Husna';

  @override
  String get qiblaCalibration =>
      'Zeichnen Sie eine \'8\' in die Luft mit Ihrem Telefon, um den Kompass zu kalibrieren.';
}
