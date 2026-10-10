import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ezan_saati/core/app_links.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';

/// Paylaşım metninin sonu: "<başlık> · Vaktinde" + kampanyalı Play bağlantısı
/// ([campaign]: friday / daily / greeting)
String shareCaption(String title, String campaign) =>
    '$title · Vaktinde\n${AppLinks.playStoreLink(campaign)}';

final RegExp _arabicScript = RegExp(r'[؀-ۿ]');

bool _isArabic(String text) => _arabicScript.hasMatch(text);

/// Paylaşılan resim kartı: 4:5 (360×450; ×3 = 1080×1350 px), marka gradyanı,
/// küçük başlık, metin (Arapça Amiri ile), altta simge + "Google Play'de
/// Vaktinde". Renkler temadan bağımsız: resim her cihazda aynı görünür.
class ShareCard extends StatelessWidget {
  static const double width = 360;
  static const double height = 450;

  /// Altbilgideki uygulama simgesi (paylaşmadan önce önbelleğe alınır)
  static const ImageProvider logo = ResizeImage(
    AssetImage('assets/icon/icon.png'),
    width: 144,
  );

  final String title;
  final String message;

  /// Ayetin Arapçası (mealin üstünde)
  final String? arabic;

  /// Sure/ayet ya da hadis kaynağı
  final String? source;
  final String footer;

