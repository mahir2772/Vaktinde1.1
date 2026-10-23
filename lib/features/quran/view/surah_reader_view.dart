import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

import '../../../data/services/hatim.dart';
import '../../../data/services/hatim_service.dart';
import '../../../data/services/quran_audio_service.dart';
import '../../../data/services/quran_service.dart';
import '../../common/share_card.dart';
import '../audio/quran_player.dart';
import '../audio/quran_player_bar.dart';
import '../widgets/ayah_sheet.dart';
import '../widgets/go_to_ayah_dialog.dart';
import '../widgets/mushaf_page.dart';
import '../widgets/quran_number_badge.dart';
import '../widgets/quran_page_frame.dart';
import '../widgets/reader_item.dart';
import '../widgets/surah_nav_tile.dart';
import '../widgets/translation_page.dart';
import '../widgets/view_settings_sheet.dart';

/// Sure okuyucu. Üç görünüm ('quran_view_mode', "Görünüm" alt sayfasından):
/// - Sayfa (varsayılan): mushaf sayfaları (API'nin sayfa bilgisi; eski
///   kopyada ~10 ayetlik gruplar), kesintisiz Arapça; ayete dokununca alt
///   sayfa (Arapça + meal, yer imi, kopyala, resimli paylaş)
/// - Ayet ayet: ayet kartları (yer imi ikonu / uzun basma, paylaşım)
/// - Meal: yalnızca meal paragrafları (Arapça arayüzde yok)
///
/// Başta başlık kartı (önceki sure düğmesi, Arapça ad, besmele), sonda
/// sonraki sure ve kaynak. Görünen ilk ayet kaydırma durunca ve çıkarken
/// son okunan olarak saklanır ('quran_last_read'). "Ayete git" ve görünüm /
/// yazı boyutu değişince okunan yer korunur.
///
/// Hatim okumasında ([hatim]) görünen mushaf sayfasından öncekiler okunmuş
/// sayılır, sırayla ilerledikçe hatim konumu ilerler (HatimService.advanceTo).
///
/// [initialAyah] verilirse liste o ayetten başlar (tembel liste: CustomScrollView
/// merkezi ayetin ögesi, öncekiler yukarı kaydırınca görünür; sayfa içindeki
/// ayete ilk karede kaydırılır).
class SurahReaderView extends StatefulWidget {
  final Surah surah;
  final int? initialAyah;

  /// Test için (varsayılan: alquran.cloud + cihazdaki kopya)
  final QuranService? service;

  /// Önceki / sonraki sure için liste (verilmezse gömülü listeden okunur)
  final List<Surah>? surahs;

  /// false: okunan yer "kaldığın yer" olarak saklanmaz (Namaz Hocası'ndan
  /// açılan Fâtiha kullanıcının kaldığı yeri ezmesin)
  final bool trackLastRead;

  /// Hatim okuması ("Devam Et"); önceki / sonraki sureye geçince de sürer
  final bool hatim;

  /// Test için (varsayılan: QuranPlayer.instance; verilirse dinleme açık)
  final QuranPlayer? player;

  const SurahReaderView({
    super.key,
    required this.surah,
    this.initialAyah,
    this.service,
    this.surahs,
    this.trackLastRead = true,
    this.hatim = false,
    this.player,
  });

  @override
  State<SurahReaderView> createState() => _SurahReaderViewState();
}

