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
  String get exactAlarm => 'Tam Vaktinde Oku';

  @override
  String get exactAlarmSub => 'Bildirim gönderir.';

  @override
  String get silentNotif => 'Sadece Yazılı Bildirim';

  @override
  String get silentNotifSub => 'Ezan/Ses çalmaz, sadece uyarı gelir.';

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
  String get navPrayer => 'Vakitler';

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
      'Doğru namaz vakitleri için İlçe seçimi önemlidir.';

  @override
  String get menuNotifications => 'Bildirim İzinleri';

  @override
  String get menuNotificationsSub => 'Ses gelmiyorsa buradan kontrol et.';

  @override
  String get menuTroubleshoot => 'Bildirim Gelmiyor mu?';

  @override
  String get menuTroubleshootSub => 'Samsung/Xiaomi için pil ayarı yapın.';

  @override
  String get sectionSupport => 'DESTEK';

  @override
  String get shareApp => 'Arkadaşınla Paylaş';

  @override
  String get rateApp => 'Bize Puan Ver';

  @override
  String get contactUs => 'İletişim & Hata Bildir';

  @override
  String shareText(String link) {
    return 'Harika bir Ezan Vakti uygulaması buldum! İndir: $link';
  }

  @override
  String get batteryDialogTitle => 'Bildirim Sorunu Çözümü';

  @override
  String get batteryDialogBody =>
      'Telefonunuz pil tasarrufu için uygulamayı kapatıyor olabilir. Bunu önlemek için:\n\n1. Son Uygulamalar (Kare tuşu) ekranını açın.\n2. \'Vaktinde\' uygulamasının üzerine basılı tutun veya logoya tıklayın.\n3. Kilit Simgesine 🔒 basarak kilitleyin.\n\nAyrıca Ayarlar > Uygulamalar > Vaktinde > Pil > Kısıtlanmamış seçeneğini seçin.';

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
      'Kılmadığınız namazları buraya not edip, kıldıkça düşebilirsiniz.\n(Sayıya tıklayarak elle girebilirsiniz)';

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
  String get zakatCalculatorTitle => 'Akıllı Zekat Hesapla';

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
  String get goldUnitPrice => 'Birim Fiyatı (TL)';

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
  String get appearanceSub => 'Tema ve Arka Plan';

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
  String get nisabLimit => 'Nisab Sınırı (80.18 gr Altın)';

  @override
  String get belowNisabMessage =>
      'Net varlığınız Nisab miktarının (zenginlik sınırı) altında olduğu için zekat farz değildir.';
}
