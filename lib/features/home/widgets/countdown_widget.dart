import 'dart:async';
import 'package:flutter/material.dart';
// --- DİL İMPORTU ---
import 'package:ezan_saati/l10n/app_localizations.dart';
// -------------------
import '../../../data/models/prayer_times_model.dart';

class CountdownWidget extends StatefulWidget {
  final PrayerTimesModel prayerTimes;

  const CountdownWidget({super.key, required this.prayerTimes});

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  // Ekranda gösterilecek çevrilmiş metin
  String _displayNextVakitIsmi = "";

  @override
  void initState() {
    super.initState();
    // İlk hesaplamayı build içinde yapacağız çünkü context (dil) lazım
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Timer her tetiklendiğinde hesaplama yapacak
          // (Hesaplama build içinde çağrılan helper ile yapılacak)
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- HESAPLAMA FONKSİYONU (Artık 'loc' alıyor) ---
  void _calculateNextPrayer(AppLocalizations loc) {
    if (widget.prayerTimes.imsak == null) return;

    final now = DateTime.now();

    // LogicKey (Değişmez) -> Zaman Eşleşmesi
    Map<String, String> vakitler = {
      "İmsak": widget.prayerTimes.imsak!,
      "Güneş": widget.prayerTimes.gunes!,
      "Öğle": widget.prayerTimes.ogle!,
      "İkindi": widget.prayerTimes.ikindi!,
      "Akşam": widget.prayerTimes.aksam!,
      "Yatsı": widget.prayerTimes.yatsi!,
    };

    DateTime? targetDate;
    String targetLogicKey = ""; // "İmsak", "Güneş" vs. (TR)
    bool isTomorrow = false;

    for (var entry in vakitler.entries) {
      List<String> parts = entry.value.split(':');
      DateTime vakitDate = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      if (vakitDate.isAfter(now)) {
        targetDate = vakitDate;
        targetLogicKey = entry.key;
        break;
      }
    }

    if (targetDate == null) {
      List<String> parts = widget.prayerTimes.imsak!.split(':');
      targetDate = DateTime(
        now.year,
        now.month,
        now.day + 1,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      targetLogicKey = "İmsak";
      isTomorrow = true;
    }

    _remainingTime = targetDate.difference(now);

    // --- İSMİ ÇEVİRME ---
    String translatedName = _getLocalizedName(targetLogicKey, loc);
    if (isTomorrow) {
      translatedName = "$translatedName ${loc.tomorrow}"; // "Fajr (Tomorrow)"
    }

    _displayNextVakitIsmi = translatedName;
  }

  // Helper: TR Anahtarı -> Çevrilmiş İsim
  String _getLocalizedName(String key, AppLocalizations loc) {
    switch (key) {
      case "İmsak":
        return loc.imsak;
      case "Güneş":
        return loc.gunes;
      case "Öğle":
        return loc.ogle;
      case "İkindi":
        return loc.ikindi;
      case "Akşam":
        return loc.aksam;
      case "Yatsı":
        return loc.yatsi;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dil nesnesini al
    final loc = AppLocalizations.of(context)!;

    // Her frame'de (ve timer tick'inde) hesapla
    _calculateNextPrayer(loc);

    String formatDuration(Duration d) {
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String hours = twoDigits(d.inHours);
      String minutes = twoDigits(d.inMinutes.remainder(60));
      String seconds = twoDigits(d.inSeconds.remainder(60));
      return "$hours:$minutes:$seconds";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30, width: 1),
      ),
      child: Column(
        children: [
          Text(
            // Çeviri: "{vakit} Vaktine Kalan" -> "Time left for Fajr"
            loc.timeLeftFor(_displayNextVakitIsmi),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            formatDuration(_remainingTime),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: "Courier",
            ),
          ),
        ],
      ),
    );
  }
}
