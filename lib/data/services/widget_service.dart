import 'package:home_widget/home_widget.dart';

class WidgetService {
  static Future<void> widgetiGuncelle({
    required String baslik,
    required String kalanSure,
    required Map<String, String> vakitler,
  }) async {
    try {
      // Başlık ve Kalan Süre
      await HomeWidget.saveWidgetData<String>('title_text', baslik);
      await HomeWidget.saveWidgetData<String>('countdown_text', kalanSure);

      // Tüm Vakitleri Kaydet (Key'ler Kotlin tarafıyla aynı olmalı)
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

      await HomeWidget.updateWidget(
        name: 'VaktindeWidgetProvider',
        androidName: 'VaktindeWidgetProvider',
      );
      print("✅ Widget Tam Liste Olarak Güncellendi");
    } catch (e) {
      print("❌ Widget Hatası: $e");
    }
  }
}
