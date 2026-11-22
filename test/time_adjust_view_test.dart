import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/settings/view/time_adjust_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('İnce ayar: artır/azalt, kaydet, kapan', (tester) async {
    // Dar telefon ekranı (taşma kontrolü)
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'saved_lat': 41.0,
      'saved_lng': 29.0,
      'time_offsets': '{"Yatsı":-3}',
    });

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => HomeViewModel(),
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TimeAdjustView()),
                  ),
                  child: const Text('aç'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    String value(String v) => '${Unicode.LRI}$v${Unicode.PDI} dk';
    expect(find.text('Vakit İnce Ayarı'), findsOneWidget);
    expect(find.text(value('-3')), findsOneWidget); // kayıtlı Yatsı ayarı
    expect(find.text(value('0')), findsNWidgets(5));

    Finder rowButton(String name, IconData icon) => find.descendant(
      of: find.ancestor(of: find.text(name), matching: find.byType(Row)).first,
      matching: find.byIcon(icon),
    );
    // Satırlar bilgi kutusunun altında; kaydet düğmesinin arkasında kalmasın
    await tester.ensureVisible(rowButton('Öğle', Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(rowButton('Öğle', Icons.add));
    await tester.tap(rowButton('Öğle', Icons.add));
    await tester.ensureVisible(rowButton('İmsak', Icons.remove));
    await tester.pumpAndSettle();
    await tester.tap(rowButton('İmsak', Icons.remove));
    await tester.pump();
    expect(find.text(value('+2')), findsOneWidget);
    expect(find.text(value('-1')), findsOneWidget);

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('time_offsets'), '{"İmsak":-1,"Öğle":2,"Yatsı":-3}');
    expect(find.byType(TimeAdjustView), findsNothing);
    expect(find.text('Vakitler güncellendi'), findsOneWidget);
  });

  for (final lang in ['tr', 'en', 'de', 'fr', 'ar']) {
    testWidgets('İnce ayar ekranı $lang dilinde taşmadan çizilir', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 3, 568 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        'saved_lat': 41.0,
        'saved_lng': 29.0,
        'time_offsets': '{"İmsak":-30,"Öğle":30}',
      });
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(),
          child: MaterialApp(
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const TimeAdjustView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Uzun bilgi metninde satırlar kaydırınca görünür
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
