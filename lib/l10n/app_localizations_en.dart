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
  String get navZikir => 'Dhikr';

  @override
  String get adPrivacySettings => 'Ad Privacy Settings';

  @override
  String get adPrivacySettingsSub => 'Change your consent for personalised ads';

  @override
  String get showcaseLanguage => 'You can change the app language here.';

  @override
  String get showcaseStory => 'Read the ayah and hadith of the day here.';

  @override
  String get showcaseAlarms =>
      'Set adhan and reminder alarms for each prayer here.';

  @override
  String get showcaseQibla => 'Find the Qibla direction with the compass.';

  @override
  String get showcaseZikir => 'Keep track of your dhikr here.';

  @override
  String get refreshLocation => 'Refresh location';

  @override
  String get navTools => 'Tools';

  @override
  String get hadithNotFound => 'Hadith text not found.';

  @override
  String get timesLoadError =>
      'Prayer times could not be loaded. Please try again.';

  @override
  String get sunriseNotPrayer => 'Sunrise, not a prayer time';

  @override
  String get currentPrayer => 'Current prayer';

  @override
  String get textCopied => 'Text copied';

  @override
  String get updateDownloaded => 'A new version has been downloaded.';

  @override
  String get restartAction => 'Restart';

  @override
  String get qiblaTurnRight => 'Turn right';

  @override
  String get qiblaTurnSlightRight => 'Turn slightly right';

  @override
  String get qiblaTurnLeft => 'Turn left';

  @override
  String get qiblaTurnSlightLeft => 'Turn slightly left';

  @override
  String phoneHeading(String deg) {
    return 'Phone heading: $deg°';
  }

  @override
  String get usingSavedLocation => 'Using your saved location.';

  @override
  String exampleHint(int n) {
    return 'E.g. $n';
  }

  @override
  String get noCustomDhikr => 'You haven\'t added a custom dhikr yet.';

  @override
  String get messagesShuffled => 'Messages shuffled';

  @override
  String get shareAsImage => 'Share as image';

  @override
  String get shareAsText => 'Share text';

  @override
  String get shareCardFooter => 'Vaktinde on Google Play';

  @override
  String get fridayGreeting => 'Jumu\'ah Mubarak';

  @override
  String get sendGreeting => 'Send greetings';

  @override
  String get greetingsTitle => 'Greeting messages';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get copy => 'Copy';

  @override
  String get messageCopied => 'Message copied';

  @override
  String versionLabel(String v) {
    return 'Version $v';
  }

  @override
  String get supportMailSubject => 'Vaktinde - Support';

  @override
  String get madeBy => 'Made with ❤️ by mmdigital';

  @override
  String get permissionPrimingTitle => 'Never miss a prayer time';

  @override
  String get permissionPrimingBody =>
      'We need notification permission for adhan alerts and location permission to calculate prayer times where you are.';

  @override
  String get continueAction => 'Continue';

  @override
  String get nextPrayer => 'Next Prayer';

  @override
  String get hadithTitle => 'Hadith of the Day';

  @override
  String get share => 'Share';

  @override
  String get close => 'Close';

  @override
  String get loading => 'Calculating Times...';

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
  String get exactAlarm => 'Alert at Prayer Time';

  @override
  String get reminderTitleAt => 'Prayer Time Reminder';

  @override
  String notifBodyUpcomingAt(String vakit, String time) {
    return '$vakit time: $time';
  }

  @override
  String get endReminderTitleAt => 'End of Prayer Time';

  @override
  String endReminderNotifBodyAt(String vakit, String time) {
    return 'End of $vakit time: $time';
  }

  @override
  String ramadanImsakBodyAt(String time) {
    return 'Suhoor time ended at $time. Have a blessed fast!';
  }

  @override
  String get alarmHealthExactOff =>
      'Alarm permission is off: the adhan and reminders can be up to about an hour late (including imsak and suhoor).';

  @override
  String get healthTitle => 'Notification Check';

  @override
  String get healthSub =>
      'If the adhan doesn\'t play, check your settings step by step';

  @override
  String get healthSectionStatus => 'Status';

  @override
  String get healthEzansTitle => 'Adhan alarms';

  @override
  String healthEzansOn(String names) {
    return 'On: $names';
  }

  @override
  String get healthEzansNone => 'The adhan isn\'t turned on for any prayer.';

  @override
  String get healthNextTitle => 'Next adhan';

  @override
  String get healthNextNone => 'No scheduled adhan found.';

  @override
  String get healthReschedule => 'Reschedule';

  @override
  String get healthNotificationsTitle => 'Notifications';

  @override
  String get healthNotificationsOk => 'On.';

  @override
  String get healthOpenSettings => 'Open settings';

  @override
  String get healthExactTitle => 'Alarms & reminders';

  @override
  String get healthExactOk => 'Allowed: the adhan plays right on time.';

  @override
  String get healthVolumeTitle => 'Sound';

  @override
  String get healthVolumeOk => 'Notification sound is on.';

  @override
  String get healthVolumeAlarmOk => 'Alarm sound is on.';

  @override
  String get healthVolumeSilent =>
      'Your phone is on silent or vibrate: you won\'t hear the adhan.';

  @override
  String get healthVolumeNotificationMuted =>
      'Notification sound is off: you won\'t hear the adhan.';

  @override
  String get healthVolumeAlarmMuted =>
      'Alarm sound is off: you won\'t hear the adhan.';

  @override
  String healthAlarmStreamTip(String setting) {
    return 'With “$setting” on, the adhan plays at alarm volume.';
  }

  @override
  String get healthDndTitle => 'Do Not Disturb';

  @override
  String get healthDndOff => 'Off.';

  @override
  String get healthDndOn => 'On: you may not hear the adhan.';

  @override
  String healthDndAlarm(String setting) {
    return 'On, but thanks to “$setting”, the adhan plays at alarm volume.';
  }

  @override
  String get healthBatteryTitle => 'Battery usage';

  @override
  String get healthBatteryOk => 'Battery optimization is off for Vaktinde.';

  @override
  String get healthBatteryOptimized =>
      'Battery optimization is on: your phone may stop Vaktinde in the background. In the app settings, open Battery and choose “Unrestricted” (on some phones “No restrictions”).';

  @override
  String get healthBackgroundTitle => 'Background activity';

  @override
  String healthBackgroundToday(String time) {
    return 'Last run: today at $time';
  }

  @override
  String healthBackgroundYesterday(String time) {
    return 'Last run: yesterday at $time';
  }

  @override
  String get healthBackgroundStale =>
      'Vaktinde hasn\'t run in the background in the last 48 hours: your phone may be stopping it.';

  @override
  String get healthShowSteps => 'Show steps';

  @override
  String healthGuideTitle(String brand) {
    return 'Settings for $brand';
  }

  @override
  String get healthGuideTitleGeneric => 'Settings for your phone';

  @override
  String get healthGuideStale =>
      'Background activity seems to have stopped. To keep the adhan on time, change these settings:';

  @override
  String get healthGuideMore => 'Detailed guides for your phone model';

  @override
  String get healthTestTitle => 'Test adhan';

  @override
  String get healthTestInfo =>
      'You\'ll get a test notification in 1 minute, with the same sound and settings as the real adhan.';

  @override
  String get healthTestButton => 'Test adhan in 1 min';

  @override
  String get healthTestScheduled =>
      'The test adhan will play in 1 minute. You can close the app.';

  @override
  String get healthTestNotifBody =>
      'If you see this notification, adhan notifications are working.';

  @override
  String get healthStepXiaomiAutostart =>
      'In the app settings, turn on “Autostart”.';

  @override
  String get healthStepXiaomiBattery =>
      'On the same screen, under Battery saver (or Battery), choose “No restrictions”.';

  @override
  String get healthStepHuaweiLaunch =>
      'Open “App launch” in Settings (under Battery or Apps). Turn off automatic management for Vaktinde and leave all options on in the window that appears.';

  @override
  String get healthStepOppoBackground =>
      'In the app settings, under Battery usage, allow background activity and auto launch.';

  @override
  String get healthStepVivoBackground =>
      'In Settings > Battery, allow high background power consumption for Vaktinde.';

  @override
  String healthStepAutostartIn(String app) {
    return 'Turn on autostart for Vaktinde in Settings or in the $app app.';
  }

  @override
  String get healthStepAppBattery =>
      'In the app settings, under Battery, choose “Unrestricted”.';

  @override
  String get healthStepSamsungSleeping =>
      'In Settings > Battery > Background usage limits, add Vaktinde to “Never sleeping apps”.';

  @override
  String get healthStepLockRecents =>
      'Lock Vaktinde on the recent apps screen (if your phone has this option).';

  @override
  String get healthDetails => 'Details';

  @override
  String get alarmHealthExactAction => 'Allow';

  @override
  String get alarmHealthNotificationsOff =>
      'Notifications are off, the adhan won\'t play.';

  @override
  String get alarmHealthNotificationsAction => 'Turn on';

  @override
  String get ezanAlarmStreamTitle => 'Play in silent mode too';

  @override
  String get ezanAlarmStreamSub =>
      'The adhan plays at alarm volume even when the phone is on silent.';

  @override
  String channelAlarmSound(String soundName) {
    return 'Sound: $soundName (plays on silent)';
  }

  @override
  String get exactAlarmSub => 'Sends a notification.';

  @override
  String get silentNotif => 'Text Notification Only';

  @override
  String get silentNotifSub => 'No Adhan/Sound, only visual alert.';

  @override
  String warningAlarm(String minute) {
    return 'Reminder $minute Minutes Before';
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
  String get notifTitleUpcoming => 'Prayer Time Approaching';

  @override
  String notifBodyUpcoming(String vakit, int minute) {
    return '$minute minutes left until $vakit.';
  }

  @override
  String get navPrayer => 'Home';

  @override
  String get navQibla => 'Qibla';

  @override
  String get menuTitle => 'Settings';

  @override
  String get sectionLocation => 'LOCATION & TIMES';

  @override
  String get changeLocation => 'Change Location';

  @override
  String get citySelect => 'Select City';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get timeAdjustTitle => 'Prayer Time Adjustment';

  @override
  String get tapToCount => 'Tap to count';

  @override
  String get timeAdjustSub => 'Fine-tune times by the minute';

  @override
  String get timeAdjustInfo =>
      'Times are calculated for your location using the Diyanet method. If they differ slightly from your local mosque, you can move each time forward or back by minutes. The adjustment applies to the home screen, widgets and prayer notifications.';

  @override
  String get timeAdjustReset => 'Reset';

  @override
  String timeAdjustMinutes(String value) {
    return '$value min';
  }

  @override
  String get timeAdjustSaved => 'Prayer times updated';

  @override
  String get trackerTitle => 'Prayer Tracker';

  @override
  String get trackerToday => 'Today';

  @override
  String get trackerYesterday => 'Yesterday';

  @override
  String get trackerPrayedAction => 'Prayed';

  @override
  String get trackerLast7Days => 'Last 7 Days';

  @override
  String get trackerCompletion => '30-day rate';

  @override
  String get trackerStreak => 'Streak';

  @override
  String trackerStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get trackerNotYet => 'This prayer time has not started yet.';

  @override
  String get trackerKazaButton => 'Add missed prayers to qada';

  @override
  String get trackerKazaInfo =>
      'Unmarked prayers from the last 30 days (since you started tracking) are added to your qada counters. Each prayer is added only once. If you have performed a prayer that was added to qada, tap it: it will be marked as prayed and subtracted from your qada count.';

  @override
  String trackerKazaConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count unmarked prayers will be added to your qada counters. Continue?',
      one: '1 unmarked prayer will be added to your qada counters. Continue?',
    );
    return '$_temp0';
  }

  @override
  String get trackerKazaAdd => 'Add';

  @override
  String trackerKazaDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prayers added to qada.',
      one: '1 prayer added to qada.',
    );
    return '$_temp0';
  }

  @override
  String get trackerKazaNone => 'No prayers to add to qada.';

  @override
  String get trackerKazaRemoveTitle => 'Remove from qada?';

  @override
  String trackerKazaRemoveConfirm(String name, int from, int to) {
    return 'This prayer will be marked as prayed and your $name qada count will change from $from to $to.';
  }

  @override
  String get trackerLegendPrayed => 'Prayed';

  @override
  String get trackerLegendKaza => 'Added to qada';

  @override
  String kerahatActive(String range) {
    return 'Makruh time now: $range';
  }

  @override
  String kerahatUpcoming(String range) {
    return 'Makruh time soon: $range';
  }

  @override
  String get endReminderTitle => 'Remind Before Prayer Time Ends';

  @override
  String get dailyContentNotifTitle => 'Daily Ayah & Hadith Notifications';

  @override
  String get dailyContentNotifSub =>
      'Sends an ayah every morning and a hadith every evening.';

  @override
  String get religiousDaysNotifTitle =>
      'Religious Day & Holy Night Notifications';

  @override
  String get religiousDaysNotifSub =>
      'Sends a morning reminder for holy nights, Eids and other religious days.';

  @override
  String get religiousDaysChannel => 'Religious Days & Holy Nights';

  @override
  String get ucAylarBaslangici => 'Start of the Three Holy Months';

  @override
  String get ramazanArefesi => 'Last Day of Ramadan';

  @override
  String get kurbanArefesi => 'Day of Arafah';

  @override
  String get ucAylarNotifBody =>
      'The three holy months of Rajab, Sha\'ban and Ramadan begin today. May they bring you many blessings.';

  @override
  String get ucAylarRegaipTitle => 'Three Holy Months & Laylat al-Raghaib';

  @override
  String get ucAylarRegaipNotifBody =>
      'The three holy months begin today, and tonight is Laylat al-Raghaib. Wishing you a blessed night and blessed months ahead.';

  @override
  String get regaipKandiliNotifBody =>
      'Tonight is Laylat al-Raghaib. Have a blessed night!';

  @override
  String get miracKandiliNotifBody =>
      'Tonight is the Night of Isra and Mi\'raj. Have a blessed night!';

  @override
  String get beratKandiliNotifBody =>
      'Tonight is the Night of Mid-Sha\'ban (Bara\'at). Have a blessed night!';

  @override
  String get mevlidKandiliNotifBody =>
      'Tonight is Mawlid al-Nabi. Have a blessed night!';

  @override
  String get kadirGecesiNotifBody =>
      'Tonight is Laylat al-Qadr. Have a blessed night!';

  @override
  String get ramazanBaslangiciNotifBody =>
      'Ramadan begins tomorrow: the first tarawih and suhoor are tonight. Have a blessed Ramadan!';

  @override
  String get ramazanArefesiNotifBody =>
      'Eid al-Fitr is tomorrow. Wishing you a blessed Eid in advance!';

  @override
  String get ramazanBayramiNotifBody =>
      'Eid Mubarak! May Allah accept from us and from you.';

  @override
  String get kurbanArefesiNotifBody =>
      'Eid al-Adha is tomorrow. Wishing you a blessed Eid in advance!';

  @override
  String get kurbanBayramiNotifBody =>
      'Eid Mubarak! May Allah accept your sacrifices and good deeds.';

  @override
  String get hicriYilbasiNotifBody =>
      'Today is the Islamic New Year. May it bring you goodness and blessings.';

  @override
  String get asureGunuNotifBody =>
      'Today is the Day of Ashura. May it bring you goodness and blessings.';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get endReminderSub =>
      'Notifies you before a prayer\'s time ends if it isn\'t marked as prayed.';

  @override
  String get endReminderNotifTitle => 'Prayer Time Ending';

  @override
  String endReminderNotifBody(String vakit, int minute) {
    return '$minute minutes left until $vakit time ends.';
  }

  @override
  String get endReminderChannel => 'Prayer End Reminders';

  @override
  String get ramadanIftarTitle => 'Iftar Time';

  @override
  String ramadanIftarBody(String vakit) {
    return '$vakit time has begun. Have a blessed iftar!';
  }

  @override
  String get ramadanImsakTitle => 'Imsak Time';

  @override
  String get ramadanImsakBody => 'Suhoor time has ended. Have a blessed fast!';

  @override
  String get sectionSupport => 'SUPPORT';

  @override
  String get shareApp => 'Share with a Friend';

  @override
  String get rateApp => 'Rate Us';

  @override
  String get contactUs => 'Contact Us & Report a Bug';

  @override
  String shareText(String link) {
    return 'I found a great Prayer Time app! Download it here: $link';
  }

  @override
  String get okUnderstood => 'OK, I Understand';

  @override
  String get religiousDaysTitle => 'Religious Days';

  @override
  String get noDataFound => 'No data found.';

  @override
  String noDataForYear(int year) {
    return 'No data found for the year $year.';
  }

  @override
  String religiousDaysListTitle(int year) {
    return 'Religious Days in $year';
  }

  @override
  String get missedPrayersTitle => 'Missed Prayers Tracker';

  @override
  String get missedPrayersInfo =>
      'Note your missed prayers here and subtract them as you make them up.\n(Tap a number to enter it manually)';

  @override
  String editMissedTitle(String title) {
    return 'Edit Missed $title';
  }

  @override
  String get missedCountLabel => 'Missed Count';

  @override
  String get missedCountHint => 'E.g. 150';

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
  String get zakatTitle => 'Zakat Calculator';

  @override
  String get zakatCalculatorTitle => 'Smart Zakat Calculator';

  @override
  String get liveRatesLoading => 'Fetching current exchange rates...';

  @override
  String get liveRatesInfo =>
      'You can manually edit the automatically fetched rates if you wish.';

  @override
  String get goldType => 'Gold Type';

  @override
  String get goldAmount => 'Quantity / Grams';

  @override
  String get goldUnitPrice => 'Unit Price';

  @override
  String get currencyType => 'Currency Type';

  @override
  String get currencyAmount => 'Amount';

  @override
  String get currencyRate => 'Current Rate';

  @override
  String get calculateButton => 'CALCULATE';

  @override
  String get zakatResultTitle => 'Zakat Due';

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
  String get zakatEligible => 'Zakat is Required';

  @override
  String get zakatNotEligible => 'Zakat is Not Required';

  @override
  String get nisabLimit => 'Nisab Threshold (80.18 g Gold)';

  @override
  String get belowNisabMessage =>
      'Since your net assets are below the nisab threshold (the minimum wealth on which zakat is due), zakat is not obligatory.';

  @override
  String get searchLocationTitle => 'Search Location (Worldwide)';

  @override
  String get searchLocationHint => 'City or country (e.g. Paris)';

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
  String get zakatDescription =>
      'Calculate your zakat in detail based on the fatwas of Diyanet (Turkey\'s Presidency of Religious Affairs) and current market rates.';

  @override
  String get cashAndCurrencyTitle => 'Cash and Currency Assets';

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
      'Since no nisab threshold applies to agricultural products, the amount you declare is added directly to your zakat total.';

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
  String get assetCheck => 'Cheque';

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
  String get agriRateCostly => 'With Cost (Pump/Transport) - 5%';

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
  String get dhikrKalima => 'Kalimat al-Tawhid';

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
  String get dhikrLaHavle => 'La Hawla wa la Quwwata illa Billah';

  @override
  String get dhikrHasbunallah => 'Hasbunallah';

  @override
  String get dhikrSubhanallahi => 'Subhanallahi wa bihamdihi';

  @override
  String get dhikrYunus => 'Dua of Prophet Yunus';

  @override
  String get dhikrYaAllah => 'Ya Allah (SWT)';

  @override
  String get dhikrYaRahman => 'Ya Rahman (SWT)';

  @override
  String get dhikrYaRahim => 'Ya Rahim (SWT)';

  @override
  String get dhikrYaSafi => 'Ya Shafi (SWT)';

  @override
  String get dhikrYaRezzak => 'Ya Razzaq (SWT)';

  @override
  String get dhikrYaFettah => 'Ya Fattah (SWT)';

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
  String get locationFoundNoName =>
      'Location found, but its name is unavailable.';

  @override
  String get dailyAyahTitle => 'Ayah of the Day';

  @override
  String get onboardingWelcome => 'Hoş Geldiniz / Welcome';

  @override
  String get onboardingSelectLanguage =>
      'Lütfen kullanmak istediğiniz dili seçin.\nPlease select your preferred language.';

  @override
  String get calibrationRequired => 'Calibration Required';

  @override
  String get qiblaAccuracyNote =>
      'The compass shows an approximate direction; metal, magnets and electronic devices can throw it off.';

  @override
  String get qiblaTipsTitle => 'For accurate results';

  @override
  String get qiblaTipFlat => 'Hold the phone flat, parallel to the ground.';

  @override
  String get qiblaTipCalibrate =>
      'Calibrate the compass by drawing an \'8\' in the air with your phone.';

  @override
  String get qiblaTipMagneticCase => 'Remove any magnetic phone case.';

  @override
  String get qiblaTipMetal =>
      'Stay away from metal objects and electronic devices.';

  @override
  String get qiblaTipMosque =>
      'If possible, compare with the Qibla direction of a mosque.';

  @override
  String qiblaAngleTrueNorth(String angle) {
    return 'Qibla angle: $angle° (from true north)';
  }

  @override
  String qiblaDeclination(String deg) {
    return 'Magnetic declination: $deg° (corrected automatically)';
  }

  @override
  String get qiblaInterferenceWarning =>
      'Magnetic interference detected: move the phone away from metal objects, magnetic cases and electronic devices.';

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
  String get editCounterTitle => 'Edit Counter';

  @override
  String get resetCounterConfirm =>
      'Are you sure you want to reset the counter?';

  @override
  String get imsakiyeTitle => 'Prayer Timetable';

  @override
  String get toolsGroupPrayer => 'Prayer';

  @override
  String get toolsGroupInfo => 'Knowledge';

  @override
  String get toolsGroupCalc => 'Calculators';

  @override
  String get toolImsakiyeDesc => 'Monthly and Ramadan times';

  @override
  String get toolTrackerDesc => 'Mark the prayers you performed';

  @override
  String get toolKazaDesc => 'Counter for missed prayers and fasts';

  @override
  String get toolReligiousDaysDesc => 'Holy nights and Eids';

  @override
  String get nearbyMosquesTitle => 'Nearby Mosques';

  @override
  String get toolNearbyMosquesDesc => 'Find the nearest mosques on the map';

  @override
  String get nearbyMosquesQuery => 'mosque';

  @override
  String get nearbyMosquesError => 'Could not open the map.';

  @override
  String get toolEsmaDesc => 'The 99 names and their meanings';

  @override
  String get toolFridayDesc => 'Messages ready to share';

  @override
  String get toolZakatDesc => 'Zakat and harvest (ushr) calculation';

  @override
  String get toolSettingsDesc => 'Location, notifications, appearance';

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: 'Tomorrow',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String get previousYear => 'Previous year';

  @override
  String get nextYear => 'Next year';

  @override
  String get previousItem => 'Previous';

  @override
  String get nextItem => 'Next';

  @override
  String missedChangeConfirm(String name, int from, int to) {
    return 'The $name count will change from $from to $to. Save it?';
  }

  @override
  String get shareFailed => 'That did not work. Please try again.';

  @override
  String get zakatCurrencyNote => 'All amounts are in Turkish lira (₺).';

  @override
  String get zakatCashTry => 'Cash (₺)';

  @override
  String get zakatRatesUnavailable =>
      'Live gold prices and exchange rates are unavailable. Please enter the prices manually.';

  @override
  String get zakatGoldGramPrice => 'Price of 1 g 24-carat gold (₺)';

  @override
  String get zakatGoldGramPriceHelp => 'Used to calculate the nisab threshold.';

  @override
  String get zakatNisabUnknown =>
      'Without a gold price the nisab threshold cannot be calculated. Enter the gold price for a correct result.';

  @override
  String get imsakiyeRamadan => 'Ramadan';

  @override
  String imsakiyeRamadanTitle(int year) {
    return 'Ramadan $year Timetable';
  }

  @override
  String get imsakiyeDay => 'Day';

  @override
  String get imsakiyeSunriseShort => 'Sunrise';

  @override
  String get imsakiyePrevMonth => 'Previous month';

  @override
  String get imsakiyeNextMonth => 'Next month';

  @override
  String get imsakiyeNoLocation =>
      'Please select your location first to see the timetable. You can set it on the home screen or in Settings.';

  @override
  String get imsakiyeShareError =>
      'Could not share the timetable. Please try again.';

  @override
  String get ramadanSahurLeft => 'Suhoor ends in';

  @override
  String get ramadanIftarLeft => 'Iftar in';

  @override
  String ramadanDayLabel(int day) {
    return 'Ramadan, day $day';
  }
}
