import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../view_model/zikir_view_model.dart';
import '../../common/widgets/ad_banner_widget.dart';

class ZikirSettingsView extends StatelessWidget {
  const ZikirSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    const primaryColor = Colors.teal;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.zikirSettings),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: textColor,
      ),
      body: Consumer<ZikirViewModel>(
        builder: (context, viewModel, child) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // --- GÖRÜNÜM SEÇİMİ ---
              Text(
                loc.appearance,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    RadioListTile<int>(
                      activeColor: primaryColor,
                      title: Text(
                        loc.themeModern,
                        style: TextStyle(color: textColor),
                      ),
                      secondary: const Icon(Icons.touch_app),
                      value: 0,
                      groupValue: viewModel.viewMode,
                      onChanged: (int? value) {
                        if (value != null) viewModel.setViewMode(value);
                      },
                    ),
                    Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                    RadioListTile<int>(
                      activeColor: primaryColor,
                      title: Text(
                        loc.themeClassic,
                        style: TextStyle(color: textColor),
                      ),
                      secondary: const Icon(
                        Icons.watch,
                      ), // Klasik mekanik görünüm ikonu
                      value: 1,
                      groupValue: viewModel.viewMode,
                      onChanged: (int? value) {
                        if (value != null) viewModel.setViewMode(value);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- KONTROL AYARLARI ---
              Text(
                loc.zikirSettings,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeColor: primaryColor,
                      title: Text(
                        loc.vibration,
                        style: TextStyle(color: textColor),
                      ),
                      secondary: const Icon(Icons.vibration),
                      value: viewModel.isVibrationEnabled,
                      onChanged: (bool value) =>
                          viewModel.toggleVibration(value),
                    ),
                    Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                    SwitchListTile(
                      activeColor: primaryColor,
                      title: Text(
                        loc.sound,
                        style: TextStyle(color: textColor),
                      ),
                      secondary: const Icon(Icons.volume_up),
                      value: viewModel.isSoundEnabled,
                      onChanged: (bool value) => viewModel.toggleSound(value),
                    ),
                    Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                    SwitchListTile(
                      activeColor: primaryColor,
                      title: Text(
                        loc.keepAwake,
                        style: TextStyle(color: textColor),
                      ),
                      secondary: const Icon(Icons.screen_lock_portrait),
                      value: viewModel.isKeepAwakeEnabled,
                      onChanged: (bool value) =>
                          viewModel.toggleKeepAwake(value),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      // --- BANNER REKLAM BURAYA ENTEGRE EDİLDİ ---
      bottomNavigationBar: const SafeArea(child: AdBannerWidget()),
    );
  }
}
