// Resimli paylaşım: Play bağlantısı (kampanyalı), tebrik mesajları (5 dil),
// paylaşım kartı %130 yazıda taşmaz, resim 1080x1350 PNG + bağlantılı metin.
import 'dart:io';

import 'package:ezan_saati/core/app_links.dart';
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/services/dini_gunler_service.dart';
import 'package:ezan_saati/data/services/json_service.dart';
import 'package:ezan_saati/features/common/share_card.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _langs = ['tr', 'en', 'de', 'fr', 'ar'];

/// Tebrik gönderilebilen türler: ekrandaki dini günler + üç aylar (Regaib'de)
final _greetingTypes = {
  for (final tur in DiniGunTuru.values)
    if (tur != DiniGunTuru.ramazanArefesi && tur != DiniGunTuru.kurbanArefesi)
      tur.name,
};

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
    );
  }
  await loader.load();
}

Future<void> _pumpCard(
  WidgetTester tester,
  ShareCard card, {
  required String lang,
  double textScale = 1.3,
}) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: card)),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Map<String, Map<String, List<String>>> greetings;

  setUpAll(() async {
    await _loadFont('Poppins', [
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        'assets/google_fonts/Poppins-$w.ttf',
    ]);
    await _loadFont('Amiri', ['assets/fonts/amiri/Amiri-Regular.ttf']);
    greetings = {
      for (final lang in _langs) lang: await JsonService().getGreetings(lang),
    };
  });

  group('Play bağlantısı', () {
    test(
      'kaynak app_share, kampanya kodlu; paylaşım metni bağlantıyla biter',
      () {
        expect(
          AppLinks.playStoreLink('friday'),
          'https://play.google.com/store/apps/details?id=com.mmdigital.vaktinde'
          '&referrer=utm_source%3Dapp_share%26utm_campaign%3Dfriday',
        );
        for (final campaign in ['daily', 'greeting']) {
          expect(
            AppLinks.playStoreLink(campaign),
            '${AppLinks.playStore}&referrer='
            'utm_source%3Dapp_share%26utm_campaign%3D$campaign',
          );
        }
        expect(
          shareCaption('Günün Ayeti', 'daily'),
          'Günün Ayeti · Vaktinde\n${AppLinks.playStoreLink('daily')}',
        );
      },
    );
  });

  group('Tebrik mesajları', () {
    for (final lang in _langs) {
      test('$lang: her tür için 4-6 kısa, tekrarsız mesaj', () {
        final data = greetings[lang]!;
        expect(data.keys.toSet(), _greetingTypes);
        for (final MapEntry(key: type, value: messages) in data.entries) {
          expect(messages.length, inInclusiveRange(4, 6), reason: type);
          expect(messages.toSet(), hasLength(messages.length), reason: type);
          for (final message in messages) {
            expect(message.trim(), message, reason: type);
            expect(message.length, inInclusiveRange(20, 180), reason: message);
            if (lang == 'fr') {
              expect(message, isNot(matches(r' [!?:;]')), reason: message);
            }
          }
        }
      });
    }

    test('bilinmeyen dil Türkçeye düşer', () async {
      expect(await JsonService().getGreetings('xx'), greetings['tr']);
    });
  });

  group('Paylaşım kartı %130 yazıda taşmaz', () {
    final long = List.filled(
      40,
      'Kolaylaştırınız, zorlaştırmayınız; müjdeleyiniz, nefret ettirmeyiniz.',
    ).join(' ');
    final longArabic = List.filled(
      30,
      'وَٱللَّهُ يَعْلَمُ وَأَنتُمْ لَا تَعْلَمُونَ',
    ).join(' ');

    for (final lang in ['tr', 'ar']) {
      testWidgets('$lang: kısa, en uzun tebrik, uzun ayet', (tester) async {
        final loc = lookupAppLocalizations(Locale(lang));
        final messages = [for (final v in greetings[lang]!.values) ...v]
          ..sort((a, b) => a.length.compareTo(b.length));
        final cards = [
          ShareCard(
            title: loc.fridayGreeting,
            message: messages.first,
            footer: loc.shareCardFooter,
          ),
          ShareCard(
            title: loc.ucAylarBaslangici,
            message: messages.last,
            footer: loc.shareCardFooter,
          ),
          ShareCard(
            title: loc.dailyAyahTitle,
            arabic: longArabic,
            message: lang == 'ar' ? longArabic : long,
            source: 'سُورَةُ البَقَرَةِ 282',
            footer: loc.shareCardFooter,
          ),
        ];
        for (final card in cards) {
          await _pumpCard(tester, card, lang: lang);
          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(find.byType(ShareCard)),
            const Size(ShareCard.width, ShareCard.height),
          );
          expect(
            find.textContaining(
              card.message.substring(0, 12),
              findRichText: true,
            ),
            findsOneWidget,
          );
        }
      });
    }

    testWidgets('uzun metin küçülür, sığmayan satır kesilir (…)', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        ShareCard(
          title: 'Günün Hadisi',
          message: long,
          source: 'Buhârî',
          footer: "Google Play'de Vaktinde",
        ),
        lang: 'tr',
      );
      final paragraph = tester.widget<RichText>(
        find.textContaining('Kolaylaştırınız', findRichText: true),
      );
      expect((paragraph.text as TextSpan).style!.fontSize, lessThan(21));
      expect(paragraph.maxLines, isNotNull);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets(
    'resimli paylaşım: 1080x1350 PNG, metin Play bağlantısıyla biter',
    (tester) async {
      final temp = Directory.systemTemp.createTempSync('vaktinde_share');
      addTearDown(() => temp.deleteSync(recursive: true));
      messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => temp.path,
      );
      MethodCall? shared;
      messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        (call) async {
          shared = call;
          return 'dev.fluttercommunity.plus/share/success';
        },
      );
      addTearDown(() {
        messenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
        messenger.setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/share'),
          null,
        );
      });

      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (c) {
              context = c;
              return const Scaffold();
            },
          ),
        ),
      );

      var done = false;
      shareAsImage(
        context,
        title: 'Hayırlı Cumalar',
        message: greetings['tr']!['ramazanBayrami']!.first,
        campaign: 'friday',
      ).then((_) => done = true);
      // Kart çizimi, PNG ve geçici dosya gerçek zaman ister
      for (var i = 0; i < 100 && !done; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(done, isTrue);
      expect(tester.takeException(), isNull);
      expect(
        find.byType(ShareCard),
        findsNothing,
      ); // ekran dışı kart kaldırıldı

      expect(shared?.method, 'shareFiles');
      final args = shared!.arguments as Map;
      expect(args['mimeTypes'], ['image/png']);
      expect(
        args['text'],
        'Hayırlı Cumalar · Vaktinde\n${AppLinks.playStoreLink('friday')}',
      );
      final png = File(
        (args['paths'] as List).single as String,
      ).readAsBytesSync();
      final header = ByteData.sublistView(png, 16, 24);
      expect([header.getUint32(0), header.getUint32(4)], [1080, 1350]);
    },
  );
}
