import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/il_ilce_service.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/prayer_time_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/hadith_service.dart';
import '../../../data/models/prayer_times_model.dart';
import '../../../data/models/hadith_model.dart';
import '../../../main.dart';

class HomeViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final StorageService _storageService = StorageService();
  final HadithService _hadithService = HadithService();
  final IlIlceService _ilIlceService = IlIlceService();

  AudioPlayer? _audioPlayer;
  Timer? _stickyNotificationTimer;

  PrayerTimesModel? prayerTimes;
  HadithModel? dailyHadith;

  String? city;
  String? district;

  Map<String, List<String>> allCitiesAndDistricts = {};
  List<String> get citiesList => allCitiesAndDistricts.keys.toList()..sort();
  List<String> get districtsList =>
      (city != null && allCitiesAndDistricts.containsKey(city))
      ? allCitiesAndDistricts[city]!
      : [];

  bool isLoading = true;
  String errorMessageKey = "";
  String? errorDetail;
  bool _isDataLoaded = false;

  Map<String, bool> onTimeAlarms = {};
  Map<String, bool> reminderAlarms = {};
  Map<String, String> selectedSounds = {};
  Map<String, String> selectedReminderSounds = {};
  Map<String, bool> silentModeSettings = {};

  final List<String> soundIds = [
    "ezan1",
    "ezan2",
    "ezan3",
    "ezan4",
    "ezan5",
    "ezan6",
    "ezan7",
    "bildirim1",
    "bildirim2",
    "bildirim3",
  ];

  final List<String> reminderSoundIds = ["bildirim1", "bildirim2", "bildirim3"];
  String? currentlyPlayingSound;
  AppLocalizations? _currentLoc;

  HomeViewModel() {
    WidgetsBinding.instance.addObserver(this);
  }

  void updateLocalization(AppLocalizations loc) {
    _currentLoc = loc;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama tamamen kapandığında veya arka plana atıldığında
    // Timer'ı durdurmuyoruz ki widget güncel kalsın,
    // ama veriler boşsa işlem yapmıyoruz.
    if (state == AppLifecycleState.resumed) {
      if (_isDataLoaded) {
        _sendTimesToBackgroundService();
        _updateStickyNotification();
      }
    }
  }

  Future<void> initializeApp(AppLocalizations loc) async {
    _currentLoc = loc;
    if (_isDataLoaded) return;

    try {
      await initializeDateFormatting('tr_TR', null);
      await _loadSavedSettings();
      await notificationService.init();
      await _requestBatteryOptimization();
      _fetchIlIlceData();

      PrayerTimesModel? cachedTimes = await _storageService
          .loadPrayerTimesData();
      String? savedCity = await _storageService.loadLocation();
      String? savedDistrict = await _storageService.loadDistrict();

      getDailyHadith(const Locale('tr'));

      if (cachedTimes != null && savedCity != null) {
        prayerTimes = cachedTimes;
        city = savedCity;
        district = savedDistrict;
        isLoading = false;
        _isDataLoaded = true;

        _sendTimesToBackgroundService();
        await _rescheduleAlarms();
        startStickyNotificationLoop();
        notifyListeners();
        return;
      }

      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        errorMessageKey = "noInternet";
        isLoading = false;
        notifyListeners();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (savedCity != null && savedCity.isNotEmpty) {
        await changeCityAndDistrict(savedCity, savedDistrict);
      } else {
        await Future.wait([getPrayerTimes(loc: loc, isManualRefresh: false)]);
      }

      _isDataLoaded = true;
    } catch (e) {
      errorMessageKey = "generalError";
      errorDetail = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchIlIlceData() async {
    final data = await _ilIlceService.getIlIlceListesi();
    if (data != null) {
      allCitiesAndDistricts = data;
      notifyListeners();
    }
  }

  // --- DÜZELTME BURADA YAPILDI ---
  Future<void> changeCityAndDistrict(
    String newCity,
    String? newDistrict,
  ) async {
    // ESKİSİ: if (prayerTimes == null) { isLoading = true; notifyListeners(); }
    // YENİSİ: Her durumda yükleniyor göster ki kullanıcı işlemin başladığını anlasın.
    isLoading = true;
    notifyListeners();

    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        if (prayerTimes == null) errorMessageKey = "internetNeeded";
        isLoading = false;
        notifyListeners();
        return;
      }

      final apiResult = await _prayerTimeService.getPrayerTimes(
        newCity,
        district: newDistrict,
      );

      if (apiResult != null) {
        prayerTimes = apiResult;
        city = newCity;
        district = newDistrict;
        errorMessageKey = "";
        errorDetail = null;

        await _storageService.saveLocation(newCity);
        if (newDistrict != null) {
          await _storageService.saveDistrict(newDistrict);
        } else {
          await _storageService.saveDistrict("");
        }

        await _storageService.savePrayerTimesData(apiResult);
        _sendTimesToBackgroundService();
        Future.microtask(() => _rescheduleAlarms());
        startStickyNotificationLoop();

        await FirebaseAnalytics.instance.logEvent(
          name: 'sehir_secildi',
          parameters: {'sehir': newCity, 'ilce': newDistrict ?? 'Merkez'},
        );
      } else {
        if (prayerTimes == null) {
          errorMessageKey = "dataError";
          errorDetail = newCity;
        }
      }
    } catch (e) {
      if (prayerTimes == null) {
        errorMessageKey = "generalError";
        errorDetail = e.toString();
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getPrayerTimes({
    required AppLocalizations loc,
    bool isManualRefresh = false,
  }) async {
    _currentLoc = loc;
    if (prayerTimes == null) {
      errorMessageKey = "";
      notifyListeners();
    }

    try {
      bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        if (prayerTimes == null) errorMessageKey = "gpsOff";
        isLoading = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (prayerTimes == null) errorMessageKey = "permissionDenied";
          isLoading = false;
          notifyListeners();
          return;
        }
      }

      final position = await _locationService.determinePosition();
      if (position != null) {
        final locationData = await _locationService
            .getCityAndDistrictFromCoordinates(
              position.latitude,
              position.longitude,
            );

        if (locationData != null) {
          String city = locationData['city']!;
          String? district = locationData['district'];
          if (district != null && district.isEmpty) district = null;
          await changeCityAndDistrict(city, district);
        } else {
          if (prayerTimes == null) errorMessageKey = "locationFoundNoName";
        }
      } else {
        if (prayerTimes == null) errorMessageKey = "locationError";
      }
    } catch (e) {
      if (prayerTimes == null) {
        errorMessageKey = "generalError";
        errorDetail = e.toString();
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _sendTimesToBackgroundService() {
    if (prayerTimes == null) return;
    try {
      Map<String, String> vakitler = {
        "İmsak": prayerTimes!.imsak!,
        "Güneş": prayerTimes!.gunes!,
        "Öğle": prayerTimes!.ogle!,
        "İkindi": prayerTimes!.ikindi!,
        "Akşam": prayerTimes!.aksam!,
        "Yatsı": prayerTimes!.yatsi!,
      };
      // Servis başlatılmamışsa hata verebilir, try-catch ile koruyoruz
      FlutterBackgroundService().invoke("setPrayerTimes", vakitler);
    } catch (e) {
      debugPrint("Servis Hatası (Önemsiz): $e");
    }
  }

  Future<void> refreshLocationAndTimes(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    _currentLoc = loc;

    bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.gpsOff),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    isLoading = true;
    notifyListeners();
    await getPrayerTimes(loc: loc, isManualRefresh: true);
  }

  Future<void> getDailyHadith(Locale locale) async {
    final hadith = await _hadithService.getDailyHadith(locale);
    if (hadith != null) {
      dailyHadith = hadith;
      notifyListeners();
    }
  }

  Future<void> _loadSavedSettings() async {
    final savedData = await _storageService.loadSettings();
    onTimeAlarms = savedData['onTime'];
    reminderAlarms = savedData['reminder'];
    selectedSounds = savedData['sounds'];
    selectedReminderSounds = savedData['reminderSounds'];
    silentModeSettings = savedData['silentMode'];
    notifyListeners();
  }

  void _saveCurrentSettings() {
    _storageService.saveSettings(
      onTimeAlarms: onTimeAlarms,
      reminderAlarms: reminderAlarms,
      selectedSounds: selectedSounds,
      selectedReminderSounds: selectedReminderSounds,
      silentModeSettings: silentModeSettings,
    );
  }

  void startStickyNotificationLoop() {
    _stickyNotificationTimer?.cancel();
    _updateStickyNotification();
    _stickyNotificationTimer = Timer.periodic(const Duration(minutes: 1), (
      timer,
    ) {
      _updateStickyNotification();
    });
  }

  void _updateStickyNotification() {
    // 1. KORUMA: Eğer veriler null ise sakın widget'ı güncelleme!
    // Bu sayede uygulama kapanırken boş veri göndermez.
    if (prayerTimes == null) return;
    if (prayerTimes!.imsak == null || prayerTimes!.yatsi == null) return;

    final now = DateTime.now();

    Map<String, String> vakitler = {
      "İmsak": prayerTimes!.imsak!,
      "Güneş": prayerTimes!.gunes!,
      "Öğle": prayerTimes!.ogle!,
      "İkindi": prayerTimes!.ikindi!,
      "Akşam": prayerTimes!.aksam!,
      "Yatsı": prayerTimes!.yatsi!,
    };

    String nextVakit = "İmsak";
    DateTime? nextTime;
    for (var entry in vakitler.entries) {
      List<String> parts = entry.value.split(':');
      DateTime vTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      if (vTime.isAfter(now)) {
        nextVakit = entry.key;
        nextTime = vTime;
        break;
      }
    }
    if (nextTime == null) {
      List<String> parts = prayerTimes!.imsak!.split(':');
      nextTime = DateTime(
        now.year,
        now.month,
        now.day + 1,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      nextVakit = "İmsak";
    }

    Duration diff = nextTime!.difference(now);
    String remainingText =
        "${diff.inHours}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}";

    String titleText = "Vaktinde • $nextVakit: ${vakitler[nextVakit]}";

    String locationInfo = city ?? "";
    if (district != null && district!.isNotEmpty) {
      locationInfo = district!;
    }
    String bodyText = "$locationInfo     Kalan: $remainingText";

    // --- TABLO TASARIMI (YATAY HİZALI) ---
    // \u2003 = Geniş Boşluk (Em Space) kullanarak hizalamayı garantiye alıyoruz.
    String headerRow =
        "İmsak\u2003Güneş\u2003Öğle\u2003İkindi\u2003Akşam\u2003Yatsı";
    String timeRow =
        "${vakitler['İmsak']}\u2003${vakitler['Güneş']}\u2003${vakitler['Öğle']}\u2003${vakitler['İkindi']}\u2003${vakitler['Akşam']}\u2003${vakitler['Yatsı']}";

    String bigContent = "$headerRow\n$timeRow";

    // Bildirimi güvenli blok içinde gönder
    try {
      notificationService.showStickyNotification(
        title: titleText,
        body: bodyText,
        bigContent: bigContent,
        endTime: nextTime,
      );
    } catch (e) {
      debugPrint("Bildirim güncelleme hatası: $e");
    }
  }

  void toggleAlarm(String vakit, bool isExactTime, bool value) {
    if (isExactTime)
      onTimeAlarms[vakit] = value;
    else
      reminderAlarms[vakit] = value;
    if (value == false) {
      _audioPlayer?.stop();
      currentlyPlayingSound = null;
    }
    notifyListeners();
    _saveCurrentSettings();
    _rescheduleAlarms();

    if (value == true) {
      FirebaseAnalytics.instance.logEvent(
        name: 'alarm_acildi',
        parameters: {
          'vakit': vakit,
          'tip': isExactTime ? 'tam_vakit' : 'hatirlatma',
        },
      );
    }
  }

  void toggleSilentMode(String vakit, bool value) {
    silentModeSettings[vakit] = value;
    if (value) {
      _audioPlayer?.stop();
      currentlyPlayingSound = null;
    }
    notifyListeners();
    _saveCurrentSettings();
    _rescheduleAlarms();
  }

  void changeSound(String vakit, String newSoundId) {
    _audioPlayer?.stop();
    currentlyPlayingSound = null;
    selectedSounds[vakit] = newSoundId;
    notifyListeners();
    _saveCurrentSettings();
    _rescheduleAlarms();
  }

  void changeReminderSound(String vakit, String newSoundId) {
    _audioPlayer?.stop();
    currentlyPlayingSound = null;
    selectedReminderSounds[vakit] = newSoundId;
    notifyListeners();
    _saveCurrentSettings();
    _rescheduleAlarms();
  }

  Future<void> playPreview(String soundId) async {
    try {
      _audioPlayer ??= AudioPlayer();
      await _audioPlayer!.stop();
      if (currentlyPlayingSound == soundId) {
        currentlyPlayingSound = null;
        notifyListeners();
        return;
      }
      await _audioPlayer!.play(AssetSource('sounds/$soundId.mp3'));
      currentlyPlayingSound = soundId;
      notifyListeners();
      _audioPlayer!.onPlayerComplete.listen((event) {
        currentlyPlayingSound = null;
        notifyListeners();
      });
    } catch (e) {
      debugPrint("Ses hatası: $e");
    }
  }

  Future<void> _rescheduleAlarms() async {
    if (prayerTimes == null || _currentLoc == null) return;
    try {
      await notificationService.requestPermissions();
      await notificationService.cancelAllNotifications();
      startStickyNotificationLoop();

      final now = DateTime.now();
      Map<String, String> vakitDisplayNames = {
        "İmsak": _currentLoc!.imsak,
        "Güneş": _currentLoc!.gunes,
        "Öğle": _currentLoc!.ogle,
        "İkindi": _currentLoc!.ikindi,
        "Akşam": _currentLoc!.aksam,
        "Yatsı": _currentLoc!.yatsi,
      };

      Map<String, String> vakitler = {
        "İmsak": prayerTimes!.imsak!,
        "Güneş": prayerTimes!.gunes!,
        "Öğle": prayerTimes!.ogle!,
        "İkindi": prayerTimes!.ikindi!,
        "Akşam": prayerTimes!.aksam!,
        "Yatsı": prayerTimes!.yatsi!,
      };

      int idCounter = 0;
      for (var entry in vakitler.entries) {
        String vakitLogicKey = entry.key;
        String vakitDisplayName = vakitDisplayNames[vakitLogicKey]!;
        List<String> parts = entry.value.split(':');
        DateTime vakitDate = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );

        if (vakitDate.isBefore(now)) {
          vakitDate = vakitDate.add(const Duration(days: 1));
        }

        if (onTimeAlarms[vakitLogicKey] == true) {
          bool isSilent = silentModeSettings[vakitLogicKey] ?? false;
          String? soundToSend = isSilent
              ? null
              : (selectedSounds[vakitLogicKey] ?? "ezan1");

          await notificationService.schedulePrayerNotification(
            id: idCounter,
            title: _currentLoc!.notifTitleTime,
            body: _currentLoc!.notifBodyTime(vakitDisplayName),
            scheduledTime: vakitDate,
            soundName: soundToSend,
          );
        }
        idCounter++;

        if (reminderAlarms[vakitLogicKey] == true) {
          int dakikaOnce =
              (vakitLogicKey == "İmsak" || vakitLogicKey == "Güneş") ? 30 : 15;
          DateTime hatirlatmaZamani = vakitDate.subtract(
            Duration(minutes: dakikaOnce),
          );
          if (hatirlatmaZamani.isAfter(now)) {
            await notificationService.schedulePrayerNotification(
              id: idCounter,
              title: _currentLoc!.notifTitleUpcoming,
              body: _currentLoc!.notifBodyUpcoming(
                vakitDisplayName,
                dakikaOnce,
              ),
              scheduledTime: hatirlatmaZamani,
              soundName: selectedReminderSounds[vakitLogicKey] ?? "bildirim1",
            );
          }
        }
        idCounter++;
      }
    } catch (e) {
      debugPrint("Alarm kurma hatası: $e");
    }
  }

  Future<void> _requestBatteryOptimization() async {
    try {
      var status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      debugPrint("Pil izni hatası: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stickyNotificationTimer?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }
}
