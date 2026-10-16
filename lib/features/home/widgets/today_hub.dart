import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/dini_gunler_service.dart';
import '../../../data/services/hatim.dart';
import '../../../data/services/hatim_service.dart';
import '../../../data/services/json_service.dart';
import '../../../data/services/prayer_tracker.dart';
import '../../../data/services/quran_service.dart';
import '../../common/ad_helper.dart';
import '../../duas/dua_data.dart';
import '../../duas/view/tesbihat_view.dart';
import '../../friday_messages/view/friday_messages_view.dart';
import '../../quran/view/quran_view.dart';
import '../../quran/view/surah_reader_view.dart';
import '../../quran/widgets/hatim_card.dart';
import '../../main_wrapper/main_tabs.dart';
import '../../religious_days/view/religious_days_view.dart';

/// Dini günün tebrik penceresi (gün): günden önce ve sonra (bayram birkaç gün
/// sürer; Dini Günler ekranında da geçen günün tebriği 3 gün gönderilebilir)
const int greetingWindowDays = 3;

/// Ana ekranda gösterilen dini gün; [daysLeft] < 0 ise gün geçti
typedef FeaturedReligiousDay = ({DiniGunModel day, int daysLeft});

/// Tebrik penceresindeki gün (önce bugün/gelecek, yoksa en son geçen), yoksa
/// sıradaki gün; hiçbiri yoksa null
FeaturedReligiousDay? featuredReligiousDay(
  AppLocalizations loc,
  DateTime today,
  List<ResmiDiniGun> resmi,
) {
  final days = [
    for (var year = today.year - 1; year <= today.year + 1; year++)
      ...DiniGunlerService.getYilinDiniGunleri(loc, year, resmi: resmi),
  ]..sort((a, b) => a.tarih.compareTo(b.tarih));
  FeaturedReligiousDay? recent;
  for (final day in days) {
    final left = PrayerTracker.daysBetween(today, day.tarih);
    if (left < -greetingWindowDays) continue;
    if (left < 0) {
      recent = (day: day, daysLeft: left);
      continue;
    }
    if (left <= greetingWindowDays || recent == null) {
      return (day: day, daysLeft: left);
    }
    return recent;
  }
  return recent;
}

/// Ana ekranda "Bugün için": günlük kısayollar tek kartta (Ayarlar/Araçlar
/// satırlarıyla aynı stil, en çok dört satır):
/// - Cuma günü "Hayırlı Cumalar · Cuma mesajı gönder" (en üstte)
/// - Dini gün tebrik penceresindeyse o gün + "Tebrik gönder" (üstte)
/// - Kur'an: hatim sürüyorsa "Hatim · Bugün a / b sayfa" (hatim okuması),
///   değilse kaldığın yer ('quran_last_read') ya da Kur'an-ı Kerim'i aç
/// - Namaz sonrası tesbihat
/// - Değilse sıradaki dini gün ve kalan gün (en altta)
///
/// Cuma mesajları ve dini günler geçiş reklamıyla (sıklık sınırı AdHelper'da),
/// Kur'an, hatim ve tesbihat reklamsız açılır. Gün dönümü ve başka ekranda okunan Kur'an 30 sn'de bir
/// (ve uygulamaya dönünce) yansır.
class TodayHub extends StatefulWidget {
  /// Şimdiki zaman (testler için); verilmezse DateTime.now
  final DateTime Function()? clock;

  /// Test için (varsayılan: gömülü sure listesi + alquran.cloud)
  final QuranService? quranService;

  const TodayHub({super.key, this.clock, this.quranService});

  @override
  State<TodayHub> createState() => _TodayHubState();
}

class _TodayHubState extends State<TodayHub> with WidgetsBindingObserver {
  late final QuranService _quran = widget.quranService ?? QuranService();
  Timer? _timer;

  // İlk yükleme bitene kadar bölüm çizilmez (satırlar yer değiştirmesin)
  bool _ready = false;
  List<Surah>? _surahs;
  QuranBookmark? _lastRead;
  HatimPlan? _hatim;
  List<ResmiDiniGun> _resmi = const [];

  // Tebrik mesajları (tür adı → mesajlar); yüklenemezse null, düğme çıkmaz
  Map<String, List<String>>? _greetings;
  String? _language;

  // Son çizilen gün ve o günün dini günü (dil/gün değişmedikçe hesaplanmaz)
  DateTime? _builtDay;
  String? _featuredKey;
  FeaturedReligiousDay? _featured;

