import 'package:adhan_dart/adhan_dart.dart';

/// Kıble yönü hesapları (saf; arayüzden bağımsız, test edilebilir).

/// Konumdan Kâbe'ye yön: kuzeyden saat yönünde derece (0..360).
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
