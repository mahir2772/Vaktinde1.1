import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../view_model/home_view_model.dart';
import '../widgets/countdown_widget.dart';

import '../../../data/models/hadith_model.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _nextVakitIsmi = "İmsak";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().initializeApp();
    });
  }

  void _calculateNextPrayer(HomeViewModel viewModel) {
    if (viewModel.prayerTimes == null) return;
    final now = DateTime.now();
    Map<String, String> vakitler = {
      "İmsak": viewModel.prayerTimes!.imsak!,
      "Güneş": viewModel.prayerTimes!.gunes!,
      "Öğle": viewModel.prayerTimes!.ogle!,
      "İkindi": viewModel.prayerTimes!.ikindi!,
      "Akşam": viewModel.prayerTimes!.aksam!,
      "Yatsı": viewModel.prayerTimes!.yatsi!,
    };

    String foundNext = "İmsak";
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
        foundNext = entry.key;
        break;
      }
    }
    _nextVakitIsmi = foundNext;
  }

  LinearGradient _getGradient(String vakit) {
    switch (vakit) {
      case "İmsak":
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
        );
      case "Güneş":
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
        );
      case "Öğle":
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2980B9), Color(0xFF6DD5FA)],
        );
      case "İkindi":
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF373B44), Color(0xFF4286f4)],
        );
      case "Akşam":
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C3E50), Color(0xFFFD746C)],
        );
      case "Yatsı":
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
        );
      default:
        return const LinearGradient(colors: [Colors.teal, Colors.tealAccent]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    if (viewModel.prayerTimes != null) {
      _calculateNextPrayer(viewModel);
    }

    final currentGradient = _getGradient(_nextVakitIsmi);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Ezan Vakti",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: Container(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => viewModel.refreshLocationAndTimes(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: currentGradient),
        child: SafeArea(child: _buildBody(viewModel)),
      ),
    );
  }

  Widget _buildBody(HomeViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 10),
            Text(
              "Vakitler Hesaplanıyor...",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }
    if (viewModel.errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                viewModel.errorMessage,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => viewModel.refreshLocationAndTimes(),
                child: const Text("Tekrar Dene"),
              ),
            ],
          ),
        ),
      );
    }
    if (viewModel.prayerTimes == null)
      return const Center(
        child: Text("Veri yok.", style: TextStyle(color: Colors.white)),
      );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              Text(
                viewModel.city.toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CountdownWidget(prayerTimes: viewModel.prayerTimes!),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              children: [
                if (viewModel.dailyHadith != null)
                  _buildHadithCard(viewModel.dailyHadith!),
                if (viewModel.dailyHadith != null) const SizedBox(height: 15),
                _buildExpandableCard(
                  viewModel,
                  "İmsak",
                  viewModel.prayerTimes!.imsak!,
                ),
                _buildExpandableCard(
                  viewModel,
                  "Güneş",
                  viewModel.prayerTimes!.gunes!,
                ),
                _buildExpandableCard(
                  viewModel,
                  "Öğle",
                  viewModel.prayerTimes!.ogle!,
                ),
                _buildExpandableCard(
                  viewModel,
                  "İkindi",
                  viewModel.prayerTimes!.ikindi!,
                ),
                _buildExpandableCard(
                  viewModel,
                  "Akşam",
                  viewModel.prayerTimes!.aksam!,
                ),
                _buildExpandableCard(
                  viewModel,
                  "Yatsı",
                  viewModel.prayerTimes!.yatsi!,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHadithCard(HadithModel hadith) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.format_quote_rounded, color: Colors.teal, size: 30),
              SizedBox(width: 10),
              Text(
                "Günün Hadisi",
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hadith.content ?? "",
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "- ${hadith.source}",
              style: TextStyle(
                color: Colors.teal.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableCard(
    HomeViewModel viewModel,
    String title,
    String time,
  ) {
    bool isNext = _nextVakitIsmi == title;
    bool isOnTimeActive = viewModel.onTimeAlarms[title] ?? false;
    bool isReminderActive = viewModel.reminderAlarms[title] ?? false;

    // Yeni: Sessiz Mod Durumu
    bool isSilentActive = viewModel.silentModeSettings[title] ?? false;

    String sureMetni = (title == "İmsak" || title == "Güneş")
        ? "30 dk"
        : "15 dk";
    String currentEzanId = viewModel.selectedSounds[title] ?? "ezan1";
    String currentReminderId =
        viewModel.selectedReminderSounds[title] ?? "bildirim1";

    return Card(
      elevation: isNext ? 8 : 2,
      shadowColor: isNext ? Colors.teal.withValues(alpha: 0.4) : Colors.black12,
      margin: const EdgeInsets.only(bottom: 12, left: 5, right: 5),
      color: isNext ? const Color(0xFFE0F2F1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isNext
            ? const BorderSide(color: Colors.teal, width: 1.5)
            : BorderSide.none,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isNext ? Colors.teal : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time_filled,
              color: isNext ? Colors.white : Colors.grey,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: isNext ? Colors.teal.shade800 : Colors.black87,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isNext
                  ? Colors.teal.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isNext ? Colors.teal.shade900 : Colors.black87,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                children: [
                  Divider(color: Colors.grey.shade300),

                  // 1. TAM VAKTİNDE OKU
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "Tam Vaktinde Oku",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      "Bildirim gönderir.",
                      style: TextStyle(fontSize: 12),
                    ),
                    activeTrackColor: Colors.teal,
                    value: isOnTimeActive,
                    onChanged: (val) => viewModel.toggleAlarm(title, true, val),
                  ),

                  // --- YENİ: SESSİZ MOD SEÇENEĞİ (Sadece Alarm Açıksa Görünür) ---
                  if (isOnTimeActive)
                    SwitchListTile(
                      contentPadding: const EdgeInsets.only(
                        left: 16,
                      ), // Biraz içeriden başlasın
                      title: const Text(
                        "Sadece Yazılı Bildirim",
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle: const Text(
                        "Ezan/Ses çalmaz, sadece uyarı gelir.",
                        style: TextStyle(fontSize: 11),
                      ),
                      activeTrackColor: Colors.blueGrey,
                      value: isSilentActive,
                      onChanged: (val) =>
                          viewModel.toggleSilentMode(title, val),
                    ),

                  // Ses Seçimi (Sadece Sesli Moddaysa Göster)
                  if (isOnTimeActive && !isSilentActive)
                    _buildSoundSelector(
                      viewModel: viewModel,
                      title: title,
                      currentSoundId: currentEzanId,
                      soundList: viewModel.soundList,
                      isReminder: false,
                    ),

                  const SizedBox(height: 5),

                  // 2. ERKEN UYARI
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "$sureMetni Önce Uyar",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      "Kısa bildirim sesi.",
                      style: TextStyle(fontSize: 12),
                    ),
                    activeTrackColor: Colors.orange,
                    value: isReminderActive,
                    onChanged: (val) =>
                        viewModel.toggleAlarm(title, false, val),
                  ),
                  if (isReminderActive)
                    _buildSoundSelector(
                      viewModel: viewModel,
                      title: title,
                      currentSoundId: currentReminderId,
                      soundList: viewModel.reminderSoundList,
                      isReminder: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundSelector({
    required HomeViewModel viewModel,
    required String title,
    required String currentSoundId,
    required List<Map<String, String>> soundList,
    required bool isReminder,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 5, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isReminder
            ? Colors.orange.withValues(alpha: 0.08)
            : Colors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReminder
              ? Colors.orange.withValues(alpha: 0.2)
              : Colors.teal.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isReminder ? Icons.notifications_active : Icons.volume_up,
            color: isReminder ? Colors.orange : Colors.teal,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentSoundId,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                style: const TextStyle(color: Colors.black87, fontSize: 13),
                items: soundList
                    .map(
                      (sound) => DropdownMenuItem<String>(
                        value: sound['id'],
                        child: Text(sound['name']!),
                      ),
                    )
                    .toList(),
                onChanged: (newValue) {
                  if (newValue != null)
                    isReminder
                        ? viewModel.changeReminderSound(title, newValue)
                        : viewModel.changeSound(title, newValue);
                },
              ),
            ),
          ),
          InkWell(
            onTap: () => viewModel.playPreview(currentSoundId),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                viewModel.currentlyPlayingSound == currentSoundId
                    ? Icons.stop_circle
                    : Icons.play_circle_fill,
                color: isReminder ? Colors.orange : Colors.teal,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
