import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/prayer_time_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/hadith_service.dart';
import '../../../data/models/prayer_times_model.dart';
import '../../../data/models/hadith_model.dart';
import '../../../main.dart'; // notificationService buradan geliyor

class HomeViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final StorageService _storageService = StorageService();
  final HadithService _hadithService = HadithService();

  AudioPlayer? _audioPlayer;
  Timer? _stickyNotificationTimer; // Widget için Timer geri geldi ✅

  PrayerTimesModel? prayerTimes;
  HadithModel? dailyHadith;

  String city = "Konum Bekleniyor...";
  bool isLoading = true;
  String errorMessage = "";

  // --- İŞTE O KRİTİK HAFIZA KONTROLÜ ---
  bool _isDataLoaded = false;
  // ------------------------------------

  Map<String, bool> onTimeAlarms = {};
  Map<String, bool> reminderAlarms = {};
  Map<String, String> selectedSounds = {};
  Map<String, String> selectedReminderSounds = {};
  Map<String, bool> silentModeSettings = {};

  final List<Map<String, String>> soundList = [
    {"id": "ezan1", "name": "Ezan 1 "},
    {"id": "ezan2", "name": "Ezan 2 "},
    {"id": "ezan3", "name": "Ezan 3 "},
    {"id": "ezan4", "name": "Ezan 4 "},
    {"id": "ezan5", "name": "Ezan 5 "},
    {"id": "ezan6", "name": "Ezan 6 "},
    {"id": "bildirim1", "name": "Kısa Bildirim 1"},
    {"id": "bildirim2", "name": "Kısa Bildirim 2"},
  ];

  final List<Map<String, String>> reminderSoundList = [
    {"id": "bildirim1", "name": "Kısa Uyarı 1"},
    {"id": "bildirim2", "name": "Kısa Uyarı 2"},
  ];

  String? currentlyPlayingSound;

  HomeViewModel() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateStickyNotification(); // Uygulama açılınca widget'ı güncelle
    }
  }

  Future<void> initializeApp() async {
    // --- BURASI ÇOK ÖNEMLİ ---
    // Eğer veri zaten hafızadaysa, fonksiyonu hemen durdur.
    // Böylece tekrar loading çıkmaz, tekrar API'ye gitmez.
    if (_isDataLoaded) {
      return;
    }
    // -------------------------

    try {
      await initializeDateFormatting('tr_TR', null);
      await _loadSavedSettings();
      await notificationService.init();

      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        errorMessage = "İnternet bağlantısı yok. Lütfen internetinizi açın.";
        String? savedCity = await _storageService.loadLocation();
        if (savedCity != null) city = savedCity;
        isLoading = false;

        // İnternet yoksa bile işlem bitti sayalım ki sürekli denemesin
        _isDataLoaded = true;

        notifyListeners();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      String? savedCity = await _storageService.loadLocation();
      if (savedCity != null && savedCity.isNotEmpty) {
        // Burada isLoading = true olur ama sadece ilk açılışta
        await changeCityManually(savedCity);
        getDailyHadith();
      } else {
        await Future.wait([
          getPrayerTimes(isManualRefresh: false),
          getDailyHadith(),
        ]);
      }

      // İşlemler bitti, bayrağı dik! Bir daha buraya girmeyecek.
      _isDataLoaded = true;
    } catch (e) {
      errorMessage = "Başlatma sırasında beklenmedik hata: $e";
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changeCityManually(String newCity) async {
    isLoading = true;
    errorMessage = "";
    notifyListeners();

    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult.contains(ConnectivityResult.none)) {
        errorMessage = "Şehir değiştirmek için internet bağlantısı gerekiyor.";
        isLoading = false;
        notifyListeners();
        return;
      }

      final apiResult = await _prayerTimeService.getPrayerTimes(newCity);

      if (apiResult != null) {
        prayerTimes = apiResult;
        city = newCity;
        await _storageService.saveLocation(newCity);

        Future.microtask(() => _rescheduleAlarms());
        startStickyNotificationLoop(); // Timer'ı başlat
      } else {
        errorMessage =
            "'$newCity' bulunamadı. İsmi doğru yazdığınızdan emin olun.";
      }
    } catch (e) {
      errorMessage = "Veri alınamadı: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getPrayerTimes({bool isManualRefresh = false}) async {
    errorMessage = "";
    notifyListeners();

    if (!isManualRefresh) {
      String? savedCity = await _storageService.loadLocation();
      if (savedCity != null && savedCity.isNotEmpty) {
        await changeCityManually(savedCity);
        return;
      }
    }

    try {
      bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        errorMessage = "GPS (Konum) kapalı. Lütfen ayarlardan konumu açın.";
        isLoading = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          errorMessage =
              "Konum izni reddedildi. Uygulamayı kullanmak için izin verin.";
          isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        errorMessage =
            "Konum izni kalıcı olarak engellendi. Ayarlardan izin vermelisiniz.";
        isLoading = false;
        notifyListeners();
        return;
      }

      final position = await _locationService.determinePosition();
      if (position != null) {
        final cityName = await _locationService.getCityFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (cityName != null) {
          await changeCityManually(cityName);
        } else {
          errorMessage = "Konum bulundu fakat şehir ismi belirlenemedi.";
        }
      } else {
        errorMessage = "Konum alınamadı. GPS sinyali zayıf olabilir.";
      }
    } catch (e) {
      errorMessage = "Bir hata oluştu: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshLocationAndTimes() async {
    await getPrayerTimes(isManualRefresh: true);
  }

  Future<void> getDailyHadith() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return;
    }

    final hadith = await _hadithService.getDailyHadith();
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

  // --- WIDGET İÇİN TIMER MANTIĞI (ESKİ SİSTEM) ---
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
    if (prayerTimes == null) return;

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

    Duration diff = nextTime.difference(now);
    String kalanSure = "${diff.inHours} sa ${diff.inMinutes.remainder(60)} dk";

    String titleText = "Sıradaki: $nextVakit ($kalanSure)";
    String bodyText = vakitler.entries
        .map((e) => "${e.key}:${e.value}")
        .join(" | ");

    notificationService.showStickyNotification(
      title: titleText,
      body: bodyText,
    );
  }
  // ----------------------------------------------

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
    if (prayerTimes == null) return;
    try {
      await notificationService.requestPermissions();
      await notificationService.cancelAllNotifications();

      startStickyNotificationLoop(); // Alarm kurulunca Timer'ı da tazele

      final now = DateTime.now();
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
        String vakitIsmi = entry.key;
        List<String> parts = entry.value.split(':');
        DateTime vakitDate = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );

        if (onTimeAlarms[vakitIsmi] == true) {
          if (vakitDate.isAfter(now)) {
            bool isSilent = silentModeSettings[vakitIsmi] ?? false;
            String? soundToSend = isSilent
                ? null
                : (selectedSounds[vakitIsmi] ?? "ezan1");

            await notificationService.schedulePrayerNotification(
              id: idCounter,
              title: "Ezan Vakti",
              body: "$vakitIsmi vakti girdi.",
              scheduledTime: vakitDate,
              soundName: soundToSend,
            );
          }
        }
        idCounter++;

        if (reminderAlarms[vakitIsmi] == true) {
          int dakikaOnce = (vakitIsmi == "İmsak" || vakitIsmi == "Güneş")
              ? 30
              : 15;
          DateTime hatirlatmaZamani = vakitDate.subtract(
            Duration(minutes: dakikaOnce),
          );
          if (hatirlatmaZamani.isAfter(now)) {
            await notificationService.schedulePrayerNotification(
              id: idCounter,
              title: "Vakit Yaklaşıyor",
              body: "$vakitIsmi vaktine $dakikaOnce dakika kaldı.",
              scheduledTime: hatirlatmaZamani,
              soundName: selectedReminderSounds[vakitIsmi] ?? "bildirim1",
            );
          }
        }
        idCounter++;
      }
    } catch (e) {
      debugPrint("Alarm kurma hatası: $e");
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