  DateTime _now() => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HatimService.changes.addListener(_refresh);
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (language != _language) {
      _language = language;
      _greetings = null;
      _loadGreetings(language);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HatimService.changes.removeListener(_refresh);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _load() async {
    final surahsFuture = _quran.loadSurahs();
    final lastReadFuture = _quran.loadLastRead();
    final hatimFuture = HatimService().load();
    final resmiFuture = DiniGunlerService.loadResmiGunler();
    List<Surah>? surahs;
    try {
      surahs = await surahsFuture;
    } catch (_) {
      // Liste okunamazsa Kur'an satırı ekranı açar (hatayı o gösterir)
    }
    final lastRead = await lastReadFuture;
    final hatim = (await hatimFuture).plan;
    final resmi = await resmiFuture;
    if (!mounted) return;
    setState(() {
      _surahs = surahs;
      _lastRead = lastRead;
      _hatim = hatim;
      _resmi = resmi;
      _ready = true;
    });
  }

  Future<void> _loadGreetings(String language) async {
    try {
      final greetings = await JsonService().getGreetings(language);
      if (mounted && language == _language) {
        setState(() => _greetings = greetings);
      }
    } catch (_) {}
  }

  /// Kaldığın yer ya da hatim başka ekranda değişmiş ya da gün dönmüş olabilir
  Future<void> _refresh() async {
    if (!mounted || !_ready) return;
    final lastRead = await _quran.loadLastRead();
    final hatim = (await HatimService().load()).plan;
    if (!mounted) return;
    final dayChanged = _builtDay != PrayerTracker.day(_now());
    if (dayChanged ||
        lastRead != _lastRead ||
        hatim?.encode() != _hatim?.encode()) {
      setState(() {
        _lastRead = lastRead;
        _hatim = hatim;
      });
    }
  }

  /// [showAd]: geçiş reklamı (Cuma mesajları, dini günler); Kur'an ve
  /// tesbihat reklamsız
  Future<void> _push(Widget page, {bool showAd = false}) async {
    if (showAd) AdHelper.instance.showInterstitialAd(context);
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
    await _refresh();
  }

  /// Kayıtlı konum listedeki bir ayetse suresi
  Surah? _lastReadSurah() {
    final position = _lastRead;
    final surahs = _surahs;
    if (position == null || surahs == null) return null;
    return surahs
        .where(
          (s) => s.number == position.surah && position.ayah <= s.ayahCount,
        )
        .firstOrNull;
  }

  // Ana çerçevede Kur'an sekmesine geçilir, okuyucu onun üstünde açılır:
  // geri gelince sure listesi görünür
  void _openQuran() {
    final surah = _lastReadSurah();
    final inTab = MainTabRequests.show(MainTab.quran);
    if (surah == null) {
      if (!inTab) _push(QuranView(service: _quran));
      return;
    }
    _push(
      SurahReaderView(
        surah: surah,
        initialAyah: _lastRead!.ayah,
        service: _quran,
        surahs: _surahs,
      ),
    );
  }

  Future<void> _openTesbihat(AppLocalizations loc) async {
    final DuaLibrary library;
    try {
      library = await DuaLibrary.load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(loc.noDataFound)));
      }
      return;
    }
    if (!mounted) return;
    await _push(TesbihatView(steps: library.tesbihat));
  }

  FeaturedReligiousDay? _featuredFor(AppLocalizations loc, DateTime today) {
    final key = '${today.toIso8601String()}|${loc.localeName}';
    if (key != _featuredKey) {
      _featuredKey = key;
      _featured = featuredReligiousDay(loc, today, _resmi);
    }
    return _featured;
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final now = _now();
    final today = PrayerTracker.day(now);
    _builtDay = today;
    final featured = _featuredFor(loc, today);
    final inWindow =
        featured != null && featured.daysLeft.abs() <= greetingWindowDays;

    final rows = <Widget>[
      if (now.weekday == DateTime.friday)
        AppListTile(
          leadingIcon: Icons.forum_outlined,
          title: loc.fridayGreeting,
          subtitle: loc.todayFridayMessage,
          onTap: () => _push(const FridayMessagesView(), showAd: true),
        ),
      if (inWindow) _religiousRow(loc, featured),
      _quranRow(loc, language, today),
      AppListTile(
        leadingIcon: Icons.touch_app_outlined,
        title: loc.tesbihatTitle,
        subtitle: loc.tesbihatDesc,
        onTap: () => _openTesbihat(loc),
      ),
      if (featured != null && !inWindow) _religiousRow(loc, featured),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          loc.todayHubTitle,
          padding: const EdgeInsetsDirectional.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.sm,
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _quranRow(AppLocalizations loc, String language, DateTime today) {
    final hatim = _hatim;
    if (hatim != null && !hatim.isFinished) {
      return AppListTile(
        leadingIcon: Icons.auto_stories_outlined,
        title: loc.hatimTitle,
        subtitle: loc.hatimToday(hatim.readOn(today), hatim.dailyGoal(today)),
        onTap: () => openHatimReading(context, service: _quran),
      );
    }
    final surah = _lastReadSurah();
    return AppListTile(
      leadingIcon: Icons.auto_stories_outlined,
      title: surah == null ? loc.todayQuranOpen : loc.quranContinue,
      subtitle: surah == null
          ? loc.toolQuranDesc
          : loc.quranAyahRef(surah.displayName(language), _lastRead!.ayah),
      onTap: _openQuran,
    );
  }

  /// Dini gün: kalan gün (geçtiyse tarihi); tebrik penceresinde altında
  /// "Tebrik gönder" (ayrı düğme: ekran okuyucuda satırla birleşmez)
  Widget _religiousRow(AppLocalizations loc, FeaturedReligiousDay featured) {
    final day = featured.day;
    final left = featured.daysLeft;
    final tile = AppListTile(
      leadingIcon: Icons.event_note,
      title: day.isim,
      subtitle: left >= 0
          ? loc.daysLeft(left)
          : DateFormat.MMMMEEEEd(loc.localeName).format(day.tarih),
      onTap: () => _push(const ReligiousDaysView(), showAd: true),
    );
    final groups = left.abs() <= greetingWindowDays
        ? greetingGroupsFor(_greetings, day.tur)
        : const <GreetingGroup>[];
    if (groups.isEmpty) return tile;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tile,
        Padding(
          // Düğmenin simgesi satırın yazısıyla aynı hizada
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.lg + AppSizes.iconBox + AppSpacing.xs,
            end: AppSpacing.lg,
            bottom: AppSpacing.sm,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => showGreetingsSheet(context, groups),
              icon: const Icon(Icons.send_rounded, size: 20),
              label: Text(loc.sendGreeting),
            ),
          ),
        ),
      ],
    );
  }
}
