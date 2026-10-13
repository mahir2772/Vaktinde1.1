// İnternetsiz konum listesi (assets/data/locations.json): veri bütünlüğü,
// koordinat doğruluğu, arama ve saat dilimi uyarısı.
import 'dart:math' as math;

import 'package:ezan_saati/data/services/location_catalog.dart';
import 'package:ezan_saati/data/services/quran_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plaka sırasıyla 81 il (resmî Türkçe yazım)
const _provinces = [
  'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Amasya', 'Ankara', //
  'Antalya', 'Artvin', 'Aydın', 'Balıkesir', 'Bilecik', 'Bingöl', 'Bitlis',
  'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum', 'Denizli',
  'Diyarbakır', 'Edirne', 'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir',
  'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkâri', 'Hatay', 'Isparta',
  'Mersin', 'İstanbul', 'İzmir', 'Kars', 'Kastamonu', 'Kayseri', 'Kırklareli',
  'Kırşehir', 'Kocaeli', 'Konya', 'Kütahya', 'Malatya', 'Manisa',
  'Kahramanmaraş', 'Mardin', 'Muğla', 'Muş', 'Nevşehir', 'Niğde', 'Ordu',
  'Rize', 'Sakarya', 'Samsun', 'Siirt', 'Sinop', 'Sivas', 'Tekirdağ', 'Tokat',
  'Trabzon', 'Tunceli', 'Şanlıurfa', 'Uşak', 'Van', 'Yozgat', 'Zonguldak',
  'Aksaray', 'Bayburt', 'Karaman', 'Kırıkkale', 'Batman', 'Şırnak', 'Bartın',
  'Ardahan', 'Iğdır', 'Yalova', 'Karabük', 'Kilis', 'Osmaniye', 'Düzce',
];

/// Ülke sınır kutuları (enlem min/maks, boylam min/maks)
const _bbox = {
  'TR': (35.8, 42.2, 25.6, 44.9),
  'DE': (47.2, 55.1, 5.8, 15.1),
  'NL': (50.7, 53.6, 3.3, 7.3),
  'BE': (49.4, 51.6, 2.5, 6.5),
  'FR': (41.3, 51.2, -5.2, 9.6),
  'AT': (46.3, 49.1, 9.5, 17.2),
  'CH': (45.8, 47.9, 5.9, 10.5),
  'GB': (49.8, 60.9, -8.7, 1.8),
  'DK': (54.5, 57.8, 8.0, 15.2),
  'SE': (55.3, 69.1, 11.0, 24.2),
  'NO': (57.9, 71.2, 4.5, 31.2),
  'KKTC': (35.0, 35.7, 32.6, 34.6),
};

double _km(LocationPlace a, LocationPlace b) {
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.lat - a.lat);
  final dLng = rad(b.lng - a.lng);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.lat)) *
          math.cos(rad(b.lat)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * 6371 * math.asin(math.sqrt(h));
}

