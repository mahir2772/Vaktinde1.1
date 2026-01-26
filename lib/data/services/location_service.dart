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
