#!/usr/bin/env python3
"""Vaktinde 1.3.0 mağaza ve tanıtım görselleri (Play Store, Instagram, video).

Kullanım:
  python3 docs/marketing/make_store_assets.py <ekran_klasörü> <çıkış_klasörü>
          [--sadece play,instagram,video] [--diller tr,en,de,fr,ar] [--zipsiz]

Ekran görüntüleri test/screenshots düzeneğinin pazarlama çeşitleridir
(m_<dil>_NN_*.png, 3x; dil başına o şehrin saat dilimiyle):
  for x in tr:Europe/Istanbul en:Europe/London de:Europe/Berlin fr:Europe/Paris ar:Europe/Istanbul; do
    SCREENSHOT_MARKETING=${x%%:*} SCREENSHOT_DPR=3 SCREENSHOT_DIR=<ekran_klasörü> TZ=${x#*:} \\
      flutter test test/screenshots/ --plain-name "${x%%:*}: pazarlama"
  done
Ana ekran (sıradaki vakit, sayaç, kerahat) çekim saatine göre değişir; öğleden sonra iyi görünür.

Çıktılar (<çıkış>/):
  play/<dil>/01..08_*.png        1080×1920 telefon ekran görüntüleri (8; arka plan yan yana akar,
                                 Arapçada sıra sağdan sola olduğu için aynalanır)
  play/<dil>/feature_graphic.png 1024×500 öne çıkan görsel
  instagram/triptik_1|2/{1,2,3}_*.png  1080×1440 üçlü ızgara (tek resmin üç parçası)
  instagram/karusel/{1..5}.png   1080×1350 kaydırmalı gönderi (kenarlardan akar)
  instagram/hikaye/{1,2,3}.png   1080×1920 hikâye
  video/<dil>/tanitim_dikey.mp4  1080×1920, 19 sn, 30 fps, sessiz (Reels/TikTok/Shorts); tr ve en
  video/<dil>/tanitim_yatay.mp4  1920×1080, aynı akış (YouTube / Play tanıtım videosu)
  _onizleme_*.jpg, README.md, *.zip (her biri ≤ 24 MB)

Dikey dosyalarda yazılar y 250–1570 arasında kalır (platform düğmeleri). Ekran görüntüleri
uygulamanın gerçek arayüzüdür; çerçeve, durum çubuğu, bildirim kartı ve ana ekran widget'ları
uygulamadaki metin ve renklerle (res/layout, lib/l10n) çizilir. Dini metin eklenmez.
Ortak yardımcılar make_content.py'den gelir. Roboto ve Noto Naskh Arabic (bildirim, widget)
Flutter SDK'sından okunur (FLUTTER_ROOT ya da PATH'teki flutter); yoksa Poppins / Amiri.

Gerekenler: Python 3, Pillow (raqm), numpy, ffmpeg (libx264).
"""
import argparse
import json
import math
import os
import shutil
import subprocess
import sys
import zipfile
from concurrent.futures import ProcessPoolExecutor

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, features

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import make_content as mc  # noqa: E402  (font, star_points, wrap_balanced, logo_img, Divider)

REPO = mc.REPO
SS, S = mc.SS, mc.S
LANGS = ['tr', 'en', 'de', 'fr', 'ar']
VIDEO_LANGS = ['tr', 'en']  # VIDEO_TEXT anahtarları
ARB = {l: json.load(open(os.path.join(REPO, 'lib', 'l10n', f'app_{l}.arb'), encoding='utf-8'))
       for l in LANGS}
WALL = os.path.join(REPO, 'assets', 'images', 'backgrounds', 'bg_plain{}.webp')


def _flutter_root():
    root = os.environ.get('FLUTTER_ROOT')
    exe = shutil.which('flutter')
    if not root and exe:
        root = os.path.dirname(os.path.dirname(os.path.realpath(exe)))
    return root or ''


_FR = _flutter_root()
ROBOTO = os.path.join(_FR, 'bin', 'cache', 'artifacts', 'material_fonts', 'Roboto-{}.ttf')
NASKH = os.path.join(_FR, 'engine', 'src', 'flutter', 'txt', 'third_party', 'fonts',
                     'NotoNaskhArabic-Regular.ttf')

# Marka renkleri
TOP, BOTTOM = (0, 98, 87), (0, 40, 36)
GLOW, SAND, GOLD = (24, 150, 134), (233, 214, 172), mc.GOLD
WHITE, CREAM = (255, 255, 255), (246, 236, 214)
TEAL_TEXT = mc.TEAL_TEXT

# --- Metinler ---------------------------------------------------------------------------
# Play: (başlık, alt yazı) × 8. Ad/terimler uygulamanın kendi çevirilerinden (lib/l10n).
PLAY_TEXT = {
    'tr': [('Ezan vakti cebinizde', 'Diyanet yöntemiyle internetsiz hesap ve geri sayım'),
           ("Kur'an-ı Kerim ve Hatim", 'Mushaf sayfası, ayet ayet ya da meal; günlük hedef'),
           ('Her vakte ayrı ezan', 'Bildirimdeki “Durdur” ile tek dokunuşla susturun'),
           ('Namazlarınızı takip edin', '7 ve 40 günlük seri hedefleri, kaza sayacı'),
           ('Kıbleyi kolayca bulun', 'Manyetik sapması düzeltilen kıble pusulası'),
           ('Zikir, dua ve namaz', 'Zikirmatik, Dualar, Tesbihat ve Namaz Hocası'),
           ("Ramazan'a ve Cuma'ya hazır", 'İmsakiye, sahur ve iftar vakitleri, Cuma mesajları'),
           ('Ana ekranınızda vakit', "Vakit halkası, namaz takibi ve Ramazan widget'ları")],
    'en': [('Prayer times in your pocket', 'Calculated offline with the Diyanet method, with a countdown'),
           ('The Quran and your Khatm', 'Mushaf page, verse by verse or translation, with a daily goal'),
           ('An adhan for every prayer', 'Silence it with one tap on “Stop” in the notification'),
           ('Keep track of your prayers', '7- and 40-day streak goals and a qada counter'),
           ('The Qibla, wherever you are', 'A compass corrected for magnetic declination'),
           ('Dhikr, duas and prayer', 'Dhikr counter, duas, tasbih and a step-by-step prayer guide'),
           ('Ready for Ramadan and Jumu’ah', 'Prayer timetable, suhoor and iftar times, Friday messages'),
           ('Prayer times at a glance', 'Prayer ring, prayer tracker and Ramadan widgets')],
    'de': [('Gebetszeiten immer dabei', 'Offline nach der Diyanet-Methode berechnet, mit Countdown'),
           ('Der Koran und Ihr Khatm', 'Mushaf-Seite, Vers für Vers oder Übersetzung, mit Tagesziel'),
           ('Adhan für jedes Gebet', 'Mit einem Tipp auf „Stoppen“ in der Benachrichtigung beenden'),
           ('Gebete im Blick', 'Serienziele für 7 und 40 Tage, Qada-Zähler'),
           ('Die Qibla, wo Sie auch sind', 'Kompass mit Korrektur der magnetischen Abweichung'),
           ('Dhikr, Bittgebete, Gebet', 'Dhikr-Zähler, Bittgebete, Tasbih und Gebetsanleitung'),
           ('Bereit für Ramadan und Freitag', 'Gebetskalender, Suhur- und Iftar-Zeiten, Freitagsgrüße'),
           ('Gebetszeiten auf einen Blick', 'Widgets: Gebetsring, Gebetstracker und Ramadan')],
    'fr': [('Vos horaires de prière', 'Calculés hors ligne selon la méthode Diyanet, avec compte à rebours'),
           ('Le Coran et votre Khatm', 'Page du mushaf, verset par verset ou traduction, objectif quotidien'),
           ('Un adhan pour chaque prière', 'Coupez-le d’une touche avec « Arrêter » dans la notification'),
           ('Suivez vos prières', 'Objectifs de série de 7 et 40 jours, compteur de qada'),
           ('La Qibla, où que vous soyez', 'Boussole corrigée de la déclinaison magnétique'),
           ('Dhikr, invocations, prière', 'Compteur de dhikr, invocations, tasbih et guide de la prière'),
           ('Prêt pour le Ramadan', 'Calendrier des prières, suhoor et iftar, messages du vendredi'),
           ('Vos prières en un coup d’œil', 'Widgets : anneau des prières, suivi et Ramadan')],
    'ar': [('مواقيت الصلاة معك دائمًا', 'تُحسب على هاتفك دون إنترنت، مع عدّ تنازلي'),
           ('القرآن الكريم والختمة', 'صفحات المصحف أو آية آية، مع هدف يومي'),
           ('أذان لكل صلاة', 'أوقِفه بلمسة واحدة على «إيقاف» في الإشعار'),
           ('تابِع صلواتك', 'أهداف المواظبة لـ 7 و40 يومًا وعدّاد القضاء'),
           ('القبلة أينما كنت', 'بوصلة مع تصحيح الانحراف المغناطيسي'),
           ('الذكر والدعاء والصلاة', 'مسبحة إلكترونية، أدعية، تسبيح وتعليم الصلاة'),
           ('مستعد لرمضان والجمعة', 'جدول المواقيت، السحور والإفطار، رسائل الجمعة'),
           ('المواقيت على شاشتك الرئيسية', 'أدوات: حلقة الأوقات، متابعة الصلوات، رمضان')],
}
# Öne çıkan görsel: slogan + üç kısa özellik
FG_TEXT = {
    'tr': ("Ezan vakti, Kur'an ve kıble|tek uygulamada", ['İnternetsiz', 'Ezan alarmı', 'Hatim takibi']),
    'en': ('Prayer times, Quran and Qibla|in one app', ['Offline', 'Adhan alerts', 'Khatm tracker']),
    'de': ('Gebetszeiten, Koran und Qibla|in einer App', ['Offline', 'Adhan-Alarm', 'Khatm-Plan']),
    'fr': ('Horaires de prière, Coran et Qibla|dans une seule app', ['Hors ligne', 'Alertes adhan', 'Suivi du Khatm']),
    'ar': ('مواقيت الصلاة والقرآن والقبلة|في تطبيق واحد', ['مواقيت دون إنترنت', 'تنبيه الأذان', 'متابعة الختمة']),
}
# Bildirim kartı: "şimdi" (Android'in metni); başlık/gövde/düğmeler uygulamanın çevirisi
NOW = {'tr': 'şimdi', 'en': 'now', 'de': 'jetzt', 'fr': 'maintenant', 'ar': 'الآن'}
# Ana ekran widget'ları: Ramazan'ın 11. günü, akşama 1:03:20 (imsakiye ekranındaki vakit)
WIDGET_DEMO = {'tr': ('18:48', '17:45'), 'en': ('5:28 PM', '4:25'), 'de': ('18:00', '16:57'),
               'fr': ('18:23', '17:20'), 'ar': ('6:49 م', '5:46')}

