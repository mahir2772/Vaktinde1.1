// Yakındaki camiler: harita uygulamasında kayıtlı konum çevresinde cami
// araması (geo:), açan uygulama yoksa Google Haritalar web araması; hiçbiri
// açılamazsa SnackBar. Geçiş reklamı olmadığı ads_policy_test'te.
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/features/common/theme_provider.dart';
import 'package:ezan_saati/features/tools/nearby_mosques.dart';
import 'package:ezan_saati/features/tools/view/tools_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _istanbul = (lat: 41.0082, lng: 28.9784);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const urlLauncher = MethodChannel('plugins.flutter.io/url_launcher');

  group('Adresler', () {
    test('kayıtlı konumla: önce geo:, sonra Google Haritalar', () {
      expect(nearbyMosqueUris('cami', _istanbul).map((u) => '$u'), [
        'geo:41.00820,28.97840?q=cami',
        'https://www.google.com/maps/search/?api=1'
            '&query=cami+near+41.00820%2C28.97840',
      ]);
    });

    test('konum yoksa geo:0,0 (harita kendi konumunu kullanır)', () {
      expect(nearbyMosqueUris('mosque', null).map((u) => '$u'), [
        'geo:0,0?q=mosque',
        'https://www.google.com/maps/search/?api=1&query=mosque',
      ]);
    });

    test('Arapça/aksanlı terim kodlanır; güney ve batı koordinatı', () {
      const arabic = '%D9%85%D8%B3%D8%AC%D8%AF'; // مسجد
      final ar = nearbyMosqueUris('مسجد', (lat: -6.2, lng: -106.816666));
      expect(ar.map((u) => '$u'), [
        'geo:-6.20000,-106.81667?q=$arabic',
        'https://www.google.com/maps/search/?api=1'
            '&query=$arabic+near+-6.20000%2C-106.81667',
      ]);
      expect(ar.first.queryParameters['q'], 'مسجد');
      expect(ar.last.queryParameters['query'], 'مسجد near -6.20000,-106.81667');
      expect(
        '${nearbyMosqueUris('mosquée', null).first}',
        'geo:0,0?q=mosqu%C3%A9e',
      );
    });

    test('arama terimi her dilde', () {
      const terms = {
        'tr': 'cami',
        'en': 'mosque',
        'de': 'Moschee',
        'fr': 'mosquée',
        'ar': 'مسجد',
      };
      terms.forEach((lang, term) {
        expect(lookupAppLocalizations(Locale(lang)).nearbyMosquesQuery, term);
      });
    });
  });

  group('Araçlar satırı', () {
    final loc = lookupAppLocalizations(const Locale('tr'));
    late List<MethodCall> launches;
    // Açan uygulama: geo: yoksa ACTIVITY_NOT_FOUND, web yoksa false
    var geoApp = true;
    var browser = true;

    setUp(() {
      launches = [];
      geoApp = true;
      browser = true;
      messenger.setMockMethodCallHandler(urlLauncher, (call) async {
        launches.add(call);
        final url = (call.arguments as Map)['url'] as String;
        if (url.startsWith('geo:')) {
          if (!geoApp) throw PlatformException(code: 'ACTIVITY_NOT_FOUND');
          return true;
        }
        return browser;
      });
    });

    tearDown(() => messenger.setMockMethodCallHandler(urlLauncher, null));

    List<String> urls() => [
      for (final c in launches) (c.arguments as Map)['url'] as String,
    ];

    Future<void> tapMosques(
      WidgetTester tester, {
      Map<String, Object> prefs = const {},
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      tester.view.physicalSize = const Size(411 * 3, 891 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ToolsView(),
          ),
        ),
      );
      await tester.pump();
      await tester.scrollUntilVisible(find.text(loc.nearbyMosquesTitle), 200);
      await tester.tap(find.text(loc.nearbyMosquesTitle));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('kayıtlı konum çevresinde harita uygulamasında açılır', (
      tester,
    ) async {
      await tapMosques(
        tester,
        prefs: {'saved_lat': _istanbul.lat, 'saved_lng': _istanbul.lng},
      );
      expect(urls(), ['geo:41.00820,28.97840?q=cami']);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('geo: açan uygulama yoksa Google Haritalar tarayıcıda', (
      tester,
    ) async {
      geoApp = false;
      await tapMosques(tester);
      expect(urls(), [
        'geo:0,0?q=cami',
        'https://www.google.com/maps/search/?api=1&query=cami',
      ]);
      // Dış uygulamada (uygulama içi görünüm değil)
      expect((launches.last.arguments as Map)['useWebView'], isFalse);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('hiçbiri açılamazsa uyarı', (tester) async {
      geoApp = false;
      browser = false;
      await tapMosques(tester);
      expect(urls(), hasLength(2));
      expect(find.text(loc.nearbyMosquesError), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