/// Türkçe alfabe sırası (â/î/û harf işaretsiz; rakam önce, boşluk yok sayılır)
int _trCompare(String a, String b) {
  const alphabet = 'abcçdefgğhıijklmnoöprsştuüvyz';
  List<int> key(String s) => [
    for (final c
        in s
            .replaceAll('İ', 'i')
            .replaceAll('I', 'ı')
            .toLowerCase()
            .replaceAll('â', 'a')
            .replaceAll('î', 'i')
            .replaceAll('û', 'u')
            .split(''))
      if (int.tryParse(c) case final digit?)
        digit - 10
      else if (alphabet.contains(c))
        alphabet.indexOf(c),
  ];
  final ka = key(a), kb = key(b);
  for (var i = 0; i < math.min(ka.length, kb.length); i++) {
    if (ka[i] != kb[i]) return ka[i].compareTo(kb[i]);
  }
  return ka.length.compareTo(kb.length);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocationCatalog catalog;

  // Asset pubspec'te kayıtlı ve okunabilir (önbellekli Future gerçek bölgede)
  setUpAll(() async => catalog = await LocationCatalog.load());

  LocationProvince province(String name) =>
      catalog.provinces.firstWhere((p) => p.name == name);
  LocationPlace district(String il, String ilce) =>
      province(il).districts.firstWhere((d) => d.name == ilce);
  LocationPlace city(String country, String name) => catalog.countries
      .firstWhere((c) => c.code == country)
      .cities
      .firstWhere((c) => c.name == name);

  group('Türkiye', () {
    test('81 il eksiksiz, Türkçe yazımla ve alfabe sırasında', () {
      final names = catalog.provinces.map((p) => p.name).toList();
      expect(names.toSet(), _provinces.toSet());
      expect(names, hasLength(81));
      expect(names, [...names]..sort(_trCompare));
    });

    test('973 ilçe: 922 ilçe + 51 "Merkez" (il merkezi satırı)', () {
      final all = [for (final p in catalog.provinces) ...p.districts];
      expect(all, hasLength(922));
      expect(all.where((d) => d.name == 'Merkez'), isEmpty);
      // Büyükşehirlerde Merkez ilçe yok; diğerlerinde il merkezi onun yerine
      expect(province('İstanbul').districts, hasLength(39));
      expect(province('Ankara').districts, hasLength(25));
      expect(province('İzmir').districts, hasLength(30));
      expect(province('Konya').districts, hasLength(31));
      expect(province('Erzincan').districts, hasLength(8));
      for (final p in catalog.provinces) {
        final names = p.districts.map((d) => d.name).toList();
        expect(names.toSet(), hasLength(names.length), reason: p.name);
        expect(names, [...names]..sort(_trCompare), reason: p.name);
        expect(p.center.district, isNull);
        for (final d in p.districts) {
          expect(d.province, p.name);
          expect(d.city, p.name);
          expect(d.district, d.name);
        }
      }
      // Türkçe harfler korunmuş (ASCII'ye çevrilmemiş)
      for (final name in ['Kadıköy', 'Üsküdar', 'Şişli', 'Beşiktaş']) {
        expect(district('İstanbul', name).name, name);
      }
      expect(district('Ankara', 'Çankaya').name, 'Çankaya');
      expect(district('Samsun', '19 Mayıs').name, '19 Mayıs');
      final letters = RegExp(r"^[A-Za-zÇĞİÖŞÜçğıöşüâîû0-9 ]+$");
      for (final p in catalog.provinces) {
        expect(letters.hasMatch(p.name), isTrue, reason: p.name);
        for (final d in p.districts) {
          expect(letters.hasMatch(d.name), isTrue, reason: d.name);
        }
      }
    });

    test('koordinatlar Türkiye içinde, ilçe kendi ilinin yakınında', () {
      final (minLat, maxLat, minLng, maxLng) = _bbox['TR']!;
      for (final p in catalog.provinces) {
        for (final place in [p.center, ...p.districts]) {
          expect(
            place.lat,
            inInclusiveRange(minLat, maxLat),
            reason: place.name,
          );
          expect(
            place.lng,
            inInclusiveRange(minLng, maxLng),
            reason: place.name,
          );
          expect(place.country, 'TR');
        }
        for (final d in p.districts) {
          expect(
            _km(p.center, d),
            lessThan(250),
            reason: '${d.name}/${p.name}',
          );
        }
      }
    });
  });

  group('Avrupa ve KKTC', () {
    test('ülkeler, başkentler ve KKTC şehirleri', () {
      expect(catalog.countries.map((c) => c.code), [
        'DE', 'NL', 'BE', 'FR', 'AT', 'CH', 'GB', 'DK', 'SE', 'NO', 'KKTC', //
      ]);
      for (final (code, capital) in [
        ('DE', 'Berlin'),
        ('NL', 'Amsterdam'),
        ('BE', 'Bruxelles'),
        ('FR', 'Paris'),
        ('AT', 'Wien'),
        ('CH', 'Bern'),
        ('GB', 'London'),
        ('DK', 'København'),
        ('SE', 'Stockholm'),
        ('NO', 'Oslo'),
      ]) {
        expect(city(code, capital).country, code);
      }
      expect(catalog.countries.last.cities.map((c) => c.name).toSet(), {
        'Lefkoşa',
        'Girne',
        'Gazimağusa',
        'Güzelyurt',
        'İskele',
        'Lefke',
      });
      expect(
        catalog.countries.fold<int>(0, (n, c) => n + c.cities.length),
        greaterThan(600),
      );
      for (final c in catalog.countries) {
        final names = c.cities.map((e) => QuranService.searchKey(e.name));
        expect(names.toSet(), hasLength(c.cities.length), reason: c.code);
        expect(LocationCatalog.timeZones, contains(c.code));
        for (final e in c.cities) {
          expect(e.district, isNull);
          expect(e.city, e.name);
        }
      }
    });

    test('koordinatlar ülke sınır kutusunda', () {
      for (final c in catalog.countries) {
        final (minLat, maxLat, minLng, maxLng) = _bbox[c.code]!;
        for (final e in c.cities) {
          expect(e.lat, inInclusiveRange(minLat, maxLat), reason: e.name);
          expect(e.lng, inInclusiveRange(minLng, maxLng), reason: e.name);
        }
      }
    });
  });

  test('bilinen yerler ±0,1°', () {
    for (final (place, lat, lng) in [
      (district('İstanbul', 'Kadıköy'), 40.99, 29.03),
      (province('Erzincan').center, 39.75, 39.49),
      (district('Erzincan', 'Kemaliye'), 39.26, 38.50),
      (province('Ankara').center, 39.92, 32.85),
      (province('İstanbul').center, 41.01, 28.96),
      (city('DE', 'Köln'), 50.94, 6.96),
      (city('DE', 'Berlin'), 52.52, 13.40),
      (city('FR', 'Paris'), 48.86, 2.35),
      (city('GB', 'London'), 51.51, -0.13),
      (city('AT', 'Wien'), 48.21, 16.37),
      (city('KKTC', 'Lefkoşa'), 35.18, 33.36),
      (city('KKTC', 'Girne'), 35.34, 33.32),
    ]) {
      expect(place.lat, closeTo(lat, 0.1), reason: place.name);
      expect(place.lng, closeTo(lng, 0.1), reason: place.name);
    }
  });

  group('Arama', () {
    test('harf işareti ve büyük/küçük harf duyarsız anahtar', () {
      expect(QuranService.searchKey('KADIKÖY'), 'kadikoy');
      expect(QuranService.searchKey('Kadıköy'), 'kadikoy');
      expect(QuranService.searchKey('İSTANBUL'), 'istanbul');
      expect(QuranService.searchKey('Şanlıurfa'), 'sanliurfa');
      expect(QuranService.searchKey('Västerås'), 'vasteras');
      expect(QuranService.searchKey('Tønsberg'), 'tonsberg');
      expect(QuranService.searchKey('Ålesund'), 'alesund');
      expect(QuranService.searchKey('Næstved'), 'naestved');
    });

    test('önce adı tam tutan, sonra başlayan; il + ilçe birlikte', () {
      final kadikoy = catalog.search('kadikoy');
      expect(kadikoy.first.name, 'Kadıköy');
      expect(kadikoy.first.province, 'İstanbul');
      expect(catalog.search('KADIKÖY').first.name, 'Kadıköy');
      expect(catalog.search('ISTANBUL').first, province('İstanbul').center);
      expect(catalog.search('erzincan merkez').single.name, 'Erzincan');
      expect(catalog.search('Yenişehir').map((p) => p.province).toSet(), {
        'Bursa',
        'Diyarbakır',
        'Mersin',
      });
      expect(catalog.search('yenisehir mersin').single.province, 'Mersin');
      expect(catalog.search('xqzw'), isEmpty);
      expect(catalog.search('  '), isEmpty);
      expect(catalog.search('a'), hasLength(50));
    });

    test('yurt dışı şehirler başka dillerdeki adlarıyla da bulunur', () {
      for (final (query, name) in [
        ('Köln', 'Köln'),
        ('koln', 'Köln'),
        ('Cologne', 'Köln'),
        ('كولونيا', 'Köln'),
        ('Münih', 'München'),
        ('Munich', 'München'),
        ('Viyana', 'Wien'),
        ('Londra', 'London'),
        ('Brüksel', 'Bruxelles'),
        ('Lahey', 'Den Haag'),
        ('Kopenhag', 'København'),
        ('Cenevre', 'Genève'),
        ('Gothenburg', 'Göteborg'),
        ('Kyrenia', 'Girne'),
        ('Lefkosa', 'Lefkoşa'),
      ]) {
        expect(catalog.search(query).first.name, name, reason: query);
      }
    });
  });

  test('saat dilimi farkı: telefonun o anki UTC farkıyla karşılaştırılır', () {
    // Kış ve yaz (KKTC yazın Türkiye ile aynı, kışın 1 saat geri)
    final winter = DateTime(2026, 1, 15, 12);
    final summer = DateTime(2026, 7, 15, 12);
    for (final (country, winterHours, summerHours) in [
      ('TR', 3, 3),
      ('DE', 1, 2),
      ('GB', 0, 1),
      ('KKTC', 2, 3),
    ]) {
      expect(
        LocationCatalog.timeZoneDiffers(country, now: winter),
        winter.timeZoneOffset != Duration(hours: winterHours),
        reason: '$country kış',
      );
      expect(
        LocationCatalog.timeZoneDiffers(country, now: summer),
        summer.timeZoneOffset != Duration(hours: summerHours),
        reason: '$country yaz',
      );
    }
    expect(LocationCatalog.timeZoneDiffers('US'), isFalse);
  });
}
