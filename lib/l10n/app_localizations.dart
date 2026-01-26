import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Vaktinde'**
  String get appTitle;

  /// No description provided for @nextPrayer.
  ///
  /// In tr, this message translates to:
  /// **'Sıradaki Vakit'**
  String get nextPrayer;

  /// No description provided for @hadithTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günün Hadisi'**
  String get hadithTitle;

  /// No description provided for @readMore.
  ///
  /// In tr, this message translates to:
  /// **'Devamını Oku...'**
  String get readMore;

  /// No description provided for @share.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get share;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Vakitler Hesaplanıyor...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// No description provided for @noData.
  ///
  /// In tr, this message translates to:
  /// **'Veri yok.'**
  String get noData;

  /// No description provided for @imsak.
  ///
  /// In tr, this message translates to:
  /// **'İmsak'**
  String get imsak;

  /// No description provided for @gunes.
  ///
  /// In tr, this message translates to:
  /// **'Güneş'**
  String get gunes;

  /// No description provided for @ogle.
  ///
  /// In tr, this message translates to:
  /// **'Öğle'**
  String get ogle;

  /// No description provided for @ikindi.
  ///
  /// In tr, this message translates to:
  /// **'İkindi'**
  String get ikindi;

  /// No description provided for @aksam.
  ///
  /// In tr, this message translates to:
  /// **'Akşam'**
  String get aksam;

  /// No description provided for @yatsi.
  ///
  /// In tr, this message translates to:
  /// **'Yatsı'**
  String get yatsi;

  /// No description provided for @exactAlarm.
  ///
  /// In tr, this message translates to:
  /// **'Tam Vaktinde Oku'**
  String get exactAlarm;

  /// No description provided for @exactAlarmSub.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim gönderir.'**
  String get exactAlarmSub;

  /// No description provided for @silentNotif.
  ///
  /// In tr, this message translates to:
  /// **'Sadece Yazılı Bildirim'**
  String get silentNotif;

  /// No description provided for @silentNotifSub.
  ///
  /// In tr, this message translates to:
  /// **'Ezan/Ses çalmaz, sadece uyarı gelir.'**
  String get silentNotifSub;

  /// No description provided for @warningAlarm.
  ///
  /// In tr, this message translates to:
  /// **'{minute} dk Önce Uyar'**
  String warningAlarm(String minute);

  /// No description provided for @warningAlarmSub.
  ///
  /// In tr, this message translates to:
  /// **'Kısa bildirim sesi.'**
  String get warningAlarmSub;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @changeLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil Değiştir'**
  String get changeLanguage;

  /// No description provided for @waitingLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum Bekleniyor...'**
  String get waitingLocation;

  /// No description provided for @noInternet.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok ve kayıtlı veri bulunamadı.'**
  String get noInternet;

  /// No description provided for @gpsOff.
  ///
  /// In tr, this message translates to:
  /// **'GPS kapalı. Lütfen konumu açın.'**
  String get gpsOff;

  /// No description provided for @permissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni reddedildi.'**
  String get permissionDenied;

  /// No description provided for @locationError.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı.'**
  String get locationError;

  /// No description provided for @internetNeeded.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı gerekiyor.'**
  String get internetNeeded;

  /// No description provided for @soundEzan.
  ///
  /// In tr, this message translates to:
  /// **'Ezan'**
  String get soundEzan;

  /// No description provided for @soundBeep.
  ///
  /// In tr, this message translates to:
  /// **'Kısa Bildirim'**
  String get soundBeep;

  /// No description provided for @notifTitleTime.
  ///
  /// In tr, this message translates to:
  /// **'Ezan Vakti'**
  String get notifTitleTime;

  /// No description provided for @notifBodyTime.
  ///
  /// In tr, this message translates to:
  /// **'{vakit} vakti girdi.'**
  String notifBodyTime(String vakit);

  /// No description provided for @notifTitleUpcoming.
  ///
  /// In tr, this message translates to:
  /// **'Vakit Yaklaşıyor'**
  String get notifTitleUpcoming;

  /// No description provided for @notifBodyUpcoming.
  ///
  /// In tr, this message translates to:
  /// **'{vakit} vaktine {minute} dakika kaldı.'**
  String notifBodyUpcoming(String vakit, int minute);

  /// No description provided for @navPrayer.
  ///
  /// In tr, this message translates to:
  /// **'Vakitler'**
  String get navPrayer;

  /// No description provided for @navQibla.
  ///
  /// In tr, this message translates to:
  /// **'Kıble'**
  String get navQibla;

  /// No description provided for @navMenu.
  ///
  /// In tr, this message translates to:
  /// **'Menü'**
  String get navMenu;

  /// No description provided for @menuTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get menuTitle;

  /// No description provided for @sectionLocation.
  ///
  /// In tr, this message translates to:
  /// **'KONUM & VAKİTLER'**
  String get sectionLocation;

  /// No description provided for @changeLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum Değiştir'**
  String get changeLocation;

  /// No description provided for @citySelect.
  ///
  /// In tr, this message translates to:
  /// **'İl Seçiniz'**
  String get citySelect;

  /// No description provided for @districtSelect.
  ///
  /// In tr, this message translates to:
  /// **'İlçe Seçiniz'**
  String get districtSelect;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @locationWarning.
  ///
  /// In tr, this message translates to:
  /// **'Doğru namaz vakitleri için İlçe seçimi önemlidir.'**
  String get locationWarning;

  /// No description provided for @menuNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim İzinleri'**
  String get menuNotifications;

  /// No description provided for @menuNotificationsSub.
  ///
  /// In tr, this message translates to:
  /// **'Ses gelmiyorsa buradan kontrol et.'**
  String get menuNotificationsSub;

  /// No description provided for @menuTroubleshoot.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Gelmiyor mu?'**
  String get menuTroubleshoot;

  /// No description provided for @menuTroubleshootSub.
  ///
  /// In tr, this message translates to:
  /// **'Samsung/Xiaomi için pil ayarı yapın.'**
  String get menuTroubleshootSub;

  /// No description provided for @sectionSupport.
  ///
  /// In tr, this message translates to:
  /// **'DESTEK'**
  String get sectionSupport;

  /// No description provided for @shareApp.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşınla Paylaş'**
  String get shareApp;

  /// No description provided for @rateApp.
  ///
  /// In tr, this message translates to:
  /// **'Bize Puan Ver'**
  String get rateApp;

  /// No description provided for @contactUs.
  ///
  /// In tr, this message translates to:
  /// **'İletişim & Hata Bildir'**
  String get contactUs;

  /// No description provided for @shareText.
  ///
  /// In tr, this message translates to:
  /// **'Harika bir Ezan Vakti uygulaması buldum! İndir: {link}'**
  String shareText(String link);

  /// No description provided for @batteryDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Sorunu Çözümü'**
  String get batteryDialogTitle;

  /// No description provided for @batteryDialogBody.
  ///
  /// In tr, this message translates to:
  /// **'Telefonunuz pil tasarrufu için uygulamayı kapatıyor olabilir. Bunu önlemek için:\n\n1. Son Uygulamalar (Kare tuşu) ekranını açın.\n2. \'Vaktinde\' uygulamasının üzerine basılı tutun veya logoya tıklayın.\n3. Kilit Simgesine 🔒 basarak kilitleyin.\n\nAyrıca Ayarlar > Uygulamalar > Vaktinde > Pil > Kısıtlanmamış seçeneğini seçin.'**
  String get batteryDialogBody;

  /// No description provided for @okUnderstood.
  ///
  /// In tr, this message translates to:
  /// **'Tamam, Anladım'**
  String get okUnderstood;

  /// No description provided for @religiousDaysTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dini Günler'**
  String get religiousDaysTitle;

  /// No description provided for @errorOccurred.
  ///
  /// In tr, this message translates to:
  /// **'Hata oluştu: {error}'**
  String errorOccurred(String error);

  /// No description provided for @noDataFound.
  ///
  /// In tr, this message translates to:
  /// **'Veri bulunamadı.'**
  String get noDataFound;

  /// No description provided for @noDataForYear.
  ///
  /// In tr, this message translates to:
  /// **'{year} yılı için veri bulunamadı.'**
  String noDataForYear(int year);

  /// No description provided for @religiousDaysListTitle.
  ///
  /// In tr, this message translates to:
  /// **'{year} Yılı Dini Günler Listesi'**
  String religiousDaysListTitle(int year);

  /// No description provided for @missedPrayersTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kaza Takibi'**
  String get missedPrayersTitle;

  /// No description provided for @missedPrayersInfo.
  ///
  /// In tr, this message translates to:
  /// **'Kılmadığınız namazları buraya not edip, kıldıkça düşebilirsiniz.\n(Sayıya tıklayarak elle girebilirsiniz)'**
  String get missedPrayersInfo;

  /// No description provided for @editMissedTitle.
  ///
  /// In tr, this message translates to:
  /// **'{title} Kazasını Düzenle'**
  String editMissedTitle(String title);

  /// No description provided for @missedCountLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kaza Sayısı'**
  String get missedCountLabel;

  /// No description provided for @missedCountHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: 150'**
  String get missedCountHint;

  /// No description provided for @sabah.
  ///
  /// In tr, this message translates to:
  /// **'Sabah'**
  String get sabah;

  /// No description provided for @vitir.
  ///
  /// In tr, this message translates to:
  /// **'Vitir'**
  String get vitir;

  /// No description provided for @oruc.
  ///
  /// In tr, this message translates to:
  /// **'Oruç'**
  String get oruc;

  /// No description provided for @timeLeftFor.
  ///
  /// In tr, this message translates to:
  /// **'{vakit} Vaktine Kalan'**
  String timeLeftFor(String vakit);

  /// No description provided for @tomorrow.
  ///
  /// In tr, this message translates to:
  /// **'(Yarın)'**
  String get tomorrow;

  /// No description provided for @fridayMessagesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Cuma Mesajları'**
  String get fridayMessagesTitle;

  /// No description provided for @esmaulHusnaTitle.
  ///
  /// In tr, this message translates to:
  /// **'Esmaül Hüsna'**
  String get esmaulHusnaTitle;

  /// No description provided for @closeCaps.
  ///
  /// In tr, this message translates to:
  /// **'KAPAT'**
  String get closeCaps;

  /// No description provided for @zakatTitle.
  ///
  /// In tr, this message translates to:
  /// **'Zekat Hesapla'**
  String get zakatTitle;

  /// No description provided for @zakatCalculatorTitle.
  ///
  /// In tr, this message translates to:
  /// **'Akıllı Zekat Hesapla'**
  String get zakatCalculatorTitle;

  /// No description provided for @liveRatesLoading.
  ///
  /// In tr, this message translates to:
  /// **'Güncel kurlar çekiliyor...'**
  String get liveRatesLoading;

  /// No description provided for @liveRatesInfo.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik çekilen kurları isterseniz el ile düzeltebilirsiniz.'**
  String get liveRatesInfo;

  /// No description provided for @sectionGold.
  ///
  /// In tr, this message translates to:
  /// **'Altın Varlığı'**
  String get sectionGold;

  /// No description provided for @goldType.
  ///
  /// In tr, this message translates to:
  /// **'Altın Türü'**
  String get goldType;

  /// No description provided for @goldAmount.
  ///
  /// In tr, this message translates to:
  /// **'Adet / Gram'**
  String get goldAmount;

  /// No description provided for @goldUnitPrice.
  ///
  /// In tr, this message translates to:
  /// **'Birim Fiyatı (TL)'**
  String get goldUnitPrice;

  /// No description provided for @sectionCurrency.
  ///
  /// In tr, this message translates to:
  /// **'Döviz Varlığı'**
  String get sectionCurrency;

  /// No description provided for @currencyType.
  ///
  /// In tr, this message translates to:
  /// **'Döviz Türü'**
  String get currencyType;

  /// No description provided for @currencyAmount.
  ///
  /// In tr, this message translates to:
  /// **'Miktar'**
  String get currencyAmount;

  /// No description provided for @currencyRate.
  ///
  /// In tr, this message translates to:
  /// **'Güncel Kur (TL)'**
  String get currencyRate;

  /// No description provided for @sectionCashDebt.
  ///
  /// In tr, this message translates to:
  /// **'Nakit & Borçlar'**
  String get sectionCashDebt;

  /// No description provided for @cashAmount.
  ///
  /// In tr, this message translates to:
  /// **'Eldeki & Bankadaki Nakit (TL)'**
  String get cashAmount;

  /// No description provided for @debtAmount.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Borçlar (Düşülecek)'**
  String get debtAmount;

  /// No description provided for @calculateButton.
  ///
  /// In tr, this message translates to:
  /// **'HESAPLA'**
  String get calculateButton;

  /// No description provided for @zakatResultTitle.
  ///
  /// In tr, this message translates to:
  /// **'Vermeniz Gereken Zekat'**
  String get zakatResultTitle;

  /// No description provided for @netAssets.
  ///
  /// In tr, this message translates to:
  /// **'Net Varlık:'**
  String get netAssets;

  /// No description provided for @qiblaTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kıble Pusulası'**
  String get qiblaTitle;

  /// No description provided for @locationServiceOff.
  ///
  /// In tr, this message translates to:
  /// **'Konum servisi kapalı. Lütfen konumu açın.'**
  String get locationServiceOff;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni reddedildi.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionForever.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni kalıcı olarak engellendi. Ayarlardan açmalısınız.'**
  String get locationPermissionForever;

  /// No description provided for @compassError.
  ///
  /// In tr, this message translates to:
  /// **'Sensör hatası: {error}'**
  String compassError(String error);

  /// No description provided for @noCompass.
  ///
  /// In tr, this message translates to:
  /// **'Cihazda pusula yok.'**
  String get noCompass;

  /// No description provided for @qiblaFound.
  ///
  /// In tr, this message translates to:
  /// **'KIBLEYİ BULDUNUZ!'**
  String get qiblaFound;

  /// No description provided for @qiblaAngle.
  ///
  /// In tr, this message translates to:
  /// **'Kıble Açısı: {angle}°'**
  String qiblaAngle(String angle);

  /// No description provided for @keepAwayMetal.
  ///
  /// In tr, this message translates to:
  /// **'Metal eşyalardan uzak tutun.'**
  String get keepAwayMetal;

  /// No description provided for @goldGram.
  ///
  /// In tr, this message translates to:
  /// **'Gram Altın (24 Ayar)'**
  String get goldGram;

  /// No description provided for @goldQuarter.
  ///
  /// In tr, this message translates to:
  /// **'Çeyrek Altın'**
  String get goldQuarter;

  /// No description provided for @goldFull.
  ///
  /// In tr, this message translates to:
  /// **'Tam Altın'**
  String get goldFull;

  /// No description provided for @typeOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer (Manuel)'**
  String get typeOther;

  /// No description provided for @usd.
  ///
  /// In tr, this message translates to:
  /// **'ABD Doları (USD)'**
  String get usd;

  /// No description provided for @eur.
  ///
  /// In tr, this message translates to:
  /// **'Euro (EUR)'**
  String get eur;

  /// No description provided for @gbp.
  ///
  /// In tr, this message translates to:
  /// **'İngiliz Sterlini (GBP)'**
  String get gbp;

  /// No description provided for @sectionAppearance.
  ///
  /// In tr, this message translates to:
  /// **'GÖRÜNÜM & DİL'**
  String get sectionAppearance;

  /// No description provided for @appearanceSettings.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm Ayarları'**
  String get appearanceSettings;

  /// No description provided for @appearanceSub.
  ///
  /// In tr, this message translates to:
  /// **'Tema ve Arka Plan'**
  String get appearanceSub;

  /// No description provided for @themeMode.
  ///
  /// In tr, this message translates to:
  /// **'Tema Modu'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get themeDark;

  /// No description provided for @bgImage.
  ///
  /// In tr, this message translates to:
  /// **'Arka Plan Resmi'**
  String get bgImage;

  /// No description provided for @bgDefault.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan'**
  String get bgDefault;

  /// No description provided for @bgMosque.
  ///
  /// In tr, this message translates to:
  /// **'Cami'**
  String get bgMosque;

  /// No description provided for @bgKaaba.
  ///
  /// In tr, this message translates to:
  /// **'Kabe'**
  String get bgKaaba;

  /// No description provided for @bgQuran.
  ///
  /// In tr, this message translates to:
  /// **'Kur\'an'**
  String get bgQuran;

  /// No description provided for @none.
  ///
  /// In tr, this message translates to:
  /// **'Yok'**
  String get none;

  /// No description provided for @zakatEligible.
  ///
  /// In tr, this message translates to:
  /// **'Zekat Verilmesi Gerekir'**
  String get zakatEligible;

  /// No description provided for @zakatNotEligible.
  ///
  /// In tr, this message translates to:
  /// **'Zekat Gerekmiyor'**
  String get zakatNotEligible;

  /// No description provided for @nisabLimit.
  ///
  /// In tr, this message translates to:
  /// **'Nisab Sınırı (80.18 gr Altın)'**
  String get nisabLimit;

  /// No description provided for @belowNisabMessage.
  ///
  /// In tr, this message translates to:
  /// **'Net varlığınız Nisab miktarının (zenginlik sınırı) altında olduğu için zekat farz değildir.'**
  String get belowNisabMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'de', 'en', 'fr', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
