import 'dart:convert';
import 'dart:math' as math;

import '../../features/imsakiye/imsakiye_logic.dart';
import 'prayer_tracker.dart';
import 'quran_service.dart';

/// Medine mushafının (Hafs, 604 sayfa) sayfa başları: assets/data/quran_pages.json,
/// sayfa n → ilk ayeti [sure, ayet]. quran-meta'nın PageList'inden (MIT;
/// atıf quran_pages_LICENSE.txt); alquran.cloud'un `page` alanıyla aynı
/// sayfalama (test/hatim_test.dart).
class QuranPages {
  static const String asset = 'assets/data/quran_pages.json';

  /// Sayfa başları (sayfa 1 → ilk öge)
  final List<({int surah, int ayah})> starts;

  const QuranPages._(this.starts);

  /// [QuranService.pageCount] kayıt, sırayla artan; değilse null
  static QuranPages? parse(String raw) {
    try {
      final data = jsonDecode(raw);
      if (data is! List || data.length != QuranService.pageCount) return null;
      final starts = <({int surah, int ayah})>[];
      for (final e in data) {
        if (e is! List || e.length != 2) return null;
        final surah = e[0];
        final ayah = e[1];
        if (surah is! int || surah < 1 || surah > QuranService.surahCount) {
          return null;
        }
        if (ayah is! int || ayah < 1) return null;
        if (starts.isNotEmpty && !_before(starts.last, surah, ayah)) {
          return null;
        }
        starts.add((surah: surah, ayah: ayah));
      }
      return QuranPages._(List.unmodifiable(starts));
    } on FormatException {
      return null;
    }
  }

  static bool _before(({int surah, int ayah}) start, int surah, int ayah) =>
      start.surah < surah || (start.surah == surah && start.ayah < ayah);

  /// Sayfanın ilk ayeti ([page] 1–604 aralığına çekilir)
  ({int surah, int ayah}) startOf(int page) =>
      starts[page.clamp(1, starts.length) - 1];

  /// Cüzün ([juz] 1–30) başladığı sayfa
  int juzStartPage(int juz) {
    final start = QuranService.juzStarts[juz.clamp(1, 30) - 1];
    return pageOf(start.surah, start.ayah);
  }

  /// Cüzün okunmuş sayılması için bitirilmesi gereken son sayfa: sonraki
  /// cüzün başladığı sayfadan önceki (sayfa ortasında başlıyorsa o sayfa
  /// sonraki cüzle okunur, hiçbir ayet atlanmaz)
  int juzEndPage(int juz) =>
      juz >= 30 ? starts.length : juzStartPage(juz + 1) - 1;

  /// Ayetin sayfası: başı ayetten sonra olmayan son sayfa
  int pageOf(int surah, int ayah) {
    var low = 0;
    var high = starts.length - 1;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (_before(starts[mid], surah, ayah + 1)) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low + 1;
  }
}

/// Hatim planı: Kur'an'ı [start] gününden [target] gününe (dahil) kadar
/// baştan sona okuma. [position]: okunup bitirilen son sayfa (0: başlanmadı,
/// [pageCount]: hatim [finished] günü bitti; okumaya [position] + 1. sayfadan
/// devam edilir); [log]: gün ("yyyy-MM-dd") → o gün okunan sayfa (son
/// [keepDays] gün). Saf hesaplar (test edilebilir).
class HatimPlan {
  static const int pageCount = QuranService.pageCount;
  static const int keepDays = 60;

  /// Okuyucuda atlamayla (açılış, "Ayete git", sure geçişi) sayılan en çok
  /// ilerleme (sayfa): daha uzak atlama okuma sayılmaz
  static const int maxStep = 2;

  /// Hatırlatma bu kadar gün ileriye kurulur (her gün ayrı bildirim; açılışta
  /// pencere ilerler)
  static const int reminderDays = 7;

  /// Plan seçenekleri: hedef bugünden 30 gün, 2 ay, 4 ay sonra (baştan
  /// başlayınca günlük hedef tam 20 / 10 / 5 sayfa)
  static const List<int> optionDays = [30, 60, 120];

  /// "Ramazan'da hatim" seçeneği Ramazan'dan en çok bu kadar gün önce çıkar
  static const int ramadanLeadDays = 15;

  /// Niyet notunun en çok uzunluğu
  static const int noteMaxLength = 80;

  final DateTime start;
  final DateTime target;
  final int position;
  final Map<String, int> log;
  final DateTime? finished;

