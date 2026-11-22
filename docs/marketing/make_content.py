#!/usr/bin/env python3
"""Vaktinde sosyal medya içerik paketi (Aralık 2026 – Mart 2027).

Kullanım:
  python3 docs/marketing/make_content.py <çıkış_klasörü> [--sadece 01_regaib_uc_aylar,08_tanitim_ezan]
                                         [--videosuz] [--zip <paket.zip>]

Her içerik için <çıkış>/<ad>/ altında:
  post.png   1080×1350 (Instagram/Facebook gönderisi, TikTok fotoğraf gönderisi)
  story.png  1080×1920 (hikâye)
  video.mp4  1080×1920, 8 sn, 30 fps, H.264 yuv420p, +faststart, sessiz (Reels/TikTok/Shorts)
Ayrıca <çıkış>/_onizleme.jpg: tüm post.png'lerin kontak sayfası.

Dikey dosyalarda önemli metin/logo x 90–990, y 260–1450 içinde kalır (videonun son
karesindeki %5 yakınlaşma dahil). Ekran görüntüleri docs/marketing/ekran/ altında
(uygulamanın test/screenshots düzeneğinden, tr açık tema). Metinler ve takvim:
docs/marketing/icerik_takvimi.md. Dini metinler yalnızca buradaki listeden; ekleme yapılmaz.

Gerekenler: Python 3, Pillow (raqm ile; Arapça şekillendirme), numpy, ffmpeg (libx264).
"""
import argparse
import math
import os
import random
import shutil
import subprocess
import sys
import zipfile
from concurrent.futures import ProcessPoolExecutor

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, features

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
POPPINS = os.path.join(REPO, 'assets', 'google_fonts', 'Poppins-{}.ttf')
AMIRI = os.path.join(REPO, 'assets', 'fonts', 'amiri', 'Amiri-Regular.ttf')
LOGO = os.path.join(REPO, 'assets', 'icon', 'icon.png')
SHOTS = os.path.join(HERE, 'ekran')
FFMPEG = shutil.which('ffmpeg') or '/usr/bin/ffmpeg'

SS = 2  # süper örnekleme: her şey 2 kat çizilir, sonra küçültülür

TEAL_TOP = (0, 121, 107)
TEAL_BOTTOM = (0, 63, 56)
GLOW = (22, 150, 136)
WHITE = (255, 255, 255)
MINT = (224, 242, 241)
GOLD = (238, 211, 148)
TEAL_TEXT = (0, 105, 92)

TR = {'language': 'tr'}
AR = {'direction': 'rtl', 'language': 'ar'}

# Video: 8 sn × 30 fps, 0,6 sn yumuşak giriş, sonda %5 yakınlaşma
FPS = 30
FRAMES = 8 * FPS
FADE_FRAMES = round(0.6 * FPS)
ZOOM_END = 1.05
ZOOM_CENTER = (540, 860)  # güvenli alanın ortası (story koordinatı)

# --- Dini metinler (harfi harfine; ekleme yapma) -------------------------------
A_REGAIB = 'اللَّهُمَّ بَارِكْ لَنَا فِي رَجَبٍ وَشَعْبَانَ وَبَلِّغْنَا رَمَضَانَ'
A_KADIR = 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي'

