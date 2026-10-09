import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/services/error_reporter.dart';
import '../../../data/services/prayer_refresh_service.dart';
import '../../../data/services/prayer_tracker.dart';
import '../../home/prayer_schedule.dart';
import '../../home/view/home_view.dart';
import '../../home/view_model/home_view_model.dart';
import '../notification_health.dart';

/// Bildirim Kontrolü: ezanı engelleyebilecek durumlar (açık ezanlar, sıradaki kurulu
/// ezan, bildirim ve alarm izni, ses, Rahatsız Etmeyin, pil, arka planda çalışma),
/// üreticiye göre arka plan ayarları ve 1 dk sonra test ezanı. Her satırda en fazla
/// bir buton; sistem ayarlarından dönünce yeniden okunur.
class NotificationHealthView extends StatefulWidget {
  const NotificationHealthView({super.key});

  @override
  State<NotificationHealthView> createState() => _NotificationHealthViewState();
}

class _NotificationHealthViewState extends State<NotificationHealthView> {
  late final AppLifecycleListener _lifecycle;
  final GlobalKey _guideKey = GlobalKey();

  bool _loaded = false;
  DeviceStatus? _device;
  // Bekleyen bildirimler okunamadıysa "sıradaki ezan" satırı yok
  bool _nextKnown = false;
  ScheduledEzan? _next;
  DateTime? _lastRun;
  DateTime? _installedAt;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _load);
    _load();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final vm = context.read<HomeViewModel>();
    unawaited(vm.alarmHealth.refresh());
    final (device, next, lastRun, installedAt) = await (
      NotificationHealth.readDevice(),
      _readNext(vm),
      PrayerRefreshService.lastHeadlessRun(),
      _readInstalledAt(),
    ).wait;
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _device = device;
      _nextKnown = next.$1;
      _next = next.$2;
      _lastRun = lastRun;
      _installedAt = installedAt;
    });
  }

  static Future<(bool, ScheduledEzan?)> _readNext(HomeViewModel vm) async {
    try {
      return (true, await vm.nextScheduledEzan());
    } catch (e) {
      return (false, null);
    }
  }

  // Bu sürümün kurulduğu ya da güncellendiği an (arka plan kaydı 1.2.0'da başladı)
  static Future<DateTime?> _readInstalledAt() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.updateTime ?? info.installTime;
    } catch (e) {
      return null;
    }
  }

  Future<void> _open(SettingsTarget target) =>
      NotificationHealth.openSettings(target);

  Future<void> _reschedule() async {
    await context.read<HomeViewModel>().rescheduleAlarms();
    if (mounted) await _load();
  }

  void _openAlarms() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    HomeView.openAlarmsTab();
  }

  void _showSteps() {
    final guide = _guideKey.currentContext;
    if (guide == null) return;
    Scrollable.ensureVisible(
      guide,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _scheduleTest() async {
    final vm = context.read<HomeViewModel>();
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _testing = true);
    var scheduled = true;
    try {
      await vm.scheduleTestEzan(loc);
    } catch (e, st) {
      scheduled = false;
      // Mesaj bildirimi beklemez
      unawaited(reportNonFatal(e, st, reason: 'test ezanı kurulamadı'));
    }
    if (!mounted) return;
    setState(() => _testing = false);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(scheduled ? loc.healthTestScheduled : loc.shareFailed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final vm = context.watch<HomeViewModel>();
    return AppScaffold(
      title: loc.healthTitle,
      body: !_loaded
          ? const LoadingState()
          : ListenableBuilder(
              listenable: vm.alarmHealth,
              builder: (context, _) => _buildContent(vm, loc),
            ),
    );
  }

  Widget _buildContent(HomeViewModel vm, AppLocalizations loc) {
    final device = _device;
    final background = NotificationHealth.backgroundStatus(
      lastRun: _lastRun,
      installedAt: _installedAt,
      now: DateTime.now(),
    );
    // Arka planda çalışma durmuşsa üretici adımları testten önce, uyarıyla
    final stale = background == HealthStatus.warning;
    final guide = _GuideSection(
      key: _guideKey,
      vendor: NotificationHealth.vendorOf(
        device?.manufacturer ?? '',
        device?.brand ?? '',
      ),
      stale: stale,
    );
    final test = _TestSection(testing: _testing, onTest: _scheduleTest);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppListSection(
            title: loc.healthSectionStatus,
            children: _checks(vm, loc, device, background),
          ),
          if (stale) guide,
          test,
          if (!stale) guide,
        ],
      ),
    );
  }

  List<Widget> _checks(
    HomeViewModel vm,
    AppLocalizations loc,
    DeviceStatus? device,
    HealthStatus? background,
  ) {
    final health = vm.alarmHealth;
    final alarmStream = vm.ezanAlarmStream && vm.alarmStreamSupported;
    // "Sessiz modda da çal" kapalıysa (ve 8.0+) sessizde/Rahatsız Etmeyin'de ipucu
    final tip = !alarmStream && vm.alarmStreamSupported
        ? ' ${loc.healthAlarmStreamTip(loc.ezanAlarmStreamTitle)}'
        : '';
    final ezans = PrayerRefreshService.vakitKeys
        .where((key) => vm.onTimeAlarms[key] == true)
        .toList();
    final checks = <Widget>[
      ezans.isEmpty
          ? _CheckTile(
              status: HealthStatus.info,
              title: loc.healthEzansTitle,
              message: loc.healthEzansNone,
              actionLabel: loc.tabAlarms,
              onAction: _openAlarms,
            )
          : _CheckTile(
              status: HealthStatus.ok,
              title: loc.healthEzansTitle,
              message: loc.healthEzansOn(
                ezans
                    .map((key) => localizedPrayerName(key, loc))
                    .join(loc.localeName.startsWith('ar') ? '، ' : ', '),
              ),
            ),
    ];

    final next = _next;
    if (ezans.isNotEmpty && _nextKnown) {
      checks.add(
        next == null
            ? _CheckTile(
                status: HealthStatus.warning,
                title: loc.healthNextTitle,
                message: loc.healthNextNone,
                actionLabel: loc.healthReschedule,
                onAction: _reschedule,
              )
            : _CheckTile(
                status: HealthStatus.ok,
                title: loc.healthNextTitle,
                message: _nextText(next, loc),
              ),
      );
    }

    final notificationsEnabled = health.notificationsEnabled;
    if (notificationsEnabled != null) {
      checks.add(
        notificationsEnabled
            ? _CheckTile(
                status: HealthStatus.ok,
                title: loc.healthNotificationsTitle,
                message: loc.healthNotificationsOk,
                actionLabel: loc.healthOpenSettings,
                onAction: () => _open(SettingsTarget.notifications),
              )
            : _CheckTile(
                status: HealthStatus.warning,
                title: loc.healthNotificationsTitle,
                message: loc.alarmHealthNotificationsOff,
                actionLabel: loc.alarmHealthNotificationsAction,
                onAction: health.fixNotifications,
              ),
      );
    }

    // "Alarmlar ve hatırlatıcılar" izni Android 12'de geldi
    final exactAllowed = health.exactAllowed;
    if (exactAllowed != null && (device?.sdkInt ?? 31) >= 31) {
      checks.add(
        exactAllowed
            ? _CheckTile(
                status: HealthStatus.ok,
                title: loc.healthExactTitle,
                message: loc.healthExactOk,
              )
            : _CheckTile(
                status: HealthStatus.warning,
                title: loc.healthExactTitle,
                message: loc.alarmHealthExactOff,
                actionLabel: loc.alarmHealthExactAction,
                onAction: health.fixExactAlarms,
              ),
      );
    }

    if (device != null) {
      final volumeKnown = alarmStream
          ? device.alarmVolume != null
          : device.ringerMode != null || device.notificationVolume != null;
      if (volumeKnown) {
        final issue = NotificationHealth.volumeIssue(
          device,
          alarmStream: alarmStream,
        );
        checks.add(
          _CheckTile(
            status: issue == null ? HealthStatus.ok : HealthStatus.warning,
            title: loc.healthVolumeTitle,
            message: switch (issue) {
              null =>
                alarmStream ? loc.healthVolumeAlarmOk : loc.healthVolumeOk,
              VolumeIssue.alarmMuted => loc.healthVolumeAlarmMuted,
              VolumeIssue.silentMode => loc.healthVolumeSilent + tip,
              VolumeIssue.notificationMuted =>
                loc.healthVolumeNotificationMuted + tip,
            },
            actionLabel: issue == null ? null : loc.healthOpenSettings,
            onAction: () => _open(SettingsTarget.sound),
          ),
        );
      }

      final dnd = NotificationHealth.dndStatus(
        device.interruptionFilter,
        alarmStream: alarmStream,
      );
      if (dnd != null) {
        // Tam sessizlikte alarm da çalmaz: ipucu yok
        final totalSilence =
            device.interruptionFilter == NotificationHealth.filterNone;
        checks.add(
          _CheckTile(
            status: dnd,
            title: loc.healthDndTitle,
            message: switch (dnd) {
              HealthStatus.ok => loc.healthDndOff,
              HealthStatus.info => loc.healthDndAlarm(loc.ezanAlarmStreamTitle),
              HealthStatus.warning =>
                loc.healthDndOn + (totalSilence ? '' : tip),
            },
            actionLabel: dnd == HealthStatus.ok ? null : loc.healthOpenSettings,
            onAction: () => _open(SettingsTarget.dnd),
          ),
        );
      }

      final batteryOptimized = device.batteryOptimized;
      if (batteryOptimized != null) {
        checks.add(
          _CheckTile(
            status: batteryOptimized ? HealthStatus.warning : HealthStatus.ok,
            title: loc.healthBatteryTitle,
            message: batteryOptimized
                ? loc.healthBatteryOptimized
                : loc.healthBatteryOk,
            actionLabel: batteryOptimized ? loc.healthOpenSettings : null,
            onAction: () => _open(SettingsTarget.battery),
          ),
        );
      }
    }

    final lastRun = _lastRun;
    if (background != null) {
      checks.add(
        _CheckTile(
          status: background,
          title: loc.healthBackgroundTitle,
          message: background == HealthStatus.ok && lastRun != null
              ? _lastRunText(lastRun, loc)
              : loc.healthBackgroundStale,
          actionLabel: background == HealthStatus.warning
              ? loc.healthShowSteps
              : null,
          onAction: _showSteps,
        ),
      );
    }
    return checks;
  }

  // "Akşam 18:01"; yarınsa "(Yarın)", daha sonraysa tarih eklenir
  String _nextText(ScheduledEzan next, AppLocalizations loc) {
    final text =
        '${localizedPrayerName(next.key, loc)} '
        '${formatClockTime(next.time, loc.localeName)}';
    final days = PrayerTracker.daysBetween(DateTime.now(), next.time);
    if (days == 1) return '$text ${loc.tomorrow}';
    if (days > 1) {
      final date = MaterialLocalizations.of(
        context,
      ).formatShortMonthDay(next.time);
      return '$text ($date)';
    }
    return text;
  }

  // Son koşu 24 saat içinde: bugün ya da dün
  static String _lastRunText(DateTime lastRun, AppLocalizations loc) {
    final time = formatClockTime(lastRun, loc.localeName);
    final yesterday = DateUtils.isSameDay(
      lastRun,
      PrayerTracker.addDays(DateTime.now(), -1),
    );
    return yesterday
        ? loc.healthBackgroundYesterday(time)
        : loc.healthBackgroundToday(time);
  }
}

