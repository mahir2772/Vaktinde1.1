// countdown_widget.dart (Revize Edilmiş Hali)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
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
  String _displayNextVakitIsmi = "";
  AppLocalizations? _loc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loc = AppLocalizations.of(context);
    _calculateAndSetState(); // İlk açılışta hesapla
  }

  @override
  void initState() {
    super.initState();
    // Hesaplama mantığı build'den çıkarılıp timer'ın içine alındı
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _loc != null) {
        _calculateAndSetState();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateAndSetState() {
    if (widget.prayerTimes.imsak == null || _loc == null) return;

    final now = DateTime.now();
    List<Map<String, dynamic>> allTimes = [];

    Map<String, String> vakitler = {
      "İmsak": widget.prayerTimes.imsak!,
      "Güneş": widget.prayerTimes.gunes!,
      "Öğle": widget.prayerTimes.ogle!,
      "İkindi": widget.prayerTimes.ikindi!,
      "Akşam": widget.prayerTimes.aksam!,
      "Yatsı": widget.prayerTimes.yatsi!,
    };

    for (var entry in vakitler.entries) {
      List<String> parts = entry.value.split(':');
      DateTime t = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      allTimes.add({"key": entry.key, "time": t, "isTomorrow": false});
    }

    List<String> imsakParts = widget.prayerTimes.imsak!.split(':');
    DateTime tomorrowImsak = DateTime(
      now.year,
      now.month,
      now.day + 1,
      int.parse(imsakParts[0]),
      int.parse(imsakParts[1]),
    );
    allTimes.add({"key": "İmsak", "time": tomorrowImsak, "isTomorrow": true});

    // Geçmiş vakitleri at
    allTimes.removeWhere((item) {
      return (item["time"] as DateTime).difference(now).inSeconds <= 0;
    });

    allTimes.sort(
      (a, b) => (a["time"] as DateTime).compareTo(b["time"] as DateTime),
    );

    if (allTimes.isNotEmpty) {
      var next = allTimes.first;
      var newRemainingTime = (next["time"] as DateTime).difference(now);

      String translatedName = _getLocalizedName(next["key"], _loc!);
      if (next["isTomorrow"] == true) {
        translatedName = "$translatedName ${_loc!.tomorrow}";
      }

      // Sadece veri değiştiğinde UI'ı güncelle
      setState(() {
        _remainingTime = newRemainingTime;
        _displayNextVakitIsmi = translatedName;
      });
    } else {
      setState(() {
        _remainingTime = Duration.zero;
      });
    }
  }

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

  String _formatDuration(Duration d) {
    int totalSeconds = d.inSeconds;
    if (totalSeconds < 0) totalSeconds = 0; // Güvenlik kelepçesi

    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(totalSeconds ~/ 3600);
    String minutes = twoDigits((totalSeconds % 3600) ~/ 60);
    String seconds = twoDigits(totalSeconds % 60);
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_loc == null) return const SizedBox.shrink();

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
            _loc!.timeLeftFor(_displayNextVakitIsmi),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            _formatDuration(_remainingTime),
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
