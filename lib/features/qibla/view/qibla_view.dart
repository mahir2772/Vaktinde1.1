import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  double _qiblaAngle = 0;
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<CompassEvent>? _compassSubscription;

  // EFSANE MATEMATİK İÇİN DEĞİŞKENLER
  double _lastHeading = 0;
  double _smoothHeading =
      0; // 360'ı aşsa bile katlanarak büyür (Titremeyi %100 keser)

  bool _isAligned = false;
  bool _isCalibrationPoor = false;

  final double meccaLat = 21.422487;
  final double meccaLong = 39.826206;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _initQibla();
      });
    });
  }

  Future<Position?> _fetchPositionSafe() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          );
    } catch (_) {
      return null;
    }
  }

  Future<void> _initQibla() async {
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    Position? position;

    try {
      position = await _fetchPositionSafe().timeout(const Duration(seconds: 5));
    } catch (_) {
      position = null;
    }

    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.locationFallbackMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      position = Position(
        longitude: 28.9784,
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

    try {
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
        _startCompass();
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

  void _startCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (!mounted) return;

      double heading = event.heading ?? 0;

      // SİHİRLİ MATEMATİK: 359'dan 0'a geçerken yaşanan kopmayı engeller
      double diff = heading - _lastHeading;
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;

      _lastHeading = heading;
      _smoothHeading +=
          diff; // Asla sıfırlanmaz, sürekli eklenir (lag olmadan pürüzsüz dönüş)

      double sapma = (heading - _qiblaAngle).abs();
      if (sapma > 180) sapma = 360 - sapma;

      bool nowAligned = sapma < 4;
      if (nowAligned && !_isAligned) {
        HapticFeedback.heavyImpact();
      }

      setState(() {
        _isAligned = nowAligned;
        _isCalibrationPoor = (event.accuracy != null && event.accuracy! > 15);
      });
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF1e272e),
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
            const CircularProgressIndicator(color: Colors.tealAccent),
            const SizedBox(height: 20),
            Text(
              loc.fetchingLocation,
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
                onPressed: () {
                  setState(() => _isLoading = true);
                  _initQibla();
                },
                icon: const Icon(Icons.refresh),
                label: Text(loc.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasPermissions) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              loc.qiblaDirection,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              _isAligned
                  ? loc.qiblaFound
                  : "${(_smoothHeading % 360).toStringAsFixed(0)}°",
              style: TextStyle(
                color: _isAligned ? Colors.greenAccent : Colors.white,
                fontSize: 45,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            Center(
              child: SizedBox(
                height: 320,
                width: 320,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // GECİKMESİZ, ANLIK SAF HIZ - Transform.rotate
                    Transform.rotate(
                      angle: -_smoothHeading * (math.pi / 180),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isAligned
                                ? Colors.greenAccent
                                : Colors.white12,
                            width: 3,
                          ),
                          color: const Color(0xFF2d3436),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  loc.directionNorth,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  loc.directionSouth,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  loc.directionEast,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  loc.directionWest,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            // KIBLE OKU
                            Transform.rotate(
                              angle: _qiblaAngle * (math.pi / 180),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 40),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.navigation,
                                        size: 60,
                                        color: _isAligned
                                            ? Colors.greenAccent
                                            : Colors.tealAccent,
                                      ),
                                      const SizedBox(height: 5),
                                      const Icon(
                                        Icons.mosque,
                                        size: 30,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isAligned
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // --- YENİ EKLENEN: ŞIK KALİBRASYON BİLGİ KARTI ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(
                    0.05,
                  ), // Hafif şeffaf arka plan
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.screen_rotation,
                      color: Colors.tealAccent,
                      size: 28,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        loc.qiblaCalibration, // Dil dosyasından çeviriyi çeker
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ------------------------------------------------
          ],
        ),

        // EĞER SENSÖR AŞIRI SAPARSA ÇIKAN KIRMIZI ACİL DURUM UYARISI (Bozulmadı)
        if (_isCalibrationPoor)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      loc.lowAccuracyWarning,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