  /// Niyet (ör. "Annemin ruhu için"); yoksa null
  final String? note;

  const HatimPlan({
    required this.start,
    required this.target,
    required this.position,
    required this.log,
    this.finished,
    this.note,
  });

  /// Bugün başlayan yeni hatim
  factory HatimPlan.begin(DateTime today, DateTime target) => HatimPlan(
    start: PrayerTracker.day(today),
    target: PrayerTracker.day(target),
    position: 0,
    log: const {},
  );

  /// Boşlukları atılmış, [noteMaxLength] karaktere kısaltılmış not; boşsa null
  static String? cleanNote(String? note) {
    final text = note?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
    if (text.isEmpty) return null;
    return text.length <= noteMaxLength
        ? text
        : text.substring(0, noteMaxLength).trimRight();
  }

  bool get isFinished => position >= pageCount;

  /// İlerleme (0–1; yüzde aşağı yuvarlanır: bitmeden %100 görünmez)
  double get progress => (position * 100 ~/ pageCount) / 100;

  /// [day] günü okunan sayfa
  int readOn(DateTime day) => log[PrayerTracker.dateKey(day)] ?? 0;

  /// [remaining] sayfanın [days] günde (bugün dahil) okunması için günlük
  /// hedef, en az 1; gün kalmadıysa kalanın tamamı
  static int goalFor(int remaining, int days) =>
      math.max(1, days < 1 ? remaining : (remaining / days).ceil());

  /// "Ramazan'da hatim" hedefi: Ramazan'daysa ya da başlamasına en çok
  /// [ramadanLeadDays] gün varsa Ramazan'ın son günü, değilse null
  static DateTime? ramadanTarget(RamadanCalendar calendar, DateTime today) {
    final range = calendar.currentOrNext(today);
    return PrayerTracker.daysBetween(today, range.start) <= ramadanLeadDays
        ? range.end
        : null;
  }

  /// Bugünün başında kalan sayfa
  int remainingOn(DateTime today) =>
      math.min(pageCount, pageCount - position + readOn(today));

  /// Bugünün hedefi: bugünün başında kalan sayfa / hedef güne kalan gün
  /// (bugün dahil). Gün içinde okudukça değişmez; geride kalınca artar,
  /// öndeyken azalır; hedef gün geçtiyse kalanın tamamı.
  int dailyGoal(DateTime today) =>
      goalFor(remainingOn(today), PrayerTracker.daysBetween(today, target) + 1);

  /// Bugünkü okumanın sayfaları: günün başındaki konumdan sonraki sayfadan
  /// günlük hedef kadar (son sayfayı aşmaz)
  ({int from, int to}) todayRange(DateTime today) {
    final from = position - readOn(today) + 1;
    return (from: from, to: math.min(pageCount, from + dailyGoal(today) - 1));
  }

  /// "Okudum": bugünkü okuma bitirildi (konum aralığın sonuna gelir); hedef
  /// zaten tamamsa ya da hatim bittiyse null
  HatimPlan? withTodayRead(DateTime today) {
    final to = todayRange(today).to;
    return isFinished || to <= position ? null : _moved(to, today);
  }

  /// Cüz ızgarası: [juz] okundu, okunuyor (sıradaki sayfa bu cüzde) ya da
  /// okunmadı
  HatimJuzState juzState(QuranPages pages, int juz) {
    if (position >= pages.juzEndPage(juz)) return HatimJuzState.done;
    return position + 1 >= pages.juzStartPage(juz)
        ? HatimJuzState.current
        : HatimJuzState.pending;
  }

  /// Cüze dokunuldu: okunmadıysa sonuna kadar okundu, okunduysa o cüz ve
  /// sonrası okunmadı sayılır
  HatimPlan withJuzToggled(QuranPages pages, int juz, DateTime today) =>
      juzState(pages, juz) == HatimJuzState.done
      ? withPosition(pages.juzStartPage(juz) - 1, today)
      : withPosition(pages.juzEndPage(juz), today);

  /// Toplu hatim: 30 cüz [people] kişiye sırayla, olabildiğince eşit
  /// paylaştırılır (ilk kişilere birer fazla); kişi sayısı 1–30
  static List<({int from, int to})> juzShares(int people) {
    final count = people.clamp(1, 30);
    final shares = <({int from, int to})>[];
    var next = 1;
    for (var i = 0; i < count; i++) {
      final size = 30 ~/ count + (i < 30 % count ? 1 : 0);
      shares.add((from: next, to: next + size - 1));
      next += size;
    }
    return shares;
  }

