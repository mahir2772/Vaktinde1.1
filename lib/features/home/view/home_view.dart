// ignore_for_file: deprecated_member_use, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
// --- YENİ EKLENDİ: Upgrader Paketi ---
import 'package:upgrader/upgrader.dart';
// ------------------------------------
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../common/language_provider.dart';
import '../../common/theme_provider.dart';
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
      final loc = AppLocalizations.of(context)!;
      final viewModel = context.read<HomeViewModel>();
      viewModel.initializeApp(loc);

      // --- EKLENDİ: Başlangıçta mevcut dile göre hadisi çek ---
      final currentLocale = context.read<LanguageProvider>().locale;
      viewModel.getDailyHadith(currentLocale);
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

    viewModel.updateLocalization(loc);

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
            PopupMenuButton<Locale>(
              onSelected: (Locale newLocale) {
                context.read<LanguageProvider>().setLanguage(newLocale);
                context.read<HomeViewModel>().getDailyHadith(newLocale);
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
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => viewModel.refreshLocationAndTimes(context),
            ),
          ],
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

    bool hasImage = themeProvider.backgroundImage != null;

    return Column(
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
            ],
          ),
        ),
        Expanded(
          child: Container(
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
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              children: [
                if (viewModel.dailyHadith != null)
                  _buildHadithCard(
                    context,
                    viewModel.dailyHadith!,
                    loc,
                    hasImage,
                  ),

                if (viewModel.dailyHadith != null) const SizedBox(height: 15),

                _buildExpandableCard(
                  viewModel,
                  loc,
                  "İmsak",
                  loc.imsak,
                  viewModel.prayerTimes!.imsak!,
                  hasImage,
                ),
                _buildExpandableCard(
                  viewModel,
                  loc,
                  "Güneş",
                  loc.gunes,
                  viewModel.prayerTimes!.gunes!,
                  hasImage,
                ),
                _buildExpandableCard(
                  viewModel,
                  loc,
                  "Öğle",
                  loc.ogle,
                  viewModel.prayerTimes!.ogle!,
                  hasImage,
                ),
                _buildExpandableCard(
                  viewModel,
                  loc,
                  "İkindi",
                  loc.ikindi,
                  viewModel.prayerTimes!.ikindi!,
                  hasImage,
                ),
                _buildExpandableCard(
                  viewModel,
                  loc,
                  "Akşam",
                  loc.aksam,
                  viewModel.prayerTimes!.aksam!,
                  hasImage,
                ),
                _buildExpandableCard(
                  viewModel,
                  loc,
                  "Yatsı",
                  loc.yatsi,
                  viewModel.prayerTimes!.yatsi!,
                  hasImage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHadithCard(
    BuildContext context,
    HadithModel hadith,
    AppLocalizations loc,
    bool hasImage,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: hasImage
            ? Theme.of(context).cardTheme.color!.withValues(alpha: 0.6)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            _showHadithDetailDialog(context, hadith, loc);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          color: Colors.teal,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          loc.hadithTitle,
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.teal.withValues(alpha: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  hadith.content ?? "",
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.readMore,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "- ${hadith.source}",
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.teal.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHadithDetailDialog(
    BuildContext context,
    HadithModel hadith,
    AppLocalizations loc,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: Colors.teal,
                  size: 40,
                ),
                const SizedBox(height: 10),
                Text(
                  loc.hadithTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const Divider(height: 30, color: Colors.teal),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      hadith.content ?? "",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "- ${hadith.source}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          loc.close,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          String textToShare =
                              "\"${hadith.content}\"\n\n- ${hadith.source}\n\n(${loc.appTitle} ile Paylaşıldı)";
                          Share.share(textToShare);
                          FirebaseAnalytics.instance.logEvent(
                            name: 'hadis_paylasildi',
                          );
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: Text(loc.share),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
            child: Text(
              time,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isNext
                    ? (hasImage ? Colors.white : Colors.teal.shade900)
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
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
      if (id.startsWith("ezan")) {
        String number = id.replaceAll("ezan", "");
        return "${loc.soundEzan} $number";
      } else if (id.startsWith("bildirim")) {
        String number = id.replaceAll("bildirim", "");
        return "${loc.soundBeep} $number";
      }
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
