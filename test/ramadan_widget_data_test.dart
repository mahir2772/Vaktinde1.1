import 'dart:convert';
import 'dart:io';

import 'package:ezan_saati/data/services/widget_service.dart';
import 'package:ezan_saati/features/imsakiye/imsakiye_logic.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

// Ramazan widget'ının verisi (WidgetService.ramadanData). Anahtarlar Kotlin'le sözleşme
// (VaktindeWidgetRamadanProvider.kt): gün numarası = bugün − ramadan_start + 1, kalan gün =
// ramadan_start − bugün; son iftardan sonra ramadan_next_start'a sayılır.
void main() {
  final calendar = RamadanCalendar.fromReligiousDays(
    jsonDecode(File('assets/data/religious_days.json').readAsStringSync())
        as List<dynamic>,
  );
  final tr = lookupAppLocalizations(const Locale('tr'));

  // yyyy-MM-dd → UTC gece yarısı (Kotlin: PrayerWidgetData.epochDay)
  DateTime utc(String key) => DateTime.parse('${key}T00:00:00Z');
  // Kotlin'in hesabı: bugün − başlangıç (gün)
  int sinceStart(String start, DateTime now) =>
      DateTime.utc(now.year, now.month, now.day).difference(utc(start)).inDays;

  // Önce: intl tarih verisi yüklenmemişken (arka plan görevinde çağıran yükler)
  test('Tarih verisi yüklenmemişse başlangıç tarihi gg.aa.yyyy', () {
    final data = WidgetService.ramadanData(
      now: DateTime(2026, 10, 10, 12),
      calendar: calendar,
      loc: tr,
    );
    expect(data['ramadan_start_text'], '08.02.2027');
    expect(data['ramadan_next_start_text'], '28.01.2028');
  });

  group('Tarih verisi yüklü', () {
    setUpAll(() => initializeDateFormatting());

    test('Ramazan öncesi: sıradaki Ramazan, kalan gün ve başlangıç tarihi', () {
      final now = DateTime(2026, 10, 10, 12);
      final data = WidgetService.ramadanData(
        now: now,
        calendar: calendar,
        loc: tr,
      );
      expect(data, {
        'ramadan_start': '2027-02-08',
        'ramadan_end': '2027-03-08', // bayramdan (9 Mart) bir önceki gün
        'ramadan_next_start': '2028-01-28',
        'ramadan_start_text': '8 Şubat 2027',
        'ramadan_next_start_text': '28 Ocak 2028',
        'ramadan_title_sahur': 'Sahura Kalan',
        'ramadan_title_iftar': 'İftara Kalan',
        'ramadan_title_until': "Ramazan'a Kalan Gün",
        'ramadan_day_text': 'Ramazan · %d. gün',
      });
      expect(-sinceStart(data['ramadan_start']!, now), 121); // Ramazan'a 121 gün
    });

    test('Arefe: kalan 1 gün (akşamdan sonra Kotlin ilk sahura sayar)', () {
      final data = WidgetService.ramadanData(
        now: DateTime(2027, 2, 7, 21),
        calendar: calendar,
        loc: tr,
      );
      expect(data['ramadan_start'], '2027-02-08');
      expect(-sinceStart(data['ramadan_start']!, DateTime(2027, 2, 7)), 1);
    });

    test('Ramazan içinde: içinde bulunulan Ramazan, gün numarası', () {
      for (final (now, day) in [
        (DateTime(2027, 2, 8, 3), 1),
        (DateTime(2027, 2, 19, 15), 12),
        (DateTime(2027, 3, 8, 12), 29),
      ]) {
        final data = WidgetService.ramadanData(
          now: now,
          calendar: calendar,
          loc: tr,
        );
        expect(data['ramadan_start'], '2027-02-08', reason: '$now');
        expect(data['ramadan_end'], '2027-03-08', reason: '$now');
        expect(sinceStart(data['ramadan_start']!, now) + 1, day);
        expect(calendar.dayOf(now), day);
        expect(
          data['ramadan_day_text']!.replaceAll('%d', '$day'),
          'Ramazan · $day. gün',
        );
      }
    });

    test('Son gün (iftardan sonra da): bu Ramazan + sıradakinin başlangıcı', () {
      final data = WidgetService.ramadanData(
        now: DateTime(2027, 3, 8, 21),
        calendar: calendar,
        loc: tr,
      );
      expect(data['ramadan_start'], '2027-02-08');
      expect(data['ramadan_end'], '2027-03-08');
      expect(data['ramadan_next_start'], '2028-01-28');
      expect(data['ramadan_next_start_text'], '28 Ocak 2028');
    });

    test('Ramazan sonrası (bayram): sıradaki Ramazan; ondan sonraki hicri '
        'hesapla (json 2028\'de bitiyor)', () {
      final data = WidgetService.ramadanData(
        now: DateTime(2027, 3, 9, 9),
        calendar: calendar,
        loc: tr,
      );
      expect(data['ramadan_start'], '2028-01-28');
      expect(data['ramadan_end'], '2028-02-25');
      final next = ramadanOfHijriYear(1450).start;
      expect(data['ramadan_next_start'], next.toIso8601String().split('T')[0]);
      expect(utc(data['ramadan_next_start']!).year, 2029);
    });

    test('Resmi tarih yoksa hicri hesap: aralık tutarlı, sıradaki ardından', () {
      final data = WidgetService.ramadanData(
        now: DateTime(2031, 6, 1),
        calendar: RamadanCalendar.hijriOnly,
      );
      final start = utc(data['ramadan_start']!);
      final end = utc(data['ramadan_end']!);
      final next = utc(data['ramadan_next_start']!);
      expect(start.isAfter(DateTime.utc(2031, 6, 1)), isTrue);
      expect(end.difference(start).inDays, anyOf(28, 29));
      expect(next.difference(start).inDays, inInclusiveRange(350, 360));
      // Dil yoksa Türkçe
      expect(data['ramadan_title_until'], tr.widgetRamadanUntil);
      expect(data['ramadan_day_text'], 'Ramazan · %d. gün');
    });

    test('Metinler seçili dilde; gün şablonunda tek %d', () {
      const days = {
        'tr': 'Ramazan · 12. gün',
        'en': 'Ramadan · day 12',
        'de': 'Ramadan · Tag 12',
        'fr': 'Ramadan · jour 12',
        'ar': 'رمضان · اليوم 12',
      };
      const starts = {
        'tr': '8 Şubat 2027',
        'en': '8 February 2027',
        'de': '8 Februar 2027',
        'fr': '8 février 2027',
      };
      for (final lang in days.keys) {
        final loc = lookupAppLocalizations(Locale(lang));
        final data = WidgetService.ramadanData(
          now: DateTime(2026, 10, 10),
          calendar: calendar,
          loc: loc,
        );
        expect(data['ramadan_title_sahur'], loc.ramadanSahurLeft);
        expect(data['ramadan_title_iftar'], loc.ramadanIftarLeft);
        expect(data['ramadan_title_until'], loc.widgetRamadanUntil);
        final template = data['ramadan_day_text']!;
        expect('%d'.allMatches(template).length, 1, reason: lang);
        expect(template.replaceAll('%d', '12'), days[lang]);
        if (starts.containsKey(lang)) {
          expect(data['ramadan_start_text'], starts[lang], reason: lang);
        } else {
          expect(data['ramadan_start_text'], contains('فبراير'));
        }
      }
    });
  });
}