PLAY_SHOTS = [  # (öndeki ekran, arkadaki ekran, ek)
    ('01_home', None, None), ('15_quran_page', '03_quran_tab', None), ('02_alarms', None, 'notif'),
    ('07_tracker', '08_kaza', None), ('04_qibla', None, None), ('05_zikir', '11_prayer_guide', None),
    ('09_imsakiye_ramadan', '10_friday', None), ('launcher', None, None)]
PLAY_NAMES = ['vakitler', 'kuran_hatim', 'ezan_durdur', 'takip_kaza', 'kible', 'zikir_dua',
              'ramazan_cuma', 'widget']

# Instagram ve video (Türkçe)
IG_TRIPTYCHS = [
    ('triptik_1', [('Ezan vakti', 'Diyanet yöntemiyle, internetsiz', '01_home'),
                   None,  # ortada marka
                   ('Kur’an ve hatim', 'Sayfa sayfa okuyun, hedef koyun', '15_quran_page')]),
    ('triptik_2', [('Kıble pusulası', 'Bulunduğunuz yerden Kâbe yönü', '04_qibla'),
                   ('Namaz takibi', 'Seri hedefleri ve kaza sayacı', '07_tracker'),
                   ('Zikirmatik', 'Hedef belirleyin, dokunun, sayın', '05_zikir')]),
]
VIDEO_SCENES = [  # (başlangıç sn, bitiş sn, ekran(lar)); başlıklar VIDEO_TEXT'te aynı sırayla
    (2.2, 5.0, ['01_home']),
    (5.0, 7.8, ['02_alarms']),
    (7.8, 10.6, ['03_quran_tab', '15_quran_page']),
    (10.6, 12.8, ['07_tracker']),
    (12.8, 14.6, ['04_qibla']),
    (14.6, 16.2, ['05_zikir']),
]
# Video dilleri: sahne başlıkları (başlık, alt yazı), kapanış kapsülü, kapanıştaki özellikler
VIDEO_TEXT = {
    'tr': ([('Namaz vakitleri,|saniyesi saniyesine', 'Diyanet yöntemiyle, internetsiz'),
            ('Ezanı tek dokunuşla|durdurun', 'Bildirimdeki “Durdur” ile'),
            ('Kur’an-ı Kerim|ve hatim takibi', 'Mushaf sayfası ve günlük hedef'),
            ('Namaz takibi|ve kaza', '7 ve 40 günlük seri hedefleri'),
            ('Kıble pusulası', 'Bulunduğunuz yerden Kâbe yönü'),
            ('Zikirmatik|ve dualar', 'Tesbihat ve Namaz Hocası')],
           "Google Play'de Vaktinde", 'İmsakiye · Zikirmatik · Namaz Hocası · 5 dil'),
    'en': ([('Prayer times,|to the second', 'Diyanet method, works offline'),
            ('Silence the adhan|with one tap', 'With “Stop” in the notification'),
            ('The Quran and|Khatm tracking', 'Mushaf pages and a daily goal'),
            ('Prayer tracker|and qada', '7- and 40-day streak goals'),
            ('Qibla compass', 'The Kaaba’s direction from where you are'),
            ('Dhikr counter|and duas', 'Tasbih after prayer and a Prayer Guide')],
           'Vaktinde on Google Play', 'Prayer Timetable · Dhikr Counter · Prayer Guide · 5 languages'),
}
VIDEO_SECONDS = 19.0
FPS = 30


# --- Yazı ------------------------------------------------------------------------------------
_fc = {}


def font(kind, size):
    """Poppins ağırlıkları, 'Amiri', 'Naskh' ya da 'Roboto<ağırlık>' (SS ölçeğinde)."""
    key = (kind, round(size * SS))
    if key not in _fc:
        if kind.startswith('Roboto'):
            path = ROBOTO.format(kind[6:])
            if not os.path.exists(path):
                path = mc.POPPINS.format({'Regular': 'Regular', 'Medium': 'Medium'}.get(kind[6:], 'SemiBold'))
        elif kind == 'Naskh':
            path = NASKH if os.path.exists(NASKH) else mc.AMIRI
        elif kind == 'Amiri':
            path = mc.AMIRI
        else:
            path = mc.POPPINS.format(kind)
        _fc[key] = ImageFont.truetype(path, key[1], layout_engine=ImageFont.Layout.RAQM)
    return _fc[key]


def opts(lang):
    return {'direction': 'rtl', 'language': 'ar'} if lang == 'ar' else {'language': lang}


def arabic_digits(s):
    return s.translate(str.maketrans('0123456789', '٠١٢٣٤٥٦٧٨٩'))


class Txt:
    """Dengeli satırlara bölünen, sığmazsa küçülen metin (ölçüler 1x piksel).
    Arapça Amiri ile (kalın başlıkta ince kontur) ve sağdan sola yazılır."""

    def __init__(self, text, size, lang, kind='Bold', color=WHITE, lh=1.16, max_w=900, max_lines=2):
        self.ar = lang == 'ar'
        self.o = opts(lang)
        self.color = color
        if self.ar:
            kind, size, lh = ('Amiri', size * 1.12, max(lh, 1.42)) if kind != 'Naskh' else (kind, size, lh)
        bold = kind == 'Amiri' and size > 40
        while True:
            self.f = font(kind, size)
            self.lines = mc.wrap_balanced(text, self.f, max_w, self.o)
            self.width = max(self.f.getlength(l, **self.o) for l in self.lines) / SS
            if (len(self.lines) <= max_lines and self.width <= max_w) or size < 14:
                break
            size *= 0.96
        self.size = size
        self.stroke = round(size * SS * 0.016) if bold else 0
        self.L = size * lh
        if self.ar:
            boxes = [self.f.getbbox(l, anchor='ls', **self.o) for l in self.lines]
            self.top = -boxes[0][1] / SS
            self.bottom = boxes[-1][3] / SS
        else:
            self.top = -self.f.getbbox('H', anchor='ls')[1] / SS
            self.bottom = 0.24 * size
        self.height = self.top + (len(self.lines) - 1) * self.L + self.bottom

    def draw(self, d, x, y, align='center', alpha=255):
        """align: center | start | end (sağdan sola dilde start = sağ kenar, x o kenardır)."""
        anchor = {'center': 'ms', 'start': 'rs' if self.ar else 'ls', 'end': 'ls' if self.ar else 'rs'}[align]
        for i, line in enumerate(self.lines):
            d.text((S(x), S(y + self.top + i * self.L)), line, font=self.f, anchor=anchor,
                   fill=self.color + (alpha,), stroke_width=self.stroke,
                   stroke_fill=self.color + (alpha,), **self.o)


def line_top(t, cy):
    """Tek satırlık metnin görsel ortası cy'de olacak üst y (Latin: büyük harf, Arapça: harf kutusu)."""
    if not t.ar:
        return cy - t.top / 2
    b = t.f.getbbox(t.lines[0], anchor='ls', **t.o)
    return cy - (b[1] + b[3]) / 2 / SS - t.top


def chip(d, cx, cy, text, lang, size=22, h=None, color=CREAM, fill=(255, 255, 255, 26),
         outline=GOLD + (150,), measure=False):
    """Kapsül içinde tek satır; genişliği döndürür (measure: çizmeden)."""
    t = Txt(text, size, lang, kind='Medium', color=color, max_w=2000, max_lines=1)
    h = h or size * 2.05
    w = t.width + size * 1.6
    if not measure:
        d.rounded_rectangle((S(cx - w / 2), S(cy - h / 2), S(cx + w / 2), S(cy + h / 2)), radius=S(h / 2),
                            fill=fill, outline=outline, width=max(1, round(S(1.3))))
        t.draw(d, cx, line_top(t, cy))
    return w


def brand_pill(canvas, cx, cy, text, size=30):
    """Beyaz kapsül: logo + metin (ör. "Google Play'de Vaktinde"); rozet değil, yalnız metin."""
    d = ImageDraw.Draw(canvas, 'RGBA')
    t = Txt(text, size, 'tr', kind='SemiBold', color=TEAL_TEXT, max_w=2000, max_lines=1)
    h, lg, pad = size * 2.7, size * 1.75, size * 0.8
    w = pad + lg + size * 0.5 + t.width + pad * 1.3
    x0 = cx - w / 2
    shadow(canvas, rrect_mask(S(w), S(h), S(h / 2)), S(x0), S(cy - h / 2), S(14), S(8), 0.35)
    d.rounded_rectangle((S(x0), S(cy - h / 2), S(x0 + w), S(cy + h / 2)), radius=S(h / 2), fill=WHITE + (255,))
    logo = mc.logo_img(lg)
    canvas.paste(logo, (round(S(x0 + pad)), round(S(cy - lg / 2))), logo)
    t.draw(d, x0 + pad + lg + size * 0.5, line_top(t, cy) - 1, 'start')
    return w


