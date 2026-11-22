#!/usr/bin/env python3
"""Vaktinde Kasım 2026 sosyal medya paketi: 16 parça (karusel, dua kartı, video, hikâye).

Kullanım:
  python3 docs/marketing/make_kasim.py <ekran_klasörü> <çıkış_klasörü>
          [--sadece 03_kissa_yunus,04_dua_sabah] [--videosuz] [--zipsiz]

Ekranlar test/screenshots pazarlama çeşidinden (tr, 3x). Bildirim kartının Roboto yazısı için
PATH'te flutter olmalı (yoksa Poppins):
  SCREENSHOT_MARKETING=tr SCREENSHOT_DPR=3 SCREENSHOT_DIR=<ekran_klasörü> TZ=Europe/Istanbul \\
    flutter test test/screenshots/ --plain-name "tr: pazarlama"

Her parça <çıkış>/<NN_ad>/ altında (JPEG, kalite 93):
  karusel    1.jpg … n.jpg (1080×1350) + hikaye.jpg (1080×1920)
  dua kartı  gonderi.jpg (1080×1350) + hikaye.jpg
  video      video.mp4 (1080×1920, 30 fps, sessiz) + kapak.jpg (1080×1350) + hikaye.jpg
  etkileşim  hikaye.jpg (anket/soru çıkartmasının yeri boş bırakılır)
Ayrıca _onizleme.jpg ve kasim_<n>.zip (her biri ≤ 24 MB; takvim ilkinde).

Dini metinler betikte yazılmaz: uygulamanın doğrulanmış verilerinden harfi harfine okunur
(stories.json, duas.json, prayer_guide.json, esmaul_husna_tr.json). Takvim ve açıklamalar:
docs/marketing/kasim_takvimi.md. Dikey dosyalarda yazılar y 250–1570 arasında kalır.
"""
import argparse
import json
import math
import os
import subprocess
import sys
import zipfile
from concurrent.futures import ProcessPoolExecutor

from PIL import Image, ImageChops, ImageDraw, features

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import make_content as mc  # noqa: E402  (logo, yıldız, Arapça metin bloğu, ffmpeg)
import make_store_assets as sa  # noqa: E402  (zemin, yazı, telefon, kapsül)

S, SS = mc.S, mc.SS
WHITE, CREAM, GOLD, GLOW, SAND = sa.WHITE, sa.CREAM, sa.GOLD, sa.GLOW, sa.SAND
DEEP = (0, 63, 56)
POST, STORY = (1080, 1350), (1080, 1920)
FPS = 30
PILL = "Google Play'de Vaktinde"


def _data(name):
    with open(os.path.join(mc.REPO, 'assets', 'data', name), encoding='utf-8') as fh:
        return json.load(fh)


_DUAS = _data('duas.json')
STORIES = {s['id']: dict(s, category=c['title']['tr'])
           for c in _data('stories.json')['categories'] for s in c['items']}
DUAS = {d['id']: d for c in _DUAS['categories'] for d in c['duas']}
DHIKR_COUNT = len(_DUAS['dhikrs'])
GUIDE = _data('prayer_guide.json')
ESMA = _data('esmaul_husna_tr.json')
L = sa.ARB['tr']

# Kalıcı bildirim kartı: ana ekran görüntüsüyle aynı an (25 Ekim 2026 12:53, İstanbul/Kadıköy;
# ekranlar başka gün çekilirse burası da güncellenir)
CARD_TIMES = [('imsak', '05:54'), ('gunes', '07:19'), ('ogle', '12:53'), ('ikindi', '15:46'),
              ('aksam', '18:16'), ('yatsi', '19:36')]
CARD_NEXT = 3
CARD_PLACE = 'İstanbul, Kadıköy · 14 Cemaziyelevvel 1448'
CARD_LEFT = 2 * 3600 + 52 * 60 + 34
CARD_DY = 170  # telefonun üstünden; kart ana ekrandaki sıradaki vakit ve sayacı örter
# Vurgulanacak alanlar (ekran görüntüsü pikseli, 1233 genişlik)
HI_SILENT = (44, 470, 1189, 726)   # Alarmlar: "Sessiz modda da çal"
HI_HATIM = (78, 770, 1155, 1368)   # Hatim: bugünkü okuma, Devam Et, Okudum


# --- Öğeler: yükseklik (1x piksel) + render(tuval, çizici, x0, x1, y) --------------------------
class T:
    """Latin metin (Poppins): ortalı ya da sola yaslı; '|' tercih edilen satır kırılımı."""

    def __init__(self, text, size, w, kind='Regular', color=WHITE, lh=1.4, align='center', lines=40):
        self.t = sa.Txt(text, size, 'tr', kind=kind, color=color, lh=lh, max_w=w, max_lines=lines)
        self.align, self.height = align, self.t.height

    def render(self, c, d, x0, x1, y):
        if self.align == 'center':
            self.t.draw(d, (x0 + x1) / 2, y)
        else:
            self.t.draw(d, x0, y, 'start')


class Ar:
    """Arapça (Amiri, ortalı, sağdan sola)."""

    def __init__(self, text, size, w, color=WHITE, lh=1.75):
        self.b = mc.TextBlock(text, 'Amiri', size, color, lh, w, arabic=True)
        self.height = self.b.height

    def render(self, c, d, x0, x1, y):
        self.b.draw(d, (x0 + x1) / 2, y)


class Orn:
    height = 24

    def render(self, c, d, x0, x1, y):
        sa.ornament(d, (x0 + x1) / 2, y + 12)


class Chip:
    def __init__(self, text, size=26, color=CREAM):
        self.text, self.size, self.color = text, size, color
        self.height = size * 2.05

    def render(self, c, d, x0, x1, y):
        sa.chip(d, (x0 + x1) / 2, y + self.height / 2, self.text, 'tr', self.size, color=self.color)


class Col:
    """Alt alta öğeler: [(öğe, üst boşluk)]."""

    def __init__(self, items):
        self.items = items
        self.height = sum(g + e.height for e, g in items)

    def render(self, c, d, x0, x1, y):
        for e, g in self.items:
            y += g
            e.render(c, d, x0, x1, y)
            y += e.height