/// Kontrol satırı: durum simgesi, başlık, açıklama ve (varsa) tek buton
class _CheckTile extends StatelessWidget {
  final HealthStatus status;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CheckTile({
    required this.status,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = PrayerColors.of(context);
    final (IconData icon, Color color) = switch (status) {
      HealthStatus.ok => (Icons.check_circle, colors.success),
      HealthStatus.warning => (Icons.warning_amber_rounded, colors.warning),
      HealthStatus.info => (Icons.info_outline, scheme.primary),
    };
    final hasAction = actionLabel != null && onAction != null;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        hasAction ? AppSpacing.xs : AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasAction)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Üreticiye göre arka plan ayarları (2-4 adım), uygulama ayarları ve ayrıntılı
/// rehber bağlantısı. [stale]: arka planda çalışma durmuş, başta uyarı
class _GuideSection extends StatelessWidget {
  final PhoneVendor vendor;
  final bool stale;

  const _GuideSection({super.key, required this.vendor, required this.stale});

  static Future<void> _openGuideSite() async {
    try {
      if (!await launchUrl(
        Uri.parse(NotificationHealth.guideUrl),
        mode: LaunchMode.externalApplication,
      )) {
        debugPrint('Rehber açılamadı');
      }
    } catch (e) {
      debugPrint('Rehber açılamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = NotificationHealth.vendorNames[vendor];
    final steps = NotificationHealth.guideSteps(vendor, loc);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(
          name == null
              ? loc.healthGuideTitleGeneric
              : loc.healthGuideTitle(name),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (stale) ...[
                      InfoBanner(
                        tone: InfoTone.warning,
                        message: loc.healthGuideStale,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    for (var i = 0; i < steps.length; i++)
                      _GuideStep(number: i + 1, text: steps[i]),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () =>
                            NotificationHealth.openSettings(SettingsTarget.app),
                        child: Text(loc.healthOpenSettings),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
              ),
              AppListTile(
                leadingIcon: Icons.public,
                title: 'dontkillmyapp.com',
                subtitle: loc.healthGuideMore,
                showChevron: false,
                trailing: Icon(
                  Icons.open_in_new,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onTap: _openGuideSite,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuideStep extends StatelessWidget {
  final int number;
  final String text;

  const _GuideStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Numara yazıyla büyür (%130'da sıkışmaz)
    final badge = MediaQuery.textScalerOf(context).scale(24);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: badge,
            height: badge,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: theme.textTheme.labelLarge!.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// "1 dk sonra test ezanı": gerçek ezanla aynı ses ve ayarlarla
class _TestSection extends StatelessWidget {
  final bool testing;
  final VoidCallback onTest;

  const _TestSection({required this.testing, required this.onTest});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeader(loc.healthTestTitle),
        AppCard(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.healthTestInfo,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: testing ? null : onTest,
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(loc.healthTestButton),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
