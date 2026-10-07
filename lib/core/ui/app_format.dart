// Vakit ve süre biçimleri (tüm ekranlarda aynı).

bool _uses12Hour(String localeName) =>
    localeName.startsWith('en') || localeName.startsWith('ar');

/// "HH:mm" (24 saat) → dile göre gösterim.
/// en/ar: 12 saat, saat sıfırla doldurulmaz ("4:08 PM", "4:08 م");
/// diğerleri: 24 saat ("16:08"). Okunamayan değer olduğu gibi döner.
String formatPrayerTime(String hhmm, String localeName) {
  final parts = hhmm.trim().split(':');
  if (parts.length < 2) return hhmm;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null || hour < 0 || hour > 23) return hhmm;
  final mm = minute.toString().padLeft(2, '0');
  if (!_uses12Hour(localeName)) {
    return '${hour.toString().padLeft(2, '0')}:$mm';
  }
  final pm = hour >= 12;
  var h12 = hour % 12;
  if (h12 == 0) h12 = 12;
  final suffix = localeName.startsWith('ar')
      ? (pm ? 'م' : 'ص')
      : (pm ? 'PM' : 'AM');
  return '$h12:$mm $suffix';
}

/// [DateTime] saatini [formatPrayerTime] ile aynı biçimde yazar
String formatClockTime(DateTime t, String localeName) => formatPrayerTime(
  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
  localeName,
);

/// Geri sayım: "02:05:09" (negatif süre 00:00:00)
String formatCountdown(Duration d) {
  var total = d.inSeconds;
  if (total < 0) total = 0;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(total ~/ 3600)}:${two((total % 3600) ~/ 60)}:${two(total % 60)}';
}
