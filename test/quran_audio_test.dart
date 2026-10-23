// Kur'an dinleme: ara sunucu yanıtlarının ayrıştırılması (sadece https, ayet
// zamanları), hata eşleme, oturum önbelleği, kârî seçimi; oynatıcı sahte ses
// katmanıyla (ayet izleme, ayet/sure tekrarı, atlama, hata, kârî değişimi,
// durdurma, geç gelen eski yanıt).
import 'dart:async';

import 'package:ezan_saati/data/services/quran_audio_service.dart';
import 'package:ezan_saati/features/quran/audio/quran_player.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'quran_audio_fakes.dart';

void main() {
  late FakeAudioServer server;
  late FakeAudioEngine engine;
  late int engines;
  late QuranPlayer player;

  QuranPlayer newPlayer() => QuranPlayer(
    service: QuranAudioService(api: fakeAudioApi, get: server.get),
    engine: (channel) async {
      engines++;
      return engine;
    },
  );

  Future<void> start(int surah, {int fromAyah = 1, String lang = 'tr'}) =>
      player.start(
        surah: surah,
        title: 'Sure $surah',
        album: "Kur'an-ı Kerim",
        language: lang,
        channelName: "Kur'an dinleme",
        fromAyah: fromAyah,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    QuranAudioService.clearCache();
    server = FakeAudioServer();
    engine = FakeAudioEngine();
    engines = 0;
    player = newPlayer();
  });

  group('QuranAudioService', () {
    test('adres yoksa ya da https değilse kapalı', () async {
      expect(
        QuranAudioService.configured,
        isFalse,
      ); // testte derleme değeri yok
      for (final api in ['', 'http://a.example', 'ftp://a', 'https://']) {
        await expectLater(
          QuranAudioService(api: api, get: server.get).reciters('tr'),
          throwsA(
            isA<QuranAudioException>().having(
              (e) => e.failure,
              'failure',
              QuranAudioFailure.unavailable,
            ),
          ),
          reason: api,
        );
      }
      expect(server.requests, isEmpty);
    });

    test('kullanılabilirlik: kârî listesi gelirse açık, sunucu kapalıysa ya '
        'da adres yoksa kapalı', () async {
      expect(
        await QuranAudioService(api: '', get: server.get).isAvailable('tr'),
        isFalse,
      );
      server.status = 503;
      final service = QuranAudioService(api: fakeAudioApi, get: server.get);
      expect(await service.isAvailable('tr'), isFalse);
      server.status = 200;
      expect(await service.isAvailable('tr'), isTrue);
      expect(await service.isAvailable('tr'), isTrue);
      expect(server.requests, hasLength(2)); // başarılı liste oturumda kalır
    });

    test('istek adresleri, oturum önbelleği', () async {
      final service = QuranAudioService(api: fakeAudioApi, get: server.get);
      final reciters = await service.reciters('tr');
      expect(reciters.map((r) => (r.id, r.name, r.style)), [
        (3, 'Abu Bakr al-Shatri', 'Murattal'),
        (9, 'Mishari Rashid al-`Afasy', ''),
      ]);
      await service.chapter(9, 112);
      await service.reciters('tr');
      await service.chapter(9, 112);
      expect(server.requests.map((u) => u.toString()), [
        'https://audio.example/base/v1/reciters?lang=tr',
        'https://audio.example/base/v1/chapter/9/112',
      ]);
    });

    test('hata eşleme: ağ yok, 404, diğer durumlar', () async {
      final service = QuranAudioService(api: fakeAudioApi, get: server.get);
      Future<QuranAudioFailure?> failure(Future<Object?> call) async {
        try {
          await call;
          return null;
        } on QuranAudioException catch (e) {
          return e.failure;
        }
      }

      expect(await failure(service.chapter(9, 99)), QuranAudioFailure.notFound);
      server.status = 503;
      expect(
        await failure(service.reciters('en')),
        QuranAudioFailure.unavailable,
      );
      server
        ..status = 200
        ..offline = true;
      expect(await failure(service.chapter(9, 1)), QuranAudioFailure.offline);
    });

    test('ayrıştırma: bozuk kârî atlanır; ses sadece https; zaman listesi '
        'bozuksa zamansız', () {
      expect(
        QuranAudioService.parseReciters({
          'reciters': [
            {'id': 1, 'name': ' A '},
            {'id': '2', 'name': 'B'},
            {'id': 3, 'name': ''},
            {'id': 4},
          ],
        }).map((r) => r.name),
        ['A'],
      );
      expect(QuranAudioService.parseReciters('x'), isEmpty);
      expect(
        QuranAudioService.parseChapter({'url': 'http://a.example/1.mp3'}),
        isNull,
      );
      expect(QuranAudioService.parseChapter({'url': 'file:///1.mp3'}), isNull);
      final timed = QuranAudioService.parseChapter(fakeChapterJson(1))!;
      expect(timed.verses, hasLength(3));
      for (final bad in [
        [
          [0, 10],
          [5, 4],
        ],
        [
          [100, 200],
          [50, 300],
        ],
        [
          [0, 10, 5],
        ],
        [
          ['0', 10],
        ],
      ]) {
        final audio = QuranAudioService.parseChapter({
          'url': 'https://download.quranicaudio.com/1.mp3',
          'verses': bad,
        })!;
        expect(audio.hasTimings, isFalse, reason: '$bad');
      }
    });

    test('konumdaki ayet, ayet başı / sonu', () {
      final audio = QuranAudioService.parseChapter(fakeChapterJson(1))!;
      // 1: 500-1400, 2: 1500-2400, 3: 2500-3400
      expect(audio.ayahAt(Duration.zero), 1); // besmele / giriş
      expect(audio.ayahAt(const Duration(milliseconds: 1450)), 1);
      expect(audio.ayahAt(const Duration(milliseconds: 1500)), 2);
      expect(audio.ayahAt(const Duration(seconds: 9)), 3);
      expect(audio.startOf(2), const Duration(milliseconds: 1500));
      expect(audio.endOf(3), const Duration(milliseconds: 3400));
      expect(audio.startOf(0), isNull);
      expect(audio.startOf(4), isNull);
      final untimed = QuranChapterAudio(url: Uri.parse('https://a/1.mp3'));
      expect(untimed.ayahAt(Duration.zero), isNull);
    });

    test('kârî seçimi: kayıtlı → Afasi → ilk', () {
      const list = [
        QuranReciter(id: 3, name: 'Abu Bakr al-Shatri'),
        QuranReciter(id: 9, name: 'Mishari Rashid al-`Afasy'),
      ];
      expect(QuranAudioService.pickReciter(list, 3).id, 3);
      expect(QuranAudioService.pickReciter(list, null).id, 9);
      expect(QuranAudioService.pickReciter(list, 77).id, 9);
      expect(
        QuranAudioService.pickReciter(const [
          QuranReciter(id: 5, name: 'X'),
        ], null).id,
        5,
      );
      // Ad dile göre gelir (tr / ar)
      for (final name in ['Mişari Raşid el-Afasi', 'مشاري راشد العفاسي']) {
        expect(
          QuranAudioService.pickReciter([
            const QuranReciter(id: 3, name: 'Ebû Bekir eş-Şâtırî'),
            QuranReciter(id: 7, name: name),
          ], null).id,
          7,
          reason: name,
        );
      }
    });

    test('ses sadece Quran Foundation / Quran.com sunucularından', () {
      for (final url in [
        'https://evil.example/1.mp3',
        'https://quranicaudio.com.evil.example/1.mp3',
        'https://u:p@download.quranicaudio.com/1.mp3',
      ]) {
        expect(QuranAudioService.parseChapter({'url': url}), isNull);
      }
      for (final url in [
        'https://download.quranicaudio.com/qdc/1.mp3',
        'https://verses.quran.foundation/Alafasy/mp3/001001.mp3',
      ]) {
        expect(QuranAudioService.parseChapter({'url': url}), isNotNull);
      }
    });
  });

  group('QuranPlayer', () {
    test('başlatma: kârî listesi, ayetin başından açılır ve çalar; '
        'konum ayeti izler', () async {
      final states = <bool>[];
      player.addListener(() => states.add(player.loading));
      await start(1, fromAyah: 2);
      expect(states.first, isTrue);
      expect(player.loading, isFalse);
      expect(player.reciter!.id, 9); // kayıt yok: Afasi
      expect(engine.calls, ['open 1500', 'play']);
      expect(engine.title, 'Sure 1');
      expect(engine.artist, 'Mishari Rashid al-`Afasy');
      expect(player.playing, isTrue);
      expect(player.ayah, 2);
      engine.at(2600);
      expect(player.ayah, 3);
      expect(player.position.value, const Duration(milliseconds: 2600));
      expect(engines, 1);
    });

    test('ayet tekrarı: ayetin sonunda başına döner; son ayette dosya '
        'bitince de; sure tekrarı döngü', () async {
      await start(1);
      engine.at(1600); // 2. ayet
      await player.cycleRepeat();
      expect(player.repeat, QuranRepeat.ayah);
      expect(engine.looping, isFalse);
      engine.calls.clear();
      engine.at(2400);
      expect(engine.calls, ['seek 1500']);
      await player.seekAyah(7); // son ayet
      engine.calls.clear();
      engine.finish();
      expect(engine.calls, ['seek 6500', 'play']);
      await player.cycleRepeat();
      expect(player.repeat, QuranRepeat.surah);
      expect(engine.looping, isTrue);
      await player.cycleRepeat();
      expect(player.repeat, QuranRepeat.off);
      expect(engine.looping, isFalse);
    });

    test('ayet zamanı olmayan kayıtta ayet tekrarı atlanır', () async {
      server.ayahs[5] = 0;
      await start(5);
      expect(player.audio!.hasTimings, isFalse);
      await player.cycleRepeat();
      expect(player.repeat, QuranRepeat.surah);
      expect(engine.looping, isTrue);
    });

    test('ilk yükleme sürerken ikinci "Dinle" ikinci oynatıcı açmaz', () async {
      final gate = Completer<void>();
      player = QuranPlayer(
        service: QuranAudioService(api: fakeAudioApi, get: server.get),
        engine: (channel) async {
          engines++;
          await gate.future;
          return engine;
        },
      );
      final first = start(1);
      await pumpEventQueue();
      expect(engines, 1);
      final second = start(2);
      await pumpEventQueue();
      gate.complete();
      await first;
      await second;
      expect(engines, 1);
      expect(engine.url.toString(), endsWith('/2.mp3'));
      expect(player.playing, isTrue);
    });

    test('önceki / sonraki ayet sınırlarda kalır; bitince oynat baştan '
        'başlatır', () async {
      await start(2);
      await player.previous();
      expect(player.ayah, 1);
      await player.next();
      await player.next();
      await player.next();
      expect(player.ayah, 3);
      engine.calls.clear();
      engine.finish();
      // just_audio sonda çalıyor kalır: duraklatılır ki oynat yeniden çalsın
      expect(player.playing, isFalse);
      expect(engine.calls, ['pause']);
      await player.toggle();
      expect(engine.calls, ['pause', 'seek 0', 'play']);
      await player.toggle();
      expect(engine.calls.last, 'pause');
    });

    test(
      'hata: kayıt yok / ağ yok / ses açılamadı; tekrar denenebilir',
      () async {
        await start(99);
        expect(player.failure, QuranAudioFailure.notFound);
        expect(player.loading, isFalse);
        expect(player.active, isTrue);
        server.offline = true;
        QuranAudioService.clearCache();
        player = newPlayer();
        await start(1);
        expect(player.failure, QuranAudioFailure.offline);
        server.offline = false;
        engine.failOpen = true;
        await start(1);
        expect(player.failure, QuranAudioFailure.offline);
        engine.failOpen = false;
        await start(1);
        expect(player.failure, isNull);
        expect(player.playing, isTrue);
      },
    );

    test('kârî değişince kaydedilir, aynı ayetten sürer; durdurunca ses '
        'katmanı kapanır', () async {
      await start(1);
      engine.at(2600);
      await player.setReciter(
        player.reciters.first,
        channelName: "Kur'an dinleme",
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(QuranAudioService.reciterKey), 3);
      expect(engine.artist, 'Abu Bakr al-Shatri');
      expect(engine.calls.where((c) => c.startsWith('open')).last, 'open 2500');
      // Yeni oynatıcı (uygulama yeniden açıldı) kayıtlı kârîyi seçer
      QuranAudioService.clearCache();
      final reopened = newPlayer();
      await reopened.start(
        surah: 2,
        title: 'Sure 2',
        album: '',
        language: 'tr',
        channelName: '',
      );
      expect(reopened.reciter!.id, 3);

      await player.stop();
      expect(engine.closed, isTrue);
      expect(player.active, isFalse);
      expect(player.ayah, isNull);
      engine.at(5000); // kapandıktan sonra gelen olay yok sayılır
      expect(player.position.value, Duration.zero);
    });

    test('art arda başlatmada geç gelen eski yanıt yok sayılır', () async {
      final first = start(1);
      final second = start(2);
      await Future.wait([first, second]);
      expect(player.surah, 2);
      expect(engine.calls.where((c) => c.startsWith('open')), hasLength(1));
      expect(
        engine.url.toString(),
        'https://download.quranicaudio.com/qdc/test/2.mp3',
      );
    });
  });
}
