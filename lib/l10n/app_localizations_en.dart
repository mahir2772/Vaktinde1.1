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
  String get imsak => 'Imsak';

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
  String get exactAlarm => 'Read Exactly on Time';

  @override
  String get exactAlarmSub => 'Sends a notification.';

  @override
  String get silentNotif => 'Text Notification Only';

  @override
  String get silentNotifSub => 'No Adhan/Sound, only visual alert.';

  @override
  String warningAlarm(String minute) {
    return 'Warn $minute mins Before';
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
  String get internetNeeded => 'Internet connection is required.';

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
  String get notifTitleUpcoming => 'Time is Approaching';

  @override
  String notifBodyUpcoming(String vakit, int minute) {
    return '$minute minutes left until $vakit.';
  }

  @override
  String get navPrayer => 'Home';

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
  String get menuTroubleshoot => 'Not Getting Notifications?';

  @override
  String get menuTroubleshootSub => 'Set battery settings for Samsung/Xiaomi.';

  @override
  String get sectionSupport => 'SUPPORT';

  @override
  String get shareApp => 'Share with a Friend';

  @override
  String get rateApp => 'Rate Us';

  @override
  String get contactUs => 'Contact & Report Bug';

  @override
  String shareText(String link) {
    return 'I found a great Prayer Time app! Download it here: $link';
  }

  @override
  String get batteryDialogTitle => 'Notification Issue Solution';

  @override
  String get batteryDialogBody =>
      'Your phone might be closing the app to save battery. To prevent this:\n\n1. Open the Recent Apps screen.\n2. Long press the \'Vaktinde\' app or tap its logo.\n3. Tap the Lock Icon 🔒 to lock it.\n\nAlso, go to Settings > Apps > Vaktinde > Battery > Select Unrestricted.';

  @override
  String get okUnderstood => 'OK, I Understand';

  @override
  String get religiousDaysTitle => 'Religious Days';

  @override
  String errorOccurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get noDataFound => 'No data found.';

  @override
  String noDataForYear(int year) {
    return 'No data found for the year $year.';
  }

  @override
  String religiousDaysListTitle(int year) {
    return 'Religious Days List for $year';
  }

  @override
  String get missedPrayersTitle => 'Missed Prayers Tracker';

  @override
  String get missedPrayersInfo =>
      'Note your missed prayers here and subtract as you pray them.\n(Tap the number to enter manually)';

  @override
  String editMissedTitle(String title) {
    return 'Edit Missed $title';
  }

  @override
  String get missedCountLabel => 'Missed Count';

  @override
  String get missedCountHint => 'E.g.: 150';

  @override
  String get sabah => 'Fajr';

  @override
  String get vitir => 'Witr';

  @override
  String get oruc => 'Fasting';

  @override
  String timeLeftFor(String vakit) {
    return 'Time Left for $vakit';
  }

  @override
  String get tomorrow => '(Tomorrow)';

  @override
  String get fridayMessagesTitle => 'Friday Messages';

  @override
  String get esmaulHusnaTitle => 'Names of Allah';

  @override
  String get closeCaps => 'CLOSE';

  @override
  String get zakatTitle => 'Zakat Calculator';

  @override
  String get zakatCalculatorTitle => 'Smart Zakat Calculator';

  @override
  String get liveRatesLoading => 'Fetching current exchange rates...';

  @override
  String get liveRatesInfo =>
      'You can manually edit the automatically fetched rates if you wish.';

  @override
  String get sectionGold => 'Gold Assets';

  @override
  String get goldType => 'Gold Type';

  @override
  String get goldAmount => 'Quantity / Grams';

  @override
  String get goldUnitPrice => 'Unit Price';

  @override
  String get sectionCurrency => 'Currency Assets';

  @override
  String get currencyType => 'Currency Type';

  @override
  String get currencyAmount => 'Amount';

  @override
  String get currencyRate => 'Current Rate';

  @override
  String get sectionCashDebt => 'Cash & Debts';

  @override
  String get cashAmount => 'Cash on Hand & in Bank';

  @override
  String get debtAmount => 'Total Debts (To be deducted)';

  @override
  String get calculateButton => 'CALCULATE';

  @override
  String get zakatResultTitle => 'Your Payable Zakat';

  @override
  String get netAssets => 'Net Assets:';

  @override
  String get qiblaTitle => 'Qibla Compass';

  @override
  String get locationServiceOff =>
      'Location service is off. Please enable location.';

  @override
  String get locationPermissionDenied => 'Location permission denied.';

  @override
  String get locationPermissionForever =>
      'Location permission is permanently denied. Please enable it in settings.';

  @override
  String compassError(String error) {
    return 'Sensor error: $error';
  }

  @override
  String get noCompass => 'No compass on this device.';

  @override
  String get qiblaFound => 'YOU FOUND THE QIBLA!';

  @override
  String qiblaAngle(String angle) {
    return 'Qibla Angle: $angle°';
  }

  @override
  String get keepAwayMetal => 'Keep away from metal objects.';

  @override
  String get goldGram => 'Gram Gold (24 Carat)';

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
  String get appearanceSub => 'Theme and Background';

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
  String get zakatNotEligible => 'Zakat is Not Required';

  @override
  String get nisabLimit => 'Nisab Limit (80.18 g Gold)';

  @override
  String get belowNisabMessage =>
      'Since your net assets are below the Nisab amount (wealth limit), Zakat is not obligatory.';

  @override
  String get searchLocationTitle => 'Search Location (Worldwide)';

  @override
  String get searchLocationHint => 'City or Country (E.g.: Paris)';

  @override
  String get searchInitial => 'Type the place you want to search...';

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
  String get channelSilentPrayers => 'Silent Adhan Notifications';

  @override
  String get tickerEzan => 'Prayer Time';

  @override
  String get stickyChannelName => 'Persistent Counter';

  @override
  String get stickyChannelDesc => 'Shows the remaining time';

  @override
  String get timeLeftTo => 'Time Left Until: ';

  @override
  String get locationFallbackMessage =>
      'Could not get location, using default values.';

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
  String get calibrationInstruction => '(Draw an \'8\' for calibration)';

  @override
  String get zakatDescription =>
      'Calculate your Zakat in detail according to religious guidelines and current market rates.';

  @override
  String get cashAndCurrencyTitle => 'Cash and Currency Assets';

  @override
  String get cashTurkishLira => 'Cash (Local Currency)';

  @override
  String get goldAndSilverTitle => 'Gold and Silver';

  @override
  String get silverGram => 'Silver (Grams)';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get commercialGoodsTitle => 'Commercial Goods';

  @override
  String get commercialEvalCurrency => 'Valuation Currency';

  @override
  String get commercialGoodsValue => 'Goods Value';

  @override
  String get exchangeRateValue => 'Exchange Rate';

  @override
  String get receivablesTitle => 'Receivables (Collectable)';

  @override
  String get receivableType => 'Type (Cash, Currency, Gold)';

  @override
  String get amountOrCount => 'Amount / Quantity';

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
      'Since Nisab is not required for agricultural products, the amount you declare is directly added to your Zakat total.';

  @override
  String get harvestedProductValue => 'Harvested Product Value';

  @override
  String get irrigationMethod => 'Irrigation Method';

  @override
  String get debtsTitle => 'Debts (To be deducted)';

  @override
  String get debtType => 'Debt Type (Cash, Currency, Gold)';

  @override
  String get zakatAgriIncluded => 'Included Agricultural Zakat (Ushr)';

  @override
  String get assetCheck => 'Check';

  @override
  String get assetBond => 'Promissory Note';

  @override
  String get assetSukuk => 'Sukuk';

  @override
  String get assetLeaseCert => 'Lease Certificate';

  @override
  String get assetStock => 'Stock';

  @override
  String get agriSoil => 'Agriculture (Soil)';

  @override
  String get agriSoilless => 'Agriculture (Soilless)';

  @override
  String get agriRateNoCost => 'No Cost (Rain/River) - 10%';

  @override
  String get agriRateCostly => 'Costly (Motor/Transport) - 5%';

  @override
  String get toImsak => 'To Imsak';

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
      'Compass calibration is weak. Please draw an \'8\' in the air with your phone.';

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
  String get customDhikrHint => 'Type your dhikr';

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
      'Easily track prayer times, dhikrs, and religious days with our modern and elegant interface.';

  @override
  String get introTitle2 => 'Smart Notifications';

  @override
  String get introDesc2 =>
      'Get alerts with the notification sound of your choice at prayer times. Never miss your worship.';

  @override
  String get introTitle3 => 'Advanced Tools';

  @override
  String get introDesc3 =>
      'Strengthen your spirituality with the Animated Dhikr Counter, Missed Prayers Tracker, Names of Allah, and Zakat Calculator.';

  @override
  String get introSkip => 'Skip';

  @override
  String get introNext => 'Next';

  @override
  String get introStart => 'Start Now';

  @override
  String get dhikrListTitle => 'Dhikr List';

  @override
  String get addCustomDhikr => 'Add New Custom Dhikr';

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
  String get totalDhikr => 'Total Dhikr Count';

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
  String get mainDhikrs => 'Basic Dhikrs';

  @override
  String get esmaulHusnaTab => 'Names of Allah';

  @override
  String get qiblaCalibration =>
      'For the compass to work accurately, please draw an \'8\' in the air with your phone.';

  @override
  String get hicriYilbasi => 'Islamic New Year';

  @override
  String get asureGunu => 'Day of Ashura';

  @override
  String get mevlidKandili => 'Mawlid al-Nabi';

  @override
  String get miracKandili => 'Isra and Mi\'raj';

  @override
  String get beratKandili => 'Mid-Sha\'ban (Bara\'at)';

  @override
  String get ramazanBaslangici => 'Start of Ramadan';

  @override
  String get kadirGecesi => 'Laylat al-Qadr';

  @override
  String get ramazanBayrami => 'Eid al-Fitr';

  @override
  String get kurbanBayrami => 'Eid al-Adha';

  @override
  String get regaipKandili => 'Laylat al-Raghaib';

  @override
  String get tabTimes => 'Times';

  @override
  String get tabAlarms => 'Alarms';

  @override
  String get locationFoundNoName => 'Location found but no name.';

  @override
  String get dailyAyahTitle => 'Ayah of the Day';

  @override
  String get remainingTime => 'Remaining';

  @override
  String get onboardingWelcome => 'Hoş Geldiniz / Welcome';

  @override
  String get onboardingSelectLanguage =>
      'Lütfen kullanmak istediğiniz dili seçin.\nPlease select your preferred language.';

  @override
  String get turnRight => 'Turn right ➔';

  @override
  String get turnSlightRight => 'Turn slight right ➔';

  @override
  String get turnLeft => '⬅ Turn left';

  @override
  String get turnSlightLeft => '⬅ Turn slight left';

  @override
  String get calibrationRequired => 'Calibration Required';

  @override
  String get gold22kGram => '22 Carat Gram Gold';

  @override
  String get goldAtaToptan => 'Ata Wholesale';

  @override
  String get goldAtaCumhuriyet => 'Ata Cumhuriyet';

  @override
  String get gold22kBracelet => '22 Carat Bracelet';

  @override
  String get gold18k => '18 Carat Gold';

  @override
  String get gold14k => '14 Carat Gold';

  @override
  String get goldHalf => 'Half Gold';

  @override
  String get goldGremse => 'Gremse Gold';

  @override
  String get goldAtaBesli => 'Ata Besli';

  @override
  String get goldResat => 'Resat Gold';

  @override
  String get goldHamit => 'Hamit Gold';

  @override
  String get currencyChf => 'Swiss Franc';

  @override
  String get currencyJpy => 'Japanese Yen';

  @override
  String get currencySar => 'Saudi Riyal';

  @override
  String get currencyAud => 'Australian Dollar';

  @override
  String get currencyCad => 'Canadian Dollar';

  @override
  String get currencyRub => 'Russian Ruble';

  @override
  String get currencyAzn => 'Azerbaijani Manat';

  @override
  String get currencyCny => 'Chinese Yuan';

  @override
  String get currencyRon => 'Romanian Leu';

  @override
  String get currencyAed => 'UAE Dirham';

  @override
  String get currencyBgn => 'Bulgarian Lev';

  @override
  String get currencyKwd => 'Kuwaiti Dinar';

  @override
  String get currencyTry => 'Turkish Lira';

  @override
  String get holdToEdit => '(Hold to edit)';

  @override
  String get editCounterTitle => 'Edit Counter';

  @override
  String get editCounterHint => 'E.g.: 2000';

  @override
  String get editTargetHint => 'E.g.: 99';

  @override
  String get resetCounterConfirm =>
      'Are you sure you want to reset the counter?';

  @override
  String get dhikrTarget => 'Target:';
}
