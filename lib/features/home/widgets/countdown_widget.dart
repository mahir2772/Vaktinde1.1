import 'dart:async';
import 'package:flutter/material.dart';
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
  String _nextVakitIsmi = "Hesaplanıyor...";

  @override
  void initState() {
    super.initState();
    _calculateNextPrayer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateNextPrayer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateNextPrayer() {
    if (widget.prayerTimes.imsak == null) return;

    final now = DateTime.now();

    Map<String, String> vakitler = {
      "İmsak": widget.prayerTimes.imsak!,
      "Güneş": widget.prayerTimes.gunes!,
      "Öğle": widget.prayerTimes.ogle!,
      "İkindi": widget.prayerTimes.ikindi!,
      "Akşam": widget.prayerTimes.aksam!,
      "Yatsı": widget.prayerTimes.yatsi!,
    };

    DateTime? targetDate;
    String targetName = "";

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
        targetName = entry.key;
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
      targetName = "İmsak (Yarın)";
    }

    if (mounted) {
      setState(() {
        _remainingTime = targetDate!.difference(now);
        _nextVakitIsmi = targetName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        // DÜZELTME: withValues kullanıldı
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30, width: 1),
      ),
      child: Column(
        children: [
          Text(
            "$_nextVakitIsmi Vaktine Kalan",
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
