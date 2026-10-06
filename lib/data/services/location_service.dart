import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  Future<Position?> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // Konumu getir
    return await Geolocator.getCurrentPosition();
  }

  /// Manuel seçilen il/ilçenin koordinatı (cihaz geocoder'ı, internet ister).
  Future<({double lat, double lng})?> getCoordinatesFromAddress(
    String city,
    String? district,
  ) async {
    final queries = [
      if (district != null && district.trim().isNotEmpty)
        '${district.trim()}, ${city.trim()}, Türkiye',
      '${city.trim()}, Türkiye',
    ];
    for (final query in queries) {
      try {
        final locations = await locationFromAddress(query);
        if (locations.isNotEmpty) {
          return (
            lat: locations.first.latitude,
            lng: locations.first.longitude,
          );
        }
      } catch (e) {
        // Sonraki sorguyu dene
      }
    }
    return null;
  }

  // --- İŞTE EKSİK OLAN FONKSİYON BU ---
  Future<Map<String, String>?> getCityAndDistrictFromCoordinates(
    double lat,
    double long,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // AdministrativeArea = İl (Örn: Erzincan)
        // SubAdministrativeArea = İlçe (Örn: Merkez, Kemaliye) veya Locality

        String? city = place.administrativeArea;
        String? district = place.subAdministrativeArea;

        // Bazen geocoder ilçe bulamazsa 'locality' kullanabiliriz
        if (district == null || district.isEmpty) {
          district = place.locality;
        }

        if (city != null && city.isNotEmpty) {
          return {
            'city': city,
            'district': district ?? '', // İlçe yoksa boş string gönder
          };
        }
      }
      return null;
    } catch (e) {
      print("Adres bulma hatası: $e");
      return null;
    }
  }
}
