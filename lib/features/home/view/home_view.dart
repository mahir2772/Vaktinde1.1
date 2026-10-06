// ignore_for_file: deprecated_member_use, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:upgrader/upgrader.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:story_view/story_view.dart';
import 'package:showcaseview/showcaseview.dart'; // YENİ EKLENDİ

import '../../common/language_provider.dart';
import '../../common/theme_provider.dart';
import '../view_model/home_view_model.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/ramadan_card.dart';
import '../widgets/kerahat_card.dart';
import '../widgets/prayer_tracker_row.dart';
// YENİ: GLOBAL ANAHTARLARI İÇERİ ALIYORUZ
import 'package:ezan_saati/features/main_wrapper/main_wrapper.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  String _nextVakitIsmi = "İmsak";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = AppLocalizations.of(context)!;
      final viewModel = context.read<HomeViewModel>();
      viewModel.initializeApp(loc);

      final currentLocale = context.read<LanguageProvider>().locale;
      viewModel.getDailyHadith(currentLocale);
    });
  }

  // --- ÇEVİRİ YARDIMCI FONKSİYONU ---
  String _t(AppLocalizations loc, String trText, String enText) {
    return loc.localeName.startsWith('tr') ? trText : enText;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  LinearGradient? _getGradient(String vakit, bool hasImage) {
    if (hasImage) return null;
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
    final loc = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();

    if (viewModel.prayerTimes != null) {
      _calculateNextPrayer(viewModel);
    }

    final currentGradient = _getGradient(
      _nextVakitIsmi,
      themeProvider.backgroundImage != null,
    );

    return UpgradeAlert(
      dialogStyle: UpgradeDialogStyle.cupertino,
      showIgnore: false,
      showLater: true,
      upgrader: Upgrader(debugLogging: false, languageCode: loc.localeName),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            loc.appTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          leading: Container(),
          actions: [
            // ADIM 1: DİL SEÇİM BUTONU
            Showcase(
              key: homeLangKey,
              description: _t(
                loc,
                "Uygulama dilini buradan değiştirebilirsiniz.",
                "You can change the app language from here.",
              ),

              overlayColor: Colors.black.withOpacity(0.8),
              tooltipBackgroundColor: Colors.teal.shade800,
              textColor: Colors.white,
              child: PopupMenuButton<Locale>(
                onSelected: (Locale newLocale) {
                  context.read<LanguageProvider>().setLanguage(newLocale);
                  context.read<HomeViewModel>().getDailyHadith(newLocale);
                  context.read<HomeViewModel>().getDailyAyah(newLocale);
                },
                icon: const Icon(Icons.language, color: Colors.white),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: Locale('tr'),
                    child: Text("Türkçe 🇹🇷"),
                  ),
                  const PopupMenuItem(
                    value: Locale('en'),
                    child: Text("English 🇬🇧"),
                  ),
                  const PopupMenuItem(
                    value: Locale('de'),
                    child: Text("Deutsch 🇩🇪"),
                  ),
                  const PopupMenuItem(
                    value: Locale('fr'),
                    child: Text("Français 🇫🇷"),
                  ),
                  const PopupMenuItem(
                    value: Locale('ar'),
                    child: Text("العربية 🇸🇦"),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => viewModel.refreshLocationAndTimes(context),
            ),
          ],
          // ADIM 3: SADECE ALARMLAR SEKMESİ PARLAYACAK
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            tabs: [
              const Tab(icon: Icon(Icons.access_time_filled), text: "Vakitler"),

              // Showcase'i sadece ikinci Tab'ın üzerine yerleştiriyoruz
              Showcase(
                key: homeAlarmsKey,
                description: _t(
                  loc,
                  "Vakitlere özel alarmları buradan ayarlayabilirsiniz.",
                  "You can set custom alarms for prayer times from here.",
                ),
                overlayColor: Colors.black.withOpacity(0.8),
                tooltipBackgroundColor: Colors.teal.shade800,
                textColor: Colors.white,
                child: const Tab(
                  icon: Icon(Icons.access_alarms),
                  text: "Alarmlar",
                ),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(gradient: currentGradient),
          child: SafeArea(child: _buildBody(viewModel, loc, themeProvider)),
        ),
      ),
    );
  }

  Widget _buildBody(
    HomeViewModel viewModel,
    AppLocalizations loc,
    ThemeProvider themeProvider,
  ) {
    if (viewModel.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 10),
            Text(loc.loading, style: const TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    if (viewModel.errorMessageKey.isNotEmpty) {
      String displayedError = loc.error;
      switch (viewModel.errorMessageKey) {
        case "noInternet":
          displayedError = loc.noInternet;
          break;
        case "gpsOff":
          displayedError = loc.gpsOff;
          break;
        case "permissionDenied":
          displayedError = loc.permissionDenied;
          break;
        case "locationError":
          displayedError = loc.locationError;
          break;
        case "internetNeeded":
          displayedError = loc.internetNeeded;
          break;
        case "locationFoundNoName":
          displayedError = "Konum bulundu ama isim yok.";
          break;
        case "dataError":
          displayedError = loc.error;
          break;
        default:
          displayedError = viewModel.errorDetail ?? loc.error;
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayedError,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => viewModel.refreshLocationAndTimes(context),
                child: Text(loc.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (viewModel.prayerTimes == null) {
      return Center(
        child: Text(loc.noData, style: const TextStyle(color: Colors.white)),
      );
    }

    bool hasImage = themeProvider.backgroundImage != null;

    return Column(
      children: [
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPanoTab(viewModel, loc, hasImage),
              _buildAlarmsTab(viewModel, loc, hasImage),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPanoTab(
    HomeViewModel viewModel,
    AppLocalizations loc,
    bool hasImage,
  ) {
    String displayCity = viewModel.city ?? loc.waitingLocation;
    String displayDistrict = "";
    if (viewModel.district != null && viewModel.district!.isNotEmpty) {
      String rawDistrict = viewModel.district!;
      if (displayCity != loc.waitingLocation &&
          rawDistrict.toLowerCase().startsWith(displayCity.toLowerCase())) {
        if (rawDistrict.length > displayCity.length) {
          displayDistrict = rawDistrict.substring(displayCity.length).trim();
        } else {
          displayDistrict = rawDistrict;
        }
      } else {
        displayDistrict = rawDistrict;
      }
    }
    String locationText = displayCity;
    if (displayDistrict.isNotEmpty && displayCity != loc.waitingLocation) {
      locationText = "$displayCity / $displayDistrict";
    }

    String currentLocaleCode = Localizations.localeOf(context).toString();
    String formattedDate = DateFormat(
      'dd MMMM yyyy',
      currentLocaleCode,
    ).format(DateTime.now());

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
            child: Column(
              children: [
                Text(
                  locationText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Transform.scale(
                  scale: 0.9,
                  child: CountdownWidget(prayerTimes: viewModel.prayerTimes!),
                ),
                RamadanCard(prayerTimes: viewModel.prayerTimes!),
              ],
            ),
          ),

          // ADIM 2: HİKAYE BÖLÜMÜ
          Showcase(
            key: homeStoryKey,
            description: _t(
              loc,
              "Günün ayet ve hadisini buradan okuyabilirsiniz.",
              "You can read the daily ayah and hadith from here.",
            ),
            overlayColor: Colors.black.withOpacity(0.8),
            tooltipBackgroundColor: Colors.teal.shade800,
            textColor: Colors.white,
            child: _buildStorySection(viewModel, loc),
          ),

          _buildSimplePrayerTimesList(viewModel, loc, hasImage),
          KerahatCard(prayerTimes: viewModel.prayerTimes!, hasImage: hasImage),
          PrayerTrackerRow(
            prayerTimes: viewModel.prayerTimes!,
            hasImage: hasImage,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAlarmsTab(
    HomeViewModel viewModel,
    AppLocalizations loc,
    bool hasImage,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: hasImage
            ? Theme.of(context).cardTheme.color!.withValues(alpha: 0.2)
            : Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 20, bottom: 20),
        children: [
          _buildExpandableCard(
            viewModel,
            loc,
            "İmsak",
            loc.imsak,
            formatVakit(viewModel.prayerTimes!.imsak!, loc.localeName),
            hasImage,
          ),
          _buildExpandableCard(
            viewModel,
            loc,
            "Güneş",
            loc.gunes,
            formatVakit(viewModel.prayerTimes!.gunes!, loc.localeName),
            hasImage,
          ),
          _buildExpandableCard(
            viewModel,
            loc,
            "Öğle",
            loc.ogle,
            formatVakit(viewModel.prayerTimes!.ogle!, loc.localeName),
            hasImage,
          ),
          _buildExpandableCard(
            viewModel,
            loc,
            "İkindi",
            loc.ikindi,
            formatVakit(viewModel.prayerTimes!.ikindi!, loc.localeName),
            hasImage,
          ),
          _buildExpandableCard(
            viewModel,
            loc,
            "Akşam",
            loc.aksam,
            formatVakit(viewModel.prayerTimes!.aksam!, loc.localeName),
            hasImage,
          ),
          _buildExpandableCard(
            viewModel,
            loc,
            "Yatsı",
            loc.yatsi,
            formatVakit(viewModel.prayerTimes!.yatsi!, loc.localeName),
            hasImage,
          ),
        ],
      ),
    );
  }

  Widget _buildStorySection(HomeViewModel viewModel, AppLocalizations loc) {
    if (viewModel.dailyAyah == null && viewModel.dailyHadith == null)
      return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (viewModel.dailyAyah != null)
            _buildStoryBubble(
              title: loc.localeName.startsWith('tr')
                  ? "Günün Ayeti"
                  : "Daily Ayah",
              icon: Icons.menu_book_rounded,
              onTap: () {
                _openStoryScreen(
                  title: loc.localeName.startsWith('tr')
                      ? "Günün Ayeti"
                      : "Ayah of the Day",
                  content:
                      "${viewModel.dailyAyah!.arabicText}\n\n${viewModel.dailyAyah!.translatedText}",
                  source: viewModel.dailyAyah!.surahName,
                );
              },
            ),
          if (viewModel.dailyAyah != null && viewModel.dailyHadith != null)
            const SizedBox(width: 30),
          if (viewModel.dailyHadith != null)
            _buildStoryBubble(
              title: loc.localeName.startsWith('tr')
                  ? "Günün Hadisi"
                  : "Daily Hadith",
              icon: Icons.format_quote_rounded,
              onTap: () {
                _openStoryScreen(
                  title: loc.hadithTitle,
                  content: viewModel.dailyHadith!.content ?? "",
                  source: viewModel.dailyHadith!.source ?? "",
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStoryBubble({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.tealAccent, Colors.teal, Colors.blueGrey],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: Colors.teal.shade100,
                child: Icon(icon, size: 30, color: Colors.teal.shade800),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }

  void _openStoryScreen({
    required String title,
    required String content,
    required String source,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            DailyStoryScreen(title: title, content: content, source: source),
      ),
    );
  }

  Widget _buildSimplePrayerTimesList(
    HomeViewModel viewModel,
    AppLocalizations loc,
    bool hasImage,
  ) {
    Map<String, String> vakitler = {
      "İmsak": viewModel.prayerTimes!.imsak!,
      "Güneş": viewModel.prayerTimes!.gunes!,
      "Öğle": viewModel.prayerTimes!.ogle!,
      "İkindi": viewModel.prayerTimes!.ikindi!,
      "Akşam": viewModel.prayerTimes!.aksam!,
      "Yatsı": viewModel.prayerTimes!.yatsi!,
    };
    Map<String, String> vakitIsimleri = {
      "İmsak": loc.imsak,
      "Güneş": loc.gunes,
      "Öğle": loc.ogle,
      "İkindi": loc.ikindi,
      "Akşam": loc.aksam,
      "Yatsı": loc.yatsi,
    };

    Widget buildCell(String key) {
      bool isNext = _nextVakitIsmi == key;
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isNext ? Colors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isNext ? Colors.teal : Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                vakitIsimleri[key]!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                  color: isNext ? Colors.white : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatVakit(vakitler[key]!, loc.localeName),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isNext
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasImage
            ? Theme.of(context).cardTheme.color!.withValues(alpha: 0.85)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              buildCell("İmsak"),
              const SizedBox(width: 10),
              buildCell("Güneş"),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              buildCell("Öğle"),
              const SizedBox(width: 10),
              buildCell("İkindi"),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              buildCell("Akşam"),
              const SizedBox(width: 10),
              buildCell("Yatsı"),
            ],
          ),
        ],
      ),
    );
  }

  String formatVakit(String vakit24, String langCode) {
    if (vakit24.isEmpty || !vakit24.contains(':')) return vakit24;
    bool use12Hour = langCode.startsWith('ar') || langCode.startsWith('en');
    if (!use12Hour) return vakit24;
    try {
      final parts = vakit24.split(':');
      int hour = int.parse(parts[0]);
      String minute = parts[1];
      String amPm = "";
      if (langCode.startsWith('ar')) {
        amPm = hour >= 12 ? "م" : "ص";
      } else {
        amPm = hour >= 12 ? "PM" : "AM";
      }
      if (hour == 0)
        hour = 12;
      else if (hour > 12)
        hour -= 12;
      return "${hour.toString().padLeft(2, '0')}:$minute $amPm";
    } catch (e) {
      return vakit24;
    }
  }

  Widget _buildExpandableCard(
    HomeViewModel viewModel,
    AppLocalizations loc,
    String logicKey,
    String displayTitle,
    String time,
    bool hasImage,
  ) {
    bool isNext = _nextVakitIsmi == logicKey;
    bool isOnTimeActive = viewModel.onTimeAlarms[logicKey] ?? false;
    bool isReminderActive = viewModel.reminderAlarms[logicKey] ?? false;
    bool isSilentActive = viewModel.silentModeSettings[logicKey] ?? false;
    String sureDegeri = (logicKey == "İmsak" || logicKey == "Güneş")
        ? "30"
        : "15";
    String currentEzanId = viewModel.selectedSounds[logicKey] ?? "ezan1";
    String currentReminderId =
        viewModel.selectedReminderSounds[logicKey] ?? "bildirim1";

    Color cardColor;
    if (hasImage) {
      cardColor = isNext
          ? Colors.teal.withValues(alpha: 0.6)
          : Theme.of(context).cardTheme.color!.withValues(alpha: 0.4);
    } else {
      cardColor = isNext
          ? const Color(0xFFE0F2F1)
          : Theme.of(context).cardTheme.color!;
    }

    return Card(
      elevation: isNext ? 8 : 2,
      shadowColor: isNext ? Colors.teal.withValues(alpha: 0.4) : Colors.black12,
      margin: const EdgeInsets.only(bottom: 12, left: 5, right: 5),
      color: cardColor,
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
            displayTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: isNext
                  ? (hasImage ? Colors.white : Colors.teal.shade800)
                  : Theme.of(context).textTheme.bodyLarge?.color,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isNext
                        ? (hasImage ? Colors.white : Colors.teal.shade900)
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isNext
                      ? (hasImage ? Colors.white70 : Colors.teal.shade700)
                      : Colors.grey.shade500,
                  size: 20,
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                children: [
                  Divider(color: Colors.grey.shade300),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      loc.exactAlarm,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      loc.exactAlarmSub,
                      style: const TextStyle(fontSize: 12),
                    ),
                    activeTrackColor: Colors.teal,
                    value: isOnTimeActive,
                    onChanged: (val) =>
                        viewModel.toggleAlarm(logicKey, true, val),
                  ),
                  if (isOnTimeActive)
                    SwitchListTile(
                      contentPadding: const EdgeInsets.only(left: 16),
                      title: Text(
                        loc.silentNotif,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        loc.silentNotifSub,
                        style: const TextStyle(fontSize: 11),
                      ),
                      activeTrackColor: Colors.blueGrey,
                      value: isSilentActive,
                      onChanged: (val) =>
                          viewModel.toggleSilentMode(logicKey, val),
                    ),
                  if (isOnTimeActive && !isSilentActive)
                    _buildSoundSelector(
                      viewModel: viewModel,
                      title: logicKey,
                      currentSoundId: currentEzanId,
                      soundList: viewModel.soundIds,
                      isReminder: false,
                    ),
                  const SizedBox(height: 5),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      loc.warningAlarm(sureDegeri),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      loc.warningAlarmSub,
                      style: const TextStyle(fontSize: 12),
                    ),
                    activeTrackColor: Colors.orange,
                    value: isReminderActive,
                    onChanged: (val) =>
                        viewModel.toggleAlarm(logicKey, false, val),
                  ),
                  if (isReminderActive)
                    _buildSoundSelector(
                      viewModel: viewModel,
                      title: logicKey,
                      currentSoundId: currentReminderId,
                      soundList: viewModel.reminderSoundIds,
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
    required List<String> soundList,
    required bool isReminder,
  }) {
    String getSoundName(String id, AppLocalizations loc) {
      if (id.startsWith("ezan"))
        return "${loc.soundEzan} ${id.replaceAll("ezan", "")}";
      if (id.startsWith("bildirim"))
        return "${loc.soundBeep} ${id.replaceAll("bildirim", "")}";
      return id;
    }

    final loc = AppLocalizations.of(context)!;
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
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 13,
                ),
                items: soundList
                    .map(
                      (soundId) => DropdownMenuItem<String>(
                        value: soundId,
                        child: Text(getSoundName(soundId, loc)),
                      ),
                    )
                    .toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    isReminder
                        ? viewModel.changeReminderSound(title, newValue)
                        : viewModel.changeSound(title, newValue);
                  }
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

class DailyStoryScreen extends StatefulWidget {
  final String title;
  final String content;
  final String source;

  const DailyStoryScreen({
    super.key,
    required this.title,
    required this.content,
    required this.source,
  });

  @override
  State<DailyStoryScreen> createState() => _DailyStoryScreenState();
}

class _DailyStoryScreenState extends State<DailyStoryScreen> {
  final StoryController controller = StoryController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StoryView(
        storyItems: [
          StoryItem.text(
            title:
                "${widget.title}\n\n\n${widget.content}\n\n\n- ${widget.source}",
            backgroundColor: Colors.teal.shade800,
            textStyle: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.5,
              shadows: [Shadow(color: Colors.black45, blurRadius: 5)],
            ),
          ),
        ],
        controller: controller,
        repeat: false,
        onComplete: () => Navigator.pop(context),
        onVerticalSwipeComplete: (direction) {
          if (direction == Direction.down) Navigator.pop(context);
        },
      ),
    );
  }
}
