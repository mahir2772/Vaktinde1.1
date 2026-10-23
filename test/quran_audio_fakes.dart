// Kur'an dinleme testlerinin ortak sahteleri: ara sunucu (kârî listesi, sure
// sesi; 404, hata kodu, ağ yok) ve ses katmanı (olaylar eşzamanlı).
import 'dart:async';
import 'dart:convert';

import 'package:ezan_saati/features/quran/audio/quran_player.dart';
import 'package:http/http.dart' as http;

const String fakeAudioApi = 'https://audio.example/base';

Map<String, Object?> fakeChapterJson(int surah, {int ayahs = 3}) => {
  'url': 'https://download.quranicaudio.com/qdc/test/$surah.mp3',
  'verses': [
    for (var i = 0; i < ayahs; i++) [i * 1000 + 500, i * 1000 + 1400],
  ],
};

class FakeAudioServer {
  final List<Uri> requests = [];
  int status = 200;
  bool offline = false;
  Map<int, int> ayahs = {1: 7, 2: 3, 112: 4};

  Future<http.Response> get(Uri url) async {
    requests.add(url);
    if (offline) throw Exception('ağ yok');
    if (status != 200) return http.Response('{}', status);
    final parts = url.pathSegments;
    if (parts.contains('reciters')) {
      return http.Response(
        jsonEncode({
          'reciters': [
            {'id': 3, 'name': 'Abu Bakr al-Shatri', 'style': 'Murattal'},
            {'id': 9, 'name': 'Mishari Rashid al-`Afasy', 'style': ''},
          ],
        }),
        200,
      );
    }
    final surah = int.parse(parts.last);
    final count = ayahs[surah];
    if (count == null) return http.Response('{}', 404);
    return http.Response(jsonEncode(fakeChapterJson(surah, ayahs: count)), 200);
  }
}

class FakeAudioEngine implements QuranAudioEngine {
  final _positions = StreamController<Duration>.broadcast(sync: true);
  final _playing = StreamController<bool>.broadcast(sync: true);
  final _completed = StreamController<void>.broadcast(sync: true);
  final List<String> calls = [];
  Uri? url;
  String? title;
  String? artist;
  bool looping = false;
  bool closed = false;
  bool failOpen = false;

  @override
  Stream<Duration> get positions => _positions.stream;
  @override
  Stream<bool> get playing => _playing.stream;
  @override
  Stream<void> get completed => _completed.stream;

  void at(int ms) => _positions.add(Duration(milliseconds: ms));

  /// just_audio gibi: dosya bitince "çalıyor" kalır, sadece bitti olayı gelir
  void finish() => _completed.add(null);

  @override
  Future<void> open(
    Uri url, {
    required String id,
    required String title,
    required String artist,
    required String album,
    Duration start = Duration.zero,
  }) async {
    if (failOpen) throw Exception('açılamadı');
    this.url = url;
    this.title = title;
    this.artist = artist;
    calls.add('open ${start.inMilliseconds}');
  }

  @override
  Future<void> play() async {
    calls.add('play');
    _playing.add(true);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _playing.add(false);
  }

  @override
  Future<void> seek(Duration position) async =>
      calls.add('seek ${position.inMilliseconds}');

  @override
  Future<void> setLooping(bool loop) async => looping = loop;

  @override
  Future<void> close() async => closed = true;
}