class Steps:
    """Numaralı (ya da yıldızlı) liste: işaret solda, metin sola yaslı; isteğe bağlı alt öğe."""

    def __init__(self, items, w, size, start=1, numbered=True):
        self.r, self.size, self.numbered = size * 0.78, size, numbered
        self.indent = 2 * self.r + size * 0.6
        self.gap = size * 0.72
        self.rows = []
        for i, item in enumerate(items):
            text, extra = item if isinstance(item, tuple) else (item, None)
            t = sa.Txt(text, size, 'tr', kind='Medium', color=WHITE, lh=1.34, max_w=w - self.indent, max_lines=8)
            off = self.r - t.top / 2  # ilk satırın büyük harf ortası işaretin ortasında
            h = max(2 * self.r, off + t.height) + (size * 0.45 + extra.height if extra else 0)
            self.rows.append((start + i, t, off, extra, h))
        self.height = sum(r[4] for r in self.rows) + self.gap * (len(self.rows) - 1)

    def render(self, c, d, x0, x1, y):
        r = self.r
        for n, t, off, extra, h in self.rows:
            cx, cy = x0 + r, y + r
            if self.numbered:
                d.ellipse((S(cx - r), S(cy - r), S(cx + r), S(cy + r)), fill=GOLD + (255,))
                nt = sa.Txt(str(n), self.size * 0.86, 'tr', kind='Bold', color=DEEP, max_w=200, max_lines=1)
                nt.draw(d, cx, sa.line_top(nt, cy))
            else:
                d.polygon([(S(a), S(b)) for a, b in mc.star_points(cx, cy, r * 0.55, 0.72)], fill=GOLD + (240,))
            t.draw(d, x0 + self.indent, y + off, 'start')
            if extra:
                extra.render(c, d, x0 + self.indent, x1, y + off + t.height + self.size * 0.45)
            y += h + self.gap


def fit(build, box, smax=1.0):
    """build(ölçek) → [(öğe, üst boşluk)]; smax'tan başlayıp kutuya sığana kadar küçültür
    (kısa metin kutuyu doldurur, uzun metin küçülür)."""
    x0, y0, x1, y1 = box
    s = smax
    while True:
        els = build(s)
        total = sum(g + e.height for e, g in els)
        if total <= y1 - y0 or s <= 0.5:
            break
        s -= 0.025
    if total > y1 - y0 + 0.5:
        raise ValueError(f'sığmadı: {total:.0f} > {y1 - y0}')
    return els, total


def stack(c, build, box, valign='center', smax=1.0):
    """Öğeleri kutuya dizer (dikeyde ortalı ya da üstten); son öğenin altını döndürür."""
    els, total = fit(build, box, smax)
    y = box[1] + ((box[3] - box[1] - total) / 2 if valign == 'center' else 0)
    d = ImageDraw.Draw(c, 'RGBA')
    for e, g in els:
        y += g
        e.render(c, d, box[0], box[2], y)
        y += e.height
    return y


# --- Zemin ve çerçeve ----------------------------------------------------------------------------
def carousel_backdrop(n):
    W, H = n * 1080, 1350
    glows = [(i * 1080 + 540, 620, 600, GLOW, 0.34) for i in range(n)]
    glows += [(i * 1080, 0, 540, SAND, 0.10) for i in range(n + 1)]
    stars = [(i * 1080, (300, 1110)[i % 2], (240, 290)[i % 2]) for i in range(n + 1)]
    return sa.Backdrop(W, H, glows, stars, ribbon=sa.wave(1196, 50, W / 1.6, 0.4))


def post_backdrop(ribbon=True):
    return sa.Backdrop(1080, 1350, [(540, 640, 600, GLOW, 0.36), (0, 0, 520, SAND, 0.10), (1080, 0, 520, SAND, 0.08)],
                       [(1080, 280, 230), (0, 1150, 260)], ribbon=sa.wave(1200, 46, 2100, 0.6) if ribbon else None)


def story_backdrop():
    return sa.Backdrop(1080, 1920, [(540, 1100, 640, GLOW, 0.38), (0, 0, 520, SAND, 0.10), (1080, 0, 520, SAND, 0.08)],
                       [(1080, 330, 250), (0, 1560, 300)], ribbon=sa.wave(1650, 64, 2200, 1.2))


def header(c, label, idx=None, n=None):
    d = ImageDraw.Draw(c, 'RGBA')
    t = sa.Txt(label, 26, 'tr', kind='SemiBold', color=GOLD, max_w=760, max_lines=1)
    t.draw(d, 90, sa.line_top(t, 90), 'start')
    if n:
        p = sa.Txt(f'{idx} / {n}', 26, 'tr', kind='Medium', color=CREAM, max_w=200, max_lines=1)
        p.draw(d, 990, sa.line_top(p, 90), 'end', alpha=210)


def footer(c, cy=1302):
    """Küçük marka satırı: logo + 'Vaktinde · Google Play'de ücretsiz'."""
    d = ImageDraw.Draw(c, 'RGBA')
    t = sa.Txt("Vaktinde · Google Play'de ücretsiz", 23, 'tr', kind='Medium', color=WHITE, max_w=900, max_lines=1)
    lg = 36
    x0 = 540 - (lg + 12 + t.width) / 2
    logo = mc.logo_img(lg)
    c.paste(logo, (round(S(x0)), round(S(cy - lg / 2))), logo)
    t.draw(d, x0 + lg + 12, sa.line_top(t, cy), 'start', alpha=225)


def swipe(c, cy=1080, cx=540):
    """'Kaydır' kapsülü ve ok (Poppins'te → yok)."""
    d = ImageDraw.Draw(c, 'RGBA')
    w = sa.chip(d, cx, cy, 'Kaydır      ', 'tr', 26, color=WHITE)
    ax = cx + w / 2 - 52
    lw = round(S(2.6))
    d.line([(S(ax), S(cy)), (S(ax + 26), S(cy))], fill=WHITE + (255,), width=lw)
    d.line([(S(ax + 16), S(cy - 10)), (S(ax + 27), S(cy)), (S(ax + 16), S(cy + 10))], fill=WHITE + (255,),
           width=lw, joint='curve')


def save(img, path, size):
    img = img.resize(size, Image.LANCZOS) if img.size != size else img
    img.convert('RGB').save(path, quality=93, subsampling=0, optimize=True)


def carousel(folder, label, slides):
    """slides: draw(tuval) listesi; zemin panorama (kenarlardan akar), üstte etiket ve sayfa."""
    n = len(slides)
    bd = carousel_backdrop(n)
    for i, draw in enumerate(slides):
        c = bd.render(i * 1080, 0, 1080, 1350)
        draw(c)
        header(c, label, i + 1, n)
        save(c, os.path.join(folder, f'{i + 1}.jpg'), POST)


def rise(c, shots, name, w, top, cx=540, shade=0.6):
    """Alttan taşan telefon (tuval kırpar)."""
    shots.phone(name, w).place(c, S(cx), S(top), shade)