SPECIALS = [
    dict(
        id='01_regaib_uc_aylar',
        icon='star',
        blocks=[
            ('kicker', '10 Aralık 2026 · Perşembe'),
            ('title', 'Üç Aylar ve\nRegaib Kandili'),
            ('divider',),
            ('arabic', A_REGAIB),
            ('quote', '“Allah’ım! Recep ve Şaban’ı bizim için mübarek kıl ve bizi Ramazan’a ulaştır.”'),
            ('divider',),
            ('greeting', 'Üç Aylarınız ve Regaib Kandiliniz mübarek olsun'),
        ],
    ),
    dict(
        id='02_mirac',
        icon='star',
        blocks=[
            ('kicker', '4 Ocak 2027 · Pazartesi'),
            ('title', 'Miraç Kandiliniz\nmübarek olsun'),
            ('divider',),
            ('quote', '“Kulunu bir gece Mescid-i\u00a0Haram’dan, çevresini bereketli kıldığımız '
                      'Mescid-i\u00a0Aksâ’ya götüren Allah, her türlü eksiklikten uzaktır.”'),
            ('source', 'İsrâ, 17/1'),
        ],
    ),
    dict(
        id='03_berat',
        icon='star',
        blocks=[
            ('kicker', '22 Ocak 2027 · Cuma'),
            ('title', 'Berat Kandiliniz\nmübarek olsun'),
            ('divider',),
            ('body', 'Rabbim bu gecenin hürmetine\ntövbelerimizi ve dualarımızı\nkabul eylesin.'),
        ],
    ),
    dict(
        id='04_ramazan',
        icon='crescent',
        blocks=[
            ('kicker', 'İlk oruç: 8 Şubat 2027 Pazartesi'),
            ('title', 'Hoş geldin\nYa Şehr-i Ramazan'),
            ('divider',),
            ('quote', '“Ey iman edenler! Oruç sizden öncekilere farz kılındığı gibi size de '
                      'farz kılındı. Umulur ki korunursunuz.”'),
            ('source', 'Bakara, 2/183'),
        ],
    ),
    dict(
        id='05_kadir',
        icon='crescent',
        blocks=[
            ('kicker', '5 Mart 2027 · Cuma'),
            ('title', 'Kadir Geceniz\nmübarek olsun'),
            ('divider',),
            ('quote', '“Kadir gecesi bin aydan daha hayırlıdır.”'),
            ('source', 'Kadr, 97/3'),
            ('divider',),
            ('arabic', A_KADIR),
            ('quote', '“Allah’ım! Sen affedicisin, affetmeyi seversin; beni affet.”'),
            ('source', 'Tirmizî'),
        ],
    ),
    dict(
        id='06_ramazan_bayrami',
        icon='crescent',
        blocks=[
            ('kicker', '9 Mart 2027 · Salı'),
            ('title', 'Ramazan\nBayramınız\nmübarek olsun'),
            ('divider',),
            ('body', 'Rabbim tuttuğumuz oruçları ve ibadetlerimizi kabul eylesin.'),
        ],
    ),
    dict(
        id='07_cuma',
        icon='star',
        title_size=104,
        blocks=[
            ('title', 'Hayırlı Cumalar'),
            ('divider',),
            ('body', 'Rabbim dualarımızı kabul eylesin.'),
        ],
    ),
]

PROMOS = [
    dict(id='08_tanitim_ezan', title='Ezan vakti,|saniyesi saniyesine',
         sub='İnternetsiz hesaplama · Ana ekran widget’ı', shots=['tr_10_home.png']),
    dict(id='09_tanitim_kible', title='Kıble pusulası cebinde',
         sub='Kıble açısı ve dönüş yönü tek ekranda', shots=['tr_20_qibla.png']),
    dict(id='10_tanitim_zikirmatik', title='Zikirmatik:\ntesbih her an yanında',
         sub='Hedef belirle, ekrana dokun ve say', shots=['tr_30_zikirmatik.png']),
    dict(id='11_tanitim_imsakiye', title='Ramazan 2027 imsakiyesi hazır',
         sub='Sahur ve iftar vakitleri, geri sayım', shots=['tr_41_imsakiye_ramazan.png']),
    dict(id='12_tanitim_takip_kaza', title='Namaz takibi ve kaza hesaplama',
         sub='Kıldığın vakitleri işaretle, kaza namazlarını hesapla',
         shots=['tr_47_prayer_tracker.png', 'tr_46_kaza_calc.png']),
    dict(id='13_tanitim_kuran', title='Kur’an-ı Kerim:\nkaldığın yerden devam',
         sub='Mushaf sayfası, meal ve yer imi', shots=['tr_70_quran_list.png']),
]

