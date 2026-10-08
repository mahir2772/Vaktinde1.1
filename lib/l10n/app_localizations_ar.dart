// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Vaktinde';

  @override
  String get navZikir => 'الذكر';

  @override
  String get adPrivacySettings => 'إعدادات خصوصية الإعلانات';

  @override
  String get adPrivacySettingsSub => 'غيّر موافقتك على الإعلانات المخصصة';

  @override
  String get showcaseLanguage => 'يمكنك تغيير لغة التطبيق من هنا.';

  @override
  String get showcaseStory => 'اقرأ آية اليوم وحديث اليوم من هنا.';

  @override
  String get showcaseAlarms => 'اضبط منبهات الأذان والتذكير لكل صلاة من هنا.';

  @override
  String get showcaseQibla => 'اعثر على اتجاه القبلة باستخدام البوصلة.';

  @override
  String get showcaseZikir => 'تابع أذكارك من هنا.';

  @override
  String get refreshLocation => 'تحديث الموقع';

  @override
  String get navTools => 'الأدوات';

  @override
  String get hadithNotFound => 'تعذّر العثور على نص الحديث.';

  @override
  String get timesLoadError =>
      'تعذّر تحميل مواقيت الصلاة. يرجى المحاولة مرة أخرى.';

  @override
  String get sunriseNotPrayer => 'شروق الشمس، ليس وقت صلاة';

  @override
  String get currentPrayer => 'الصلاة الحالية';

  @override
  String get textCopied => 'تم نسخ النص';

  @override
  String get updateDownloaded => 'تم تنزيل إصدار جديد.';

  @override
  String get restartAction => 'إعادة التشغيل';

  @override
  String get qiblaTurnRight => 'استدر يميناً';

  @override
  String get qiblaTurnSlightRight => 'استدر قليلاً إلى اليمين';

  @override
  String get qiblaTurnLeft => 'استدر يساراً';

  @override
  String get qiblaTurnSlightLeft => 'استدر قليلاً إلى اليسار';

  @override
  String phoneHeading(String deg) {
    return 'اتجاه الهاتف: $deg°';
  }

  @override
  String get usingSavedLocation => 'يتم استخدام الموقع المحفوظ.';

  @override
  String exampleHint(int n) {
    return 'مثال: $n';
  }

  @override
  String get noCustomDhikr => 'لم تُضف أي ذكر مخصص بعد.';

  @override
  String get messagesShuffled => 'تم ترتيب الرسائل عشوائيًا';

  @override
  String get shuffle => 'ترتيب عشوائي';

  @override
  String get copy => 'نسخ';

  @override
  String get messageCopied => 'تم نسخ الرسالة';

  @override
  String versionLabel(String v) {
    return 'الإصدار $v';
  }

  @override
  String get supportMailSubject => 'Vaktinde - الدعم';

  @override
  String get madeBy => 'صُنع بـ ❤️ بواسطة mmdigital';

  @override
  String get permissionPrimingTitle => 'لا تفوّت وقت الصلاة';

  @override
  String get permissionPrimingBody =>
      'نحتاج إلى إذن الإشعارات لتنبيهات الأذان، وإذن الموقع لحساب مواقيت الصلاة حسب مكانك.';

  @override
  String get continueAction => 'متابعة';

  @override
  String get ok => 'حسناً';

  @override
  String get nextPrayer => 'الوقت التالي';

  @override
  String get hadithTitle => 'حديث اليوم';

  @override
  String get readMore => 'اقرأ المزيد...';

  @override
  String get share => 'مشاركة';

  @override
  String get close => 'إغلاق';

  @override
  String get loading => 'جارٍ حساب الأوقات...';

  @override
  String get error => 'خطأ';

  @override
  String get retry => 'حاول مرة أخرى';

  @override
  String get noData => 'لا توجد بيانات.';

  @override
  String get imsak => 'الإمساك';

  @override
  String get gunes => 'الشروق';

  @override
  String get ogle => 'الظهر';

  @override
  String get ikindi => 'العصر';

  @override
  String get aksam => 'المغرب';

  @override
  String get yatsi => 'العشاء';

  @override
  String get exactAlarm => 'إشعار في الوقت المحدد';

  @override
  String get reminderTitleAt => 'تذكير بوقت الصلاة';

  @override
  String notifBodyUpcomingAt(String vakit, String time) {
    return 'دخول وقت $vakit: $time';
  }

  @override
  String get endReminderTitleAt => 'خروج وقت الصلاة';

  @override
  String endReminderNotifBodyAt(String vakit, String time) {
    return 'خروج وقت $vakit: $time';
  }

  @override
  String ramadanImsakBodyAt(String time) {
    return 'انتهى وقت السحور الساعة $time. صومًا مقبولًا!';
  }

  @override
  String get alarmHealthExactOff =>
      'إذن المنبّه معطّل: قد يتأخر الأذان والتذكيرات حتى ساعة تقريبًا (بما في ذلك الإمساك والسحور).';

  @override
  String get alarmHealthExactAction => 'سماح';

  @override
  String get alarmHealthNotificationsOff => 'الإشعارات معطّلة، لن يعمل الأذان.';

  @override
  String get alarmHealthNotificationsAction => 'تفعيل';

  @override
  String get ezanAlarmStreamTitle => 'التشغيل في الوضع الصامت أيضاً';

  @override
  String get ezanAlarmStreamSub =>
      'يُرفع الأذان بمستوى صوت المنبّه حتى عندما يكون الهاتف صامتاً.';

  @override
  String channelAlarmSound(String soundName) {
    return 'الصوت: $soundName (حتى في الوضع الصامت)';
  }

  @override
  String get exactAlarmSub => 'يرسل إشعاراً.';

  @override
  String get silentNotif => 'إشعار نصي فقط';

  @override
  String get silentNotifSub => 'بدون أذان/صوت، تنبيه مرئي فقط.';

  @override
  String warningAlarm(String minute) {
    return 'تنبيه قبل $minute دقيقة';
  }

  @override
  String get warningAlarmSub => 'صوت إشعار قصير.';

  @override
  String get settings => 'الإعدادات';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get waitingLocation => 'في انتظار الموقع...';

  @override
  String get noInternet =>
      'لا يوجد اتصال بالإنترنت ولم يتم العثور على بيانات محفوظة.';

  @override
  String get gpsOff => 'الـ GPS مغلق. يرجى تفعيل الموقع.';

  @override
  String get permissionDenied => 'تم رفض إذن الموقع.';

  @override
  String get locationError => 'تعذر الحصول على الموقع.';

  @override
  String get internetNeeded => 'يلزم الاتصال بالإنترنت.';

  @override
  String get soundEzan => 'أذان';

  @override
  String get soundBeep => 'تنبيه قصير';

  @override
  String get notifTitleTime => 'وقت الصلاة';

  @override
  String notifBodyTime(String vakit) {
    return 'حان وقت $vakit.';
  }

  @override
  String get notifTitleUpcoming => 'اقترب الوقت';

  @override
  String notifBodyUpcoming(String vakit, int minute) {
    return 'تبقّى $minute دقيقة على دخول وقت $vakit.';
  }

  @override
  String get navPrayer => 'الرئيسية';

  @override
  String get navQibla => 'القبلة';

  @override
  String get navMenu => 'القائمة';

  @override
  String get menuTitle => 'الإعدادات';

  @override
  String get sectionLocation => 'الموقع والأوقات';

  @override
  String get changeLocation => 'تغيير الموقع';

  @override
  String get citySelect => 'اختر المدينة';

  @override
  String get districtSelect => 'اختر المنطقة';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get locationWarning =>
      'اختيار المنطقة مهم للحصول على أوقات دقيقة للصلاة.';

  @override
  String get menuNotifications => 'أذونات الإشعارات';

  @override
  String get menuNotificationsSub => 'تحقق هنا إذا لم تسمع أصواتًا.';

  @override
  String get menuTroubleshoot => 'لا تصلك الإشعارات؟';

  @override
  String get menuTroubleshootSub =>
      'قم بضبط إعدادات البطارية لأجهزة Samsung/Xiaomi.';

  @override
  String get timeAdjustTitle => 'ضبط أوقات الصلاة';

  @override
  String get tapToCount => 'انقر للعدّ';

  @override
  String get timeAdjustSub => 'تعديل الأوقات بالدقيقة';

  @override
  String get timeAdjustInfo =>
      'تُحسب الأوقات حسب موقعك وفق طريقة رئاسة الشؤون الدينية التركية (ديانت). إذا كانت تختلف قليلاً عن أوقات المسجد في منطقتك، يمكنك تقديم كل وقت أو تأخيره بالدقائق. يُطبَّق التعديل على الشاشة الرئيسية والودجت وإشعارات الصلاة.';

  @override
  String get timeAdjustReset => 'إعادة تعيين';

  @override
  String timeAdjustMinutes(String value) {
    return '$value د';
  }

  @override
  String get timeAdjustSaved => 'تم تحديث أوقات الصلاة';

  @override
  String get trackerTitle => 'متابعة الصلوات';

  @override
  String get trackerToday => 'اليوم';

  @override
  String get trackerYesterday => 'أمس';

  @override
  String get trackerPrayedAction => 'صلّيت';

  @override
  String get trackerLast7Days => 'آخر 7 أيام';

  @override
  String get trackerCompletion => 'نسبة 30 يومًا';

  @override
  String get trackerStreak => 'أيام متتالية';

  @override
  String trackerStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: '0 يوم',
    );
    return '$_temp0';
  }

  @override
  String get trackerNotYet => 'لم يدخل وقت هذه الصلاة بعد.';

  @override
  String get trackerKazaButton => 'إضافة الصلوات غير المؤدّاة إلى القضاء';

  @override
  String get trackerKazaInfo =>
      'تُضاف الصلوات غير المعلَّمة خلال آخر 30 يومًا (منذ بدء المتابعة) إلى عدادات القضاء. تُضاف كل صلاة مرة واحدة فقط.';

  @override
  String trackerKazaConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'ستُضاف $count صلاة غير معلَّمة إلى عدادات القضاء. هل تريد المتابعة؟',
      few:
          'ستُضاف $count صلوات غير معلَّمة إلى عدادات القضاء. هل تريد المتابعة؟',
      two: 'ستُضاف صلاتان غير معلَّمتين إلى عدادات القضاء. هل تريد المتابعة؟',
      one: 'ستُضاف صلاة واحدة غير معلَّمة إلى عدادات القضاء. هل تريد المتابعة؟',
    );
    return '$_temp0';
  }

  @override
  String get trackerKazaAdd => 'إضافة';

  @override
  String trackerKazaDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أُضيفت $count صلاة إلى القضاء.',
      few: 'أُضيفت $count صلوات إلى القضاء.',
      two: 'أُضيفت صلاتان إلى القضاء.',
      one: 'أُضيفت صلاة واحدة إلى القضاء.',
    );
    return '$_temp0';
  }

  @override
  String get trackerKazaNone => 'لا توجد صلوات لإضافتها إلى القضاء.';

  @override
  String get trackerKazaLocked =>
      'أُضيفت هذه الصلاة إلى القضاء. بعد قضائها يمكنك إنقاصها من «تتبع الصلوات الفائتة».';

  @override
  String get trackerLegendPrayed => 'مؤداة';

  @override
  String get trackerLegendKaza => 'أُضيفت إلى القضاء';

  @override
  String kerahatActive(String range) {
    return 'وقت كراهة الآن: $range';
  }

  @override
  String kerahatUpcoming(String range) {
    return 'وقت الكراهة يقترب: $range';
  }

  @override
  String get endReminderTitle => 'التذكير قبل خروج الوقت';

  @override
  String get dailyContentNotifTitle => 'إشعار آية اليوم وحديث اليوم';

  @override
  String get dailyContentNotifSub => 'يرسل آية كل صباح وحديثًا كل مساء.';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get endReminderSub =>
      'يرسل تنبيهًا قبل خروج وقت صلاة لم تُعلَّم كمؤداة.';

  @override
  String get endReminderNotifTitle => 'الوقت يوشك على الخروج';

  @override
  String endReminderNotifBody(String vakit, int minute) {
    return 'تبقّى $minute دقيقة على خروج وقت $vakit.';
  }

  @override
  String get endReminderChannel => 'تذكيرات خروج الوقت';

  @override
  String get ramadanIftarTitle => 'حان وقت الإفطار';

  @override
  String ramadanIftarBody(String vakit) {
    return 'دخل وقت $vakit. إفطارًا هنيئًا!';
  }

  @override
  String get ramadanImsakTitle => 'حان وقت الإمساك';

  @override
  String get ramadanImsakBody => 'انتهى وقت السحور. صومًا مقبولًا!';

  @override
  String get sectionSupport => 'الدعم';

  @override
  String get shareApp => 'شارك مع صديق';

  @override
  String get rateApp => 'قيّمنا';

  @override
  String get contactUs => 'اتصل بنا وأبلغ عن خطأ';

  @override
  String shareText(String link) {
    return 'وجدت تطبيقاً رائعاً لأوقات الصلاة! حمله من هنا: $link';
  }

  @override
  String get batteryDialogTitle => 'حل مشكلة الإشعارات';

  @override
  String get batteryDialogBody =>
      'قد يقوم هاتفك بإغلاق التطبيق لتوفير البطارية. لمنع ذلك:\n\n1. افتح شاشة التطبيقات الحديثة.\n2. اضغط مطولاً على تطبيق \'Vaktinde\' أو انقر على شعاره.\n3. اضغط على أيقونة القفل 🔒 لقفله.\n\nأيضاً، اذهب إلى الإعدادات > التطبيقات > Vaktinde > البطارية > اختر غير مقيد.';

  @override
  String get okUnderstood => 'حسناً، فهمت';

  @override
  String get religiousDaysTitle => 'المناسبات الدينية';

  @override
  String errorOccurred(String error) {
    return 'حدث خطأ: $error';
  }

  @override
  String get noDataFound => 'لم يتم العثور على بيانات.';

  @override
  String noDataForYear(int year) {
    return 'لم يتم العثور على بيانات لعام $year.';
  }

  @override
  String religiousDaysListTitle(int year) {
    return 'قائمة المناسبات الدينية لعام $year';
  }

  @override
  String get missedPrayersTitle => 'تتبع الصلوات الفائتة';

  @override
  String get missedPrayersInfo =>
      'سجل صلواتك الفائتة هنا واطرحها عند قضائها.\n(اضغط على الرقم للإدخال يدوياً)';

  @override
  String editMissedTitle(String title) {
    return 'تعديل قضاء $title';
  }

  @override
  String get missedCountLabel => 'عدد الفوائت';

  @override
  String get missedCountHint => 'مثال: 150';

  @override
  String get sabah => 'الفجر';

  @override
  String get vitir => 'الوتر';

  @override
  String get oruc => 'الصيام';

  @override
  String timeLeftFor(String vakit) {
    return 'الوقت المتبقي حتى $vakit';
  }

  @override
  String get tomorrow => '(غداً)';

  @override
  String get fridayMessagesTitle => 'رسائل الجمعة';

  @override
  String get esmaulHusnaTitle => 'أسماء الله الحسنى';

  @override
  String get closeCaps => 'إغلاق';

  @override
  String get zakatTitle => 'حاسبة الزكاة';

  @override
  String get zakatCalculatorTitle => 'حاسبة الزكاة الذكية';

  @override
  String get liveRatesLoading => 'جارٍ جلب أسعار الصرف الحالية...';

  @override
  String get liveRatesInfo =>
      'جُلبت الأسعار تلقائيًا، ويمكنك تعديلها يدويًا إذا رغبت.';

  @override
  String get sectionGold => 'أصول الذهب';

  @override
  String get goldType => 'نوع الذهب';

  @override
  String get goldAmount => 'الكمية / الجرامات';

  @override
  String get goldUnitPrice => 'سعر الوحدة';

  @override
  String get sectionCurrency => 'الأصول النقدية والعملات';

  @override
  String get currencyType => 'نوع العملة';

  @override
  String get currencyAmount => 'المبلغ';

  @override
  String get currencyRate => 'سعر الصرف الحالي';

  @override
  String get sectionCashDebt => 'النقد والديون';

  @override
  String get cashAmount => 'النقد المتوفر وفي البنك';

  @override
  String get debtAmount => 'إجمالي الديون (للخصم)';

  @override
  String get calculateButton => 'احسب';

  @override
  String get zakatResultTitle => 'الزكاة المستحقة عليك';

  @override
  String get netAssets => 'صافي الأصول:';

  @override
  String get qiblaTitle => 'بوصلة القبلة';

  @override
  String get locationServiceOff => 'خدمة الموقع مغلقة. يرجى تفعيل الموقع.';

  @override
  String get locationPermissionDenied => 'تم رفض إذن الموقع.';

  @override
  String get locationPermissionForever =>
      'تم رفض إذن الموقع بشكل دائم. يرجى تفعيله من الإعدادات.';

  @override
  String compassError(String error) {
    return 'خطأ في المستشعر: $error';
  }

  @override
  String get noCompass => 'لا توجد بوصلة في هذا الجهاز.';

  @override
  String get qiblaFound => 'لقد وجدت القبلة!';

  @override
  String qiblaAngle(String angle) {
    return 'زاوية القبلة: $angle°';
  }

  @override
  String get keepAwayMetal => 'أبعِد الهاتف عن الأشياء المعدنية.';

  @override
  String get goldGram => 'جرام ذهب (عيار 24)';

  @override
  String get goldQuarter => 'ربع ليرة ذهب';

  @override
  String get goldFull => 'ليرة ذهب كاملة';

  @override
  String get typeOther => 'أخرى (يدوي)';

  @override
  String get usd => 'دولار أمريكي (USD)';

  @override
  String get eur => 'يورو (EUR)';

  @override
  String get gbp => 'جنيه إسترليني (GBP)';

  @override
  String get sectionAppearance => 'المظهر واللغة';

  @override
  String get appearanceSettings => 'إعدادات المظهر';

  @override
  String get appearanceSub => 'السمة والخلفية';

  @override
  String get themeMode => 'وضع السمة';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get bgImage => 'صورة الخلفية';

  @override
  String get bgDefault => 'الافتراضي';

  @override
  String get bgMosque => 'مسجد';

  @override
  String get bgKaaba => 'الكعبة';

  @override
  String get bgQuran => 'القرآن';

  @override
  String get none => 'لا شيء';

  @override
  String get zakatEligible => 'تجب الزكاة';

  @override
  String get zakatNotEligible => 'لا تجب الزكاة';

  @override
  String get nisabLimit => 'حد النصاب (80.18 جم ذهب)';

  @override
  String get belowNisabMessage =>
      'بما أن صافي أصولك أقل من حد النصاب، فلا تجب عليك الزكاة.';

  @override
  String get searchLocationTitle => 'البحث عن موقع (حول العالم)';

  @override
  String get searchLocationHint => 'مدينة أو دولة (مثل: باريس)';

  @override
  String get searchInitial => 'اكتب المكان الذي تريد البحث عنه...';

  @override
  String get searchNotFound => 'لم يتم العثور على الموقع.';

  @override
  String get searchError => 'لم يتم العثور على نتائج. يرجى المحاولة مرة أخرى.';

  @override
  String locationSelected(String city) {
    return 'تم اختيار $city';
  }

  @override
  String channelSoundPrefix(String soundName) {
    return 'الصوت: $soundName';
  }

  @override
  String get channelSilentPrayers => 'إشعارات الأذان الصامتة';

  @override
  String get tickerEzan => 'وقت الصلاة';

  @override
  String get stickyChannelName => 'عداد دائم';

  @override
  String get stickyChannelDesc => 'يعرض الوقت المتبقي';

  @override
  String get timeLeftTo => 'المتبقي على خروج الوقت: ';

  @override
  String get locationFallbackMessage =>
      'تعذر الحصول على الموقع، يتم استخدام القيم الافتراضية.';

  @override
  String get fetchingLocation => 'جارٍ الحصول على الموقع...';

  @override
  String get directionNorth => 'ش';

  @override
  String get directionSouth => 'ج';

  @override
  String get directionEast => 'ق';

  @override
  String get directionWest => 'غ';

  @override
  String get calibrationInstruction => '(ارسم رقم \'8\' للمعايرة)';

  @override
  String get zakatDescription =>
      'احسب زكاتك بالتفصيل وفقًا لفتاوى رئاسة الشؤون الدينية التركية وأسعار السوق الحالية.';

  @override
  String get cashAndCurrencyTitle => 'النقد والعملات';

  @override
  String get cashTurkishLira => 'النقد بالليرة التركية (₺)';

  @override
  String get goldAndSilverTitle => 'الذهب والفضة';

  @override
  String get silverGram => 'فضة (جرام)';

  @override
  String get unitPrice => 'سعر الوحدة';

  @override
  String get commercialGoodsTitle => 'عروض التجارة';

  @override
  String get commercialEvalCurrency => 'عملة التقييم';

  @override
  String get commercialGoodsValue => 'قيمة البضاعة';

  @override
  String get exchangeRateValue => 'سعر الصرف';

  @override
  String get receivablesTitle => 'الديون المستحقة لك (القابلة للتحصيل)';

  @override
  String get receivableType => 'نوع الدين (نقد، عملة أجنبية، ذهب)';

  @override
  String get amountOrCount => 'المبلغ / الكمية';

  @override
  String get otherAssetsTitle => 'أصول أخرى';

  @override
  String get assetType => 'نوع الأصل';

  @override
  String get currencyLabel => 'العملة';

  @override
  String get valueOrAmount => 'القيمة / المبلغ';

  @override
  String get agriProductsTitle => 'المنتجات الزراعية (العشر)';

  @override
  String get agriDiyanetNote =>
      'نظرًا لعدم اشتراط النصاب في زكاة المنتجات الزراعية، يُضاف المبلغ الذي تُدخله مباشرةً إلى إجمالي الزكاة.';

  @override
  String get harvestedProductValue => 'قيمة المحصول (₺)';

  @override
  String get irrigationMethod => 'طريقة الري';

  @override
  String get debtsTitle => 'الديون (للخصم)';

  @override
  String get debtType => 'نوع الدين (نقد، عملة، ذهب)';

  @override
  String get zakatAgriIncluded => 'منها زكاة المنتجات الزراعية (العُشر)';

  @override
  String get assetCheck => 'شيك';

  @override
  String get assetBond => 'كمبيالة';

  @override
  String get assetSukuk => 'صكوك';

  @override
  String get assetLeaseCert => 'شهادة إجارة';

  @override
  String get assetStock => 'أسهم';

  @override
  String get agriSoil => 'منتج زراعي (زراعة تقليدية)';

  @override
  String get agriSoilless => 'منتج زراعي (بدون تربة)';

  @override
  String get agriRateNoCost => 'بدون تكلفة (مطر/نهر) - 10%';

  @override
  String get agriRateCostly => 'بتكلفة (محرك/نقل) - 5%';

  @override
  String get toImsak => 'إلى الإمساك';

  @override
  String get toGunes => 'إلى الشروق';

  @override
  String get toOgle => 'إلى الظهر';

  @override
  String get toIkindi => 'إلى العصر';

  @override
  String get toAksam => 'إلى المغرب';

  @override
  String get toYatsi => 'إلى العشاء';

  @override
  String get lowAccuracyWarning =>
      'معايرة البوصلة ضعيفة. يرجى رسم رقم \'8\' في الهواء بهاتفك.';

  @override
  String get qiblaDirection => 'اتجاه القبلة';

  @override
  String get zikirmatikTitle => 'مسبحة إلكترونية';

  @override
  String get dhikrSubhanallah => 'سبحان الله';

  @override
  String get dhikrElhamdulillah => 'الحمد لله';

  @override
  String get dhikrAllahuEkber => 'الله أكبر';

  @override
  String get dhikrKalima => 'كلمة التوحيد';

  @override
  String get dhikrSalavat => 'الصلاة على النبي';

  @override
  String get targetReached => 'لقد وصلت إلى الهدف!';

  @override
  String get resetCounter => 'إعادة تعيين';

  @override
  String targetCount(int target) {
    return 'الهدف: $target';
  }

  @override
  String get setTarget => 'تحديد الهدف';

  @override
  String get dhikrOther => 'أخرى (ذكر مخصص)';

  @override
  String get customDhikrTitle => 'إضافة ذكر مخصص';

  @override
  String get customDhikrHint => 'اكتب الذكر الخاص بك';

  @override
  String get zikirSettings => 'الإعدادات';

  @override
  String get vibration => 'اهتزاز';

  @override
  String get sound => 'تأثير صوتي';

  @override
  String get keepAwake => 'إبقاء الشاشة قيد التشغيل';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeModern => 'زر حديث';

  @override
  String get themeClassic => 'مسبحة كلاسيكية';

  @override
  String get introTitle1 => 'مرحباً بك في Vaktinde';

  @override
  String get introDesc1 =>
      'تتبع أوقات الصلاة، الأذكار، والأيام الدينية بسهولة مع واجهتنا الحديثة والأنيقة.';

  @override
  String get introTitle2 => 'إشعارات ذكية';

  @override
  String get introDesc2 =>
      'احصل على تنبيهات بصوت الإشعار الذي تختاره في أوقات الصلاة. لا تفوت عباداتك أبداً.';

  @override
  String get introTitle3 => 'أدوات متقدمة';

  @override
  String get introDesc3 =>
      'عزز روحانيتك مع المسبحة المتحركة، متتبع الصلوات الفائتة، أسماء الله الحسنى، وحاسبة الزكاة.';

  @override
  String get introSkip => 'تخطي';

  @override
  String get introNext => 'التالي';

  @override
  String get introStart => 'ابدأ الآن';

  @override
  String get dhikrListTitle => 'قائمة الأذكار';

  @override
  String get addCustomDhikr => 'إضافة ذكر مخصص جديد';

  @override
  String get customDhikrAdded => 'تمت إضافة الذكر بنجاح.';

  @override
  String get customDhikrLimit =>
      'يمكنك إضافة ما يصل إلى 20 ذكراً مخصصاً كحد أقصى!';

  @override
  String get deleteDhikr => 'حذف';

  @override
  String get statisticsTitle => 'الإحصائيات';

  @override
  String get monthly => 'شهرياً';

  @override
  String get yearly => 'سنوياً';

  @override
  String get totalDhikr => 'إجمالي الأذكار';

  @override
  String get today => 'اليوم';

  @override
  String get statsEmpty => 'لا توجد بيانات للأذكار بعد.';

  @override
  String get dhikrEstagfirullah => 'أستغفر الله';

  @override
  String get dhikrLaHavle => 'لا حول ولا قوة إلا بالله';

  @override
  String get dhikrHasbunallah => 'حسبنا الله';

  @override
  String get dhikrSubhanallahi => 'سبحان الله وبحمده';

  @override
  String get dhikrYunus => 'دعاء نبي الله يونس';

  @override
  String get dhikrYaAllah => 'يا الله (جل جلاله)';

  @override
  String get dhikrYaRahman => 'يا رحمن (جل جلاله)';

  @override
  String get dhikrYaRahim => 'يا رحيم (جل جلاله)';

  @override
  String get dhikrYaSafi => 'يا شافي (جل جلاله)';

  @override
  String get dhikrYaRezzak => 'يا رزاق (جل جلاله)';

  @override
  String get dhikrYaFettah => 'يا فتاح (جل جلاله)';

  @override
  String get mainDhikrs => 'الأذكار الأساسية';

  @override
  String get esmaulHusnaTab => 'أسماء الله الحسنى';

  @override
  String get qiblaCalibration =>
      'لتعمل البوصلة بدقة، يرجى رسم رقم \'8\' في الهواء بهاتفك.';

  @override
  String get hicriYilbasi => 'رأس السنة الهجرية';

  @override
  String get asureGunu => 'يوم عاشوراء';

  @override
  String get mevlidKandili => 'المولد النبوي';

  @override
  String get miracKandili => 'الإسراء والمعراج';

  @override
  String get beratKandili => 'ليلة النصف من شعبان';

  @override
  String get ramazanBaslangici => 'بداية شهر رمضان';

  @override
  String get kadirGecesi => 'ليلة القدر';

  @override
  String get ramazanBayrami => 'عيد الفطر';

  @override
  String get kurbanBayrami => 'عيد الأضحى';

  @override
  String get regaipKandili => 'ليلة الرغائب';

  @override
  String get tabTimes => 'الأوقات';

  @override
  String get tabAlarms => 'المنبهات';

  @override
  String get locationFoundNoName => 'تم العثور على الموقع ولكن بدون اسم.';

  @override
  String get dailyAyahTitle => 'آية اليوم';

  @override
  String get remainingTime => 'المتبقي';

  @override
  String get onboardingWelcome => 'Hoş Geldiniz / مرحباً بكم';

  @override
  String get onboardingSelectLanguage =>
      'Lütfen kullanmak istediğiniz dili seçin.\nيرجى تحديد لغتك المفضلة.';

  @override
  String get turnRight => 'انعطف يميناً ➔';

  @override
  String get turnSlightRight => 'انعطف يميناً قليلاً ➔';

  @override
  String get turnLeft => '⬅ انعطف يساراً';

  @override
  String get turnSlightLeft => '⬅ انعطف يساراً قليلاً';

  @override
  String get calibrationRequired => 'المعايرة مطلوبة';

  @override
  String get gold22kGram => 'جرام ذهب عيار 22';

  @override
  String get goldAtaToptan => 'آتا بالجملة';

  @override
  String get goldAtaCumhuriyet => 'آتا جمهوريت';

  @override
  String get gold22kBracelet => 'سوار عيار 22';

  @override
  String get gold18k => 'ذهب عيار 18';

  @override
  String get gold14k => 'ذهب عيار 14';

  @override
  String get goldHalf => 'نصف ليرة ذهب';

  @override
  String get goldGremse => 'ذهب غريمسة';

  @override
  String get goldAtaBesli => 'آتا بيشلي';

  @override
  String get goldResat => 'ليرة رشادية';

  @override
  String get goldHamit => 'ليرة حميدية';

  @override
  String get currencyChf => 'فرنك سويسري';

  @override
  String get currencyJpy => 'ين ياباني';

  @override
  String get currencySar => 'ريال سعودي';

  @override
  String get currencyAud => 'دولار أسترالي';

  @override
  String get currencyCad => 'دولار كندي';

  @override
  String get currencyRub => 'روبل روسي';

  @override
  String get currencyAzn => 'مانات أذربيجاني';

  @override
  String get currencyCny => 'يوان صيني';

  @override
  String get currencyRon => 'ليو روماني';

  @override
  String get currencyAed => 'درهم إماراتي';

  @override
  String get currencyBgn => 'ليف بلغاري';

  @override
  String get currencyKwd => 'دينار كويتي';

  @override
  String get currencyTry => 'ليرة تركية';

  @override
  String get holdToEdit => 'اضغط مطولاً للتعديل';

  @override
  String get editCounterTitle => 'تعديل العداد';

  @override
  String get editCounterHint => 'مثال: 2000';

  @override
  String get editTargetHint => 'مثال: 99';

  @override
  String get resetCounterConfirm => 'هل أنت متأكد أنك تريد إعادة تعيين العداد؟';

  @override
  String get dhikrTarget => 'الهدف:';

  @override
  String get imsakiyeTitle => 'جدول المواقيت';

  @override
  String get toolsGroupPrayer => 'الصلاة';

  @override
  String get toolsGroupInfo => 'معلومات';

  @override
  String get toolsGroupCalc => 'الحاسبات';

  @override
  String get toolImsakiyeDesc => 'مواقيت الشهر ورمضان';

  @override
  String get toolTrackerDesc => 'سجّل الصلوات التي أدّيتها';

  @override
  String get toolKazaDesc => 'عدّاد قضاء الصلوات والصيام';

  @override
  String get toolReligiousDaysDesc => 'الليالي المباركة والأعياد';

  @override
  String get toolEsmaDesc => 'الأسماء الحسنى ومعانيها';

  @override
  String get toolFridayDesc => 'رسائل جاهزة للمشاركة';

  @override
  String get toolZakatDesc => 'حساب الزكاة والعُشر';

  @override
  String get toolSettingsDesc => 'الموقع والإشعارات والمظهر';

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بعد $count يوم',
      many: 'بعد $count يومًا',
      few: 'بعد $count أيام',
      two: 'بعد يومين',
      one: 'غدًا',
      zero: 'اليوم',
    );
    return '$_temp0';
  }

  @override
  String get previousYear => 'السنة السابقة';

  @override
  String get nextYear => 'السنة التالية';

  @override
  String get previousItem => 'السابق';

  @override
  String get nextItem => 'التالي';

  @override
  String missedChangeConfirm(String name, int from, int to) {
    return 'سيتغيّر عدد قضاء $name من $from إلى $to. هل تريد الحفظ؟';
  }

  @override
  String get shareFailed => 'تعذّر إتمام العملية. يُرجى المحاولة مرة أخرى.';

  @override
  String get zakatCurrencyNote => 'جميع المبالغ بالليرة التركية (₺).';

  @override
  String get zakatCashTry => 'النقد (₺)';

  @override
  String get zakatRatesUnavailable =>
      'تعذّر جلب أسعار الذهب وأسعار الصرف الحالية. يُرجى إدخال الأسعار يدويًا.';

  @override
  String get zakatGoldGramPrice => 'سعر جرام الذهب عيار 24 (₺)';

  @override
  String get zakatGoldGramPriceHelp => 'يُستخدم لحساب حدّ النصاب.';

  @override
  String get zakatNisabUnknown =>
      'لا يمكن حساب حدّ النصاب بدون سعر الذهب. أدخل سعر الذهب للحصول على نتيجة صحيحة.';

  @override
  String get imsakiyeRamadan => 'رمضان';

  @override
  String imsakiyeRamadanTitle(int year) {
    return 'إمساكية رمضان $year';
  }

  @override
  String get imsakiyeDay => 'اليوم';

  @override
  String get imsakiyeSunriseShort => 'الشروق';

  @override
  String get imsakiyePrevMonth => 'الشهر السابق';

  @override
  String get imsakiyeNextMonth => 'الشهر التالي';

  @override
  String get imsakiyeNoLocation =>
      'يرجى تحديد موقعك أولاً لعرض جدول المواقيت. يمكنك تحديده من الشاشة الرئيسية أو من الإعدادات.';

  @override
  String get imsakiyeShareError =>
      'تعذّرت مشاركة الجدول. يرجى المحاولة مرة أخرى.';

  @override
  String get ramadanSahurLeft => 'الوقت المتبقي للسحور';

  @override
  String get ramadanIftarLeft => 'الوقت المتبقي للإفطار';

  @override
  String ramadanDayLabel(int day) {
    return 'اليوم $day من رمضان';
  }
}
