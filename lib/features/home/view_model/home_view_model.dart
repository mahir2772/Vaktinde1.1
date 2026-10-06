// ignore_for_file: empty_catches

import 'dart:async';
import 'package:ezan_saati/features/quran/ayah_model.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/prayer_time_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/hadith_service.dart';
import '../../../data/models/prayer_times_model.dart';
import '../../../data/models/hadith_model.dart';
import '../../../main.dart';
import '../../../data/services/widget_service.dart';
import '../../../data/services/ayah_service.dart';
import 'package:hijri/hijri_calendar.dart'; // 🔥 YENİ: Hicri Takvim Paketi

class HomeViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final StorageService _storageService = StorageService();
  final HadithService _hadithService = HadithService();
  final AyahService _ayahService = AyahService();
  AyahModel? dailyAyah;

  AudioPlayer? _audioPlayer;

  PrayerTimesModel? prayerTimes;
  HadithModel? dailyHadith;

  String? city;
  String? district;
  String hijriDateText = ""; // 🔥 YENİ: Hicri Tarih Metni

  bool isLoading = true;
  String errorMessageKey = "";
  String? errorDetail;
  bool _isDataLoaded = false;
  DateTime? _timesDate; // Ekrandaki vakitlerin ait olduğu gün

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
    "ezan8",
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
    if (_currentLoc?.localeName == loc.localeName) return;

    _currentLoc = loc;
    if (_isDataLoaded) {
      _calculateHijriDate();
      _rescheduleAlarms();
      _sendTimesToBackgroundService();
      _updateHomeScreenWidget();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isDataLoaded) {
        _refreshTimesIfNewDay();
        _calculateHijriDate(); // Uygulama uyanınca tarihi kontrol et
        _sendTimesToBackgroundService();
        _updateHomeScreenWidget();
      }
    }
  }

  // 🔥 YENİ: Hicri Tarih Hesaplama Fonksiyonu
  void _calculateHijriDate() {
    if (_currentLoc == null) return;

    // Uygulama diline göre Hicri paketin dilini ayarla
    String langCode = _currentLoc!.localeName.substring(0, 2);
    HijriCalendar.setLocal(langCode);

    HijriCalendar today = HijriCalendar.now();
    hijriDateText = today.toFormat("dd MMMM yyyy"); // Örn: 7 Safer 1448
    notifyListeners();
  }

  Future<void> initializeApp(AppLocalizations loc) async {
    _currentLoc = loc;
    if (_isDataLoaded) return;

    try {
      await initializeDateFormatting('tr_TR', null);
      await _loadSavedSettings();
      await notificationService.init();

      await _requestBatteryOptimization();

      _calculateHijriDate(); // 🔥 İlk açılışta Hicri tarihi hesapla

      String? savedCity = await _storageService.loadLocation();
      String? savedDistrict = await _storageService.loadDistrict();
      // Koordinat kayıtlıysa vakitler internetsiz hesaplanır; yoksa bugünün cache'i
      PrayerTimesModel? cachedTimes = await _calculateFromSavedCoordinates();
      cachedTimes ??= await _storageService.loadPrayerTimesData();

      Locale currentLocale = Locale(loc.localeName.substring(0, 2));
      getDailyHadith(currentLocale);
      getDailyAyah(currentLocale);

      if (cachedTimes != null && savedCity != null) {
        prayerTimes = cachedTimes;
        city = savedCity;
        district = savedDistrict;
        isLoading = false;
        _isDataLoaded = true;
        _timesDate = DateTime.now();

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
        await changeCityAndDistrict("İstanbul", null);
      }

      _isDataLoaded = true;
    } catch (e) {
      errorMessageKey = "generalError";
      errorDetail = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<PrayerTimesModel?> _calculateFromSavedCoordinates() async {
    final coords = await _storageService.loadCoordinates();
    if (coords == null) return null;
    final times = _prayerTimeService.calculate(coords.lat, coords.lng);
    _timesDate = DateTime.now();
    await _storageService.savePrayerTimesData(times);
    return times;
  }

  // Gün değiştiyse (uygulama arka plandan dönünce) vakitleri yeniden hesapla
  Future<void> _refreshTimesIfNewDay() async {
    if (_timesDate != null && DateUtils.isSameDay(_timesDate, DateTime.now())) {
      return;
    }
    final times = await _calculateFromSavedCoordinates();
    if (times == null) {
      // Eski sürümden gelen (koordinatsız) kullanıcı: konumu bir kez çözümle
      if (city != null && !isLoading) {
        await changeCityAndDistrict(city!, district);
      }
      return;
    }
    prayerTimes = times;
    notifyListeners();
    _sendTimesToBackgroundService();
    _updateHomeScreenWidget();
    await _rescheduleAlarms();
  }

  Future<void> changeCityAndDistrict(
    String newCity,
    String? newDistrict, {
    double? lat,
    double? lng,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      if (lat == null || lng == null) {
        var connectivityResult = await (Connectivity().checkConnectivity());
        if (connectivityResult.contains(ConnectivityResult.none)) {
          if (prayerTimes == null) errorMessageKey = "internetNeeded";
          return;
        }
        final coords = await _locationService.getCoordinatesFromAddress(
          newCity,
          newDistrict,
        );
        lat = coords?.lat;
        lng = coords?.lng;
      }

      // Öncelik: cihazda hesaplama. Koordinat bulunamazsa yedek: Aladhan API
      final PrayerTimesModel? apiResult = (lat != null && lng != null)
          ? _prayerTimeService.calculate(lat, lng)
          : await _prayerTimeService.getPrayerTimes(
              newCity,
              district: newDistrict,
            );
      if (apiResult != null) {
        if (lat != null && lng != null) {
          await _storageService.saveCoordinates(lat, lng);
        } else {
          await _storageService.clearCoordinates();
        }
        _timesDate = DateTime.now();
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
        if (isManualRefresh) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
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
        // Yer adı bulunamasa da vakitler koordinatla hesaplanır
        String city =
            locationData?['city'] ??
            '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
        String? district = locationData?['district'];
        if (district != null && district.isEmpty) district = null;
        await changeCityAndDistrict(
          city,
          district,
          lat: position.latitude,
          lng: position.longitude,
        );
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
    if (prayerTimes == null || _currentLoc == null) return;
    try {
      Map<String, String> times = {
        "İmsak": prayerTimes!.imsak!,
        "Güneş": prayerTimes!.gunes!,
        "Öğle": prayerTimes!.ogle!,
        "İkindi": prayerTimes!.ikindi!,
        "Akşam": prayerTimes!.aksam!,
        "Yatsı": prayerTimes!.yatsi!,
      };
      String langCode = _currentLoc!.localeName;
      String remainingText = "Kalan";

      if (langCode.startsWith('en'))
        remainingText = "Left";
      else if (langCode.startsWith('de'))
        remainingText = "Übrig";
      else if (langCode.startsWith('fr'))
        remainingText = "Restant";
      else if (langCode.startsWith('ar'))
        remainingText = "الباقي";
      Map<String, String> displayTexts = {
        "next": _currentLoc!.nextPrayer,
        "remaining": remainingText,
        "hijri_date":
            hijriDateText, // 🔥 YENİ: Arka plan servisine Hicri tarihi de gönder
        "İmsak": _currentLoc!.imsak,
        "Güneş": _currentLoc!.gunes,
        "Öğle": _currentLoc!.ogle,
        "İkindi": _currentLoc!.ikindi,
        "Akşam": _currentLoc!.aksam,
        "Yatsı": _currentLoc!.yatsi,
        "to_İmsak": _currentLoc!.toImsak,
        "to_Güneş": _currentLoc!.toGunes,
        "to_Öğle": _currentLoc!.toOgle,
        "to_İkindi": _currentLoc!.toIkindi,
        "to_Akşam": _currentLoc!.toAksam,
        "to_Yatsı": _currentLoc!.toYatsi,
        "loading": _currentLoc!.loading,
      };
      FlutterBackgroundService().invoke("setPrayerTimes", {
        "times": times,
        "display": displayTexts,
      });
      _updateHomeScreenWidget();
    } catch (e) {}
  }

  void _updateHomeScreenWidget() {
    if (prayerTimes == null) return;
    try {
      final now = DateTime.now();
      Map<String, String> vakitler = {
        "İmsak": prayerTimes!.imsak!,
        "Güneş": prayerTimes!.gunes!,
        "Öğle": prayerTimes!.ogle!,
        "İkindi": prayerTimes!.ikindi!,
        "Akşam": prayerTimes!.aksam!,
        "Yatsı": prayerTimes!.yatsi!,
      };
      Map<String, String> vakitIsimleri = {
        "İmsak": _currentLoc?.imsak ?? "İmsak",
        "Güneş": _currentLoc?.gunes ?? "Güneş",
        "Öğle": _currentLoc?.ogle ?? "Öğle",
        "İkindi": _currentLoc?.ikindi ?? "İkindi",
        "Akşam": _currentLoc?.aksam ?? "Akşam",
        "Yatsı": _currentLoc?.yatsi ?? "Yatsı",
      };
      String sonrakiVakitIsmi = "İmsak";
      DateTime? sonrakiVakitTarihi;
      bool bulundu = false;
      for (var entry in vakitler.entries) {
        if (entry.key == "Güneş") continue;
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

      String dinamikBaslik = "";
      switch (sonrakiVakitIsmi) {
        case "İmsak":
          dinamikBaslik = _currentLoc?.toImsak ?? "Sabaha";
          break;
        case "Güneş":
          dinamikBaslik = _currentLoc?.toGunes ?? "Güneşe";
          break;
        case "Öğle":
          dinamikBaslik = _currentLoc?.toOgle ?? "Öğleye";
          break;
        case "İkindi":
          dinamikBaslik = _currentLoc?.toIkindi ?? "İkindiye";
          break;
        case "Akşam":
          dinamikBaslik = _currentLoc?.toAksam ?? "Akşama";
          break;
        case "Yatsı":
          dinamikBaslik = _currentLoc?.toYatsi ?? "Yatsıya";
          break;
        default:
          dinamikBaslik = "Kalan";
      }

      String guncelKonum = city ?? "Konum Bekleniyor";
      if (city != null && district != null && district!.isNotEmpty) {
        guncelKonum = "$city, $district";
      }

      WidgetService.widgetiGuncelle(
        baslik: dinamikBaslik,
        hedefZamanMs: sonrakiVakitTarihi!.millisecondsSinceEpoch,
        vakitler: vakitler,
        konum: guncelKonum,
        vakitIsimleri: vakitIsimleri,
        hijriDateText:
            hijriDateText, // 🔥 YENİ: Widget servisine Hicri tarihi de gönder
      );
    } catch (e) {}
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

  Future<void> _scheduleDailyContent() async {
    if (_currentLoc == null) return;
    try {
      if (dailyAyah != null) {
        String title = _currentLoc!.localeName.startsWith('tr')
            ? "Günün Ayeti"
            : "Ayah of the Day";
        String content =
            "${dailyAyah!.arabicText}\n\n${dailyAyah!.translatedText}";
        await notificationService.scheduleDailyContent(
          id: 1000,
          title: title,
          body: content,
          hour: 10,
          minute: 0,
          channelId: 'daily_ayah_channel',
          channelName: 'Günlük Ayet',
        );
      }
      if (dailyHadith != null && dailyHadith!.content != null) {
        String title = _currentLoc!.localeName.startsWith('tr')
            ? "Günün Hadisi"
            : "Hadith of the Day";
        await notificationService.scheduleDailyContent(
          id: 1900,
          title: title,
          body: dailyHadith!.content!,
          hour: 19,
          minute: 0,
          channelId: 'daily_hadith_channel',
          channelName: 'Günlük Hadis',
        );
      }
    } catch (e) {}
  }

  Future<void> getDailyHadith(Locale locale) async {
    final hadith = await _hadithService.getDailyHadith(locale);
    if (hadith != null) {
      dailyHadith = hadith;
      notifyListeners();
      await _scheduleDailyContent();
    }
  }

  Future<void> getDailyAyah(Locale locale) async {
    final ayah = await _ayahService.getRandomAyah(locale.languageCode);
    if (ayah != null) {
      dailyAyah = ayah;
      notifyListeners();
      await _scheduleDailyContent();
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
    } catch (e) {}
  }

  Future<void> _rescheduleAlarms() async {
    if (prayerTimes == null || _currentLoc == null) return;
    try {
      await notificationService.cancelSpecificAlarms();

      final now = DateTime.now();
      Map<String, String> vakitDisplayNames = {
        "İmsak": _currentLoc!.imsak,
        "Güneş": _currentLoc!.gunes,
        "Öğle": _currentLoc!.ogle,
        "İkindi": _currentLoc!.ikindi,
        "Akşam": _currentLoc!.aksam,
        "Yatsı": _currentLoc!.yatsi,
      };
      // Koordinat varsa 5 günlük alarm kurulur: uygulama açılmasa da ezan gelir.
      // (ID'ler gün başına 12: 0-59, cancelSpecificAlarms ile uyumlu)
      final coords = await _storageService.loadCoordinates();
      final int dayCount = coords != null ? 5 : 1;
      int idCounter = 0;
      for (int day = 0; day < dayCount; day++) {
        final dayDate = DateTime(now.year, now.month, now.day + day);
        final dayTimes = day == 0
            ? prayerTimes!
            : _prayerTimeService.calculate(
                coords!.lat,
                coords.lng,
                date: dayDate,
              );
        Map<String, String> vakitler = {
          "İmsak": dayTimes.imsak!,
          "Güneş": dayTimes.gunes!,
          "Öğle": dayTimes.ogle!,
          "İkindi": dayTimes.ikindi!,
          "Akşam": dayTimes.aksam!,
          "Yatsı": dayTimes.yatsi!,
        };
        for (var entry in vakitler.entries) {
          String vakitLogicKey = entry.key;
          String vakitDisplayName = vakitDisplayNames[vakitLogicKey]!;
          List<String> parts = entry.value.split(':');
          DateTime vakitDate = DateTime(
            dayDate.year,
            dayDate.month,
            dayDate.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
          // Tek günlük modda geçmiş vakit yarına kayar; çok günlükte zaten yarın da kurulu
          if (dayCount == 1 && vakitDate.isBefore(now)) {
            vakitDate = vakitDate.add(const Duration(days: 1));
          }

          if (onTimeAlarms[vakitLogicKey] == true) {
            bool isSilent = silentModeSettings[vakitLogicKey] ?? false;
            String? soundToSend = isSilent
                ? null
                : (selectedSounds[vakitLogicKey] ?? "ezan1");
            String channelName = soundToSend != null
                ? _currentLoc!.channelSoundPrefix(soundToSend)
                : _currentLoc!.channelSilentPrayers;
            await notificationService.schedulePrayerNotification(
              id: idCounter,
              title: _currentLoc!.notifTitleTime,
              body: _currentLoc!.notifBodyTime(vakitDisplayName),
              scheduledTime: vakitDate,
              soundName: soundToSend,
              localizedChannelName: channelName,
              localizedTicker: _currentLoc!.tickerEzan,
            );
          }
          idCounter++;
          if (reminderAlarms[vakitLogicKey] == true) {
            int dakikaOnce =
                (vakitLogicKey == "İmsak" || vakitLogicKey == "Güneş")
                ? 30
                : 15;
            DateTime hatirlatmaZamani = vakitDate.subtract(
              Duration(minutes: dakikaOnce),
            );
            if (hatirlatmaZamani.isAfter(now)) {
              String reminderSound =
                  selectedReminderSounds[vakitLogicKey] ?? "bildirim1";
              String channelNameReminder = _currentLoc!.channelSoundPrefix(
                reminderSound,
              );
              await notificationService.schedulePrayerNotification(
                id: idCounter,
                title: _currentLoc!.notifTitleUpcoming,
                body: _currentLoc!.notifBodyUpcoming(
                  vakitDisplayName,
                  dakikaOnce,
                ),
                scheduledTime: hatirlatmaZamani,
                soundName: reminderSound,
                localizedChannelName: channelNameReminder,
                localizedTicker: _currentLoc!.tickerEzan,
              );
            }
          }
          idCounter++;
        }
      }

      await _scheduleDailyContent();
    } catch (e) {}
  }

  Future<void> _requestBatteryOptimization() async {
    try {
      var status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer?.dispose();
    super.dispose();
  }
}