# Biçimler: tuval, içerik kutusu (x0, y0, x1, y1), marka satırı / kapsül merkezi
FORMATS = {
    'post': dict(size=(1080, 1350), box=(90, 70, 990, 1225), brand_y=1292,
                 stars=[(0.07, 0.09, 0.21), (0.95, 0.87, 0.25), (0.94, 0.08, 0.11),
                        (0.05, 0.92, 0.13)]),
    # Dikey: güvenli alan x 90–990, y 260–1450; %5 yakınlaşmaya pay bırakılır
    'story': dict(size=(1080, 1920), box=(120, 300, 960, 1318), brand_y=1388,
                  stars=[(0.08, 0.07, 0.24), (0.95, 0.93, 0.28), (0.93, 0.05, 0.12),
                         (0.05, 0.96, 0.15), (0.97, 0.44, 0.09), (0.03, 0.62, 0.08)]),
}


# --- Yardımcılar -------------------------------------------------------------------
_fonts = {}


def font(kind, size):
    key = (kind, round(size * SS))
    if key not in _fonts:
        path = AMIRI if kind == 'Amiri' else POPPINS.format(kind)
        _fonts[key] = ImageFont.truetype(path, key[1], layout_engine=ImageFont.Layout.RAQM)
    return _fonts[key]


def S(v):
    return v * SS


def star_points(cx, cy, r, inner=0.78):
    pts = []
    for k in range(16):
        a = math.pi / 8 * k - math.pi / 2
        rr = r if k % 2 == 0 else r * inner
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return pts


