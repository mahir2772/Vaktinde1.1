import 'package:home_widget/home_widget.dart';

class WidgetService {
  static Future<void> widgetiGuncelle({
    required String baslik,
    required int hedefZamanMs,
    required Map<String, String> vakitler,
    required String konum,
    required Map<String, String> vakitIsimleri,
    required String hijriDateText, // 🔥 YENİ
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
