// "Namazdayım" otomatik sessiz modu: pencere planı, sesli ezanda 1 dk kayma,
// Cuma penceresi birleşimi, Avrupa yazında gece yarısı sonrası Yatsı,
// StorageService, BackupService, 5 dil ve Bildirim Ayarları arayüzü.
import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/models/prayer_times_model.dart';
import 'package:ezan_saati/data/services/backup_service.dart';
import 'package:ezan_saati/data/services/prayer_silence.dart';
import 'package:ezan_saati/data/services/storage_service.dart';
import 'package:ezan_saati/features/home/view_model/home_view_model.dart';
import 'package:ezan_saati/features/settings/view/notification_settings_view.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final normalDay = PrayerTimesModel(
    imsak: '05:30',
    gunes: '07:00',
    ogle: '12:30',
    ikindi: '15:30',
    aksam: '18:00',
    yatsi: '19:30',
  );

  group('PrayerSilence.buildPlan', () {
    test('ayar kapalıysa boş plan döner', () {
      final plan = PrayerSilence.buildPlan(
        days: [normalDay],
        now: DateTime(2026, 11, 22, 10, 0),
        settings: const PrayerSilenceSettings(enabled: false),
      );
      expect(plan, isEmpty);
    });

    test(
      'sesli ezanda 1 dk sonra başlar, sesli değilse tam vakitte başlar',
      () {
        // 2026-11-22 Pazar
        final plan = PrayerSilence.buildPlan(
          days: [normalDay],
          now: DateTime(2026, 11, 22, 12, 0),
          settings: const PrayerSilenceSettings(
            enabled: true,
            durationMinutes: 20,
            prayers: {'Öğle', 'İkindi'},
            fridayEnabled: false,
          ),
          audibleEzans: const {'Öğle'},
        );
        expect(plan, [
          SilenceWindow(
            start: DateTime(2026, 11, 22, 12, 31),
            end: DateTime(2026, 11, 22, 12, 51),
          ),
          SilenceWindow(
            start: DateTime(2026, 11, 22, 15, 30),
            end: DateTime(2026, 11, 22, 15, 50),
          ),
        ]);
      },
    );

    test(
      'Cuma günü Öğle penceresi (15 dk önce → 45 dk sonra) çakışan öğleyle birleşir',
      () {
        // 2026-11-27 Cuma
        final plan = PrayerSilence.buildPlan(
          days: [normalDay],
          now: DateTime(2026, 11, 27, 10, 0),
          settings: const PrayerSilenceSettings(
            enabled: true,
            durationMinutes: 20,
            prayers: {'Öğle'},
            fridayEnabled: true,
          ),
        );
        expect(plan, [
          SilenceWindow(
            start: DateTime(2026, 11, 27, 12, 15),
            end: DateTime(2026, 11, 27, 13, 15),
          ),
        ]);
      },
    );

    test('Avrupa yazında gece yarısını geçen Yatsı ve farklı saat dilimi', () {
      // Amsterdam yaz = UTC+2; Akşam 22:05, Yatsı 00:15 (ertesi gün)
      final summer = PrayerTimesModel(
        imsak: '03:00',
        gunes: '05:18',
        ogle: '13:45',
        ikindi: '18:05',
        aksam: '22:05',
        yatsi: '00:15',
        timeZone: 'Europe/Amsterdam',
      );
      // 2026-06-21 20:30 UTC = 22:30 CEST
      final plan = PrayerSilence.buildPlan(
        days: [summer],
        now: DateTime.utc(2026, 6, 21, 20, 30),
        settings: const PrayerSilenceSettings(
          enabled: true,
          durationMinutes: 30,
          prayers: {'Yatsı'},
          fridayEnabled: false,
        ),
      );
      expect(plan, hasLength(1));
      // 2026-06-22 00:15 CEST = 2026-06-21 22:15 UTC
      expect(plan.single.start.toUtc(), DateTime.utc(2026, 6, 21, 22, 15));
      expect(plan.single.end.toUtc(), DateTime.utc(2026, 6, 21, 22, 45));
    });
  });

  group('Storage & Backup', () {
    test('StorageService ayarları kaydeder ve okur', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      final def = await storage.loadPrayerSilenceSettings();
      expect(def.enabled, isFalse);
      expect(def.durationMinutes, 20);
      expect(def.prayers, PrayerSilence.defaultPrayers);
      expect(def.fridayEnabled, isTrue);

      const custom = PrayerSilenceSettings(
        enabled: true,
        durationMinutes: 30,
        prayers: {'Öğle', 'Yatsı'},
        fridayEnabled: false,
      );
      await storage.savePrayerSilenceSettings(custom);
      final loaded = await storage.loadPrayerSilenceSettings();
      expect(loaded.enabled, isTrue);
      expect(loaded.durationMinutes, 30);
      expect(loaded.prayers, {'Öğle', 'Yatsı'});
      expect(loaded.fridayEnabled, isFalse);
    });

    test(
      'BackupService geçerli ayarları kabul eder, geçersiz süreyi reddeder',
      () {
        expect(
          BackupService.isBackedUp(StorageService.prayerSilenceEnabledKey),
          isTrue,
        );
        expect(
          BackupService.isBackedUp(StorageService.prayerSilenceMinutesKey),
          isTrue,
        );
        expect(
          BackupService.isBackedUp(StorageService.prayerSilencePrayersKey),
          isTrue,
        );
        expect(
          BackupService.isBackedUp(StorageService.prayerSilenceFridayKey),
          isTrue,
        );

        final good = BackupService.encode({
          StorageService.prayerSilenceEnabledKey: true,
          StorageService.prayerSilenceMinutesKey: 30,
          StorageService.prayerSilencePrayersKey: ['Öğle', 'Akşam'],
          StorageService.prayerSilenceFridayKey: true,
        }, created: DateTime.utc(2026, 11, 22));
        expect(
          BackupService.decode(
            good,
          ).values[StorageService.prayerSilenceMinutesKey],
          30,
        );

        final badMinutes = BackupService.encode({
          StorageService.prayerSilenceMinutesKey: 99,
        }, created: DateTime.utc(2026, 11, 22));
        expect(
          () => BackupService.decode(badMinutes),
          throwsA(isA<BackupFormatException>()),
        );
      },
    );
  });

  group('5 dil ve arayüz', () {
    for (final code in ['tr', 'en', 'de', 'fr', 'ar']) {
      test('$code: tüm Namazdayım metinleri çevrili', () {
        final loc = lookupAppLocalizations(Locale(code));
        final texts = [
          loc.prayerSilenceTitle,
          loc.prayerSilenceSub,
          loc.prayerSilenceActiveSub(20),
          loc.prayerSilencePermissionNeeded,
          loc.prayerSilencePermissionBanner,
          loc.prayerSilenceGrantAccess,
          loc.prayerSilenceDuration,
          loc.prayerSilenceMinutes(30),
          loc.prayerSilencePrayers,
          loc.prayerSilenceFridayTitle,
          loc.prayerSilenceFridaySub,
          loc.prayerSilenceNote,
        ];
        for (final t in texts) {
          expect(t.trim(), isNotEmpty, reason: code);
          expect(t, isNot(contains('{')), reason: '$code: $t');
        }
      });
    }

    testWidgets(
      'Bildirim Ayarları: satır açılır, süre ve Cuma ayarı kaydedilir',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        late HomeViewModel vm;
        final tr = lookupAppLocalizations(const Locale('tr'));

        await tester.pumpWidget(
          ChangeNotifierProvider<HomeViewModel>(
            lazy: false,
            create: (_) => vm = HomeViewModel(),
            child: MaterialApp(
              theme: AppTheme.light(),
              locale: const Locale('tr'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const NotificationSettingsView(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(tr.prayerSilenceTitle), findsOneWidget);
        await tester.tap(find.text(tr.prayerSilenceTitle));
        await tester.pumpAndSettle();

        // DND izni yokken uyarı ve düğme görünür
        expect(find.text(tr.prayerSilenceGrantAccess), findsOneWidget);

        // Süre 30 dk seçilir
        await tester.tap(find.text(tr.prayerSilenceMinutes(30)));
        await tester.pumpAndSettle();
        expect(vm.prayerSilence.durationMinutes, 30);

        // Cuma penceresi kapatılır
        final fridayTile = find.text(tr.prayerSilenceFridayTitle);
        await tester.ensureVisible(fridayTile);
        await tester.pumpAndSettle();
        await tester.tap(fridayTile);
        await tester.pumpAndSettle();
        expect(vm.prayerSilence.fridayEnabled, isFalse);

        final saved = await StorageService().loadPrayerSilenceSettings();
        expect(saved.durationMinutes, 30);
        expect(saved.fridayEnabled, isFalse);
        expect(tester.takeException(), isNull);

        // Widget ağacını kapat: HomeViewModel.dispose() zamanlayıcıyı temizler
        await tester.pumpWidget(const SizedBox());
      },
    );
  });
}
