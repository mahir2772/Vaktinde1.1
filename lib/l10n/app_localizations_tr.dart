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
  String get ok => 'Tamam';

  @override
  String get nextPrayer => 'Sıradaki Vakit';

  @override
  String get hadithTitle => 'Günün Hadisi';

  @override
  String get readMore => 'Devamını Oku...';

  @override
  String get share => 'Paylaş';

  @override
  String get close => 'Kapat';

  @override
  String get loading => 'Vakitler Hesaplanıyor...';

  @override
  String get error => 'Hata';

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
  String get navMenu => 'Menü';

  @override
  String get menuTitle => 'Ayarlar';

  @override
  String get sectionLocation => 'KONUM & VAKİTLER';

  @override
  String get changeLocation => 'Konum Değiştir';

  @override
  String get citySelect => 'İl Seçiniz';

  @override
  String get districtSelect => 'İlçe Seçiniz';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'İptal';

  @override
  String get locationWarning =>
      'Doğru namaz vakitleri için ilçe seçimi önemlidir.';

  @override
  String get menuNotifications => 'Bildirim İzinleri';

  @override
  String get menuNotificationsSub => 'Ses gelmiyorsa buradan kontrol edin.';

  @override
  String get menuTroubleshoot => 'Bildirim Gelmiyor mu?';

  @override
  String get menuTroubleshootSub => 'Samsung/Xiaomi için pil ayarı yapın.';

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
      'Son 30 gün içinde (takibe başladığınız günden itibaren) işaretlenmemiş vakitler kaza sayaçlarına eklenir. Her vakit yalnızca bir kez eklenir.';

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
  String get trackerKazaLocked =>
      'Bu vakit kazaya eklendi. Kıldığınızda Kaza Takibi\'nden düşebilirsiniz.';

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
  String get dailyContentNotifTitle => 'Günün Ayeti ve Hadisi Bildirimi';

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
  String get batteryDialogTitle => 'Bildirim Sorunu Çözümü';

  @override
  String get batteryDialogBody =>
      'Telefonunuz pil tasarrufu için uygulamayı kapatıyor olabilir. Bunu önlemek için:\n\n1. Son Uygulamalar (kare tuşu) ekranını açın.\n2. \'Vaktinde\' uygulamasının üzerine basılı tutun veya simgesine dokunun.\n3. Kilit simgesine 🔒 dokunarak uygulamayı kilitleyin.\n\nAyrıca Ayarlar > Uygulamalar > Vaktinde > Pil bölümünden \'Kısıtlanmamış\' seçeneğini işaretleyin.';

  @override
  String get okUnderstood => 'Tamam, Anladım';

  @override
  String get religiousDaysTitle => 'Dini Günler';

  @override
  String errorOccurred(String error) {
    return 'Hata oluştu: $error';
  }

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
  String get closeCaps => 'KAPAT';

  @override
  String get zakatTitle => 'Zekat Hesapla';

  @override
  String get zakatCalculatorTitle => 'Akıllı Zekat Hesaplama';

  @override
  String get liveRatesLoading => 'Güncel kurlar çekiliyor...';

  @override
  String get liveRatesInfo =>
      'Otomatik çekilen kurları isterseniz el ile düzeltebilirsiniz.';

  @override
  String get sectionGold => 'Altın Varlığı';

  @override
  String get goldType => 'Altın Türü';

  @override
  String get goldAmount => 'Adet / Gram';

  @override
  String get goldUnitPrice => 'Birim Fiyatı';

  @override
  String get sectionCurrency => 'Döviz Varlığı';

  @override
  String get currencyType => 'Döviz Türü';

  @override
  String get currencyAmount => 'Miktar';

  @override
  String get currencyRate => 'Güncel Kur (TL)';

  @override
  String get sectionCashDebt => 'Nakit & Borçlar';

  @override
  String get cashAmount => 'Eldeki & Bankadaki Nakit (TL)';

  @override
  String get debtAmount => 'Toplam Borçlar (Düşülecek)';

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
  String get locationPermissionForever =>
      'Konum izni kalıcı olarak engellendi. Ayarlardan açmalısınız.';

  @override
  String compassError(String error) {
    return 'Sensör hatası: $error';
  }

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
  String get bgQuran => 'Kur\'an';

  @override
  String get none => 'Yok';

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
  String get stickyChannelName => 'Kalıcı Sayaç';

  @override
  String get stickyChannelDesc => 'Vakte kalan süreyi gösterir';

  @override
  String get timeLeftTo => 'Vaktin Çıkmasına: ';

  @override
  String get locationFallbackMessage =>
      'Konum alınamadı, varsayılan değer kullanılıyor.';

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
  String get calibrationInstruction => '(Kalibrasyon için \'8\' çizin)';

  @override
  String get zakatDescription =>
      'Diyanet İşleri Başkanlığı fetvalarına ve güncel piyasa alış/satış kurlarına göre zekatınızı detaylı olarak hesaplayın.';

  @override
  String get cashAndCurrencyTitle => 'Nakit ve Döviz Varlıkları';

  @override
  String get cashTurkishLira => 'Nakit Türk Lirası (TL)';

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
  String get customDhikrTitle => 'Özel Zikir Ekle';

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
  String get introTitle1 => 'Vaktinde\'ye Hoş Geldiniz';

  @override
  String get introDesc1 =>
      'Namaz vakitlerini, zikirlerinizi ve dini günleri en modern ve şık arayüzle kolayca takip edin.';

  @override
  String get introTitle2 => 'Akıllı Bildirimler';

  @override
  String get introDesc2 =>
      'Ezan vakitlerinde dilediğiniz bildirim sesiyle uyarı alın. İbadetlerinizi asla kaçırmayın.';

  @override
  String get introTitle3 => 'Gelişmiş Araçlar';

  @override
  String get introDesc3 =>
      'Animasyonlu Zikirmatik, Kaza Takibi, Esmaül Hüsna ve Zekat hesaplama ile maneviyatınızı güçlendirin.';

  @override
  String get introSkip => 'Geç';

  @override
  String get introNext => 'İleri';

  @override
  String get introStart => 'Hemen Başla';

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
  String get remainingTime => 'Kalan';

  @override
  String get onboardingWelcome => 'Hoş Geldiniz / Welcome';

  @override
  String get onboardingSelectLanguage =>
      'Lütfen kullanmak istediğiniz dili seçin.\nPlease select your preferred language.';

  @override
  String get turnRight => 'Sağa dönün ➔';

  @override
  String get turnSlightRight => 'Biraz sağa dönün ➔';

  @override
  String get turnLeft => '⬅ Sola dönün';

  @override
  String get turnSlightLeft => '⬅ Biraz sola dönün';

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
  String get holdToEdit => 'Düzenlemek için basılı tutun';

  @override
  String get editCounterTitle => 'Sayacı Düzenle';

  @override
  String get editCounterHint => 'Örn: 2000';

  @override
  String get editTargetHint => 'Örn: 99';

  @override
  String get resetCounterConfirm =>
      'Sayacı sıfırlamak istediğinize emin misiniz?';

  @override
  String get dhikrTarget => 'Hedef:';

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