def background(fmt, glow_center, glow_radius, sparkle=False, keepout=()):
    """Koyu teal gradyan + hafif ışıma + silik sekiz köşeli yıldızlar (RGBA, SS boyutu)."""
    w, h = FORMATS[fmt]['size']
    t = np.linspace(0.0, 1.0, h, dtype=np.float32)[:, None, None]
    top = np.array(TEAL_TOP, np.float32)
    bottom = np.array(TEAL_BOTTOM, np.float32)
    arr = np.broadcast_to(top * (1 - t) + bottom * t, (h, w, 3)).copy()
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    gx, gy = glow_center
    d2 = ((xx - gx) ** 2 + (yy - gy) ** 2) / (glow_radius ** 2)
    g = (np.exp(-d2) * 0.42)[..., None]
    arr = arr * (1 - g) + np.array(GLOW, np.float32) * g
    rng = np.random.default_rng(7)
    arr += rng.uniform(-0.8, 0.8, arr.shape).astype(np.float32)  # bantlaşmaya karşı titreşim
    img = Image.fromarray(np.clip(arr + 0.5, 0, 255).astype(np.uint8), 'RGB')
    img = img.resize((w * SS, h * SS), Image.BICUBIC).convert('RGBA')

    deco = Image.new('RGBA', img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(deco)
    for fx, fy, fr in FORMATS[fmt]['stars']:
        cx, cy, r = S(fx * w), S(fy * h), S(fr * w)
        d.polygon(star_points(cx, cy, r), outline=(255, 255, 255, 36), width=round(S(5)))
        d.polygon(star_points(cx, cy, r * 0.62), outline=(255, 255, 255, 22), width=round(S(3.5)))
    if sparkle:  # kandil gecesi: küçük silik ışık noktaları
        rnd = random.Random(fmt)
        for _ in range(70 if fmt == 'story' else 50):
            x, y = rnd.uniform(0, w), rnd.uniform(0, h * 0.97)
            r = rnd.uniform(1.2, 3.0)
            a = rnd.randint(40, 120)
            # Yazının yakınına nokta düşmesin (Arapça harekeyle/noktayla karışmasın)
            if any(k[0] <= x <= k[2] and k[1] <= y <= k[3] for k in keepout):
                continue
            d.ellipse((S(x - r), S(y - r), S(x + r), S(y + r)), fill=(255, 246, 220, a))
    return Image.alpha_composite(img, deco)


def wrap_lines(text, f, max_w, opts):
    lines = []
    for para in text.split('\n'):
        cur = ''
        for word in para.split(' '):
            cand = word if not cur else cur + ' ' + word
            if not cur or f.getlength(cand, **opts) <= S(max_w):
                cur = cand
            else:
                lines.append(cur)
                cur = word
        lines.append(cur)
    return lines


def wrap_balanced(text, f, max_w, opts):
    """Aynı satır sayısında en dengeli kırılım (tek kelimelik son satır olmasın).
    '|' tercih edilen kırılım yeridir: metin tek satıra sığmazsa önce oradan bölünür."""
    if '|' in text:
        whole = text.replace('|', ' ')
        if '\n' not in whole and f.getlength(whole, **opts) <= S(max_w):
            return [whole]
        return [l for part in text.split('|') for l in wrap_balanced(part, f, max_w, opts)]
    base = wrap_lines(text, f, max_w, opts)
    if len(base) <= 1 or '\n' in text:
        return base
    lo, hi = max_w * 0.4, max_w
    for _ in range(18):
        mid = (lo + hi) / 2
        if len(wrap_lines(text, f, mid, opts)) <= len(base):
            hi = mid
        else:
            lo = mid
    return wrap_lines(text, f, hi, opts)


class TextBlock:
    def __init__(self, text, kind, size, color, lh, max_w, arabic=False):
        self.opts = AR if arabic else TR
        if '\n' in text and not arabic:
            # Elle bölünmüş satırlar korunur: sığmayan satır varsa yazı küçülür
            for _ in range(40):
                widest = max(font(kind, size).getlength(p, **self.opts) for p in text.split('\n')) / SS
                if widest <= max_w:
                    break
                size *= max(0.9, max_w / widest - 0.002)
        self.f = font(kind, size)
        self.lines = wrap_balanced(text, self.f, max_w, self.opts)
        self.color = color
        self.L = size * lh
        if arabic:
            boxes = [self.f.getbbox(l, anchor='ls', **self.opts) for l in self.lines]
            self.top = -boxes[0][1] / SS
            self.bottom = boxes[-1][3] / SS
        else:
            self.top = -self.f.getbbox('H', anchor='ls')[1] / SS  # büyük harf yüksekliği
            self.bottom = 0.2 * size
        self.height = self.top + (len(self.lines) - 1) * self.L + self.bottom
        self.width = max(self.f.getlength(l, **self.opts) for l in self.lines) / SS

    def draw(self, d, cx, y):
        base = y + self.top
        for i, line in enumerate(self.lines):
            d.text((S(cx), S(base + i * self.L)), line, font=self.f, anchor='ms',
                   fill=self.color, **self.opts)


class Divider:
    def __init__(self, scale):
        self.s = scale
        self.height = 24 * scale

    def draw(self, d, cx, y):
        s, cy = self.s, y + self.height / 2
        col = GOLD + (215,)
        lw = max(1, round(S(2.2 * s)))
        d.line((S(cx - 128 * s), S(cy), S(cx - 24 * s), S(cy)), fill=col, width=lw)
        d.line((S(cx + 24 * s), S(cy), S(cx + 128 * s), S(cy)), fill=col, width=lw)
        d.polygon([(S(x), S(yy)) for x, yy in star_points(cx, cy, 12 * s, 0.72)], fill=col)


class Kicker:
    def __init__(self, text, scale):
        self.text = text
        self.f = font('SemiBold', 27 * scale)
        self.s = scale
        self.tw = self.f.getlength(text, **TR) / SS
        self.cap = -self.f.getbbox('H', anchor='ls')[1] / SS
        self.height = 58 * scale
        self.width = self.tw + 52 * scale

    def draw(self, d, cx, y):
        x0, x1 = cx - self.width / 2, cx + self.width / 2
        d.rounded_rectangle((S(x0), S(y), S(x1), S(y + self.height)), radius=S(self.height / 2),
                            fill=(255, 255, 255, 26), outline=(255, 255, 255, 120),
                            width=max(1, round(S(2 * self.s))))
        base = y + self.height / 2 + self.cap / 2
        d.text((S(cx), S(base)), self.text, font=self.f, anchor='ms', fill=MINT, **TR)


class Icon:
    def __init__(self, kind, scale):
        self.kind = kind
        self.s = scale
        self.height = 66 * scale

    def draw(self, d, cx, y, layer):
        s = self.s
        r = 31 * s
        cy = y + self.height / 2
        if self.kind == 'star':
            col = GOLD + (235,)
            d.polygon([(S(a), S(b)) for a, b in star_points(cx, cy, r, 0.78)], outline=col,
                      width=max(1, round(S(3 * s))))
            d.polygon([(S(a), S(b)) for a, b in star_points(cx, cy, r * 0.5, 0.78)], fill=col)
        else:  # hilal
            m = Image.new('L', layer.size, 0)
            md = ImageDraw.Draw(m)
            md.ellipse((S(cx - r), S(cy - r), S(cx + r), S(cy + r)), fill=255)
            ox, oy, rr = cx + r * 0.42, cy - r * 0.22, r * 0.86
            md.ellipse((S(ox - rr), S(oy - rr), S(ox + rr), S(oy + rr)), fill=0)
            solid = Image.new('RGBA', layer.size, GOLD + (240,))
            layer.paste(solid, (0, 0), m)


def logo_img(px):
    if not hasattr(logo_img, 'src'):
        logo_img.src = Image.open(LOGO).convert('RGBA')
    return logo_img.src.resize((round(S(px)), round(S(px))), Image.LANCZOS)


def brand_line(layer, cx, cy, quiet):
    """Küçük marka satırı: logo + 'Vaktinde · Google Play’de ücretsiz'."""
    d = ImageDraw.Draw(layer)
    text = 'Vaktinde · Google Play’de ücretsiz'
    f = font('Medium', 22)
    lg = 34
    tw = f.getlength(text, **TR) / SS
    total = lg + 12 + tw
    x0 = cx - total / 2
    logo = logo_img(lg)
    alpha = 200 if quiet else 255
    if quiet:
        logo.putalpha(logo.getchannel('A').point(lambda v: v * alpha // 255))
    layer.alpha_composite(logo, (round(S(x0)), round(S(cy - lg / 2))))
    cap = -f.getbbox('H', anchor='ls')[1] / SS
    d.text((S(x0 + lg + 12), S(cy + cap / 2)), text, font=f, anchor='ls',
           fill=(255, 255, 255, alpha), **TR)


def store_pill(layer, cx, cy):
    """Belirgin kapsül: logo + 'Google Play’de ücretsiz · Vaktinde'."""
    text = 'Google Play’de ücretsiz · Vaktinde'
    f = font('SemiBold', 28)
    h, lg, pad = 76, 48, 22
    tw = f.getlength(text, **TR) / SS
    w = pad + lg + 14 + tw + pad + 8
    x0, y0 = cx - w / 2, cy - h / 2
    sh = Image.new('L', layer.size, 0)
    ImageDraw.Draw(sh).rounded_rectangle((S(x0), S(y0 + 8), S(x0 + w), S(y0 + h + 8)),
                                         radius=S(h / 2), fill=90)
    sh = sh.filter(ImageFilter.GaussianBlur(S(12)))
    shadow = Image.new('RGBA', layer.size, (0, 30, 26, 255))
    shadow.putalpha(sh)
    layer.alpha_composite(shadow)
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle((S(x0), S(y0), S(x0 + w), S(y0 + h)), radius=S(h / 2), fill=WHITE + (255,))
    layer.alpha_composite(logo_img(lg), (round(S(x0 + pad)), round(S(cy - lg / 2))))
    cap = -f.getbbox('H', anchor='ls')[1] / SS
    d.text((S(x0 + pad + lg + 14), S(cy + cap / 2)), text, font=f, anchor='ls', fill=TEAL_TEXT, **TR)
    return w


BEZEL = 0.032


def phone_height(w, shot_size):
    sw = w * (1 - 2 * BEZEL)
    return sw * shot_size[1] / shot_size[0] + 2 * w * BEZEL


def draw_phone(layer, shot_path, cx, top, w):
    """Basit telefon çerçevesi: yuvarlak köşe, ince çerçeve, hafif gölge. Görüntü kırpılmaz."""
    shot = Image.open(shot_path).convert('RGB')
    W = round(S(w))
    bezel = round(W * BEZEL)
    sw = W - 2 * bezel
    sh = round(sw * shot.height / shot.width)
    H = sh + 2 * bezel
    R = round(W * 0.105)
    x0, y0 = round(S(cx) - W / 2), round(S(top))
    m = Image.new('L', layer.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((x0, y0 + S(20), x0 + W, y0 + H + S(20)), radius=R, fill=120)
    m = m.filter(ImageFilter.GaussianBlur(S(26)))
    shadow = Image.new('RGBA', layer.size, (0, 22, 20, 255))
    shadow.putalpha(m)
    layer.alpha_composite(shadow)
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle((x0, y0, x0 + W - 1, y0 + H - 1), radius=R, fill=(17, 22, 22, 255),
                        outline=(112, 128, 126, 255), width=max(2, round(S(1.6))))
    screen = shot.resize((sw, sh), Image.LANCZOS)
    mask = Image.new('L', (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw - 1, sh - 1), radius=R - bezel, fill=255)
    layer.paste(screen, (x0 + bezel, y0 + bezel), mask)
    return H / SS


# --- Yerleşim ---------------------------------------------------------------------------
def special_blocks(spec, scale, max_w):
    out = []
    ts = spec.get('title_size', 72)
    if spec.get('icon'):
        out.append(('icon', Icon(spec['icon'], scale), 0))
    gaps = dict(kicker=26, title=30, divider=34, arabic=34, quote=30, source=14, greeting=34, body=34)
    prev = 'icon' if spec.get('icon') else None
    for b in spec['blocks']:
        kind = b[0]
        gap = gaps[kind] * scale if prev else 0
        if kind == 'divider' and prev == 'title':
            gap = 36 * scale
        if kind == 'arabic' and prev == 'divider':
            gap = 30 * scale
        if kind == 'kicker':
            el = Kicker(b[1], scale)
        elif kind == 'title':
            el = TextBlock(b[1], 'Bold', ts * scale, WHITE, 1.14, max_w)
        elif kind == 'divider':
            el = Divider(scale)
        elif kind == 'arabic':
            el = TextBlock(b[1], 'Amiri', 60 * scale, WHITE, 1.8, max_w, arabic=True)
        elif kind == 'quote':
            el = TextBlock(b[1], 'Regular', 34 * scale, MINT, 1.45, max_w)
        elif kind == 'source':
            el = TextBlock(b[1], 'SemiBold', 26 * scale, GOLD, 1.2, max_w)
        elif kind == 'greeting':
            el = TextBlock(b[1], 'SemiBold', 42 * scale, WHITE, 1.3, max_w)
        elif kind == 'body':
            el = TextBlock(b[1], 'Medium', 40 * scale, MINT, 1.45, max_w)
        else:
            raise ValueError(kind)
        out.append((kind, el, gap))
        prev = kind
    return out


def render_special(spec, fmt):
    cfg = FORMATS[fmt]
    w, h = cfg['size']
    x0, y0, x1, y1 = cfg['box']
    max_w, box_h = x1 - x0, y1 - y0
    scale = 1.2
    while True:
        blocks = special_blocks(spec, scale, max_w)
        total = sum(el.height + gap for _, el, gap in blocks)
        if total <= box_h or scale < 0.5:
            break
        scale -= 0.02
    assert total <= box_h, (spec['id'], fmt, total)
    cx = (x0 + x1) / 2
    y = max(y0, y0 + (box_h - total) / 2 - box_h * 0.015)  # optik orta, kutudan taşmadan
    placed, keepout = [], []
    for kind, el, gap in blocks:
        y += gap
        placed.append((kind, el, y))
        half = getattr(el, 'width', 300) / 2 + 60
        keepout.append((cx - half, y - 50, cx + half, y + el.height + 50))
        y += el.height
    keepout.append((cx - 300, cfg['brand_y'] - 50, cx + 300, cfg['brand_y'] + 50))
    bg = background(fmt, (w / 2, y0 + box_h * 0.45), w * 0.62, sparkle=True, keepout=keepout)
    fg = Image.new('RGBA', bg.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(fg)
    for kind, el, yy in placed:
        if kind == 'icon':
            el.draw(d, cx, yy, fg)
        else:
            el.draw(d, cx, yy)
            if hasattr(el, 'width'):
                assert el.width <= max_w + 0.5, (spec['id'], kind, el.width)
    brand_line(fg, w / 2, cfg['brand_y'], quiet=True)
    return bg, fg, dict(scale=round(scale, 2), top=round(placed[0][2]), bottom=round(y))


SUB_GAP = 24  # başlık ile alt yazı arası


def render_promo(spec, fmt):
    cfg = FORMATS[fmt]
    w, h = cfg['size']
    if fmt == 'post':
        top, max_w, ts, ss_, pill_y = 62, 940, 56, 30, 1284
    else:
        top, max_w, ts, ss_, pill_y = 300, 840, 58, 31, 1374
    title = TextBlock(spec['title'], 'Bold', ts, WHITE, 1.14, max_w)
    sub = TextBlock(spec['sub'], 'Regular', ss_, MINT, 1.35, max_w)
    shots = [os.path.join(SHOTS, s) for s in spec['shots']]
    sizes = [Image.open(p).size for p in shots]
    ph_top = top + title.height + SUB_GAP + sub.height + 40
    ph_bottom = pill_y - 38 - 34
    avail = ph_bottom - ph_top
    n = len(shots)
    gap = 34
    col_w = (max_w - (n - 1) * gap) / n if n > 1 else 560
    pw = min(col_w, avail / (phone_height(1, sizes[0])))
    ph = phone_height(pw, sizes[0])
    glow_y = ph_top + ph / 2
    bg = background(fmt, (w / 2, glow_y), w * 0.55)
    fg = Image.new('RGBA', bg.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(fg)
    title.draw(d, w / 2, top)
    sub.draw(d, w / 2, top + title.height + SUB_GAP)
    ptop = ph_top + (avail - ph) / 2
    total_w = n * pw + (n - 1) * gap
    for i, p in enumerate(shots):
        cx = w / 2 - total_w / 2 + pw / 2 + i * (pw + gap)
        draw_phone(fg, p, cx, ptop, pw)
    pill_w = store_pill(fg, w / 2, pill_y)
    assert title.width <= max_w and sub.width <= max_w and pill_w <= max_w, spec['id']
    return bg, fg, dict(phone_w=round(pw), title_lines=len(title.lines), sub_lines=len(sub.lines))


# --- Çıktı ---------------------------------------------------------------------------------
def finalize(bg, fg, size):
    return Image.alpha_composite(bg, fg).convert('RGB').resize(size, Image.LANCZOS)


def ease(t):
    return 1 - (1 - t) ** 3


def write_video(bg, fg, path):
    W, H = FORMATS['story']['size']
    full = Image.alpha_composite(bg, fg).convert('RGB')
    cx, cy = S(ZOOM_CENTER[0]), S(ZOOM_CENTER[1])
    cmd = [FFMPEG, '-y', '-loglevel', 'error', '-f', 'rawvideo', '-pix_fmt', 'rgb24',
           '-s', f'{W}x{H}', '-r', str(FPS), '-i', '-', '-an',
           '-vf', 'scale=out_color_matrix=bt709:out_range=tv,format=yuv420p',
           '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-profile:v', 'high',
           '-level', '4.1', '-pix_fmt', 'yuv420p', '-r', str(FPS),
           '-color_primaries', 'bt709', '-color_trc', 'bt709', '-colorspace', 'bt709',
           '-movflags', '+faststart', path]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    alpha = fg.getchannel('A')
    for i in range(FRAMES):
        if i < FADE_FRAMES:  # yumuşak giriş: içerik zeminin üstünde belirir, hafifçe yükselir
            e = ease((i + 1) / FADE_FRAMES)
            layer = fg.copy()
            layer.putalpha(alpha.point(lambda v, e=e: round(v * e)))
            src = bg.copy()
            src.alpha_composite(layer, (0, round(S(18 * (1 - e)))))
            src = src.convert('RGB')
        else:
            src = full
        z = 1 + (ZOOM_END - 1) * i / (FRAMES - 1)  # sabit hızda, alt piksel kutuyla (titremesiz)
        box = (cx - cx / z, cy - cy / z, cx - cx / z + S(W) / z, cy - cy / z + S(H) / z)
        frame = src.resize((W, H), Image.BICUBIC, box=box)
        proc.stdin.write(frame.tobytes())
    proc.stdin.close()
    if proc.wait() != 0:
        raise RuntimeError('ffmpeg hata verdi: ' + path)


def build(item, out_dir, video):
    folder = os.path.join(out_dir, item['id'])
    os.makedirs(folder, exist_ok=True)
    render = render_promo if 'shots' in item else render_special
    info = {}
    for fmt in ('post', 'story'):
        bg, fg, meta = render(item, fmt)
        info[fmt] = meta
        finalize(bg, fg, FORMATS[fmt]['size']).save(os.path.join(folder, f'{fmt}.png'), optimize=True)
        if fmt == 'story' and video:
            write_video(bg, fg, os.path.join(folder, 'video.mp4'))
    return item['id'], info


def contact_sheet(out_dir, ids):
    tw, th, gap, label = 288, 360, 22, 34
    cols = 5
    rows = math.ceil(len(ids) / cols)
    W = cols * tw + (cols + 1) * gap
    H = rows * (th + label) + (rows + 1) * gap
    sheet = Image.new('RGB', (W, H), (236, 241, 240))
    d = ImageDraw.Draw(sheet)
    f = ImageFont.truetype(POPPINS.format('Medium'), 18, layout_engine=ImageFont.Layout.RAQM)
    for i, cid in enumerate(ids):
        r, c = divmod(i, cols)
        x = gap + c * (tw + gap)
        y = gap + r * (th + label + gap)
        im = Image.open(os.path.join(out_dir, cid, 'post.png')).resize((tw, th), Image.LANCZOS)
        sheet.paste(im, (x, y))
        d.text((x + tw / 2, y + th + 24), cid, font=f, anchor='ms', fill=(30, 40, 40))
    sheet.save(os.path.join(out_dir, '_onizleme.jpg'), quality=88)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('out', help='çıkış klasörü')
    ap.add_argument('--sadece', help='virgülle ayrılmış içerik adları')
    ap.add_argument('--videosuz', action='store_true', help='video üretme (hızlı deneme)')
    ap.add_argument('--zip', help='hepsini bu zip dosyasına da koy (takvim dahil)')
    ap.add_argument('--is', type=int, default=min(4, os.cpu_count() or 1), dest='jobs')
    args = ap.parse_args()

    if not features.check('raqm'):
        sys.exit('Pillow raqm desteği yok: Arapça metin doğru şekillenmez.')
    items = SPECIALS + PROMOS
    if args.sadece:
        want = set(args.sadece.split(','))
        items = [i for i in items if i['id'] in want]
    os.makedirs(args.out, exist_ok=True)
    with ProcessPoolExecutor(max_workers=args.jobs) as ex:
        futs = [ex.submit(build, it, args.out, not args.videosuz) for it in items]
        for fu in futs:
            cid, info = fu.result()
            print(cid, info)
    all_ids = [i['id'] for i in SPECIALS + PROMOS
               if os.path.exists(os.path.join(args.out, i['id'], 'post.png'))]
    contact_sheet(args.out, all_ids)
    if args.zip:
        cal = os.path.join(HERE, 'icerik_takvimi.md')
        with zipfile.ZipFile(args.zip, 'w', zipfile.ZIP_DEFLATED) as z:
            if os.path.exists(cal):
                z.write(cal, 'icerik_takvimi.md')
            z.write(os.path.join(args.out, '_onizleme.jpg'), '_onizleme.jpg')
            for cid in all_ids:
                for name in ('post.png', 'story.png', 'video.mp4'):
                    p = os.path.join(args.out, cid, name)
                    if os.path.exists(p):
                        z.write(p, f'{cid}/{name}', compress_type=zipfile.ZIP_STORED)
        print('zip:', args.zip)


if __name__ == '__main__':
    main()
