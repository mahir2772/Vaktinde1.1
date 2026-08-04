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

class _QiblaViewState extends State<QiblaView> with TickerProviderStateMixin {
  bool _hasPermissions = false;
  double _qiblaAngle = 0;
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<CompassEvent>? _compassSubscription;

  // EFSANE MATEMATİK İÇİN DEĞİŞKENLER
  double _lastHeading = 0;
  double _smoothHeading = 0;

  bool _isAligned = false;
  bool _isCalibrationPoor = false;

  // DİALOG KONTROLLERİ
  bool _hasCheckedCalibrationOnce = false;
  bool _showInPageDialog =
      false; // YENİ: Kutu sadece bu sayfanın içinde açılacak

  final double meccaLat = 21.422487;
  final double meccaLong = 39.826206;

  late AnimationController _calibController;

  @override
  void initState() {
    super.initState();

    _calibController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

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

      // PAT DİYE İZİN İSTEYEN KODLARI SİLDİK.
      // İzni Showcase bittikten sonra main.dart bizzat isteyecek.
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

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

      double diff = heading - _lastHeading;
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;

      _lastHeading = heading;
      _smoothHeading += diff;

      double sapma = (heading - _qiblaAngle).abs();
      if (sapma > 180) sapma = 360 - sapma;

      bool nowAligned = sapma < 4;
      if (nowAligned && !_isAligned) {
        HapticFeedback.heavyImpact();
      }

      bool isPoor =
          event.accuracy == null ||
          event.accuracy! <= 0 ||
          event.accuracy! > 15;

      // Global showDialog yerine sadece bu sayfanın içinde tetiklenen kutuyu açıyoruz
      if (isPoor && !_hasCheckedCalibrationOnce) {
        _hasCheckedCalibrationOnce = true;
        setState(() {
          _showInPageDialog = true;
        });
      }

      setState(() {
        _isAligned = nowAligned;
        _isCalibrationPoor = isPoor;
      });
    });
  }

  String _getTurnInstruction() {
    double current = _smoothHeading % 360;
    if (current < 0) current += 360;

    double diff = _qiblaAngle - current;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;

    if (diff > 15) return "Sağa dön ➔";
    if (diff > 4) return "Hafif sağa dön ➔";
    if (diff < -15) return "⬅ Sola dön";
    if (diff < -4) return "⬅ Hafif sola dön";
    return "";
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _calibController.dispose();
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
        // ANA KIBLE ARAYÜZÜ
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

            SizedBox(
              height: 30,
              child: (!_isAligned && !_isCalibrationPoor)
                  ? Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        _getTurnInstruction(),
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
            const SizedBox(height: 10),

            Center(
              child: SizedBox(
                height: 320,
                width: 320,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
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
                        loc.qiblaCalibration,
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
          ],
        ),

        // KIRMIZI KÜÇÜK ANİMASYON UYARISI
        if (_isCalibrationPoor)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: AnimatedBuilder(
              animation: _calibController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.95 + (_calibController.value * 0.05),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(
                            0.6 * _calibController.value,
                          ),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Transform.rotate(
                          angle:
                              math.sin(_calibController.value * math.pi * 2) *
                              0.4,
                          child: const Icon(
                            Icons.screen_rotation_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            loc.lowAccuracyWarning,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        // YENİ: EKRANA GÖMÜLÜ DİALOG (Asla diğer sayfalara taşmaz)
        if (_showInPageDialog)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(
                0.8,
              ), // Arkadaki Kıbleyi hafif karartır
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2d3436),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.redAccent,
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Kalibrasyon Gerekli",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Icon(
                        Icons.screen_rotation,
                        color: Colors.tealAccent,
                        size: 65,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        loc.lowAccuracyWarning,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _showInPageDialog =
                                  false; // Tıklayınca kutuyu kapatır
                            });
                          },
                          child: Text(
                            loc.localeName.startsWith('tr')
                                ? "Tamam, Anladım"
                                : "OK",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
