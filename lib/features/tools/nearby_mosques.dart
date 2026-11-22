import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ezan_saati/data/services/storage_service.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

/// Yakındaki camiler için açılacak adresler, deneme sırasıyla: harita
/// uygulamasında arama (geo:, koordinat yoksa 0,0 → uygulama kendi konumunu
/// kullanır), geo: açan uygulama yoksa Google Haritalar web araması (Maps
/// URLs, api=1; konum sorgu metninde).
List<Uri> nearbyMosqueUris(String term, ({double lat, double lng})? coords) {
  final at = coords == null
      ? null
      : '${coords.lat.toStringAsFixed(5)},${coords.lng.toStringAsFixed(5)}';
  return [
    Uri.parse('geo:${at ?? '0,0'}?q=${Uri.encodeComponent(term)}'),
    Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': at == null ? term : '$term near $at',
    }),
  ];
}

/// Kayıtlı konum çevresindeki camileri cihazın harita uygulamasında açar.
/// Uygulama dışına çıkar: geçiş reklamı gösterilmez. Hiçbiri açılamazsa
/// SnackBar. launchUrl doğrudan startActivity çağırır (canLaunchUrl yok),
/// bu yüzden manifest'te `<queries>` gerekmez.
Future<void> openNearbyMosques(BuildContext context) async {
  final loc = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final coords = await StorageService().loadCoordinates();
  for (final uri in nearbyMosqueUris(loc.nearbyMosquesQuery, coords)) {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (e) {
      // Açan uygulama yok (ACTIVITY_NOT_FOUND): sıradaki adres denenir
      debugPrint("Harita açılamadı (${uri.scheme})");
    }
  }
  messenger.showSnackBar(SnackBar(content: Text(loc.nearbyMosquesError)));
}
