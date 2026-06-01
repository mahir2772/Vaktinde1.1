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
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String get hadithTitle => 'حديث اليوم';

  @override
  String get readMore => 'اقرأ المزيد...';

  @override
  String get share => 'مشاركة';

  @override
  String get close => 'إغلاق';

  @override
  String get loading => 'جاري حساب الأوقات...';

  @override
  String get error => 'خطأ';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get noData => 'لا توجد بيانات.';

  @override
  String get imsak => 'الفجر';

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
  String get exactAlarm => 'تنبيه في الوقت بالضبط';

  @override
  String get exactAlarmSub => 'يرسل إشعاراً.';

  @override
  String get silentNotif => 'إشعار نصي فقط';

  @override
  String get silentNotifSub => 'بدون صوت/أذان، فقط تنبيه.';

  @override
  String warningAlarm(String minute) {
    return 'تذكير قبل $minute دقيقة';
  }

  @override
  String get warningAlarmSub => 'صوت تنبيه قصير.';

  @override
  String get settings => 'الإعدادات';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get waitingLocation => 'جاري انتظار الموقع...';

  @override
  String get noInternet => 'لا يوجد اتصال بالإنترنت ولا توجد بيانات محفوظة.';

  @override
  String get gpsOff => 'نظام تحديد المواقع مغلق. يرجى تفعيله.';

  @override
  String get permissionDenied => 'تم رفض إذن الموقع.';

  @override
  String get locationError => 'تعذر الحصول على الموقع.';

  @override
  String get internetNeeded => 'يتطلب اتصالاً بالإنترنت.';

  @override
  String get soundEzan => 'أذان';

  @override
  String get soundBeep => 'تنبيه قصير';

  @override
  String get notifTitleTime => 'وقت الصلاة';

  @override
  String notifBodyTime(String vakit) {
    return 'ححان الآن موعد صلاة $vakit.';
  }

  @override
  String get notifTitleUpcoming => 'اقترب الوقت';

  @override
  String notifBodyUpcoming(String vakit, int minute) {
    return 'متبقي $minute دقيقة على صلاة $vakit.';
  }

  @override
  String get navPrayer => 'الأوقات';

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
  String get locationWarning => 'اختيار المنطقة مهم للحصول على أوقات دقيقة.';

  @override
  String get menuNotifications => 'أذونات الإشعارات';

  @override
  String get menuNotificationsSub => 'تحقق هنا إذا كنت لا تسمع صوتاً.';

  @override
  String get menuTroubleshoot => 'الإشعارات لا تعمل؟';

  @override
  String get menuTroubleshootSub => 'إعدادات البطارية لأجهزة Samsung/Xiaomi.';

  @override
  String get sectionSupport => 'الدعم';

  @override
  String get shareApp => 'شارك مع الأصدقاء';

  @override
  String get rateApp => 'قيمنا';

  @override
  String get contactUs => 'تواصل معنا والإبلاغ عن خطأ';

  @override
  String shareText(String link) {
    return 'لقد وجدت تطبيقاً رائعاً لمواقيت الصلاة! حمل من: $link';
  }

  @override
  String get batteryDialogTitle => 'إصلاح مشاكل الإشعارات';

  @override
  String get batteryDialogBody =>
      'قد يقوم هاتفك بإغلاق التطبيق لتوفير البطارية. لمنع ذلك:\n\n1. افتح التطبيقات الحديثة (الزر المربع).\n2. اضغط مطولاً على تطبيق \'Vaktinde\' أو انقر على الشعار.\n3. اضغط على رمز القفل 🔒 لقفل التطبيق.\n\nاذهب أيضاً إلى الإعدادات > التطبيقات > Vaktinde > البطارية > غير مقيد.';

  @override
  String get okUnderstood => 'حسناً، فهمت';

  @override
  String get religiousDaysTitle => 'الأيام الدينية';

  @override
  String errorOccurred(String error) {
    return 'حدث خطأ: $error';
  }

  @override
  String get noDataFound => 'لا توجد بيانات.';

  @override
  String noDataForYear(int year) {
    return 'لا توجد بيانات لعام $year.';
  }

  @override
  String religiousDaysListTitle(int year) {
    return 'قائمة الأيام الدينية لعام $year';
  }

  @override
  String get missedPrayersTitle => 'قضاء الصلوات';

  @override
  String get missedPrayersInfo =>
      'تتبع صلواتك الفائتة هنا وقم بإنقاص العدد عند القضاء.\n(اضغط على الرقم للإدخال اليدوي)';

  @override
  String editMissedTitle(String title) {
    return 'تعديل فائت $title';
  }

  @override
  String get missedCountLabel => 'العدد';

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
    return 'الوقت المتبقي لـ $vakit';
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
  String get liveRatesLoading => 'جاري جلب الأسعار المباشرة...';

  @override
  String get liveRatesInfo => 'يمكنك تعديل الأسعار يدوياً إذا لزم الأمر.';

  @override
  String get sectionGold => 'أصول الذهب';

  @override
  String get goldType => 'نوع الذهب';

  @override
  String get goldAmount => 'الكمية / جرام';

  @override
  String get goldUnitPrice => 'سعر الوحدة (ليرة)';

  @override
  String get sectionCurrency => 'أصول العملات';

  @override
  String get currencyType => 'نوع العملة';

  @override
  String get currencyAmount => 'المبلغ';

  @override
  String get currencyRate => 'السعر الحالي (ليرة)';

  @override
  String get sectionCashDebt => 'النقد والديون';

  @override
  String get cashAmount => 'النقد في اليد والبنك (ليرة)';

  @override
  String get debtAmount => 'إجمالي الديون (للخصم)';

  @override
  String get calculateButton => 'حساب';

  @override
  String get zakatResultTitle => 'الزكاة المستحقة';

  @override
  String get netAssets => 'صافي الأصول:';

  @override
  String get qiblaTitle => 'بوصلة القبلة';

  @override
  String get locationServiceOff => 'خدمة الموقع معطلة. يرجى تفعيل الموقع.';

  @override
  String get locationPermissionDenied => 'تم رفض إذن الموقع.';

  @override
  String get locationPermissionForever =>
      'تم رفض إذن الموقع بشكل دائم. قم بتفعيله من الإعدادات.';

  @override
  String compassError(String error) {
    return 'خطأ في المستشعر: $error';
  }

  @override
  String get noCompass => 'لا توجد بوصلة في الجهاز.';

  @override
  String get qiblaFound => 'لقد وجدت القبلة!';

  @override
  String qiblaAngle(String angle) {
    return 'زاوية القبلة: $angle°';
  }

  @override
  String get keepAwayMetal => 'ابعد الجهاز عن المعادن.';

  @override
  String get goldGram => 'جرام ذهب (24 قيراط)';

  @override
  String get goldQuarter => 'ربع ذهب';

  @override
  String get goldFull => 'ذهب كامل';

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
  String get bgDefault => 'افتراضي';

  @override
  String get bgMosque => 'مسجد';

  @override
  String get bgKaaba => 'الكعبة';

  @override
  String get bgQuran => 'القرآن';

  @override
  String get none => 'لا يوجد';

  @override
  String get zakatEligible => 'تجب الزكاة';

  @override
  String get zakatNotEligible => 'لا تجب الزكاة';

  @override
  String get nisabLimit => 'حد النصاب (80.18 جرام ذهب)';

  @override
  String get belowNisabMessage =>
      'الزكاة غير واجبة لأن صافي أصولك أقل من حد النصاب.';

  @override
  String get searchLocationTitle => 'بحث عن موقع (جميع أنحاء العالم)';

  @override
  String get searchLocationHint => 'المدينة أو البلد (مثال: باريس)';

  @override
  String get searchInitial => 'اكتب للبحث...';

  @override
  String get searchNotFound => 'لم يتم العثور على الموقع.';

  @override
  String get searchError => 'لم يتم العثور على نتائج. حاول مرة أخرى.';

  @override
  String locationSelected(String city) {
    return 'تم اختيار $city';
  }

  @override
  String channelSoundPrefix(String soundName) {
    return 'الصوت: $soundName';
  }

  @override
  String get channelSilentPrayers => 'إشعارات الصلاة الصامتة';

  @override
  String get tickerEzan => 'وقت الصلاة';

  @override
  String get stickyChannelName => 'مؤقت دائم';

  @override
  String get stickyChannelDesc => 'يعرض الوقت المتبقي للصلاة';

  @override
  String get timeLeftTo => 'الوقت المتبقي لـ: ';

  @override
  String get locationFallbackMessage =>
      'تعذر الحصول على الموقع، يتم استخدام القيمة الافتراضية.';

  @override
  String get fetchingLocation => 'جاري الحصول على الموقع...';

  @override
  String get directionNorth => 'ش';

  @override
  String get directionSouth => 'ج';

  @override
  String get directionEast => 'ق';

  @override
  String get directionWest => 'غ';

  @override
  String get calibrationInstruction => '(ارسم \'8\' للمعايرة)';

  @override
  String get zakatDescription =>
      'احسب زكاتك بالتفصيل وفقًا لفتاوى رئاسة الشؤون الدينية وأسعار الشراء / البيع الحالية في السوق.';

  @override
  String get cashAndCurrencyTitle => 'النقد والأصول بالعملات الأجنبية';

  @override
  String get cashTurkishLira => 'النقد بالليرة التركية (TRY)';

  @override
  String get goldAndSilverTitle => 'الذهب والفضة';

  @override
  String get silverGram => 'الفضة (جرام)';

  @override
  String get unitPrice => 'سعر الوحدة';

  @override
  String get commercialGoodsTitle => 'البضائع التجارية';

  @override
  String get commercialEvalCurrency => 'عملة التقييم';

  @override
  String get commercialGoodsValue => 'قيمة البضائع';

  @override
  String get exchangeRateValue => 'سعر الصرف';

  @override
  String get receivablesTitle => 'الذمم المدينة (القابلة للتحصيل)';

  @override
  String get receivableType => 'نوع الذمة (TRY، عملة أجنبية، ذهب)';

  @override
  String get amountOrCount => 'المبلغ / العدد';

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
      'نظراً لعدم اشتراط بلوغ النصاب في زكاة المنتجات الزراعية، يُضاف المبلغ الذي تصرح به مباشرة إلى سلة الزكاة.';

  @override
  String get harvestedProductValue => 'قيمة المحصول المحصود (TRY)';

  @override
  String get irrigationMethod => 'طريقة الري';

  @override
  String get debtsTitle => 'الديون (التي سيتم خصمها)';

  @override
  String get debtType => 'نوع الدين (TRY، عملة أجنبية، ذهب)';

  @override
  String get zakatAgriIncluded => 'تتضمن زكاة المنتجات الزراعية (العشر)';

  @override
  String get assetCheck => 'شيك';

  @override
  String get assetBond => 'سند لأمر';

  @override
  String get assetSukuk => 'صكوك';

  @override
  String get assetLeaseCert => 'شهادة إجارة';

  @override
  String get assetStock => 'سهم';

  @override
  String get agriSoil => 'منتج زراعي (زراعة التربة)';

  @override
  String get agriSoilless => 'منتج زراعي (زراعة بدون تربة)';

  @override
  String get agriRateNoCost => 'بدون تكلفة (مطر / نهر) - 10%';

  @override
  String get agriRateCostly => 'بتكلفة (محرك / نقل) - 5%';

  @override
  String get toImsak => 'إلى الفجر';

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
      'معايرة البوصلة ضعيفة. يرجى رسم رقم \'8\' في الهواء.';

  @override
  String get qiblaDirection => 'اتجاه القبلة';

  @override
  String get zikirmatikTitle => 'المسبحة الإلكترونية';

  @override
  String get dhikrSubhanallah => 'سبحان الله';

  @override
  String get dhikrElhamdulillah => 'الحمد لله';

  @override
  String get dhikrAllahuEkber => 'الله أكبر';

  @override
  String get dhikrKalima => 'كلمة التوحيد';

  @override
  String get dhikrSalavat => 'الصلوات';

  @override
  String get targetReached => 'اكتمل الهدف!';

  @override
  String get resetCounter => 'تصفير';

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
  String get customDhikrHint => 'أدخل الذكر الخاص بك هنا';

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
  String get introTitle1 => 'مرحبًا بك في Vaktinde';

  @override
  String get introDesc1 =>
      'تتبع أوقات الصلاة وأذكارك والأيام الدينية بسهولة من خلال واجهة حديثة وأنيقة.';

  @override
  String get introTitle2 => 'إشعارات ذكية';

  @override
  String get introDesc2 =>
      'احصل على إشعار بالصوت المفضل لديك في أوقات الصلاة. لا تفوت صلواتك أبدًا.';

  @override
  String get introTitle3 => 'أدوات متقدمة';

  @override
  String get introDesc3 =>
      'عزز روحانيتك باستخدام أدوات مثل عداد الأذكار المتحرك، والصلوات الفائتة، وحاسبة الزكاة.';

  @override
  String get introSkip => 'تخطي';

  @override
  String get introNext => 'التالي';

  @override
  String get introStart => 'البدء';

  @override
  String get dhikrListTitle => 'قائمة الأذكار';

  @override
  String get addCustomDhikr => 'إضافة ذكر مخصص';

  @override
  String get customDhikrAdded => 'تمت إضافة الذكر بنجاح.';

  @override
  String get customDhikrLimit => 'يمكنك إضافة ما يصل إلى 20 ذكراً مخصصاً!';

  @override
  String get deleteDhikr => 'حذف';

  @override
  String get statisticsTitle => 'الإحصائيات';

  @override
  String get monthly => 'شهري';

  @override
  String get yearly => 'سنوي';

  @override
  String get totalDhikr => 'مجموع الأذكار';

  @override
  String get today => 'اليوم';

  @override
  String get statsEmpty => 'لا توجد بيانات للأذكار بعد.';

  @override
  String get dhikrEstagfirullah => 'أستغفر الله';

  @override
  String get dhikrLaHavle => 'لا حول ولا قوة إلا بالله';

  @override
  String get dhikrHasbunallah => 'حسبنا الله ونعم الوكيل';

  @override
  String get dhikrSubhanallahi => 'سبحان الله وبحمده';

  @override
  String get dhikrYunus => 'دعاء النبي يونس';

  @override
  String get dhikrYaAllah => 'يا الله';

  @override
  String get dhikrYaRahman => 'يا رحمن';

  @override
  String get dhikrYaRahim => 'يا رحيم';

  @override
  String get dhikrYaSafi => 'يا شافي';

  @override
  String get dhikrYaRezzak => 'يا رزاق';

  @override
  String get dhikrYaFettah => 'يا فتاح';

  @override
  String get mainDhikrs => 'الأذكار الرئيسية';

  @override
  String get esmaulHusnaTab => 'أسماء الله الحسنى';

  @override
  String get qiblaCalibration =>
      'ارسم الرقم \'8\' في الهواء بهاتفك لمعايرة البوصلة بدقة.';
}
