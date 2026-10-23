import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../../data/services/quran_audio_service.dart';

/// Tekrar: kapalı, çalan ayet, bütün sure
enum QuranRepeat { off, ayah, surah }

/// Ses çalan katman (testte sahtesi kullanılır)
abstract class QuranAudioEngine {
  Stream<Duration> get positions;
  Stream<bool> get playing;
  Stream<void> get completed;

  /// [url] sesini [start] anından hazırlar; bildirimde [title] / [artist]
  Future<void> open(
    Uri url, {
    required String id,
    required String title,
    required String artist,
    required String album,
    Duration start,
  });
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setLooping(bool loop);

  /// Çalmayı bitirir; bildirim ve ön plan servisi kalkar
  Future<void> close();
}

typedef QuranAudioEngineFactory =
    Future<QuranAudioEngine> Function(String channelName);

/// just_audio + just_audio_background: ekran kapalıyken ve uygulama arka
/// plandayken çalar, kilit ekranında / bildirimde standart medya kontrolleri.
/// Arka plan katmanı ilk "Dinle"de bir kez kurulur (açılışı yavaşlatmaz).
/// Ses akışla çalınır; diske önbellek yazılmaz (QF içeriği saklanmaz).
class JustAudioEngine implements QuranAudioEngine {
  static Future<void>? _background;

  final AudioPlayer _player = AudioPlayer();

  JustAudioEngine._();

  static Future<QuranAudioEngine> create(String channelName) async {
    await (_background ??=
        JustAudioBackground.init(
          androidNotificationChannelId: 'com.mmdigital.vaktinde.quran_audio',
          androidNotificationChannelName: channelName,
          androidNotificationOngoing: true,
          // Adıyla çağrılır: res/raw/keep.xml'de korunur
          androidNotificationIcon: 'mipmap/launcher_icon',
        ).catchError((Object e) {
          _background = null;
          throw e;
        }));
    return JustAudioEngine._();
  }

  @override
  Stream<Duration> get positions => _player.positionStream;

  @override
  Stream<bool> get playing => _player.playingStream;

  @override
  Stream<void> get completed => _player.processingStateStream
      .where((state) => state == ProcessingState.completed)
      .map((_) {});

  @override
  Future<void> open(
    Uri url, {
    required String id,
    required String title,
    required String artist,
    required String album,
    Duration start = Duration.zero,
  }) => _player.setAudioSource(
    AudioSource.uri(
      url,
      tag: MediaItem(id: id, title: title, artist: artist, album: album),
    ),
    initialPosition: start,
  );

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setLooping(bool loop) =>
      _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);

  @override
  Future<void> close() => _player.dispose();
}

/// Kur'an dinleme durumu (uygulama boyunca tek): çalan sure ve ayet, kârî,
/// tekrar. Okuyucu çalan ayeti vurgular ve izler; konum [position]'da
/// (her karede bütün ekranı yenilemesin diye ayrı).
class QuranPlayer extends ChangeNotifier {
  static final QuranPlayer instance = QuranPlayer();

  final QuranAudioService _service;
  final QuranAudioEngineFactory _engineFactory;

  /// [service], [engine]: test için
  QuranPlayer({QuranAudioService? service, QuranAudioEngineFactory? engine})
    : _service = service ?? QuranAudioService(),
      _engineFactory = engine ?? JustAudioEngine.create;

  QuranAudioEngine? _engine;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// Her başlatma / durdurmada artar: geç gelen eski yanıt yok sayılır
  int _session = 0;

