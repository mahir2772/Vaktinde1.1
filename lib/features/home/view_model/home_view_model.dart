// ignore_for_file: empty_catches

import 'dart:async';
import 'package:ezan_saati/features/quran/ayah_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/prayer_time_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/hadith_service.dart';
import '../../../data/models/prayer_times_model.dart';
import '../../../data/models/hadith_model.dart';
import '../../../main.dart';
import '../../../data/services/ayah_service.dart';
import '../../../data/services/background_manager.dart';
import '../../../data/services/error_reporter.dart';
import '../../../data/services/hatim_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/prayer_refresh_service.dart';
import '../../../data/services/prayer_tracker.dart';
import '../../../data/services/prayer_tracker_service.dart';
import '../../../data/services/tracker_widget_service.dart';
import '../alarm_health.dart';
import '../../common/app_analytics.dart';

class HomeViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final LocationService _locationService = LocationService();
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  final StorageService _storageService = StorageService();
  final HadithService _hadithService = HadithService();
  final AyahService _ayahService = AyahService();
  final PrayerRefreshService _refreshService = PrayerRefreshService(
    notificationService,
  );
  AyahModel? dailyAyah;

  // Ses önizlemesi: res/raw'daki bildirim sesi ('vaktinde/device' playSound/stopSound;
  // assets'te kopyası yok). Her çalma bir tur; eski turun gecikmiş yanıtı yenisine dokunmaz.
  static const MethodChannel _device = MethodChannel('vaktinde/device');
  int _previewRun = 0;

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
  // "Vakit çıkmadan hatırlat"
  bool endReminderEnabled = false;
  int endReminderMinutes = PrayerTracker.defaultEndReminderMinutes;
  // "Sessiz modda da çal": ezan alarm ses akışında (varsayılan kapalı)
  bool ezanAlarmStream = false;
  // Android 7.x'te alarm ses akışı uygulanamaz: anahtar gösterilmez
  bool alarmStreamSupported = true;
  // "Günün ayeti ve hadisi" bildirimi (varsayılan açık)
  bool dailyContentEnabled = true;
  // "Dini gün ve kandil bildirimleri" (varsayılan açık)
  bool religiousDaysEnabled = true;
  // "Cuma bildirimi" (varsayılan açık)
  bool fridayNotifEnabled = true;
  // "Özel günde ezanı sessiz bildir" (varsayılan açık)
  bool excusedSilentEzan = true;
  // "Kalıcı bildirim" (yeni kurulumda kapalı, eski kullanıcıda açık)
  bool persistentNotificationEnabled = false;

  /// Ezan uyarısının sağlığı (bildirim ve tam zamanlı alarm izni); izin
  /// değişince ya da bildirimler açılıp kapanınca alarmlar yeniden kurulur
  late final AlarmHealth alarmHealth = AlarmHealth(
    notificationService,
    onChanged: rescheduleAlarms,
  );

  /// En az bir ezan / hatırlatma / vakit çıkış uyarısı açık mı (uyarı şeridi için)
  bool get anyAlarmEnabled =>
      onTimeAlarms.values.any((on) => on) ||
      reminderAlarms.values.any((on) => on) ||
      endReminderEnabled;
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
    PrayerTrackerService.excusedChanges.addListener(_onExcusedChanged);
    PrayerTrackerService.changes.addListener(_onTrackerChanged);
    _armMidnightTimer();
  }

  // Özel gün işaretlendi / kaldırıldı (takip satırı ya da ekranı): özel günde
  // ezan sessiz, hatırlatma yok → alarmlar yeniden kurulur
  void _onExcusedChanged() => _rescheduleAlarms();

  // Takip kaydı değişti (işaret, özel gün, kaza, yedekten dönüş): takip widget'ı
  void _onTrackerChanged() => TrackerWidgetService.update(loc: _currentLoc);

  Timer? _midnightTimer;

  // Uygulama açık kalsa da gece yarısından hemen sonra vakitler yenilenir
  void _armMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1, 0, 0, 30);
    _midnightTimer = Timer(next.difference(now), () {
      if (_isDataLoaded) {
        try {
          _calculateHijriDate();
          _refreshTimesIfNewDay().catchError((Object e) {});
        } catch (e) {}
      }
      _armMidnightTimer();
    });
  }

  void updateLocalization(AppLocalizations loc) {
    if (_currentLoc?.localeName == loc.localeName) return;

    _currentLoc = loc;
    if (_isDataLoaded) {
      _calculateHijriDate();
      _rescheduleAlarms();
      _updateHomeScreenWidget();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Ayarlardan dönülmüş olabilir: izinler yeniden okunur (düzeldiyse uyarı kalkar)
      alarmHealth.refresh();
      if (_isDataLoaded) {
        _refreshTimesIfNewDay();
        _calculateHijriDate(); // Uygulama uyanınca tarihi kontrol et
        _updateHomeScreenWidget();
      }
    }
  }

  // 🔥 YENİ: Hicri Tarih Hesaplama Fonksiyonu
  void _calculateHijriDate() {
    if (_currentLoc == null) return;

    // Uygulama diline göre, örn: 7 Safer 1448 (hijri paketinde olmayan de/fr için İngilizce)
    String langCode = _currentLoc!.localeName.substring(0, 2);
    hijriDateText = PrayerRefreshService.hijriDateText(langCode);
    notifyListeners();
  }

  Future<void>? _initRun;

  /// Uygulama verisini bir kez yükler; tekrar çağrılar aynı işi döndürür
  /// (MainWrapper başlatır).
  Future<void> initializeApp(AppLocalizations loc) {
    _currentLoc = loc;
    return _initRun ??= _initialize(loc);
  }

  Future<void> _initialize(AppLocalizations loc) async {
    if (_isDataLoaded) return;

    try {
      await initializeDateFormatting('tr_TR', null);
      await _loadSavedSettings();
      await checkAlarmStreamSupport();
      await notificationService.init();
      alarmHealth.refresh();

      _calculateHijriDate(); // İlk açılışta Hicri tarih

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

        _updateHomeScreenWidget();
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

  // Kayıtlı koordinat + vakit ince ayarı ile bugünün vakitleri (koordinat yoksa null)
  Future<PrayerTimesModel?> _calculateFromSavedCoordinates() async {
    final times = await _prayerTimeService.forDate(DateTime.now());
    if (times == null) return null;
    _timesDate = DateTime.now();
    await _storageService.savePrayerTimesData(times);
    return times;
  }

  // Gün değiştiyse (uygulama arka plandan dönünce) vakitleri yeniden hesapla
  Future<void> _refreshTimesIfNewDay() async {
    if (_timesDate != null && DateUtils.isSameDay(_timesDate, DateTime.now())) {
      return;
    }
    // Dünün ayet/hadisi tekrar kurulmasın: yenileri alınır (kendileri kurar)
    _refreshDailyContent();
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
    _updateHomeScreenWidget();
    await _rescheduleAlarms();
  }

  void _refreshDailyContent() {
    if (_currentLoc == null) return;
    final locale = Locale(_currentLoc!.localeName.substring(0, 2));
    getDailyHadith(locale).catchError((Object e) {});
    getDailyAyah(locale).catchError((Object e) {});
  }

  /// Vakit ince ayarı kaydedildikten sonra: bugünün vakitleri, ekran, widget'lar,
  /// kalıcı bildirim ve alarmlar yeniden hesaplanır.
  /// Koordinat yoksa (yedek API vakitleri) ince ayar uygulanmaz.
  Future<void> applyTimeOffsets() async {
    final times = await _calculateFromSavedCoordinates();
    if (times == null) return;
    prayerTimes = times;
    notifyListeners();
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
          ? _prayerTimeService.calculate(
              lat,
              lng,
              offsets: await _storageService.loadTimeOffsets(),
            )
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

        _updateHomeScreenWidget();
        Future.microtask(() => _rescheduleAlarms());
        // Konum bilgisi (il/ilçe) analitiğe gönderilmez
        await AppAnalytics.logEvent(name: 'sehir_secildi');
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

  void _updateHomeScreenWidget() {
    if (prayerTimes == null) return;
    _refreshService.updateHomeWidget(
      times: prayerTimes!,
      loc: _currentLoc,
      city: city,
      district: district,
      hijriDateText: hijriDateText,
    );
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
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    isLoading = true;
    notifyListeners();
    await getPrayerTimes(loc: loc, isManualRefresh: true);
  }

  // Ayet/hadisin günü: bugünün içeriği alınmadan bildirim kurulmaz (WorkManager
  // tamamlar); bildirim çalacağı günün içeriğini kendisi alır (bugünse aynısı)
  DateTime? _ayahDate;
  DateTime? _hadithDate;

  Future<void> _scheduleDailyContent() async {
    if (_currentLoc == null) return;
    final now = DateTime.now();
    final ayah = DateUtils.isSameDay(_ayahDate, now);
    final hadith = DateUtils.isSameDay(_hadithDate, now);
    if (!ayah && !hadith) return;
    try {
      await _refreshService.scheduleDailyContent(
        localeName: _currentLoc!.localeName,
        ayah: ayah,
        hadith: hadith,
      );
    } catch (e) {}
  }

  Future<void> getDailyHadith(Locale locale) async {
    final today = DateTime.now();
    final hadith = await _hadithService.getDailyHadith(locale, day: today);
    if (hadith != null) {
      dailyHadith = hadith;
      _hadithDate = today;
      notifyListeners();
      await _scheduleDailyContent();
      // Ağ varken sonraki günler önceden alınır (arka plandaki bildirim için)
      if (!_hadithService.isFallback(hadith, locale)) {
        unawaited(_hadithService.prefetch(locale).catchError((Object _) {}));
      }
    }
  }

  Future<void> getDailyAyah(Locale locale) async {
    final today = DateTime.now();
    final ayah = await _ayahService.getDailyAyah(
      locale.languageCode,
      day: today,
    );
    if (ayah != null) {
      dailyAyah = ayah;
      _ayahDate = today;
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
    ezanAlarmStream = savedData['alarmStream'] == true;
    final endReminder = await _storageService.loadEndReminderSettings();
    endReminderEnabled = endReminder.enabled;
    endReminderMinutes = endReminder.minutes;
    dailyContentEnabled = await _storageService.loadDailyContentEnabled();
    religiousDaysEnabled = await _storageService.loadReligiousDaysEnabled();
    fridayNotifEnabled = await _storageService.loadFridayNotifEnabled();
    excusedSilentEzan = await _storageService.loadExcusedSilentEzan();
    persistentNotificationEnabled = await _storageService
        .loadPersistentNotification();
    notifyListeners();
  }

  /// "Kalıcı bildirim": açılınca 888 çizilir (telefon açılışında da);
  /// kapatılınca bildirim ve yenileme alarmı kalkar
  Future<void> setPersistentNotificationEnabled(bool value) async {
    if (persistentNotificationEnabled == value) return;
    persistentNotificationEnabled = value;
    notifyListeners();
    await _applyPersistentNotification();
  }

  Future<void> _applyPersistentNotification() async {
    try {
      await _storageService.savePersistentNotification(
        persistentNotificationEnabled,
      );
      await BackgroundManager.apply(persistentNotificationEnabled);
    } catch (e, st) {
      reportNonFatal(e, st, reason: 'kalıcı bildirim ayarı uygulanamadı');
    }
  }

  /// "Günün ayeti ve hadisi" bildirimi: kapatılınca kurulu olanlar hemen iptal
  /// edilir (bir daha kurulmaz); açılınca bugünün içeriği kurulur, alınamamış
  /// olan yeniden istenir (gelince kurulur)
  Future<void> setDailyContentEnabled(bool value) async {
    if (dailyContentEnabled == value) return;
    dailyContentEnabled = value;
    notifyListeners();
    try {
      await _storageService.saveDailyContentEnabled(value);
    } catch (e, st) {
      reportNonFatal(e, st, reason: 'günlük içerik ayarı kaydedilemedi');
    }
    if (!value) {
      await _refreshService.cancelDailyContent();
      return;
    }
    await _ensureDailyContent();
  }

  // Bugünün içeriği kurulur; alınamamış olan yeniden istenir (gelince kurulur)
  Future<void> _ensureDailyContent() async {
    await _scheduleDailyContent();
    final loc = _currentLoc;
    if (loc == null) return;
    final locale = Locale(loc.localeName.substring(0, 2));
    final now = DateTime.now();
    await Future.wait([
      if (!DateUtils.isSameDay(_ayahDate, now))
        getDailyAyah(locale).catchError((Object e) {}),
      if (!DateUtils.isSameDay(_hadithDate, now))
        getDailyHadith(locale).catchError((Object e) {}),
    ]);
  }

  /// Yedekten geri yüklemeden sonra: ayarlar, konum ve vakitler kayıttan
  /// yeniden okunur; ekran, widget'lar, kalıcı bildirim ve bildirimlerin hepsi
  /// (ezan, hatırlatma, vakit çıkışı, dini günler, Cuma, günün ayeti/hadisi)
  /// yeni ayarlarla yeniden kurulur. Koordinatsız konum internetle çözümlenir.
  Future<void> reloadFromStorage() async {
    _stopSound();
    final persistentBefore = persistentNotificationEnabled;
    await _loadSavedSettings();
    // Yedekteki kalıcı bildirim ayarı farklıysa servis başlar ya da durur
    if (persistentNotificationEnabled != persistentBefore) {
      await _applyPersistentNotification();
    }
    final savedCity = await _storageService.loadLocation();
    final savedDistrict = await _storageService.loadDistrict();
    final times = await _calculateFromSavedCoordinates();
    if (times != null) {
      prayerTimes = times;
      if (savedCity != null) {
        city = savedCity;
        district = savedDistrict;
      }
      isLoading = false;
      errorMessageKey = "";
      errorDetail = null;
      _isDataLoaded = true;
      _calculateHijriDate();
      notifyListeners();
      _updateHomeScreenWidget();
      await _rescheduleAlarms();
    } else if (savedCity != null && savedCity.isNotEmpty) {
      // Eski (koordinatsız) kayıt: konum bir kez çözümlenir (alarmları da
      // kurar); internet yoksa yeni ayarlar eldeki vakitlerle kurulur
      await changeCityAndDistrict(savedCity, savedDistrict);
      await (_rescheduleRun ?? _rescheduleAlarms());
    } else {
      notifyListeners();
      await _rescheduleAlarms();
    }
    // Vakit yoksa alarm turu çalışmaz: dini günler, Cuma ve hatim ayrıca
    // eşitlenir
    if (prayerTimes == null) {
      if (_currentLoc != null) {
        await _refreshService.syncReligiousDays(_currentLoc!);
        await _refreshService.syncFridayNotifications(_currentLoc!);
      }
      await HatimService().syncReminder();
    }
    if (dailyContentEnabled) {
      // Alınamamış içerik ağdan istenir (beklenmez; gelince kurulur)
      unawaited(_ensureDailyContent());
    } else {
      await _refreshService.cancelDailyContent();
    }
  }

  /// "Dini gün ve kandil bildirimleri": kapatılınca kurulu olanlar hemen iptal
  /// edilir (bir daha kurulmaz); açılınca önümüzdeki günler kurulur (ID 2000-2399)
  Future<void> setReligiousDaysEnabled(bool value) async {
    if (religiousDaysEnabled == value) return;
    religiousDaysEnabled = value;
    notifyListeners();
    try {
      await _storageService.saveReligiousDaysEnabled(value);
    } catch (e, st) {
      reportNonFatal(e, st, reason: 'dini gün ayarı kaydedilemedi');
    }
    final loc = _currentLoc;
    if (loc == null) return;
    await _refreshService.syncReligiousDays(loc);
    // Dini güne denk gelen Cuma bildirimi o güne göre atlanır ya da kurulur
    await _refreshService.syncFridayNotifications(loc);
  }

  /// "Cuma bildirimi": kapatılınca kurulu olanlar hemen iptal edilir (bir daha
  /// kurulmaz); açılınca önümüzdeki Cumalar kurulur (ID 2400-2403)
  Future<void> setFridayNotifEnabled(bool value) async {
    if (fridayNotifEnabled == value) return;
    fridayNotifEnabled = value;
    notifyListeners();
    try {
      await _storageService.saveFridayNotifEnabled(value);
    } catch (e, st) {
      reportNonFatal(e, st, reason: 'Cuma bildirimi ayarı kaydedilemedi');
    }
    final loc = _currentLoc;
    if (loc == null) return;
    await _refreshService.syncFridayNotifications(loc);
  }

  /// "Özel günde ezanı sessiz bildir": ezanlar, hatırlatmalar ve vakit çıkış
  /// hatırlatmaları yeni ayarla yeniden kurulur
  Future<void> setExcusedSilentEzan(bool value) async {
    if (excusedSilentEzan == value) return;
    excusedSilentEzan = value;
    notifyListeners();
    try {
      await _storageService.saveExcusedSilentEzan(value);
    } catch (e, st) {
      reportNonFatal(e, st, reason: 'özel gün ezan ayarı kaydedilemedi');
    }
    await rescheduleAlarms();
  }

  /// Vakit çıkış hatırlatması ayarı; sadece bu hatırlatmalar (ID 100-124) yeniden kurulur
  Future<void> setEndReminder({bool? enabled, int? minutes}) async {
    if (enabled != null) endReminderEnabled = enabled;
    if (minutes != null) endReminderMinutes = minutes;
    notifyListeners();
    await _storageService.saveEndReminderSettings(
      enabled: endReminderEnabled,
      minutes: endReminderMinutes,
    );
    await refreshEndReminders();
  }

  /// Android sürümü okunur: 8.0 altında "Sessiz modda da çal" gizlenir
  Future<void> checkAlarmStreamSupport() async {
    final supported = await NotificationService.alarmStreamSupported();
    if (supported == alarmStreamSupported) return;
    alarmStreamSupported = supported;
    notifyListeners();
  }

  /// "Sessiz modda da çal": ezanlar yeni (alarm) kanallarıyla yeniden kurulur
  Future<void> setEzanAlarmStream(bool value) async {
    if (ezanAlarmStream == value) return;
    ezanAlarmStream = value;
    notifyListeners();
    try {
      await _storageService.saveEzanAlarmStream(value);
    } catch (e, st) {
      reportNonFatal(e, st, reason: 'sessiz modda çal ayarı kaydedilemedi');
    }
    await rescheduleAlarms();
  }

  /// Bildirim Kontrolü: 1 dk sonra gerçek ezanla aynı ses/kanal/kiple test ezanı
  Future<void> scheduleTestEzan(AppLocalizations loc) =>
      _refreshService.scheduleTestEzan(
        loc: loc,
        onTimeAlarms: onTimeAlarms,
        selectedSounds: selectedSounds,
        silentModeSettings: silentModeSettings,
        alarmStream: ezanAlarmStream,
      );

  /// Bildirim Kontrolü: sıradaki kurulu ezan (bekleyenler okunamazsa hata)
  Future<ScheduledEzan?> nextScheduledEzan() =>
      _refreshService.nextScheduledEzan();

  /// Takipte bir vakit geri alınınca ya da ayar değişince hatırlatmalar eşitlenir
  Future<void> refreshEndReminders() async {
    if (prayerTimes == null || _currentLoc == null) return;
    await _refreshService.syncEndReminders(
      todayTimes: prayerTimes!,
      loc: _currentLoc!,
    );
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
      _stopSound();
    }
    notifyListeners();
    _saveCurrentSettings();
    _rescheduleAlarms();
    if (value == true) {
      // Hangi vakit olduğu (ibadet bilgisi) gönderilmez
      AppAnalytics.logEvent(
        name: 'alarm_acildi',
        parameters: {'tip': isExactTime ? 'tam_vakit' : 'hatirlatma'},
      );
    }
  }

  void toggleSilentMode(String vakit, bool value) {
    silentModeSettings[vakit] = value;
    if (value) {
      _stopSound();
    }
    notifyListeners();
    _saveCurrentSettings();
    _rescheduleAlarms();
  }

  void changeSound(String vakit, String newSoundId) {
    _stopSound();
    selectedSounds[vakit] = newSoundId;
    notifyListeners();
    _saveCurrentSettings();
    _rescheduleAlarms();
  }

  void changeReminderSound(String vakit, String newSoundId) {
    _stopSound();
    selectedReminderSounds[vakit] = newSoundId;
    notifyListeners();
    _saveCurrentSettings();
    _rescheduleAlarms();
  }

  /// Sesi önizler; çalan sese yeniden dokunmak durdurur, başka ses öncekini keser.
  /// Kanal yanıtı ses susunca gelir (bitti, durduruldu ya da açılamadı).
  Future<void> playPreview(String soundId) async {
    if (currentlyPlayingSound == soundId) return stopPreview();
    final run = ++_previewRun;
    currentlyPlayingSound = soundId;
    notifyListeners();
    try {
      await _device.invokeMethod('playSound', soundId);
    } catch (e) {}
    if (run == _previewRun && currentlyPlayingSound == soundId) {
      currentlyPlayingSound = null;
      notifyListeners();
    }
  }

  /// Çalan önizlemeyi durdurur (alarm alt sayfası kapanınca)
  Future<void> stopPreview() async {
    if (currentlyPlayingSound == null) return;
    _stopSound();
    notifyListeners();
  }

  /// Çalan önizlemeyi susturur; ekranı çağıran yeniler
  void _stopSound() {
    if (currentlyPlayingSound == null) return;
    currentlyPlayingSound = null;
    _device.invokeMethod('stopSound').catchError((Object e) => null);
  }

  // Alarm kurma işleri üst üste binmez: çalışırken gelen istekler bitince tek seferde,
  // en güncel ayarlarla yeniden çalıştırılır (kapatılan alarm kurulu kalmasın).
  // Toplu iptal yok: çekmecedeki ezan / "vakit çıkıyor" bildirimleri silinmez.
  Future<void>? _rescheduleRun;
  bool _rescheduleAgain = false;

  /// Alarmları güncel ayarlar ve izinlerle yeniden kurar (üst üste istekler birleşir)
  Future<void> rescheduleAlarms() => _rescheduleAlarms();

  Future<void> _rescheduleAlarms() {
    final running = _rescheduleRun;
    if (running != null) {
      _rescheduleAgain = true;
      return running;
    }
    final run = _runRescheduleLoop();
    _rescheduleRun = run;
    return run;
  }

  /// Süren alarm kurma işi (ve bekleyen tekrarı) bitince tamamlanır
  @visibleForTesting
  Future<void> get alarmsSettled => _rescheduleRun ?? Future<void>.value();

  Future<void> _runRescheduleLoop() async {
    try {
      do {
        _rescheduleAgain = false;
        await _doRescheduleAlarms();
      } while (_rescheduleAgain);
    } finally {
      _rescheduleRun = null;
    }
  }

  // Koordinat varsa 5 günlük alarm kurulur: uygulama açılmasa da ezan gelir (ID 0-71)
  Future<void> _doRescheduleAlarms() async {
    if (prayerTimes == null || _currentLoc == null) return;
    try {
      await _refreshService.rescheduleAlarms(
        todayTimes: prayerTimes!,
        loc: _currentLoc!,
        onTimeAlarms: onTimeAlarms,
        reminderAlarms: reminderAlarms,
        selectedSounds: selectedSounds,
        selectedReminderSounds: selectedReminderSounds,
        silentModeSettings: silentModeSettings,
        alarmStream: ezanAlarmStream,
      );

      await _scheduleDailyContent();
      await HatimService().syncReminder();
    } catch (e, st) {
      await reportNonFatal(e, st, reason: 'alarmlar kurulamadı (uygulama)');
    }
  }

  static const String _batteryAskedKey = 'battery_optimization_asked';

  /// Pil optimizasyonu muafiyeti en fazla bir kez istenir (her açılışta değil);
  /// MainWrapper izin akışından sonra çağırır
  Future<void> requestBatteryOptimizationOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_batteryAskedKey) ?? false) return;
      await prefs.setBool(_batteryAskedKey, true);
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PrayerTrackerService.excusedChanges.removeListener(_onExcusedChanged);
    PrayerTrackerService.changes.removeListener(_onTrackerChanged);
    _midnightTimer?.cancel();
    _stopSound();
    alarmHealth.dispose();
    super.dispose();
  }
}