  /// Okuyucuda [page] sayfası bitirildi: konum ileri gider (fark bugüne
  /// yazılır; sıranın denetimi okuyucuda); geri dönüşte ya da bitmiş hatimde
  /// null
  HatimPlan? advancedTo(int page, DateTime today) =>
      isFinished || page <= position
      ? null
      : _moved(math.min(page, pageCount), today);

  /// "Sayfa Gir" (basılı mushaftan okuyan) ve cüz ızgarası: konum [page]
  /// olur (0–604); bugünün kaydı fark kadar değişir, 0'ın altına inmez
  HatimPlan withPosition(int page, DateTime today) =>
      _moved(page.clamp(0, pageCount), today);

  /// "Planı Değiştir": konum ve kayıt korunur
  HatimPlan withTarget(DateTime target) => HatimPlan(
    start: start,
    target: PrayerTracker.day(target),
    position: position,
    log: log,
    finished: finished,
    note: note,
  );

  /// Niyet değişti (boş: kaldırılır)
  HatimPlan withNote(String? note) => HatimPlan(
    start: start,
    target: target,
    position: position,
    log: log,
    finished: finished,
    note: cleanNote(note),
  );

  HatimPlan _moved(int page, DateTime today) {
    final key = PrayerTracker.dateKey(today);
    final read = math.max(0, (log[key] ?? 0) + page - position);
    return HatimPlan(
      start: start,
      target: target,
      position: page,
      log: _prune({...log, key: read}, today),
      finished: page >= pageCount
          ? (finished ?? PrayerTracker.day(today))
          : null,
      note: note,
    );
  }

  /// Boş ve [keepDays] günden eski kayıtlar atılır
  static Map<String, int> _prune(Map<String, int> log, DateTime today) {
    final cutoff = PrayerTracker.dateKey(
      PrayerTracker.addDays(today, -keepDays),
    );
    return {
      for (final MapEntry(:key, :value) in log.entries)
        if (value > 0 && key.compareTo(cutoff) >= 0) key: value,
    };
  }

  /// Bugünün hedefi tamam (hatırlatma bugün çalmaz)
  bool goalMetOn(DateTime today) => readOn(today) >= dailyGoal(today);

  /// Hatırlatmaların çalacağı anlar ([minute]: günün dakikası): bugünden
  /// başlayarak [reminderDays] gün; bugünün hedefi tamamsa ya da saati
  /// geçtiyse bugün yok. Bitmiş hatimde boş (kurulu olanlar iptal edilir).
  List<DateTime> reminderTimes(int minute, DateTime now) {
    if (isFinished) return const [];
    final today = PrayerTracker.day(now);
    final times = <DateTime>[];
    for (var i = 0; i < reminderDays; i++) {
      final day = PrayerTracker.addDays(today, i);
      final at = DateTime(
        day.year,
        day.month,
        day.day,
        minute ~/ 60,
        minute % 60,
      );
      if (i == 0 && (!at.isAfter(now) || goalMetOn(today))) continue;
      times.add(at);
    }
    return times;
  }

  String encode() => jsonEncode({
    'start': PrayerTracker.dateKey(start),
    'target': PrayerTracker.dateKey(target),
    'position': position,
    'log': log,
    if (finished != null) 'finished': PrayerTracker.dateKey(finished!),
    if (note != null) 'note': note,
  });

  /// Kayıtlı plan; bozuk ya da tutarsızsa (bitiş günü konumla uyuşmuyor) null
  static HatimPlan? parse(String? raw) {
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return null;
      DateTime? date(Object? value) =>
          value is String ? PrayerTracker.parseDateKey(value) : null;
      final start = date(data['start']);
      final target = date(data['target']);
      final position = data['position'];
      final log = data['log'];
      final finished = date(data['finished']);
      if (start == null || target == null || log is! Map) return null;
      if (position is! int || position < 0 || position > pageCount) return null;
      if ((position == pageCount) != (finished != null)) return null;
      final days = <String, int>{};
      for (final MapEntry(:key, :value) in log.entries) {
        if (key is! String || date(key) == null) return null;
        if (value is! int || value < 0) return null;
        days[key] = value;
      }
      final note = data['note'];
      return HatimPlan(
        start: start,
        target: target,
        position: position,
        log: days,
        finished: finished,
        note: note is String ? cleanNote(note) : null,
      );
    } on FormatException {
      return null;
    }
  }
}

/// Hatim ekranındaki cüz hücresinin durumu
enum HatimJuzState { done, current, pending }
