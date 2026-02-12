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
}
