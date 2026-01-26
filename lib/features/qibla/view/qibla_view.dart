import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vector_math/vector_math.dart' show radians;
import 'package:ezan_saati/l10n/app_localizations.dart';

class QiblaView extends StatefulWidget {
  const QiblaView({super.key});

  @override
  State<QiblaView> createState() => _QiblaViewState();
}

class _QiblaViewState extends State<QiblaView> {
  bool _hasPermissions = false;
  double _qiblaAngle = 0; // Kabe'nin açısı
  bool _isLoading = true;
  String? _errorMessage;

  // Mekke Koordinatları
  final double meccaLat = 21.422487;
  final double meccaLong = 39.826206;

  @override
  void initState() {
    super.initState();
    // Ekran çizildikten sonra işlemleri başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initQibla();
    });
  }

  Future<void> _initQibla() async {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Konum Servisi Açık mı?
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Servis kapalıysa kullanıcıdan açmasını iste
        // (Bazı telefonlarda direkt hata fırlatmak yerine null dönebilir)
        throw Exception(loc.locationServiceOff);
      }

      // 2. İzin Kontrolü
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(loc.locationPermissionDenied);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(loc.locationPermissionForever);
      }

      // 3. Konumu Al (Zaman Aşımı Ekli!)
      Position? position;
      try {
        // Önce 5 saniye içinde yüksek hassasiyetle bulmaya çalış
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        // Bulamazsa son bilinen konumu dene (Daha hızlıdır)
        position = await Geolocator.getLastKnownPosition();
      }

      // Eğer hala konum yoksa (GPS tamamen kapalı veya sinyal yok)
      if (position == null) {
        // Varsayılan olarak İstanbul veya 0 kabul edip açalım ki uygulama kilitlenmesin
        // Kullanıcıya uyarı verip devam ediyoruz
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Konum alınamadı, varsayılan değer kullanılıyor."),
            ),
          );
        }
        position = Position(
          longitude: 28.9784, // İstanbul (Varsayılan)
          latitude: 41.0082,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      // 4. Kıble Hesabı
      double latUser = radians(position.latitude);
      double longUser = radians(position.longitude);
      double latMecca = radians(meccaLat);
      double longMecca = radians(meccaLong);

      double longDiff = longMecca - longUser;
      double y = math.sin(longDiff) * math.cos(latMecca);
      double x =
          math.cos(latUser) * math.sin(latMecca) -
          math.sin(latUser) * math.cos(latMecca) * math.cos(longDiff);

      double result = math.atan2(y, x);
      double degrees = (result * 180 / math.pi + 360) % 360;

      if (mounted) {
        setState(() {
          _hasPermissions = true;
          _qiblaAngle = degrees;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll("Exception:", "").trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF2d3436),
      appBar: AppBar(
        title: Text(loc.qiblaTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(loc),
    );
  }

  Widget _buildBody(AppLocalizations loc) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.teal),
            const SizedBox(height: 20),
            Text(
              "Konum alınıyor...", // Bunu dil dosyasına ekleyebilirsin: loc.fetchingLocation
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_off,
                size: 80,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _initQibla,
                icon: const Icon(Icons.refresh),
                label: Text(loc.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (!_hasPermissions) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Sensör Hatası: ${snapshot.error}",
              style: const TextStyle(color: Colors.white),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        double? direction = snapshot.data?.heading;
        if (direction == null) {
          return Center(
            child: Text(
              loc.noCompass,
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        // Sapma ve Hizalama
        double sapma = (direction - _qiblaAngle).abs();
        if (sapma > 180) sapma = 360 - sapma;
        bool isAligned = sapma < 4;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "${direction.toStringAsFixed(0)}°",
                style: TextStyle(
                  color: isAligned ? Colors.greenAccent : Colors.white,
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isAligned
                    ? loc.qiblaFound
                    : loc.qiblaAngle(_qiblaAngle.toStringAsFixed(0)),
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),

              const SizedBox(height: 40),

              // --- PUSULA ---
              SizedBox(
                height: 300,
                width: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. DIŞ ÇEMBER
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1e272e),
                        border: Border.all(
                          color: isAligned
                              ? Colors.greenAccent
                              : Colors.white24,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),

                    // 2. DÖNEN KADRAN
                    Transform.rotate(
                      angle: (direction * (math.pi / 180) * -1),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        child: Stack(
                          children: const [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                "N",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Text(
                                "S",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "E",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "W",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            // Ara Yönler
                            Align(
                              alignment: Alignment(0.7, -0.7),
                              child: Icon(
                                Icons.circle,
                                size: 5,
                                color: Colors.white24,
                              ),
                            ),
                            Align(
                              alignment: Alignment(-0.7, -0.7),
                              child: Icon(
                                Icons.circle,
                                size: 5,
                                color: Colors.white24,
                              ),
                            ),
                            Align(
                              alignment: Alignment(0.7, 0.7),
                              child: Icon(
                                Icons.circle,
                                size: 5,
                                color: Colors.white24,
                              ),
                            ),
                            Align(
                              alignment: Alignment(-0.7, 0.7),
                              child: Icon(
                                Icons.circle,
                                size: 5,
                                color: Colors.white24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. KIBLE İKONU
                    Transform.rotate(
                      angle: ((_qiblaAngle - direction) * (math.pi / 180)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mosque,
                            size: 40,
                            color: isAligned
                                ? Colors.greenAccent
                                : Colors.amber,
                          ),
                          Container(
                            height: 80,
                            width: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  isAligned ? Colors.greenAccent : Colors.amber,
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 4. MERKEZ NOKTASI
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isAligned ? Colors.greenAccent : Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "${loc.keepAwayMetal}\n(Kalibrasyon için '8' çizin)",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
