import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'quran_service.dart';

/// Gömülü listedeki yer: il merkezi, ilçe ya da yurt dışı şehir. Seçim mevcut
/// konum akışıyla kaydedilir ([city] il/şehir, [district] sadece Türkiye ilçesi).
class LocationPlace {
  final String name;
  final double lat;
  final double lng;

  /// 'TR', Avrupa ülkesinin ISO kodu ya da 'KKTC'
  final String country;

  /// Türkiye ilçesinin ili (il merkezi ve yurt dışı şehirde null)
  final String? province;

  /// Başka dillerdeki adlar, sadece aramada (Münih, Cologne, كولونيا)
  final List<String> aliases;

  const LocationPlace({
    required this.name,
    required this.lat,
    required this.lng,
    required this.country,
    this.province,
    this.aliases = const [],
  });

  String get city => province ?? name;
  String? get district => province == null ? null : name;
}

/// Türkiye ili: il merkezi (Merkez ilçe) + diğer ilçeler (Türkçe sırada)
class LocationProvince {
  final LocationPlace center;
  final List<LocationPlace> districts;

  const LocationProvince(this.center, this.districts);

  String get name => center.name;
}

class LocationCountry {
  final String code;
  final List<LocationPlace> cities;

  const LocationCountry(this.code, this.cities);
}

/// İnternetsiz konum listesi (assets/data/locations.json): Türkiye 81 il ve
/// 922 ilçe (51 "Merkez" ilçe il merkezinin kendisi), Avrupa'da ~50 bin üstü
/// şehirler + başkent/eyalet merkezleri ve KKTC. Kaynak ve lisans:
/// assets/data/locations_LICENSE.txt (GeoNames CC BY 4.0, dr5hn ODbL 1.0).
class LocationCatalog {
  static const asset = 'assets/data/locations.json';

  final List<LocationProvince> provinces;
  final List<LocationCountry> countries;

  /// Arama dizini: il merkezleri, ilçeler, yurt dışı şehirler sırasıyla
  final List<({LocationPlace place, String key, List<String> other})> _index;

  LocationCatalog(this.provinces, this.countries)
    : _index = [
        for (final p in provinces) _entry(p.center, ['${p.name} Merkez']),
        for (final p in provinces)
          for (final d in p.districts)
            _entry(d, ['${d.name} ${p.name}', '${p.name} ${d.name}']),
        for (final c in countries)
          for (final city in c.cities) _entry(city, city.aliases),
      ];

  static ({LocationPlace place, String key, List<String> other}) _entry(
    LocationPlace place,
    List<String> other,
  ) => (
    place: place,
    key: QuranService.searchKey(place.name),
    other: [for (final o in other) QuranService.searchKey(o)],
  );

  /// Dosya biçimi: {"tr": [[il, lat, lng, [[ilçe, lat, lng], ...]], ...],
  /// "countries": [[kod, [[şehir, lat, lng, [eş adlar]?], ...]], ...]}
  factory LocationCatalog.fromJson(Map<String, dynamic> json) {
    LocationPlace place(
      List<dynamic> row,
      String country, {
      String? province,
    }) => LocationPlace(
      name: row[0] as String,
      lat: (row[1] as num).toDouble(),
      lng: (row[2] as num).toDouble(),
      country: country,
      province: province,
      aliases: row.length > 3 ? List<String>.from(row[3] as List) : const [],
    );
    return LocationCatalog(
      [
        for (final p in json['tr'] as List)
          LocationProvince(place([p[0], p[1], p[2]], 'TR'), [
            for (final d in p[3] as List)
              place(d as List, 'TR', province: p[0] as String),
          ]),
      ],
      [
        for (final c in json['countries'] as List)
          LocationCountry(c[0] as String, [
            for (final city in c[1] as List)
              place(city as List, c[0] as String),
          ]),
      ],
    );
  }

  /// Harf işareti ve büyük/küçük harf yok sayılır (Kur'an listesindeki arama).
  /// Sıra: adı aynı, adı sorguyla başlayan, adında geçen, başka adı (eş ad,
  /// "İlçe İl") sorguyla başlayan; aynı sırada liste sırası.
  List<LocationPlace> search(String query, {int limit = 50}) {
    final q = QuranService.searchKey(query);
    if (q.isEmpty) return const [];
    final ranked = <List<LocationPlace>>[[], [], [], []];
    for (final e in _index) {
      final rank = e.key == q
          ? 0
          : e.key.startsWith(q)
          ? 1
          : e.key.contains(q)
          ? 2
          : e.other.any((o) => o.startsWith(q))
          ? 3
          : null;
      if (rank != null) ranked[rank].add(e.place);
    }
    return ranked.expand((r) => r).take(limit).toList();
  }

  static Future<LocationCatalog>? _cache;
  static LocationCatalog? _loaded;

  /// Yüklendiyse liste (ilk karede yükleniyor görünmesin)
  static LocationCatalog? get loaded => _loaded;

  /// Bir kez okunur; hata olursa sonraki çağrı yeniden dener
  static Future<LocationCatalog> load() => _cache ??= _read();

  static Future<LocationCatalog> _read() async {
    try {
      final raw = await rootBundle.loadString(asset);
      return _loaded = LocationCatalog.fromJson(
        json.decode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      _cache = null;
      rethrow;
    }
  }

  /// Ülkenin saat dilimi (KKTC: Asia/Famagusta)
  static const timeZones = {
    'TR': 'Europe/Istanbul',
    'DE': 'Europe/Berlin',
    'NL': 'Europe/Amsterdam',
    'BE': 'Europe/Brussels',
    'FR': 'Europe/Paris',
    'AT': 'Europe/Vienna',
    'CH': 'Europe/Zurich',
    'GB': 'Europe/London',
    'DK': 'Europe/Copenhagen',
    'SE': 'Europe/Stockholm',
    'NO': 'Europe/Oslo',
    'KKTC': 'Asia/Famagusta',
  };

  /// Vakitler telefonun saatiyle gösterilir: ülkenin şu anki UTC farkı
  /// telefonunkinden farklıysa true (bilinmeyen ülke: false)
  static bool timeZoneDiffers(String country, {DateTime? now}) {
    final zone = timeZones[country];
    if (zone == null) return false;
    try {
      if (!tz.timeZoneDatabase.isInitialized) tzdata.initializeTimeZones();
      final local = (now ?? DateTime.now()).toLocal();
      final there = tz.TZDateTime.from(local, tz.getLocation(zone));
      return there.timeZoneOffset != local.timeZoneOffset;
    } catch (_) {
      return false;
    }
  }
}
