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
// EKLENDİ: Widget servisini import ediyoruz (Yolunu projene göre ayarla)
// Eğer lib/widget_service.dart ise:
import '../../../data/services/widget_service.dart';

class HomeViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final StorageService _storageService = StorageService();
  final HadithService _hadithService = HadithService();
  final IlIlceService _ilIlceService = IlIlceService();

  AudioPlayer? _audioPlayer;

  // DÜZELTME: Timer kaldırıldı (Çakışma önlendi)
  // Timer? _stickyNotificationTimer;

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

  // --- GÜNCELLENEN KISIM ---
  // Dil değiştiğinde tetiklenir.
  void updateLocalization(AppLocalizations loc) {
    _currentLoc = loc;

    // Eğer veriler yüklüyse, alarmları yeni dille tekrar kur.
    // Böylece bildirimler "Vakit Geldi" yerine "Prayer Time" (veya tam tersi) olur.
    if (_isDataLoaded) {
      _rescheduleAlarms();
      // EKLENDİ: Dil değişince Widget da güncellensin
      _updateHomeScreenWidget();
    }
  }
  // -------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isDataLoaded) {
        // DÜZELTME: Uygulama öne gelince sadece arka plana güncel veriyi hatırlatıyoruz.
        // Kendimiz bildirim oluşturmuyoruz.
        _sendTimesToBackgroundService();
        // EKLENDİ: Uygulama açılınca Widget güncellensin
        _updateHomeScreenWidget();
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

        // Verileri arka plana gönder, gerisine karışma
        _sendTimesToBackgroundService();
        await _rescheduleAlarms();

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

  Future<void> changeCityAndDistrict(
    String newCity,
    String? newDistrict,
  ) async {
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

        // DÜZELTME: Veri değişti, servise haber ver.
        _sendTimesToBackgroundService();
        Future.microtask(() => _rescheduleAlarms());

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

  // --- KRİTİK METOT: Arka plan servisiyle konuşan tek yer burası ---
  void _sendTimesToBackgroundService() {
    if (prayerTimes == null || _currentLoc == null) return;
    try {
      // 1. Hesaplama için gerekli ham veriler (Bunlar değişmez, kodun kalbi)
      Map<String, String> times = {
        "İmsak": prayerTimes!.imsak!,
        "Güneş": prayerTimes!.gunes!,
        "Öğle": prayerTimes!.ogle!,
        "İkindi": prayerTimes!.ikindi!,
        "Akşam": prayerTimes!.aksam!,
        "Yatsı": prayerTimes!.yatsi!,
      };

      // 2. Bildirimde görünecek ÇEVİRİLER (Dinamik)
      // "Kalan" kelimesi için basit bir sözlük yapıyoruz
      String langCode = _currentLoc!.localeName; // 'tr', 'en' vb.
      String remainingText = "Kalan"; // Varsayılan TR

      if (langCode.startsWith('en'))
        remainingText = "Left";
      else if (langCode.startsWith('de'))
        remainingText = "Übrig";
      else if (langCode.startsWith('fr'))
        remainingText = "Restant";
      else if (langCode.startsWith('ar'))
        remainingText = "الباقي";

      Map<String, String> displayTexts = {
        "next": _currentLoc!.nextPrayer, // "Sıradaki Vakit" / "Next Prayer"
        "remaining": remainingText, // "Kalan" / "Left"
        "İmsak": _currentLoc!.imsak, // "İmsak" / "Fajr"
        "Güneş": _currentLoc!.gunes,
        "Öğle": _currentLoc!.ogle,
        "İkindi": _currentLoc!.ikindi,
        "Akşam": _currentLoc!.aksam,
        "Yatsı": _currentLoc!.yatsi,
      };

      // Servise ikisini birden paketleyip atıyoruz
      FlutterBackgroundService().invoke("setPrayerTimes", {
        "times": times,
        "display": displayTexts,
      });

      // EKLENDİ: Veriler hazır olduğunda Widget'ı da güncelle!
      _updateHomeScreenWidget();
    } catch (e) {
      debugPrint("Servis Hatası (Önemsiz): $e");
    }
  }

  // ========================================================
  // EKLENEN YENİ FONKSİYON: Ana Ekran Widget'ını Hesapla ve Güncelle
  // ========================================================
  void _updateHomeScreenWidget() {
    if (prayerTimes == null) return;

    try {
      final now = DateTime.now();

      // Vakitler Map'i
      Map<String, String> vakitler = {
        "İmsak": prayerTimes!.imsak!,
        "Güneş": prayerTimes!.gunes!,
        "Öğle": prayerTimes!.ogle!,
        "İkindi": prayerTimes!.ikindi!,
        "Akşam": prayerTimes!.aksam!,
        "Yatsı": prayerTimes!.yatsi!,
      };

      String sonrakiVakitIsmi = "İmsak";
      DateTime? sonrakiVakitTarihi;
      bool bulundu = false;

      // Sıradaki vakti bul
      for (var entry in vakitler.entries) {
        if (entry.key == "Güneş")
          continue; // Güneş namaz vakti olmadığı için atlanabilir

        List<String> parts = entry.value.split(':');
        DateTime vakitDate = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );

        if (vakitDate.isAfter(now)) {
          sonrakiVakitIsmi = entry.key;
          sonrakiVakitTarihi = vakitDate;
          bulundu = true;
          break;
        }
      }

      // Gece ise yarınki İmsak'ı hedef al
      if (!bulundu) {
        sonrakiVakitIsmi = "İmsak";
        List<String> parts = vakitler["İmsak"]!.split(':');
        sonrakiVakitTarihi = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        ).add(const Duration(days: 1));
      }

      // Kalan Süreyi Hesapla (Örn: "02:15" formatında)
      Duration diff = sonrakiVakitTarihi!.difference(now);
      String kalanSureText =
          "${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}";

      // Widget'a gönder
      WidgetService.widgetiGuncelle(
        baslik: "$sonrakiVakitIsmi Vaktine Kalan",
        kalanSure:
            kalanSureText, // Saniye saniye saymaz, widget güncellendikçe değişir
        vakitler: vakitler,
      );
    } catch (e) {
      debugPrint("Widget Hesaplama Hatası: $e");
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

  // --- DÜZELTME: Bu metotlar (Sticky Notification Loop) tamamen silindi ---
  // Çakışmayı önlemek için buradaki timer ve bildirim kodlarını sildik.
  // Bildirimi artık BackgroundManager tek başına yönetiyor.

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
      // Sadece zamanlanmış alarmları iptal ediyoruz, sticky bildirimi ellemiyoruz.
      // Sticky bildirimi zaten ID 888 ile BackgroundManager yönetiyor.
      await notificationService.cancelAllNotifications();

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
    // Timer silindiği için dispose'a gerek kalmadı
    _audioPlayer?.dispose();
    super.dispose();
  }
}
