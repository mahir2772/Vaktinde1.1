// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Vaktinde';

  @override
  String get navZikir => 'Zikir';

  @override
  String get adPrivacySettings => 'Reklam Gizlilik Ayarları';

  @override
  String get adPrivacySettingsSub =>
      'Kişiselleştirilmiş reklam iznini değiştirin';

  @override
  String get showcaseLanguage => 'Uygulama dilini buradan değiştirebilirsiniz.';

  @override
  String get showcaseStory =>
      'Günün ayetini ve hadisini buradan okuyabilirsiniz.';

  @override
  String get showcaseAlarms =>
      'Her vakit için ezan ve hatırlatma alarmlarını buradan ayarlayabilirsiniz.';

  @override
  String get showcaseQibla => 'Kıble yönünü pusula ile bulabilirsiniz.';

  @override
  String get showcaseZikir => 'Zikirlerinizi buradan takip edebilirsiniz.';

  @override
  String get refreshLocation => 'Konumu yenile';

  @override
  String get navTools => 'Araçlar';

  @override
  String get hadithNotFound => 'Hadis metni bulunamadı.';

  @override
  String get timesLoadError => 'Vakitler yüklenemedi. Lütfen tekrar deneyin.';

  @override
  String get sunriseNotPrayer => 'Güneşin doğuşu, namaz vakti değildir';

  @override
  String get currentPrayer => 'Şu anki vakit';

  @override
  String get textCopied => 'Metin kopyalandı';

  @override
  String get updateDownloaded => 'Yeni sürüm indirildi.';

  @override
  String get restartAction => 'Yeniden başlat';

  @override
  String get qiblaTurnRight => 'Sağa dönün';

  @override
  String get qiblaTurnSlightRight => 'Biraz sağa dönün';

  @override
  String get qiblaTurnLeft => 'Sola dönün';

  @override
  String get qiblaTurnSlightLeft => 'Biraz sola dönün';

  @override
  String phoneHeading(String deg) {
    return 'Telefon yönü: $deg°';
  }

  @override
  String get usingSavedLocation => 'Kayıtlı konum kullanılıyor.';

  @override
  String exampleHint(int n) {
    return 'Örn: $n';
  }

  @override
  String get noCustomDhikr => 'Henüz özel zikir eklemediniz.';

  @override
  String get messagesShuffled => 'Mesajlar karıştırıldı';

  @override
  String get shuffle => 'Karıştır';

  @override
  String get copy => 'Kopyala';

  @override
  String get messageCopied => 'Mesaj kopyalandı';

  @override
  String versionLabel(String v) {
    return 'Sürüm $v';
  }

  @override
  String get supportMailSubject => 'Vaktinde - Destek';

  @override
  String get madeBy => 'mmdigital tarafından ❤️ ile yapıldı';

  @override
  String get permissionPrimingTitle => 'Ezan vakitlerini kaçırmayın';

  @override
  String get permissionPrimingBody =>
      'Ezan bildirimleri için bildirim iznine, vakitleri bulunduğunuz yere göre hesaplamak için konum iznine ihtiyacımız var.';

  @override
  String get continueAction => 'Devam';

  @override
  String get nextPrayer => 'Sıradaki Vakit';

  @override
  String get hadithTitle => 'Günün Hadisi';

  @override
  String get share => 'Paylaş';

  @override
  String get close => 'Kapat';

  @override
  String get loading => 'Vakitler Hesaplanıyor...';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get noData => 'Veri yok.';

  @override
  String get imsak => 'İmsak';

  @override
  String get gunes => 'Güneş';

  @override
  String get ogle => 'Öğle';

  @override
  String get ikindi => 'İkindi';

  @override
  String get aksam => 'Akşam';

  @override
  String get yatsi => 'Yatsı';

  @override
  String get exactAlarm => 'Tam Vaktinde Bildir';

  @override
  String get reminderTitleAt => 'Vakit Hatırlatması';

  @override
  String notifBodyUpcomingAt(String vakit, String time) {
    return '$vakit vakti: $time';
  }

  @override
  String get endReminderTitleAt => 'Vakit Çıkışı';

  @override
  String endReminderNotifBodyAt(String vakit, String time) {
    return '$vakit vaktinin çıkışı: $time';
  }

  @override
  String ramadanImsakBodyAt(String time) {
    return 'Sahur vakti $time itibarıyla sona erdi. Hayırlı oruçlar!';
  }

  @override
  String get alarmHealthExactOff =>
      'Alarm izni kapalı: ezan ve hatırlatmalar yaklaşık bir saate kadar gecikebilir (imsak ve sahur dahil).';

  @override
  String get healthTitle => 'Bildirim Kontrolü';

  @override
  String get healthSub => 'Ezan gelmiyorsa ayarları adım adım kontrol edin';

  @override
  String get healthSectionStatus => 'Durum';

  @override
  String get healthEzansTitle => 'Ezan alarmları';

  @override
  String healthEzansOn(String names) {
    return 'Açık: $names';
  }

  @override
  String get healthEzansNone => 'Hiçbir vakit için ezan açık değil.';

  @override
  String get healthNextTitle => 'Sıradaki ezan';

  @override
  String get healthNextNone => 'Kurulu ezan bulunamadı.';

  @override
  String get healthReschedule => 'Yeniden kur';

  @override
  String get healthNotificationsTitle => 'Bildirimler';

  @override
  String get healthNotificationsOk => 'Açık.';

  @override
  String get healthOpenSettings => 'Ayarları aç';

  @override
  String get healthExactTitle => 'Alarmlar ve hatırlatıcılar';

  @override
  String get healthExactOk => 'İzin verildi: ezan tam vaktinde çalar.';

  @override
  String get healthVolumeTitle => 'Ses';

  @override
  String get healthVolumeOk => 'Bildirim sesi açık.';

  @override
  String get healthVolumeAlarmOk => 'Alarm sesi açık.';

  @override
  String get healthVolumeSilent =>
      'Telefon sessiz ya da titreşim modunda: ezan sesi duyulmaz.';

  @override
  String get healthVolumeNotificationMuted =>
      'Bildirim sesi kapalı: ezan sesi duyulmaz.';

  @override
  String get healthVolumeAlarmMuted => 'Alarm sesi kapalı: ezan sesi duyulmaz.';

  @override
  String healthAlarmStreamTip(String setting) {
    return '“$setting” açıkken ezan alarm sesiyle çalar.';
  }

  @override
  String get healthDndTitle => 'Rahatsız Etmeyin';

  @override
  String get healthDndOff => 'Kapalı.';

  @override
  String get healthDndOn => 'Açık: ezan sesi duyulmayabilir.';

  @override
  String healthDndAlarm(String setting) {
    return 'Açık, ancak “$setting” sayesinde ezan alarm sesiyle çalar.';
  }

  @override
  String get healthBatteryTitle => 'Pil kullanımı';

  @override
  String get healthBatteryOk => 'Pil optimizasyonu Vaktinde için kapalı.';

  @override
  String get healthBatteryOptimized =>
      'Pil optimizasyonu açık: telefon Vaktinde\'yi arka planda durdurabilir. Uygulama ayarlarında Pil bölümünden “Kısıtlanmamış” seçeneğini işaretleyin (bazı telefonlarda “Sınırsız” ya da “Kısıtlama yok”).';

  @override
  String get healthBackgroundTitle => 'Arka planda çalışma';

  @override
  String healthBackgroundToday(String time) {
    return 'Son çalışma: bugün $time';
  }

  @override
  String healthBackgroundYesterday(String time) {
    return 'Son çalışma: dün $time';
  }

  @override
  String get healthBackgroundStale =>
      'Vaktinde son 48 saatte arka planda hiç çalışmadı: telefon uygulamayı durduruyor olabilir.';

  @override
  String get healthShowSteps => 'Adımları göster';

  @override
  String healthGuideTitle(String brand) {
    return '$brand için ayarlar';
  }

  @override
  String get healthGuideTitleGeneric => 'Telefonunuz için ayarlar';

  @override
  String get healthGuideStale =>
      'Arka planda çalışma durmuş görünüyor. Ezanın gecikmemesi için şu ayarları yapın:';

  @override
  String get healthGuideMore =>
      'Telefon modelinize göre ayrıntılı anlatım (İngilizce)';

  @override
  String get healthTestTitle => 'Test ezanı';

  @override
  String get healthTestInfo =>
      'Gerçek ezanla aynı ses ve ayarlarla 1 dakika sonra bir test bildirimi gelir.';

  @override
  String get healthTestButton => '1 dk sonra test ezanı';

  @override
  String get healthTestScheduled =>
      'Test ezanı 1 dakika sonra çalacak. Uygulamayı kapatabilirsiniz.';

  @override
  String get healthTestNotifBody =>
      'Bu bildirim geldiyse ezan bildirimleri çalışıyor.';

  @override
  String get healthStepXiaomiAutostart =>
      'Uygulama ayarlarında “Otomatik başlatma” seçeneğini açın.';

  @override
  String get healthStepXiaomiBattery =>
      'Aynı ekranda Pil tasarrufu (ya da Pil) bölümünden “Kısıtlama yok” seçeneğini işaretleyin.';

  @override
  String get healthStepHuaweiLaunch =>
      'Ayarlar\'da “Uygulama başlatma” bölümünü açın (Pil ya da Uygulamalar altında). Vaktinde için otomatik yönetimi kapatın ve açılan penceredeki tüm seçenekleri açık bırakın.';

  @override
  String get healthStepOppoBackground =>
      'Uygulama ayarları > Pil kullanımı bölümünde arka planda çalışmaya ve otomatik başlatmaya izin verin.';

  @override
  String get healthStepVivoBackground =>
      'Ayarlar > Pil bölümünde Vaktinde\'nin arka planda yüksek güç tüketmesine izin verin.';

  @override
  String healthStepAutostartIn(String app) {
    return 'Ayarlar\'da ya da $app uygulamasında Vaktinde için otomatik başlatmayı açın.';
  }

  @override
  String get healthStepAppBattery =>
      'Uygulama ayarları > Pil bölümünde “Kısıtlanmamış” seçeneğini işaretleyin.';

  @override
  String get healthStepSamsungSleeping =>
      'Ayarlar > Pil > Arka plan kullanım sınırları bölümünde Vaktinde\'yi hiç uyku moduna alınmayan uygulamalara ekleyin.';

  @override
  String get healthStepLockRecents =>
      'Son uygulamalar ekranında Vaktinde\'yi kilitleyin (telefonunuzda bu seçenek varsa).';

  @override
  String get healthDetails => 'Ayrıntılar';

  @override
  String get alarmHealthExactAction => 'İzin ver';

  @override
  String get alarmHealthNotificationsOff => 'Bildirimler kapalı, ezan çalmaz.';

  @override
  String get alarmHealthNotificationsAction => 'Aç';

  @override
  String get ezanAlarmStreamTitle => 'Sessiz modda da çal';

  @override
  String get ezanAlarmStreamSub =>
      'Ezan, telefon sessizdeyken de alarm ses seviyesinde çalar.';

  @override
  String channelAlarmSound(String soundName) {
    return 'Ses: $soundName (sessizde de çalar)';
  }

  @override
  String get exactAlarmSub => 'Bildirim gönderir.';

  @override
  String get silentNotif => 'Sadece Yazılı Bildirim';

  @override
  String get silentNotifSub => 'Ezan/ses çalmaz, sadece uyarı gelir.';

  @override
  String warningAlarm(String minute) {
    return '$minute dk Önce Uyar';
  }

  @override
  String get warningAlarmSub => 'Kısa bildirim sesi.';

  @override
  String get settings => 'Ayarlar';

  @override
  String get changeLanguage => 'Dil Değiştir';

  @override
  String get waitingLocation => 'Konum Bekleniyor...';

  @override
  String get noInternet =>
      'İnternet bağlantısı yok ve kayıtlı veri bulunamadı.';

  @override
  String get gpsOff => 'GPS kapalı. Lütfen konumu açın.';

  @override
  String get permissionDenied => 'Konum izni reddedildi.';

  @override
  String get locationError => 'Konum alınamadı.';

  @override
  String get internetNeeded => 'İnternet bağlantısı gerekiyor.';

  @override
  String get soundEzan => 'Ezan';

  @override
  String get soundBeep => 'Kısa Bildirim';

  @override
  String get notifTitleTime => 'Ezan Vakti';

  @override
  String notifBodyTime(String vakit) {
    return '$vakit vakti girdi.';
  }

  @override
  String get notifTitleUpcoming => 'Vakit Yaklaşıyor';

  @override
  String notifBodyUpcoming(String vakit, int minute) {
    return '$vakit vaktine $minute dakika kaldı.';
  }

  @override
  String get navPrayer => 'Ana Sayfa';

  @override
  String get navQibla => 'Kıble';

  @override
  String get menuTitle => 'Ayarlar';

  @override
  String get sectionLocation => 'KONUM & VAKİTLER';

  @override
  String get changeLocation => 'Konum Değiştir';

  @override
  String get citySelect => 'İl Seçiniz';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'İptal';

  @override
  String get timeAdjustTitle => 'Vakit İnce Ayarı';

  @override
  String get tapToCount => 'Saymak için dokunun';

  @override
  String get timeAdjustSub => 'Vakitleri dakika dakika düzeltin';

  @override
  String get timeAdjustInfo =>
      'Vakitler konumunuza göre Diyanet yöntemiyle hesaplanır. Bölgenizdeki caminin vakitleriyle küçük farklar varsa her vakti dakika olarak ileri veya geri alabilirsiniz. Ayar ana ekrana, widget\'lara ve ezan bildirimlerine uygulanır.';

  @override
  String get timeAdjustReset => 'Sıfırla';

  @override
  String timeAdjustMinutes(String value) {
    return '$value dk';
  }

  @override
  String get timeAdjustSaved => 'Vakitler güncellendi';

  @override
  String get trackerTitle => 'Namaz Takibi';

  @override
  String get trackerToday => 'Bugün';

  @override
  String get trackerYesterday => 'Dün';

  @override
  String get trackerPrayedAction => 'Kıldım';

  @override
  String get trackerLast7Days => 'Son 7 Gün';

  @override
  String get trackerCompletion => '30 günlük oran';

  @override
  String get trackerStreak => 'Seri';

  @override
  String trackerStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün',
    );
    return '$_temp0';
  }

  @override
  String get trackerNotYet => 'Bu vakit henüz girmedi.';

  @override
  String get trackerKazaButton => 'Kılınmayanları kazaya ekle';

  @override
  String get trackerKazaInfo =>
      'Son 30 gün içinde (takibe başladığınız günden itibaren) işaretlenmemiş vakitler kaza sayaçlarına eklenir. Her vakit yalnızca bir kez eklenir. Kazaya eklenen bir vakti kıldıysanız üzerine dokunun; kılındı olarak işaretlenir ve kaza sayısından düşülür.';

  @override
  String trackerKazaConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'İşaretlenmemiş $count vakit kaza sayaçlarına eklenecek. Devam edilsin mi?',
    );
    return '$_temp0';
  }

  @override
  String get trackerKazaAdd => 'Ekle';

  @override
  String trackerKazaDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vakit kazaya eklendi.',
    );
    return '$_temp0';
  }

  @override
  String get trackerKazaNone => 'Kazaya eklenecek vakit yok.';

  @override
  String get trackerKazaRemoveTitle => 'Kazadan çıkarılsın mı?';

  @override
  String trackerKazaRemoveConfirm(String name, int from, int to) {
    return 'Bu vakit kılındı olarak işaretlenecek ve $name kaza sayısı $from yerine $to olacak.';
  }

  @override
  String get addWidgetTitle => 'Ana Ekrana Widget Ekle';

  @override
  String get addWidgetSub => 'Vakitleri uygulamayı açmadan görün';

  @override
  String get addWidgetHint =>
      'Birini seçin; ana ekranınız eklemeden önce onay isteyecek.';

  @override
  String get widgetLargeName => 'Günün Vakitleri';

  @override
  String get widgetLargeDesc =>
      'Büyük boy: konum, hicri tarih, günün vakitleri ve kalan süre';

  @override
  String get widgetWideName => 'Sıradaki Vakit';

  @override
  String get widgetWideDesc =>
      'Yatay şerit: konum, hicri tarih ve sıradaki vakte kalan süre';

  @override
  String get widgetSmallName => 'Vakit Sayacı';

  @override
  String get widgetSmallDesc => 'Küçük kare: sıradaki vakte kalan süre';

  @override
  String get trackerLegendPrayed => 'Kılındı';

  @override
  String get trackerLegendKaza => 'Kazaya eklendi';

  @override
  String kerahatActive(String range) {
    return 'Şu an kerahat vakti: $range';
  }

  @override
  String kerahatUpcoming(String range) {
    return 'Kerahat vakti yaklaşıyor: $range';
  }

  @override
  String get endReminderTitle => 'Vakit Çıkmadan Hatırlat';

  @override
  String get dailyContentNotifTitle => 'Günün Ayeti ve Hadisi Bildirimleri';

  @override
  String get dailyContentNotifSub =>
      'Her gün sabah bir ayet, akşam bir hadis gönderir.';

  @override
  String get religiousDaysNotifTitle => 'Dini Gün ve Kandil Bildirimleri';

  @override
  String get religiousDaysNotifSub =>
      'Kandil, bayram ve diğer dini günlerde sabah bildirim gönderir.';

  @override
  String get religiousDaysChannel => 'Dini Günler ve Kandiller';

  @override
  String get ucAylarBaslangici => 'Üç Ayların Başlangıcı';

  @override
  String get ramazanArefesi => 'Ramazan Bayramı Arefesi';

  @override
  String get kurbanArefesi => 'Kurban Bayramı Arefesi';

  @override
  String get ucAylarNotifBody =>
      'Recep, Şaban ve Ramazan aylarından oluşan üç aylar bugün başladı. Üç aylarınız mübarek olsun.';

  @override
  String get ucAylarRegaipTitle => 'Üç Aylar ve Regaib Kandili';

  @override
  String get ucAylarRegaipNotifBody =>
      'Üç aylar bugün başladı, bu gece de Regaib Kandili. Üç aylarınız ve kandiliniz mübarek olsun.';

  @override
  String get regaipKandiliNotifBody =>
      'Bu gece Regaib Kandili. Kandiliniz mübarek olsun.';

  @override
  String get miracKandiliNotifBody =>
      'Bu gece Miraç Kandili. Kandiliniz mübarek olsun.';

  @override
  String get beratKandiliNotifBody =>
      'Bu gece Berat Kandili. Kandiliniz mübarek olsun.';

  @override
  String get mevlidKandiliNotifBody =>
      'Bu gece Mevlid Kandili. Kandiliniz mübarek olsun.';

  @override
  String get kadirGecesiNotifBody =>
      'Bu gece Kadir Gecesi. Kadir Geceniz mübarek olsun.';

  @override
  String get ramazanBaslangiciNotifBody =>
      'Ramazan yarın başlıyor; ilk teravih ve sahur bu gece. Hayırlı Ramazanlar!';

  @override
  String get ramazanArefesiNotifBody =>
      'Bugün arefe, yarın Ramazan Bayramı. Bayramınız şimdiden mübarek olsun.';

  @override
  String get ramazanBayramiNotifBody =>
      'Ramazan Bayramınız mübarek olsun. Nice bayramlara!';

  @override
  String get kurbanArefesiNotifBody =>
      'Bugün arefe, yarın Kurban Bayramı. Bayramınız şimdiden mübarek olsun.';

  @override
  String get kurbanBayramiNotifBody =>
      'Kurban Bayramınız mübarek, kurbanlarınız kabul olsun.';

  @override
  String get hicriYilbasiNotifBody =>
      'Bugün Hicri Yılbaşı. Yeni yılınız hayırlara vesile olsun.';

  @override
  String get asureGunuNotifBody => 'Bugün Aşure Günü. Hayırlara vesile olsun.';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get endReminderSub =>
      'Kılındı olarak işaretlenmemiş namazlar için vakit çıkmadan bildirim gönderir.';

  @override
  String get endReminderNotifTitle => 'Vakit Çıkıyor';

  @override
  String endReminderNotifBody(String vakit, int minute) {
    return '$vakit vaktinin çıkmasına $minute dakika kaldı.';
  }

  @override
  String get endReminderChannel => 'Vakit Çıkış Hatırlatmaları';

  @override
  String get ramadanIftarTitle => 'İftar Vakti';

  @override
  String ramadanIftarBody(String vakit) {
    return '$vakit vakti girdi. Hayırlı iftarlar!';
  }

  @override
  String get ramadanImsakTitle => 'İmsak Vakti';

  @override
  String get ramadanImsakBody => 'Sahur vakti sona erdi. Hayırlı oruçlar!';

  @override
  String get sectionSupport => 'DESTEK';

  @override
  String get shareApp => 'Arkadaşlarınızla Paylaş';

  @override
  String get rateApp => 'Bize Puan Ver';

  @override
  String get contactUs => 'İletişim & Hata Bildir';

  @override
  String shareText(String link) {
    return 'Harika bir ezan vakti uygulaması buldum! İndir: $link';
  }

  @override
  String get okUnderstood => 'Tamam, Anladım';

  @override
  String get religiousDaysTitle => 'Dini Günler';

  @override
  String get noDataFound => 'Veri bulunamadı.';

  @override
  String noDataForYear(int year) {
    return '$year yılı için veri bulunamadı.';
  }

  @override
  String religiousDaysListTitle(int year) {
    return '$year Yılı Dini Günler Listesi';
  }

  @override
  String get missedPrayersTitle => 'Kaza Takibi';

  @override
  String get missedPrayersInfo =>
      'Kılmadığınız namazları buraya not edip, kıldıkça düşebilirsiniz.\n(Sayıya dokunarak elle girebilirsiniz)';

  @override
  String editMissedTitle(String title) {
    return '$title Kazasını Düzenle';
  }

  @override
  String get missedCountLabel => 'Kaza Sayısı';

  @override
  String get missedCountHint => 'Örn: 150';

  @override
  String get sabah => 'Sabah';

  @override
  String get vitir => 'Vitir';

  @override
  String get oruc => 'Oruç';

  @override
  String timeLeftFor(String vakit) {
    return '$vakit Vaktine Kalan';
  }

  @override
  String get tomorrow => '(Yarın)';

  @override
  String get fridayMessagesTitle => 'Cuma Mesajları';

  @override
  String get esmaulHusnaTitle => 'Esmaül Hüsna';

  @override
  String get zakatTitle => 'Zekat Hesapla';

  @override
  String get fitreTitle => 'Fitre ve Fidye';

  @override
  String get toolFitreDesc => 'Fitre ve fidye tutarı hesabı';

  @override
  String get fitreInfo =>
      'Kişi başı tutar, Diyanet\'in belirlediği en az fitre (fıtır sadakası) miktarıdır; fitre para ya da gıda olarak verilebilir. Fidye, yaşlılık ya da iyileşme umudu olmayan bir hastalık nedeniyle oruç tutamayanların her gün için verdiği bir fitre tutarıdır. Türkiye dışındaysanız bulunduğunuz yerdeki tutarı yazabilirsiniz.';

  @override
  String get fitreAmountLabel => 'Kişi başı tutar';

  @override
  String fitreSource(String source, String year) {
    return 'Kaynak: $source, $year';
  }

  @override
  String get fitreResetAmount => 'Varsayılan tutara dön';

  @override
  String get fitreSectionTitle => 'Fitre';

  @override
  String get fitrePeopleLabel => 'Kişi sayısı';

  @override
  String get fidyeSectionTitle => 'Fidye';

  @override
  String get fidyeDaysLabel => 'Gün sayısı';

  @override
  String get fitreTotal => 'Toplam';

  @override
  String get fastTitle => 'Ramazan Orucu';

  @override
  String fastCount(int done, int total) {
    return '$done/$total gün';
  }

  @override
  String get fastInfo =>
      'Tuttuğunuz günlere dokunun. Tutulmayan günler kaza orucu sayacına bir kez eklenir; kazaya eklenen bir günü tuttuysanız üzerine dokunun, sayaçtan düşülür.';

  @override
  String get fastLegendFasted => 'Tutuldu';

  @override
  String get fastLegendKaza => 'Kazaya eklendi';

  @override
  String get fastKazaButton => 'Tutulmayanları kaza orucuna ekle';

  @override
  String fastKazaConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'İşaretlenmemiş $count gün kaza orucu sayacına eklenecek. Devam edilsin mi?',
    );
    return '$_temp0';
  }

  @override
  String fastKazaDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün kaza orucuna eklendi.',
    );
    return '$_temp0';
  }

  @override
  String get fastKazaNone => 'Kazaya eklenecek gün yok.';

  @override
  String get fastKazaRemoveTitle => 'Kazadan çıkarılsın mı?';

  @override
  String fastKazaRemoveConfirm(int from, int to) {
    return 'Bu gün tutuldu olarak işaretlenecek ve kaza orucu sayısı $from yerine $to olacak.';
  }

  @override
  String get fastFastedAction => 'Tuttum';

  @override
  String get zakatCalculatorTitle => 'Akıllı Zekat Hesaplama';

  @override
  String get liveRatesLoading => 'Güncel kurlar çekiliyor...';

  @override
  String get liveRatesInfo =>
      'Otomatik çekilen kurları isterseniz el ile düzeltebilirsiniz.';

  @override
  String get goldType => 'Altın Türü';

  @override
  String get goldAmount => 'Adet / Gram';

  @override
  String get goldUnitPrice => 'Birim Fiyatı';

  @override
  String get currencyType => 'Döviz Türü';

  @override
  String get currencyAmount => 'Miktar';

  @override
  String get currencyRate => 'Güncel Kur (TL)';

  @override
  String get calculateButton => 'HESAPLA';

  @override
  String get zakatResultTitle => 'Vermeniz Gereken Zekat';

  @override
  String get netAssets => 'Net Varlık:';

  @override
  String get qiblaTitle => 'Kıble Pusulası';

  @override
  String get locationServiceOff => 'Konum servisi kapalı. Lütfen konumu açın.';

  @override
  String get locationPermissionDenied => 'Konum izni reddedildi.';

  @override
  String get noCompass => 'Cihazda pusula yok.';

  @override
  String get qiblaFound => 'KIBLEYİ BULDUNUZ!';

  @override
  String qiblaAngle(String angle) {
    return 'Kıble Açısı: $angle°';
  }

  @override
  String get keepAwayMetal => 'Metal eşyalardan uzak tutun.';

  @override
  String get goldGram => 'Gram Altın (24 Ayar)';

  @override
  String get goldQuarter => 'Çeyrek Altın';

  @override
  String get goldFull => 'Tam Altın';

  @override
  String get typeOther => 'Diğer (Manuel)';

  @override
  String get usd => 'ABD Doları (USD)';

  @override
  String get eur => 'Euro (EUR)';

  @override
  String get gbp => 'İngiliz Sterlini (GBP)';

  @override
  String get sectionAppearance => 'GÖRÜNÜM & DİL';

  @override
  String get appearanceSettings => 'Görünüm Ayarları';

  @override
  String get appearanceSub => 'Tema ve arka plan';

  @override
  String get themeMode => 'Tema Modu';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get bgImage => 'Arka Plan Resmi';

  @override
  String get bgDefault => 'Varsayılan';

  @override
  String get bgMosque => 'Cami';

  @override
  String get bgKaaba => 'Kabe';

  @override
  String get zakatEligible => 'Zekat Verilmesi Gerekir';

  @override
  String get zakatNotEligible => 'Zekat Gerekmiyor';

  @override
  String get nisabLimit => 'Nisap Sınırı (80,18 gr Altın)';

  @override
  String get belowNisabMessage =>
      'Net varlığınız nisap miktarının (zenginlik sınırı) altında olduğu için zekat farz değildir.';

  @override
  String get searchLocationTitle => 'Konum Ara (Tüm Dünya)';

  @override
  String get searchLocationHint => 'Şehir veya Ülke (Örn: Paris)';

  @override
  String get searchInitial => 'Aramak istediğiniz yeri yazın...';

  @override
  String get searchNotFound => 'Konum bulunamadı.';

  @override
  String get searchError => 'Sonuç bulunamadı. Lütfen tekrar deneyin.';

  @override
  String locationSelected(String city) {
    return '$city seçildi';
  }

  @override
  String channelSoundPrefix(String soundName) {
    return 'Ses: $soundName';
  }

  @override
  String get channelSilentPrayers => 'Sessiz Ezan Bildirimleri';

  @override
  String get tickerEzan => 'Ezan Vakti';

  @override
  String get fetchingLocation => 'Konum alınıyor...';

  @override
  String get directionNorth => 'K';

  @override
  String get directionSouth => 'G';

  @override
  String get directionEast => 'D';

  @override
  String get directionWest => 'B';

  @override
  String get zakatDescription =>
      'Diyanet İşleri Başkanlığı fetvalarına ve güncel piyasa alış/satış kurlarına göre zekatınızı detaylı olarak hesaplayın.';

  @override
  String get cashAndCurrencyTitle => 'Nakit ve Döviz Varlıkları';

  @override
  String get goldAndSilverTitle => 'Altın ve Gümüş';

  @override
  String get silverGram => 'Gümüş (Gram)';

  @override
  String get unitPrice => 'Birim Fiyatı';

  @override
  String get commercialGoodsTitle => 'Ticari Mallar';

  @override
  String get commercialEvalCurrency => 'Değerleme Para Birimi';

  @override
  String get commercialGoodsValue => 'Malın Değeri';

  @override
  String get exchangeRateValue => 'Kur Değeri';

  @override
  String get receivablesTitle => 'Alacaklar (Tahsil Edilebilecek)';

  @override
  String get receivableType => 'Alacağın Cinsi (TL, Döviz, Altın)';

  @override
  String get amountOrCount => 'Miktar / Adet';

  @override
  String get otherAssetsTitle => 'Diğer Varlıklar';

  @override
  String get assetType => 'Varlık Türü';

  @override
  String get currencyLabel => 'Para Birimi';

  @override
  String get valueOrAmount => 'Değeri / Miktarı';

  @override
  String get agriProductsTitle => 'Zirai Ürünler (Öşür)';

  @override
  String get agriDiyanetNote =>
      'Zirai ürünlerin zekat hesaplamasında nisap miktarı aranmadığı için, ürün değerinden hesaplanan öşür doğrudan toplam zekata eklenir.';

  @override
  String get harvestedProductValue => 'Hasat Edilen Ürün Değeri (TL)';

  @override
  String get irrigationMethod => 'Sulama Yöntemi';

  @override
  String get debtsTitle => 'Borçlar (Düşülecek)';

  @override
  String get debtType => 'Borcun Cinsi (TL, Döviz, Altın)';

  @override
  String get zakatAgriIncluded => 'Dahil Edilen Öşür (Zirai Ürün Zekatı)';

  @override
  String get assetCheck => 'Çek';

  @override
  String get assetBond => 'Senet';

  @override
  String get assetSukuk => 'Sukuk';

  @override
  String get assetLeaseCert => 'Kira Sertifikası';

  @override
  String get assetStock => 'Hisse Senedi';

  @override
  String get agriSoil => 'Zirai Ürün (Topraklı Tarım)';

  @override
  String get agriSoilless => 'Zirai Ürün (Topraksız Tarım)';

  @override
  String get agriRateNoCost => 'Masrafsız (Yağmur/Nehir) - %10';

  @override
  String get agriRateCostly => 'Masraflı (Motor/Taşıma) - %5';

  @override
  String get toImsak => 'İmsaka';

  @override
  String get toGunes => 'Güneşe';

  @override
  String get toOgle => 'Öğleye';

  @override
  String get toIkindi => 'İkindiye';

  @override
  String get toAksam => 'Akşama';

  @override
  String get toYatsi => 'Yatsıya';

  @override
  String get lowAccuracyWarning =>
      'Pusula kalibrasyonu zayıf. Lütfen telefonunuzla havada \'8\' çizin.';

  @override
  String get qiblaDirection => 'Kıble Yönü';

  @override
  String get zikirmatikTitle => 'Zikirmatik';

  @override
  String get dhikrSubhanallah => 'Sübhanallah';

  @override
  String get dhikrElhamdulillah => 'Elhamdülillah';

  @override
  String get dhikrAllahuEkber => 'Allahu Ekber';

  @override
  String get dhikrKalima => 'Kelime-i Tevhid';

  @override
  String get dhikrSalavat => 'Salavat';

  @override
  String get targetReached => 'Hedefe Ulaştınız!';

  @override
  String get resetCounter => 'Sıfırla';

  @override
  String targetCount(int target) {
    return 'Hedef: $target';
  }

  @override
  String get setTarget => 'Hedef Belirle';

  @override
  String get dhikrOther => 'Diğer (Özel Zikir)';

  @override
  String get customDhikrHint => 'Çekeceğiniz zikri yazın';

  @override
  String get zikirSettings => 'Ayarlar';

  @override
  String get vibration => 'Titreşim';

  @override
  String get sound => 'Ses Efekti';

  @override
  String get keepAwake => 'Ekran Uyanık Kalsın';

  @override
  String get appearance => 'Görünüm';

  @override
  String get themeModern => 'Modern Düğme';

  @override
  String get themeClassic => 'Klasik Tesbih';

  @override
  String get dhikrListTitle => 'Zikir Listesi';

  @override
  String get addCustomDhikr => 'Yeni Özel Zikir Ekle';

  @override
  String get customDhikrAdded => 'Zikir başarıyla eklendi.';

  @override
  String get customDhikrLimit =>
      'En fazla 20 adet özel zikir ekleyebilirsiniz!';

  @override
  String get deleteDhikr => 'Sil';

  @override
  String get statisticsTitle => 'İstatistikler';

  @override
  String get monthly => 'Aylık';

  @override
  String get yearly => 'Yıllık';

  @override
  String get totalDhikr => 'Toplam Çekilen Zikir';

  @override
  String get today => 'Bugün';

  @override
  String get statsEmpty => 'Henüz zikir verisi yok.';

  @override
  String get dhikrEstagfirullah => 'Estağfirullah';

  @override
  String get dhikrLaHavle => 'La Havle Vela Kuvvete İlla Billah';

  @override
  String get dhikrHasbunallah => 'Hasbünallah';

  @override
  String get dhikrSubhanallahi => 'Sübhanallahi ve Bihamdihi';

  @override
  String get dhikrYunus => 'Hz. Yunus\'un Duası';

  @override
  String get dhikrYaAllah => 'Ya Allah (C.C.)';

  @override
  String get dhikrYaRahman => 'Ya Rahman (C.C.)';

  @override
  String get dhikrYaRahim => 'Ya Rahim (C.C.)';

  @override
  String get dhikrYaSafi => 'Ya Şafi (C.C.)';

  @override
  String get dhikrYaRezzak => 'Ya Rezzak (C.C.)';

  @override
  String get dhikrYaFettah => 'Ya Fettah (C.C.)';

  @override
  String get mainDhikrs => 'Temel Zikirler';

  @override
  String get esmaulHusnaTab => 'Esmaül Hüsna';

  @override
  String get qiblaCalibration =>
      'Pusulanın doğru çalışması için telefonunuzla havada \'8\' çizin.';

  @override
  String get hicriYilbasi => 'Hicri Yılbaşı';

  @override
  String get asureGunu => 'Aşure Günü';

  @override
  String get mevlidKandili => 'Mevlid Kandili';

  @override
  String get miracKandili => 'Miraç Kandili';

  @override
  String get beratKandili => 'Berat Kandili';

  @override
  String get ramazanBaslangici => 'Ramazan Başlangıcı';

  @override
  String get kadirGecesi => 'Kadir Gecesi';

  @override
  String get ramazanBayrami => 'Ramazan Bayramı';

  @override
  String get kurbanBayrami => 'Kurban Bayramı';

  @override
  String get regaipKandili => 'Regaib Kandili';

  @override
  String get tabTimes => 'Vakitler';

  @override
  String get tabAlarms => 'Alarmlar';

  @override
  String get locationFoundNoName => 'Konum bulundu ancak yer adı alınamadı.';

  @override
  String get dailyAyahTitle => 'Günün Ayeti';

  @override
  String get onboardingWelcome => 'Hoş Geldiniz / Welcome';

  @override
  String get onboardingSelectLanguage =>
      'Lütfen kullanmak istediğiniz dili seçin.\nPlease select your preferred language.';

  @override
  String get calibrationRequired => 'Kalibrasyon Gerekli';

  @override
  String get qiblaAccuracyNote =>
      'Pusula yaklaşık yön gösterir; metal, mıknatıs ve elektronik cihazlar yönü saptırabilir.';

  @override
  String get qiblaTipsTitle => 'Doğru sonuç için';

  @override
  String get qiblaTipFlat => 'Telefonu yere paralel tutun.';

  @override
  String get qiblaTipCalibrate =>
      'Telefonunuzla havada \'8\' çizerek kalibre edin.';

  @override
  String get qiblaTipMagneticCase =>
      'Mıknatıslı kılıf kullanıyorsanız çıkarın.';

  @override
  String get qiblaTipMetal =>
      'Metal eşyalardan ve elektronik cihazlardan uzak durun.';

  @override
  String get qiblaTipMosque =>
      'Mümkünse bir caminin kıble yönüyle karşılaştırın.';

  @override
  String qiblaAngleTrueNorth(String angle) {
    return 'Kıble açısı: $angle° (coğrafi kuzeyden)';
  }

  @override
  String qiblaDeclination(String deg) {
    return 'Manyetik sapma: $deg° (otomatik düzeltildi)';
  }

  @override
  String get qiblaInterferenceWarning =>
      'Manyetik parazit algılandı: telefonu metal eşyalardan, mıknatıslı kılıftan ve elektronik cihazlardan uzaklaştırın.';

  @override
  String get gold22kGram => '22 Ayar Gram Altın';

  @override
  String get goldAtaToptan => 'Ata Toptan';

  @override
  String get goldAtaCumhuriyet => 'Ata Cumhuriyet';

  @override
  String get gold22kBracelet => '22 Ayar Bilezik';

  @override
  String get gold18k => '18 Ayar Altın';

  @override
  String get gold14k => '14 Ayar Altın';

  @override
  String get goldHalf => 'Yarım Altın';

  @override
  String get goldGremse => 'Gremse Altın';

  @override
  String get goldAtaBesli => 'Ata Beşli';

  @override
  String get goldResat => 'Reşat Altın';

  @override
  String get goldHamit => 'Hamit Altın';

  @override
  String get currencyChf => 'İsviçre Frangı';

  @override
  String get currencyJpy => 'Japon Yeni';

  @override
  String get currencySar => 'Suudi Arabistan Riyali';

  @override
  String get currencyAud => 'Avustralya Doları';

  @override
  String get currencyCad => 'Kanada Doları';

  @override
  String get currencyRub => 'Rus Rublesi';

  @override
  String get currencyAzn => 'Azerbaycan Manatı';

  @override
  String get currencyCny => 'Çin Yuanı';

  @override
  String get currencyRon => 'Romanya Leyi';

  @override
  String get currencyAed => 'BAE Dirhemi';

  @override
  String get currencyBgn => 'Bulgar Levası';

  @override
  String get currencyKwd => 'Kuveyt Dinarı';

  @override
  String get currencyTry => 'Türk Lirası';

  @override
  String get editCounterTitle => 'Sayacı Düzenle';

  @override
  String get resetCounterConfirm =>
      'Sayacı sıfırlamak istediğinize emin misiniz?';

  @override
  String get imsakiyeTitle => 'İmsakiye';

  @override
  String get toolsGroupPrayer => 'Namaz';

  @override
  String get toolsGroupInfo => 'Bilgi';

  @override
  String get toolsGroupCalc => 'Hesaplama';

  @override
  String get toolImsakiyeDesc => 'Aylık ve Ramazan vakitleri';

  @override
  String get toolTrackerDesc => 'Kıldığınız vakitleri işaretleyin';

  @override
  String get toolKazaDesc => 'Kaza namazı ve oruç sayacı';

  @override
  String get toolReligiousDaysDesc => 'Kandiller ve bayramlar';

  @override
  String get nearbyMosquesTitle => 'Yakındaki Camiler';

  @override
  String get toolNearbyMosquesDesc => 'Size en yakın camileri haritada bulun';

  @override
  String get nearbyMosquesQuery => 'cami';

  @override
  String get nearbyMosquesError => 'Harita açılamadı.';

  @override
  String get toolEsmaDesc => 'Allah\'ın 99 ismi ve anlamları';

  @override
  String get toolFridayDesc => 'Paylaşmaya hazır mesajlar';

  @override
  String get toolZakatDesc => 'Zekat ve öşür hesabı';

  @override
  String get toolSettingsDesc => 'Konum, bildirimler, görünüm';

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün kaldı',
      one: 'Yarın',
      zero: 'Bugün',
    );
    return '$_temp0';
  }

  @override
  String get previousYear => 'Önceki yıl';

  @override
  String get nextYear => 'Sonraki yıl';

  @override
  String get previousItem => 'Önceki';

  @override
  String get nextItem => 'Sonraki';

  @override
  String missedChangeConfirm(String name, int from, int to) {
    return '$name kaza sayısı $from yerine $to olacak. Kaydedilsin mi?';
  }

  @override
  String get shareFailed => 'İşlem yapılamadı. Lütfen tekrar deneyin.';

  @override
  String get zakatCurrencyNote => 'Tüm tutarlar Türk lirası (₺) cinsindendir.';

  @override
  String get zakatCashTry => 'Nakit (₺)';

  @override
  String get zakatRatesUnavailable =>
      'Güncel altın fiyatı ve kurlar alınamadı. Lütfen fiyatları elle girin.';

  @override
  String get zakatGoldGramPrice => '24 Ayar Gram Altın Fiyatı (₺)';

  @override
  String get zakatGoldGramPriceHelp => 'Nisap sınırı bu fiyatla hesaplanır.';

  @override
  String get zakatNisabUnknown =>
      'Gram altın fiyatı olmadan nisap sınırı hesaplanamaz. Sonucun doğru olması için altın fiyatını girin.';

  @override
  String get imsakiyeRamadan => 'Ramazan';

  @override
  String imsakiyeRamadanTitle(int year) {
    return 'Ramazan $year İmsakiyesi';
  }

  @override
  String get imsakiyeDay => 'Gün';

  @override
  String get imsakiyeSunriseShort => 'Güneş';

  @override
  String get imsakiyePrevMonth => 'Önceki ay';

  @override
  String get imsakiyeNextMonth => 'Sonraki ay';

  @override
  String get imsakiyeNoLocation =>
      'İmsakiyeyi görmek için önce konumunuzu seçin. Konumu ana ekrandan veya Ayarlar\'dan belirleyebilirsiniz.';

  @override
  String get imsakiyeShareError =>
      'İmsakiye paylaşılamadı. Lütfen tekrar deneyin.';

  @override
  String get ramadanSahurLeft => 'Sahura Kalan';

  @override
  String get ramadanIftarLeft => 'İftara Kalan';

  @override
  String ramadanDayLabel(int day) {
    return 'Ramazan\'ın $day. günü';
  }
}