def two_phones(c, shots, back, front, top):
    shots.phone(back, 500).place(c, S(330), S(top))
    shots.phone(front, 540).place(c, S(712), S(top + 70), shade=0.7)


def story_canvas():
    return story_backdrop().render(0, 0, *STORY)


def pill(c, cy=1490):
    sa.brand_pill(c, 540, cy, PILL)


# --- Kalıcı bildirim kartı ve vurgu ------------------------------------------------------------------
def persist_card(width, left):
    """Kalıcı bildirim (custom_notification.xml, açık tema): başlık satırı, konum · hicri, sıradaki
    vakit ve geri sayım, altında altı vakit (sıradaki kalın). width: SS pikseli."""
    k = width / 395  # px/dp
    W, H = round(width), round(122 * k)
    img = Image.new('RGB', (W, H), (250, 252, 251))
    d = ImageDraw.Draw(img, 'RGBA')
    d.rounded_rectangle((0, 0, W - 1, H - 1), radius=26 * k, outline=(214, 226, 223, 255), width=max(1, round(k)))
    dark, grey = (28, 30, 30, 255), (90, 98, 97, 255)

    def f(weight, sp):
        return sa.font('Roboto' + weight, sp * k / SS)

    logo = mc.logo_img(9 * k / SS * 2)
    img.paste(logo, (round(18 * k), round(13 * k)), logo)
    d.text((46 * k, 26 * k), 'Vaktinde', font=f('Regular', 12.5), fill=grey, anchor='ls')
    ax = W - 26 * k
    d.line([(ax - 5 * k, 19 * k), (ax, 24 * k), (ax + 5 * k, 19 * k)], fill=grey, width=round(1.8 * k))
    x0, x1, y1 = 18 * k, W - 18 * k, 58 * k
    h, rem = divmod(max(0, left), 3600)
    cnt = f'{h}:{rem // 60:02d}:{rem % 60:02d}' if h else f'{rem // 60:02d}:{rem % 60:02d}'
    fc, fn, fl = f('Bold', 15), f('Bold', 13), f('Regular', 12)
    name = L[CARD_TIMES[CARD_NEXT][0]]
    d.text((x1, y1), cnt, font=fc, fill=dark, anchor='rs')
    right = fc.getlength(cnt) + 4 * k + fn.getlength(name)
    d.text((x1 - fc.getlength(cnt) - 4 * k, y1), name, font=fn, fill=dark, anchor='rs')
    place, avail = CARD_PLACE, x1 - x0 - right - 8 * k
    while fl.getlength(place) > avail and len(place) > 2:
        place = place[:-2].rstrip() + '…'
    d.text((x0, y1), place, font=fl, fill=grey, anchor='ls')
    colw = (x1 - x0) / 6
    for i, (key, tm) in enumerate(CARD_TIMES):
        cx, nxt = x0 + colw * (i + 0.5), i == CARD_NEXT
        w8 = 'Bold' if nxt else 'Regular'
        d.text((cx, 84 * k), L[key], font=f(w8, 12), fill=dark if nxt else grey, anchor='ms')
        d.text((cx, 103 * k), tm, font=f(w8, 13), fill=dark, anchor='ms')
    img.putalpha(sa.rrect_mask(W, H, 26 * k))
    return img


