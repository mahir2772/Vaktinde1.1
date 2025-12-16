import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vector_math/vector_math.dart' show radians;

class QiblaView extends StatefulWidget {
  const QiblaView({super.key});

  @override
  State<QiblaView> createState() => _QiblaViewState();
}

class _QiblaViewState extends State<QiblaView> {
  bool _hasPermissions = false;
  double _qiblaAngle = 0; // Kabe'nin coğrafi açısı

  // Mekke Koordinatları
  final double meccaLat = 21.422487;
  final double meccaLong = 39.826206;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndCalculate();
  }

  Future<void> _checkPermissionsAndCalculate() async {
    // 1. İzinleri Kontrol Et
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // 2. Kıble Açısını Hesapla
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2d3436), // Koyu Gri Arka Plan
      appBar: AppBar(
        title: const Text("Kıble Pusulası"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<CompassEvent>(
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
                "Sensör hatası: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          // Yön Bilgisi
          double? direction = snapshot.data?.heading;
          if (direction == null) {
            return const Center(
              child: Text(
                "Cihazda pusula yok.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Doğruluk Kontrolü (Yeşil Işık)
          // Kıble ile telefon yönü arasındaki fark azsa yeşil yap
          double sapma = (direction - _qiblaAngle).abs();
          bool isAligned = sapma < 5 || sapma > 355;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // DERECE GÖSTERGESİ
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
                      ? "KIBLEYİ BULDUNUZ!"
                      : "Kıble Açısı: ${_qiblaAngle.toStringAsFixed(0)}°",
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),

                const SizedBox(height: 50),

                // --- PUSULA GÖVDESİ ---
                SizedBox(
                  height: 300,
                  width: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. DIŞ ÇEMBER (SÜS)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),

                      // 2. DÖNEN KADRAN (N, S, E, W YAZILARI)
                      AnimatedRotation(
                        turns: (direction / 360) * -1, // Telefonun tersine dön
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF1e272e), // Pusula içi
                          ),
                          child: Stack(
                            children: const [
                              Align(
                                alignment: Alignment.topCenter,
                                child: Text(
                                  "N",
                                  style: TextStyle(
                                    color: Colors.red,
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
                            ],
                          ),
                        ),
                      ),

                      // 3. KIBLE İĞNESİ (KABE'Yİ GÖSTERİR)
                      // Bu iğne pusula kadranının üstünde döner
                      AnimatedRotation(
                        turns: (_qiblaAngle - direction) / 360,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 50,
                              color: isAligned
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                            ),
                            Container(
                              height: 100,
                              width: 2,
                              color: Colors.transparent,
                            ), // Boşluk
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),
                const Text(
                  "Metal eşyalardan uzak tutun.",
                  style: TextStyle(color: Colors.white30),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
