import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import 'package:ezan_saati/core/ui/app_format.dart';
import 'package:ezan_saati/features/imsakiye/imsakiye_logic.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

class WidgetService {
  // Bugünün vakitleri ("HH:mm"; Kotlin bunlarla hesaplar: PrayerWidgetData.kt)
  static const Map<String, String> timeKeys = {
    'İmsak': 'imsak_time',
    'Güneş': 'gunes_time',
    'Öğle': 'ogle_time',
    'İkindi': 'ikindi_time',
    'Akşam': 'aksam_time',
    'Yatsı': 'yatsi_time',
  };

  /// Vakit anahtarının ([timeKeys], [tomorrowKeys]) ekrandaki yazımı:
  /// "imsak_time" → "imsak_time_text". Uygulama dilinde [formatPrayerTime]
  /// (en/ar 12 saat "4:08 PM", diğerleri 24 saat); Kotlin varsa bunu gösterir,
  /// yoksa (eski veri) "HH:mm".
  static String textKey(String timeKey) => '${timeKey}_text';

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

  /// Ramazan widget'ının anahtarları (Kotlin: VaktindeWidgetRamadanProvider.kt):
  /// içinde bulunulan ya da sıradaki Ramazan'ın ilk ve son oruç günü, ondan
  /// sonrakinin ilk günü (yyyy-MM-dd; son iftardan sonra widget uygulamayı
  /// beklemeden ona sayar), başlangıç tarihlerinin metni ve başlıklar. Gün numarasını
  /// ve kalan günü Kotlin tarihlerden hesaplar; gün metninde %d sayının yeri.
  /// Saf; tarih metni için intl tarih verisi yüklü olmalı (değilse gg.aa.yyyy).
  /// [loc] yoksa Türkçe.
  static Map<String, String> ramadanData({
    required DateTime now,
    required RamadanCalendar calendar,
    AppLocalizations? loc,
  }) {
    final l = loc ?? lookupAppLocalizations(const Locale('tr'));
    final current = calendar.currentOrNext(now);
    final next = calendar.rangeOf(current.hijriYear + 1);
    String day(DateTime d) => d.toIso8601String().split('T')[0];
    // Ana ekrandaki miladi tarihle aynı biçim ("8 Şubat 2027")
    String text(DateTime d) {
      try {
        return DateFormat('d MMMM y', l.localeName).format(d);
      } catch (_) {
        return DateFormat('dd.MM.yyyy').format(d);
      }
    }

    return {
      'ramadan_start': day(current.start),
      'ramadan_end': day(current.end),
      'ramadan_next_start': day(next.start),
      'ramadan_start_text': text(current.start),
      'ramadan_next_start_text': text(next.start),
      'ramadan_title_sahur': l.ramadanSahurLeft,
      'ramadan_title_iftar': l.ramadanIftarLeft,
      'ramadan_title_until': l.widgetRamadanUntil,
      'ramadan_day_text': l.widgetRamadanDay('%d'),
    };
  }

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
    Map<String, String>? ramazan, // [ramadanData]; null: Ramazan anahtarları değişmez
    String? dil, // AppLocalizations.localeName: saat yazımı ([textKey]); null: 24 saat
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('title_text', baslik);
      await HomeWidget.saveWidgetData<int>('target_time_ms', hedefZamanMs);
      await HomeWidget.saveWidgetData<String>('location_text', konum);
      await HomeWidget.saveWidgetData<String>(
        'hijri_date_text',
        hijriDateText,
      ); // 🔥 YENİ

      // Her vakit "HH:mm" + ekrandaki yazımı (dil değişince 24/12 saat de değişir)
      String yazim(String vakit) => formatPrayerTime(vakit, dil ?? 'tr');
      for (final entry in timeKeys.entries) {
        final vakit = vakitler[entry.key] ?? "";
        await HomeWidget.saveWidgetData<String>(entry.value, vakit);
        await HomeWidget.saveWidgetData<String>(
          textKey(entry.value),
          yazim(vakit),
        );
      }

      await HomeWidget.saveWidgetData<String>(dateKey, tarih);
      for (final entry in tomorrowKeys.entries) {
        final vakit = yarinVakitler?[entry.key];
        await HomeWidget.saveWidgetData<String>(entry.value, vakit);
        await HomeWidget.saveWidgetData<String>(
          textKey(entry.value),
          vakit == null ? null : yazim(vakit),
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
      for (final entry in (ramazan ?? const <String, String>{}).entries) {
        await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
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

      // 2x2 RAMAZAN WIDGET'I
      await HomeWidget.updateWidget(
        name: 'VaktindeWidgetRamadanProvider',
        androidName: 'VaktindeWidgetRamadanProvider',
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