class _SurahReaderViewState extends State<SurahReaderView>
    with WidgetsBindingObserver {
  late final QuranService _service = widget.service ?? QuranService();
  final ScrollController _controller = ScrollController();
  final ReaderItemRegistry _registry = ReaderItemRegistry();
  final GlobalKey _viewportKey = GlobalKey();
  final Key _centerKey = UniqueKey();

  String? _language;
  int _loadId = 0;
  SurahText? _text;
  bool _loadFailed = false;

  bool _settingsLoaded = false;
  double _fontScale = 1;
  double _translationScale = 1;

  /// Seçilen görünüm (Arapça arayüzde meal seçiliyse sayfa gösterilir)
  QuranViewMode _mode = QuranViewMode.page;
  QuranBookmark? _bookmark;
  List<Surah>? _surahs;

  /// Listenin merkezindeki ayet; her değişimde [_generation] artar (yeni
  /// kaydırma görünümü o ayetten başlar)
  late int? _anchor = widget.initialAyah;
  int _generation = 0;
  int _laidOutGeneration = -1;
  bool _visibleCheckScheduled = false;
  bool _jumping = false;
  int? _currentAyah;
  int? _savedAyah;

  /// Vurgu: alt sayfası açık ayet ve "Ayete git" ile gelinen (2 sn)
  int? _sheetAyah;
  int? _flashAyah;
  Timer? _flashTimer;

  SurahText? _groupsText;
  List<QuranPageGroup> _groups = const [];

  /// Hatim okumasında sayfa tablosu, bitirilen son sayfa (açılışta kayıttan),
  /// son görünen sayfa ve okuyucu hatim sırasında mı (kaydırarak ilerleme
  /// sayılır)
  QuranPages? _pages;
  int _hatimPosition = 0;
  int? _hatimPage;
  bool _hatimInOrder = false;

  /// Dinleme: çalan ayet vurgulanır ve izlenir (kullanıcı son [_followPause]
  /// içinde kaydırdıysa araya girilmez)
  late final QuranPlayer _player = widget.player ?? QuranPlayer.instance;
  int? _playingAyah;
  DateTime? _userScrolledAt;
  static const Duration _followPause = Duration(seconds: 8);

  /// Dinle düğmesi: ara sunucu kârî listesini verdiyse (testte oynatıcı
  /// verilince her zaman)
  late bool _audioEnabled = widget.player != null;

  QuranViewMode get _viewMode =>
      QuranService.effectiveViewMode(_mode, _language ?? 'tr');

  bool get _hasTranslation =>
      QuranEdition.translationFor(_language ?? 'tr') != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player.addListener(_onPlayer);
    _playingAyah = _player.surah == widget.surah.number ? _player.ayah : null;
    _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (language != _language) {
      _language = language;
      _loadText();
      _checkAudio(language);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulamadan çıkarken okunan yer saklansın
    if (state != AppLifecycleState.resumed) _updateVisibleAyah();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.removeListener(_onPlayer);
    _flashTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final scale = await _service.loadFontScale();
    final translationScale = await _service.loadTranslationScale();
    final mode = await _service.loadViewMode();
    final bookmark = await _service.loadBookmark();
    var surahs = widget.surahs;
    if (surahs == null) {
      try {
        surahs = await _service.loadSurahs();
      } catch (_) {}
    }
    QuranPages? pages;
    var hatimPosition = 0;
    if (widget.hatim) {
      try {
        pages = await HatimService.loadPages();
        hatimPosition = (await HatimService().load()).plan?.position ?? 0;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _fontScale = scale;
      _translationScale = translationScale;
      _mode = mode;
      _bookmark = bookmark;
      _surahs = surahs;
      _pages = pages;
      _hatimPosition = hatimPosition;
      _settingsLoaded = true;
    });
  }

  /// Sure metnini yükler (dil değişince yeniden: okunan ayetten devam);
  /// eski istek sonucu yok sayılır
  void _loadText() {
    final id = ++_loadId;
    if (_text != null) {
      _anchor = _currentAyah ?? _anchor;
      _generation++;
    }
    _text = null;
    _loadFailed = false;
    _service
        .loadSurah(widget.surah, _language!)
        .then(
          (text) {
            if (mounted && id == _loadId) setState(() => _text = text);
          },
          onError: (Object _) {
            if (mounted && id == _loadId) setState(() => _loadFailed = true);
          },
        );
  }

  void _retry() => setState(_loadText);

  List<QuranPageGroup> _pageGroups(SurahText text) {
    if (!identical(text, _groupsText)) {
      _groupsText = text;
      _groups = QuranService.pageGroups(text);
    }
    return _groups;
  }

  /// Ayetin liste dizini (0: başlık); sayfa görünümünde sayfasının dizini
  int _itemOfAyah(int ayah, List<QuranPageGroup>? groups, int ayahCount) {
    final number = ayah.clamp(1, ayahCount);
    if (groups == null) return number;
    final index = groups.indexWhere((g) => g.contains(number));
    return index < 0 ? 0 : index + 1;
  }

  // ----------------------------------------------------- Okunan yer

  /// Görünen ilk ayet: görünür ögelerin en üstteki, görünüm alanının üst
  /// kenarının denk geldiği satır
  int? _firstVisibleAyah() {
    final viewport = _viewportKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox || !viewport.attached || !viewport.hasSize) {
      return null;
    }
    final top = viewport.localToGlobal(Offset.zero).dy;
    final bottom = top + viewport.size.height;
    // Üst kenarda birkaç piksel kalan satır / kart okunan sayılmaz
    final probe = math.min(top + _visibleProbe, bottom);
    AyahLocator? best;
    var bestTop = double.infinity;
    for (final item in _registry.items) {
      if (!item.mounted) continue;
      final box = item.context.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final itemTop = box.localToGlobal(Offset.zero).dy;
      if (itemTop + box.size.height <= probe || itemTop >= bottom) continue;
      if (itemTop < bestTop) {
        best = item;
        bestTop = itemTop;
      }
    }
    return best?.ayahAt(math.max(0, probe - bestTop));
  }

  static const double _visibleProbe = AppSpacing.lg;

  void _updateVisibleAyah() {
    final ayah = _firstVisibleAyah();
    if (ayah == null) return;
    _currentAyah = ayah;
    _saveLastRead(ayah);
    _advanceHatim(ayah, scrolled: true);
  }

  void _saveLastRead(int ayah) {
    if (!widget.trackLastRead || ayah == _savedAyah) return;
    _savedAyah = ayah;
    _service.saveLastRead(
      QuranBookmark(surah: widget.surah.number, ayah: ayah),
    );
  }

  /// Hatim okumasında görünen ayetin sayfasından (tablodan; sayfa görünümünde
  /// ekrandaki mushaf sayfasıyla aynı) önceki sayfalar bitirilmiş sayılır;
  /// Nâs'ın sonuna inince son sayfa da (hatim tamamlanır). Hatim sırasında
  /// kaydırarak ilerlemenin her adımı sayılır; atlamada (açılış, "Ayete git",
  /// sure geçişi) en çok [HatimPlan.maxStep] sayfa ileri. Daha uzağa atlayınca
  /// sıradan çıkılır, bitirilen sayfaya geri dönünce yeniden girilir.
  void _advanceHatim(int ayah, {required bool scrolled}) {
    final pages = _pages;
    if (pages == null) return;
    final page = _atMushafEnd()
        ? HatimPlan.pageCount + 1
        : pages.pageOf(widget.surah.number, ayah);
    if (page == _hatimPage) return;
    _hatimPage = page;
    final done = page - 1;
    if (done <= _hatimPosition) {
      _hatimInOrder = true;
      return;
    }
    _hatimInOrder =
        (scrolled && _hatimInOrder) ||
        done <= _hatimPosition + HatimPlan.maxStep;
    if (!_hatimInOrder) return;
    _hatimPosition = done;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final completedText = AppLocalizations.of(context)!.hatimCompleted;
    HatimService().advanceTo(done).then((completed) {
      if (completed) _showSnack(messenger, completedText);
    }, onError: (Object _) {});
  }

  // Nâs'ın sonu ekranda (kaydırılacak yer kalmadı)
  bool _atMushafEnd() =>
      widget.surah.number == QuranService.surahCount &&
      _controller.hasClients &&
      _controller.position.extentAfter < 1;

  /// Kaydırma durunca (yerleşim bittikten sonra) görünen ayet saklanır
  void _scheduleVisibleCheck() {
    if (_visibleCheckScheduled) return;
    _visibleCheckScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _visibleCheckScheduled = false;
      if (mounted) _updateVisibleAyah();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  /// Yeni kaydırma görünümünün ilk karesinden sonra: merkez öge çok ayetliyse
  /// (sayfa) hedef ayetin satırına kaydırılır. Gidilen ayet (devam, cüz,
  /// "Ayete git") son okunan olur; baştan açılışta görünen ilk ayet.
  void _afterLayout() {
    if (_laidOutGeneration == _generation) return;
    _laidOutGeneration = _generation;
    final generation = _generation;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      final anchor = _anchor;
      final text = _text;
      if (anchor == null || text == null) {
        _scheduleVisibleCheck();
        return;
      }
      final target = anchor.clamp(1, text.ayahs.length);
      if (target > 1) {
        final groups = _viewMode == QuranViewMode.ayah
            ? null
            : _pageGroups(text);
        final item = _registry[_itemOfAyah(target, groups, text.ayahs.length)];
        final offset = item?.offsetOf(target) ?? 0;
        if (offset > AppSpacing.sm && _controller.hasClients) {
          final position = _controller.position;
          // Bu kaydırmanın bitişi son okunanı değiştirmez (hedef ayet saklanır)
          _jumping = true;
          try {
            _controller.jumpTo(
              (offset - AppSpacing.sm).clamp(
                position.minScrollExtent,
                position.maxScrollExtent,
              ),
            );
          } finally {
            _jumping = false;
          }
        }
      }
      _currentAyah = target;
      _saveLastRead(target);
      _advanceHatim(target, scrolled: false);
    });
  }

  /// Okunan ayet korunarak yeniden kurar (görünüm / yazı boyutu değişimi)
  void _reanchor(VoidCallback change) {
    final ayah = _firstVisibleAyah() ?? _currentAyah ?? _anchor;
    setState(() {
      change();
      _anchor = ayah;
      _generation++;
    });
  }

  void _jumpTo(int ayah) {
    _flashTimer?.cancel();
    setState(() {
      _anchor = ayah;
      _generation++;
      _flashAyah = ayah;
    });
    _flashTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _flashAyah = null);
    });
  }

  // ------------------------------------------------------ Dinleme

  Future<void> _checkAudio(String language) async {
    if (widget.player != null || !QuranAudioService.configured) return;
    final available = await QuranAudioService().isAvailable(language);
    if (mounted && available != _audioEnabled) {
      setState(() => _audioEnabled = available);
    }
  }

  void _onPlayer() {
    final ayah = _player.surah == widget.surah.number ? _player.ayah : null;
    if (ayah == _playingAyah) return;
    if (!mounted) return;
    setState(() => _playingAyah = ayah);
    if (ayah != null && _player.playing) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _followAyah(ayah);
      });
    }
  }

  /// [fromAyah]'tan dinler (verilmezse görünen ayetten); bu surenin sesi
  /// zaten açıksa ayete atlar ya da çal / duraklat
  void _listen({int? fromAyah}) {
    if (_player.surah == widget.surah.number && _player.audio != null) {
      fromAyah == null ? _player.toggle() : _player.seekAyah(fromAyah);
      return;
    }
    startQuranListening(
      context,
      surah: widget.surah.number,
      title: widget.surah.displayName(_language!),
      fromAyah: fromAyah ?? _firstVisibleAyah() ?? _currentAyah ?? 1,
      player: _player,
    );
  }

  /// Dinlenen ayet ekranın üst bölümünde değilse ona kaydırılır (öge kurulu
  /// değilse liste o ayetten yeniden kurulur)
  void _followAyah(int ayah) {
    final scrolled = _userScrolledAt;
    if (scrolled != null &&
        DateTime.now().difference(scrolled) < _followPause) {
      return;
    }
    final text = _text;
    final viewport = _viewportKey.currentContext?.findRenderObject();
    if (text == null ||
        viewport is! RenderBox ||
        !viewport.hasSize ||
        !_controller.hasClients) {
      return;
    }
    final groups = _viewMode == QuranViewMode.ayah ? null : _pageGroups(text);
    final item = _registry[_itemOfAyah(ayah, groups, text.ayahs.length)];
    final box = item != null && item.mounted
        ? item.context.findRenderObject()
        : null;
    if (box is! RenderBox || !box.attached || !box.hasSize) {
      setState(() {
        _anchor = ayah;
        _generation++;
      });
      return;
    }
    final top =
        box.localToGlobal(Offset(0, item!.offsetOf(ayah))).dy -
        viewport.localToGlobal(Offset.zero).dy;
    if (top >= 0 && top <= viewport.size.height * 0.6) return;
    final position = _controller.position;
    _controller.animateTo(
      (position.pixels + top - AppSpacing.sm).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // ------------------------------------------------------ Ayarlar

  void _setMode(QuranViewMode mode) {
    if (mode == _mode) return;
    _reanchor(() => _mode = mode);
    _service.saveViewMode(mode);
  }

  void _setFontScale(double scale) {
    if (scale == _fontScale) return;
    _reanchor(() => _fontScale = scale);
    _service.saveFontScale(scale);
  }

  void _setTranslationScale(double scale) {
    if (scale == _translationScale) return;
    _reanchor(() => _translationScale = scale);
    _service.saveTranslationScale(scale);
  }

  void _openViewSettings() {
    showQuranViewSettings(
      context,
      mode: _viewMode,
      translationAvailable: _hasTranslation,
      fontScale: _fontScale,
      translationScale: _translationScale,
      onModeChanged: _setMode,
      onFontScaleChanged: _setFontScale,
      onTranslationScaleChanged: _setTranslationScale,
    );
  }

  Future<void> _goToAyah() async {
    final ayah = await showGoToAyahDialog(
      context,
      ayahCount: widget.surah.ayahCount,
    );
    if (ayah != null && mounted) _jumpTo(ayah);
  }

  void _openSurah(Surah surah) {
    _updateVisibleAyah();
    final route = MaterialPageRoute<void>(
      builder: (_) => SurahReaderView(
        surah: surah,
        service: _service,
        surahs: _surahs,
        trackLastRead: widget.trackLastRead,
        hatim: widget.hatim,
      ),
    );
    // Listeye dönüş, değiştirilen okuyucunun kapanmasını bekler (son okunan
    // yer orada yenilenir)
    Navigator.of(context).pushReplacement(route, result: route.popped);
  }

  // ----------------------------------------------------- Ayet işlemleri

  /// [toggle]: kayıtlı ayette siler (ikon, alt sayfa); uzun basma her zaman
  /// kaydeder. Yeni durumu döner (kayıt olmazsa null).
  Future<bool?> _setBookmark(
    int ayah, {
    required bool toggle,
    bool snack = true,
  }) async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final mark = QuranBookmark(surah: widget.surah.number, ayah: ayah);
    final remove = toggle && _bookmark == mark;
    try {
      if (remove) {
        await _service.clearBookmark();
      } else {
        await _service.saveBookmark(mark);
      }
    } catch (_) {
      if (snack) _showSnack(messenger, loc.shareFailed);
      return null;
    }
    if (!mounted) return null;
    setState(() => _bookmark = remove ? null : mark);
    if (snack) {
      _showSnack(
        messenger,
        remove ? loc.quranBookmarkRemoved : loc.quranBookmarkSaved,
      );
    }
    return !remove;
  }

  void _share(QuranAyah ayah) {
    final loc = AppLocalizations.of(context)!;
    final translation = ayah.translation;
    shareAsImage(
      context,
      title: loc.quranAyahRef(
        widget.surah.displayName(_language!),
        ayah.number,
      ),
      message: translation ?? ayah.arabic,
      arabic: translation == null ? null : ayah.arabic,
      campaign: 'quran',
    );
  }

  Future<void> _openAyahSheet(QuranAyah ayah) async {
    final text = _text;
    if (text == null) return;
    final loc = AppLocalizations.of(context)!;
    final group = _pageGroups(
      text,
    ).where((g) => g.contains(ayah.number)).firstOrNull;
    final page = group?.page;
    final juz =
        group?.juz ?? QuranService.juzOf(widget.surah.number, ayah.number);
    setState(() => _sheetAyah = ayah.number);
    await showAyahSheet(
      context,
      surah: widget.surah,
      ayah: ayah,
      language: _language!,
      pageLabel: page == null
          ? loc.quranJuz(juz)
          : '${loc.quranPage(page)} · ${loc.quranJuz(juz)}',
      fontScale: _fontScale,
      translationScale: _translationScale,
      bookmarked:
          _bookmark ==
          QuranBookmark(surah: widget.surah.number, ayah: ayah.number),
      onToggleBookmark: () =>
          _setBookmark(ayah.number, toggle: true, snack: false),
      onListen: _audioEnabled ? () => _listen(fromAyah: ayah.number) : null,
    );
    if (mounted) setState(() => _sheetAyah = null);
  }

  // ------------------------------------------------------------ Ekran

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final text = _text;
    final ready = _settingsLoaded && text != null;
    final Widget body;
    if (_loadFailed) {
      body = ErrorState(message: loc.quranLoadError, onRetry: _retry);
    } else if (!ready) {
      body = const LoadingState();
    } else {
      // İlk açılışta Görünüm ipucu altta, metnin üstünde yüzer (okuma yeri
      // kaymaz)
      body = Stack(
        children: [
          Positioned.fill(child: _buildContent(text)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FeatureTip(
              id: 'quran_reader',
              message: loc.tipQuranReader,
              padding: const EdgeInsets.all(AppSpacing.lg),
              floating: true,
            ),
          ),
        ],
      );
    }
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _updateVisibleAyah();
      },
      child: AppScaffold(
        title: widget.surah.displayName(_language!),
        actions: [
          if (_audioEnabled)
            IconButton(
              tooltip: loc.quranListen,
              onPressed: ready ? _listen : null,
              icon: const Icon(Icons.headphones_outlined),
            ),
          IconButton(
            tooltip: loc.quranGoToAyah,
            onPressed: ready ? _goToAyah : null,
            icon: const Icon(Icons.numbers),
          ),
          IconButton(
            tooltip: loc.quranViewSettings,
            onPressed: _settingsLoaded ? _openViewSettings : null,
            icon: Icon(quranViewModeIcon(_viewMode)),
          ),
        ],
        body: _audioEnabled
            ? Column(
                children: [
                  Expanded(child: body),
                  QuranPlayerBar(player: _player),
                ],
              )
            : body,
      ),
    );
  }

  Widget _buildContent(SurahText text) {
    final loc = AppLocalizations.of(context)!;
    final language = _language!;
    final mode = _viewMode;
    final ayahs = text.ayahs;
    final groups = mode == QuranViewMode.ayah ? null : _pageGroups(text);
    // 0: başlık, 1..n: sayfalar ya da ayetler, n + 1: sonraki sure ve kaynak
    final count = (groups?.length ?? ayahs.length) + 2;
    final anchor = _anchor;
    final center = anchor == null || anchor <= 1
        ? 0
        : _itemOfAyah(anchor, groups, ayahs.length);
    _afterLayout();

    final surahs = _surahs;
    final number = widget.surah.number;
    final previous = surahs?.where((s) => s.number == number - 1).firstOrNull;
    final next = surahs?.where((s) => s.number == number + 1).firstOrNull;
    final bookmark = _bookmark;
    final bookmarked = bookmark?.surah == number ? bookmark!.ayah : null;
    final selected = _sheetAyah ?? _flashAyah ?? _playingAyah;
    final surahName = widget.surah.displayName(language);

    Widget item(int index) {
      if (index == 0) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (previous != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: SurahNavTile(
                  label: loc.quranPreviousSurah,
                  surah: previous,
                  language: language,
                  forward: false,
                  onTap: () => _openSurah(previous),
                ),
              ),
            _SurahHeader(
              surah: widget.surah,
              language: language,
              bismillah: text.bismillah,
              fontScale: _fontScale,
            ),
          ],
        );
      }
      if (index == count - 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (next != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: SurahNavTile(
                  label: loc.quranNextSurah,
                  surah: next,
                  language: language,
                  forward: true,
                  onTap: () => _openSurah(next),
                ),
              ),
            _SourceNote(translationEdition: text.translationEdition),
          ],
        );
      }
      switch (mode) {
        case QuranViewMode.ayah:
          final ayah = ayahs[index - 1];
          return SingleAyahItem(
            registry: _registry,
            index: index,
            ayah: ayah.number,
            child: _AyahCard(
              ayah: ayah,
              fontScale: _fontScale,
              translationScale: _translationScale,
              bookmarked: bookmarked == ayah.number,
              highlighted:
                  _flashAyah == ayah.number || _playingAyah == ayah.number,
              onBookmark: () => _setBookmark(ayah.number, toggle: true),
              onLongPress: () => _setBookmark(ayah.number, toggle: false),
              onShare: () => _share(ayah),
            ),
          );
        case QuranViewMode.page:
          final group = groups![index - 1];
          return MushafPage(
            registry: _registry,
            index: index,
            group: group,
            label: quranPageLabel(loc, group, surahName: surahName),
            fontScale: _fontScale,
            selectedAyah: selected,
            bookmarkedAyah: bookmarked,
            onAyahTap: _openAyahSheet,
          );
        case QuranViewMode.translation:
          final group = groups![index - 1];
          return TranslationPage(
            registry: _registry,
            index: index,
            group: group,
            label: quranPageLabel(loc, group, surahName: surahName),
            translationScale: _translationScale,
            selectedAyah: selected,
            bookmarkedAyah: bookmarked,
            onAyahTap: _openAyahSheet,
          );
      }
    }

    return KeyedSubtree(
      key: _viewportKey,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Kullanıcı kaydırınca dinlenen ayet bir süre izlenmez
          if (notification is ScrollStartNotification &&
              notification.dragDetails != null) {
            _userScrolledAt = DateTime.now();
          }
          if (notification is ScrollEndNotification &&
              notification.depth == 0 &&
              !_jumping) {
            _scheduleVisibleCheck();
          }
          return false;
        },
        child: CustomScrollView(
          key: ValueKey(_generation),
          controller: _controller,
          center: _centerKey,
          slivers: [
            // Merkezden önceki öğeler ters sırayla yukarı doğru dizilir
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => item(center - 1 - i),
                childCount: center,
              ),
            ),
            SliverList(
              key: _centerKey,
              delegate: SliverChildBuilderDelegate(
                (context, i) => item(center + i),
                childCount: count - center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showSnack(ScaffoldMessengerState? messenger, String text) {
  if (messenger == null || !messenger.mounted) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
}

/// Ayetin Arapça metni (Amiri, sağdan sola); boyut [fontScale] ile
TextStyle _arabicStyle(BuildContext context, double fontScale) => TextStyle(
  fontFamily: AppTheme.arabicFamily,
  fontSize: 26 * fontScale,
  height: 2,
  color: Theme.of(context).colorScheme.onSurface,
);

class _SurahHeader extends StatelessWidget {
  final Surah surah;
  final String language;
  final String? bismillah;
  final double fontScale;

  const _SurahHeader({
    required this.surah,
    required this.language,
    required this.bismillah,
    required this.fontScale,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final info =
        '${surah.isMedinan ? loc.quranMedinan : loc.quranMeccan} · '
        '${loc.quranAyahCount(surah.ayahCount)}';
    return AppCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Column(
        children: [
          Text(
            surah.arabicName,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: AppTheme.arabicFamily,
              fontSize: 30,
              height: 1.5,
              color: scheme.primary,
            ),
          ),
          if (language != 'ar')
            Text(
              surah.displayName(language),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            info,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (bismillah != null) ...[
            const Divider(height: AppSpacing.xl),
            Text(
              bismillah!,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: _arabicStyle(context, fontScale),
            ),
          ],
        ],
      ),
    );
  }
}

class _AyahCard extends StatelessWidget {
  final QuranAyah ayah;
  final double fontScale;
  final double translationScale;
  final bool bookmarked;

  /// "Ayete git" ile gelinen ayet (kısa süre)
  final bool highlighted;
  final VoidCallback onBookmark;
  final VoidCallback onLongPress;
  final VoidCallback onShare;

  const _AyahCard({
    required this.ayah,
    required this.fontScale,
    required this.translationScale,
    required this.bookmarked,
    required this.highlighted,
    required this.onBookmark,
    required this.onLongPress,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final translation = ayah.translation;
    // Yer imi / gelinen ayet: hafif marka tonu (opak; arka plan resminde de
    // okunur)
    final cardColor = theme.cardTheme.color ?? scheme.surfaceContainerLowest;
    final tint = highlighted ? 0.8 : (bookmarked ? 0.5 : 0.0);
    final color = tint == 0
        ? null
        : Color.alphaBlend(
            scheme.primaryContainer.withValues(alpha: tint),
            cardColor,
          );

    return AppCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      padding: EdgeInsets.zero,
      color: color,
      child: InkWell(
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.xs,
                0,
              ),
              child: Row(
                children: [
                  QuranNumberBadge(number: ayah.number),
                  const Spacer(),
                  IconButton(
                    tooltip: bookmarked
                        ? loc.quranBookmarkRemove
                        : loc.quranBookmarkSave,
                    onPressed: onBookmark,
                    icon: Icon(
                      bookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: bookmarked ? scheme.primary : null,
                    ),
                  ),
                  IconButton(
                    tooltip: loc.quranShareAyah,
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ayah.arabic,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.start,
                    style: _arabicStyle(context, fontScale),
                  ),
                  if (translation != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      translation,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontSize: 16 * translationScale,
                        height: 1.55,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Metin kaynağı: Tanzil (koşulu: kaynak ve tanzil.net bağlantısı belirtilir)
/// ve meal sahibi
class _SourceNote extends StatelessWidget {
  final String? translationEdition;

  const _SourceNote({required this.translationEdition});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final edition = translationEdition;
    final translator = edition == null
        ? null
        : QuranEdition.translatorOf(edition);
    return AppCard(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(loc.quranTextSource, style: style),
          if (translator != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(loc.quranTranslationSource(translator), style: style),
          ],
        ],
      ),
    );
  }
}
