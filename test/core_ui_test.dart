import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Ortak bileşenler: açık/koyu, RTL, 320dp genişlik ve %130 yazıda taşmamalı
void main() {
  Widget gallery() {
    return Builder(
      builder: (context) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SectionHeader(
            'Konum ve vakitlerin uzun bir bölüm başlığı',
            trailing: Icon(Icons.info_outline),
          ),
          AppCard(
            onTap: () {},
            semanticLabel: 'kart',
            child: const Text('Kart içeriği, birkaç satıra yayılabilen metin'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppListSection(
            title: 'Ayarlar',
            children: [
              AppListTile(
                title: 'Vakit çıkmadan önce hatırlat (uzun başlık)',
                subtitle:
                    'Kılındı işaretlenmemiş namaz için bildirim gönderir.',
                leadingIcon: Icons.alarm,
                trailing: Switch(value: true, onChanged: (_) {}),
                onTap: () {},
              ),
              const AppListTile(title: 'Sadece başlık', showChevron: false),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final state in PrayerRowState.values)
            PrayerTimeRow(
              name: 'İkindi ${state.name}',
              time: '16:08',
              state: state,
              icon: Icons.wb_sunny_outlined,
              trailing: const Icon(Icons.alarm_on, size: 18),
              onTap: () {},
            ),
          const SizedBox(height: AppSpacing.md),
          for (final tone in InfoTone.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InfoBanner(
                message: 'Kerahat vakti yaklaşıyor: 13:50–14:35 (${tone.name})',
                tone: tone,
                action: TextButton(
                  onPressed: () {},
                  child: const Text('Tamam'),
                ),
              ),
            ),
          const Row(
            children: [
              Expanded(
                child: StatTile(value: '%87', label: '30 günlük oran'),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  value: '12 gün',
                  label: 'Seri',
                  icon: Icons.local_fire_department,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ToolTile(
                  icon: Icons.calendar_month,
                  title: 'İmsakiye ve uzun bir başlık',
                  subtitle: 'Aylık ve Ramazan',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ToolTile(
                  icon: Icons.calculate,
                  title: 'Zekat',
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: CounterStepper(
              value: 5,
              min: -30,
              max: 30,
              onChanged: (_) {},
              format: (v) => '${v > 0 ? '+' : ''}$v dk',
              semanticLabel: 'Yatsı',
              onValueTap: () {},
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Center(
            child: TabularText(
              '02:05:09',
              style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(
            height: 260,
            child: EmptyState(
              icon: Icons.inbox,
              title: 'Henüz kayıt yok',
              message: 'Eklediğiniz zikirler burada görünür.',
              actionLabel: 'Ekle',
              onAction: _noop,
            ),
          ),
          SizedBox(
            height: 260,
            child: ErrorState(message: 'Vakitler yüklenemedi.', onRetry: () {}),
          ),
          const SizedBox(
            height: 160,
            child: LoadingState(message: 'Yükleniyor'),
          ),
        ],
      ),
    );
  }

  Future<void> pumpGallery(
    WidgetTester tester, {
    required ThemeMode mode,
    required Locale locale,
    double textScale = 1.0,
    Widget? home,
  }) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home:
            home ??
            AppScaffold(
              title: 'Çok uzun bir ekran başlığı ve devamı',
              actions: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
              ],
              body: gallery(),
            ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  final configs = <(String, ThemeMode, Locale, double)>[
    ('açık tr', ThemeMode.light, const Locale('tr'), 1.0),
    ('koyu tr', ThemeMode.dark, const Locale('tr'), 1.0),
    ('açık ar (RTL)', ThemeMode.light, const Locale('ar'), 1.0),
    ('koyu de %130', ThemeMode.dark, const Locale('de'), 1.3),
    ('açık ar %130', ThemeMode.light, const Locale('ar'), 1.3),
  ];

  for (final (name, mode, locale, scale) in configs) {
    testWidgets('Bileşenler taşmadan çizilir: $name', (tester) async {
      await pumpGallery(tester, mode: mode, locale: locale, textScale: scale);
      expect(tester.takeException(), isNull);
      // Listenin sonuna kadar adım adım kaydırılınca da hata yok
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      while (position.pixels < position.maxScrollExtent) {
        position.jumpTo(
          (position.pixels + 400).clamp(0, position.maxScrollExtent),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      expect(find.byType(LoadingState), findsOneWidget);
    });
  }

  testWidgets('Tema: mor M3 varsayılanı yok, marka rengi ve PrayerColors var', (
    tester,
  ) async {
    final light = AppTheme.light();
    final dark = AppTheme.dark();
    expect(light.colorScheme.primary, const Color(0xFF00796B));
    expect(light.colorScheme.surface, const Color(0xFFF6F8F7));
    expect(dark.colorScheme.primary, const Color(0xFF4DB6AC));
    expect(dark.cardTheme.color, const Color(0xFF161D1C));
    expect(light.extension<PrayerColors>(), isNotNull);
    expect(dark.extension<PrayerColors>(), isNotNull);
    expect(
      AppTheme.light(hasBackgroundImage: true).scaffoldBackgroundColor,
      Colors.transparent,
    );
    // En küçük yazı 13sp
    for (final style in [
      light.textTheme.bodySmall,
      light.textTheme.labelSmall,
      light.textTheme.labelMedium,
    ]) {
      expect(style!.fontSize, greaterThanOrEqualTo(13));
      expect(style.fontFamily, 'Poppins');
    }
  });

  testWidgets('Onay penceresi: onay true, iptal false', (tester) async {
    late BuildContext ctx;
    await pumpGallery(
      tester,
      mode: ThemeMode.light,
      locale: const Locale('tr'),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    final loc = lookupAppLocalizations(const Locale('tr'));

    var result = showConfirmDialog(
      ctx,
      title: 'Sıfırla',
      message: 'Sayacı sıfırlamak istediğinize emin misiniz?',
      confirmLabel: 'Sıfırla',
      destructive: true,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sıfırla'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);

    result = showConfirmDialog(
      ctx,
      title: 'Sil',
      message: 'Emin misiniz?',
      confirmLabel: 'Sil',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(loc.cancel));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });

  testWidgets('CounterStepper sınırda durur', (tester) async {
    var value = 29;
    await pumpGallery(
      tester,
      mode: ThemeMode.light,
      locale: const Locale('tr'),
      home: Scaffold(
        body: Center(
          child: StatefulBuilder(
            builder: (context, setState) => CounterStepper(
              value: value,
              min: 28,
              max: 30,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(value, 30);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(value, 30);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
    }
    expect(value, 28);
  });

  test('formatPrayerTime: en/ar 12 saat (sıfırsız), diğerleri 24 saat', () {
    expect(formatPrayerTime('16:08', 'tr'), '16:08');
    expect(formatPrayerTime('05:35', 'de'), '05:35');
    expect(formatPrayerTime('5:35', 'fr'), '05:35');
    expect(formatPrayerTime('16:08', 'en'), '4:08 PM');
    expect(formatPrayerTime('00:15', 'en'), '12:15 AM');
    expect(formatPrayerTime('12:57', 'en_US'), '12:57 PM');
    expect(formatPrayerTime('05:35', 'ar'), '5:35 ص');
    expect(formatPrayerTime('20:02', 'ar'), '8:02 م');
    expect(formatPrayerTime('', 'tr'), '');
    expect(formatPrayerTime('bozuk', 'en'), 'bozuk');
    expect(formatClockTime(DateTime(2026, 1, 1, 13, 5), 'en'), '1:05 PM');
  });

  test('formatCountdown', () {
    expect(
      formatCountdown(const Duration(hours: 2, minutes: 5, seconds: 9)),
      '02:05:09',
    );
    expect(formatCountdown(const Duration(seconds: -5)), '00:00:00');
    expect(
      formatCountdown(const Duration(hours: 23, minutes: 59, seconds: 59)),
      '23:59:59',
    );
  });
}

void _noop() {}
