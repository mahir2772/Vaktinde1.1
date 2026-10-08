import 'dart:math' as math;

import 'package:adhan_dart/adhan_dart.dart';

/// Kıble yönü hesapları (saf; arayüzden bağımsız, test edilebilir).

/// Konumdan Kâbe'ye yön: coğrafi kuzeyden saat yönünde derece (0..360).
/// İstanbul ≈ 151,6°.
double qiblaBearing(double latitude, double longitude) =>
    normalizeDegrees(Qibla.qibla(Coordinates(latitude, longitude)));

/// Açıyı 0..360 aralığına getirir (pusula -180..180 de verebilir)
double normalizeDegrees(double degrees) {
  final value = degrees % 360;
  return value < 0 ? value + 360 : value;
}

/// [from] yönünden [to] yönüne en kısa dönüş (-180..180).
/// Pozitif: saat yönünde (sağa), negatif: sola.
double signedDelta(double from, double to) {
  var diff = normalizeDegrees(to) - normalizeDegrees(from);
  if (diff > 180) diff -= 360;
  if (diff < -180) diff += 360;
  return diff;
}

/// Pusula doğruluğu (± derece) zayıf ya da bilinmiyor mu. Android eklentisi
/// yüksek/orta/düşük için 15/30/45 verir, güvenilmez/bilinmeyende null;
/// sadece "yüksek" (≤15°) yeterli sayılır.
bool compassAccuracyPoor(double? accuracy) =>
    accuracy == null || accuracy <= 0 || accuracy > 15;

/// Manyetometre doğruluğu (SensorManager: 0 güvenilmez, 1 düşük, 2 orta,
/// 3 yüksek) kalibrasyon istiyor mu: sadece 0 ve 1. Bilinmiyorsa (null) karar
/// pusula doğruluğuna kalır.
bool magnetometerAccuracyPoor(int? accuracy) => accuracy == 0 || accuracy == 1;

/// Kalibrasyon uyarısı kararı: pusula doğruluğu zayıf/bilinmiyor ya da
/// manyetometre kalibrasyon istiyor. Eklentinin doğruluğu kayıtlı tüm
/// sensörlerin (ivmeölçer dahil) son durumudur; manyetometreninki ayrıca okunur.
bool calibrationPoor({double? compassAccuracy, int? magnetometerAccuracy}) =>
    compassAccuracyPoor(compassAccuracy) ||
    magnetometerAccuracyPoor(magnetometerAccuracy);

enum QiblaTurn { aligned, slightRight, right, slightLeft, left }

/// Telefon yönü [heading] iken kıbleye ([bearing]) dönmek için yönerge.
/// 4°'den az sapma "bulundu", 15°'ye kadar "biraz" dön.
QiblaTurn qiblaTurnFor(double heading, double bearing) {
  final diff = signedDelta(heading, bearing);
  if (diff.abs() < 4) return QiblaTurn.aligned;
  if (diff > 15) return QiblaTurn.right;
  if (diff > 0) return QiblaTurn.slightRight;
  if (diff < -15) return QiblaTurn.left;
  return QiblaTurn.slightLeft;
}

// --- Manyetik kuzey düzeltmesi ---

/// Konumun Dünya Manyetik Modeli değerleri (MainActivity 'geomagnetic')
class Geomagnetic {
  /// Manyetik sapma (derece, doğu +): coğrafi yön = manyetik yön + sapma
  final double declination;

  /// Beklenen alan şiddeti (µT); bilinmiyorsa parazit denetimi yapılmaz
  final double? strength;

  const Geomagnetic({required this.declination, this.strength});

  /// Kanal yanıtı {'declination': derece, 'strength': µT}; sapma okunamazsa
  /// null (düzeltme yapılmaz)
  static Geomagnetic? tryParse(Object? data) {
    if (data is! Map) return null;
    final declination = data['declination'];
    if (declination is! num ||
        !declination.isFinite ||
        declination.abs() > 180) {
      return null;
    }
    final strength = data['strength'];
    return Geomagnetic(
      declination: declination.toDouble(),
      strength: strength is num && strength.isFinite && strength > 0
          ? strength.toDouble()
          : null,
    );
  }
}

