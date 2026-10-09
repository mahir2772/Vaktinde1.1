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

  /// No description provided for @navZikir.
  ///
  /// In tr, this message translates to:
  /// **'Zikir'**
  String get navZikir;

  /// No description provided for @adPrivacySettings.
  ///
  /// In tr, this message translates to:
  /// **'Reklam Gizlilik Ayarları'**
  String get adPrivacySettings;

  /// No description provided for @adPrivacySettingsSub.
  ///
  /// In tr, this message translates to:
  /// **'Kişiselleştirilmiş reklam iznini değiştirin'**
  String get adPrivacySettingsSub;

  /// No description provided for @showcaseLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama dilini buradan değiştirebilirsiniz.'**
  String get showcaseLanguage;

  /// No description provided for @showcaseStory.
  ///
  /// In tr, this message translates to:
  /// **'Günün ayetini ve hadisini buradan okuyabilirsiniz.'**
  String get showcaseStory;

  /// No description provided for @showcaseAlarms.
  ///
  /// In tr, this message translates to:
  /// **'Her vakit için ezan ve hatırlatma alarmlarını buradan ayarlayabilirsiniz.'**
  String get showcaseAlarms;

  /// No description provided for @showcaseQibla.
  ///
  /// In tr, this message translates to:
  /// **'Kıble yönünü pusula ile bulabilirsiniz.'**
  String get showcaseQibla;

  /// No description provided for @showcaseZikir.
  ///
  /// In tr, this message translates to:
  /// **'Zikirlerinizi buradan takip edebilirsiniz.'**
  String get showcaseZikir;

  /// No description provided for @refreshLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konumu yenile'**
  String get refreshLocation;

  /// No description provided for @navTools.
  ///
  /// In tr, this message translates to:
  /// **'Araçlar'**
  String get navTools;

  /// No description provided for @hadithNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Hadis metni bulunamadı.'**
  String get hadithNotFound;

  /// No description provided for @timesLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Vakitler yüklenemedi. Lütfen tekrar deneyin.'**
  String get timesLoadError;

  /// No description provided for @sunriseNotPrayer.
  ///
  /// In tr, this message translates to:
  /// **'Güneşin doğuşu, namaz vakti değildir'**
  String get sunriseNotPrayer;

  /// No description provided for @currentPrayer.
  ///
  /// In tr, this message translates to:
  /// **'Şu anki vakit'**
  String get currentPrayer;

  /// No description provided for @textCopied.
  ///
  /// In tr, this message translates to:
  /// **'Metin kopyalandı'**
  String get textCopied;

  /// No description provided for @updateDownloaded.
  ///
  /// In tr, this message translates to:
  /// **'Yeni sürüm indirildi.'**
  String get updateDownloaded;

  /// No description provided for @restartAction.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden başlat'**
  String get restartAction;

  /// No description provided for @qiblaTurnRight.
  ///
  /// In tr, this message translates to:
  /// **'Sağa dönün'**
  String get qiblaTurnRight;

  /// No description provided for @qiblaTurnSlightRight.
  ///
  /// In tr, this message translates to:
  /// **'Biraz sağa dönün'**
  String get qiblaTurnSlightRight;

  /// No description provided for @qiblaTurnLeft.
  ///
  /// In tr, this message translates to:
  /// **'Sola dönün'**
  String get qiblaTurnLeft;

  /// No description provided for @qiblaTurnSlightLeft.
  ///
  /// In tr, this message translates to:
  /// **'Biraz sola dönün'**
  String get qiblaTurnSlightLeft;

  /// No description provided for @phoneHeading.
  ///
  /// In tr, this message translates to:
  /// **'Telefon yönü: {deg}°'**
  String phoneHeading(String deg);

  /// No description provided for @usingSavedLocation.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı konum kullanılıyor.'**
  String get usingSavedLocation;

  /// No description provided for @exampleHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: {n}'**
  String exampleHint(int n);

  /// No description provided for @noCustomDhikr.
  ///
  /// In tr, this message translates to:
  /// **'Henüz özel zikir eklemediniz.'**
  String get noCustomDhikr;

  /// No description provided for @messagesShuffled.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlar karıştırıldı'**
  String get messagesShuffled;

  /// No description provided for @shuffle.
  ///
  /// In tr, this message translates to:
  /// **'Karıştır'**
  String get shuffle;

  /// No description provided for @copy.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get copy;

  /// No description provided for @messageCopied.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj kopyalandı'**
  String get messageCopied;

  /// No description provided for @versionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm {v}'**
  String versionLabel(String v);

  /// No description provided for @supportMailSubject.
  ///
  /// In tr, this message translates to:
  /// **'Vaktinde - Destek'**
  String get supportMailSubject;

  /// No description provided for @madeBy.
  ///
  /// In tr, this message translates to:
  /// **'mmdigital tarafından ❤️ ile yapıldı'**
  String get madeBy;

  /// No description provided for @permissionPrimingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ezan vakitlerini kaçırmayın'**
  String get permissionPrimingTitle;

  /// No description provided for @permissionPrimingBody.
  ///
  /// In tr, this message translates to:
  /// **'Ezan bildirimleri için bildirim iznine, vakitleri bulunduğunuz yere göre hesaplamak için konum iznine ihtiyacımız var.'**
  String get permissionPrimingBody;

  /// No description provided for @continueAction.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get continueAction;

  /// No description provided for @ok.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

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
  /// **'Tam Vaktinde Bildir'**
  String get exactAlarm;

  /// No description provided for @reminderTitleAt.
  ///
  /// In tr, this message translates to:
  /// **'Vakit Hatırlatması'**
  String get reminderTitleAt;

  /// No description provided for @notifBodyUpcomingAt.
  ///
  /// In tr, this message translates to:
  /// **'{vakit} vakti: {time}'**
  String notifBodyUpcomingAt(String vakit, String time);

  /// No description provided for @endReminderTitleAt.
  ///
  /// In tr, this message translates to:
  /// **'Vakit Çıkışı'**
  String get endReminderTitleAt;

  /// No description provided for @endReminderNotifBodyAt.
  ///
  /// In tr, this message translates to:
  /// **'{vakit} vaktinin çıkışı: {time}'**
  String endReminderNotifBodyAt(String vakit, String time);

  /// No description provided for @ramadanImsakBodyAt.
  ///
  /// In tr, this message translates to:
  /// **'Sahur vakti {time} itibarıyla sona erdi. Hayırlı oruçlar!'**
  String ramadanImsakBodyAt(String time);

  /// No description provided for @alarmHealthExactOff.
  ///
  /// In tr, this message translates to:
  /// **'Alarm izni kapalı: ezan ve hatırlatmalar yaklaşık bir saate kadar gecikebilir (imsak ve sahur dahil).'**
  String get alarmHealthExactOff;

  /// No description provided for @healthTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Kontrolü'**
  String get healthTitle;

  /// No description provided for @healthSub.
  ///
  /// In tr, this message translates to:
  /// **'Ezan gelmiyorsa ayarları adım adım kontrol edin'**
  String get healthSub;

  /// No description provided for @healthSectionStatus.
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get healthSectionStatus;

  /// No description provided for @healthEzansTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ezan alarmları'**
  String get healthEzansTitle;

  /// No description provided for @healthEzansOn.
  ///
  /// In tr, this message translates to:
  /// **'Açık: {names}'**
  String healthEzansOn(String names);

  /// No description provided for @healthEzansNone.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbir vakit için ezan açık değil.'**
  String get healthEzansNone;

  /// No description provided for @healthNextTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sıradaki ezan'**
  String get healthNextTitle;

  /// No description provided for @healthNextNone.
  ///
  /// In tr, this message translates to:
  /// **'Kurulu ezan bulunamadı.'**
  String get healthNextNone;

  /// No description provided for @healthReschedule.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden kur'**
  String get healthReschedule;

  /// No description provided for @healthNotificationsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get healthNotificationsTitle;

  /// No description provided for @healthNotificationsOk.
  ///
  /// In tr, this message translates to:
  /// **'Açık.'**
  String get healthNotificationsOk;

  /// No description provided for @healthOpenSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarları aç'**
  String get healthOpenSettings;

  /// No description provided for @healthExactTitle.
  ///
  /// In tr, this message translates to:
  /// **'Alarmlar ve hatırlatıcılar'**
  String get healthExactTitle;

  /// No description provided for @healthExactOk.
  ///
  /// In tr, this message translates to:
  /// **'İzin verildi: ezan tam vaktinde çalar.'**
  String get healthExactOk;

  /// No description provided for @healthVolumeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ses'**
  String get healthVolumeTitle;

  /// No description provided for @healthVolumeOk.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim sesi açık.'**
  String get healthVolumeOk;

  /// No description provided for @healthVolumeAlarmOk.
  ///
  /// In tr, this message translates to:
  /// **'Alarm sesi açık.'**
  String get healthVolumeAlarmOk;

  /// No description provided for @healthVolumeSilent.
  ///
  /// In tr, this message translates to:
  /// **'Telefon sessiz ya da titreşim modunda: ezan sesi duyulmaz.'**
  String get healthVolumeSilent;

  /// No description provided for @healthVolumeNotificationMuted.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim sesi kapalı: ezan sesi duyulmaz.'**
  String get healthVolumeNotificationMuted;

  /// No description provided for @healthVolumeAlarmMuted.
  ///
  /// In tr, this message translates to:
  /// **'Alarm sesi kapalı: ezan sesi duyulmaz.'**
  String get healthVolumeAlarmMuted;

  /// No description provided for @healthAlarmStreamTip.
  ///
  /// In tr, this message translates to:
  /// **'“{setting}” açıkken ezan alarm sesiyle çalar.'**
  String healthAlarmStreamTip(String setting);

  /// No description provided for @healthDndTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rahatsız Etmeyin'**
  String get healthDndTitle;

  /// No description provided for @healthDndOff.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı.'**
  String get healthDndOff;

  /// No description provided for @healthDndOn.
  ///
  /// In tr, this message translates to:
  /// **'Açık: ezan sesi duyulmayabilir.'**
  String get healthDndOn;

  /// No description provided for @healthDndAlarm.
  ///
  /// In tr, this message translates to:
  /// **'Açık, ancak “{setting}” sayesinde ezan alarm sesiyle çalar.'**
  String healthDndAlarm(String setting);

  /// No description provided for @healthBatteryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Pil kullanımı'**
  String get healthBatteryTitle;

  /// No description provided for @healthBatteryOk.
  ///
  /// In tr, this message translates to:
  /// **'Pil optimizasyonu Vaktinde için kapalı.'**
  String get healthBatteryOk;

  /// No description provided for @healthBatteryOptimized.
  ///
  /// In tr, this message translates to:
  /// **'Pil optimizasyonu açık: telefon Vaktinde\'yi arka planda durdurabilir. Uygulama ayarlarında Pil bölümünden “Kısıtlanmamış” seçeneğini işaretleyin (bazı telefonlarda “Sınırsız” ya da “Kısıtlama yok”).'**
  String get healthBatteryOptimized;

  /// No description provided for @healthBackgroundTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arka planda çalışma'**
  String get healthBackgroundTitle;

  /// No description provided for @healthBackgroundToday.
  ///
  /// In tr, this message translates to:
  /// **'Son çalışma: bugün {time}'**
  String healthBackgroundToday(String time);

  /// No description provided for @healthBackgroundYesterday.
  ///
  /// In tr, this message translates to:
  /// **'Son çalışma: dün {time}'**
  String healthBackgroundYesterday(String time);

  /// No description provided for @healthBackgroundStale.
  ///
  /// In tr, this message translates to:
  /// **'Vaktinde son 48 saatte arka planda hiç çalışmadı: telefon uygulamayı durduruyor olabilir.'**
  String get healthBackgroundStale;

  /// No description provided for @healthShowSteps.
  ///
  /// In tr, this message translates to:
  /// **'Adımları göster'**
  String get healthShowSteps;

  /// No description provided for @healthGuideTitle.
  ///
  /// In tr, this message translates to:
  /// **'{brand} için ayarlar'**
  String healthGuideTitle(String brand);

  /// No description provided for @healthGuideTitleGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Telefonunuz için ayarlar'**
  String get healthGuideTitleGeneric;

  /// No description provided for @healthGuideStale.
  ///
  /// In tr, this message translates to:
  /// **'Arka planda çalışma durmuş görünüyor. Ezanın gecikmemesi için şu ayarları yapın:'**
  String get healthGuideStale;

  /// No description provided for @healthGuideMore.
  ///
  /// In tr, this message translates to:
  /// **'Telefon modelinize göre ayrıntılı anlatım (İngilizce)'**
  String get healthGuideMore;

  /// No description provided for @healthTestTitle.
  ///
  /// In tr, this message translates to:
  /// **'Test ezanı'**
  String get healthTestTitle;

  /// No description provided for @healthTestInfo.
  ///
  /// In tr, this message translates to:
  /// **'Gerçek ezanla aynı ses ve ayarlarla 1 dakika sonra bir test bildirimi gelir.'**
  String get healthTestInfo;

  /// No description provided for @healthTestButton.
  ///
  /// In tr, this message translates to:
  /// **'1 dk sonra test ezanı'**
  String get healthTestButton;

  /// No description provided for @healthTestScheduled.
  ///
  /// In tr, this message translates to:
  /// **'Test ezanı 1 dakika sonra çalacak. Uygulamayı kapatabilirsiniz.'**
  String get healthTestScheduled;

  /// No description provided for @healthTestNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu bildirim geldiyse ezan bildirimleri çalışıyor.'**
  String get healthTestNotifBody;

  /// No description provided for @healthStepXiaomiAutostart.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama ayarlarında “Otomatik başlatma” seçeneğini açın.'**
  String get healthStepXiaomiAutostart;

  /// No description provided for @healthStepXiaomiBattery.
  ///
  /// In tr, this message translates to:
  /// **'Aynı ekranda Pil tasarrufu (ya da Pil) bölümünden “Kısıtlama yok” seçeneğini işaretleyin.'**
  String get healthStepXiaomiBattery;

  /// No description provided for @healthStepHuaweiLaunch.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar\'da “Uygulama başlatma” bölümünü açın (Pil ya da Uygulamalar altında). Vaktinde için otomatik yönetimi kapatın ve açılan penceredeki tüm seçenekleri açık bırakın.'**
  String get healthStepHuaweiLaunch;

  /// No description provided for @healthStepOppoBackground.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama ayarları > Pil kullanımı bölümünde arka planda çalışmaya ve otomatik başlatmaya izin verin.'**
  String get healthStepOppoBackground;

  /// No description provided for @healthStepVivoBackground.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar > Pil bölümünde Vaktinde\'nin arka planda yüksek güç tüketmesine izin verin.'**
  String get healthStepVivoBackground;

  /// No description provided for @healthStepAutostartIn.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar\'da ya da {app} uygulamasında Vaktinde için otomatik başlatmayı açın.'**
  String healthStepAutostartIn(String app);

  /// No description provided for @healthStepAppBattery.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama ayarları > Pil bölümünde “Kısıtlanmamış” seçeneğini işaretleyin.'**
  String get healthStepAppBattery;

  /// No description provided for @healthStepSamsungSleeping.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar > Pil > Arka plan kullanım sınırları bölümünde Vaktinde\'yi hiç uyku moduna alınmayan uygulamalara ekleyin.'**
  String get healthStepSamsungSleeping;

  /// No description provided for @healthStepLockRecents.
  ///
  /// In tr, this message translates to:
  /// **'Son uygulamalar ekranında Vaktinde\'yi kilitleyin (telefonunuzda bu seçenek varsa).'**
  String get healthStepLockRecents;

  /// No description provided for @healthDetails.
  ///
  /// In tr, this message translates to:
  /// **'Ayrıntılar'**
  String get healthDetails;

  /// No description provided for @alarmHealthExactAction.
  ///
  /// In tr, this message translates to:
  /// **'İzin ver'**
  String get alarmHealthExactAction;

  /// No description provided for @alarmHealthNotificationsOff.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler kapalı, ezan çalmaz.'**
  String get alarmHealthNotificationsOff;

  /// No description provided for @alarmHealthNotificationsAction.
  ///
  /// In tr, this message translates to:
  /// **'Aç'**
  String get alarmHealthNotificationsAction;

  /// No description provided for @ezanAlarmStreamTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sessiz modda da çal'**
  String get ezanAlarmStreamTitle;

  /// No description provided for @ezanAlarmStreamSub.
  ///
  /// In tr, this message translates to:
  /// **'Ezan, telefon sessizdeyken de alarm ses seviyesinde çalar.'**
  String get ezanAlarmStreamSub;

  /// No description provided for @channelAlarmSound.
  ///
  /// In tr, this message translates to:
  /// **'Ses: {soundName} (sessizde de çalar)'**
  String channelAlarmSound(String soundName);

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
  /// **'Ezan/ses çalmaz, sadece uyarı gelir.'**
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
  /// **'Ana Sayfa'**
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
  /// **'Doğru namaz vakitleri için ilçe seçimi önemlidir.'**
  String get locationWarning;

  /// No description provided for @menuNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim İzinleri'**
  String get menuNotifications;

  /// No description provided for @menuNotificationsSub.
  ///
  /// In tr, this message translates to:
  /// **'Ses gelmiyorsa buradan kontrol edin.'**
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

  /// No description provided for @timeAdjustTitle.
  ///
  /// In tr, this message translates to:
  /// **'Vakit İnce Ayarı'**
  String get timeAdjustTitle;

  /// No description provided for @tapToCount.
  ///
  /// In tr, this message translates to:
  /// **'Saymak için dokunun'**
  String get tapToCount;

  /// No description provided for @timeAdjustSub.
  ///
  /// In tr, this message translates to:
  /// **'Vakitleri dakika dakika düzeltin'**
  String get timeAdjustSub;

  /// No description provided for @timeAdjustInfo.
  ///
  /// In tr, this message translates to:
  /// **'Vakitler konumunuza göre Diyanet yöntemiyle hesaplanır. Bölgenizdeki caminin vakitleriyle küçük farklar varsa her vakti dakika olarak ileri veya geri alabilirsiniz. Ayar ana ekrana, widget\'lara ve ezan bildirimlerine uygulanır.'**
  String get timeAdjustInfo;

  /// No description provided for @timeAdjustReset.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get timeAdjustReset;

  /// No description provided for @timeAdjustMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{value} dk'**
  String timeAdjustMinutes(String value);

  /// No description provided for @timeAdjustSaved.
  ///
  /// In tr, this message translates to:
  /// **'Vakitler güncellendi'**
  String get timeAdjustSaved;

  /// No description provided for @trackerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Namaz Takibi'**
  String get trackerTitle;

  /// No description provided for @trackerToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get trackerToday;

  /// No description provided for @trackerYesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get trackerYesterday;

  /// No description provided for @trackerPrayedAction.
  ///
  /// In tr, this message translates to:
  /// **'Kıldım'**
  String get trackerPrayedAction;

  /// No description provided for @trackerLast7Days.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 Gün'**
  String get trackerLast7Days;

  /// No description provided for @trackerCompletion.
  ///
  /// In tr, this message translates to:
  /// **'30 günlük oran'**
  String get trackerCompletion;

  /// No description provided for @trackerStreak.
  ///
  /// In tr, this message translates to:
  /// **'Seri'**
  String get trackerStreak;

  /// No description provided for @trackerStreakDays.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{{count} gün}}'**
  String trackerStreakDays(int count);

  /// No description provided for @trackerNotYet.
  ///
  /// In tr, this message translates to:
  /// **'Bu vakit henüz girmedi.'**
  String get trackerNotYet;

  /// No description provided for @trackerKazaButton.
  ///
  /// In tr, this message translates to:
  /// **'Kılınmayanları kazaya ekle'**
  String get trackerKazaButton;

  /// No description provided for @trackerKazaInfo.
  ///
  /// In tr, this message translates to:
  /// **'Son 30 gün içinde (takibe başladığınız günden itibaren) işaretlenmemiş vakitler kaza sayaçlarına eklenir. Her vakit yalnızca bir kez eklenir.'**
  String get trackerKazaInfo;

  /// No description provided for @trackerKazaConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{İşaretlenmemiş {count} vakit kaza sayaçlarına eklenecek. Devam edilsin mi?}}'**
  String trackerKazaConfirm(int count);

  /// No description provided for @trackerKazaAdd.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get trackerKazaAdd;

  /// No description provided for @trackerKazaDone.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, other{{count} vakit kazaya eklendi.}}'**
  String trackerKazaDone(int count);

  /// No description provided for @trackerKazaNone.
  ///
  /// In tr, this message translates to:
  /// **'Kazaya eklenecek vakit yok.'**
  String get trackerKazaNone;

  /// No description provided for @trackerKazaLocked.
  ///
  /// In tr, this message translates to:
  /// **'Bu vakit kazaya eklendi. Kıldığınızda Kaza Takibi\'nden düşebilirsiniz.'**
  String get trackerKazaLocked;

  /// No description provided for @trackerLegendPrayed.
  ///
  /// In tr, this message translates to:
  /// **'Kılındı'**
  String get trackerLegendPrayed;

  /// No description provided for @trackerLegendKaza.
  ///
  /// In tr, this message translates to:
  /// **'Kazaya eklendi'**
  String get trackerLegendKaza;

  /// No description provided for @kerahatActive.
  ///
  /// In tr, this message translates to:
  /// **'Şu an kerahat vakti: {range}'**
  String kerahatActive(String range);

  /// No description provided for @kerahatUpcoming.
  ///
  /// In tr, this message translates to:
  /// **'Kerahat vakti yaklaşıyor: {range}'**
  String kerahatUpcoming(String range);

  /// No description provided for @endReminderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Vakit Çıkmadan Hatırlat'**
  String get endReminderTitle;

  /// No description provided for @dailyContentNotifTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günün Ayeti ve Hadisi Bildirimleri'**
  String get dailyContentNotifTitle;

  /// No description provided for @dailyContentNotifSub.
  ///
  /// In tr, this message translates to:
  /// **'Her gün sabah bir ayet, akşam bir hadis gönderir.'**
  String get dailyContentNotifSub;

  /// No description provided for @religiousDaysNotifTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dini Gün ve Kandil Bildirimleri'**
  String get religiousDaysNotifTitle;

  /// No description provided for @religiousDaysNotifSub.
  ///
  /// In tr, this message translates to:
  /// **'Kandil, bayram ve diğer dini günlerde sabah bildirim gönderir.'**
  String get religiousDaysNotifSub;

  /// No description provided for @religiousDaysChannel.
  ///
  /// In tr, this message translates to:
  /// **'Dini Günler ve Kandiller'**
  String get religiousDaysChannel;

  /// No description provided for @ucAylarBaslangici.
  ///
  /// In tr, this message translates to:
  /// **'Üç Ayların Başlangıcı'**
  String get ucAylarBaslangici;

  /// No description provided for @ramazanArefesi.
  ///
  /// In tr, this message translates to:
  /// **'Ramazan Bayramı Arefesi'**
  String get ramazanArefesi;

  /// No description provided for @kurbanArefesi.
  ///
  /// In tr, this message translates to:
  /// **'Kurban Bayramı Arefesi'**
  String get kurbanArefesi;

  /// No description provided for @ucAylarNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Recep, Şaban ve Ramazan aylarından oluşan üç aylar bugün başladı. Üç aylarınız mübarek olsun.'**
  String get ucAylarNotifBody;

  /// No description provided for @ucAylarRegaipTitle.
  ///
  /// In tr, this message translates to:
  /// **'Üç Aylar ve Regaib Kandili'**
  String get ucAylarRegaipTitle;

  /// No description provided for @ucAylarRegaipNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Üç aylar bugün başladı, bu gece de Regaib Kandili. Üç aylarınız ve kandiliniz mübarek olsun.'**
  String get ucAylarRegaipNotifBody;

  /// No description provided for @regaipKandiliNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu gece Regaib Kandili. Kandiliniz mübarek olsun.'**
  String get regaipKandiliNotifBody;

  /// No description provided for @miracKandiliNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu gece Miraç Kandili. Kandiliniz mübarek olsun.'**
  String get miracKandiliNotifBody;

  /// No description provided for @beratKandiliNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu gece Berat Kandili. Kandiliniz mübarek olsun.'**
  String get beratKandiliNotifBody;

  /// No description provided for @mevlidKandiliNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu gece Mevlid Kandili. Kandiliniz mübarek olsun.'**
  String get mevlidKandiliNotifBody;

  /// No description provided for @kadirGecesiNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu gece Kadir Gecesi. Kadir Geceniz mübarek olsun.'**
  String get kadirGecesiNotifBody;

  /// No description provided for @ramazanBaslangiciNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Ramazan yarın başlıyor; ilk teravih ve sahur bu gece. Hayırlı Ramazanlar!'**
  String get ramazanBaslangiciNotifBody;

  /// No description provided for @ramazanArefesiNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Bugün arefe, yarın Ramazan Bayramı. Bayramınız şimdiden mübarek olsun.'**
  String get ramazanArefesiNotifBody;

  /// No description provided for @ramazanBayramiNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Ramazan Bayramınız mübarek olsun. Nice bayramlara!'**
  String get ramazanBayramiNotifBody;

  /// No description provided for @kurbanArefesiNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Bugün arefe, yarın Kurban Bayramı. Bayramınız şimdiden mübarek olsun.'**
  String get kurbanArefesiNotifBody;

  /// No description provided for @kurbanBayramiNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Kurban Bayramınız mübarek, kurbanlarınız kabul olsun.'**
  String get kurbanBayramiNotifBody;

  /// No description provided for @hicriYilbasiNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Bugün Hicri Yılbaşı. Yeni yılınız hayırlara vesile olsun.'**
  String get hicriYilbasiNotifBody;

  /// No description provided for @asureGunuNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'Bugün Aşure Günü. Hayırlara vesile olsun.'**
  String get asureGunuNotifBody;

  /// No description provided for @privacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacyPolicy;

  /// No description provided for @endReminderSub.
  ///
  /// In tr, this message translates to:
  /// **'Kılındı olarak işaretlenmemiş namazlar için vakit çıkmadan bildirim gönderir.'**
  String get endReminderSub;

  /// No description provided for @endReminderNotifTitle.
  ///
  /// In tr, this message translates to:
  /// **'Vakit Çıkıyor'**
  String get endReminderNotifTitle;

  /// No description provided for @endReminderNotifBody.
  ///
  /// In tr, this message translates to:
  /// **'{vakit} vaktinin çıkmasına {minute} dakika kaldı.'**
  String endReminderNotifBody(String vakit, int minute);

  /// No description provided for @endReminderChannel.
  ///
  /// In tr, this message translates to:
  /// **'Vakit Çıkış Hatırlatmaları'**
  String get endReminderChannel;

  /// No description provided for @ramadanIftarTitle.
  ///
  /// In tr, this message translates to:
  /// **'İftar Vakti'**
  String get ramadanIftarTitle;

  /// No description provided for @ramadanIftarBody.
  ///
  /// In tr, this message translates to:
  /// **'{vakit} vakti girdi. Hayırlı iftarlar!'**
  String ramadanIftarBody(String vakit);

  /// No description provided for @ramadanImsakTitle.
  ///
  /// In tr, this message translates to:
  /// **'İmsak Vakti'**
  String get ramadanImsakTitle;

  /// No description provided for @ramadanImsakBody.
  ///
  /// In tr, this message translates to:
  /// **'Sahur vakti sona erdi. Hayırlı oruçlar!'**
  String get ramadanImsakBody;

  /// No description provided for @sectionSupport.
  ///
  /// In tr, this message translates to:
  /// **'DESTEK'**
  String get sectionSupport;

  /// No description provided for @shareApp.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşlarınızla Paylaş'**
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
  /// **'Harika bir ezan vakti uygulaması buldum! İndir: {link}'**
  String shareText(String link);

  /// No description provided for @batteryDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Sorunu Çözümü'**
  String get batteryDialogTitle;

  /// No description provided for @batteryDialogBody.
  ///
  /// In tr, this message translates to:
  /// **'Telefonunuz pil tasarrufu için uygulamayı kapatıyor olabilir. Bunu önlemek için:\n\n1. Son Uygulamalar (kare tuşu) ekranını açın.\n2. \'Vaktinde\' uygulamasının üzerine basılı tutun veya simgesine dokunun.\n3. Kilit simgesine 🔒 dokunarak uygulamayı kilitleyin.\n\nAyrıca Ayarlar > Uygulamalar > Vaktinde > Pil bölümünden \'Kısıtlanmamış\' seçeneğini işaretleyin.'**
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
  /// **'Kılmadığınız namazları buraya not edip, kıldıkça düşebilirsiniz.\n(Sayıya dokunarak elle girebilirsiniz)'**
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
  /// **'Akıllı Zekat Hesaplama'**
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
  /// **'Birim Fiyatı'**
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
  /// **'Tema ve arka plan'**
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
  /// **'Nisap Sınırı (80,18 gr Altın)'**
  String get nisabLimit;

  /// No description provided for @belowNisabMessage.
  ///
  /// In tr, this message translates to:
  /// **'Net varlığınız nisap miktarının (zenginlik sınırı) altında olduğu için zekat farz değildir.'**
  String get belowNisabMessage;

  /// No description provided for @searchLocationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konum Ara (Tüm Dünya)'**
  String get searchLocationTitle;

  /// No description provided for @searchLocationHint.
  ///
  /// In tr, this message translates to:
  /// **'Şehir veya Ülke (Örn: Paris)'**
  String get searchLocationHint;

  /// No description provided for @searchInitial.
  ///
  /// In tr, this message translates to:
  /// **'Aramak istediğiniz yeri yazın...'**
  String get searchInitial;

  /// No description provided for @searchNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Konum bulunamadı.'**
  String get searchNotFound;

  /// No description provided for @searchError.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı. Lütfen tekrar deneyin.'**
  String get searchError;

  /// No description provided for @locationSelected.
  ///
  /// In tr, this message translates to:
  /// **'{city} seçildi'**
  String locationSelected(String city);

  /// No description provided for @channelSoundPrefix.
  ///
  /// In tr, this message translates to:
  /// **'Ses: {soundName}'**
  String channelSoundPrefix(String soundName);

  /// No description provided for @channelSilentPrayers.
  ///
  /// In tr, this message translates to:
  /// **'Sessiz Ezan Bildirimleri'**
  String get channelSilentPrayers;

  /// No description provided for @tickerEzan.
  ///
  /// In tr, this message translates to:
  /// **'Ezan Vakti'**
  String get tickerEzan;

  /// No description provided for @stickyChannelName.
  ///
  /// In tr, this message translates to:
  /// **'Kalıcı Sayaç'**
  String get stickyChannelName;

  /// No description provided for @stickyChannelDesc.
  ///
  /// In tr, this message translates to:
  /// **'Vakte kalan süreyi gösterir'**
  String get stickyChannelDesc;

  /// No description provided for @timeLeftTo.
  ///
  /// In tr, this message translates to:
  /// **'Vaktin Çıkmasına: '**
  String get timeLeftTo;

  /// No description provided for @locationFallbackMessage.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı, varsayılan değer kullanılıyor.'**
  String get locationFallbackMessage;

  /// No description provided for @fetchingLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınıyor...'**
  String get fetchingLocation;

  /// No description provided for @directionNorth.
  ///
  /// In tr, this message translates to:
  /// **'K'**
  String get directionNorth;

  /// No description provided for @directionSouth.
  ///
  /// In tr, this message translates to:
  /// **'G'**
  String get directionSouth;

  /// No description provided for @directionEast.
  ///
  /// In tr, this message translates to:
  /// **'D'**
  String get directionEast;

  /// No description provided for @directionWest.
  ///
  /// In tr, this message translates to:
  /// **'B'**
  String get directionWest;

  /// No description provided for @calibrationInstruction.
  ///
  /// In tr, this message translates to:
  /// **'(Kalibrasyon için \'8\' çizin)'**
  String get calibrationInstruction;

  /// No description provided for @zakatDescription.
  ///
  /// In tr, this message translates to:
  /// **'Diyanet İşleri Başkanlığı fetvalarına ve güncel piyasa alış/satış kurlarına göre zekatınızı detaylı olarak hesaplayın.'**
  String get zakatDescription;

  /// No description provided for @cashAndCurrencyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Nakit ve Döviz Varlıkları'**
  String get cashAndCurrencyTitle;

  /// No description provided for @cashTurkishLira.
  ///
  /// In tr, this message translates to:
  /// **'Nakit Türk Lirası (TL)'**
  String get cashTurkishLira;

  /// No description provided for @goldAndSilverTitle.
  ///
  /// In tr, this message translates to:
  /// **'Altın ve Gümüş'**
  String get goldAndSilverTitle;

  /// No description provided for @silverGram.
  ///
  /// In tr, this message translates to:
  /// **'Gümüş (Gram)'**
  String get silverGram;

  /// No description provided for @unitPrice.
  ///
  /// In tr, this message translates to:
  /// **'Birim Fiyatı'**
  String get unitPrice;

  /// No description provided for @commercialGoodsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ticari Mallar'**
  String get commercialGoodsTitle;

  /// No description provided for @commercialEvalCurrency.
  ///
  /// In tr, this message translates to:
  /// **'Değerleme Para Birimi'**
  String get commercialEvalCurrency;

  /// No description provided for @commercialGoodsValue.
  ///
  /// In tr, this message translates to:
  /// **'Malın Değeri'**
  String get commercialGoodsValue;

  /// No description provided for @exchangeRateValue.
  ///
  /// In tr, this message translates to:
  /// **'Kur Değeri'**
  String get exchangeRateValue;

  /// No description provided for @receivablesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Alacaklar (Tahsil Edilebilecek)'**
  String get receivablesTitle;

  /// No description provided for @receivableType.
  ///
  /// In tr, this message translates to:
  /// **'Alacağın Cinsi (TL, Döviz, Altın)'**
  String get receivableType;

  /// No description provided for @amountOrCount.
  ///
  /// In tr, this message translates to:
  /// **'Miktar / Adet'**
  String get amountOrCount;

  /// No description provided for @otherAssetsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Diğer Varlıklar'**
  String get otherAssetsTitle;

  /// No description provided for @assetType.
  ///
  /// In tr, this message translates to:
  /// **'Varlık Türü'**
  String get assetType;

  /// No description provided for @currencyLabel.
  ///
  /// In tr, this message translates to:
  /// **'Para Birimi'**
  String get currencyLabel;

  /// No description provided for @valueOrAmount.
  ///
  /// In tr, this message translates to:
  /// **'Değeri / Miktarı'**
  String get valueOrAmount;

  /// No description provided for @agriProductsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Zirai Ürünler (Öşür)'**
  String get agriProductsTitle;

  /// No description provided for @agriDiyanetNote.
  ///
  /// In tr, this message translates to:
  /// **'Zirai ürünlerin zekat hesaplamasında nisap miktarı aranmadığı için, ürün değerinden hesaplanan öşür doğrudan toplam zekata eklenir.'**
  String get agriDiyanetNote;

  /// No description provided for @harvestedProductValue.
  ///
  /// In tr, this message translates to:
  /// **'Hasat Edilen Ürün Değeri (TL)'**
  String get harvestedProductValue;

  /// No description provided for @irrigationMethod.
  ///
  /// In tr, this message translates to:
  /// **'Sulama Yöntemi'**
  String get irrigationMethod;

  /// No description provided for @debtsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Borçlar (Düşülecek)'**
  String get debtsTitle;

  /// No description provided for @debtType.
  ///
  /// In tr, this message translates to:
  /// **'Borcun Cinsi (TL, Döviz, Altın)'**
  String get debtType;

  /// No description provided for @zakatAgriIncluded.
  ///
  /// In tr, this message translates to:
  /// **'Dahil Edilen Öşür (Zirai Ürün Zekatı)'**
  String get zakatAgriIncluded;

  /// No description provided for @assetCheck.
  ///
  /// In tr, this message translates to:
  /// **'Çek'**
  String get assetCheck;

  /// No description provided for @assetBond.
  ///
  /// In tr, this message translates to:
  /// **'Senet'**
  String get assetBond;

  /// No description provided for @assetSukuk.
  ///
  /// In tr, this message translates to:
  /// **'Sukuk'**
  String get assetSukuk;

  /// No description provided for @assetLeaseCert.
  ///
  /// In tr, this message translates to:
  /// **'Kira Sertifikası'**
  String get assetLeaseCert;

  /// No description provided for @assetStock.
  ///
  /// In tr, this message translates to:
  /// **'Hisse Senedi'**
  String get assetStock;

  /// No description provided for @agriSoil.
  ///
  /// In tr, this message translates to:
  /// **'Zirai Ürün (Topraklı Tarım)'**
  String get agriSoil;

  /// No description provided for @agriSoilless.
  ///
  /// In tr, this message translates to:
  /// **'Zirai Ürün (Topraksız Tarım)'**
  String get agriSoilless;

  /// No description provided for @agriRateNoCost.
  ///
  /// In tr, this message translates to:
  /// **'Masrafsız (Yağmur/Nehir) - %10'**
  String get agriRateNoCost;

  /// No description provided for @agriRateCostly.
  ///
  /// In tr, this message translates to:
  /// **'Masraflı (Motor/Taşıma) - %5'**
  String get agriRateCostly;

  /// No description provided for @toImsak.
  ///
  /// In tr, this message translates to:
  /// **'İmsaka'**
  String get toImsak;

  /// No description provided for @toGunes.
  ///
  /// In tr, this message translates to:
  /// **'Güneşe'**
  String get toGunes;

  /// No description provided for @toOgle.
  ///
  /// In tr, this message translates to:
  /// **'Öğleye'**
  String get toOgle;

  /// No description provided for @toIkindi.
  ///
  /// In tr, this message translates to:
  /// **'İkindiye'**
  String get toIkindi;

  /// No description provided for @toAksam.
  ///
  /// In tr, this message translates to:
  /// **'Akşama'**
  String get toAksam;

  /// No description provided for @toYatsi.
  ///
  /// In tr, this message translates to:
  /// **'Yatsıya'**
  String get toYatsi;

  /// No description provided for @lowAccuracyWarning.
  ///
  /// In tr, this message translates to:
  /// **'Pusula kalibrasyonu zayıf. Lütfen telefonunuzla havada \'8\' çizin.'**
  String get lowAccuracyWarning;

  /// No description provided for @qiblaDirection.
  ///
  /// In tr, this message translates to:
  /// **'Kıble Yönü'**
  String get qiblaDirection;

  /// No description provided for @zikirmatikTitle.
  ///
  /// In tr, this message translates to:
  /// **'Zikirmatik'**
  String get zikirmatikTitle;

  /// No description provided for @dhikrSubhanallah.
  ///
  /// In tr, this message translates to:
  /// **'Sübhanallah'**
  String get dhikrSubhanallah;

  /// No description provided for @dhikrElhamdulillah.
  ///
  /// In tr, this message translates to:
  /// **'Elhamdülillah'**
  String get dhikrElhamdulillah;

  /// No description provided for @dhikrAllahuEkber.
  ///
  /// In tr, this message translates to:
  /// **'Allahu Ekber'**
  String get dhikrAllahuEkber;

  /// No description provided for @dhikrKalima.
  ///
  /// In tr, this message translates to:
  /// **'Kelime-i Tevhid'**
  String get dhikrKalima;

  /// No description provided for @dhikrSalavat.
  ///
  /// In tr, this message translates to:
  /// **'Salavat'**
  String get dhikrSalavat;

  /// No description provided for @targetReached.
  ///
  /// In tr, this message translates to:
  /// **'Hedefe Ulaştınız!'**
  String get targetReached;

  /// No description provided for @resetCounter.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get resetCounter;

  /// No description provided for @targetCount.
  ///
  /// In tr, this message translates to:
  /// **'Hedef: {target}'**
  String targetCount(int target);

  /// No description provided for @setTarget.
  ///
  /// In tr, this message translates to:
  /// **'Hedef Belirle'**
  String get setTarget;

  /// No description provided for @dhikrOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer (Özel Zikir)'**
  String get dhikrOther;

  /// No description provided for @customDhikrTitle.
  ///
  /// In tr, this message translates to:
  /// **'Özel Zikir Ekle'**
  String get customDhikrTitle;

  /// No description provided for @customDhikrHint.
  ///
  /// In tr, this message translates to:
  /// **'Çekeceğiniz zikri yazın'**
  String get customDhikrHint;

  /// No description provided for @zikirSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get zikirSettings;

  /// No description provided for @vibration.
  ///
  /// In tr, this message translates to:
  /// **'Titreşim'**
  String get vibration;

  /// No description provided for @sound.
  ///
  /// In tr, this message translates to:
  /// **'Ses Efekti'**
  String get sound;

  /// No description provided for @keepAwake.
  ///
  /// In tr, this message translates to:
  /// **'Ekran Uyanık Kalsın'**
  String get keepAwake;

  /// No description provided for @appearance.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get appearance;

  /// No description provided for @themeModern.
  ///
  /// In tr, this message translates to:
  /// **'Modern Düğme'**
  String get themeModern;

  /// No description provided for @themeClassic.
  ///
  /// In tr, this message translates to:
  /// **'Klasik Tesbih'**
  String get themeClassic;

  /// No description provided for @introTitle1.
  ///
  /// In tr, this message translates to:
  /// **'Vaktinde\'ye Hoş Geldiniz'**
  String get introTitle1;

  /// No description provided for @introDesc1.
  ///
  /// In tr, this message translates to:
  /// **'Namaz vakitlerini, zikirlerinizi ve dini günleri en modern ve şık arayüzle kolayca takip edin.'**
  String get introDesc1;

  /// No description provided for @introTitle2.
  ///
  /// In tr, this message translates to:
  /// **'Akıllı Bildirimler'**
  String get introTitle2;

  /// No description provided for @introDesc2.
  ///
  /// In tr, this message translates to:
  /// **'Ezan vakitlerinde dilediğiniz bildirim sesiyle uyarı alın. İbadetlerinizi asla kaçırmayın.'**
  String get introDesc2;

  /// No description provided for @introTitle3.
  ///
  /// In tr, this message translates to:
  /// **'Gelişmiş Araçlar'**
  String get introTitle3;

  /// No description provided for @introDesc3.
  ///
  /// In tr, this message translates to:
  /// **'Animasyonlu Zikirmatik, Kaza Takibi, Esmaül Hüsna ve Zekat hesaplama ile maneviyatınızı güçlendirin.'**
  String get introDesc3;

  /// No description provided for @introSkip.
  ///
  /// In tr, this message translates to:
  /// **'Geç'**
  String get introSkip;

  /// No description provided for @introNext.
  ///
  /// In tr, this message translates to:
  /// **'İleri'**
  String get introNext;

  /// No description provided for @introStart.
  ///
  /// In tr, this message translates to:
  /// **'Hemen Başla'**
  String get introStart;

  /// No description provided for @dhikrListTitle.
  ///
  /// In tr, this message translates to:
  /// **'Zikir Listesi'**
  String get dhikrListTitle;

  /// No description provided for @addCustomDhikr.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Özel Zikir Ekle'**
  String get addCustomDhikr;

  /// No description provided for @customDhikrAdded.
  ///
  /// In tr, this message translates to:
  /// **'Zikir başarıyla eklendi.'**
  String get customDhikrAdded;

  /// No description provided for @customDhikrLimit.
  ///
  /// In tr, this message translates to:
  /// **'En fazla 20 adet özel zikir ekleyebilirsiniz!'**
  String get customDhikrLimit;

  /// No description provided for @deleteDhikr.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get deleteDhikr;

  /// No description provided for @statisticsTitle.
  ///
  /// In tr, this message translates to:
  /// **'İstatistikler'**
  String get statisticsTitle;

  /// No description provided for @monthly.
  ///
  /// In tr, this message translates to:
  /// **'Aylık'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık'**
  String get yearly;

  /// No description provided for @totalDhikr.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Çekilen Zikir'**
  String get totalDhikr;

  /// No description provided for @today.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get today;

  /// No description provided for @statsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz zikir verisi yok.'**
  String get statsEmpty;

  /// No description provided for @dhikrEstagfirullah.
  ///
  /// In tr, this message translates to:
  /// **'Estağfirullah'**
  String get dhikrEstagfirullah;

  /// No description provided for @dhikrLaHavle.
  ///
  /// In tr, this message translates to:
  /// **'La Havle Vela Kuvvete İlla Billah'**
  String get dhikrLaHavle;

  /// No description provided for @dhikrHasbunallah.
  ///
  /// In tr, this message translates to:
  /// **'Hasbünallah'**
  String get dhikrHasbunallah;

  /// No description provided for @dhikrSubhanallahi.
  ///
  /// In tr, this message translates to:
  /// **'Sübhanallahi ve Bihamdihi'**
  String get dhikrSubhanallahi;

  /// No description provided for @dhikrYunus.
  ///
  /// In tr, this message translates to:
  /// **'Hz. Yunus\'un Duası'**
  String get dhikrYunus;

  /// No description provided for @dhikrYaAllah.
  ///
  /// In tr, this message translates to:
  /// **'Ya Allah (C.C.)'**
  String get dhikrYaAllah;

  /// No description provided for @dhikrYaRahman.
  ///
  /// In tr, this message translates to:
  /// **'Ya Rahman (C.C.)'**
  String get dhikrYaRahman;

  /// No description provided for @dhikrYaRahim.
  ///
  /// In tr, this message translates to:
  /// **'Ya Rahim (C.C.)'**
  String get dhikrYaRahim;

  /// No description provided for @dhikrYaSafi.
  ///
  /// In tr, this message translates to:
  /// **'Ya Şafi (C.C.)'**
  String get dhikrYaSafi;

  /// No description provided for @dhikrYaRezzak.
  ///
  /// In tr, this message translates to:
  /// **'Ya Rezzak (C.C.)'**
  String get dhikrYaRezzak;

  /// No description provided for @dhikrYaFettah.
  ///
  /// In tr, this message translates to:
  /// **'Ya Fettah (C.C.)'**
  String get dhikrYaFettah;

  /// No description provided for @mainDhikrs.
  ///
  /// In tr, this message translates to:
  /// **'Temel Zikirler'**
  String get mainDhikrs;

  /// No description provided for @esmaulHusnaTab.
  ///
  /// In tr, this message translates to:
  /// **'Esmaül Hüsna'**
  String get esmaulHusnaTab;

  /// No description provided for @qiblaCalibration.
  ///
  /// In tr, this message translates to:
  /// **'Pusulanın doğru çalışması için telefonunuzla havada \'8\' çizin.'**
  String get qiblaCalibration;

  /// No description provided for @hicriYilbasi.
  ///
  /// In tr, this message translates to:
  /// **'Hicri Yılbaşı'**
  String get hicriYilbasi;

  /// No description provided for @asureGunu.
  ///
  /// In tr, this message translates to:
  /// **'Aşure Günü'**
  String get asureGunu;

  /// No description provided for @mevlidKandili.
  ///
  /// In tr, this message translates to:
  /// **'Mevlid Kandili'**
  String get mevlidKandili;

  /// No description provided for @miracKandili.
  ///
  /// In tr, this message translates to:
  /// **'Miraç Kandili'**
  String get miracKandili;

  /// No description provided for @beratKandili.
  ///
  /// In tr, this message translates to:
  /// **'Berat Kandili'**
  String get beratKandili;

  /// No description provided for @ramazanBaslangici.
  ///
  /// In tr, this message translates to:
  /// **'Ramazan Başlangıcı'**
  String get ramazanBaslangici;

  /// No description provided for @kadirGecesi.
  ///
  /// In tr, this message translates to:
  /// **'Kadir Gecesi'**
  String get kadirGecesi;

  /// No description provided for @ramazanBayrami.
  ///
  /// In tr, this message translates to:
  /// **'Ramazan Bayramı'**
  String get ramazanBayrami;

  /// No description provided for @kurbanBayrami.
  ///
  /// In tr, this message translates to:
  /// **'Kurban Bayramı'**
  String get kurbanBayrami;

  /// No description provided for @regaipKandili.
  ///
  /// In tr, this message translates to:
  /// **'Regaib Kandili'**
  String get regaipKandili;

  /// No description provided for @tabTimes.
  ///
  /// In tr, this message translates to:
  /// **'Vakitler'**
  String get tabTimes;

  /// No description provided for @tabAlarms.
  ///
  /// In tr, this message translates to:
  /// **'Alarmlar'**
  String get tabAlarms;

  /// No description provided for @locationFoundNoName.
  ///
  /// In tr, this message translates to:
  /// **'Konum bulundu ancak yer adı alınamadı.'**
  String get locationFoundNoName;

  /// No description provided for @dailyAyahTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günün Ayeti'**
  String get dailyAyahTitle;

  /// No description provided for @remainingTime.
  ///
  /// In tr, this message translates to:
  /// **'Kalan'**
  String get remainingTime;

  /// No description provided for @onboardingWelcome.
  ///
  /// In tr, this message translates to:
  /// **'Hoş Geldiniz / Welcome'**
  String get onboardingWelcome;

  /// No description provided for @onboardingSelectLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen kullanmak istediğiniz dili seçin.\nPlease select your preferred language.'**
  String get onboardingSelectLanguage;

  /// No description provided for @turnRight.
  ///
  /// In tr, this message translates to:
  /// **'Sağa dönün ➔'**
  String get turnRight;

  /// No description provided for @turnSlightRight.
  ///
  /// In tr, this message translates to:
  /// **'Biraz sağa dönün ➔'**
  String get turnSlightRight;

  /// No description provided for @turnLeft.
  ///
  /// In tr, this message translates to:
  /// **'⬅ Sola dönün'**
  String get turnLeft;

  /// No description provided for @turnSlightLeft.
  ///
  /// In tr, this message translates to:
  /// **'⬅ Biraz sola dönün'**
  String get turnSlightLeft;

  /// No description provided for @calibrationRequired.
  ///
  /// In tr, this message translates to:
  /// **'Kalibrasyon Gerekli'**
  String get calibrationRequired;

  /// No description provided for @qiblaAccuracyNote.
  ///
  /// In tr, this message translates to:
  /// **'Pusula yaklaşık yön gösterir; metal, mıknatıs ve elektronik cihazlar yönü saptırabilir.'**
  String get qiblaAccuracyNote;

  /// No description provided for @qiblaTipsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Doğru sonuç için'**
  String get qiblaTipsTitle;

  /// No description provided for @qiblaTipFlat.
  ///
  /// In tr, this message translates to:
  /// **'Telefonu yere paralel tutun.'**
  String get qiblaTipFlat;

  /// No description provided for @qiblaTipCalibrate.
  ///
  /// In tr, this message translates to:
  /// **'Telefonunuzla havada \'8\' çizerek kalibre edin.'**
  String get qiblaTipCalibrate;

  /// No description provided for @qiblaTipMagneticCase.
  ///
  /// In tr, this message translates to:
  /// **'Mıknatıslı kılıf kullanıyorsanız çıkarın.'**
  String get qiblaTipMagneticCase;

  /// No description provided for @qiblaTipMetal.
  ///
  /// In tr, this message translates to:
  /// **'Metal eşyalardan ve elektronik cihazlardan uzak durun.'**
  String get qiblaTipMetal;

  /// No description provided for @qiblaTipMosque.
  ///
  /// In tr, this message translates to:
  /// **'Mümkünse bir caminin kıble yönüyle karşılaştırın.'**
  String get qiblaTipMosque;

  /// No description provided for @qiblaAngleTrueNorth.
  ///
  /// In tr, this message translates to:
  /// **'Kıble açısı: {angle}° (coğrafi kuzeyden)'**
  String qiblaAngleTrueNorth(String angle);

  /// No description provided for @qiblaDeclination.
  ///
  /// In tr, this message translates to:
  /// **'Manyetik sapma: {deg}° (otomatik düzeltildi)'**
  String qiblaDeclination(String deg);

  /// No description provided for @qiblaInterferenceWarning.
  ///
  /// In tr, this message translates to:
  /// **'Manyetik parazit algılandı: telefonu metal eşyalardan, mıknatıslı kılıftan ve elektronik cihazlardan uzaklaştırın.'**
  String get qiblaInterferenceWarning;

  /// No description provided for @gold22kGram.
  ///
  /// In tr, this message translates to:
  /// **'22 Ayar Gram Altın'**
  String get gold22kGram;

  /// No description provided for @goldAtaToptan.
  ///
  /// In tr, this message translates to:
  /// **'Ata Toptan'**
  String get goldAtaToptan;

  /// No description provided for @goldAtaCumhuriyet.
  ///
  /// In tr, this message translates to:
  /// **'Ata Cumhuriyet'**
  String get goldAtaCumhuriyet;

  /// No description provided for @gold22kBracelet.
  ///
  /// In tr, this message translates to:
  /// **'22 Ayar Bilezik'**
  String get gold22kBracelet;

  /// No description provided for @gold18k.
  ///
  /// In tr, this message translates to:
  /// **'18 Ayar Altın'**
  String get gold18k;

  /// No description provided for @gold14k.
  ///
  /// In tr, this message translates to:
  /// **'14 Ayar Altın'**
  String get gold14k;

  /// No description provided for @goldHalf.
  ///
  /// In tr, this message translates to:
  /// **'Yarım Altın'**
  String get goldHalf;

  /// No description provided for @goldGremse.
  ///
  /// In tr, this message translates to:
  /// **'Gremse Altın'**
  String get goldGremse;

  /// No description provided for @goldAtaBesli.
  ///
  /// In tr, this message translates to:
  /// **'Ata Beşli'**
  String get goldAtaBesli;

  /// No description provided for @goldResat.
  ///
  /// In tr, this message translates to:
  /// **'Reşat Altın'**
  String get goldResat;

  /// No description provided for @goldHamit.
  ///
  /// In tr, this message translates to:
  /// **'Hamit Altın'**
  String get goldHamit;

  /// No description provided for @currencyChf.
  ///
  /// In tr, this message translates to:
  /// **'İsviçre Frangı'**
  String get currencyChf;

  /// No description provided for @currencyJpy.
  ///
  /// In tr, this message translates to:
  /// **'Japon Yeni'**
  String get currencyJpy;

  /// No description provided for @currencySar.
  ///
  /// In tr, this message translates to:
  /// **'Suudi Arabistan Riyali'**
  String get currencySar;

  /// No description provided for @currencyAud.
  ///
  /// In tr, this message translates to:
  /// **'Avustralya Doları'**
  String get currencyAud;

  /// No description provided for @currencyCad.
  ///
  /// In tr, this message translates to:
  /// **'Kanada Doları'**
  String get currencyCad;

  /// No description provided for @currencyRub.
  ///
  /// In tr, this message translates to:
  /// **'Rus Rublesi'**
  String get currencyRub;

  /// No description provided for @currencyAzn.
  ///
  /// In tr, this message translates to:
  /// **'Azerbaycan Manatı'**
  String get currencyAzn;

  /// No description provided for @currencyCny.
  ///
  /// In tr, this message translates to:
  /// **'Çin Yuanı'**
  String get currencyCny;

  /// No description provided for @currencyRon.
  ///
  /// In tr, this message translates to:
  /// **'Romanya Leyi'**
  String get currencyRon;

  /// No description provided for @currencyAed.
  ///
  /// In tr, this message translates to:
  /// **'BAE Dirhemi'**
  String get currencyAed;

  /// No description provided for @currencyBgn.
  ///
  /// In tr, this message translates to:
  /// **'Bulgar Levası'**
  String get currencyBgn;

  /// No description provided for @currencyKwd.
  ///
  /// In tr, this message translates to:
  /// **'Kuveyt Dinarı'**
  String get currencyKwd;

  /// No description provided for @currencyTry.
  ///
  /// In tr, this message translates to:
  /// **'Türk Lirası'**
  String get currencyTry;

  /// No description provided for @holdToEdit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenlemek için basılı tutun'**
  String get holdToEdit;

  /// No description provided for @editCounterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sayacı Düzenle'**
  String get editCounterTitle;

  /// No description provided for @editCounterHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: 2000'**
  String get editCounterHint;

  /// No description provided for @editTargetHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: 99'**
  String get editTargetHint;

  /// No description provided for @resetCounterConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Sayacı sıfırlamak istediğinize emin misiniz?'**
  String get resetCounterConfirm;

  /// No description provided for @dhikrTarget.
  ///
  /// In tr, this message translates to:
  /// **'Hedef:'**
  String get dhikrTarget;

  /// No description provided for @imsakiyeTitle.
  ///
  /// In tr, this message translates to:
  /// **'İmsakiye'**
  String get imsakiyeTitle;

  /// No description provided for @toolsGroupPrayer.
  ///
  /// In tr, this message translates to:
  /// **'Namaz'**
  String get toolsGroupPrayer;

  /// No description provided for @toolsGroupInfo.
  ///
  /// In tr, this message translates to:
  /// **'Bilgi'**
  String get toolsGroupInfo;

  /// No description provided for @toolsGroupCalc.
  ///
  /// In tr, this message translates to:
  /// **'Hesaplama'**
  String get toolsGroupCalc;

  /// No description provided for @toolImsakiyeDesc.
  ///
  /// In tr, this message translates to:
  /// **'Aylık ve Ramazan vakitleri'**
  String get toolImsakiyeDesc;

  /// No description provided for @toolTrackerDesc.
  ///
  /// In tr, this message translates to:
  /// **'Kıldığınız vakitleri işaretleyin'**
  String get toolTrackerDesc;

  /// No description provided for @toolKazaDesc.
  ///
  /// In tr, this message translates to:
  /// **'Kaza namazı ve oruç sayacı'**
  String get toolKazaDesc;

  /// No description provided for @toolReligiousDaysDesc.
  ///
  /// In tr, this message translates to:
  /// **'Kandiller ve bayramlar'**
  String get toolReligiousDaysDesc;

  /// No description provided for @nearbyMosquesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yakındaki Camiler'**
  String get nearbyMosquesTitle;

  /// No description provided for @toolNearbyMosquesDesc.
  ///
  /// In tr, this message translates to:
  /// **'Size en yakın camileri haritada bulun'**
  String get toolNearbyMosquesDesc;

  /// No description provided for @nearbyMosquesQuery.
  ///
  /// In tr, this message translates to:
  /// **'cami'**
  String get nearbyMosquesQuery;

  /// No description provided for @nearbyMosquesError.
  ///
  /// In tr, this message translates to:
  /// **'Harita açılamadı.'**
  String get nearbyMosquesError;

  /// No description provided for @toolEsmaDesc.
  ///
  /// In tr, this message translates to:
  /// **'Allah\'ın 99 ismi ve anlamları'**
  String get toolEsmaDesc;

  /// No description provided for @toolFridayDesc.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşmaya hazır mesajlar'**
  String get toolFridayDesc;

  /// No description provided for @toolZakatDesc.
  ///
  /// In tr, this message translates to:
  /// **'Zekat ve öşür hesabı'**
  String get toolZakatDesc;

  /// No description provided for @toolSettingsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Konum, bildirimler, görünüm'**
  String get toolSettingsDesc;

  /// No description provided for @daysLeft.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =0{Bugün} =1{Yarın} other{{count} gün kaldı}}'**
  String daysLeft(int count);

  /// No description provided for @previousYear.
  ///
  /// In tr, this message translates to:
  /// **'Önceki yıl'**
  String get previousYear;

  /// No description provided for @nextYear.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki yıl'**
  String get nextYear;

  /// No description provided for @previousItem.
  ///
  /// In tr, this message translates to:
  /// **'Önceki'**
  String get previousItem;

  /// No description provided for @nextItem.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki'**
  String get nextItem;

  /// No description provided for @missedChangeConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{name} kaza sayısı {from} yerine {to} olacak. Kaydedilsin mi?'**
  String missedChangeConfirm(String name, int from, int to);

  /// No description provided for @shareFailed.
  ///
  /// In tr, this message translates to:
  /// **'İşlem yapılamadı. Lütfen tekrar deneyin.'**
  String get shareFailed;

  /// No description provided for @zakatCurrencyNote.
  ///
  /// In tr, this message translates to:
  /// **'Tüm tutarlar Türk lirası (₺) cinsindendir.'**
  String get zakatCurrencyNote;

  /// No description provided for @zakatCashTry.
  ///
  /// In tr, this message translates to:
  /// **'Nakit (₺)'**
  String get zakatCashTry;

  /// No description provided for @zakatRatesUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Güncel altın fiyatı ve kurlar alınamadı. Lütfen fiyatları elle girin.'**
  String get zakatRatesUnavailable;

  /// No description provided for @zakatGoldGramPrice.
  ///
  /// In tr, this message translates to:
  /// **'24 Ayar Gram Altın Fiyatı (₺)'**
  String get zakatGoldGramPrice;

  /// No description provided for @zakatGoldGramPriceHelp.
  ///
  /// In tr, this message translates to:
  /// **'Nisap sınırı bu fiyatla hesaplanır.'**
  String get zakatGoldGramPriceHelp;

  /// No description provided for @zakatNisabUnknown.
  ///
  /// In tr, this message translates to:
  /// **'Gram altın fiyatı olmadan nisap sınırı hesaplanamaz. Sonucun doğru olması için altın fiyatını girin.'**
  String get zakatNisabUnknown;

  /// No description provided for @imsakiyeRamadan.
  ///
  /// In tr, this message translates to:
  /// **'Ramazan'**
  String get imsakiyeRamadan;

  /// No description provided for @imsakiyeRamadanTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ramazan {year} İmsakiyesi'**
  String imsakiyeRamadanTitle(int year);

  /// No description provided for @imsakiyeDay.
  ///
  /// In tr, this message translates to:
  /// **'Gün'**
  String get imsakiyeDay;

  /// No description provided for @imsakiyeSunriseShort.
  ///
  /// In tr, this message translates to:
  /// **'Güneş'**
  String get imsakiyeSunriseShort;

  /// No description provided for @imsakiyePrevMonth.
  ///
  /// In tr, this message translates to:
  /// **'Önceki ay'**
  String get imsakiyePrevMonth;

  /// No description provided for @imsakiyeNextMonth.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki ay'**
  String get imsakiyeNextMonth;

  /// No description provided for @imsakiyeNoLocation.
  ///
  /// In tr, this message translates to:
  /// **'İmsakiyeyi görmek için önce konumunuzu seçin. Konumu ana ekrandan veya Ayarlar\'dan belirleyebilirsiniz.'**
  String get imsakiyeNoLocation;

  /// No description provided for @imsakiyeShareError.
  ///
  /// In tr, this message translates to:
  /// **'İmsakiye paylaşılamadı. Lütfen tekrar deneyin.'**
  String get imsakiyeShareError;

  /// No description provided for @ramadanSahurLeft.
  ///
  /// In tr, this message translates to:
  /// **'Sahura Kalan'**
  String get ramadanSahurLeft;

  /// No description provided for @ramadanIftarLeft.
  ///
  /// In tr, this message translates to:
  /// **'İftara Kalan'**
  String get ramadanIftarLeft;

  /// No description provided for @ramadanDayLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ramazan\'ın {day}. günü'**
  String ramadanDayLabel(int day);
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
