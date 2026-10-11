/// Zikirmatik saf hesapları (arayüzden bağımsız, test edilebilir): hedef
/// halkası, tur sayımı ve zikir listesinde önceki/sonraki.
library;

/// Tur kipinde ("Hedefte sıfırdan devam et") kaydedilen/gösterilen sayaç:
/// hedefi aşan sayaç (tur kipi sonradan açıldı, sayaç elle büyütüldü ya da
/// hedef küçültüldü) tamamlanan turlara aktarılır, sayaç her zaman hedefin
/// altında kalır. Hedef ve tur en az 1, sayaç en az 0 sayılır.
({int count, int round}) carryRounds(int count, int target, int round) {
  final t = target < 1 ? 1 : target;
  final r = round < 1 ? 1 : round;
  final c = count < 0 ? 0 : count;
  return (count: c % t, round: r + c ~/ t);
}

/// Sayaç ekranında gösterilen değerler: büyük sayı, hedef halkası ve tur.
///
/// Tur kipi kapalıyken (varsayılan) sayaç toplamdır; halka hedefin her katında
/// dolar (33'te dolu, 34'te 2. turun 1'i) ve tur toplamdan hesaplanır. Tur
/// kipinde sayaç turun içindeki sayıdır (hedefe gelince sıfırlanır), tur
/// kayıtlıdır.
class ZikirProgress {
  /// Büyük sayı: toplam (tur kipinde turun içindeki sayı)
  final int count;

  /// Halkadaki ve "27 / 33"teki ilerleme (0..hedef)
  final int inRound;

  /// Hedef (en az 1)
  final int target;

  /// Kaçıncı tur (en az 1)
  final int round;

  /// Tur kipi açık: tur her zaman gösterilir
  final bool roundMode;

  /// Hedefe ulaşıldı: kapalı kipte hedefin katında, tur kipinde yeni turun
  /// başında (sayaç sıfırlandı, sonraki dokunuşa kadar)
  final bool reached;

  const ZikirProgress._({
    required this.count,
    required this.inRound,
    required this.target,
    required this.round,
    required this.roundMode,
    required this.reached,
  });

  factory ZikirProgress.of({
    required int count,
    required int target,
    int round = 1,
    bool roundMode = false,
  }) {
    final t = target < 1 ? 1 : target;
    if (roundMode) {
      final carried = carryRounds(count, t, round);
      return ZikirProgress._(
        count: carried.count,
        inRound: carried.count,
        target: t,
        round: carried.round,
        roundMode: true,
        reached: carried.round > 1 && carried.count == 0,
      );
    }
    final c = count < 0 ? 0 : count;
    final r = c == 0 ? 1 : (c - 1) ~/ t + 1;
    return ZikirProgress._(
      count: c,
      inRound: c - (r - 1) * t,
      target: t,
      round: r,
      roundMode: false,
      reached: c > 0 && c % t == 0,
    );
  }

  /// Halkanın dolu kısmı (0..1)
  double get fraction => (inRound / target).clamp(0.0, 1.0);

  /// "Tur N" gösterilir mi: tur kipinde her zaman, değilse 2. turdan itibaren
  bool get showRound => roundMode || round > 1;
}

/// Başlık kartında kaydırınca / oklarla geçilen zikir: seçili zikir temel +
/// kullanıcının zikirlerindeyse ([main]) o listede, Esmâ-ül Hüsnâ'daysa
/// ([esma]) onda; uçlarda başa/sona döner. Listede olmayan (silinmiş) zikirden
/// ileri ilk, geri son zikre gidilir. [step] +1 sonraki, -1 önceki.
String adjacentDhikr({
  required String current,
  required List<String> main,
  required List<String> esma,
  required int step,
}) {
  final list = main.contains(current) || !esma.contains(current) ? main : esma;
  if (list.isEmpty || step == 0) return current;
  final index = list.indexOf(current);
  if (index < 0) return step > 0 ? list.first : list.last;
  return list[(index + step) % list.length];
}