/// Manyetik model önbelleğinin konum hücresi: koordinat 0,1°'ye yuvarlanır
/// (~11 km; sapma bu mesafede fark edilmeyecek kadar az değişir)
String geomagneticCell(double latitude, double longitude) =>
    '${(latitude * 10).round()}:${(longitude * 10).round()}';

/// Pusulanın manyetik kuzeye göre yönü → coğrafi kuzeye göre yön (kıble açısı
/// coğrafi kuzeye göredir). Sapma bilinmiyorsa düzeltme yapılmaz.
double trueHeading(double magneticHeading, double? declination) =>
    normalizeDegrees(magneticHeading + (declination ?? 0));

/// Sapma metni: tam dereceye yuvarlanır; doğu "+6", batı "-6", "0"
String formatDeclination(double declination) {
  final value = declination.round();
  return value > 0 ? '+$value' : '$value';
}

// --- Titreşim süzgeci ---

/// Yön süzgecinde olay başına yeni okumanın payı. Eklenti ~30 Hz (32 ms)
/// verir: dönüşün %95'i ~0,35 sn'de tamamlanır, 30°'lik dönüş ~0,5 sn'de
/// 0,5°'ye kadar oturur; el titremesi ~üçte birine iner.
const double headingSmoothing = 0.25;

/// Dairesel alçak geçiren süzgecin durumu: yönün birim çemberdeki (sin, cos)
/// karşılığının üstel ortalaması (359° ile 1° arası 180°'ye savrulmaz)
typedef HeadingFilter = ({double sin, double cos});

/// [state]'e yeni [heading] okumasını katar. İlk okumada (null) ya da zıt
/// okumalar birbirini sıfırlarsa (yön tanımsız) süzgeç okumadan başlar.
HeadingFilter smoothHeading(
  HeadingFilter? state,
  double heading, {
  double alpha = headingSmoothing,
}) {
  final radians = heading * math.pi / 180;
  final HeadingFilter reading = (
    sin: math.sin(radians),
    cos: math.cos(radians),
  );
  if (state == null) return reading;
  final HeadingFilter next = (
    sin: state.sin + alpha * (reading.sin - state.sin),
    cos: state.cos + alpha * (reading.cos - state.cos),
  );
  if (next.sin * next.sin + next.cos * next.cos < 1e-6) return reading;
  return next;
}

/// Süzgeç durumundaki yön (0..360)
double filteredHeading(HeadingFilter state) =>
    normalizeDegrees(math.atan2(state.sin, state.cos) * 180 / math.pi);

// --- Manyetik parazit ---

/// Manyetometre olayı (MainActivity 'vaktinde/magnetic'): alan şiddeti (µT) ve
/// SensorManager doğruluğu (0..3; bilinmiyorsa null)
typedef MagneticReading = ({double magnitude, int? accuracy});

/// Kanal olayı [şiddet, doğruluk] (-1: bilinmiyor); okunamazsa null
MagneticReading? parseMagneticReading(Object? event) {
  if (event is! List || event.length < 2) return null;
  final magnitude = event[0];
  if (magnitude is! num || !magnitude.isFinite || magnitude < 0) return null;
  final accuracy = event[1];
  final status = accuracy is num && accuracy.isFinite ? accuracy.toInt() : -1;
  return (
    magnitude: magnitude.toDouble(),
    accuracy: status >= 0 && status <= 3 ? status : null,
  );
}

/// Alan şiddeti beklenenden bu oranda saparsa parazit sayılır (mıknatıslı
/// kılıf, metal eşya, elektronik cihaz)
const double interferenceEnter = 0.25;

/// Uyarı açıkken sapma bunun altına inmeden parazit sürer (eşikte yanıp
/// sönmesin)
const double interferenceExit = 0.15;

/// Ölçülen şiddetin beklenene göre göreli sapması (|ölçülen/beklenen − 1|);
/// beklenen bilinmiyorsa ya da ölçüm geçersizse null
double? fieldDeviation(double measured, double? expected) {
  if (expected == null || !(expected > 0)) return null;
  if (!measured.isFinite || measured < 0) return null;
  return (measured / expected - 1).abs();
}

/// Bu ölçüm parazit sayılır mı. Histerezis: uyarı kapalıyken sapma %25'i
/// aşmalı; açıkken %15'in altına inene kadar parazit sürer.
bool magneticInterference(double deviation, {required bool warning}) =>
    warning ? deviation >= interferenceExit : deviation > interferenceEnter;