# --- Zemin ------------------------------------------------------------------------------------
class Backdrop:
    """Panorama zemini: dikey teal geçiş, ışımalar, sade arka planlardaki silik 8 köşeli yıldız
    deseni, kenarlardan taşan büyük yıldız çizgileri ve altın şerit. Koordinatlar panoramaya göre:
    parçalar ayrı çizilse de birleşince kesintisizdir."""

    def __init__(self, W, H, glows=(), stars=(), ribbon=None, lattice=(92, 80, 12)):
        self.W, self.H = W, H
        self.glows, self.stars, self.ribbon, self.lattice = glows, stars, ribbon, lattice

    def render(self, ox, oy, w, h, ss=SS):
        yy, xx = np.mgrid[oy:oy + h, ox:ox + w].astype(np.float32)
        t = (yy / self.H)[..., None]
        arr = np.array(TOP, np.float32) * (1 - t) + np.array(BOTTOM, np.float32) * t
        for gx, gy, r, col, s in self.glows:
            g = (np.exp(-((xx - gx) ** 2 + (yy - gy) ** 2) / (r * r)) * s)[..., None]
            arr = arr * (1 - g) + np.array(col, np.float32) * g
        arr += np.random.default_rng(ox * 7 + oy).uniform(-0.7, 0.7, arr.shape).astype(np.float32)
        img = Image.fromarray(np.clip(arr + 0.5, 0, 255).astype(np.uint8), 'RGB')
        if ss != 1:
            img = img.resize((w * ss, h * ss), Image.BICUBIC)
        d = ImageDraw.Draw(img, 'RGBA')
        k = ss

        def P(pts):
            return [((x - ox) * k, (y - oy) * k) for x, y in pts]

        dx, dy, r = self.lattice
        for j in range(int((oy - r) // dy), int((oy + h + r) // dy) + 1):
            off = (j % 2) * dx / 2
            for i in range(int((ox - r - off) // dx), int((ox + w + r - off) // dx) + 1):
                d.polygon(P(mc.star_points(i * dx + off, j * dy + dy / 2, r, 0.78)), fill=(255, 255, 255, 9))
        for sx, sy, sr in self.stars:
            if sx + sr < ox or sx - sr > ox + w:
                continue
            d.polygon(P(mc.star_points(sx, sy, sr, 0.76)), outline=GOLD + (44,), width=max(1, round(2.2 * k)))
            d.polygon(P(mc.star_points(sx, sy, sr * 0.64, 0.76)), outline=(255, 255, 255, 24),
                      width=max(1, round(1.6 * k)))
        if self.ribbon:
            for dy_, a, wd in ((0, 165, 3.0), (16, 80, 1.4)):
                pts = [(x, self.ribbon(x) + dy_) for x in range(ox - 20, ox + w + 21, 6)]
                d.line(P(pts), fill=GOLD + (a,), width=max(1, round(wd * k)), joint='curve')
        return img


def wave(base, amp, period, phase=0.0):
    return lambda x: base + amp * math.sin(2 * math.pi * x / period + phase)


# --- Gölge, telefon, bildirim, widget ----------------------------------------------------------
def rrect_mask(w, h, r):
    m = Image.new('L', (round(w), round(h)), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, round(w) - 1, round(h) - 1), radius=round(r), fill=255)
    return m


def shadow(canvas, mask, x, y, blur, dy, opacity, color=(0, 22, 20)):
    """Bulanık gölge (küçültülmüş maskeyle hızlı); canvas RGB, koordinatlar SS pikseli."""
    q = 4
    pad = int(blur * 2.5)
    m = Image.new('L', ((mask.width + 2 * pad) // q + 1, (mask.height + 2 * pad) // q + 1), 0)
    m.paste(mask.resize((max(1, mask.width // q), max(1, mask.height // q)), Image.BILINEAR), (pad // q, pad // q))
    m = m.filter(ImageFilter.GaussianBlur(blur / q)).resize((m.width * q, m.height * q), Image.BILINEAR)
    m = m.point(lambda v: round(v * opacity))
    canvas.paste(Image.new('RGB', m.size, color), (round(x) - pad, round(y) - pad + round(dy)), m)


def status_bar(shot, clock, lang):
    """Durum çubuğu (28 dp: saat, kamera deliği, simgeler) ve hareketle gezinme çizgisi (20 dp).
    Sağdan sola dilde Android gibi aynalanır; renk zemine göre."""
    shot = shot.convert('RGB')
    W, H = shot.size
    k = W / 411
    d = ImageDraw.Draw(shot, 'RGBA')
    light = np.asarray(shot.crop((0, 0, W, round(28 * k))).convert('L')).mean() > 150
    col = (28, 32, 32, 255) if light else (255, 255, 255, 255)
    rtl = lang == 'ar'

    def X(x):  # dp, soldan; RTL'de aynalanır
        return (411 - x if rtl else x) * k

    cy = 14.5 * k
    f = font('Naskh' if rtl else 'RobotoMedium', 14 * k / SS)
    d.text((X(24), cy), arabic_digits(clock) if rtl else clock, font=f, fill=col,
           anchor='rm' if rtl else 'lm')
    d.ellipse((W / 2 - 5.5 * k, cy - 5.5 * k, W / 2 + 5.5 * k, cy + 5.5 * k), fill=(6, 8, 8, 255))
    # pil (en dışta), sinyal, wifi
    bx = 411 - 24 - 22
    b0, b1 = X(bx), X(bx + 20)
    bl, br = min(b0, b1), max(b0, b1)
    d.rounded_rectangle((bl, cy - 5.5 * k, br, cy + 5.5 * k), radius=2.6 * k, outline=col, width=round(1.4 * k))
    fill_w = (br - bl - 4.4 * k) * 0.82
    fl = br - 2.2 * k - fill_w if rtl else bl + 2.2 * k
    d.rounded_rectangle((fl, cy - 3.3 * k, fl + fill_w, cy + 3.3 * k), radius=1.2 * k, fill=col)
    nub = X(bx + 21.5)
    d.rectangle((min(nub, X(bx + 20)), cy - 2 * k, max(nub, X(bx + 20)), cy + 2 * k), fill=col)
    sx = bx - 7 - 13
    tri = [(X(sx), cy + 6.5 * k), (X(sx + 13), cy + 6.5 * k), (X(sx + 13), cy - 6.5 * k)]
    d.polygon(tri, fill=col)
    wx = sx - 6 - 9
    wc = X(wx)
    d.pieslice((wc - 9.5 * k, cy - 6 * k, wc + 9.5 * k, cy + 13 * k), 225, 315, fill=col)
    # gezinme çizgisi
    light_b = np.asarray(shot.crop((0, H - round(20 * k), W, H)).convert('L')).mean() > 128
    pc = (40, 44, 44, 230) if light_b else (235, 240, 239, 230)
    d.rounded_rectangle((W / 2 - 54 * k, H - 12 * k, W / 2 + 54 * k, H - 7.5 * k), radius=2.3 * k, fill=pc)
    return shot


BEZEL, RADIUS = 0.026, 0.118


class Phone:
    """Telefon çerçevesi (SS ölçeğinde RGBA): ince koyu çerçeve, metal kenar, yan düğmeler."""

    def __init__(self, shot, w):
        self.w = w = round(w)
        bez, R = round(w * BEZEL), round(w * RADIUS)
        sw = w - 2 * bez
        sh = round(sw * shot.height / shot.width)
        self.h = h = sh + 2 * bez
        self.pad = pad = round(w * 0.012)
        img = Image.new('RGBA', (w + 2 * pad, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        bw = round(w * 0.012)
        for y0, ln in ((0.19, 0.07), (0.30, 0.12)):
            d.rounded_rectangle((pad + w - 2 * bw, round(h * y0), pad + w + bw, round(h * (y0 + ln))),
                                radius=bw, fill=(52, 60, 59, 255))
        edge = max(2, round(w * 0.0045))
        d.rounded_rectangle((pad, 0, pad + w - 1, h - 1), radius=R, fill=(92, 104, 102, 255))
        d.rounded_rectangle((pad + edge, edge, pad + w - 1 - edge, h - 1 - edge), radius=R - edge,
                            fill=(12, 15, 15, 255))
        self.screen_box = (pad + bez, bez, sw, sh)
        self.screen_mask = rrect_mask(sw, sh, R - bez)
        img.paste(shot.resize((sw, sh), Image.LANCZOS), (pad + bez, bez), self.screen_mask)
        self.img = img
        self.mask = rrect_mask(w, h, R)

    def place(self, canvas, cx, top, shade=0.55):
        """Gölgesiyle yapıştırır (cx, top: SS pikseli, gövdenin ortası/üstü)."""
        x0 = round(cx - self.w / 2)
        shadow(canvas, self.mask, x0, top, self.w * 0.045, self.w * 0.04, shade)
        canvas.paste(self.img, (x0 - self.pad, round(top)), self.img)
        return x0


def notif_card(lang, width):
    """Ezan bildirimi (Android 12+ görünümü): uygulamanın başlık, gövde ve düğme metinleri."""
    L = ARB[lang]
    rtl = lang == 'ar'
    k = width / 395  # px/dp
    h = round(146 * k)
    img = Image.new('RGB', (round(width), h), (250, 252, 251))  # RGB: yarı saydam boya karışsın
    d = ImageDraw.Draw(img, 'RGBA')
    d.rounded_rectangle((0, 0, img.width - 1, h - 1), radius=26 * k, outline=(214, 226, 223, 255),
                        width=max(1, round(k)))
    fk = (lambda w: 'Naskh') if rtl else (lambda w: 'Roboto' + w)

    def tx(x, y, s, size, weight, color, anchor='ls'):
        f = font(fk(weight), size * k / SS)
        if rtl:
            x = img.width - x
            anchor = {'ls': 'rs', 'rs': 'ls', 'ms': 'ms', 'lm': 'rm'}[anchor]
        d.text((x, y), s, font=f, fill=color, anchor=anchor, **opts(lang))
        return f.getlength(s, **opts(lang))

    logo = mc.logo_img(9 * k / SS * 2)
    lx = 18 * k if not rtl else img.width - 18 * k - logo.width
    img.paste(logo, (round(lx), round(16 * k)), logo)
    # üst satır: uygulama adı (Latin, Roboto) • zaman (dilin yazısıyla)
    grey = (90, 98, 97, 255)
    f_lat, f_now = font('RobotoRegular', 12.5 * k / SS), font(fk('Regular'), 12.5 * k / SS)
    x = 46 * k
    for part, f in (('Vaktinde', f_lat), ('•', f_lat), (NOW[lang], f_now)):
        d.text((img.width - x if rtl else x, 29 * k), part, font=f, fill=grey, anchor='rs' if rtl else 'ls',
               **opts(lang if f is f_now else 'en'))
        x += f.getlength(part) + 5 * k
    # açılır ok
    ax = img.width - 26 * k if not rtl else 26 * k
    d.line([(ax - 5 * k, 22 * k), (ax, 27 * k), (ax + 5 * k, 22 * k)], fill=(90, 98, 97, 255), width=round(1.8 * k))
    tx(46 * k, 58 * k, L['notifTitleTime'], 16, 'Medium', (28, 30, 30, 255))
    tx(46 * k, 81 * k, L['notifBodyTime'].replace('{vakit}', L['ogle']), 14.5, 'Regular', (70, 78, 77, 255))
    # düğmeler: Kıldım, Durdur (basılı)
    x = 46 * k
    for i, lbl in enumerate((L['trackerPrayedAction'], L['notifStopAction'])):
        f = font(fk('Medium'), 14.5 * k / SS)
        tw = f.getlength(lbl, **opts(lang))
        if i == 1:
            bx0, bx1 = x - 14 * k, x + tw + 14 * k
            if rtl:
                bx0, bx1 = img.width - bx1, img.width - bx0
            d.rounded_rectangle((bx0, 103 * k, bx1, 135 * k), radius=16 * k, fill=(0, 121, 107, 34))
        tx(x, 124 * k, lbl, 14.5, 'Medium', (0, 105, 92, 255))
        x += tw + 34 * k
    img.putalpha(rrect_mask(img.width, h, 26 * k))
    return img


def wfont(s, size, k, lang, bold=False):
    """Sistem fontu: Roboto; Arapça harfte Noto Naskh ('·' Naskh'ta yok: o zaman Amiri)."""
    if lang == 'ar' and any('\u0600' <= c <= '\u06ff' for c in s):
        return font('Amiri' if '·' in s else 'Naskh', size * k / SS)
    return font('Roboto' + ('Bold' if bold else 'Regular'), size * k / SS)


def wtext(d, xy, s, size, k, lang, bold=False, color=(255, 255, 255, 255), anchor='ms', max_w=None, min_size=8):
    """Widget yazısı; max_w (dp) verilirse Android'in autoSize'ı gibi sığana kadar küçülür."""
    while True:
        f = wfont(s, size, k, lang, bold)
        if not max_w or size <= min_size or f.getlength(s, **opts(lang)) <= max_w * k:
            break
        size -= 0.5
    arabic_bold = bold and lang == 'ar' and 'Roboto' not in f.path
    d.text(xy, s, font=f, fill=color, anchor=anchor, stroke_width=round(0.35 * k) if arabic_bold else 0,
           stroke_fill=color, **opts(lang))
    return f


def launcher_screen(lang, size):
    """Ana ekran: kum rengi sade arka plan + Vakit halkası, Ramazan ve Namaz takibi widget'ları
    (res/layout/vaktinde_widget_* ölçü ve renkleriyle; Ramazan'ın 11. günü, akşama 1:03:20)."""
    L = ARB[lang]
    W, H = size
    k = W / 411
    wall = Image.open(WALL.format(3)).convert('RGB')
    sc = max(W / wall.width, H / wall.height)
    wall = wall.resize((round(wall.width * sc), round(wall.height * sc)), Image.LANCZOS)
    img = wall.crop(((wall.width - W) // 2, 0, (wall.width - W) // 2 + W, H))
    d = ImageDraw.Draw(img, 'RGBA')  # RGB zemin: yarı saydam boyalar karışır
    t_aksam, clock = WIDGET_DEMO[lang]
    chrono = '1:03:20' if lang != 'ar' else arabic_digits('1:03:20')
    names = [L['sabah'], L['ogle'], L['ikindi'], L['aksam'], L['yatsi']]
    rtl = lang == 'ar'

    def styled(d, cx, y, s, size):  # PrayerWidgetData.styledTime: sondaki "PM"/"م" %80
        col = (255, 255, 255, 204)
        head, _, tail = s.rpartition(' ')
        if not head or any(c.isdigit() for c in tail):
            wtext(d, (cx, y), s, size, k, lang, color=col)
            return
        fa, fb = wfont(head, size, k, lang), wfont(tail, size * 0.8, k, lang)
        wa, wb = fa.getlength(head + ' ', **opts(lang)), fb.getlength(tail, **opts(lang))
        x0 = cx + (wa + wb) / 2 if rtl else cx - (wa + wb) / 2
        sign = -1 if rtl else 1
        d.text((x0, y), head, font=fa, fill=col, anchor='rs' if rtl else 'ls', **opts(lang))
        d.text((x0 + sign * wa, y), tail, font=fb, fill=col, anchor='rs' if rtl else 'ls', **opts(lang))

    def card(x, y, w, h):  # widget_background: #00504A %95, 22 dp köşe
        d.rounded_rectangle((x * k, y * k, (x + w) * k, (y + h) * k), radius=22 * k, fill=(0, 80, 74, 242))

    # Vakit halkası (2x2): halka iç yarıçap kenar/2,4, kalınlık kenar/14; saat 12'den saat yönünde
    gx, gy, side = 22, 250, 176
    card(gx, gy, side, side)
    rs = side - 12
    c = (gx + side / 2) * k
    cy0 = (gy + side / 2) * k
    ro = rs * (1 / 2.4 + 1 / 14) * k
    th = rs / 14 * k
    box = (c - ro, cy0 - ro, c + ro, cy0 + ro)
    d.ellipse(box, outline=(255, 255, 255, 51), width=round(th))
    d.arc(box, -90, -90 + 360 * 0.58, fill=(255, 202, 40, 255), width=round(th))
    wtext(d, (c, cy0 - 16 * k), L['aksam'], 13, k, lang, bold=True, color=(0, 229, 168, 255), max_w=rs * 0.6)
    wtext(d, (c, cy0 + 8 * k), chrono, 17, k, lang, bold=True)
    styled(d, c, cy0 + 26 * k, t_aksam, 12)
    # Ramazan (2x2)
    rx = 411 - gx - side
    card(rx, gy, side, side)
    c = (rx + side / 2) * k
    wtext(d, (c, cy0 - 38 * k), L['widgetRamadanDay'].replace('{day}', '11'), 12, k, lang, bold=True,
          color=(255, 202, 40, 255))
    wtext(d, (c, cy0 - 14 * k), L['ramadanIftarLeft'], 14, k, lang, bold=True, color=(0, 229, 168, 255))
    wtext(d, (c, cy0 + 16 * k), chrono, 22, k, lang, bold=True)
    styled(d, c, cy0 + 38 * k, L['aksam'] + ' ' + t_aksam, 12)
    # Namaz takibi (4x1)
    tw, ty = 411 - 2 * gx, gy + side + 14
    card(gx, ty, tw, 84)
    unit = (tw - 16) / 6.1
    hx = (gx + 10 if not rtl else gx + tw - 10) * k
    head_w = unit * 1.1 - 4
    wtext(d, (hx, (ty + 38) * k), L['trackerToday'], 14, k, lang, bold=True, anchor='rs' if rtl else 'ls',
          max_w=head_w, min_size=9)
    wtext(d, (hx, (ty + 58) * k), '3/5', 13, k, lang, bold=True, color=(255, 202, 40, 255),
          anchor='rs' if rtl else 'ls')
    for i, name in enumerate(names):
        cxd = 10 + unit * 1.1 + unit * (i + 0.5)
        cxp = (gx + (tw - cxd if rtl else cxd)) * k
        cy = (ty + 32) * k
        r = 12 * k
        if i < 3:
            d.ellipse((cxp - r, cy - r, cxp + r, cy + r), fill=(0, 229, 168, 255))
            d.line([(cxp - 5.2 * k, cy), (cxp - 1.4 * k, cy + 4 * k), (cxp + 5.6 * k, cy - 4.2 * k)],
                   fill=(0, 51, 47, 255), width=round(2.2 * k), joint='curve')
            col = (255, 255, 255, 255)
        else:
            d.ellipse((cxp - r, cy - r, cxp + r, cy + r), outline=(255, 255, 255, 128), width=round(1.5 * k))
            rr = 6.2 * k
            d.ellipse((cxp - rr, cy - rr, cxp + rr, cy + rr), outline=(255, 255, 255, 179), width=round(1.3 * k))
            d.line([(cxp, cy - 3.6 * k), (cxp, cy), (cxp + 2.8 * k, cy + 1.8 * k)], fill=(255, 255, 255, 179),
                   width=round(1.2 * k))
            col = (255, 255, 255, 179)
        wtext(d, (cxp, (ty + 64) * k), name, 12, k, lang, color=col)
    return status_bar(img, clock, lang)


# --- Ekran görüntüleri -------------------------------------------------------------------------
class Shots:
    def __init__(self, folder, lang):
        self.folder, self.lang = folder, lang
        p = os.path.join(folder, f'm_{lang}_clock.txt')
        self.clock = open(p).read().strip() if os.path.exists(p) else '12:30'
        if lang in ('en', 'ar'):  # 12 saat
            h, m = map(int, self.clock.split(':'))
            self.clock = f'{(h - 1) % 12 + 1}:{m:02d}'
        self._cache = {}

    def get(self, name):
        if name not in self._cache:
            if name == 'launcher':
                self._cache[name] = launcher_screen(self.lang, (1233, 2673))
            else:
                path = os.path.join(self.folder, f'm_{self.lang}_{name}.png')
                self._cache[name] = status_bar(Image.open(path), self.clock, self.lang)
        return self._cache[name]

    def phone(self, name, w):
        return Phone(self.get(name), S(w))


# --- Kompozisyonlar ------------------------------------------------------------------------------
def ornament(d, cx, y, alpha=225):
    """Altın süs: iki çizgi ve ortada sekiz köşeli yıldız."""
    col = GOLD + (alpha,)
    lw = max(1, round(S(2.0)))
    d.line((S(cx - 96), S(y), S(cx - 20), S(y)), fill=col, width=lw)
    d.line((S(cx + 20), S(y), S(cx + 96), S(y)), fill=col, width=lw)
    d.polygon([(S(a), S(b)) for a, b in mc.star_points(cx, y, 11, 0.72)], fill=col)


class Heading:
    """Süs (altın çizgi + yıldız), başlık ve alt yazı bloğu."""

    def __init__(self, lang, title, sub, max_w=900, size=76, sub_size=34, sub_lines=2, deco=True):
        self.t = Txt(title, size, lang, kind='Bold', max_w=max_w)
        self.s = Txt(sub, sub_size, lang, kind='Regular', color=CREAM, lh=1.34, max_w=max_w * 0.96,
                     max_lines=sub_lines) if sub else None
        self.deco = deco
        self.gap = size * 0.3
        self.height = (40 if deco else 0) + self.t.height + (self.gap + self.s.height if sub else 0)

    def draw(self, d, cx, y, align='center', alpha=255):
        if self.deco:
            ox = 0 if align == 'center' else (-96 if self.t.ar else 96)
            ornament(d, cx + ox, y + 8, alpha=round(225 * alpha / 255))
            y += 40
        self.t.draw(d, cx, y, align, alpha)
        if self.s:
            self.s.draw(d, cx, y + self.t.height + self.gap, align, round(alpha * 0.92))


def finalize(canvas, size):
    return canvas.resize(size, Image.LANCZOS)


def play_backdrop():
    W, H = 8 * 1080, 1920
    glows = [(i * 1080 + 540, 1180, 640, GLOW, 0.36) for i in range(8)]
    glows += [(i * 1080, 80, 520, SAND, 0.10) for i in range(9)]
    stars = [(i * 1080, (420, 1520)[i % 2], (240, 300)[i % 2]) for i in range(9)]
    return Backdrop(W, H, glows, stars, ribbon=wave(1530, 150, 2160, 0.9))


def play_screen(lang, idx, shots, bd):
    rtl = lang == 'ar'
    W, H = 1080, 1920
    # Arapça mağaza sağdan sola dizer: zemin parçası aynalanır ki komşular yine birleşsin
    canvas = bd.render(idx * 1080, 0, W, H)
    if rtl:
        canvas = canvas.transpose(Image.FLIP_LEFT_RIGHT)
    d = ImageDraw.Draw(canvas, 'RGBA')
    hd = Heading(lang, *PLAY_TEXT[lang][idx])
    top = 530  # telefonun üstü: bütün dizide aynı; yazı bloğu üstteki alanda ortalanır
    y = 50 + (top - 70 - 50 - hd.height) / 2
    hd.draw(d, 540, y)
    front, back, extra = PLAY_SHOTS[idx]

    def mx(x):
        return W - x if rtl else x

    if back:
        shots.phone(back, 590).place(canvas, S(mx(336)), S(top))
        shots.phone(front, 660).place(canvas, S(mx(708)), S(top + 96), shade=0.7)
    elif extra == 'notif':
        # Bildirim, ekranın üst çubuklarını (durum, başlık, sekmeler: 28+56+48 dp ve altı) örter
        ph = shots.phone(front, 740)
        ph.place(canvas, S(540), S(top + 40))
        card = notif_card(lang, S(740 * 1.02))
        bars = S(top + 40) + ph.screen_box[1] + 145 * ph.screen_box[2] / 411
        cy = round(bars - card.height + S(4))
        shadow(canvas, card.getchannel('A'), S(540) - card.width // 2, cy, S(26), S(18), 0.55)
        canvas.paste(card, (S(540) - card.width // 2, cy), card)
    else:
        shots.phone(front, 740).place(canvas, S(540), S(top))
    return {'y': round(y), 'h': round(hd.height), 'title_lines': len(hd.t.lines),
            'sub_lines': len(hd.s.lines)}, canvas


def feature_graphic(lang, shots):
    W, H = 1024, 500
    bd = Backdrop(W, H, [(760, 300, 330, GLOW, 0.42), (120, 0, 360, SAND, 0.10)],
                  [(1024, 70, 150), (0, 500, 170)], ribbon=wave(462, 18, 1100, 2.2), lattice=(60, 52, 8))
    canvas = bd.render(0, 0, W, H)
    rtl = lang == 'ar'
    if rtl:
        canvas = canvas.transpose(Image.FLIP_LEFT_RIGHT)
    d = ImageDraw.Draw(canvas, 'RGBA')

    def mx(x):
        return W - x if rtl else x

    # telefonlar (sağda; Arapçada solda): ana ekran önde, Kur'an sayfası arkada
    shots.phone('15_quran_page', 220).place(canvas, S(mx(838)), S(92))
    shots.phone('01_home', 240).place(canvas, S(mx(688)), S(58), shade=0.7)
    # marka: logo + ad, slogan, özellik kapsülleri (blok dikeyde ortalı)
    x0, lg = 64, 84
    name = Txt('Vaktinde', 60, 'tr', kind='Bold', max_w=400, max_lines=1)
    tag, chips = FG_TEXT[lang]
    t = Txt(tag, 33, lang, kind='SemiBold', color=WHITE, lh=1.25, max_w=470, max_lines=2)
    widths = [chip(d, 0, 0, c, lang, 19, measure=True) for c in chips]
    while sum(widths) + 10 * (len(widths) - 1) > 520:
        widths.pop()
    y0 = (H - (lg + 38 + t.height + 30 + 40)) / 2
    logo = mc.logo_img(lg)
    canvas.paste(logo, (round(S(mx(x0) - (lg if rtl else 0))), round(S(y0))), logo)
    name.draw(d, mx(x0 + lg + 22), line_top(name, y0 + lg / 2), 'end' if rtl else 'start')
    ty = y0 + lg + 38
    t.draw(d, mx(x0), ty, 'start')
    x, cy = x0, ty + t.height + 30 + 20
    for c, w in zip(chips, widths):
        chip(d, mx(x + w / 2), cy, c, lang, 19)
        x += w + 10
    assert t.width <= 470, lang
    return finalize(canvas, (W, H))


def build_play(args):
    lang, shot_dir, out = args
    shots = Shots(shot_dir, lang)
    folder = os.path.join(out, 'play', lang)
    os.makedirs(folder, exist_ok=True)
    bd = play_backdrop()
    info = []
    for i in range(8):
        meta, canvas = play_screen(lang, i, shots, bd)
        finalize(canvas, (1080, 1920)).save(os.path.join(folder, f'{i + 1:02d}_{PLAY_NAMES[i]}.png'), optimize=True)
        info.append(meta)
    feature_graphic(lang, shots).save(os.path.join(folder, 'feature_graphic.png'), optimize=True)
    return lang, info


# --- Instagram (Türkçe) ------------------------------------------------------------------------
def brand_block(canvas, cx, y, logo=200, name=104, tag="Namaz vakti, Kur'an ve kıble\ntek uygulamada",
                tag_size=42):
    """Logo, ad ve slogan (ortalı); bloğun yüksekliğini döndürür."""
    d = ImageDraw.Draw(canvas, 'RGBA')
    lg = mc.logo_img(logo)
    canvas.paste(lg, (round(S(cx - logo / 2)), round(S(y))), lg)
    n = Txt('Vaktinde', name, 'tr', kind='Bold', max_w=900, max_lines=1)
    ny = y + logo + name * 0.32
    n.draw(d, cx, ny)
    ornament(d, cx, ny + n.height + 34)
    t = Txt(tag, tag_size, 'tr', kind='Regular', color=CREAM, lh=1.32, max_w=900)
    t.draw(d, cx, ny + n.height + 68)
    return ny + n.height + 68 + t.height - y


def ig_backdrop(n, w, h, ribbon_y):
    W = n * w
    glows = [(i * w + w / 2, h * 0.62, w * 0.55, GLOW, 0.36) for i in range(n)]
    glows += [(i * w, 0, w * 0.5, SAND, 0.10) for i in range(n + 1)]
    stars = [(i * w, (h * 0.2, h * 0.86)[i % 2], (250, 300)[i % 2]) for i in range(n + 1)]
    return Backdrop(W, h, glows, stars, ribbon=wave(ribbon_y, h * 0.06, W / 1.6, 0.4))


def save_slices(bd, n, w, h, draw, folder, names):
    """Panoramayı parça parça çizer; draw(canvas, ox) parça koordinatıyla öğeleri yerleştirir."""
    os.makedirs(folder, exist_ok=True)
    for i in range(n):
        canvas = bd.render(i * w, 0, w, h)
        draw(canvas, i * w)
        finalize(canvas, (w, h)).save(os.path.join(folder, names[i]), optimize=True)


def phone_panel(canvas, shots, x, title, sub, shot, top=470):
    """Üçlü ızgara paneli: başlık bloğu üstte ortalı, telefon alttan taşar."""
    hd = Heading('tr', title, sub, size=70)
    hd.draw(ImageDraw.Draw(canvas, 'RGBA'), x, 60 + (top - 60 - 50 - hd.height) / 2)
    shots.phone(shot, 600).place(canvas, S(x), S(top))


def build_triptychs(shots, out):
    for name, panels in IG_TRIPTYCHS:
        bd = ig_backdrop(3, 1080, 1440, 1140)

        def draw(canvas, ox, panels=panels):
            for i, p in enumerate(panels):
                x = i * 1080 + 540 - ox
                if p is None:  # marka paneli: blok dikeyde ortalı (önce boş tuvalde ölçülür)
                    hgt = brand_block(Image.new('RGB', (8, 8)), 540, 0, logo=220, name=116)
                    brand_block(canvas, x, (1440 - hgt) / 2 - 90, logo=220, name=116)
                    brand_pill(canvas, x, 1262, "Google Play'de Vaktinde")
                else:
                    phone_panel(canvas, shots, x, *p)

        save_slices(bd, 3, 1080, 1440, draw, os.path.join(out, 'instagram', name),
                    ['1_sol.png', '2_orta.png', '3_sag.png'])


def bullets(d, x, y, items, size=33, gap=70):
    for i, s in enumerate(items):
        cy = y + i * gap
        d.polygon([(S(a), S(b)) for a, b in mc.star_points(x + 12, cy, 13, 0.72)], fill=GOLD + (235,))
        t = Txt(s, size, 'tr', kind='Medium', color=CREAM, max_w=900, max_lines=1)
        t.draw(d, x + 42, line_top(t, cy), 'start')


def build_carousel(shots, out):
    W, H, n = 1080, 1350, 5
    bd = ig_backdrop(n, W, H, 1180)

    def draw(canvas, ox):
        d = ImageDraw.Draw(canvas, 'RGBA')

        def L(x):  # panorama → bu parça
            return x - ox

        # 1: giriş; 1→2 sınırında duran telefon kaydırmaya çağırır
        t = Txt("Namaz vakti,|Kur'an ve kıble|tek uygulamada", 80, 'tr', max_w=640, max_lines=3)
        s = Txt('Vakitler internetsiz hesaplanır', 34, 'tr', kind='Regular', color=CREAM, max_w=640)
        ornament(d, L(90 + 96), 330)
        t.draw(d, L(90), 372, 'start')
        s.draw(d, L(90), 372 + t.height + 26, 'start', 235)
        w = chip(d, L(90 + 115), 1150, 'Kaydırın      ', 'tr', 26, color=WHITE)
        ax = L(90 + 115) + w / 2 - 52  # ok (Poppins'te → yok)
        d.line([(S(ax), S(1150)), (S(ax + 26), S(1150))], fill=WHITE + (255,), width=round(S(2.6)))
        d.line([(S(ax + 16), S(1140)), (S(ax + 27), S(1150)), (S(ax + 16), S(1160))], fill=WHITE + (255,),
               width=round(S(2.6)), joint='curve')
        shots.phone('01_home', 560).place(canvas, S(L(W + 40)), S(330))
        # 2: ezan bildirimi
        Heading('tr', 'Ezan vakti yaklaşınca', 'Her vakte ayrı ezan ya da bildirim sesi',
                size=68).draw(d, L(W + 540), 90)
        card = notif_card('tr', S(620))
        cx, cy = S(L(W + 690)), S(470)
        shadow(canvas, card.getchannel('A'), cx - card.width // 2, cy, S(24), S(16), 0.55)
        canvas.paste(card, (cx - card.width // 2, cy), card)
        bullets(d, L(W + 400), 860, ['Bildirimde “Durdur”', 'Vakitten önce uyarı', 'Sessiz modda da çalar',
                                     '“Kıldım” ile takip'])
        # 3: Kur'an ve hatim; 4: takip, kıble
        for i, (title, sub, back, front) in enumerate([
                ("Kur'an-ı Kerim ve hatim", 'Mushaf sayfası, ayet ayet ya da meal; günlük hedef',
                 '03_quran_tab', '15_quran_page'),
                ('Takip ve kıble', 'Seri hedefleri, kaza sayacı ve kıble pusulası',
                 '04_qibla', '07_tracker')]):
            x0 = (2 + i) * W
            Heading('tr', title, sub, size=66).draw(d, L(x0 + 540), 80)
            shots.phone(back, 500).place(canvas, S(L(x0 + 330)), S(400))
            shots.phone(front, 540).place(canvas, S(L(x0 + 712)), S(470), shade=0.7)
        # 5: çağrı (marka, metin kapsülü, diğer özellikler)
        x = L(4 * W + 540)
        hgt = brand_block(Image.new('RGB', (8, 8)), 540, 0, logo=170, name=96)
        y0 = (H - (hgt + 230 + 76 + 30)) / 2 - 20
        brand_block(canvas, x, y0, logo=170, name=96)
        brand_pill(canvas, x, y0 + hgt + 90, "Google Play'de Vaktinde")
        for r, row in enumerate([['İmsakiye', 'Namaz Hocası', 'Dualar'], ["Widget'lar", 'Yazı boyutu', '5 dil']]):
            ws = [chip(d, 0, 0, c, 'tr', 24, measure=True) for c in row]
            cx = x - (sum(ws) + 14 * (len(ws) - 1)) / 2
            for c, w in zip(row, ws):
                chip(d, cx + w / 2, y0 + hgt + 230 + r * 76, c, 'tr', 24)
                cx += w + 14

    save_slices(bd, n, W, H, draw, os.path.join(out, 'instagram', 'karusel'), [f'{i + 1}.png' for i in range(n)])


def build_stories(shots, out):
    W, H = 1080, 1920
    folder = os.path.join(out, 'instagram', 'hikaye')
    os.makedirs(folder, exist_ok=True)
    specs = [
        ('Ezan vakti yaklaşınca', 'Vakitler internetsiz hesaplanır; ezanı bildirimdeki “Durdur” ile susturursunuz',
         ('01_home', None)),
        ("Kur'an'ı sayfa sayfa okuyun", 'Hatim hedefinizi koyun, okudukça sayfalar sayılsın',
         ('15_quran_page', '03_quran_tab')),
        ('Yeni: sade arka planlar', 'Yazı boyutunu da uygulamanın içinden ayarlayın',
         ('16_home_plain', '14_appearance')),
    ]
    bd = Backdrop(W, H, [(540, 1150, 620, GLOW, 0.38), (0, 0, 520, SAND, 0.10), (1080, 0, 520, SAND, 0.08)],
                  [(1080, 330, 250), (0, 1560, 300)], ribbon=wave(1460, 120, 2200, 1.2))
    for i, (title, sub, (front, back)) in enumerate(specs):
        canvas = bd.render(0, 0, W, H)
        d = ImageDraw.Draw(canvas, 'RGBA')
        hd = Heading('tr', title, sub, max_w=900, size=72, sub_size=36)
        hd.draw(d, 540, 270)
        top = 270 + hd.height + 90
        if back:
            shots.phone(back, 560).place(canvas, S(330), S(top))
            shots.phone(front, 620).place(canvas, S(712), S(top + 90), shade=0.7)
        else:
            ph = shots.phone(front, 700)
            ph.place(canvas, S(540), S(top + 150))
            card = notif_card('tr', S(700))
            cy = round(S(top))
            shadow(canvas, card.getchannel('A'), S(540) - card.width // 2, cy, S(24), S(16), 0.55)
            canvas.paste(card, (S(540) - card.width // 2, cy), card)
        if i == 2:
            brand_pill(canvas, 540, 1480, "Google Play'de Vaktinde")
        finalize(canvas, (W, H)).save(os.path.join(folder, f'{i + 1}.png'), optimize=True)


def build_instagram(args):
    shot_dir, out = args
    shots = Shots(shot_dir, 'tr')
    build_triptychs(shots, out)
    build_carousel(shots, out)
    build_stories(shots, out)
    return 'instagram', None


# --- Video (sessiz; VIDEO_TEXT dilleri) ----------------------------------------------------------
def ease(t):
    t = min(1.0, max(0.0, t))
    return 1 - (1 - t) ** 3


def ramp(t, a, b):
    """a→b arasında 0→1 (yumuşak)."""
    return ease((t - a) / (b - a)) if b > a else float(t >= a)


def to1x(img):
    return img.resize((max(1, round(img.width / SS)), max(1, round(img.height / SS))), Image.LANCZOS)


def layer(w, h, paint, color=WHITE):
    """Saydam katman (1x): RGB yazı rengiyle dolu, böylece kenar yumuşatması koyulaşmaz."""
    img = Image.new('RGBA', (round(S(w)), round(S(h))), color + (0,))
    paint(img, ImageDraw.Draw(img, 'RGBA'))
    return to1x(img)


def faded(img, a):
    if a >= 1:
        return img.getchannel('A')
    return img.getchannel('A').point(lambda v: round(v * a))


def shadow_layer(mask, blur, opacity):
    pad = int(blur * 2.5)
    m = Image.new('L', (mask.width + 2 * pad, mask.height + 2 * pad), 0)
    m.paste(mask, (pad, pad))
    m = m.filter(ImageFilter.GaussianBlur(blur)).point(lambda v: round(v * opacity))
    img = Image.new('RGBA', m.size, (0, 22, 20, 0))
    img.putalpha(m)
    return img, pad


VIDEO_FRAMES_PREVIEW = [1.0, 3.6, 6.8, 8.6, 10.0, 11.8, 13.8, 15.4, 18.4]


def build_video(args):
    shot_dir, out, orient, lang = args
    vert = orient == 'dikey'
    W, H = (1080, 1920) if vert else (1920, 1080)
    shots = Shots(shot_dir, lang)
    captions, pill_text, more_text = VIDEO_TEXT[lang]
    if vert:
        bd = Backdrop(W, H, [(540, 1250, 640, GLOW, 0.38), (0, 0, 520, SAND, 0.10), (1080, 0, 520, SAND, 0.08)],
                      [(1080, 300, 260), (0, 1620, 300)], ribbon=wave(1500, 110, 2200, 1.2))
        pw, pcx, ptop = 640, 540, 650
        cap_x, cap_align, cap_w, cap_size = 540, 'center', 920, 70
    else:
        bd = Backdrop(W, H, [(1400, 620, 560, GLOW, 0.40), (200, 0, 520, SAND, 0.10)],
                      [(0, 1000, 260), (1920, 120, 220)], ribbon=wave(900, 60, 2400, 0.3))
        pw, pcx, ptop = 440, 1400, 72
        cap_x, cap_align, cap_w, cap_size = 190, 'start', 760, 78
    bg = to1x(bd.render(0, 0, W, H))

    # Telefonlar (aynı çerçeve, farklı ekran) + gölge
    # ekran sırası başlıklardan: bir başlıkta birden çok ekran varsa süre eşit bölünür
    schedule = [(a + j * (b - a) / len(sc_), n) for a, b, sc_ in VIDEO_SCENES for j, n in enumerate(sc_)]
    phones = {}
    for _, n in schedule:
        ph = shots.phone(n, pw)
        phones[n] = to1x(ph.img)
    ph_pad = round(ph.pad / SS)
    sh, sh_pad = shadow_layer(to1x(ph.mask), pw * 0.045, 0.55)
    bars = (ph.screen_box[1] + 145 * ph.screen_box[2] / 411) / SS  # telefon üstünden sekmelerin altına
    card = to1x(notif_card(lang, S(pw * 1.02)))
    csh, csh_pad = shadow_layer(card.getchannel('A'), 18, 0.5)

    # Başlıklar
    caps = []
    for (a, b, _), (title, sub) in zip(VIDEO_SCENES, captions):
        hd = Heading(lang, title, sub, max_w=cap_w, size=cap_size, sub_size=36)
        lw = cap_w + 200
        lay = layer(lw, hd.height + 40, lambda im, d, hd=hd: hd.draw(
            d, lw / 2 if cap_align == 'center' else 0, 10, cap_align))
        cy = 445 if vert else 540
        caps.append((a, b, lay, (cap_x - lw / 2 if cap_align == 'center' else cap_x), cy - hd.height / 2 - 10))

    # Giriş ve kapanış: logo, ad, slogan (+ kapanışta metin kapsülü ve özellikler)
    sc = 1.0 if vert else 0.82
    logo = to1x(mc.logo_img(round(220 * sc)))
    n = Txt('Vaktinde', 110 * sc, lang, kind='Bold', max_w=1000, max_lines=1)
    name = layer(n.width + 40, n.height + 30, lambda im, d: n.draw(d, (n.width + 40) / 2, 10))
    t = Txt(FG_TEXT[lang][0].replace('|', '\n'), 44 * sc, lang, kind='Regular', color=CREAM, lh=1.32, max_w=900)
    tag = layer(960, t.height + 80, lambda im, d: (ornament(d, 480, 12), t.draw(d, 480, 50)), color=CREAM)
    by = 560 if vert else 120  # logonun üstü
    ny = by + logo.height + 30 * sc
    ty = ny + name.height + 10 * sc
    # kapanış kapsülü: durağan zemine çizilir, zeminle karıştırılarak belirir
    pill_y = ty + tag.height + (90 if vert else 64)
    full = bd.render(0, 0, W, H)
    brand_pill(full, W / 2, pill_y, pill_text, size=34)
    pill_box = (W // 2 - 420, round(pill_y) - 52, W // 2 + 420, round(pill_y) + 96)
    pill_on, pill_off = to1x(full).crop(pill_box), bg.crop(pill_box)
    more = Txt(more_text, 30, lang, kind='Medium', color=CREAM, max_w=1000)
    more_lay = layer(more.width + 40, more.height + 30, lambda im, d: more.draw(d, (more.width + 40) / 2, 10),
                     color=CREAM)

    path = os.path.join(out, 'video', lang, f'tanitim_{orient}.mp4')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    cmd = [mc.FFMPEG, '-y', '-loglevel', 'error', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}',
           '-r', str(FPS), '-i', '-', '-an', '-vf', 'scale=out_color_matrix=bt709:out_range=tv,format=yuv420p',
           '-c:v', 'libx264', '-preset', 'slow', '-crf', '19', '-profile:v', 'high', '-level', '4.2',
           '-pix_fmt', 'yuv420p', '-r', str(FPS), '-color_primaries', 'bt709', '-color_trc', 'bt709',
           '-colorspace', 'bt709', '-movflags', '+faststart', path]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    previews = {}
    total = round(VIDEO_SECONDS * FPS)
    for i in range(total):
        t = i / FPS
        f = bg.copy()

        def put(img, x, y, a, mask=None):
            if a > 0.004:
                f.paste(img, (round(x), round(y)), faded(img, a) if mask is None else mask)

        # giriş (0–2,3 sn)
        if t < 2.4:
            out_a = 1 - ramp(t, 1.75, 2.3)
            up = -40 * ramp(t, 1.75, 2.3)
            a = ramp(t, 0.0, 0.8) * out_a
            s_ = 0.9 + 0.1 * ramp(t, 0.0, 0.8)
            lg = logo.resize((round(logo.width * s_), round(logo.height * s_)), Image.LANCZOS) if s_ < 0.999 else logo
            put(lg, W / 2 - lg.width / 2, by + (logo.height - lg.height) / 2 + up, a)
            put(name, W / 2 - name.width / 2, ny + 20 * (1 - ramp(t, 0.25, 0.95)) + up, ramp(t, 0.25, 0.95) * out_a)
            put(tag, W / 2 - tag.width / 2, ty + 20 * (1 - ramp(t, 0.5, 1.2)) + up, ramp(t, 0.5, 1.2) * out_a)
        # telefon (2,0–16,9 sn)
        if 2.0 <= t < 17.0:
            enter = ramp(t, 2.0, 2.9)
            leave = ease((t - 16.2) / 0.7) if t > 16.2 else 0
            y = ptop + (H + 60 - ptop) * (1 - enter) + (H + 60 - ptop) * leave * leave
            y += 6 * math.sin(2 * math.pi * (t - 2.0) / 5.0)
            cur = [n for s0, n in schedule if s0 <= t + 0.2] or ['01_home']
            prev = [n for s0, n in schedule if s0 <= t - 0.2] or cur
            img = phones[cur[-1]]
            if cur[-1] != prev[-1]:
                s0 = next(s for s, n in schedule if n == cur[-1])
                img = Image.blend(phones[prev[-1]], phones[cur[-1]], ramp(t, s0 - 0.2, s0 + 0.2))
            f.paste(sh, (round(pcx - pw / 2 - sh_pad), round(y - sh_pad + pw * 0.04)), sh)
            f.paste(img, (round(pcx - pw / 2 - ph_pad), round(y)), img)
            # bildirim (5,5–7,8 sn)
            if 5.45 <= t < 7.85:
                a = ramp(t, 5.45, 5.9) * (1 - ramp(t, 7.55, 7.85))
                cy = y + bars - card.height + 4 - 90 * (1 - ramp(t, 5.45, 5.95))
                cx = pcx - card.width / 2
                put(csh, cx - csh_pad, cy - csh_pad + 12, a)
                put(card, cx, cy, a)
        # başlıklar
        for a0, b0, lay, x, y in caps:
            if a0 <= t < b0:
                a = ramp(t, a0 + 0.05, a0 + 0.45) * (1 - ramp(t, b0 - 0.3, b0 - 0.02))
                put(lay, x, y + 22 * (1 - ramp(t, a0 + 0.05, a0 + 0.5)), a)
        # kapanış (16,4 sn →)
        if t >= 16.4:
            put(logo, W / 2 - logo.width / 2, by + 24 * (1 - ramp(t, 16.4, 17.0)), ramp(t, 16.4, 17.0))
            put(name, W / 2 - name.width / 2, ny + 20 * (1 - ramp(t, 16.6, 17.2)), ramp(t, 16.6, 17.2))
            put(tag, W / 2 - tag.width / 2, ty + 20 * (1 - ramp(t, 16.8, 17.4)), ramp(t, 16.8, 17.4))
            a = ramp(t, 17.2, 17.8)
            if a > 0:
                f.paste(Image.blend(pill_off, pill_on, a), pill_box[:2])
            put(more_lay, W / 2 - more_lay.width / 2, pill_y + 92, ramp(t, 17.6, 18.2))
        proc.stdin.write(f.tobytes())
        for pt in VIDEO_FRAMES_PREVIEW:
            if i == round(pt * FPS):
                previews[pt] = f.copy()
    proc.stdin.close()
    if proc.wait() != 0:
        raise RuntimeError('ffmpeg hata verdi: ' + path)
    return (lang, orient), previews



# --- Önizleme, README, zip -----------------------------------------------------------------------
def _thumb(path, w):
    im = Image.open(path).convert('RGB')
    return im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)


def sheet(rows, path, gap=8, bgc=(234, 239, 238)):
    """rows: [(etiket, [resim, ...], aralık)] → tek JPG."""
    f = ImageFont.truetype(mc.POPPINS.format('Medium'), 22, layout_engine=ImageFont.Layout.RAQM)
    lab = max(84, max(round(f.getlength(label)) + 16 for label, _, _ in rows))
    W = max(lab + sum(i.width for i in ims) + g * (len(ims) - 1) for _, ims, g in rows) + 2 * gap
    H = sum(max(i.height for i in ims) for _, ims, _ in rows) + gap * (len(rows) + 1)
    out = Image.new('RGB', (W, H), bgc)
    d = ImageDraw.Draw(out)
    y = gap
    for label, ims, g in rows:
        h = max(i.height for i in ims)
        d.text((gap + 4, y + h / 2), label, font=f, fill=(30, 50, 48), anchor='lm')
        x = gap + lab
        for im in ims:
            out.paste(im, (x, y + (h - im.height) // 2))
            x += im.width + g
        y += h + gap
    out.save(path, quality=86)


def previews(out, langs, video_frames):
    play = []
    for l in langs:
        folder = os.path.join(out, 'play', l)
        if not os.path.isdir(folder):
            continue
        ims = [_thumb(os.path.join(folder, n), 200) for n in sorted(os.listdir(folder)) if n[:2].isdigit()]
        if l == 'ar':  # mağazadaki gibi sağdan sola
            ims.reverse()
        play.append((l, ims + [_thumb(os.path.join(folder, 'feature_graphic.png'), 420)], 2))
    if play:
        sheet(play, os.path.join(out, '_onizleme_play.jpg'))
    ig = os.path.join(out, 'instagram')
    if os.path.isdir(ig):
        rows = []
        for name in ('triptik_1', 'triptik_2', 'karusel', 'hikaye'):
            folder = os.path.join(ig, name)
            w = 200 if name == 'hikaye' else 230
            ims = [_thumb(os.path.join(folder, n), w) for n in sorted(os.listdir(folder))]
            rows.append((name.replace('triptik_', 'trip ')[:7], ims, 14 if name == 'hikaye' else 3))
        sheet(rows, os.path.join(out, '_onizleme_instagram.jpg'))
    if video_frames:
        rows = []
        for (lang, orient), frames in sorted(video_frames.items(), key=lambda kv: (VIDEO_LANGS.index(kv[0][0]), kv[0][1])):
            w = 150 if orient == 'dikey' else 300
            ims = [frames[k].resize((w, round(frames[k].height * w / frames[k].width)), Image.LANCZOS)
                   for k in sorted(frames)]
            label = f'{lang} {orient}'
            rows += [(label, ims, 6)] if orient == 'dikey' else [(label, ims[:5], 6), ('', ims[5:], 6)]
        sheet(rows, os.path.join(out, '_onizleme_video.jpg'))


PLAY_URL = 'https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde'
README = """# Vaktinde 1.3.0 tanıtım paketi

Play Store görselleri (5 dil), Instagram gönderileri (Türkçe) ve sessiz tanıtım videoları (Türkçe, İngilizce).
Hepsi uygulamanın gerçek ekranlarından üretildi; çerçeve, durum çubuğu, ezan bildirimi ve ana ekran
widget'ları uygulamanın kendi metin ve renkleriyle çizildi. Yeniden üretmek için:
`python3 docs/marketing/make_store_assets.py <ekran_klasörü> <çıkış_klasörü>` (ayrıntı betiğin başında).

Ön izlemeler: `_onizleme_play.jpg`, `_onizleme_instagram.jpg`, `_onizleme_video.jpg`.

## 1. Google Play (`play/<dil>/`)

Play Console > Büyüme > Mağazada varlık > Ana mağaza girişi; her dilin çevirisinde aynı adlı klasör
(tr-TR = `tr`, en-US = `en`, de-DE = `de`, fr-FR = `fr`, ar = `ar`).

| Dosya | Nereye |
|---|---|
| `01_vakitler.png` … `08_widget.png` | Telefon ekran görüntüleri, **bu sırayla** (1080×1920). İlk ikisi temel değer: vakitler/ezan ve Kur'an/hatim |
| `feature_graphic.png` | Öne çıkan grafik (1024×500) |
| `video/<dil>/tanitim_yatay.mp4` | Önce YouTube'a yükleyin, bağlantıyı "Video" alanına yapıştırın (3. bölüm): tr-TR'ye Türkçe, diğer dillere İngilizce video |

- Zemin sekiz görsel boyunca kesintisiz akar (mağazada yan yana bakınca birleşir). Arapça mağaza
  sağdan sola dizdiği için `ar` setinde zemin aynalandı; yükleme sırası yine 01 → 08.
- Şehirler: tr İstanbul/Kadıköy, en London, de Köln, fr Paris, ar İstanbul/Fatih (vakitler o şehrin
  saat dilimiyle hesaplandı). 8. görseldeki widget'lar Ramazan'ın 11. günü örneğidir.
- Play kurallarına uygun: sıralama, ödül, "en iyi", "ücretsiz", fiyat ya da Google Play rozeti yok.

## 2. Instagram (`instagram/`, Türkçe)

### Üçlü ızgara (`triptik_1`, `triptik_2`; 1080×1440, 3:4)
Üç gönderi profil ızgarasında tek resim gibi görünür, her biri tek başına da okunur.
**Paylaşım sırası sağdan sola:** önce `3_sag.png`, sonra `2_orta.png`, en son `1_sol.png`
(ızgarada en yeni gönderi solda durur). Üçünü arka arkaya, araya başka gönderi koymadan paylaşın;
sonraki gönderileri de üçer üçer paylaşırsanız sıra bozulmaz. İki üçlüyü de paylaşacaksanız önce
`triptik_2`, sonra `triptik_1` (marka tanıtımı üst satırda kalsın).

| Gönderi | Açıklama önerisi |
|---|---|
| triptik_1 / 3_sag | Kur'an-ı Kerim'i mushaf sayfasıyla okuyun, hatim hedefinizi koyun; okudukça sayfalar sayılır. #kuran #hatim #kuranıkerim #vaktinde |
| triptik_1 / 2_orta | Vaktinde: namaz vakti, Kur'an ve kıble tek uygulamada. Google Play'de "Vaktinde" aratın, bağlantı profilde. #vaktinde #namazvakti #ezanvakti |
| triptik_1 / 1_sol | Ezan vakti cebinizde: vakitler Diyanet yöntemiyle telefonunuzda, internetsiz hesaplanır. #ezanvakti #namazvakti #vaktinde |
| triptik_2 / 3_sag | Zikirmatik: hedefinizi seçin, ekrana dokunun, sayın. Günlük sayınız da kaydedilir. #zikirmatik #zikir #tesbih #vaktinde |
| triptik_2 / 2_orta | Namaz takibi: kıldığınız vakitleri işaretleyin, 7 ve 40 günlük seri hedeflerine ulaşın, kazalarınızı sayın. #namaztakibi #kazanamazı #namaz #vaktinde |
| triptik_2 / 1_sol | Kıble pusulası: bulunduğunuz yerden Kâbe yönü, manyetik sapma düzeltmesiyle. #kıble #kıblepusulası #namaz #vaktinde |

### Kaydırmalı gönderi (`karusel/1.png` … `5.png`; 1080×1350, 4:5)
Tek gönderide 1 → 5 sırasıyla. Görseller kenarlardan birbirine akar; 1. ile 2. arasındaki telefon
kaydırmaya çağırır.

```
Namaz vakti, ezan bildirimi, Kur'an ve hatim, namaz takibi, kıble ve zikirmatik tek uygulamada.
Vaktinde 1.3.0 ile ezanı bildirimdeki "Durdur"la tek dokunuşla susturabilir, Kur'an'ı mushaf sayfasıyla okuyabilirsiniz.
Google Play'de "Vaktinde" aratın, bağlantı profilde.

#vaktinde #namazvakti #ezanvakti #kuran #hatim #kıble #zikirmatik #namaz
```

### Hikâyeler (`hikaye/1.png` … `3.png`; 1080×1920)
Yazılar üst 250 ve alt 350 pikselin dışında. Her birine bağlantı çıkartması ekleyin:
`{url}&referrer=utm_source%3Dinstagram%26utm_medium%3Dstory`
1. Ezan vakti ve "Durdur" · 2. Kur'an ve hatim · 3. Yeni sade arka planlar ve yazı boyutu.

Facebook için aynı görseller ve metinler kullanılabilir (Meta Business Suite'ten ikisine birlikte).

## 3. Video (`video/tr/`, `video/en/`; sessiz)

İki dilde aynı akış: `tr` Türkçe, `en` İngilizce başlıklar ve uygulamanın İngilizce ekranları (London).
Müzik yok: her uygulamanın kendi kütüphanesinden ekleyin (Instagram/Facebook "Ses", TikTok "Ses ekle",
YouTube "Ses"). Dikey videoda önemli yazılar üst 250 / alt 350 pikselin dışında.

| Dosya | Nereye |
|---|---|
| `<dil>/tanitim_dikey.mp4` (1080×1920, 19 sn) | Instagram/Facebook Reels, TikTok, YouTube Shorts. Kapak: kapanış karesi (18. sn) |
| `<dil>/tanitim_yatay.mp4` (1920×1080, 19 sn) | YouTube (herkese açık ya da liste dışı, gömmeye açık, reklamsız) → bağlantısı Play Console "Video" alanına: tr-TR'de Türkçe, en-US/de-DE/fr-FR/ar'da İngilizce |

**Reels / Facebook**
```
Ezan vakti, Kur'an ve hatim, namaz takibi, kıble ve zikirmatik: hepsi Vaktinde'de.
Google Play'de "Vaktinde" aratın, bağlantı profilde.
#vaktinde #namazvakti #ezanvakti #kuran #kıble #zikirmatik
```

**TikTok**
```
Namaz vakti, ezan, Kur'an ve kıble tek uygulamada. Play Store'da "Vaktinde" aratın.
#vaktinde #namazvakti #ezan #kuran #keşfet
```

**YouTube Shorts** başlık: `Vaktinde: ezan vakti, Kur'an ve kıble tek uygulamada #Shorts`
```
Namaz vakitleri Diyanet yöntemiyle, internetsiz; ezanı bildirimden tek dokunuşla durdurun.
Kur'an-ı Kerim ve hatim takibi, namaz takibi, kıble pusulası, zikirmatik ve daha fazlası.
{url}&referrer=utm_source%3Dyoutube%26utm_medium%3Dshorts
```

**YouTube (yatay, Play tanıtım videosu)** başlık: `Vaktinde 1.3.0: Ezan Vakti, Kur'an ve Kıble`

**İngilizce (`en/`)** YouTube başlığı: `Vaktinde: Prayer Times, Quran and Qibla in One App`
```
Prayer times calculated offline with the Diyanet method; silence the adhan with one tap on "Stop".
Read the Quran by mushaf page and track your Khatm, keep track of your prayers, find the Qibla and count your dhikr.
{url}&referrer=utm_source%3Dyoutube%26utm_medium%3Dvideo
```
Reels / TikTok: `Prayer times, adhan, Quran and Qibla in one app. Search "Vaktinde" on Google Play.
#prayertimes #adhan #quran #qibla #muslimapp #vaktinde`

## 4. Zip paketleri
Her paket 24 MB'tan küçük ve içinde bu README de var: `play_<diller>.zip`, `instagram.zip`, `video.zip`.
"""


def write_readme(out):
    with open(os.path.join(out, 'README.md'), 'w', encoding='utf-8') as fh:
        fh.write(README.replace('{url}', PLAY_URL))


def make_zips(out, langs, limit=24 * 1024 * 1024):
    """play_<diller>.zip (sınırı aşmayan dil grupları), instagram.zip, video.zip."""
    def files(folder):
        base = os.path.join(out, folder)
        return sorted(os.path.join(dp, n) for dp, _, ns in os.walk(base) for n in ns) if os.path.isdir(base) else []

    groups, size = [], 0
    for l in langs:
        s_ = sum(os.path.getsize(f) for f in files(os.path.join('play', l)))
        if not s_:
            continue
        if groups and size + s_ <= limit:
            groups[-1].append(l)
            size += s_
        else:
            groups.append([l])
            size = s_
    packs = [('play_' + '_'.join(g), [f for l in g for f in files(os.path.join('play', l))]) for g in groups]
    packs += [(n, files(n)) for n in ('instagram', 'video')]
    made = []
    for name, fs in packs:
        if not fs:
            continue
        path = os.path.join(out, name + '.zip')
        with zipfile.ZipFile(path, 'w', zipfile.ZIP_STORED) as z:
            z.write(os.path.join(out, 'README.md'), 'README.md')
            for f in fs:
                z.write(f, os.path.relpath(f, out))
        assert os.path.getsize(path) <= 25 * 1024 * 1024, path
        made.append((name + '.zip', os.path.getsize(path)))
    return made


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('shots', help='pazarlama ekran görüntülerinin klasörü (m_<dil>_*.png)')
    ap.add_argument('out', help='çıkış klasörü')
    ap.add_argument('--sadece', default='play,instagram,video', help='virgülle: play,instagram,video')
    ap.add_argument('--diller', default=','.join(LANGS))
    ap.add_argument('--zipsiz', action='store_true')
    ap.add_argument('--is', type=int, default=min(4, os.cpu_count() or 1), dest='jobs')
    args = ap.parse_args()
    if not features.check('raqm'):
        sys.exit('Pillow raqm desteği yok: Arapça metin doğru şekillenmez.')
    parts = set(args.sadece.split(','))
    langs = [l for l in args.diller.split(',') if l in LANGS]
    os.makedirs(args.out, exist_ok=True)
    frames = {}
    with ProcessPoolExecutor(max_workers=args.jobs) as ex:
        jobs = [ex.submit(build_video, (args.shots, args.out, o, l))
                for l in VIDEO_LANGS if l in langs for o in ('dikey', 'yatay') if 'video' in parts]
        jobs += [ex.submit(build_play, (l, args.shots, args.out)) for l in langs if 'play' in parts]
        if 'instagram' in parts:
            jobs.append(ex.submit(build_instagram, (args.shots, args.out)))
        for j in jobs:
            key, info = j.result()
            if isinstance(key, tuple):  # video: (dil, yön)
                frames[key] = info
                key, info = ' '.join(key), 'tamam'
            print(key, info)
    previews(args.out, langs, frames)
    write_readme(args.out)
    if not args.zipsiz:
        for name, size in make_zips(args.out, langs):
            print(f'{name}: {size / 1e6:.1f} MB')


if __name__ == '__main__':
    main()