  int? _surah;
  String _title = '';
  String _album = '';
  String? _language;
  List<QuranReciter> _reciters = const [];
  QuranReciter? _reciter;
  QuranChapterAudio? _audio;
  int? _ayah;
  int? _repeatAyah;
  bool _playing = false;
  bool _loading = false;
  bool _completed = false;
  QuranAudioFailure? _failure;
  QuranRepeat _repeat = QuranRepeat.off;

  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);

  /// Dinleme açık (çubuk görünür)
  bool get active => _surah != null;
  int? get surah => _surah;
  String get title => _title;
  QuranReciter? get reciter => _reciter;
  List<QuranReciter> get reciters => _reciters;
  QuranChapterAudio? get audio => _audio;
  int? get ayah => _ayah;
  bool get playing => _playing;
  bool get loading => _loading;
  QuranAudioFailure? get failure => _failure;
  QuranRepeat get repeat => _repeat;

  /// [surah]'ı ([fromAyah] ayetinden) çalmaya başlar. [title] bildirimde sure
  /// adı, [album] "Kur'an-ı Kerim", [channelName] bildirim kanalının adı.
  Future<void> start({
    required int surah,
    required String title,
    required String album,
    required String language,
    required String channelName,
    int fromAyah = 1,
  }) async {
    final session = ++_session;
    _surah = surah;
    _title = title;
    _album = album;
    _audio = null;
    _ayah = fromAyah;
    _loading = true;
    _completed = false;
    _failure = null;
    position.value = Duration.zero;
    notifyListeners();
    try {
      if (_reciters.isEmpty || _language != language) {
        _reciters = await _service.reciters(language);
        _language = language;
        final saved = _reciter?.id ?? await QuranAudioService.loadReciterId();
        _reciter = QuranAudioService.pickReciter(_reciters, saved);
      }
      final reciter = _reciter!;
      final audio = await _service.chapter(reciter.id, surah);
      if (session != _session) return;
      final engine =
          _engine ?? await _attach(await _engineFactory(channelName));
      if (session != _session) return;
      await engine.open(
        audio.url,
        id: '${reciter.id}/$surah',
        title: title,
        artist: reciter.name,
        album: album,
        start: audio.startOf(fromAyah) ?? Duration.zero,
      );
      await engine.setLooping(_repeat == QuranRepeat.surah);
      if (session != _session) return;
      _audio = audio;
      _ayah = audio.hasTimings ? fromAyah : null;
      _repeatAyah = _ayah;
      _loading = false;
      notifyListeners();
      unawaited(engine.play().catchError((Object _) {}));
    } on QuranAudioException catch (e) {
      _fail(session, e.failure);
    } catch (_) {
      // Ses açılamadı (ağ kesildi, adres yanıt vermedi)
      _fail(session, QuranAudioFailure.offline);
    }
  }

  void _fail(int session, QuranAudioFailure failure) {
    if (session != _session) return;
    _loading = false;
    _failure = failure;
    notifyListeners();
  }

  Future<QuranAudioEngine> _attach(QuranAudioEngine engine) async {
    _engine = engine;
    _subscriptions
      ..add(engine.positions.listen(_onPosition))
      ..add(
        engine.playing.listen((playing) {
          if (playing == _playing) return;
          _playing = playing;
          if (playing) _completed = false;
          notifyListeners();
        }),
      )
      ..add(engine.completed.listen((_) => _onCompleted()));
    return engine;
  }

  void _onPosition(Duration value) {
    position.value = value;
    final audio = _audio;
    if (audio == null) return;
    final repeatAyah = _repeatAyah;
    if (_repeat == QuranRepeat.ayah && repeatAyah != null) {
      final end = audio.endOf(repeatAyah);
      if (end != null && value >= end) {
        _engine?.seek(audio.startOf(repeatAyah)!);
        return;
      }
    }
    final ayah = audio.ayahAt(value);
    if (ayah != _ayah) {
      _ayah = ayah;
      notifyListeners();
    }
  }

  void _onCompleted() {
    final audio = _audio;
    final repeatAyah = _repeatAyah;
    if (_repeat == QuranRepeat.ayah && audio != null && repeatAyah != null) {
      // Son ayet tekrarı: dosya sonu ayetin sonu
      _engine?.seek(audio.startOf(repeatAyah)!);
      _engine?.play();
      return;
    }
    _completed = true;
    _playing = false;
    notifyListeners();
  }

  Future<void> toggle() async {
    final engine = _engine;
    if (engine == null || _audio == null) return;
    if (_playing) {
      await engine.pause();
      return;
    }
    if (_completed) {
      _completed = false;
      await engine.seek(Duration.zero);
    }
    unawaited(engine.play().catchError((Object _) {}));
  }

  /// Ayete atlar (zaman yoksa bir şey yapmaz); tekrar ayet kipindeyse
  /// tekrarlanan ayet de o olur
  Future<void> seekAyah(int ayah) async {
    final engine = _engine;
    final start = _audio?.startOf(ayah);
    if (engine == null || start == null) return;
    _ayah = ayah;
    _repeatAyah = ayah;
    _completed = false;
    notifyListeners();
    await engine.seek(start);
    if (!_playing) unawaited(engine.play().catchError((Object _) {}));
  }

  Future<void> next() async {
    final ayah = _ayah;
    final count = _audio?.verses.length ?? 0;
    if (ayah != null && ayah < count) await seekAyah(ayah + 1);
  }

  Future<void> previous() async {
    final ayah = _ayah;
    if (ayah != null) await seekAyah(ayah > 1 ? ayah - 1 : 1);
  }

  /// Kapalı → ayet → sure → kapalı
  Future<void> cycleRepeat() async {
    _repeat =
        QuranRepeat.values[(_repeat.index + 1) % QuranRepeat.values.length];
    _repeatAyah = _ayah;
    notifyListeners();
    await _engine?.setLooping(_repeat == QuranRepeat.surah);
  }

  /// Kârî değişir (kaydedilir); çalıyorsa aynı ayetten yeni kârîyle sürer
  Future<void> setReciter(
    QuranReciter reciter, {
    required String channelName,
  }) async {
    if (reciter == _reciter) return;
    _reciter = reciter;
    await QuranAudioService.saveReciterId(reciter.id);
    final surah = _surah;
    final language = _language;
    if (surah == null || language == null) {
      notifyListeners();
      return;
    }
    await start(
      surah: surah,
      title: _title,
      album: _album,
      language: language,
      channelName: channelName,
      fromAyah: _ayah ?? 1,
    );
  }

  /// Dinlemeyi kapatır: ses durur, bildirim kalkar
  Future<void> stop() async {
    _session++;
    final engine = _engine;
    _engine = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _surah = null;
    _audio = null;
    _ayah = null;
    _repeatAyah = null;
    _playing = false;
    _loading = false;
    _completed = false;
    _failure = null;
    position.value = Duration.zero;
    notifyListeners();
    await engine?.close();
  }
}