def hi_overlay(ph, box, shot_w=1233):
    """Telefon görüntüsü boyutunda (SS) katman: ekran karartılır, kutu açık kalır, altın çerçeve."""
    sx, sy, sw, _ = ph.screen_box
    f = sw / shot_w
    x0, y0, x1, y1 = sx + box[0] * f, sy + box[1] * f, sx + box[2] * f, sy + box[3] * f
    dim = Image.new('L', ph.img.size, 0)
    dim.paste(ph.screen_mask.point(lambda v: v * 125 // 255), (sx, sy))
    hole = Image.new('L', ph.img.size, 0)
    ImageDraw.Draw(hole).rounded_rectangle((x0, y0, x1, y1), radius=S(16), fill=255)
    lay = Image.new('RGBA', ph.img.size, (0, 14, 12, 0))
    lay.putalpha(ImageChops.subtract(dim, hole))
    ImageDraw.Draw(lay).rounded_rectangle((x0 - S(4), y0 - S(4), x1 + S(4), y1 + S(4)), radius=S(19),
                                          outline=GOLD + (255,), width=round(S(4.5)))
    return lay


# --- 1) Kıssa karuselleri ------------------------------------------------------------------------
def kissa(folder, shots, sid, phone_shot):
    st = STORIES[sid]
    title, ar, sub = st['title']['tr'], st['title']['ar'], st['subtitle']['tr']
    paras = st['text']['tr'].split('\n\n')
    lesson, source = st['lesson']['tr'], st['source']['tr']
    label = f"Kıssalar · {st['category']}"
    box, w = (110, 150, 970, 1110), 860

    def cover(c, story=False):
        b = (110, 330, 970, 1300) if story else (110, 170, 970, 990)
        stack(c, lambda s: [(Chip(st['category'], 28 * s), 0), (T(title, 100 * s, w, 'Bold', lines=2), 44 * s),
                            (Ar(ar, 60 * s, w, GOLD), 22 * s), (Orn(), 36 * s),
                            (T(sub, 44 * s, w, 'Medium', CREAM, lines=3), 36 * s)], b, smax=1.5 if story else 1.15)

    def para(text):
        return lambda c: (stack(c, lambda s: [
            (T(title, 34 * s, w, 'SemiBold', GOLD, align='start', lines=1), 0),
            (T(text, 44 * s, w, 'Regular', WHITE, 1.5, 'start'), 34 * s)], box, smax=1.25), footer(c))

    def lesson_slide(c):
        stack(c, lambda s: [(T('Kıssadan hisse', 66 * s, w, 'Bold', lines=1), 0), (Orn(), 30 * s),
                            (T(lesson, 48 * s, w, 'Medium', CREAM, 1.42), 36 * s),
                            (T('Kaynak', 26 * s, w, 'SemiBold', GOLD, lines=1), 90 * s),
                            (T(source, 30 * s, w, 'Regular', CREAM, 1.42), 12 * s)], box, smax=1.2)
        footer(c)

    def cta(c):
        y = stack(c, lambda s: [(T(f"{len(STORIES)} kıssanın tamamı|Vaktinde'de", 64 * s, w, 'Bold', lines=2), 0),
                                (T('Peygamberler, Peygamberimizin hayatı, sahabe ve İslam âlimleri',
                                   32 * s, w, 'Regular', CREAM, 1.36), 22 * s)], (110, 150, 970, 420), 'top')
        pill(c, y + 70)
        rise(c, shots, phone_shot, 560, y + 170)

    carousel(folder, label, [lambda c: (cover(c), swipe(c), footer(c))] + [para(p) for p in paras] +
             [lesson_slide, cta])
    c = story_canvas()
    cover(c, story=True)
    d = ImageDraw.Draw(c, 'RGBA')
    T('Kıssanın devamı gönderide', 32, 900, 'Medium', CREAM, lines=1).render(c, d, 90, 990, 1380)
    pill(c)
    save(c, os.path.join(folder, 'hikaye.jpg'), STORY)


# --- 2) Dua kartları ---------------------------------------------------------------------------------
def dua_card(folder, shots, did):
    du = DUAS[did]
    note = (du.get('note') or {}).get('tr')
    src = du['source']['tr'] if isinstance(du['source'], dict) else du['source']

    def build(w, big):
        def b(s):
            k = s * (1.12 if big else 1.0)
            items = [(Chip('Kaydet, lazım olur', 26 * k, WHITE), 0),
                     (T(du['title']['tr'], 66 * k, w, 'Bold', lines=2), 30 * k),
                     (Ar(du['arabic'], 54 * k, w), 34 * k), (Orn(), 30 * k),
                     (T('Okunuşu', 24 * k, w, 'SemiBold', GOLD, lines=1), 30 * k),
                     (T(du['translit']['tr'], 33 * k, w, 'Medium', CREAM, 1.42), 10 * k),
                     (T('Anlamı', 24 * k, w, 'SemiBold', GOLD, lines=1), 30 * k),
                     (T(du['meaning']['tr'], 35 * k, w, 'Regular', WHITE, 1.42), 10 * k),
                     (T(f'Kaynak: {src}', 25 * k, w, 'SemiBold', GOLD, 1.3), 30 * k)]
            if note:
                items.append((T(note, 25 * k, w, 'Regular', CREAM, 1.36), 12 * k))
            return items
        return b

    c = post_backdrop(ribbon=False).render(0, 0, *POST)
    stack(c, build(900, False), (90, 60, 990, 1245), smax=1.2)
    footer(c)
    save(c, os.path.join(folder, 'gonderi.jpg'), POST)
    c = story_canvas()
    stack(c, build(860, True), (110, 280, 970, 1400), smax=1.3)
    pill(c)
    save(c, os.path.join(folder, 'hikaye.jpg'), STORY)


# --- 3) Abdest karuseli --------------------------------------------------------------------------
def abdest(folder, shots):
    farz, alinis, bozan = GUIDE['wudu']
    assert farz['title']['tr'].startswith('Abdestin farz') and bozan['title']['tr'].startswith('Abdesti bozan')
    steps = [it['text']['tr'] for it in alinis['items']]
    bes = GUIDE['dhikr']['besmele']
    dua = DUAS['abdest_sonrasi']
    note = GUIDE['note']['tr']
    w, box = 860, (110, 150, 970, 1110)

    def cover(c, story=False):
        b = (110, 330, 970, 1340) if story else (110, 170, 970, 1000)
        stack(c, lambda s: [(Chip('Namaz Hocası', 28 * s), 0), (T('Abdest|nasıl alınır?', 100 * s, 860, 'Bold', lines=2), 44 * s),
                            (Orn(), 36 * s), (T('Adım adım, sünnete uygun sıra', 42 * s, 860, 'Medium', CREAM, lines=2), 34 * s),
                            (T(note, 27 * s, 820, 'Regular', CREAM, 1.4), 60 * s)], b, smax=1.5 if story else 1.15)

    def step_slide(a, b_):
        def draw(c):
            def build(s):
                items = []
                for i in range(a, b_):
                    extra = None
                    if i == 0:  # niyet ve Besmele
                        extra = Col([(Ar(bes['arabic'], 44 * s, w - 120), 0),
                                     (T(bes['translit']['tr'], 28 * s, w - 120, 'Regular', CREAM, lines=1), 6 * s)])
                    items.append((steps[i], extra))
                return [(T(alinis['title']['tr'], 34 * s, w, 'SemiBold', GOLD, align='start', lines=2), 0),
                        (Steps(items, w, 42 * s, start=a + 1), 44 * s)]
            stack(c, build, box, smax=1.3)
            footer(c)
        return draw

    def list_slide(sec, numbered):
        def draw(c):
            stack(c, lambda s: [(T(sec['title']['tr'], 62 * s, w, 'Bold', lines=2), 0), (Orn(), 30 * s),
                                (Steps([it['text']['tr'] for it in sec['items']], w, 40 * s, numbered=numbered),
                                 44 * s)], box, smax=1.25)
            footer(c)
        return draw

    def dua_slide(c):
        stack(c, lambda s: [(T(dua['title']['tr'], 62 * s, w, 'Bold', lines=1), 0),
                            (Ar(dua['arabic'], 48 * s, w), 34 * s), (Orn(), 28 * s),
                            (T(dua['translit']['tr'], 30 * s, w, 'Medium', CREAM, 1.42), 28 * s),
                            (T(dua['meaning']['tr'], 33 * s, w, 'Regular', WHITE, 1.42), 26 * s),
                            (T(f"Kaynak: {dua['source']['tr']}", 25 * s, w, 'SemiBold', GOLD, lines=1), 26 * s)], box,
              smax=1.15)
        footer(c)

    def cta(c):
        y = stack(c, lambda s: [(T('Namazın kılınışı da|adım adım', 64 * s, w, 'Bold', lines=2), 0),
                                (T('Namaz Hocası: abdest, farzlar, rekâtlar ve kılınış', 32 * s, w, 'Regular', CREAM,
                                   1.36), 22 * s)], (110, 150, 970, 420), 'top')
        pill(c, y + 70)
        rise(c, shots, '11_prayer_guide', 560, y + 170)

    n = len(steps)
    thirds = [(0, math.ceil(n / 3)), (math.ceil(n / 3), math.ceil(2 * n / 3)), (math.ceil(2 * n / 3), n)]
    carousel(folder, 'Namaz Hocası · Abdest',
             [lambda c: (cover(c), swipe(c, 1110), footer(c))] + [step_slide(a, b) for a, b in thirds] +
             [list_slide(farz, True), list_slide(bozan, False), dua_slide, cta])
    c = story_canvas()
    cover(c, story=True)
    pill(c)
    save(c, os.path.join(folder, 'hikaye.jpg'), STORY)


# --- 4) Esmaül Hüsna karuseli ------------------------------------------------------------------------
def esma(folder, shots, start=1, count=5):
    items = ESMA[start - 1:start - 1 + count]
    end = start + len(items) - 1
    title = L['esmaulHusnaTitle']
    w, box = 860, (110, 150, 970, 1110)

    def cover(c, story=False):
        b = (110, 330, 970, 1340) if story else (110, 170, 970, 1000)
        stack(c, lambda s: [(Chip(f'{start}–{end}', 28 * s), 0), (T(title, 104 * s, w, 'Bold', lines=2), 40 * s),
                            (Ar('الأسماء الحسنى', 70 * s, w, GOLD), 18 * s), (Orn(), 34 * s),
                            (T("Allah'ın güzel isimleri ve anlamları", 42 * s, w, 'Medium', CREAM, lines=2), 34 * s)], b,
              smax=1.5 if story else 1.15)

    def name_slide(i, it):
        def draw(c):
            stack(c, lambda s: [(Chip(str(start + i), 26 * s), 0), (Ar(it['arabic'], 190 * s, w, GOLD, lh=1.3), 30 * s),
                                (T(it['name'], 78 * s, w, 'Bold', lines=1), 64 * s), (Orn(), 34 * s),
                                (T(it['meaning'], 44 * s, w, 'Regular', CREAM, 1.42), 34 * s)], box, smax=1.15)
            footer(c)
        return draw

    def cta(c):
        brand = dict(logo=220, name=116, tag="99 ismin tamamı ve\nanlamları Vaktinde'de", tag_size=46)
        hgt = sa.brand_block(Image.new('RGB', (8, 8)), 540, 0, **brand)
        y0 = (1350 - hgt - 170) / 2
        sa.brand_block(c, 540, y0, **brand)
        pill(c, y0 + hgt + 100)

    carousel(folder, title, [lambda c: (cover(c), swipe(c), footer(c))] +
             [name_slide(i, it) for i, it in enumerate(items)] + [cta])
    c = story_canvas()
    cover(c, story=True)
    pill(c)
    save(c, os.path.join(folder, 'hikaye.jpg'), STORY)


# --- 5) Etkileşim hikâyeleri --------------------------------------------------------------------------
def story_bes_vakit(folder, shots):
    c = story_canvas()
    y = stack(c, lambda s: [(Chip('Bugün', 30 * s, WHITE), 0), (T('5 vakti|kıldın mı?', 104 * s, 900, 'Bold', lines=2), 40 * s),
                            (T('Cevabını aşağıdan işaretle', 40 * s, 900, 'Medium', CREAM, lines=1), 30 * s)],
              (90, 300, 990, 760), 'top')
    d = ImageDraw.Draw(c, 'RGBA')
    names = ['Sabah', L['ogle'], L['ikindi'], L['aksam'], L['yatsi']]
    r, cy = 62, y + 120
    for i, nm in enumerate(names):
        cx = 540 + (i - 2) * 182
        d.ellipse((S(cx - r), S(cy - r), S(cx + r), S(cy + r)), fill=(255, 255, 255, 22), outline=GOLD + (230,),
                  width=round(S(3.4)))
        t = sa.Txt(nm, 30, 'tr', kind='Medium', color=WHITE, max_w=180, max_lines=1)
        t.draw(d, cx, cy + r + 30)
    T("Kıldığın vakitleri Vaktinde'de tek dokunuşla işaretle", 32, 860, 'Medium', CREAM, 1.36).render(c, d, 110, 970, 1335)
    pill(c)
    save(c, os.path.join(folder, 'hikaye.jpg'), STORY)


def story_dua_sorusu(folder, shots):
    c = story_canvas()
    stack(c, lambda s: [(Chip('Soru', 30 * s, WHITE), 0), (T('En sevdiğin dua|hangisi?', 100 * s, 900, 'Bold', lines=2), 40 * s),
                        (Orn(), 34 * s), (T('Yanıtla, birbirimizden öğrenelim', 40 * s, 900, 'Medium', CREAM, lines=2), 34 * s)],
          (90, 300, 990, 800), 'top')
    d = ImageDraw.Draw(c, 'RGBA')
    T(f"{len(DUAS)} dua; Arapçası, okunuşu ve anlamıyla Vaktinde'de", 32, 860, 'Medium', CREAM, 1.36).render(
        c, d, 110, 970, 1335)
    pill(c)
    save(c, os.path.join(folder, 'hikaye.jpg'), STORY)


def story_hatim_ortagi(folder, shots):
    c = story_canvas()
    y = stack(c, lambda s: [(Chip(L['hatimGroup'], 30 * s, WHITE), 0),
                            (T('Hatim ortağını|etiketle', 96 * s, 900, 'Bold', lines=2), 40 * s),
                            (T(L['hatimGroupDesc'], 38 * s, 900, 'Medium', CREAM, 1.36), 30 * s)],
              (90, 280, 990, 760), 'top')
    d = ImageDraw.Draw(c, 'RGBA')
    cols, cw, ch, gap = 6, 118, 72, 12
    x0 = 540 - (cols * cw + (cols - 1) * gap) / 2
    top = y + 50
    fills = [(GOLD, DEEP), ((178, 223, 219), DEEP), ((255, 255, 255), DEEP)]
    for j in range(30):
        r, col = divmod(j, cols)
        fill, ink = fills[j // 10]
        bx, by = x0 + col * (cw + gap), top + r * (ch + gap)
        d.rounded_rectangle((S(bx), S(by), S(bx + cw), S(by + ch)), radius=S(16), fill=fill + (235,))
        t = sa.Txt(str(j + 1), 34, 'tr', kind='SemiBold', color=ink, max_w=cw, max_lines=1)
        t.draw(d, bx + cw / 2, sa.line_top(t, by + ch / 2))
    ly = top + 5 * (ch + gap) + 44
    lines = [sa.Txt(L['hatimGroupLine'].replace('{person}', str(p + 1)).replace(
        '{juz}', L['hatimGroupRange'].replace('{from}', str(p * 10 + 1)).replace('{to}', str(p * 10 + 10))),
        32, 'tr', kind='Medium', color=WHITE, max_w=600, max_lines=1) for p in range(3)]
    lx = 540 - (46 + max(t.width for t in lines)) / 2
    for p, ((fill, _), t) in enumerate(zip(fills, lines)):
        cy = ly + p * 48
        d.rounded_rectangle((S(lx), S(cy - 13), S(lx + 26), S(cy + 13)), radius=S(7), fill=fill + (235,))
        t.draw(d, lx + 46, sa.line_top(t, cy), 'start')
    pill(c)
    save(c, os.path.join(folder, 'hikaye.jpg'), STORY)


# --- 6) Videolar ve 1.4.0 duyurusu ------------------------------------------------------------------
BM = {  # "Biliyor muydun?": kanca, sahne (başlık, alt yazı, ekran, vurgu / kart)
    '02_bm_sessiz': dict(
        hook='Telefon sessizdeyken|ezan duyulur mu?',
        scenes=[dict(title='“' + L['ezanAlarmStreamTitle'] + '”',
                     sub='Alarmlar sekmesinde açın. ' + L['ezanAlarmStreamSub'],
                     shot='02_alarms', hi=HI_SILENT)]),
    '05_bm_hatim': dict(
        hook='Hatmi yarım|kalanlar için',
        scenes=[dict(title='Günlük hedefle hatim',
                     sub='Planını seç (günde 20, 10 ya da 5 sayfa). Okudukça sayfalar sayılır, “Okudum” ile işaretle.',
                     shot='06_hatim', hi=HI_HATIM)]),
    '11_bm_bildirim': dict(
        hook='Uygulamayı açmadan|vakitleri görün',
        scenes=[dict(title=L['persistentNotifTitle'],
                     sub='Sıradaki vakte geri sayım ve günün altı vakti. Ayarlar › Bildirim Ayarları’ndan açın.',
                     shot='01_home', card=True)]),
}
NEWS = [  # 1.4.0: (başlık, alt yazı, ekran(lar)); başlık ve metinler uygulamanın Yenilikler'inden
    (L['hatimTitle'], L['whatsNewHatimDesc'], ('06_hatim',)),
    (L['duasTitle'], L['whatsNewDuasDesc'], ('12_duas', '13_dua_travel')),
    (L['storiesTitle'], L['whatsNewStoriesDesc'], ('17_stories', '18_story_bilal')),
    ('Bildirimde tüm vakitler', 'Kalıcı bildirimde sıradaki vakte geri sayım ve günün altı vakti', ('01_home',)),
]


def news_scenes(t0=2.1, dur=2.7):
    out = []
    for i, (title, sub, shots_) in enumerate(NEWS):
        a = t0 + i * dur
        out.append(dict(t0=a, t1=a + dur, title=title, sub=sub, shot=shots_[-1], card=shots_[-1] == '01_home'))
    return out


class Movie:
    """Sessiz dikey video: kanca → telefonlu sahneler (vurgu / bildirim kartı) → kapanış."""

    def __init__(self, shots, chip, hook, scenes, total):
        W, H = STORY
        self.total, self.scenes = total, scenes
        bd = story_backdrop()
        self.bg = sa.to1x(bd.render(0, 0, W, H))
        hook_img = bd.render(0, 0, W, H)
        stack(hook_img, lambda s: [(Chip(chip, 32 * s, WHITE), 0),
                                   (T(hook, 96 * s, 900, 'Bold', WHITE, 1.14, lines=3), 46 * s)], (90, 560, 990, 1200))
        self.hook = sa.to1x(hook_img)
        end = bd.render(0, 0, W, H)
        hgt = sa.brand_block(Image.new('RGB', (8, 8)), 540, 0, logo=220, name=110)
        sa.brand_block(end, 540, 520, logo=220, name=110)
        sa.brand_pill(end, 540, 520 + hgt + 110, PILL, size=34)
        T("Play Store'da “Vaktinde” arayın", 32, 900, 'Medium', CREAM, lines=1).render(
            end, ImageDraw.Draw(end, 'RGBA'), 90, 990, 520 + hgt + 190)
        self.end = sa.to1x(end)
        self.hook_end = scenes[0]['t0'] + 0.2
        self.end_t = scenes[-1]['t1'] - 0.1
        self.pw, self.ptop = 600, 650
        self.phones, self.overlays = {}, {}
        for i, sc in enumerate(scenes):
            ph = shots.phone(sc['shot'], self.pw)
            self.phones.setdefault(sc['shot'], sa.to1x(ph.img))
            if sc.get('hi'):
                self.overlays[i] = sa.to1x(hi_overlay(ph, sc['hi']))
        self.ph_pad = round(ph.pad / SS)
        self.sh, self.sh_pad = sa.shadow_layer(sa.to1x(ph.mask), self.pw * 0.045, 0.55)
        self.caps = []
        for sc in scenes:
            hd = sa.Heading('tr', sc['title'], sc['sub'], max_w=920, size=62, sub_size=34)
            self.caps.append((sa.layer(1080, hd.height + 40, lambda im, d, hd=hd: hd.draw(d, 540, 10)), hd.height))
        self.cards = {}
        self.card_sh = None

    def card(self, left):
        if left not in self.cards:
            self.cards[left] = sa.to1x(persist_card(S(980), left))
            if self.card_sh is None:
                self.card_sh = sa.shadow_layer(self.cards[left].getchannel('A'), 20, 0.55)
        return self.cards[left]

    def frame(self, t):
        ramp = sa.ramp
        if t < self.hook_end:
            f = Image.blend(self.bg, self.hook, ramp(t, 0.0, 0.6) * (1 - ramp(t, self.hook_end - 0.45, self.hook_end)))
        else:
            f = self.bg.copy()

        def put(img, x, y, a, mask=None):
            if a > 0.004:
                f.paste(img, (round(x), round(y)), sa.faded(img, a) if mask is None else mask)

        s0, s1 = self.scenes[0]['t0'], self.scenes[-1]['t1']
        if s0 <= t < s1:
            H = STORY[1]
            enter, leave = ramp(t, s0, s0 + 0.8), ramp(t, s1 - 0.6, s1)
            y = self.ptop + (H + 60 - self.ptop) * (1 - enter) + (H + 60 - self.ptop) * leave * leave
            y += 6 * math.sin(2 * math.pi * (t - s0) / 5.0)
            i = max(j for j, sc in enumerate(self.scenes) if sc['t0'] <= t)
            sc = self.scenes[i]
            img = self.phones[sc['shot']]
            if i and t < sc['t0'] + 0.3 and self.scenes[i - 1]['shot'] != sc['shot']:
                img = Image.blend(self.phones[self.scenes[i - 1]['shot']], img, ramp(t, sc['t0'] - 0.05, sc['t0'] + 0.3))
            x = 540 - self.pw / 2 - self.ph_pad
            f.paste(self.sh, (round(540 - self.pw / 2 - self.sh_pad), round(y - self.sh_pad + self.pw * 0.04)), self.sh)
            f.paste(img, (round(x), round(y)), img)
            if i in self.overlays:
                a = ramp(t, sc['t0'] + 0.9, sc['t0'] + 1.4) * (1 - ramp(t, sc['t1'] - 0.4, sc['t1'] - 0.1))
                a *= 0.86 + 0.14 * math.sin(2 * math.pi * (t - sc['t0']) / 1.3)
                put(self.overlays[i], x, y, a)
            if sc.get('card'):
                a0 = sc['t0'] + 0.5
                a = ramp(t, a0, a0 + 0.5) * (1 - ramp(t, sc['t1'] - 0.35, sc['t1'] - 0.05))
                if a > 0:
                    card = self.card(CARD_LEFT - int(max(0.0, t - a0)))
                    cy = y + CARD_DY + 40 * (1 - ramp(t, a0, a0 + 0.55))
                    sh, pad = self.card_sh
                    put(sh, 50 - pad, cy - pad + 14, a)
                    put(card, 50, cy, a)
            for j, (lay, hh) in enumerate(self.caps):
                c = self.scenes[j]
                if c['t0'] <= t < c['t1']:
                    a = ramp(t, c['t0'] + 0.1, c['t0'] + 0.5) * (1 - ramp(t, c['t1'] - 0.35, c['t1'] - 0.05))
                    put(lay, 0, 455 - hh / 2 - 10 + 20 * (1 - ramp(t, c['t0'] + 0.1, c['t0'] + 0.55)), a)
        if t >= self.end_t:
            f = Image.blend(f, self.end, ramp(t, self.end_t, self.end_t + 0.6))
        return f

    def write(self, path):
        W, H = STORY
        cmd = [mc.FFMPEG, '-y', '-loglevel', 'error', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}',
               '-r', str(FPS), '-i', '-', '-an', '-vf', 'scale=out_color_matrix=bt709:out_range=tv,format=yuv420p',
               '-c:v', 'libx264', '-preset', 'slow', '-crf', '19', '-profile:v', 'high', '-level', '4.2',
               '-pix_fmt', 'yuv420p', '-r', str(FPS), '-color_primaries', 'bt709', '-color_trc', 'bt709',
               '-colorspace', 'bt709', '-movflags', '+faststart', path]
        proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)
        for i in range(round(self.total * FPS)):
            proc.stdin.write(self.frame(i / FPS).tobytes())
        proc.stdin.close()
        if proc.wait() != 0:
            raise RuntimeError('ffmpeg hata verdi: ' + path)


def bm_cover(shots, spec):
    """Video kapağı (1080×1350): kanca üstte, telefon alttan taşar (vurgu / kart ile)."""
    c = post_backdrop().render(0, 0, *POST)
    y = stack(c, lambda s: [(Chip('Biliyor muydun?', 28 * s, WHITE), 0),
                            (T(spec['hook'], 84 * s, 900, 'Bold', WHITE, 1.14, lines=3), 34 * s)], (90, 90, 990, 560), 'top')
    sc = spec['scenes'][0]
    ph = shots.phone(sc['shot'], 600)
    top = y + 70
    ph.place(c, S(540), S(top))
    if sc.get('hi'):
        lay = hi_overlay(ph, sc['hi'])
        c.paste(lay, (round(S(540) - ph.w / 2 - ph.pad), round(S(top))), lay)
    if sc.get('card'):
        card = persist_card(S(980), CARD_LEFT)
        sa.shadow(c, card.getchannel('A'), S(50), S(top + CARD_DY), S(20), S(14), 0.55)
        c.paste(card, (round(S(50)), round(S(top + CARD_DY))), card)
    return c


def bm_video(folder, shots, pid, video):
    spec = BM[pid]
    sc = dict(spec['scenes'][0], t0=2.6, t1=9.6)
    mv = Movie(shots, 'Biliyor muydun?', spec['hook'], [sc], 12.0)
    save(bm_cover(shots, spec), os.path.join(folder, 'kapak.jpg'), POST)
    save(mv.frame(6.4), os.path.join(folder, 'hikaye.jpg'), STORY)
    if video:
        mv.write(os.path.join(folder, 'video.mp4'))


def yeni_surum(folder, shots, video):
    w = 860
    bullets = ['Hatim ekranı', f'{len(DUAS)} dua', L['storiesTitle'], f'{DHIKR_COUNT} hazır zikir', 'Bildirimde tüm vakitler']

    def cover(c, story=False):
        b = (110, 330, 970, 1380) if story else (110, 160, 970, 1010)
        stack(c, lambda s: [(Chip('Güncelleme', 28 * s, WHITE), 0), (T("Vaktinde'de|yeni", 104 * s, w, 'Bold', lines=2), 40 * s),
                            (Orn(), 34 * s), (Steps(bullets, 620, 40 * s, numbered=False), 44 * s)],
              (b[0] + 120, b[1], b[2] - 120, b[3]), smax=1.5 if story else 1.1)

    def feature(i):
        title, sub, shots_ = NEWS[i]

        def draw(c):
            hd = sa.Heading('tr', title, sub, max_w=900, size=62, sub_size=32)
            hd.draw(ImageDraw.Draw(c, 'RGBA'), 540, 150)
            top = 150 + hd.height + 70
            if len(shots_) == 2:
                two_phones(c, shots, shots_[0], shots_[1], top)
            else:
                rise(c, shots, shots_[0], 560, top)
            if shots_[0] == '01_home':
                card = persist_card(S(980), CARD_LEFT)
                sa.shadow(c, card.getchannel('A'), S(50), S(top + CARD_DY), S(20), S(14), 0.55)
                c.paste(card, (round(S(50)), round(S(top + CARD_DY))), card)
        return draw

    def cta(c):
        hgt = sa.brand_block(Image.new('RGB', (8, 8)), 540, 0, logo=170, name=96)
        y0 = (1350 - hgt - 230) / 2
        sa.brand_block(c, 540, y0, logo=170, name=96)
        pill(c, y0 + hgt + 100)
        T('Güncellemek için Google Play’i açın', 30, 900, 'Medium', CREAM, lines=1).render(
            c, ImageDraw.Draw(c, 'RGBA'), 90, 990, y0 + hgt + 180)

    carousel(folder, 'Vaktinde 1.4.0', [lambda c: (cover(c), swipe(c), footer(c))] +
             [feature(i) for i in range(len(NEWS))] + [cta])
    c = story_canvas()
    cover(c, story=True)
    pill(c)
    save(c, os.path.join(folder, 'hikaye.jpg'), STORY)
    if video:
        scenes = news_scenes()
        Movie(shots, 'Güncelleme', "Vaktinde'de|yeni", scenes, scenes[-1]['t1'] + 2.6).write(
            os.path.join(folder, 'video.mp4'))


# --- Parçalar (takvim sırası) ------------------------------------------------------------------------
PIECES = [
    ('01_yeni_surum', lambda f, sh, v: yeni_surum(f, sh, v)),
    ('02_bm_sessiz', lambda f, sh, v: bm_video(f, sh, '02_bm_sessiz', v)),
    ('03_kissa_yunus', lambda f, sh, v: kissa(f, sh, 'yunus', '17_stories')),
    ('04_dua_sabah', lambda f, sh, v: dua_card(f, sh, 'bike_asbahna')),
    ('05_bm_hatim', lambda f, sh, v: bm_video(f, sh, '05_bm_hatim', v)),
    ('06_hikaye_bes_vakit', lambda f, sh, v: story_bes_vakit(f, sh)),
    ('07_abdest', lambda f, sh, v: abdest(f, sh)),
    ('08_dua_sinav', lambda f, sh, v: dua_card(f, sh, 'rabbisrah')),
    ('09_kissa_yusuf', lambda f, sh, v: kissa(f, sh, 'yusuf', '17_stories')),
    ('10_hikaye_dua_sorusu', lambda f, sh, v: story_dua_sorusu(f, sh)),
    ('11_bm_bildirim', lambda f, sh, v: bm_video(f, sh, '11_bm_bildirim', v)),
    ('12_dua_yolculuk', lambda f, sh, v: dua_card(f, sh, 'travel')),
    ('13_esma_1_5', lambda f, sh, v: esma(f, sh, 1, 5)),
    ('14_hikaye_hatim_ortagi', lambda f, sh, v: story_hatim_ortagi(f, sh)),
    ('15_kissa_bilal', lambda f, sh, v: kissa(f, sh, 'bilal', '18_story_bilal')),
    ('16_dua_sikinti', lambda f, sh, v: dua_card(f, sh, 'kerb')),
]


def build(args):
    pid, shot_dir, out, video = args
    folder = os.path.join(out, pid)
    os.makedirs(folder, exist_ok=True)
    dict(PIECES)[pid](folder, sa.Shots(shot_dir, 'tr'), video)
    return pid, sorted(os.listdir(folder))


def preview(out, ids):
    """Her parçanın ilk görseli yan yana (_onizleme.jpg)."""
    tw, gap, label = 270, 18, 30
    thumbs = []
    for pid in ids:
        files = sorted(os.listdir(os.path.join(out, pid)))
        first = next(n for n in ('1.jpg', 'gonderi.jpg', 'kapak.jpg', 'hikaye.jpg') if n in files)
        im = Image.open(os.path.join(out, pid, first)).convert('RGB')
        thumbs.append((pid, im.resize((tw, round(im.height * tw / im.width)), Image.LANCZOS)))
    cols = 4
    rows = math.ceil(len(thumbs) / cols)
    th = max(t.height for _, t in thumbs)
    sheet = Image.new('RGB', (cols * tw + (cols + 1) * gap, rows * (th + label + gap) + gap), (236, 241, 240))
    d = ImageDraw.Draw(sheet)
    f = sa.font('Medium', 17 / SS)
    for i, (pid, t) in enumerate(thumbs):
        r, c = divmod(i, cols)
        x, y = gap + c * (tw + gap), gap + r * (th + label + gap)
        sheet.paste(t, (x, y))
        d.text((x + tw / 2, y + th + 22), pid, font=f, anchor='ms', fill=(30, 40, 40))
    sheet.save(os.path.join(out, '_onizleme.jpg'), quality=88)


def make_zips(out, ids, limit=24 * 1024 * 1024):
    """kasim_1.zip, kasim_2.zip …: parça klasörleri sırayla, her zip ≤ limit; takvim ve önizleme ilkinde."""
    extras = [(os.path.join(HERE, 'kasim_takvimi.md'), 'kasim_takvimi.md'), (os.path.join(out, '_onizleme.jpg'), '_onizleme.jpg')]
    extras = [(p, a) for p, a in extras if os.path.exists(p)]
    groups, size = [[]], sum(os.path.getsize(p) for p, _ in extras)
    for pid in ids:
        fs = [os.path.join(out, pid, n) for n in sorted(os.listdir(os.path.join(out, pid)))]
        s_ = sum(os.path.getsize(p) for p in fs)
        if groups[-1] and size + s_ > limit:
            groups.append([])
            size = 0
        groups[-1].append((pid, fs))
        size += s_
    made = []
    for i, g in enumerate(groups):
        path = os.path.join(out, f'kasim_{i + 1}.zip')
        with zipfile.ZipFile(path, 'w', zipfile.ZIP_STORED) as z:
            for p, a in (extras if i == 0 else []):
                z.write(p, a)
            for pid, fs in g:
                for p in fs:
                    z.write(p, f'{pid}/{os.path.basename(p)}')
        assert os.path.getsize(path) <= 25 * 1024 * 1024, path
        made.append((os.path.basename(path), os.path.getsize(path)))
    return made


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('shots', help='pazarlama ekran görüntülerinin klasörü (m_tr_*.png)')
    ap.add_argument('out', help='çıkış klasörü')
    ap.add_argument('--sadece', help='virgülle ayrılmış parça adları')
    ap.add_argument('--videosuz', action='store_true', help='video üretme (hızlı deneme)')
    ap.add_argument('--zipsiz', action='store_true')
    ap.add_argument('--is', type=int, default=min(4, os.cpu_count() or 1), dest='jobs')
    args = ap.parse_args()
    if not features.check('raqm'):
        sys.exit('Pillow raqm desteği yok: Arapça metin doğru şekillenmez.')
    ids = [p for p, _ in PIECES]
    if args.sadece:
        want = set(args.sadece.split(','))
        unknown = want - set(ids)
        if unknown:
            sys.exit('bilinmeyen parça: ' + ', '.join(sorted(unknown)))
        ids = [p for p in ids if p in want]
    os.makedirs(args.out, exist_ok=True)
    with ProcessPoolExecutor(max_workers=args.jobs) as ex:
        for pid, files in ex.map(build, [(p, args.shots, args.out, not args.videosuz) for p in ids]):
            print(pid, ' '.join(files))
    done = [p for p, _ in PIECES if os.path.isdir(os.path.join(args.out, p))]
    preview(args.out, done)
    if not args.zipsiz:
        for name, size in make_zips(args.out, done):
            print(f'{name}: {size / 1e6:.1f} MB')


if __name__ == '__main__':
    main()
