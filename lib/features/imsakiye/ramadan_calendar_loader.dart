import '../../data/services/json_service.dart';
import 'imsakiye_logic.dart';

Future<RamadanCalendar>? _cache;

/// Diyanet tarihleri (religious_days.json) uygulama boyunca bir kez okunur;
/// okunamazsa hijri paketi hesabına düşülür.
Future<RamadanCalendar> loadRamadanCalendar() => _cache ??= _read();

Future<RamadanCalendar> _read() async {
  try {
    return RamadanCalendar.fromReligiousDays(
      await JsonService().getReligiousDays(),
    );
  } catch (_) {
    return RamadanCalendar.hijriOnly;
  }
}
