#!/usr/bin/env python3
"""Günün ayeti adaylarını üretir: assets/data/daily_ayahs.json.

Kullanım: python3 tool/daily_ayahs.py <tur-diyanetisleri.json>
Girdi: fawazahmed0/quran-api "tur-diyanetisleri" baskısı (Diyanet İşleri meali, Tanzil
tr.diyanet ile aynı; uygulama alquran.cloud'dan bu meali gösterir).

Ölçüt: meal 90-330 karakter; tek başına anlaşılır başlangıç (GOOD); ikinci kelime
öncesine bağlı zamir değil; karşılıklı konuşma yok; birlikte çevrilip aynı metni
paylaşan ayet grupları (Arapçayla eşleşmez) ve hurûf-ı mukattaa (kısa) hariç.
"""
import json
import re
import sys

GOOD = {'ey', 'de', 'allah', "allah'ın", "allah'a", 'allah,', "allah'tan", 'rabbimiz!', 'rabbimiz,',
        'rabbim!', 'doğrusu', 'şüphesiz', 'kim', 'kimi', 'her', 'insan', 'insanı', 'insanlar', 'göklerde',
        'göklerin', 'gökleri', 'biz', 'rabbin', 'rabbiniz', 'namazı', 'sabredin', 'inananlar', 'iman',
        'mallarını', 'iyilik', 'yerde', 'gökte'}
BAD_SECOND = {'bunu', 'bunda', 'böyle', 'onlar', 'onları', 'onlara', 'onların', 'bunlar', 'bunları', 'o',
              'onu', 'ona', 'onun', 'bu', 'şunlar', 'sizler'}
DIALOG = re.compile(r"\b(dedi|dediler|demişti|demiştir|diyordu|diyorlardı|demişlerdi|dedin|dedik|dedim|"
                    r"diyecekler|derler|der|diyerek|cevap|seslendi|seslenildi|sordu|sorarlar|sorduklarında)\b",
                    re.I)


def main(path):
    q = json.load(open(path, encoding='utf-8'))['quran']

    def ok(i):
        t = q[i - 1]['text']
        if (i > 1 and q[i - 2]['text'] == t) or (i < len(q) and q[i]['text'] == t):
            return False
        if not 90 <= len(t) <= 330 or t[0] in '("“\'':
            return False
        w = [x.lower().replace('i̇', 'i') for x in t.split()]
        if w[0].endswith(':') or w[0] not in GOOD:
            return False
        if len(w) > 1 and w[1].strip(',;:') in BAD_SECOND:
            return False
        return not DIALOG.search(t)

    nums = [i for i in range(1, len(q) + 1) if ok(i)]
    doc = {'about': 'Günün ayeti adayları (genel ayet numarası 1-6236). Diyanet İşleri meali 90-330 karakter; '
                    'tek başına anlaşılır başlangıç (Ey…, De ki…, Allah…, Rabbimiz…, Doğrusu…, Kim…, Her…); '
                    'karşılıklı konuşma, öncesine bağlı zamir ve birlikte çevrilmiş ayet grupları hariç. '
                    'Üretim: tool/daily_ayahs.py',
           'ayahs': nums}
    with open('assets/data/daily_ayahs.json', 'w', encoding='utf-8') as fh:
        fh.write(json.dumps(doc, ensure_ascii=False, separators=(',', ':')))
    print(len(nums), 'ayet')


if __name__ == '__main__':
    main(sys.argv[1])
