import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../../../data/services/backup_service.dart';
import '../../../data/services/error_reporter.dart';
import '../../../data/services/prayer_tracker_service.dart';
import '../../common/language_provider.dart';
import '../../common/theme_provider.dart';
import '../../home/view_model/home_view_model.dart';
import '../../zikirmatik/view_model/zikir_view_model.dart';

enum _BackupAction { backup, restore }

/// Ayarlar > Yedekleme: kullanıcı verisi tek dosyaya yazılıp paylaşım
/// penceresiyle kaydedilir/gönderilir; seçilen yedek dosyası onaydan sonra
/// mevcut verinin yerine yüklenir ([BackupService])
class BackupSection extends StatefulWidget {
  const BackupSection({super.key});

  @override
  State<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<BackupSection> {
  _BackupAction? _running;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final idle = _running == null;
    return AppListSection(
      title: loc.sectionBackup,
      children: [
        AppListTile(
          leadingIcon: Icons.save_alt_outlined,
          title: loc.backupExportTitle,
          subtitle: loc.backupExportSub,
          trailing: _running == _BackupAction.backup ? const _Busy() : null,
          onTap: idle ? _export : null,
        ),
        AppListTile(
          leadingIcon: Icons.settings_backup_restore_outlined,
          title: loc.backupImportTitle,
          subtitle: loc.backupImportSub,
          trailing: _running == _BackupAction.restore ? const _Busy() : null,
          onTap: idle ? _import : null,
        ),
      ],
    );
  }

  Future<void> _export() async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _running = _BackupAction.backup);
    try {
      final now = DateTime.now();
      // Açık özel gün dönemi bugüne kadar kaydedilir: yedekte aynı günler olsun
      await PrayerTrackerService().loadExcused();
      final text = await BackupService.export(
        await SharedPreferences.getInstance(),
        now: now,
      );
      final name = BackupService.fileName(now);
      await Share.shareXFiles(
        [
          XFile.fromData(
            utf8.encode(text),
            mimeType: 'application/json',
            name: name,
          ),
        ],
        fileNameOverrides: [name],
        subject: loc.backupShareSubject,
      );
    } catch (e) {
      debugPrint('Yedek paylaşılamadı: $e');
      _snack(messenger, loc.shareFailed);
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  Future<void> _import() async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    // Bekleme sonrasında bağlam kullanılmasın diye baştan; sağlayıcısı
    // olmayan (testte) atlanır
    final home = _maybeRead<HomeViewModel>();
    final language = _maybeRead<LanguageProvider>();
    final theme = _maybeRead<ThemeProvider>();
    final zikir = _maybeRead<ZikirViewModel>();
    setState(() => _running = _BackupAction.restore);
    try {
      final BackupData backup;
      try {
        final raw = await BackupService.pickFile();
        if (raw == null) return; // seçmekten vazgeçildi
        backup = BackupService.decode(raw);
      } on BackupFormatException catch (e) {
        _snack(
          messenger,
          e.error == BackupError.newerVersion
              ? loc.backupNewerVersion
              : loc.backupInvalidFile,
        );
        return;
      }
      if (!mounted) return;
      final confirmed = await showConfirmDialog(
        context,
        title: loc.backupRestoreConfirmTitle,
        message: loc.backupRestoreConfirmMessage(
          _dateText(backup.created, loc.localeName),
        ),
        confirmLabel: loc.backupRestoreConfirm,
        destructive: true,
      );
      if (!confirmed) return;
      await restoreBackup(
        backup,
        home: home,
        language: language,
        theme: theme,
        zikir: zikir,
      );
      // Yedekteki dil seçilmiş olabilir
      final restoredLoc = language == null
          ? loc
          : lookupAppLocalizations(language.locale);
      _snack(messenger, restoredLoc.backupRestored);
    } catch (e, st) {
      _snack(messenger, loc.shareFailed);
      unawaited(reportNonFatal(e, st, reason: 'yedek geri yüklenemedi'));
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  T? _maybeRead<T>() {
    try {
      return Provider.of<T>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
  }

  static String _dateText(DateTime created, String localeName) {
    final local = created.toLocal();
    try {
      return DateFormat('d MMMM y', localeName).format(local);
    } catch (_) {
      return DateFormat('dd.MM.yyyy').format(local);
    }
  }

  static void _snack(ScaffoldMessengerState? messenger, String text) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

/// Yedeği yazar ve uygulamayı yeni kayıtlarla yeniler: namaz takibi
/// dinleyicileri, dil, tema, zikir; en son ana model (konum, vakitler,
/// widget'lar, kalıcı bildirim ve tüm alarmlar)
Future<void> restoreBackup(
  BackupData backup, {
  HomeViewModel? home,
  LanguageProvider? language,
  ThemeProvider? theme,
  ZikirViewModel? zikir,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await PrayerTrackerService.replaceRecords(
    () => BackupService.restore(prefs, backup),
  );
  await language?.reload();
  await theme?.reload();
  await zikir?.reload();
  await home?.reloadFromStorage();
}

class _Busy extends StatelessWidget {
  const _Busy();

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 24,
    child: CircularProgressIndicator(strokeWidth: 2.5),
  );
}
