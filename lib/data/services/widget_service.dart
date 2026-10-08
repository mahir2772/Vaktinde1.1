import 'package:home_widget/home_widget.dart';

class WidgetService {
  // Gün dönümü anahtarları (Kotlin: PrayerWidgetData.kt): bugünün setinin günü
  // (yyyy-MM-dd) ve yarının vakitleri. Yarının verisi yoksa anahtarlar silinir;
  // Kotlin eski davranışa (bugünün imsakı +1 gün) döner.
  static const String dateKey = 'times_date';
  static const Map<String, String> tomorrowKeys = {
    'İmsak': 'tomorrow_imsak_time',
    'Güneş': 'tomorrow_gunes_time',
    'Öğle': 'tomorrow_ogle_time',
    'İkindi': 'tomorrow_ikindi_time',
    'Akşam': 'tomorrow_aksam_time',
    'Yatsı': 'tomorrow_yatsi_time',
  };
  static const String tomorrowHijriKey = 'tomorrow_hijri_date_text';

  // Vakte kalan başlıkları ("Öğleye", Kotlin: PrayerWidgetData.kt): 'title_text'
  // yazıldığı andaki sıradaki vakte göredir; vakit geçince Kotlin başlığı
  // uygulamayı beklemeden bunlardan seçer
  static const Map<String, String> titleKeys = {
    'İmsak': 'title_imsak',
    'Güneş': 'title_gunes',
    'Öğle': 'title_ogle',
    'İkindi': 'title_ikindi',
    'Akşam': 'title_aksam',
    'Yatsı': 'title_yatsi',
  };

  static Future<void> widgetiGuncelle({
    required String baslik,
    required int hedefZamanMs,
    required Map<String, String> vakitler,
    required String konum,
    required Map<String, String> vakitIsimleri,
    required Map<String, String> vakitBasliklari,
    required String hijriDateText, // 🔥 YENİ
    String? tarih,
    Map<String, String>? yarinVakitler,
    String? yarinHijriDateText,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('title_text', baslik);
      await HomeWidget.saveWidgetData<int>('target_time_ms', hedefZamanMs);
      await HomeWidget.saveWidgetData<String>('location_text', konum);
      await HomeWidget.saveWidgetData<String>(
        'hijri_date_text',
        hijriDateText,
      ); // 🔥 YENİ

      await HomeWidget.saveWidgetData<String>(
        'imsak_time',
        vakitler['İmsak'] ?? "",
      );
      await HomeWidget.saveWidgetData<String>(
        'gunes_time',
        vakitler['Güneş'] ?? "",
      );
      await HomeWidget.saveWidgetData<String>(
        'ogle_time',
        vakitler['Öğle'] ?? "",
      );
      await HomeWidget.saveWidgetData<String>(
        'ikindi_time',
        vakitler['İkindi'] ?? "",
      );
      await HomeWidget.saveWidgetData<String>(
        'aksam_time',
        vakitler['Akşam'] ?? "",
      );
      await HomeWidget.saveWidgetData<String>(
        'yatsi_time',
        vakitler['Yatsı'] ?? "",
      );

      await HomeWidget.saveWidgetData<String>(dateKey, tarih);
      for (final entry in tomorrowKeys.entries) {
        await HomeWidget.saveWidgetData<String>(
          entry.value,
          yarinVakitler?[entry.key],
        );
      }
      await HomeWidget.saveWidgetData<String>(
        tomorrowHijriKey,
        yarinHijriDateText,
      );

      await HomeWidget.saveWidgetData<String>(
        'label_imsak',
        vakitIsimleri['İmsak'] ?? "",
      );
      await HomeWidget.saveWidgetData<String>(
        'label_gunes',
        vakitIsimleri['Güneş'] ?? "",
      );
      await HomeWidget.saveWidgetData<String>(
        'label_ogle',
        vakitIsimleri['Öğle'] ?? "",
      );
      await HomeWidget.saveWidgetData<String>(
        'label_ikindi',
        vakitIsimleri['İkindi'] ?? "",
      );
      await HomeWidget.saveWidgetData<String>(
        'label_aksam',
        vakitIsimleri['Akşam'] ?? "",
      );
      await HomeWidget.saveWidgetData<String>(
        'label_yatsi',
        vakitIsimleri['Yatsı'] ?? "",
      );
      for (final entry in titleKeys.entries) {
        await HomeWidget.saveWidgetData<String>(
          entry.value,
          vakitBasliklari[entry.key] ?? "",
        );
      }

      // 1x1 WIDGET GÜNCELLEMESİ
      await HomeWidget.updateWidget(
        name: 'VaktindeWidgetSmallProvider',
        androidName: 'VaktindeWidgetSmallProvider',
      );

      // 3x2 WIDGET GÜNCELLEMESİ
      await HomeWidget.updateWidget(
        name: 'VaktindeWidgetLargeProvider',
        androidName: 'VaktindeWidgetLargeProvider',
      );

      // YENİ 4x1 (İNCE) WIDGET GÜNCELLEMESİ
      await HomeWidget.updateWidget(
        name: 'VaktindeWidgetSmall2Provider',
        androidName: 'VaktindeWidgetSmall2Provider',
      );

      await HomeWidget.updateWidget(
        name: 'NotificationUpdater',
        androidName: 'NotificationUpdater',
      );
    } catch (e) {
      // Hata sessizce yutulur
    }
  }
}
