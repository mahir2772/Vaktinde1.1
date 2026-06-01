// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Vaktinde';

  @override
  String get nextPrayer => 'Next Prayer';

  @override
  String get hadithTitle => 'Hadith of the Day';

  @override
  String get readMore => 'Read More...';

  @override
  String get share => 'Share';

  @override
  String get close => 'Close';

  @override
  String get loading => 'Calculating Times...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get noData => 'No data.';

  @override
  String get imsak => 'Fajr';

  @override
  String get gunes => 'Sunrise';

  @override
  String get ogle => 'Dhuhr';

  @override
  String get ikindi => 'Asr';

  @override
  String get aksam => 'Maghrib';

  @override
  String get yatsi => 'Isha';

  @override
  String get exactAlarm => 'Notify at Exact Time';

  @override
  String get exactAlarmSub => 'Sends a notification.';

  @override
  String get silentNotif => 'Text Notification Only';

  @override
  String get silentNotifSub => 'No sound/Adhan, just a notification.';

  @override
  String warningAlarm(String minute) {
    return 'Remind $minute min Before';
  }

  @override
  String get warningAlarmSub => 'Short notification sound.';

  @override
  String get settings => 'Settings';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get waitingLocation => 'Waiting for Location...';

  @override
  String get noInternet => 'No internet connection and no saved data found.';

  @override
  String get gpsOff => 'GPS is off. Please enable location.';

  @override
  String get permissionDenied => 'Location permission denied.';

  @override
  String get locationError => 'Could not get location.';

  @override
  String get internetNeeded => 'Internet connection required.';

  @override
  String get soundEzan => 'Adhan';

  @override
  String get soundBeep => 'Short Beep';

  @override
  String get notifTitleTime => 'Prayer Time';

  @override
  String notifBodyTime(String vakit) {
    return 'It is time for $vakit.';
  }

  @override
  String get notifTitleUpcoming => 'Time Approaching';

  @override
  String notifBodyUpcoming(String vakit, int minute) {
    return '$minute minutes left for $vakit.';
  }

  @override
  String get navPrayer => 'Times';

  @override
  String get navQibla => 'Qibla';

  @override
  String get navMenu => 'Menu';

  @override
  String get menuTitle => 'Settings';

  @override
  String get sectionLocation => 'LOCATION & TIMES';

  @override
  String get changeLocation => 'Change Location';

  @override
  String get citySelect => 'Select City';

  @override
  String get districtSelect => 'Select District';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get locationWarning =>
      'Selecting a district is important for accurate prayer times.';

  @override
  String get menuNotifications => 'Notification Permissions';

  @override
  String get menuNotificationsSub => 'Check here if you don\'t hear sounds.';

  @override
  String get menuTroubleshoot => 'Notifications Not Working?';

  @override
  String get menuTroubleshootSub => 'Battery settings for Samsung/Xiaomi.';

  @override
  String get sectionSupport => 'SUPPORT';

  @override
  String get shareApp => 'Share with Friends';

  @override
  String get rateApp => 'Rate Us';

  @override
  String get contactUs => 'Contact & Report Bug';

  @override
  String shareText(String link) {
    return 'I found a great Prayer Times app! Download: $link';
  }

  @override
  String get batteryDialogTitle => 'Fix Notification Issues';

  @override
  String get batteryDialogBody =>
      'Your phone might be killing the app to save battery. To prevent this:\n\n1. Open Recent Apps (Square button).\n2. Long press \'Vaktinde\' app or click the logo.\n3. Tap the Lock Icon 🔒 to lock it.\n\nAlso go to Settings > Apps > Vaktinde > Battery > Unrestricted.';

  @override
  String get okUnderstood => 'OK, Understood';

  @override
  String get religiousDaysTitle => 'Religious Days';

  @override
  String errorOccurred(String error) {
    return 'Error occurred: $error';
  }

  @override
  String get noDataFound => 'No data found.';

  @override
  String noDataForYear(int year) {
    return 'No data found for the year $year.';
  }

  @override
  String religiousDaysListTitle(int year) {
    return '$year Religious Days List';
  }

  @override
  String get missedPrayersTitle => 'Missed Prayers';

  @override
  String get missedPrayersInfo =>
      'Track your missed prayers here and decrease as you perform them.\n(Tap the number to enter manually)';

  @override
  String editMissedTitle(String title) {
    return 'Edit $title Missed';
  }

  @override
  String get missedCountLabel => 'Missed Count';

  @override
  String get missedCountHint => 'Ex: 150';

  @override
  String get sabah => 'Fajr';

  @override
  String get vitir => 'Witr';

  @override
  String get oruc => 'Fasting';

  @override
  String timeLeftFor(String vakit) {
    return 'Time left for $vakit';
  }

  @override
  String get tomorrow => '(Tomorrow)';

  @override
  String get fridayMessagesTitle => 'Friday Messages';

  @override
  String get esmaulHusnaTitle => '99 Names of Allah';

  @override
  String get closeCaps => 'CLOSE';

  @override
  String get zakatTitle => 'Zakat Calculator';

  @override
  String get zakatCalculatorTitle => 'Smart Zakat Calculator';

  @override
  String get liveRatesLoading => 'Fetching live rates...';

  @override
  String get liveRatesInfo =>
      'You can manually adjust the auto-fetched rates if needed.';

  @override
  String get sectionGold => 'Gold Assets';

  @override
  String get goldType => 'Gold Type';

  @override
  String get goldAmount => 'Quantity / Gram';

  @override
  String get goldUnitPrice => 'Unit Price (TL)';

  @override
  String get sectionCurrency => 'Currency Assets';

  @override
  String get currencyType => 'Currency Type';

  @override
  String get currencyAmount => 'Amount';

  @override
  String get currencyRate => 'Current Rate (TL)';

  @override
  String get sectionCashDebt => 'Cash & Debts';

  @override
  String get cashAmount => 'Cash on Hand & Bank (TL)';

  @override
  String get debtAmount => 'Total Debts (To Deduct)';

  @override
  String get calculateButton => 'CALCULATE';

  @override
  String get zakatResultTitle => 'Zakat Payable';

  @override
  String get netAssets => 'Net Assets:';

  @override
  String get qiblaTitle => 'Qibla Compass';

  @override
  String get locationServiceOff =>
      'Location service is disabled. Please enable location.';

  @override
  String get locationPermissionDenied => 'Location permission denied.';

  @override
  String get locationPermissionForever =>
      'Location permission permanently denied. Enable from settings.';

  @override
  String compassError(String error) {
    return 'Sensor error: $error';
  }

  @override
  String get noCompass => 'No compass on device.';

  @override
  String get qiblaFound => 'YOU FOUND THE QIBLA!';

  @override
  String qiblaAngle(String angle) {
    return 'Qibla Angle: $angle°';
  }

  @override
  String get keepAwayMetal => 'Keep away from metal objects.';

  @override
  String get goldGram => 'Gram Gold (24K)';

  @override
  String get goldQuarter => 'Quarter Gold';

  @override
  String get goldFull => 'Full Gold';

  @override
  String get typeOther => 'Other (Manual)';

  @override
  String get usd => 'US Dollar (USD)';

  @override
  String get eur => 'Euro (EUR)';

  @override
  String get gbp => 'British Pound (GBP)';

  @override
  String get sectionAppearance => 'APPEARANCE & LANGUAGE';

  @override
  String get appearanceSettings => 'Appearance Settings';

  @override
  String get appearanceSub => 'Theme & Background';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get bgImage => 'Background Image';

  @override
  String get bgDefault => 'Default';

  @override
  String get bgMosque => 'Mosque';

  @override
  String get bgKaaba => 'Kaaba';

  @override
  String get bgQuran => 'Quran';

  @override
  String get none => 'None';

  @override
  String get zakatEligible => 'Zakat is Required';

  @override
  String get zakatNotEligible => 'Zakat Not Required';

  @override
  String get nisabLimit => 'Nisab Threshold (80.18g Gold)';

  @override
  String get belowNisabMessage =>
      'Zakat is not obligatory because your net assets are below the Nisab threshold.';

  @override
  String get searchLocationTitle => 'Search Location (Worldwide)';

  @override
  String get searchLocationHint => 'City or Country (Ex: Paris)';

  @override
  String get searchInitial => 'Type to search...';

  @override
  String get searchNotFound => 'Location not found.';

  @override
  String get searchError => 'No results found. Please try again.';

  @override
  String locationSelected(String city) {
    return '$city selected';
  }

  @override
  String channelSoundPrefix(String soundName) {
    return 'Sound: $soundName';
  }

  @override
  String get channelSilentPrayers => 'Silent Prayer Notifications';

  @override
  String get tickerEzan => 'Prayer Time';

  @override
  String get stickyChannelName => 'Persistent Timer';

  @override
  String get stickyChannelDesc => 'Shows the remaining time for the prayer';

  @override
  String get timeLeftTo => 'Time left to: ';

  @override
  String get locationFallbackMessage =>
      'Location could not be retrieved, using default value.';

  @override
  String get fetchingLocation => 'Fetching location...';

  @override
  String get directionNorth => 'N';

  @override
  String get directionSouth => 'S';

  @override
  String get directionEast => 'E';

  @override
  String get directionWest => 'W';

  @override
  String get calibrationInstruction => '(Draw an \'8\' to calibrate)';

  @override
  String get zakatDescription =>
      'Calculate your zakat in detail according to the fatwas of the Presidency of Religious Affairs and current market buy/sell rates.';

  @override
  String get cashAndCurrencyTitle => 'Cash and Currency Assets';

  @override
  String get cashTurkishLira => 'Cash Turkish Lira (TRY)';

  @override
  String get goldAndSilverTitle => 'Gold and Silver';

  @override
  String get silverGram => 'Silver (Gram)';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get commercialGoodsTitle => 'Commercial Goods';

  @override
  String get commercialEvalCurrency => 'Valuation Currency Type';

  @override
  String get commercialGoodsValue => 'Value of Goods';

  @override
  String get exchangeRateValue => 'Exchange Rate Value';

  @override
  String get receivablesTitle => 'Receivables (Collectible)';

  @override
  String get receivableType =>
      'Type of Receivable (TRY, Foreign Currency, Gold)';

  @override
  String get amountOrCount => 'Amount / Count';

  @override
  String get otherAssetsTitle => 'Other Assets';

  @override
  String get assetType => 'Asset Type';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get valueOrAmount => 'Value / Amount';

  @override
  String get agriProductsTitle => 'Agricultural Products (Ushr)';

  @override
  String get agriDiyanetNote =>
      'Since the nisab amount is not required in the zakat calculation of agricultural products, the amount you declare is directly added to the zakat basket.';

  @override
  String get harvestedProductValue => 'Harvested Product Value (TRY)';

  @override
  String get irrigationMethod => 'Irrigation Method';

  @override
  String get debtsTitle => 'Debts (To be Deducted)';

  @override
  String get debtType => 'Debt Type (TRY, Foreign Currency, Gold)';

  @override
  String get zakatAgriIncluded => 'Agricultural Product (Ushr) Zakat Included';

  @override
  String get assetCheck => 'Cheque';

  @override
  String get assetBond => 'Bond';

  @override
  String get assetSukuk => 'Sukuk';

  @override
  String get assetLeaseCert => 'Lease Certificate';

  @override
  String get assetStock => 'Stock';

  @override
  String get agriSoil => 'Agricultural Product (Soil Farming)';

  @override
  String get agriSoilless => 'Agricultural Product (Soilless Farming)';

  @override
  String get agriRateNoCost => 'Costless (Rain/River) - 10%';

  @override
  String get agriRateCostly => 'Costly (Motor/Transport) - 5%';

  @override
  String get toImsak => 'To Fajr';

  @override
  String get toGunes => 'To Sunrise';

  @override
  String get toOgle => 'To Dhuhr';

  @override
  String get toIkindi => 'To Asr';

  @override
  String get toAksam => 'To Maghrib';

  @override
  String get toYatsi => 'To Isha';

  @override
  String get lowAccuracyWarning =>
      'Compass calibration is poor. Please draw an \'8\' in the air.';

  @override
  String get qiblaDirection => 'Qibla Direction';

  @override
  String get zikirmatikTitle => 'Dhikr Counter';

  @override
  String get dhikrSubhanallah => 'Subhanallah';

  @override
  String get dhikrElhamdulillah => 'Alhamdulillah';

  @override
  String get dhikrAllahuEkber => 'Allahu Akbar';

  @override
  String get dhikrKalima => 'Kalima Tayyibah';

  @override
  String get dhikrSalavat => 'Salawat';

  @override
  String get targetReached => 'Target Reached!';

  @override
  String get resetCounter => 'Reset';

  @override
  String targetCount(int target) {
    return 'Target: $target';
  }

  @override
  String get setTarget => 'Set Target';

  @override
  String get dhikrOther => 'Other (Custom Dhikr)';

  @override
  String get customDhikrTitle => 'Add Custom Dhikr';

  @override
  String get customDhikrHint => 'Enter your dhikr here';

  @override
  String get zikirSettings => 'Settings';

  @override
  String get vibration => 'Vibration';

  @override
  String get sound => 'Sound Effect';

  @override
  String get keepAwake => 'Keep Screen Awake';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeModern => 'Modern Button';

  @override
  String get themeClassic => 'Classic Tasbih';

  @override
  String get introTitle1 => 'Welcome to Vaktinde';

  @override
  String get introDesc1 =>
      'Easily track prayer times, your dhikrs, and religious days with a modern and elegant interface.';

  @override
  String get introTitle2 => 'Smart Notifications';

  @override
  String get introDesc2 =>
      'Get notified with your preferred sound at prayer times. Never miss your prayers.';

  @override
  String get introTitle3 => 'Advanced Tools';

  @override
  String get introDesc3 =>
      'Strengthen your spirituality with tools like Animated Dhikr Counter, Missed Prayers, and Zakat Calculator.';

  @override
  String get introSkip => 'Skip';

  @override
  String get introNext => 'Next';

  @override
  String get introStart => 'Get Started';

  @override
  String get dhikrListTitle => 'Dhikr List';

  @override
  String get addCustomDhikr => 'Add Custom Dhikr';

  @override
  String get customDhikrAdded => 'Dhikr added successfully.';

  @override
  String get customDhikrLimit => 'You can add up to 20 custom dhikrs!';

  @override
  String get deleteDhikr => 'Delete';

  @override
  String get statisticsTitle => 'Statistics';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get totalDhikr => 'Total Dhikrs';

  @override
  String get today => 'Today';

  @override
  String get statsEmpty => 'No dhikr data yet.';

  @override
  String get dhikrEstagfirullah => 'Astaghfirullah';

  @override
  String get dhikrLaHavle => 'La Hawla wa la Quwwata';

  @override
  String get dhikrHasbunallah => 'Hasbunallah';

  @override
  String get dhikrSubhanallahi => 'Subhanallahi wa bihamdihi';

  @override
  String get dhikrYunus => 'Prayer of Prophet Yunus';

  @override
  String get dhikrYaAllah => 'Ya Allah';

  @override
  String get dhikrYaRahman => 'Ya Rahman';

  @override
  String get dhikrYaRahim => 'Ya Rahim';

  @override
  String get dhikrYaSafi => 'Ya Shafi';

  @override
  String get dhikrYaRezzak => 'Ya Razzaq';

  @override
  String get dhikrYaFettah => 'Ya Fattah';

  @override
  String get mainDhikrs => 'Main Dhikrs';

  @override
  String get esmaulHusnaTab => 'Esmaul Husna';

  @override
  String get qiblaCalibration =>
      'Draw an \'8\' in the air with your phone for accurate compass calibration.';
}