  const ShareCard({
    super.key,
    required this.title,
    required this.message,
    this.arabic,
    this.source,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    // Arapça harfler (başlık, kaynak, altbilgi) de Amiri ile çizilir
    final base = Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: Colors.white,
      fontFamilyFallback: const [
        AppTheme.arabicFamily,
        ...AppTheme.fontFallback,
      ],
    );
    Widget circle(double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
      ),
    );
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brand, AppColors.darkPrimaryContainer],
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(top: -80, right: -60, child: circle(220)),
              Positioned(bottom: -100, left: -70, child: circle(260)),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: base.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: 36,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Expanded(
                      child: _CardText(
                        arabic: arabic,
                        message: message,
                        source: source,
                        base: base,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Image(image: logo, width: 28, height: 28),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            footer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: base.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartın metni, sığan en büyük boyutta: önce Arapçasıyla, sığmazsa
/// Arapçasız %100'den %60'a küçültülür; yine sığmazsa satır sınırı (…).
class _CardText extends StatelessWidget {
  static const double _minScale = 0.6;
  static const double _gap = AppSpacing.lg;

  final String? arabic;
  final String message;
  final String? source;
  final TextStyle base;

  const _CardText({
    required this.arabic,
    required this.message,
    required this.source,
    required this.base,
  });

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final arabicText = arabic?.trim() ?? '';
    final messageText = message.trim();
    final sourceText = (source?.trim() ?? '').isEmpty
        ? ''
        : '— ${source!.trim()}';
    final hasArabic = arabicText.isNotEmpty && arabicText != messageText;

    TextStyle arabicStyle(double scale) => base.copyWith(
      fontFamily: AppTheme.arabicFamily,
      fontSize: 24 * scale,
      height: 1.8,
    );
    TextStyle messageStyle(double scale) => _isArabic(messageText)
        ? arabicStyle(scale * 26 / 24).copyWith(height: 1.7)
        : base.copyWith(
            fontSize: 21 * scale,
            fontWeight: FontWeight.w500,
            height: 1.45,
          );
    final sourceStyle = base.copyWith(
      // Amiri'nin harfleri küçük: Arapça kaynak (sure adı) biraz büyük
      fontSize: _isArabic(sourceText) ? 16 : 13,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.8),
    );

    TextDirection direction(String text) =>
        _isArabic(text) ? TextDirection.rtl : TextDirection.ltr;
    // Çizim (RichText) ve ölçüm (TextPainter) aynı ayarlarla
    Widget paragraph(String text, TextStyle style, {int? maxLines}) => RichText(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: direction(text),
      textScaler: scaler,
      maxLines: maxLines,
      overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
    );

    return LayoutBuilder(
      builder: (context, box) {
        double heightOf(String text, TextStyle style, {int? maxLines}) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textAlign: TextAlign.center,
            textDirection: direction(text),
            textScaler: scaler,
            maxLines: maxLines,
            ellipsis: maxLines == null ? null : '…',
          )..layout(maxWidth: box.maxWidth);
          final height = painter.height;
          painter.dispose();
          return height;
        }

        final available =
            box.maxHeight -
            (sourceText.isEmpty
                ? 0
                : heightOf(sourceText, sourceStyle, maxLines: 2) + _gap);

        ({double scale, bool withArabic})? fit() {
          for (final withArabic in [if (hasArabic) true, false]) {
            for (var step = 0; step <= 8; step++) {
              final scale = 1 - step * 0.05;
              var h = heightOf(messageText, messageStyle(scale));
              if (withArabic) {
                h += heightOf(arabicText, arabicStyle(scale)) + _gap;
              }
              if (h <= available) return (scale: scale, withArabic: withArabic);
            }
          }
          return null;
        }

        final fitted = fit();
        final scale = fitted?.scale ?? _minScale;
        int? maxLines;
        if (fitted == null) {
          // En küçük boyutta da sığmıyor: sığan satır kadar (…)
          var lines = 1;
          final style = messageStyle(scale);
          while (heightOf(messageText, style, maxLines: lines + 1) <=
              available) {
            lines++;
          }
          maxLines = lines;
        }

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (fitted?.withArabic ?? false) ...[
                paragraph(arabicText, arabicStyle(scale)),
                const SizedBox(height: _gap),
              ],
              paragraph(messageText, messageStyle(scale), maxLines: maxLines),
              if (sourceText.isNotEmpty) ...[
                const SizedBox(height: _gap),
                paragraph(sourceText, sourceStyle, maxLines: 2),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Mesaj kartı (Cuma mesajları, tebrikler): metin + Kopyala / Metni paylaş /
/// Resimli paylaş. [title]: resimli kartın başlığı ve paylaşım metninin imzası.
class MessageCard extends StatelessWidget {
  final String message;
  final String title;
  final String campaign;

  /// Sağ üstte sıra ("3 / 103")
  final String? position;

  const MessageCard({
    super.key,
    required this.message,
    required this.title,
    required this.campaign,
    this.position,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, color: scheme.primary, size: 28),
              const Spacer(),
              if (position != null)
                Text(
                  position!,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.labelMedium!.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: theme.textTheme.bodyLarge!.copyWith(
              height: 1.6,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              TextButton.icon(
                onPressed: () => copyText(context, message),
                icon: const Icon(Icons.copy, size: 20),
                label: Text(loc.copy),
              ),
              TextButton.icon(
                onPressed: () => shareAsText(
                  context,
                  text: message,
                  title: title,
                  campaign: campaign,
                ),
                icon: const Icon(Icons.share, size: 20),
                label: Text(loc.shareAsText),
              ),
              FilledButton.tonalIcon(
                onPressed: () => shareAsImage(
                  context,
                  title: title,
                  message: message,
                  campaign: campaign,
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, AppSizes.minTouch),
                ),
                icon: const Icon(Icons.image_outlined, size: 20),
                label: Text(loc.shareAsImage),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Alt sayfa içeriği kendi ScaffoldMessenger'ıyla: kopyalandı/hata bildirimi
/// sayfanın altında kalmaz, sayfanın içinde görünür.
class SheetMessenger extends StatelessWidget {
  final Widget child;

  const SheetMessenger({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ScaffoldMessenger(
    child: Scaffold(backgroundColor: Colors.transparent, body: child),
  );
}

void _snack(ScaffoldMessengerState? messenger, String text) {
  if (messenger == null || !messenger.mounted) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
}

Future<void> copyText(BuildContext context, String text) async {
  final loc = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await Clipboard.setData(ClipboardData(text: text));
    _snack(messenger, loc.messageCopied);
  } catch (_) {
    _snack(messenger, loc.shareFailed);
  }
}

/// Düz metin paylaşımı: metin + [shareCaption] (Play bağlantısıyla biter)
Future<void> shareAsText(
  BuildContext context, {
  required String text,
  required String title,
  required String campaign,
}) async {
  final loc = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await Share.share('${text.trim()}\n\n${shareCaption(title, campaign)}');
  } catch (_) {
    _snack(messenger, loc.shareFailed);
  }
}

bool _sharingImage = false;

/// Resimli paylaşım: [ShareCard] ekran dışında çizilir, PNG'ye çevrilir ve
/// [shareCaption] metniyle paylaşılır. Yazı ölçeği/kalın yazı ayarı resme
/// uygulanmaz (her cihazda aynı resim).
Future<void> shareAsImage(
  BuildContext context, {
  required String title,
  required String message,
  String? arabic,
  String? source,
  required String campaign,
}) async {
  if (_sharingImage) return;
  _sharingImage = true;
  final loc = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final overlay = Overlay.maybeOf(context);
  final media = MediaQuery.of(
    context,
  ).copyWith(textScaler: TextScaler.noScaling, boldText: false);
  final boundaryKey = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -ShareCard.width * 3,
      top: 0,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: MediaQuery(
            data: media,
            child: RepaintBoundary(
              key: boundaryKey,
              child: ShareCard(
                title: title,
                message: message,
                arabic: arabic,
                source: source,
                footer: loc.shareCardFooter,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  var inserted = false;
  try {
    if (overlay == null) throw StateError('no overlay');
    await precacheImage(ShareCard.logo, context);
    overlay.insert(entry);
    inserted = true;
    await WidgetsBinding.instance.endOfFrame;

    final boundary = boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('share card not rendered');
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final ByteData? png;
    try {
      png = await image.toByteData(format: ui.ImageByteFormat.png);
    } finally {
      image.dispose();
    }
    if (png == null) throw StateError('png encode failed');
    entry.remove();
    inserted = false;

    const fileName = 'vaktinde.png';
    await Share.shareXFiles(
      [
        XFile.fromData(
          png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
          mimeType: 'image/png',
          name: fileName,
        ),
      ],
      fileNameOverrides: const [fileName],
      text: shareCaption(title, campaign),
    );
  } catch (_) {
    _snack(messenger, loc.shareFailed);
  } finally {
    if (inserted) entry.remove();
    entry.dispose();
    _sharingImage = false;
  }
}
